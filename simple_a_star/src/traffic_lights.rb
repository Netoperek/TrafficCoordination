require_relative 'states_vertex'
require_relative 'generic_a_star'
require_relative '../helpers/data_helper'
require_relative 'road'
require 'csv'
require 'json'
require 'pry'

data = CSV.read('../plus_max_acceleration')
PLUS_MAX_ACCELERATION = data.last.last.to_i

states = states_from_file '../start_states_file'
states_attributes = states[:attributes]
data = states[:data]

roads = roads_from_file '../roads_file'
roads_attributes = roads[:attributes]
roads_data = roads[:data]
roads_data.map! { |ele| Road.new(roads_attributes, ele) }

