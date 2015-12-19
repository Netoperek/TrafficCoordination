require_relative 'state'

class StatesVertex
  attr_accessor :id, :neighbours, :attributes, :states

  def generate_all_states
    car_states = @states.map { |ele| generate_car_states(ele) }
    result = car_states.shift
    second_car_states = car_states.shift
    while !second_car_states.nil?
      result = result.product(second_car_states)
      second_car_states = car_states.shift
    end
    result
  end

  def generate_car_states(car_state)
    new_states = []

    state = car_state.state
    # no movement
    #
    new_state = State.new(state.keys, state.values)
    new_states.push(new_state)

    # movement with velocity
    #
    new_state = State.new(state.keys, state.values)
    new_state.state[:position] -= new_state.state[:velocity]
    new_state.state[:velocity] += new_state.state[:acceleration]
    new_states.push(new_state)

    # acceleration + 1
    #
    new_state = State.new(state.keys, state.values)
    new_state.state[:acceleration] += 1
    new_states.push(new_state)

    # acceleration - 1
    #
    new_state = State.new(state.keys, state.values)
    if new_state.state[:acceleration] > 0
      new_state.state[:acceleration] -= 1
      new_states.push(new_state)
    end
    new_states
  end

  def initialize(id, attributes, states)
    @id = id
    @attributes = attributes
    @states = states.map { |ele| State.new(attributes, ele) }
  end

  def edge_weight(to)
    @neighbours[to]
  end

  def neighbours
    
    @neighbours.keys
  end
end
