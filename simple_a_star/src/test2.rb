require_relative 'states_vertex'
require_relative 'generic_a_star'
require_relative '../helpers/data_helper'
require_relative 'road'
require 'json'
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
  result = states_vertex.states.map { |state| state.state[:position] > state.state[:final_position] }
  result.reduce(:&)
end

# Adding velocity
#
# kiedy bym przyspieszal maksymalnie to kiedy dojade celu
# i zwracam najgorsze
heuristic_function = Proc.new do |states_vertex|
  result = states_vertex.states.map { |ele| ele.state[:velocity] }
  (100 / result.reduce(:+).to_f).abs
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

start = Time.now
result = astar.a_star(start_vertex, heuristic_function, win_function, reconstruct_path_function)
finish = Time.now
time = finish - start

result = result.map { |ele| ele.states }
result = result.map { |states| states.map { |state| state.state } }
result_json = JSON.pretty_generate(result)
File.open('../../core_out.json', 'w') { |file| file.write(result_json) }

File.open('../../human_core_out.json', 'w') do |file|
  result.each_with_index do |ele, index|
    file.puts(index+1)
    file.puts(ele)
  end
  file.puts("It took: #{time} s")
end