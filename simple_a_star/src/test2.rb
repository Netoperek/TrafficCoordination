require_relative 'states_vertex'
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

# Win if all cars are on desired roads
#
win_function = Proc.new do |states_vertex|
  result = states_vertex.states.map { |state| state.state[:final_road_nr] == state.state[:current_road_nr] }
  result.reduce(:&)
end

# Adding velocity and acceleration of each car
#
heuristic_function = Proc.new do |states_vertex|
  result = states_vertex.states.map { |ele| ele.state[:velocity] + ele.state[:acceleration] }
  100 / result.reduce(:+).to_f
end

reconstruct_path_function = Proc.new do |came_from, current_node, start|
  path ||=[]
  if came_from.keys.include? current_node
    path = reconstruct_path_function.call(came_from, came_from[current_node], start)
    path.push current_node
  else
    [start]
  end
end

astar = AStar.new(StatesVertex)
result = astar.a_star(start_vertex, heuristic_function, win_function, reconstruct_path_function)
result = result.map { |ele| ele.states }
result = result.map { |states| states.map { |state| state.state } }

result.each_with_index do |ele, index|
  puts index
  puts ele
  puts ""
end
