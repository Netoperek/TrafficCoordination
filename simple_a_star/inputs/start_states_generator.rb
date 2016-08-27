require_relative '../helpers/data_helper'
require_relative '../src/road'
require 'pry'

unless ARGV[0]
  puts 'USAGE: ruby start_states_generator joads_file'
  exit
end

roads = roads_from_file(ARGV[0])
roads_attributes = roads[:attributes]
$roads_data = roads[:data]
$roads_data.map! { |ele| Road.new(roads_attributes, ele) }
$roads_size = roads.size

$pos_taken = {}

def random_car_pos(car_nr)
  road_nr = rand(1..$roads_size)
  road = $roads_data[road_nr-1].state
  road_size = road[:size]

  while true
    unless $pos_taken[road_nr: road_nr]
      $pos_taken[road_nr: road_nr] = car_nr
    end
  end
end

binding.pry
