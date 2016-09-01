for i in {2,4,6,8,10,12,14}; do
  rm ../../statistics_output/cars_count_$i
done

for j in {2,4,6,8,10,12,14}; do
  for i in {1..30}; do
    echo "case $i" >> ../../statistics_output/cars_count_$j
    ruby main.rb ../inputs/generated$j/generated_cars_states_file$i ../inputs/sl_roads_file >> ../../statistics_output/cars_count_$j
    echo "" >> ../../statistics_output/cars_count_$j
  done
done
