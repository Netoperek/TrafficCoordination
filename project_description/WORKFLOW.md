# TrafficCoordination

## Generic A Start algorithm

  1. The Generic A Start algorithm is in the following file:
       TrafficCoordination/simple_a_star/src/generic_a_star.rb

  1. It is a class which contains any vertex_class that can be passed in order to initialize it if:
      + the class implements the method "neighbours" - which returns the neighbours() of the vertex
      + the class implements the method "edge_weight(index_to)" - which returns the edge weight from the vertex to given one

  1. def class_is_valid
      + checks wether the class is valid for the algorithm as described above
  1. def hash_min(hash, to_visit_vertices)
      + returns the key of the given hash min value if the to_visit_vertices array includes the key
  1. def reconstruct_path(came_from, current_node, start)
      + reconstruct the path of A Start algorithm
  1. a_star
      + the content of the algorithm

## File to run the examples: TrafficCoordination/simple_a_star/src/test2.rb

  1. it defines win_function which is passed to Generic A Start algorithm - it defines when algorithm is successfuly

  1. heuristic function - which is passed to Generic A Start algorithm

  1. reconstruct_path_function - which can be passed to Generic A Start algorithm to reconstruct_path in other ways

  1. it reads data from files and runs the Generic A Start algorithm

  1. it writes the output of the algorithm to the following files:

    + TrafficCoordination/core_out.json
    + TrafficCoordination/human_core_out.json

## Road Class

  1. Represents road which is read from file

## State Class

  1. Represents state which is read from file

## StatesVertex

  Represents the vertex class which is passed to Generic A Start Algorithm

  ### Variables

  1. Has the following instance variables:
    + attributes of the state (read from file: car_nr,current_road_nr,position,velocity,final_position)
    + states - map of all of the cars states based on State Class

  1. Has the following class variables:
    + roads - which represents the states of all roads (read only once from the file)

  ### Methods

  1. def roads_data
    + reads roads data from the following file TrafficCoordination/simple_a_star/src/roads_file
  1. def crossroads_passed(car_state)
    + tells where the car will pass crossroads
  1. def cars_on_same_road(car_state_a, car_state_b)
    + tells where two cars are on the same road
  1. def roads_crossing(road_a, road_b)
    + tells where two roads are crossing
  1. def state_vertex_collides(state_vertex)
    + returns true if the state_vertex has any cars that collided
  1. def mix_states(states, states_result, result, index)
    + return mixed states of all cars (all combinations)
  1. def generic_a_star
    + generates all cars states and deletes the states that had collisions
  1. def generate_car_states(car_state)
    + generates all possible states for a car
      - movement with velocity
      - movement with velocity, acceleration + 1
      - movement with velocity, acceleration - 1
      - movement with velocity, acceleration + 2 (PLUS_ACCELEARTION_MAX defines if we do that)
      - movement with velocity, acceleration - 2 (PLUS_ACCELEARTION_MAX defines if we do that)
  1. def neighbours
    + runs generate_all_states method
