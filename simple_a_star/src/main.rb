require_relative 'states_vertex'
require_relative 'generic_a_star'
require_relative '../helpers/data_helper'
require_relative 'road'
require 'csv'
require 'json'
require 'pry'

unless ARGV[0] && ARGV[1]
  puts 'USAGE: ruby main.rb ../start_states_file ../roads_file'
  exit
end

cars_states_file = ARGV[0]
roads_states_file = ARGV[1]

data = CSV.read('../plus_max_acceleration')
PLUS_MAX_ACCELERATION = data.last.last.to_i

states = states_from_file cars_states_file
states_attributes = states[:attributes]
data = states[:data]

roads = roads_from_file roads_states_file
roads_attributes = roads[:attributes]
roads_data = roads[:data]
roads_data.map! { |ele| Road.new(roads_attributes, ele) }

start_vertex = StatesVertex.new(states_attributes, data)

# Win if all cars are on desired roads
#
win_function = Proc.new do |states_vertex|
  result = states_vertex.states.map do |state|
     (state.state[:position] > state.state[:final_position] && state.state[:direction] == 1) || \
     (state.state[:position] < state.state[:final_position] && state.state[:direction] == -1)
  end
  result.reduce(:&)
end

# Adding velocity
#
heuristic_function = Proc.new do |states_vertex|

  # Maximum acceleration - time stamp heurestic function
  #
  states = states_vertex.states.map { |ele| ele.state }
  time_stamps = []
  states.each do |ele|
    time_stamps_number = 0
    state = ele.clone
    while (state[:direction] == 1 && state[:position] <= state[:final_position]) \
            || (state[:position] >= state[:final_position] && state[:direction] == -1)
      state[:velocity] += PLUS_MAX_ACCELERATION
      state[:position] += state[:velocity] * state[:direction]
      time_stamps_number += 1
    end
  time_stamps.push(time_stamps_number)
  end
  time_stamps.reduce(:+)
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
puts time
