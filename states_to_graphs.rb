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
  end

  crossroads = roads_states.map { |ele| { :road_nr => ele.state[:road_nr] , :cuts => ele.state[:cuts] } }
  crossroads.each do |ele|
    road_nr = ele[:road_nr]
    cuts = ele[:cuts]
    cuts.each do |cut|
      crossing_road_nr = cut[:road_nr]
      node_a = nodes.select { |node| node[:name] == cut[:crossroad] && node[:road_nr] == road_nr }
      node_a = node_a.first
      crossroad = crossroads.select { |cross| cross[:road_nr] == crossing_road_nr }
      cut = crossroad.first[:cuts].select { |ele| ele[:road_nr] == road_nr }
      cut = cut.first[:crossroad]
      node_b = nodes.select { |node| node[:name] == cut && node[:road_nr] == crossing_road_nr}
      crossing_nodes[node_a] = node_b
    end
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
    node_name_suffix = node[:road_nr].to_s
    node_name_suffix = node[:road_nr].to_s if node[:road_nr].is_a?(Integer)
    unless node[:car_nr].nil?
      car_color = colors_cars_hash[node[:car_nr]]
      nodes.push(g.add_nodes('car#' + node[:car_nr].to_s, :color => car_color, :fillcolor => color, :style => :filled, :penwidth => 16.0, :label => node[:car_nr].to_s))
    else
      nodes.push(g.add_nodes(node[:name].to_s + "#" + node_name_suffix, :color => 'black', :fillcolor => color, :style => :filled, :penwidth => 1.0, :label => '' ))
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
        if car_state["current_road_nr"] == node[:road_nr] && car_state["position"] == node[:name]
          node[:car_nr] = car_state['car_nr']
        end 
        if node[:road_nr].is_a?(String) 
          is_on_crossroads = node[:road_nr].split().include?(car_state["current_road_nr"].to_s) && node[:road_nr].split().include?(car_state["final_road_nr"].to_s)
          if is_on_crossroads && car_state["position"] == node[:name]
            node[:car_nr] = car_state['car_nr']
          end 
        end
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
