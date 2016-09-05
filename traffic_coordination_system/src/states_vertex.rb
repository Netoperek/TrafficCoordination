require_relative 'state'
require_relative 'road'
require_relative '../helpers/data_helper'

class StatesVertex
	@@roads_file

	def self.roads_file(roads_file)
		@@roads_file=roads_file
	end

  if File.exists?('../plus_max_acceleration')
    data = CSV.read('../plus_max_acceleration')
    PLUS_MAX_ACCELERATION = data.last.last.to_i
  else
    PLUS_MAX_ACCELERATION = 1
  end
  
  MINUS_ACCELEARTION_MAX = -1
  SAFETY = 1
  MAX_VELOCITY = 4

  attr_accessor :attributes, :states, :roads

  def id
    @states.map { |state| state.state.to_s }
  end

  def roads_data
    return @@roads unless @@roads.nil?
    roads = roads_from_file @@roads_file
    roads_attributes = roads[:attributes]
    roads_data = roads[:data]
    @@roads = roads_data.map! { |ele| Road.new(roads_attributes, ele) }
    @@roads = @@roads.map! { |ele| ele.state }
  end

  def fixed_velocity(velocity)
    return velocity if velocity <= MAX_VELOCITY
    return MAX_VELOCITY
  end

  # returns roads nr that the car cut
  #
  def crossroads_passed(car_state)
    old_state = @states.select { |ele| ele.state[:car_nr] == car_state[:car_nr]}
    old_state = old_state.first.state

    cuts = roads_data.select { |ele| ele[:road_nr] == car_state[:current_road_nr] }
    cuts = cuts.first[:cuts]
    new_position = car_state[:position]
    old_position = old_state[:position]
    cuts = cuts.select do |ele|
      (new_position >= ele[:crossroad] && old_position < ele[:crossroad] && car_state[:direction] == 1) || \
        (new_position <= ele[:crossroad] && old_position > ele[:crossroad] && car_state[:direction] == -1)
    end
    cuts.map { |ele| ele[:road_nr] }
  end

  def merge_road_occupation(road_areas, start_pos, end_pos)
    new_road_area = { :start_pos => start_pos, :end_pos => end_pos }
    areas_to_push = []
    road_areas.each do |road_area|
      return false if start_pos >= road_area[:start_pos] && start_pos <= road_area[:end_pos]
      return false if end_pos >= road_area[:start_pos] && end_pos <= road_area[:end_pos]
    end
    road_areas.push(new_road_area)
  end

  def cuts
    roads_data.map { |ele| { :road_nr => ele[:road_nr], :cuts => ele[:cuts] } }
  end

  def state_vertex_collides(state_vertex)
    cars_states = state_vertex.states
    roads_areas = []

    # Collisions on one lane
    #
    cars_states.each do |car_state|
      car_state = car_state.state
      old_state = @states.select { |ele| ele.state[:car_nr] == car_state[:car_nr]}
      old_state = old_state.first.state
      start_pos = old_state[:position]
      end_pos = car_state[:position]
      roads_areas[car_state[:current_road_nr]] ||= []
      output = merge_road_occupation(roads_areas[car_state[:current_road_nr]], start_pos, end_pos)
      return true if output == false
    end

    # Collisions on crossroads
    #
    crossroads_points = []
    cars_states.each do |car_state|
      crossed = crossroads_passed(car_state.state)
      crossed.map! { |ele| [ car_state.state[:current_road_nr], ele] }
      crossed.each do |cross|
        crossroads_points.push(cross)
        crossroads_points.push(cross.reverse)
      end
    end 
    return true unless crossroads_points.uniq.size == crossroads_points.size

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

    max_acc = (state[:position] > state[:final_position] && state[:direction] == 1) || \
     (state[:position] < state[:final_position] && state[:direction] == -1)

    # movement with velocity, acceleration + 1
    #
    new_state = state.clone
    new_state[:velocity] = fixed_velocity(new_state[:velocity] + 1)
    new_state[:position] += new_state[:velocity] * new_state[:direction]
    new_states.push(new_state)

    return new_states if max_acc

    # movement with velocity
    #
    new_state = state.clone
    new_state[:position] += new_state[:velocity] * new_state[:direction]
    new_states.push(new_state)

    # movement with velocity, acceleration - 1
    #
    new_state = state.clone
    new_state[:velocity] -= 1
    new_state[:position] += new_state[:velocity] * new_state[:direction]
    new_states.push(new_state) if new_state[:velocity] >= 0

    if PLUS_MAX_ACCELERATION == 2
      # movement with velocity, acceleration + 2
      #
      new_state = state.clone
      new_state[:velocity] = fixed_velocity(new_state[:velocity] + 2)
      new_state[:position] += new_state[:velocity] * new_state[:direction]
      new_states.push(new_state)
    end

    if MINUS_ACCELEARTION_MAX == -2
      # movement with velocity, acceleration - 2
      #
      new_state = state.clone
      new_state[:velocity] -= 2
      new_state[:position] += new_state[:velocity] * new_state[:direction]
      new_states.push(new_state) if new_state[:velocity] >= 0
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
