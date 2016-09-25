require_relative 'traffic_coordination_system/helpers/data_helper'
require_relative 'traffic_coordination_system/src/road'
require_relative 'traffic_coordination_system/src/states_vertex'
require 'set'
require 'json'
require 'ruby-graphviz'
require 'pry'

PENDWIDTH = 30.0
MISTAKE_DISTANCE = 1
CARS_MISTAKES_AT_ONCE = 2
PLUS_MAX_ACCELERATION = 1
GRAPH_TYPE = 'neato'

unless ARGV[0] && ARGV[1]
  puts 'USAGE: ruby states_to_graphs.rb traffic_coordination_system/inputs/start_states_file traffic_coordination_system/inputs/roads_file'
  exit
end

start_states_file = ARGV[0]
roads_file = ARGV[1]

def data_from_files(start_states_file, roads_file)
  states = states_from_file start_states_file
  states_attributes = states[:attributes]
  data = states[:data]
  start_vertex = StatesVertex.new(states_attributes, data)

  roads = roads_from_file roads_file
  roads_attributes = roads[:attributes]
  roads_states = roads[:data]
  roads_states.map! { |ele| Road.new(roads_attributes, ele) }

  cars_states = start_vertex.states
  { :cars_states => cars_states,
    :roads_states => roads_states }
end

$data = data_from_files(start_states_file, roads_file)

def present_roads_as_nodes(roads_states, cars_states)
  nodes = []

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
  nodes
end

# { [a, b] } - node a crosses with node b
#
def extract_crossing_nodes(nodes, roads_states)
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
  crossing_nodes
end

def create_links(nodes)
  i = -1
  links = []
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
  links
end

def find_replace_node(nodes, index)
  new_nodes = nodes.find_all { |ele| ele[:name].is_a? Array }
  new_nodes.uniq!
  new_nodes.each do |ele|
    return ele if ele[:name][0] == nodes[index][:name] && ele[:road_nr][0] == nodes[index][:road_nr]
    return ele if ele[:name][1] == nodes[index][:name] && ele[:road_nr][1] == nodes[index][:road_nr]
  end
  raise 'Node to replace was not found'
end

def remove_mirror_links(links)
  i = 0
  j = 0
  to_delete = []
  for i in 0..links.size-1
    for j in i+1..links.size-1
      to_delete.push(links[i]) if links[i][:target] == links[j][:source] && links[i][:source] == links[j][:target]
    end
  end
  links - to_delete
end

def base_json(cars_states, roads_states, colors_cars_hash)
  colors_set = Set.new
  cars_nr = cars_states.map { |ele| ele.state[:car_nr] }

  # Cars on one road have same color
  #
  roads_nr = roads_states.map{ |ele| ele.state[:road_nr] }
  roads_nr.each { |road_nr| colors_cars_hash[road_nr] = random_hex_color(colors_set) }

  nodes = present_roads_as_nodes(roads_states, cars_states)

  crossing_nodes = extract_crossing_nodes(nodes, roads_states)

  # Removing all crossing nodes
  # Getting nodes to add
  #
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
  new_nodes_idx = -1

  # Adding crossroads nodes
  #
  nodes_to_add.each do |ele|
    join_indices = ele.map { |e| nodes.find_index e }
    name = []
    road_nr = []
    name.push(ele[0][:name]+1)
    name.push(ele[2][:name]+1)
    road_nr.push(ele[0][:road_nr])
    road_nr.push(ele[2][:road_nr])
    node = { :name => name, :road_nr => road_nr, :car_nr => nil }
    nodes.push(node)
    new_nodes_idx = nodes.size-1 if new_nodes_idx == -1
  end

  nodes_to_add.each_with_index do |ele, node_to_add_idx|
    join_indices = ele.map { |e| nodes.find_index e }
    join_indices.each do |index|
      if nodes_to_delete.include? nodes[index]
        node_to_replace = find_replace_node(nodes, index)
        replace_idx = nodes_to_add[node_to_add_idx].find_index nodes[index]
        nodes_to_add[node_to_add_idx][replace_idx] = node_to_replace
      end
    end
  end

  nodes -= nodes_to_delete
  nodes.uniq!
  links = create_links(nodes)
  new_nodes_idx -= nodes_to_delete.size

  nodes_to_add.each do |ele|
    join_indices = ele.map { |e| nodes.find_index e }
    node_index = new_nodes_idx
    i = 0
    join_indices.each do |idx|
      link = { :source => idx, :target => node_index }
      links.push(link)
    end
    new_nodes_idx += 1
  end

  links = remove_mirror_links(links)

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

