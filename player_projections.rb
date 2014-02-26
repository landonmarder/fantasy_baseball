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
    @batters.each do |batter|
      player_info = batter['name']['text']
      name = player_info.split('.')[-1].split(',')[0][1..-1]
      positions = []

      find_positions(positions, player_info)
      puts "#{name}: #{positions}"
    end
  end


  private

  def find_positions(arr, player)
    POSITIONS.map { |position|
      arr << position if player.gsub(',','').split(' ').include?(position)
    }
  end
end

x = PlayerProjections.new
x.parse_batters
