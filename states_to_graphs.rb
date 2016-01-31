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

def base_json(cars_states, roads_states, colors_cars_hash)
  colors_set = Set.new
  cars_nr = cars_states.map { |ele| ele.state[:car_nr] }
  cars_nr.each.map { |car_nr| colors_cars_hash[car_nr] = random_hex_color(colors_set) }

  crossroads_set = Set.new
  nodes = []
  links = []

  roads_states.each do |ele|
    road = ele.state
    size = road[:size]
    road_nr = road[:road_nr]
    car_state = cars_states.select { |ele| ele.state[:current_road_nr] == road_nr }

    i = 0
    while i < size
      car_nr = nil
      car_nr = car_state.first.state[:car_nr] unless car_state.first.nil?
      node = { :name => i+1, :road_nr => road[:road_nr], :car_nr => car_nr } 
      nodes.push(node)
      i += 1
    end
  end

  crossing_nodes = Set.new
  crossroads = roads_states.map { |ele| { :road_nr => ele.state[:road_nr] , :cuts => ele.state[:cuts] } }
  crossroads.each do |ele|
    road_nr = ele[:road_nr]
    cuts = ele[:cuts]
    cuts.each do |cut|
      crossing_road_nr = cut[:road_nr]
      node_a = nodes.find_index { |node| node[:name] == cut[:crossroad] && node[:road_nr] == road_nr }
      crossroad = crossroads.select { |cross| cross[:road_nr] == crossing_road_nr }
      cut = crossroad.first[:cuts].select { |ele| ele[:road_nr] == road_nr }
      cut = cut.first[:crossroad]
      node_b = nodes.find_index { |node| node[:name] == cut && node[:road_nr] == crossing_road_nr}
      crossing_nodes.add([node_b, node_a].sort)
    end
  end

  crossroads_indices = []
  crossing_nodes.each do |ele|
    nodes.delete_at(ele[0])
    nodes.delete_at(ele[1]-1)
    node = { :name => "#{ele[0]-1}-#{ele[1]-2}", :road_nr => "#{ele[0]}-#{ele[1]}", :car_nr => -1 } 
    nodes.push(node)
    links.delete_if { |e| e[:source] == ele[0] || e[:target] == ele[0] }
    links.delete_if { |e| e[:source] == ele[1] || e[:target] == ele[1] }
    crossroads_indices.push(nodes.size-1)
  end

  i = -1
  while i < nodes.size-2
    i += 1
    node = nodes[i]
    next_node = nodes[i+1]
    node_road_nr = node[:road_nr]
    next_node_road_nr = next_node[:road_nr]

    if node_road_nr == next_node_road_nr && node[:name] == next_node[:name]-1
      link = { :source => i, :target => i+1 }
      links.push(link)
    end
  end

  crossroads_indices.each do |ele|
    crossroad_node = nodes[ele][:name]
    node_a = crossroad_node.split('-')[0].to_i
    node_b = crossroad_node.split('-')[1].to_i
    link = { :source => node_a, :target => ele }
    links.push(link)
    link = { :source => ele, :target => node_a+1 }
    links.push(link)
    link = { :source => node_b, :target => ele }
    links.push(link)
    link = { :source => ele, :target => node_b+1 }
    links.push(link)
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

def print_graph(outcome, index, colors_roads_hash, colors_cars_hash)
  colors_set = Set.new
  g = GraphViz.new(:G, :type => :digraph, :use => 'neato')
  nodes = []
  color = 'black'

  outcome["nodes"].each do |node|
    if node[:road_nr].is_a?(Integer) && !colors_roads_hash.keys.include?(node[:road_nr])
      color = random_hex_color(colors_set)
      colors_roads_hash[node[:road_nr]] = color
    elsif node[:road_nr].is_a?(Integer)
      color = colors_roads_hash[node[:road_nr]]
    end

    unless node[:car_nr].nil?
      car_color = colors_cars_hash[node[:car_nr]]
      nodes.push(g.add_nodes('car#' + node[:car_nr].to_s, :color => car_color, :fillcolor => color, :style => :filled, :penwidth => 16.0, :label => node[:car_nr].to_s))
    else
      nodes.push(g.add_nodes(node[:name].to_s + '#' + node[:road_nr].to_s, :color => 'black', :fillcolor => color, :style => :filled, :penwidth => 1.0, :label => ''))
    end
  end

  outcome["links"].each do |link|
    source = link[:source]
    target = link[:target]
    source = nodes[source]
    target = nodes[target]
    g.add_edges(source, target, :arrowhead => :none)
  end
  g.output( :png => "output/#{index}.png" )
end

def apply_changing_states(core_outcome, graph, colors_cars_hash)
  colors_roads_hash = {}
  file = File.read(core_outcome) 
  cars_states = JSON.parse(file)
  index = 0
  cars_states.each do |states|
    index += 1
    graph["nodes"].each do |node|
      node[:car_nr] = nil
      states.each do |car_state|
        node[:car_nr] = car_state['car_nr'] if car_state["current_road_nr"] == node[:road_nr] && car_state["position"] == node[:name]
      end
    end
    print_graph(graph, index, colors_roads_hash, colors_cars_hash)
    # File.open("simulator/output/#{index}.json", 'w') { |file| file.write(JSON.pretty_generate(graph)) }
  end
end

colors_cars_hash = {}

FileUtils.rm_rf('output/.', secure: true)
data = data_from_files('simple_a_star/start_states_file', 'simple_a_star/roads_file')
outcome = base_json(data[:cars_states], data[:roads_states], colors_cars_hash)
apply_changing_states('core_out.json', outcome, colors_cars_hash)
