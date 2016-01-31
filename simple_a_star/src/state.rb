class State
  attr_reader :state

  def initialize(attributes, values)
    @state = {}
    attributes.zip(values) { |a, b| @state[a.to_sym] = b }
  end
end
