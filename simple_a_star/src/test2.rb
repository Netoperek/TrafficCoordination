require_relative 'state_vertex'
require_relative 'generic_a_star'
require_relative '../helpers/data_helper'
require_relative 'road'
require 'pry'

states = states_from_file '../start_states_file'
states_attributes = states[:attributes]
data = states[:data]

roads = roads_from_file '../roads_file'
roads_attributes = roads[:attributes]
roads_data = roads[:data]
roads_data.map! { |ele| Road.new(roads_attributes, ele) }

start_vertex = StatesVertex.new(states_attributes, data)

binding.pry

heuristic_function = Proc.new do |states_vertex|
  result = states_vertex.states.map { |ele| ele.state[:velocity] + ele.state[:acceleration }
  result.reduce(:+)
end
