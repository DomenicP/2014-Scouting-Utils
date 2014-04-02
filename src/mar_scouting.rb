require_relative 'tba'
require 'CSV'
require 'pry'

# Get the list of teams attending MAR DCMP
@teams = TBA.get_event_teams "2014mrcmp"
@teams.sort_by! { |t| t['team_number'] }

# Retrive match data for the teams
@data = @teams.map { |t| TBA.get_team t['team_number'] }

CSV.open('MAR_Scouting.csv', 'w') do |csv|
  # Header row
  csv << ['Team #', 'Name', 'Wins', 'Losses', 'Ties', 'High Score', 'Average Score', 'Awards']
  @data.each do |t|
    row = []
    row << t['team_number']    # Team Number
    row << t['nickname']       # Team Name
    
    wins = losses = ties = 0
    scores = []
    awards = []
    t['events'].each do |e|
      e['matches'].each do |m|
        # Determine which alliance the team is on
        isRed = m['alliances']['red']['teams'].include? t['key']

        # Grab the team's score
        team_score = opponent_score = 0
        if isRed
          team_score = m['alliances']['red']['score']
          opponent_score = m['alliances']['blue']['score']
        else
          team_score = m['alliances']['blue']['score']
          opponent_score = m['alliances']['red']['score']
        end
        scores << team_score

        # Determine if match was a win, loss, or tie
        if team_score > opponent_score
          wins += 1
        elsif team_score < opponent_score
          losses += 1
        else
          ties += 1
        end
      end

      # Grab award info
      e['awards'].each { |a| awards << "#{a['name']} (#{a['event_key'][4..-1].upcase})" }
    end

    row << wins
    row << losses
    row << ties
    row << scores.max
    row << ((scores.inject(0) { |sum, score| sum += score }) / scores.count)
    row << awards.join('; ')
    
    csv << row
  end
end

