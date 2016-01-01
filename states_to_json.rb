require_relative 'simple_a_star/helpers/data_helper'
require_relative 'simple_a_star/src/road'
require_relative 'simple_a_star/src/states_vertex'
require 'set'
require 'json'
require 'pry'

def data_from_files(start_states_file, roads_file)
  states = states_from_file 'simple_a_star/start_states_file'
  states_attributes = states[:attributes]
  data = states[:data]
  start_vertex = StatesVertex.new(states_attributes, data)

  roads = roads_from_file 'simple_a_star/roads_file'
  roads_attributes = roads[:attributes]
  roads_states = roads[:data]
  roads_states.map! { |ele| Road.new(roads_attributes, ele) }

  cars_states = start_vertex.states
  { :cars_states => cars_states,
    :roads_states => roads_states }
end

def base_json(cars_states, roads_states)
  crossroads_set = Set.new
  nodes = []
  links = []

  roads_states.each do |ele|
    road = ele.state
    size = road[:size]
    road_nr = road[:road_nr]

    while size > 0
      node = { :name => size, :road_nr => road[:road_nr] } 
      nodes.push(node)
      size -= 1
    end
  end

  i = -1
  crossing_nodes = {}
  crossroads_hash = {}
  while i < nodes.size-2
    i += 1
    node = nodes[i]
    next_node = nodes[i+1]
    node_road_nr = node[:road_nr]
    next_node_road_nr = next_node[:road_nr]

    if node_road_nr == next_node_road_nr
      link = { :source => i, :target => i+1 }
      links.push(link)
    end
    crossing_nodes[next_node[:road_nr]] = i+1 if next_node[:name] == 1
  end
  
  crossing_nodes.values.each do |i|
    road = roads_states.select { |ele| ele.state[:road_nr] == nodes[i][:road_nr] }
    cuts = road.first.state[:cuts]
    cuts.push(road.first.state[:road_nr])
    crossroads = cuts.sort.join(" ")
    unless crossroads_set.include? crossroads
      crossroads_set.add(crossroads)
      node = { :road_nr => crossroads, :name => 0 }
      nodes.push(node)
      crossroads_hash[crossroads] = nodes.size-1
    end
  end

  crossroads_set.each do |ele|
    ele.split().each do |node|
      target = crossing_nodes[node.to_i]
      link = { :source => crossroads_hash[ele], :target => target }
      links.push(link)
    end
  end

  result = { 'nodes' => nodes, 'links' => links }
  JSON.pretty_generate(result)
end

data = data_from_files('simple_a_star/start_states_file', 'simple_a_star/roads_file')
outcome = base_json(data[:cars_states], data[:roads_states])
File.open('simulator/out.json', 'w') { |file| file.write(outcome) }

