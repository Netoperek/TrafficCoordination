# TrafficCoordination

## MASTER THESIS

### The goal of the project

The goal of this project is to use A Start algorithm in order to solve the following problem:

1. There are roads with multiple lanes
  + each roads is represented in a discret way (is divided in to pieces)
  + each roads has the following parameters:
    - its unique id (number)
    - its size (number of pieces)
    - list of numbers of other roads which cuts it along with numbers of positions where other roads cuts it
1. There are many cars on those roads
  + each car has the following parameters:
    - unique id (number)
    - initial velocity
    - current road number that it is on
    - initial position
    - final position
  + each car can accelerate within the following values {-2, -1, 0, 1, 2} (depends on the configuration)
1. The algorithm looks for the situation where all of the cars have reach their final positions
1. Cars move on WITHOUT collisions

### Example output

![Alt text](https://media.giphy.com/media/3o6EhMdCqWV1fOqhPO/giphy.gif)

![Alt text](https://media.giphy.com/media/3oD3Ylmw0CSTmo4Z2M/giphy.gif)
