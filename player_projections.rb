require 'rest_client'
require 'json'
require 'pry'
require 'csv'

class PlayerProjections

  POSITIONS = %w{1B 2B SS C 3B OF DH SP RP}
  AUCTION_DOLLARS = 260 * 12
  AUCTIONABLE_PLAYERS = 150

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
    parse_auction_values(players)
    calculate_league_values(players)

    CSV.open("projections/batters_updated.csv", 'wb') do |csv|
      csv << batters.first.keys
      batters.each do |hash|
        csv << hash.values
      end
    end
    puts "---------------"
    puts "Batters updated!"
    CSV.open("projections/pitchers_updated.csv", 'wb') do |csv|
      csv << pitchers.first.keys
      pitchers.each do |hash|
        csv << hash.values
      end
    end
    puts "Pitchers updated!"

    CSV.open("projections/fantasy_baseball_auction-#{Time.new.month.to_s+"-"+Time.new.day.to_s+"-"+Time.new.year.to_s}.csv", 'wb') do |csv|
      csv << ["Name", "Position","Total Points", "League Value", "ESPN Value", "Perceived Value"]
      players.each do |hash|
        csv << [hash[:name], hash[:position], hash[:total_points], hash[:league_value], hash[:espn_auction_value], hash[:perceived_value]]
      end
    end
    puts "Projections can be found in projections/fantasy_baseball_auction-#{Time.new.month.to_s+"-"+Time.new.day.to_s+"-"+Time.new.year.to_s}.csv"
  end

  private

  def calculate_league_values(players)
    cost_per_point = cost_per_point(players)
    players.each do |player|
      player[:espn_auction_value] = 0 if player[:espn_auction_value] == nil
      player[:league_value] = player[:total_points] / cost_per_point
      player[:perceived_value] = player[:league_value] - player[:espn_auction_value]
    end
  end

  def cost_per_point(players)
    total_inplay_points(players) / AUCTION_DOLLARS
  end

  def total_inplay_points(players)
    sum = 0
    players[0..AUCTIONABLE_PLAYERS].each do |player|
      sum += player[:total_points]
    end
    sum
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

  def parse_auction_values(players)
    CSV.foreach('espn_auction_values.csv') do |row|
      puts "#{row[0]}"
      auction_value = row[2].gsub('$','').split('/')[1].to_i
      players.each do |player|
        player[:espn_auction_value] = auction_value if player[:name] == row[0]
      end
    end
  end

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
