require_relative 'simple_a_star/helpers/data_helper'
require_relative 'simple_a_star/src/road'
require_relative 'simple_a_star/src/states_vertex'
require 'set'
require 'json'
require 'ruby-graphviz'
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

    while size > 0
      car_nr = nil
      car_nr = car_state.first.state[:car_nr] unless car_state.first.nil?
      node = { :name => size, :road_nr => road[:road_nr], :car_nr => car_nr } 
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
      target = crossing_nodes[-node.to_i] if target.nil?
      link = { :source => crossroads_hash[ele], :target => target }
      links.push(link)
    end
  end

  result = { 'nodes' => nodes, 'links' => links }
end

def random_hex_color(colors_set)
  while true
    color = "#" + "%06x" % (rand * 0xffffff)
    break unless colors_set.include?(color)
  end
  colors_set.add(color)
  color
end

def print_graph(outcome, index, colors_roads_hash)
  colors_set = Set.new
  g = GraphViz.new(:G, :type => :digraph, :use => 'neato' )
  nodes = []
  color = 'black'
  outcome["nodes"].each do |node|
    if node[:road_nr].is_a?(Integer) && !colors_roads_hash.keys.include?(node[:road_nr])
      color = random_hex_color(colors_set)
      colors_roads_hash[node[:road_nr]] = color
    elsif node[:road_nr].is_a?(Integer)
      color = colors_roads_hash[node[:road_nr]]
    end
    node_name_suffix = node[:road_nr].to_s
    node_name_suffix = node[:road_nr].to_s if node[:road_nr].is_a?(Integer)
    unless node[:car_nr].nil?
      nodes.push(g.add_nodes('car#' + node[:car_nr].to_s, :color => 'red', :fillcolor => color, :style => :filled, :penwidth => 4.0))
    else
      nodes.push(g.add_nodes(node[:name].to_s + "#" + node_name_suffix, :color => 'black', :fillcolor => color, :style => :filled, :penwidth => 1.0))
    end
  end
  outcome["links"].each do |link|
    source = link[:source]
    target = link[:target]
    source = nodes[source]
    target = nodes[target]
    g.add_edges(source, target, :arrowhead => :none)
  end
  g.output( :png => "output/hello_world#{index}.png" )
end

def apply_changing_states(core_outcome, graph)
  colors_roads_hash = {}
  file = File.read(core_outcome) 
  cars_states = JSON.parse(file)
  index = 0
  cars_states.each do |states|
    index += 1
    graph["nodes"].each do |node|
      node[:car_nr] = nil
      states.each do |car_state|
        if car_state["current_road_nr"] == node[:road_nr] && car_state["position"] == node[:name]
          node[:car_nr] = car_state['car_nr']
        end 
        if node[:road_nr].is_a?(String) && node[:road_nr].split().include?(car_state["current_road_nr"].to_s) && car_state["position"] == node[:name]
          node[:car_nr] = car_state['car_nr']
        end 
      end
    end
    print_graph(graph, index, colors_roads_hash)
    # File.open("simulator/output/#{index}.json", 'w') { |file| file.write(JSON.pretty_generate(graph)) }
  end
end

data = data_from_files('simple_a_star/start_states_file', 'simple_a_star/roads_file')
outcome = base_json(data[:cars_states], data[:roads_states])
apply_changing_states('core_out.json', outcome)
