require 'set'
require 'pry'

FIXNUM_MAX = (2**(0.size * 8 -2) -1)
NOT_IMPLEMENTED_ERROR_MSG = 'Class must define the following methods: neighbours, id'

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

class MyVertex
  def neighbours
  end

  def id
  end

  def edge_weight(to)
  end
end

class AStar
  def initialize(class_name)
    class_is_valid(class_name)
  end

  def class_is_valid(class_name)
    methods = [:neighbours, :id, :edge_weight]
    methods.each do |method|
      raise NOT_IMPLEMENTED_ERROR_MSG unless class_name.method_defined? method
    end
    raise NOT_IMPLEMENTED_ERROR_MSG unless 
      (class_name.method_defined? :neighbours) && (class_name.method_defined? :id)
  end

  def type_check(object, class_name)
    raise NOT_IMPLEMENTED_ERROR_MSG unless object.kind_of(class_name)
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

  def reconstruct_path(came_from, current_node)
    if came_from.keys.include? current_node
      path = reconstruct_path(came_from, came_from[current_node])
      return "#{path} " << current_node
    else
      puts "CAME_FROM #{came_from}"
      return 'START'
    end
  end

  def a_star(start, goal, heuristic_function)
    # Type validation
    # 
    type_check(start)      
    type_check(goal)      

    # Initials
    #
    visited_vertices = Set.new
    to_visit_vertices = Set.new
    to_visit_vertices.add(start.id)
    g_score = { start.id => 0.0 }
    f_score = { start.id => 0.0 }
    h_score = { }
    came_from = { }

    while !to_visit_vertices.empty?
      current_node = hash_min(f_score, to_visit_vertices)
      return reconstruct_path(came_from, goal.id) if current_node.id == goal.id
      
      to_visit_vertices.delete(current_node.id)
      visited_vertices.add(current_node.id)

      current_node.neighbors.each do |neighbour|
        next if visited_vertices.include?(neighbour.id)
        
        edge_weight = current_node.edge_weight(neighbour)
        tentative_g_score = g_score[current_node.id].to_f + edge_weight
        tentative_is_better = false

        if !to_visit_vertices.include?(neighbour.id)
          to_visit_vertices.add(neighbour.id)
          h_score[neighbour.id] = heuristic_function.call(neighbour.id)
          tentative_is_better = true
        elsif tentative_g_score < g_score[neighbour.id].to_f
          tentative_is_better = true 
        end

        if tentative_is_better
          came_from[neighbour.id] = current_node.id
          g_score[neighbour.id] = tentative_g_score
          f_score[neighbour.id] = g_score[neighbour.id] + h_score[neighbour.id]
        end
      end
    end

  end
end

my_a_star = AStar.new(MyVertex)
