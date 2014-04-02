require_relative 'tba'
require 'CSV'
require 'pry'

EVENT = "2014mrcmp"

# Get the list of teams attending MAR DCMP
puts "Retrieving team list for #{EVENT}"
@teams = TBA.get_event_teams EVENT
@teams.sort_by! { |t| t['team_number'] }

# Retrive match data for the teams
puts "Getting data for teams..."
@data = @teams.map do |t|
  puts "Team #{t['team_number']}: #{t['nickname']}"
  TBA.get_team t['team_number']
end

CSV.open("data/#{EVENT}.csv", 'w') do |csv|
  # Header row
  csv << ['Team #', 'Name', 'Wins', 'Losses', 'Ties', 'Win/Loss Ratio', 'High Score (Q)', 'Average Score (Q)', 'High Score (E)', 'Average Score (E)', 'Awards']
  @data.each do |t|
    row = []
    row << t['team_number']
    row << t['nickname']
    
    wins = losses = ties = 0
    qual_scores = []
    elim_scores = []
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

        if m['comp_level'] == 'qm'
          qual_scores << team_score
        else
          elim_scores << team_score
        end

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
    row << (wins.to_f / losses.to_f).round(2)
    row << qual_scores.max
    row << ((qual_scores.inject(0) { |sum, score| sum += score }) / qual_scores.count)
    row << elim_scores.max
    row << ((elim_scores.inject(0) { |sum, score| sum += score }) / elim_scores.count)

    row << awards.join('; ')
    
    csv << row
  end
end

