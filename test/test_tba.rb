require 'scouting/tba'
require 'minitest/autorun'

class TestTBA < Minitest::Unit::TestCase
  def test_get_team
    team = TBA.get_team 316
    assert_equal team['team_number'], 316
  end

  def test_get_event_list
    events = TBA.get_event_list 1996
    expected = ["1996cmp", "1996nh"]
    assert_equal events, expected
  end

  def test_get_event
    event = TBA.get_event "2014paphi"
    assert_equal event['short_name'], "Springside Chestnut Hill"
    assert_raises(TBA::NotFoundError) { TBA.get_event "2014test"}
  end

  def test_get_event_teams
    teams = TBA.get_event_teams "2014paphi"
    assert_equal teams.count, 34
  end

  def test_get_event_matches
    matches = TBA.get_event_matches "2014paphi"
    assert_equal matches.count, 87
  end
end
