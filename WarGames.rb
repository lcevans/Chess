require './Chess.rb'

5.times do
  game = Game.new(ComputerPlayer.new, ComputerPlayer.new)
  game.play
  sleep 0.5
end

puts "A strange game. The only winning move is not to play."