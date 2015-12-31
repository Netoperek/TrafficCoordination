require 'set'
require 'pry'

class AStar
  FIXNUM_MAX = (2**(0.size * 8 -2) -1)
  NOT_IMPLEMENTED_ERROR_MSG = 'Class must define the following methods: neighbours, id'

  attr_accessor :vertex_class

  def initialize(class_name)
    @vertex_class = class_name
    class_is_valid
  end

  def class_is_valid
    methods = [:neighbours, :edge_weight]
    methods.each do |method|
      raise NOT_IMPLEMENTED_ERROR_MSG unless @vertex_class.method_defined? method
    end
  end

  def type_check(object)
    raise NOT_IMPLEMENTED_ERROR_MSG unless object.kind_of?(@vertex_class)
  end

  def hash_min(hash, to_visit_vertices)
      min = FIXNUM_MAX
      min_key = ''
      hash.each do |key, value|
        if to_visit_vertices.include?(key) && value < min
          min = value
          min_key = key
        end
      end
      min_key
  end

  def reconstruct_path(came_from, current_node, start)
    if came_from.keys.include? current_node
      path = reconstruct_path(came_from, came_from[current_node], start)
      return "#{path} " << current_node.id.to_s
    else
      return start.id
    end
  end

  def a_star(start, heuristic_function, win_function, reconstruct_path_function=nil)
    # Type validation
    # 
    type_check(start)      

    # Initials
    #
    visited_vertices = Set.new
    to_visit_vertices = Set.new
    to_visit_vertices.add(start)
    g_score = { start => 0.0 }
    f_score = { start => 0.0 }
    h_score = { }
    came_from = { }

    while !to_visit_vertices.empty?
      current_node = hash_min(f_score, to_visit_vertices)

      # Developer may pass his own reconstruct_path_function
      #
      if reconstruct_path_function.nil?
        return reconstruct_path(came_from, current_node, start) if win_function.call(current_node)
      else
        return reconstruct_path_function.call(came_from, current_node, start) if win_function.call(current_node)
      end

      to_visit_vertices.delete(current_node)
      visited_vertices.add(current_node)

      current_node.neighbours.each do |neighbour|
        next if visited_vertices.include?(neighbour)
        
        # edge_weight = current_node.edge_weight(neighbour)
        tentative_g_score = g_score[current_node].to_f # + edge_weight
        tentative_is_better = false

        if !to_visit_vertices.include?(neighbour)
          to_visit_vertices.add(neighbour)
          h_score[neighbour] = heuristic_function.call(neighbour)
          tentative_is_better = true
        elsif tentative_g_score < g_score[neighbour].to_f
          tentative_is_better = true 
        end

        if tentative_is_better
          came_from[neighbour] = current_node
          g_score[neighbour] = tentative_g_score
          f_score[neighbour] = g_score[neighbour] + h_score[neighbour]
        end
      end
    end

  end
end
