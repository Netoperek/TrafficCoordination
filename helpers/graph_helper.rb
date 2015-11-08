module GraphHelper
  def example_graph
    g = GraphViz.new(:G, :type => :digraph)
    edges = {}

    s = g.add_nodes('START')
    a = g.add_nodes('a')
    b = g.add_nodes('b')
    c = g.add_nodes('c')
    d = g.add_nodes('d')
    e = g.add_nodes('e')
    f = g.add_nodes('FINISH')

    edges['START>a'] = g.add_edges(s, a, weight: '1.5', label: '1.5')
    edges['START>d'] = g.add_edges(s, d, weight: '2', label: '2')
    edges['a>b'] = g.add_edges(a, b, weight: '2', label: '2')
    edges['b>c'] = g.add_edges(b, c, weight: '3', label: '3')
    edges['c>FINISH'] = g.add_edges(c, f, weight: '4', label: '4')
    edges['d>e'] = g.add_edges(d, e, weight: '3', label: '3')
    edges['e>FINISH'] = g.add_edges(e, f, weight: '2', label: '2')

    # g.output( :png => "output/example_graph.png" )
    { graph: g, edges: edges }
  end
end
