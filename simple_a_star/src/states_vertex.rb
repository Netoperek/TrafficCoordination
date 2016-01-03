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
    @@roads = @@roads.map! { |ele| ele.state }
  end

  def is_on_final_road(car_state)
    car_state[:final_road_nr] == car_state[:current_road_nr]
  end

  def car_road_cuts(car_state)
    cuts = roads_data.select { |ele| ele[:road_nr] == car_state[:current_road_nr] }
    cuts.first[:cuts]
  end

  def state_vertex_collides(state_vertex)
    states = state_vertex.states
    i = -1 
    j = 0
    while i < states.size
      i = i + 1 
      while j < states.size-1
        j = i + 1
        on_crossroads = states[i].state[:position] == 0 && states[j].state[:position] == 0
        same_crossroads = car_road_cuts(states[i].state) & car_road_cuts(states[j].state)
        return true if on_crossroads && same_crossroads
      end
    end
    false
  end

  def mix_states(states, states_result, result, index)   
    if states_result.size == states.first.size            
      result.push(states_result)                          
    else                                                  
      states.each do |state|                              
        f_states_dup = states_result.dup                  
        f_states_dup[index] = state[index]                
        mix_states(states, f_states_dup, result, index+1)
      end                                                 
    end                                                   
  end                                                     

  def generate_all_states
    cars_states = @states.map { |ele| generate_car_states(ele) }
    final_car_states = []
    for i in 0..cars_states.size-1
      final_car_states.push(cars_states.map { |ele| ele[i] })
    end
    cars_states = final_car_states

    result = []
    mix_states(cars_states, [], result, 0)
    binding.pry

    result.map! { |ele| ele.map { |e| e.values } }
    result.map! { |ele| StatesVertex.new(@attributes, ele) }
    # deleting states with cars on the same crossroads
    #
    result.delete_if { |state_vertex| state_vertex_collides(state_vertex) }
  end

  def generate_car_states(car_state)
    new_states = []

    state = car_state.state
    # no movement -> IMMEDIATE STOP
    #
    new_state = state.clone
    new_states.push(new_state)
    new_state[:velocity] = 0

    # movement with velocity on crossroads
    #
    if new_state[:position] <= 0
      new_state = state.clone
      cuts = car_road_cuts(new_state)
      raise "WRONG CROSSROADS?" unless cuts.include?(new_state[:final_road_nr]) || is_on_final_road(new_state)
      if new_state[:final_road_nr] != new_state[:current_road_nr]
        new_state[:position] -= new_state[:velocity]
      else
        new_state[:position] += new_state[:velocity]
      end
      new_state[:velocity] += new_state[:acceleration]
      new_state[:current_road_nr] = new_state[:final_road_nr]
      new_state[:position] *= -1 if new_state[:position] < 0
      new_states.push(new_state)
      return new_states
    end

    # movement with velocity
    #
    new_state = state.clone
    if new_state[:final_road_nr] != new_state[:current_road_nr]
      new_state[:position] -= new_state[:velocity]
    else
      new_state[:position] += new_state[:velocity]
    end
    new_state[:velocity] += new_state[:acceleration]
    new_states.push(new_state)

    # acceleration + 1
    #
    new_state = state.clone
    new_state[:acceleration] += 1
    new_state[:position] -= new_state[:velocity]
    new_states.push(new_state)

    # acceleration - 1
    #
    new_state = state.clone
    if new_state[:acceleration] > 0
      new_state[:acceleration] -= 1
      new_state[:position] -= new_state[:velocity]
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
