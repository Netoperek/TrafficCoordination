rm -rf generated*

for i in {2,4,6,8,10,12,14}; do
	ruby start_states_generator.rb sl_roads_file $i 30
done
