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

  def crossroads_passed(car_state)
    cuts = roads_data.select { |ele| ele[:road_nr] == car_state[:current_road_nr] }
    cuts = cuts.first[:cuts]
    new_position = car_state[:position] + car_state[:velocity] + 2
    cuts = cuts.select { |ele| new_position >= ele[:crossroad] && car_state[:position] < ele[:crossroad] }
    cuts.map { |ele| ele[:road_nr] }
  end

  def roads_crossing(road_a, road_b)
    cuts = roads_data.map { |ele| { :road_nr => ele[:road_nr], :cuts => ele[:cuts].map { |e| e[:road_nr] } } }
    cuts = cuts.select { |ele| ele[:road_nr] == road_a }
    return cuts.first[:cuts].include? road_b
  end

  def state_vertex_collides(state_vertex)
    states = state_vertex.states

    for i in 0..states.size-1
      for j in i+1..states.size-1
        state_i = states[i].state
        state_j = states[j].state

        # Avoid same position and velocity states
        #
        same_positions = state_i[:position] == state_j[:position]
        same_velocities = state_i[:velocity] == state_j[:velocity]
        return true if same_positions && same_velocities

        # Avoid crossing crossroads at the same time by >= 2 cars
        #
        crossroads_passed_i = crossroads_passed(state_i)
        crossroads_passed_j = crossroads_passed(state_j)
        crossroads_passed_i.each do |i|
          crossroads_passed_j.each do |j|
            return true if roads_crossing(i, j)
          end
        end
      end
    end
    return false
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
 
  def generate_car_states(car_state)
    new_states = []
    state = car_state.state

    # movement with velocity
    #
    new_state = state.clone
    new_state[:position] += new_state[:velocity]
    new_states.push(new_state)

    # movement with velocity, acceleration + 1
    #
    new_state = state.clone
    new_state[:velocity] += 1
    new_state[:position] += new_state[:velocity]
    new_states.push(new_state)

    # movement with velocity, acceleration - 1
    #
    new_state = state.clone
    new_state[:velocity] -= 1
    new_state[:position] += new_state[:velocity]
    new_states.push(new_state) if new_state[:velocity] >= 0

    # movement with velocity, acceleration + 2 
    #
    new_state = state.clone
    new_state[:velocity] += 2
    new_state[:position] += new_state[:velocity]
    new_states.push(new_state)

    # movement with velocity, acceleration - 2 
    #
    new_state = state.clone
    new_state[:velocity] -= 2
    new_state[:position] += new_state[:velocity]
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