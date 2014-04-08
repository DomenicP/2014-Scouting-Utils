require 'net/http'
require 'json'

module TBA
  X_TBA_APP_ID = 'domenic316:tba-ruby:0.1'
  API_URL_BASE = 'http://www.thebluealliance.com/api/v2'

  class NotFoundError < StandardError; end

  def self.get_team(number, year = 2014)
    make_request "/team/frc#{number}/#{year}"
  end

  def self.get_event_list(year)
    make_request "/events/#{year}"
  end

  def self.get_event(event_code)
    make_request "/event/#{event_code}"
  end

  def self.get_event_teams(event_code)
    make_request "/event/#{event_code}/teams"
  end

  def self.get_event_matches(event_code)
    make_request "/event/#{event_code}/matches"
  end

  def self.make_request(path)
    uri = URI(API_URL_BASE + path)
    
    res = Net::HTTP.start(uri.host, uri.port) do |http|
      req = Net::HTTP::Get.new uri
      req['X-TBA-App-Id'] = X_TBA_APP_ID
      http.request req
    end

    if res.is_a? Net::HTTPSuccess
      JSON.parse res.body
    elsif res.is_a? Net::HTTPNotFound
      raise NotFoundError
    else
      raise "Error: request returned response code #{res.code}"
    end
  end
end
