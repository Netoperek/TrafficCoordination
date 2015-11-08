require 'ruby-graphviz'
require 'set'
require 'pry'
require_relative '../helpers/graph_helper'

# A* implementation
#
include GraphHelper

FIXNUM_MAX = (2**(0.size * 8 -2) -1)
COLOR = '#ff0000'

# Simple mapping for the following example: https://pl.wikipedia.org/wiki/Algorytm_A*
#
heuristic_function = Proc.new do |node|
  result = 4 if node == 'a'
  result = 2 if node == 'b'
  result = 4 if node == 'c'
  result = 2 if node == 'e'
  result = 4.5 if node == 'd'
  result = 2 if node == 'FINISH'
  result
end

def hash_min(hash, to_visit_vertices)
    min = FIXNUM_MAX
    min_key = ''
    hash.each do |key, value|
      if to_visit_vertices.include?(key.id) && value < min
        min = value
        min_key = key
      end
    end
    min_key
end

def edge_weight(edge)
  edge['weight'].to_s.tr('"','').to_f
end

def reconstruct_path(came_from, current_node)
  if came_from.keys.include? current_node
    path = reconstruct_path(came_from, came_from[current_node])
    return "#{path} " << current_node
  else
    puts "CAME_FROM #{came_from}"
    return 'START'
  end
end

def a_star(graph, start, goal, heuristic_function)
  # Initials
  #
  visited_vertices = Set.new
  to_visit_vertices = Set.new
  to_visit_vertices.add(start.id)
  g_score = { start => 0.0 }
  f_score = { start => 0.0 }
  h_score = { }
  came_from = { }
  edges = graph[:edges]

  while !to_visit_vertices.empty?
    current_node = hash_min(f_score, to_visit_vertices)
    return reconstruct_path(came_from, goal.id) if current_node.id == goal.id
    
    to_visit_vertices.delete(current_node.id)
    visited_vertices.add(current_node.id)

    current_node.neighbors.each do |neighbour|
      next if visited_vertices.include?(neighbour.id)
      
      edge_id = "#{current_node.id}>#{neighbour.id}"
      tentative_g_score = g_score[current_node].to_f + edge_weight(edges[edge_id])
      tentative_is_better = false

      if !to_visit_vertices.include?(neighbour.id)
        to_visit_vertices.add(neighbour.id)
        h_score[neighbour] = heuristic_function.call(neighbour.id)
        tentative_is_better = true
      elsif tentative_g_score < g_score[neighbour].to_f
        tentative_is_better = true 
      end

      if tentative_is_better
        came_from[neighbour.id] = current_node.id
        g_score[neighbour] = tentative_g_score
        f_score[neighbour] = g_score[neighbour] + h_score[neighbour]
      end
        
    end
  end
  return "FAILURE"
end

graph = example_graph
result = a_star(
  graph,
  graph[:graph].get_node('START'),
  graph[:graph].get_node('FINISH'),
  heuristic_function)
p result.split

result.split.each do { graph[:graph].get_node(ele)[:color] }
graph[:graph].output( :png => "result.png" )
