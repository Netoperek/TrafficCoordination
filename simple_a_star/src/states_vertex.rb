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

    next_positions = []
    states.each do |ele|
      # 2 is max acceleration
      #
      new_position = ele.state[:position] - ele.state[:velocity] - 2
      next_positions.push(new_position) unless is_on_final_road(ele.state)
    end
    cars_on_cross_number = next_positions.count { |ele| ele <= 0 }
    many_cars_cross = cars_on_cross_number > 1

    for i in 0..states.size-1
      for j in i+1..states.size-1
        state_i = states[i].state
        state_j = states[j].state
        same_positions = state_i[:position] == state_j[:position]
        same_velocities = state_i[:velocity] == state_j[:velocity]
        skip_state = is_on_final_road(state_j) || is_on_final_road(state_i)
        return true if same_positions && same_velocities && !skip_state
      end
    end

    return many_cars_cross
  end

  def state_vertex_car_near_crossroads(state_vertex)
    positions = state_vertex.states.map { |ele| ele.state[:position] }
    positions.delete_if { |ele| ele > 5 }
    positions.count > 0
  end

  def mix_states(states, states_result, result, index)   
    if states_result.size == states.size                  
      result.push(states_result)                          
    else                                                  
      states[index].each do |state|                       
        f_states_dup = states_result.dup                  
        f_states_dup[index] = state                       
        mix_states(states, f_states_dup, result, index+1)
      end                                                 
    end                                                   
  end                                                     

  def generate_all_states
    cars_states = @states.map { |ele| generate_car_states(ele) }
    result = []
    mix_states(cars_states, [], result, 0)

    result.map! { |ele| ele.map { |e| e.values } }
    result.map! { |ele| StatesVertex.new(@attributes, ele) }

    # deleting states with colliding cars
    #
    result.delete_if { |state_vertex| state_vertex_collides(state_vertex) }
  end
 
  def correct_roads(state)
    if state[:position] < 0
      cuts = car_road_cuts(state)
      raise "WRONG CROSSROADS?" unless cuts.include?(state[:final_road_nr]) || is_on_final_road(state)
      state[:current_road_nr] = state[:final_road_nr]
      state[:position] *= -1
    end
    state
  end
   
  def generate_car_states(car_state)
    new_states = []
    state = car_state.state

    # movement with velocity
    #
    new_state = state.clone
    new_state[:position] -= new_state[:velocity]
    new_state = correct_roads(new_state)
    new_states.push(new_state)

    # movement with velocity, acceleration + 1
    #
    new_state = state.clone
    new_state[:velocity] += 1
    new_state[:position] -= new_state[:velocity]
    new_state = correct_roads(new_state)
    new_states.push(new_state)

    # movement with velocity, acceleration - 1
    #
    new_state = state.clone
    new_state[:velocity] -= 1
    new_state[:position] -= new_state[:velocity]
    new_state = correct_roads(new_state)
    new_states.push(new_state) if new_state[:velocity] >= 0

    # movement with velocity, acceleration + 2 
    #
    new_state = state.clone
    new_state[:velocity] += 2
    new_state[:position] -= new_state[:velocity]
    new_state = correct_roads(new_state)
    new_states.push(new_state)

    # movement with velocity, acceleration - 2 
    #
    new_state = state.clone
    new_state[:velocity] -= 2
    new_state[:position] -= new_state[:velocity]
    new_state = correct_roads(new_state)
    new_states.push(new_state) if new_state[:velocity] >= 0

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
