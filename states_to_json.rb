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
    car_state = cars_states.select { |ele| ele.state[:current_road_nr] == road_nr }
    position = nil
    unless car_state.first.nil?
      position = car_state.first.state[:position] if car_state.first.state[:current_road_nr] == road[:road_nr]
    end

    while size > 0
      if !position.nil? && position == size
        node = { :name => size, :road_nr => -road[:road_nr] } 
      else
        node = { :name => size, :road_nr => road[:road_nr] } 
      end
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

    if node_road_nr.abs == next_node_road_nr.abs
      link = { :source => i, :target => i+1 }
      links.push(link)
    end
    crossing_nodes[next_node[:road_nr]] = i+1 if next_node[:name] == 1
  end
  
  crossing_nodes.values.each do |i|
    road = roads_states.select { |ele| ele.state[:road_nr] == nodes[i][:road_nr].abs }
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
      target = crossing_nodes[-node.to_i] if target.nil?
      link = { :source => crossroads_hash[ele], :target => target }
      links.push(link)
    end
  end

  result = { 'nodes' => nodes, 'links' => links }
end

def apply_changing_states(core_outcome, graph)
  file = File.read(core_outcome) 
  cars_states = JSON.parse(file)
  index = 0
  cars_states.each do |states|
    index += 1
    graph["nodes"].each do |node|
      node[:road_nr] *= -1 if node[:road_nr].is_a?(Integer) && node[:road_nr] < 0 
      states.each do |car_state|
        if car_state["current_road_nr"] == node[:road_nr] && car_state["position"] == node[:name]
          node[:road_nr] *= -1
        end 
      end
    end
    File.open("simulator/output/#{index}.json", 'w') { |file| file.write(JSON.pretty_generate(graph)) }
  end
  
end

data = data_from_files('simple_a_star/start_states_file', 'simple_a_star/roads_file')
outcome = base_json(data[:cars_states], data[:roads_states])
outcome_json = JSON.pretty_generate(outcome)
File.open('simulator/out.json', 'w') { |file| file.write(outcome_json) }

apply_changing_states('core_out.json', outcome)
