require_relative 'my_vertex'
require_relative 'generic_a_star'

# Simple mapping for the following example: https://pl.wikipedia.org/wiki/Algorytm_A*
#
heuristic_function = Proc.new do |node|
  result = 4 if node.id == 2
  result = 2 if node.id == 3 
  result = 4 if node.id == 3
  result = 4 if node.id == 4
  result = 4.5 if node.id == 5
  result = 2 if node.id == 6
  result = 3 if node.id == 7
  result
end

v1 = MyVertex.new(1)
v2 = MyVertex.new(2)
v3 = MyVertex.new(3)
v4 = MyVertex.new(4)
v5 = MyVertex.new(5)
v6 = MyVertex.new(6)
v7 = MyVertex.new(7)

v1.neighbours = { v2 => 1.5, v5 => 2 }
v2.neighbours = { v3 => 2 }
v3.neighbours = { v4 => 3 }
v4.neighbours = { v5 => 4 }
v5.neighbours = { v6 => 3 }
v6.neighbours = { v7 => 2 }

a = AStar.new(MyVertex)
puts a.a_star(v1, v7, heuristic_function)
