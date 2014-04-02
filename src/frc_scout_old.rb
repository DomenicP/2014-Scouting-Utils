#!/usr/bin/env ruby

require 'open-uri'
require 'nokogiri'
require 'pry'
require 'csv'

class Match
  attr_accessor :timestamp, :event, :type, :count, :red_score, :blue_score,
                :red1, :red2, :red3, :blue1, :blue2, :blue3,
                :red_foul, :blue_foul, :red_auto, :blue_auto, :red_teleop, :blue_teleop

  def parse_xml xml
    @timestamp = DateTime.strptime(xml.at_css("pubdate").content, "%a, %d %b %Y %T")
    @event = xml.at_css('event').content
    @type = xml.at_css('typ').content
    @count = xml.at_css('mch').content.to_i
    @red_score = xml.at_css('rfin').content.to_i
    @blue_score = xml.at_css('bfin').content.to_i
    @red1 = xml.at_css('red1').content.to_i
    @red2 = xml.at_css('red2').content.to_i
    @red3  = xml.at_css('red3').content.to_i
    @blue1 = xml.at_css('blue1').content.to_i
    @blue2 = xml.at_css('blue2').content.to_i
    @blue3 = xml.at_css('blue3').content.to_i
    @red_foul = xml.at_css('rfpts').content.to_i
    @blue_foul = xml.at_css('bfpts').content.to_i
    @red_auto = xml.at_css('rhpts').content.to_i
    @blue_auto = xml.at_css('bhpts').content.to_i
    @red_teleop = xml.at_css('rtpts').content.to_i
    @blue_teleop = xml.at_css('btpts').content.to_i
    return self
  end
  
  def print
    printf "========================================\n"
    printf "| Event: %-18s Match: %-3s |\n", @event, @type + @count.to_s
    printf "|--------------------------------------|\n"
    printf "| Red: %-12d Blue: %-13d|\n", @red_score, @blue_score
    printf "|  %4d %4d %4d    %4d %4d %4d    |\n", @red1, @red2, @red3, @blue1, @blue2, @blue3
    printf "|--------------------------------------|\n"
    printf "| Red Auto: %5d     Blue Auto: %5d |\n", @red_auto, @blue_auto
    printf "| Red Teleop: %3d     Blue Teleop: %3d |\n", @red_teleop, @blue_teleop
    printf "| Red Foul: %5d     Blue Foul: %5d |\n", @red_foul, @blue_foul
    printf "========================================\n"
    puts
  end

  def winning_score(penalties=true)
    red = penalties ? @red_score : @red_score - @red_foul
    blue = penalties ? @blue_score : @blue_score - @blue_foul
    @red_score > @blue_score ? red : blue;
  end

  def loosing_score(penalties=true)
    red = penalties ? @red_score : @red_score - @red_foul
    blue = penalties ? @blue_score : @blue_score - @blue_foul
    @red_score < @blue_score ? red : blue;
  end

  def combined_score(penalties=true)
    penalties ? @red_score + @blue_score : @red_score - @red_foul + @blue_score - @blue_foul
  end

  def score_difference(penalties=true)
    winning_score(penalties) - loosing_score(penalties)
  end
end

