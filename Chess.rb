# encoding: utf-8

require 'colorize'
require './board.rb'
require './piece.rb'

class Array
  def vector_add(vector)
    self.zip(vector).map{|x,y| x + y}
  end
end

class Game

  attr_accessor :board

  def initialize(player1, player2)
    @player1 = player1
    player1.color = :white
    @player2 = player2
    player2.color = :black
    @current_player = @player1
    @board = Board.new
  end

  def display
    puts `clear`
    print "    a  b  c  d  e  f  g  h "
    puts ""
    (0..7).each do |x|
      print " #{8-x} "
      (0..7).each do |y|
        (x + y).even? ? background_color = :white : background_color = :red
        if @board.tiles[x][y] == nil
          print "   ".colorize(:background => background_color)
        else
          print " #{@board.tiles[x][y].to_s} ".colorize(:color => :black, :background => background_color)
        end
      end
      puts ""
    end
  end

  def play
    current_color = @current_player.color

    until @board.in_checkmate?(current_color)
      display
      puts "It's #{current_color}'s turn to play"

      get_player_move(current_color)
      handle_pawn_promotion(current_color)

      @current_player == @player1 ? @current_player = @player2 : @current_player = @player1
      current_color = @current_player.color
    end

    display_outcome
  end

  def handle_pawn_promotion(color)
    pawn = @board.check_pawn_promotion(color)
    unless pawn.nil?
      begin
        new_piece_type = @current_player.decide_promotion
        @board.promote_pawn(pawn, new_piece_type)
      rescue ArgumentError => e
        puts "*********#{e.message}*********"
        retry
      end
    end
  end

  def get_player_move(current_color)
    begin
      old_pos, new_pos = @current_player.get_move(@board)
      if check_input_is_castle(old_pos,new_pos,current_color)
        @board.castle_move(old_pos, new_pos, current_color)
      else
        @board.move(old_pos, new_pos, current_color)
      end
    rescue ArgumentError => e
      puts "*********#{e.message}*********" if @current_player.is_a?(HumanPlayer)
      retry
    end
  end

  def display_outcome
    display
    puts "Game over, #{@current_player.color} loses!"
  end

  def check_input_is_castle(king_pos,rook_pos,current_color)
    piece = board.get_tile(king_pos)
    if piece.is_a?(King)
      piece.castle_moves(@board).include?([king_pos, rook_pos])
    else
      return false
    end
  end

end

class HumanPlayer
  attr_accessor :name, :color
  def initialize(name = "Fleshbag")
    @name = name
  end

  def get_move(board)
    puts "Enter move in this format: e4 f6"
    input = gets.strip
    raise ArgumentError.new "Invalid input" unless /^[a-h][1-8] [a-h][1-8]$/ =~ input
    input.split(" ").map { |algebraic_coords| convert_move(algebraic_coords) }
  end

  def decide_promotion
    puts "What do you want to promote your pawn to (Rook, Queen, Bishop, Knight)"
    gets.chomp.downcase
  end

  def convert_move(coords)
    letter, num = coords[0], coords[1]
    [8 - num.to_i, "abcdefgh".index(letter)]
  end
end

class ComputerPlayer
  attr_accessor :name, :color
  def initialize(name = "Commodore 64")
    @name = name
  end

  def get_move(board)
    piece = board.colored_pieces(@color).sample
    old_pos = piece.location
    new_pos = piece.uninhibited_moves(board).sample
    [old_pos,new_pos]
  end

  def decide_promotion
    "queen"
  end

end

if __FILE__ == $0
  game = Game.new(ComputerPlayer.new, ComputerPlayer.new)
  game.play
end

# board = Board.new
# board.move([6,5], [5,5])
# board.move([1,4], [3,4])
# board.move([6,6], [4,6])
# board.move([0,3], [4,7])