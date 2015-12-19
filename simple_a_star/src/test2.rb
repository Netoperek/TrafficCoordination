require_relative 'state_vertex'
require_relative 'generic_a_star'
require_relative '../helpers/data_helper'
require 'pry'

states = states_from_file '../traffic_file'
attributes = states[:attributes]
data = states[:data]

start_vertex = StatesVertex.new(1, attributes, data)
binding.pry
