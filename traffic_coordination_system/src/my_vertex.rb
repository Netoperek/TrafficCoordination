class MyVertex
  attr_accessor :id, :neighbours

  def initialize(id)
    @id = id
  end

  def edge_weight(to)
    @neighbours[to]
  end

  def neighbours
    @neighbours.keys
  end
end
