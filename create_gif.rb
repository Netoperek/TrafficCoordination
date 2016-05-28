require 'rmagick'
include Magick

def sorted_pngs
  files_number = Dir['output/normal/*'].count
  files_list = []
  for i in 1..files_number
    files_list.push("output/normal/#{i}.png")
  end
  files_list
end

animation = ImageList.new(*sorted_pngs)
animation.delay = 100
animation.write("animated.gif")