class MatchSet
  attr_accessor :matches

  def self.parse_xml path
    doc = Nokogiri::XML open(path)
    matches = []
    doc.css('match').each do |m|
      matches << Match.new.parse_xml(m)
    end
    return MatchSet.new(matches)
  end

  def initialize(matches)
    @matches = matches
  end

  def [](i)
    @matches[i]
  end

  def first
    @matches.first
  end

  def last
    @matches.last
  end

  def count
    @matches.count
  end

  def each(&block)
    @matches.each(&block)
  end
  
  def practice_matches
    MatchSet.new @matches.select { |m| m.type == 'P' }
  end

  def qualification_matches
    MatchSet.new @matches.select { |m| m.type == 'Q' }
  end

  def elimination_matches
    MatchSet.new @matches.select { |m| m.type == 'E' }
  end

  def penalty_free_matches
    MatchSet.new @matches.select { |m| m.red_foul == 0 && m.blue_foul == 0 }
  end

  def matches_for_event(event)
    MatchSet.new @matches.select { |m| m.event == event }
  end

  def sort_by_winning_score(penalties=true)
    MatchSet.new @matches.sort { |b, a| a.winning_score(penalties) <=> b.winning_score(penalties) }
  end

  def sort_by_combined_score(penalties=true)
    MatchSet.new @matches.sort { |b, a| a.combined_score(penalties) <=> b.combined_score(penalties) }
  end

  def sort_by_score_difference(penalties=true)
    MatchSet.new @matches.sort { |b, a| a.score_difference(penalties) <=> b.score_difference(penalties) }
  end

  def average_score
    @matches.inject(0) { |s, m| s + m.red_score + m.blue_score } / (@matches.count * 2)
  end

  def average_winning_score(penalties=true)
    sum = 0
    @matches.each { |m| sum += m.winning_score(penalties) }
    sum / @matches.count
  end

  def average_loosing_score(penalties=true)
    sum = 0
    @matches.each { |m| sum += m.loosing_score(penalties) }
    sum / @matches.count
  end

  def median_score
    scores = @matches.inject([]) { |acc, m| acc << m.red_score << m.blue_score }.sort
    scores[(scores.count / 2.0).ceil]
  end

  def average_penalties
    fouls = @matches.inject([]) do |acc, m|
        acc << m.red_foul unless m.red_foul == 0
        acc << m.blue_foul unless m.blue_foul == 0
        acc
    end
    fouls.inject(0) { |s, f| s + f } / fouls.count
  end

  def median_penalties
    fouls = @matches.inject([]) do |acc, m|
      acc << m.red_foul unless m.red_foul == 0
      acc << m.blue_foul unless m.blue_foul == 0
      acc
    end.sort
    fouls[(fouls.count / 2.0).ceil]
  end

  def print_all
    @matches.each { |m| m.print }
  end

  def to_csv path
    CSV.open(path, "w") do |csv|
      csv <<  @matches.first.instance_variables.inject([]) { |acc, v| acc << v.to_s[1..-1]; acc }
      @matches.each do |m|
        csv << m.instance_variables.inject([]) { |acc, v| acc << m.instance_variable_get(v); acc }
      end
    end
  end
end

def stats(matches)
  puts "Most recent match:"
  matches.first.print
  matches.to_csv "matches.csv"

  result = matches.sort_by_winning_score
  puts "Highest scoring match: #{result.first.winning_score}"
  result.first.print

  result = matches.sort_by_winning_score(false)
  puts "Highest scoring match (minus penalties): #{result.first.winning_score(false)}"
  result.first.print

  result = matches.penalty_free_matches.sort_by_winning_score
  puts "Highest scoring penalty-free match: #{result.first.winning_score}"
  result.first.print

  result = matches.sort_by_combined_score
  puts "Highest combined score: #{result.first.combined_score}"
  result.first.print

  result = matches.sort_by_score_difference
  puts "Largest score difference: #{result.first.score_difference}"
  result.first.print

  result = matches.sort_by_score_difference(false)
  puts "Largest score difference (without penalties): #{result.first.score_difference(false)}"
  result.first.print

  puts "Matches played: #{matches.count}"
  puts "Penalty free matches: #{matches.penalty_free_matches.count}"
  printf "Percentage of matches without penalties: %.2f%%\n", (matches.penalty_free_matches.count.to_f/matches.count.to_f)*100.0
  puts "Average score: #{matches.average_score}"
  puts "Average winning score: #{matches.average_winning_score}"
  puts "Average loosing score: #{matches.average_loosing_score}"
  puts "Median score: #{matches.median_score}"
  puts "Average foul points (both alliances): #{matches.average_penalties}"
  puts "Median foul points: #{matches.median_penalties}"
end

URL = "http://www.chiefdelphi.com/forums/frcspy.php?xml=2"
@matches = MatchSet::parse_xml(URL)
@matches.to_csv "matches.csv"
@quals = @matches.qualification_matches
@elims = @matches.elimination_matches
#stats(@quals)
#stats(@elims)
