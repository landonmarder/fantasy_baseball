require 'rest_client'
require 'json'
require 'pry'

class PlayerProjections

  POSITIONS = %w{1B 2B SS C 3B OF DH}

  def initialize
    response_batters = RestClient.get 'http://www.kimonolabs.com/api/bt868shs?apikey=455e95d967d14e53ad7188d10746bcf6'
    json_batters = JSON.parse(response_batters)
    @batters = json_batters['results']['collection1']
  end

  def parse_batters
    batters = []
    @batters.each do |batter|
      player_info = batter['name']['text']
      positions = []

      find_positions(positions, player_info)


      batters << {name: find_name(player_info), position: positions.join(', '),
                  at_bats: batter['ab'].to_i, runs: batter['r'].to_i,
                  home_runs: batter['hr'].to_i, rbi: batter['rbi'].to_i,
                  stolen_bases: batter['sb'].to_i, walks: batter['bb'].to_i,
                  strike_outs: batter['k'].to_i, total_bases_non_hr: total_bases_non_hr(batter['slg'].to_f, batter['ab'].to_i, batter['hr'].to_i)
                }

      binding.pry
    end
    batters
  end


  private

  def find_positions(arr, player)
    POSITIONS.map { |position|
      arr << position if player.gsub(',','').split(' ').include?(position)
    }
  end

  def find_name(player)
    x = player.split('.')
    x.shift
    name = x.join('').split(',')[0][1..-1]
  end

  def total_bases_non_hr(slg, ab, hr)
    (slg * ab) - (hr * 4)
  end
end

x = PlayerProjections.new
x.parse_batters
