require 'rest_client'
require 'json'
require 'pry'
require 'csv'

class PlayerProjections

  POSITIONS = %w{1B 2B SS C 3B OF DH SP RP}

  def initialize()
    response_batters = RestClient.get 'http://www.kimonolabs.com/api/bt868shs?apikey=455e95d967d14e53ad7188d10746bcf6'
    json_batters = JSON.parse(response_batters)
    @batters = json_batters['results']['collection1']

    pitchers_response = RestClient.get 'http://www.kimonolabs.com/api/9ks1v5fg?apikey=455e95d967d14e53ad7188d10746bcf6'
    json_pitchers = JSON.parse(pitchers_response)
    @pitchers = json_pitchers['results']['collection1']
  end

  def to_csv
    pitchers = parse_pitchers
    batters = parse_batters
    players = pitchers + batters
    players.sort_by! { |player| -player[:total_points] }

    CSV.open('batters_updated.csv', 'wb') do |csv|
      csv << batters.first.keys
      batters.each do |hash|
        csv << hash.values
      end
    end
    puts "Batters updated"
    CSV.open('pitchers_updated.csv', 'wb') do |csv|
      csv << pitchers.first.keys
      pitchers.each do |hash|
        csv << hash.values
      end
    end
    puts "Pitchers updated"
    CSV.open('players_updated.csv', 'wb') do |csv|
      csv << players.first.keys
      players.each do |hash|
        csv << hash.values
      end
    end
    puts "Total players updated"
  end

  def parse_pitchers
    pitchers = []
    @pitchers.each do |pitcher|
      player_info = pitcher['name']['text']
      positions = []

      find_positions(positions, player_info)

      pitchers << { name: find_name(player_info), position: positions.join(', '),
                  innings: pitcher['ip'].to_f, saves: pitcher['save'].to_i,
                  walks_hits: walks_and_hits(pitcher['whip'].to_f, pitcher['ip'].to_f),
                  strike_outs: pitcher['k'].to_i, earned_runs: earned_runs(pitcher['era'].to_f, pitcher['ip'].to_f),
                  wins: pitcher['win'].to_i,
                  total_points: pitcher_total_points(pitcher['ip'].to_f, pitcher['w'].to_i, pitcher['sv'].to_i, walks_and_hits(pitcher['whip'].to_f, pitcher['ip'].to_f), earned_runs(pitcher['era'].to_f, pitcher['ip'].to_f), pitcher['k'].to_i ) }
    end
    pitchers
  end

  private

  def parse_batters
    batters = []
    @batters.each do |batter|
      player_info = batter['name']['text']
      positions = []

      find_positions(positions, player_info)

      batters << { name: find_name(player_info), position: positions.join(', '),
                  at_bats: batter['ab'].to_i, runs: batter['runs'].to_i,
                  home_runs: batter['hr'].to_i, rbi: batter['rbi'].to_i,
                  stolen_bases: batter['sb'].to_i, walks: batter['bb'].to_i,
                  strike_outs: batter['k'].to_i,
                  total_bases_non_hr: total_bases_non_hr(batter['slg'].to_f, batter['ab'].to_i, batter['hr'].to_i),
                  total_points: hitter_total_points(batter['ab'].to_i, batter['runs'].to_i, total_bases_non_hr(batter['slg'].to_f, batter['ab'].to_i, batter['hr'].to_i), batter['hr'].to_i, batter['rbi'].to_i, batter['sb'].to_i, batter['bb'].to_i, batter['k'].to_i) }
    end
    batters
  end

  def find_positions(arr, player)
    POSITIONS.map { |position|
      arr << position if player.gsub(',','').split(' ').include?(position)
    }
  end

  def find_name(player)
    x = player.split('.')
    x.shift
    x.join('').split(',')[0][1..-1]
  end

  def total_bases_non_hr(slg, ab, hr)
    (slg * ab) - (hr * 4)
  end

  def hitter_total_points(ab, r, tb, hr, rbi, sb, bb, k)
    (-0.5 * ab) + (1.0 * r) + (1.2533 * tb) + (4.5 * hr) + (1.0 * rbi) + (2.0 * sb) + (1.0 * bb) + (-0.7 + k)
  end

  def walks_and_hits(whip, ip)
    whip * ip
  end

  def earned_runs(era, ip)
    (era / 9.0) * ip
  end

  def pitcher_total_points(ip, w, sv, h_bb, er, k)
    (2.0 * ip) + (4.0 * w) + (2.5 * sv) + (-1.0 * h_bb) + (-3.0 * er) + (1.0 * k)
  end
end

x = PlayerProjections.new()
x.to_csv
