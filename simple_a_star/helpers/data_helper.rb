require 'csv'

def states_from_file(file)
  data = CSV.read(file)
  attributes = data.shift
  data.map! { |ele| ele.map { |e2| e2.to_i } }
  { :attributes => attributes, :data => data }
end
