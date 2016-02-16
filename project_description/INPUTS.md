## Inputs

There are two inputs for the algorithm two work:

1. TrafficCoordination/simple_a_star/src/start_states_file
  The file describes cars and specifies the following:
    + unique car id (number)
    + unique road nr id (number)
    + its initial velocity (if the car's velocity is 1 - it will move one piece forward after one time stamp)
    + its current position (number on which piece of roads it currently is)
    + its final position (number on which piece of roads it should be to be finished)
1. TrafficCoordination/simple_a_star/src/roads_file
  The file describes dorads and specifies the following:
    + unique road nr (number)
    + size of the road (number of pieces)
    + list of values (3 10); (4 20); (5 10); ...
      - where (x y);
        + x - is the number of roads which it cuts
        + y - is the number of piece of the roads which it cuts
