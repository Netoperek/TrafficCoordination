require_relative 'state'
require_relative 'road'
require_relative '../helpers/data_helper'

class StatesVertex
  FIXNUM_MAX = 100
  attr_accessor :attributes, :states, :roads

  def id
    @states.map { |state| state.state.to_s }
  end

  def roads_data
    return @@roads unless @@roads.nil?
    roads = roads_from_file '../roads_file'
    roads_attributes = roads[:attributes]
    roads_data = roads[:data]
    @@roads = roads_data.map! { |ele| Road.new(roads_attributes, ele) }
  end

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

    # movement with velocity on crossroads
    #
    if new_state[:position] <= 0
      new_state = state.clone
      cuts = roads_data.map { |ele| ele.state[:cuts].first }
      raise "WRONG CROSSROADS?" unless cuts.include? new_state[:final_road_nr]
      new_state[:position] -= new_state[:velocity]
      new_state[:velocity] += new_state[:acceleration]
      new_state[:current_road_nr] = new_state[:final_road_nr]
      new_states.push(new_state)
      return new_states
    end

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
    @@roads = nil
  end

  def edge_weight(to)
    return FIXNUM_MAX
  end

  def neighbours
    generate_all_states
  end
end
