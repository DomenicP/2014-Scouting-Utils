require 'open-uri'
require 'nokogiri'
require 'sequel'

module FRCSpy
  URL = "http://www.chiefdelphi.com/forums/frcspy.php?xml=2"
  DB = Sequel.connect('sqlite://data/matches/matches.sqlite3')

  def self.setup_database
    DB.drop_table? :matches
    DB.create_table :matches do
      primary_key  :id
      DateTime     :pubdate
      String       :event
      String       :type
      Integer      :count
      Integer      :red_score
      Integer      :blue_score
      Integer      :red1
      Integer      :red2
      Integer      :red3
      Integer      :blue1
      Integer      :blue2
      Integer      :blue3
      Integer      :red_foul
      Integer      :blue_foul
      Integer      :red_auto
      Integer      :blue_auto
      Integer      :red_teleop
      Integer      :blue_teleop
    end
  end

  def self.parse_xml path
    puts "Reading XML"
    doc = Nokogiri::XML open(path)
    puts "Parsing Matches"
    match_data = doc.css('match').map do |xml|
      m = {}
      m[:pubdate] = DateTime.strptime(xml.at_css('pubdate').content,
                                      "%a, %d %b %Y %T")
      m[:event] = xml.at_css('event').content
      m[:type] = xml.at_css('typ').content
      m[:count] = xml.at_css('mch').content.to_i
      m[:red_score] = xml.at_css('rfin').content
      m[:blue_score] = xml.at_css('bfin').content.to_i
      m[:red1] = xml.at_css('red1').content.to_i
      m[:red2] = xml.at_css('red2').content.to_i
      m[:red3] = xml.at_css('red3').content.to_i
      m[:blue1] = xml.at_css('blue1').content.to_i
      m[:blue2] = xml.at_css('blue2').content.to_i
      m[:blue3] = xml.at_css('blue3').content.to_i
      m[:red_foul] = xml.at_css('rfpts').content.to_i
      m[:blue_foul] = xml.at_css('bfpts').content.to_i
      m[:red_auto] = xml.at_css('rhpts').content.to_i
      m[:blue_auto] = xml.at_css('bhpts').content.to_i
      m[:red_teleop] = xml.at_css('rtpts').content.to_i
      m[:blue_teleop] = xml.at_css('btpts').content.to_i
      m
    end
    puts "Inserting records into database"
    match_data.each { |m| DB[:matches].insert m }
  end

  def self.update
    setup_database
    parse_xml URL
  end
  
  def self.matches_for_event(code)
    DB[:matches].where :event => code
  end

  def self.matches_for_team(num)
    DB[:matches].where Sequel.or(:red1 => num, :red2 => num, :red3 => num,
                                 :blue1 => num, :blue2 => num, :blue3 => num)
  end
end