def print_graph(outcome, index, colors_roads_hash, colors_cars_hash, cars_states, mistakes, collision)
  colors_set = Set.new
  if collision
    g = GraphViz.new(:G, :type => :digraph, :use => GRAPH_TYPE, :labelloc => 'top', :label => 'Collision', :fontsize => '30')
  else
    g = GraphViz.new(:G, :type => :digraph, :use => GRAPH_TYPE, :labelloc => 'top')
  end
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

def crossroads_passed(car_state)
  roads_data = $data[:roads_states]
  cuts = roads_data.select { |ele| ele[:road_nr] == car_state[:current_road_nr] }
  cuts = cuts.first[:cuts]
  cuts = cuts.select { |ele| new_position >= ele[:crossroad] && car_state[:position] < ele[:crossroad] }
  cuts.map { |ele| ele[:road_nr] }
end

def states_collides(states_before, states_after)
  roads_data = $data[:roads_states]

  roads_data.each do |roads_states|
    road = roads_states.state
    cars_on_roads_before = states_before.select { |ele| ele['current_road_nr'] == road[:road_nr] }
    cars_on_roads_before.map! { |ele| ele['position'] }

    cars_on_roads_after = states_after.select { |ele| ele['current_road_nr'] == road[:road_nr] }
    cars_on_roads_after.map! { |ele| ele['position'] }

    for i in 0..cars_on_roads_before.length-2
      order_before = cars_on_roads_before[i] < cars_on_roads_before[i+1]
      order_after = cars_on_roads_after[i] < cars_on_roads_after[i+1]
      return true if cars_on_roads_before[i] == cars_on_roads_before[i+1]
      return true if cars_on_roads_after[i] == cars_on_roads_after[i+1]
      return true if order_before != order_after
    end
  end

  crossroads_passed = []
  for i in 0..states_before.length-1
    roads_data_states = roads_data.map { |ele| ele.state }
    old_car_state = states_before[i]
    new_car_state = states_after[i]

    new_position = new_car_state['position']
    old_position = old_car_state['position']

    cuts = roads_data_states.select { |ele| ele[:road_nr] == new_car_state['current_road_nr'] }
    cuts = cuts.first[:cuts]
    cuts = cuts.select do |ele|                                                                                 
      (new_position >= ele[:crossroad] && old_position < ele[:crossroad] && new_car_state['direction'] == 1) || \
        (new_position <= ele[:crossroad] && old_position > ele[:crossroad] && new_car_state['direction'] == -1)  
    end                                                                                                         

    cuts = cuts.map { |ele| [new_car_state['current_road_nr'], ele[:road_nr]] } + \
      cuts.map { |ele| [ele[:road_nr], new_car_state['current_road_nr']] }
    crossroads_passed += cuts
  end

  crossroads_passed.delete_if { |ele| ele.empty? }

  return true if crossroads_passed.uniq.length != crossroads_passed.length
  return false
end

def apply_changing_states(core_outcome, graph, colors_cars_hash, roads_states, mistakes)
  roads_states = roads_states.map { |ele| ele.state }
  colors_roads_hash = {}
  file = File.read(core_outcome)
  cars_states = JSON.parse(file)
  index = 0
  collision = false
  cars_states.each do |states|
    collision = states_collides(cars_states[index-1], cars_states[index]) unless index == 0
    puts "COLLISION on step #{index+1}" if collision
    index += 1
    graph['nodes'].each do |node|
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
    print_graph(graph, index, colors_roads_hash, colors_cars_hash, cars_states, mistakes, collision)
    # File.open("simulator/output/#{index}.json", 'w') { |file| file.write(JSON.pretty_generate(graph)) }
  end
end

colors_cars_hash = {}

FileUtils.rm_rf('output/normal/.', secure: true)
FileUtils.rm_rf('output/mistakes/.', secure: true)
data = data_from_files(start_states_file, roads_file)

puts 'NORMAL OUTPUT'

# Normal output
#
outcome = base_json(data[:cars_states], data[:roads_states], colors_cars_hash)
apply_changing_states('core_out.json', outcome, colors_cars_hash, data[:roads_states], false)

puts 'OUTPUT WITH MISTAKES'

# Mistakes output
#
file = File.read('core_out.json')
states = JSON.parse(file)
states.each_with_index do |cars_states, index|
  next if index == 0

  cars_states.each_with_index do |car_state, car_nr|
    make_mistake = (0..100).to_a.sample

    if make_mistake == 8
      car_state["position"] += MISTAKE_DISTANCE
      for idx in index+1..states.length-1
        car_state = states[idx][car_nr]
        car_state["position"] += MISTAKE_DISTANCE
      end
    end
  end
end

result_json = JSON.pretty_generate(states)
File.open('core_mistake_out.json', 'w') { |file| file.write(result_json) }

outcome = base_json(data[:cars_states], data[:roads_states], colors_cars_hash)
apply_changing_states('core_mistake_out.json', outcome, colors_cars_hash, data[:roads_states], true)
