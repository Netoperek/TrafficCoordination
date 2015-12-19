require_relative 'state'

class StatesVertex
  attr_accessor :attributes, :states

  def generate_all_states
    car_states = @states.map { |ele| generate_car_states(ele) }
    result = car_states.shift
    second_car_states = car_states.shift
    while !second_car_states.nil?
      result = result.product(second_car_states)
      second_car_states = car_states.shift
    end
    result.map! { |ele| ele.map { |e| e.values } }
    result.map! { |ele| StatesVertex.new(@attributes, ele) }
  end

  def generate_car_states(car_state)
    new_states = []

    state = car_state.state
    # no movement
    #
    new_state = state.clone
    new_states.push(new_state)

    # movement with velocity
    #
    new_state = state.clone
    new_state[:position] -= new_state[:velocity]
    new_state[:velocity] += new_state[:acceleration]
    new_states.push(new_state)

    # acceleration + 1
    #
    new_state = state.clone
    new_state[:acceleration] += 1
    new_states.push(new_state)

    # acceleration - 1
    #
    new_state = state.clone
    if new_state[:acceleration] > 0
      new_state[:acceleration] -= 1
      new_states.push(new_state)
    end
    new_states
  end

  def initialize(attributes, states)
    @attributes = attributes
    @states = states.map { |ele| State.new(attributes, ele) }
  end

  def edge_weight(to)
    @neighbours[to]
  end

  def neighbours
    generate_all_states
  end
end
