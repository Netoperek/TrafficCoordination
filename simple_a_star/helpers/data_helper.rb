require 'csv'

def states_from_file(file)
  data = CSV.read(file)
  attributes = data.shift
  data.map! { |ele| ele.map { |e2| e2.to_i } }
  { :attributes => attributes, :data => data }
end

def roads_from_file(file)
  data = CSV.read(file)
  attributes = data.shift
  data.map! do |ele|
    [ ele[0].to_i,
      ele[1].to_i,
      ele[2].split.map { |ele| ele.to_i },
      ele[3].to_i ]
  end
  { :attributes => attributes, :data => data }
end
