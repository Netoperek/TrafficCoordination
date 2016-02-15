# TrafficCoordination

## Environment description

1. Operating system - linux ubuntu

1. Install the following:
  - curl
    ```
    sudo apt-get install curl -y
    ```
  - rvm & ruby
    ```
    gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
    \curl -sSL https://get.rvm.io | bash -s stable --ruby
    source /usr/local/rvm/scripts/rvm
    ```
  - git
    ```
    sudo apt-get install git -y
    ```
  - graphviz
    ```
    sudo apt-get install graphviz
    ```

1. Clone the repository:
  - git clone https://github.com/Netoperek/TrafficCoordination.git
  - cd TrafficCoordination
  - git checkout multiCrossroads

1. Install necessary gems
  - bundle install

1. Run A Start for TrafficCoordination
  - cd simple_a_star/src
  - ruby test2.rb

1. Generate visual representation of the solution
  - (in TrafficCoordination dir) ruby states_to_graphs.rb
  - Output will be generated in TrafficCoordination/output dir
