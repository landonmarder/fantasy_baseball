require 'rest_client'
require 'json'
# require 'pry'

response = RestClient.get 'http://www.kimonolabs.com/api/bt868shs?apikey=455e95d967d14e53ad7188d10746bcf6'

json = JSON.parse(response)

batters = json['results']['collection1']
# binding.pry
