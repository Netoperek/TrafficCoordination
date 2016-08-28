# Convert input from another project to csv
# Input represents cars location
#

require 'json'
require 'csv'

file = File.read('cars.json')
data_hash = JSON.parse(file)

hash_table = []
data_hash.each do |ele|
  hash = {
    :car_nr => ele['id'],
    :current_road_nr => ele['position']['node_id'],
    :postion => ele['position']['position_on_node'],
    :velocity => ele['velocity'],
    :final_position => ele['path_to_dest'].last
  } 
  hash_table.push(hash)
end

csv_string = CSV.generate do |csv|
  hash_table.each do |hash|
    csv << hash.values
  end
end

csv_string = "car_nr,current_road_nr,position,velocity,final_position\n" + csv_string

File.open('converted_start_states_file', 'w') { |file| file.write(csv_string) }
