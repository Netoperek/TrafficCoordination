require_relative 'simple_a_star/helpers/data_helper'
require_relative 'simple_a_star/src/road'
require_relative 'simple_a_star/src/states_vertex'
require 'set'
require 'json'
require 'ruby-graphviz'
require 'pry'

PENDWIDTH = 30.0
MISTAKE_DISTANCE = 2
CARS_MISTAKES_AT_ONCE = 2

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
  # cars_nr.each.map { |car_nr| colors_cars_hash[car_nr] = random_hex_color(colors_set) }
  
  # Cars on one road have same color
  #
  roads_nr = roads_states.map{ |ele| ele.state[:road_nr] }
  roads_nr.each { |road_nr| colors_cars_hash[road_nr] = random_hex_color(colors_set) }

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
  nodes_to_delete = []
  nodes_to_add = []
  crossing_nodes.each do |ele|
    nodes_to_delete.push(nodes[ele[0]])
    nodes_to_delete.push(nodes[ele[1]])
    node_a = nodes[ele[0]-1] if ele[0]-1 >= 0 && ele[0]-1 < nodes.size
    node_b = nodes[ele[0]+1] if ele[0]+1 >= 0 && ele[0]+1 < nodes.size
    node_c = nodes[ele[1]-1] if ele[1]-1 >= 0 && ele[1]-1 < nodes.size
    node_d = nodes[ele[1]+1] if ele[1]+1 >= 0 && ele[1]+1 < nodes.size
    crossroad_node_connect = []
    crossroad_node_connect.push(node_a) unless node_a.nil?
    crossroad_node_connect.push(node_b) unless node_b.nil?
    crossroad_node_connect.push(node_c) unless node_c.nil?
    crossroad_node_connect.push(node_d) unless node_d.nil?
    nodes_to_add.push(crossroad_node_connect)
  end

  nodes_to_delete.uniq!
  nodes -= nodes_to_delete

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

  nodes_to_add.each do |ele|
    connect_indices = ele.map { |e| nodes.find_index e }
    name = []
    road_nr = []
    name.push(ele[0][:name]+1)
    name.push(ele[2][:name]+1)
    road_nr.push(ele[0][:road_nr])
    road_nr.push(ele[2][:road_nr])
    name.uniq!
    road_nr.uniq!
    node = { :name => name, :road_nr => road_nr, :car_nr => nil } 
    nodes.push(node)
    node_index = nodes.size-1
    i = 0
    while i < connect_indices.size
      link = { :source => connect_indices[i], :target => node_index }
      links.push(link)
      link = { :source => node_index, :target => connect_indices[i+1] }
      links.push(link)
      i += 2
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

def print_graph(outcome, index, colors_roads_hash, colors_cars_hash, cars_states, mistakes)
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
      road_nr = cars_states[0][node[:car_nr]-1]["current_road_nr"]
      car_color = colors_cars_hash[road_nr]
      nodes.push(g.add_nodes('car#' + node[:car_nr].to_s, :color => car_color, :fillcolor => color, :style => :filled, :penwidth => PENDWIDTH, :label => node[:car_nr].to_s))
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
  dir = 'normal' unless mistakes
  dir = 'mistakes' if mistakes
  g.output( :png => "output/#{dir}/#{index}.png" )
end

def apply_changing_states(core_outcome, graph, colors_cars_hash, roads_states, mistakes)
  roads_states = roads_states.map { |ele| ele.state }
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
        if node[:name].is_a? Array
          cut = roads_states.select { |ele| ele[:road_nr] == car_state["current_road_nr"] }
          cut = cut.first
          cut = cut[:cuts].select { |ele| ele[:crossroad] == car_state["position"] }
          cut = cut.first
          node[:car_nr] = car_state['car_nr'] if node[:road_nr].include?(car_state["current_road_nr"]) && node[:name].include?(car_state["position"]) && node[:road_nr].include?(cut[:road_nr])
        end
      end
    end
    print_graph(graph, index, colors_roads_hash, colors_cars_hash, cars_states, mistakes)
    # File.open("simulator/output/#{index}.json", 'w') { |file| file.write(JSON.pretty_generate(graph)) }
  end
end

colors_cars_hash = {}

FileUtils.rm_rf('output/normal/.', secure: true)
FileUtils.rm_rf('output/mistake/.', secure: true)
data = data_from_files('simple_a_star/start_states_file', 'simple_a_star/roads_file')

# Normal output
#
outcome = base_json(data[:cars_states], data[:roads_states], colors_cars_hash)
apply_changing_states('core_out.json', outcome, colors_cars_hash, data[:roads_states], false)

# Mistakes output
#
file = File.read('core_out.json') 
cars_states = JSON.parse(file)
cars_states.each do |states|
  i = (0..states.length-1).to_a.sample
  car_state = states[i]
  car_state["position"] += MISTAKE_DISTANCE
end

result_json = JSON.pretty_generate(cars_states)                               
File.open('core_mistake_out.json', 'w') { |file| file.write(result_json) } 

outcome = base_json(data[:cars_states], data[:roads_states], colors_cars_hash)
apply_changing_states('core_mistake_out.json', outcome, colors_cars_hash, data[:roads_states], true)
