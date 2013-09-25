# encoding: utf-8


class Array
  def vector_add(vector)
    self.zip(vector).map{|x,y| x + y}
  end
end

class Piece
  attr_accessor :location, :color

  def initialize(location, color)
    @location = location
    @color = color
  end

end

class SteppingPiece < Piece
  def uninhibited_moves(board)
    locations = move_displacements.map { |displacement| @location.vector_add(displacement) }
    locations.select { |position| board.open_space?(position, @color) }
  end
end

class Knight < SteppingPiece
  def to_s
    @color == :white ? "♘" : "♞"
  end

  def move_displacements
    move_displacements = []
    [-2, -1, 1, 2].each do |delta_x|
      [-2, -1, 1, 2].each do |delta_y|
        move_displacements << [delta_x, delta_y] if (delta_x + delta_y).odd?
      end
    end
    move_displacements
  end
end

class King < SteppingPiece
  def to_s
  @color == :white ? "♔" : "♚"
  end

  def move_displacements
    move_displacements = []
    [-1, 0, +1].each do |delta_x|
      [-1, 0, +1].each do |delta_y|
        next if delta_x == 0 && delta_y == 0
        move_displacements << [delta_x, delta_y]
      end
    end
    move_displacements
  end
end

class SlidingPiece < Piece
  def uninhibited_moves(board)
    dirs, moves = move_dirs, []

    dirs.each do |displacement|
      test_pos = @location
      test_pos = test_pos.vector_add(displacement)
      while board.empty_space?(test_pos)
        moves << test_pos
        test_pos = test_pos.vector_add(displacement)
      end
      #If it's an enemy color piece, take it
      moves << test_pos if board.open_space?(test_pos, @color)
    end
    moves
  end
end

class Queen < SlidingPiece
  def to_s
  @color == :white ? "♕" : "♛"
  end

  def move_dirs
    moves = [[0,1], [1,0], [-1, 0], [0, -1], [-1,1], [1,1], [1,-1], [-1,-1]]
  end
end

class Bishop < SlidingPiece
  def to_s
  @color == :white ? "♗" : "♝"
  end

  def move_dirs
    moves = [[1,1], [1,-1], [-1, -1], [-1, 1]]
  end
end

class Rook < SlidingPiece
  def to_s
  @color == :white ? "♖" : "♜"
  end

  def move_dirs
    moves = [[0,1], [1,0], [-1, 0], [0, -1]]
  end

end

class Pawn < Piece
  def to_s
  @color == :white ? "♙" : "♟"
  end

  def uninhibited_moves(board)
    # move_displacements = [[-1,1],[0,1],[1,1]]
    # move_displacements.map! {|x,y| [-x,-y]} if @color == :black
    moves = []

    @color == :black ? simple_disp = [1,0] : simple_disp = [-1, 0]
    simple_move = simple_disp.vector_add(@location)
    if board.empty_space?(simple_move)
      moves << simple_move
    end

    @color == :black ? home_row = 1 : home_row = 6
    if @location[0] == home_row
      @color == :black ? double_disp = [2,0] : double_disp = [-2,0]
      double_move = double_disp.vector_add(@location)
      if board.empty_space?(simple_move) && board.empty_space?(double_move)
        moves << double_move
      end
    end

    @color == :black ? diagonal_displacements = [[1,1], [1, -1]] : diagonal_displacements = [[-1, 1], [-1, -1]]
    diagonal_displacements.each do |displacement|
      move = displacement.vector_add(@location)
      moves << move if board.open_space?(move, @color) && !board.empty_space?(move)
    end
    moves
  end
end

class Board
  attr_accessor :tiles

  def empty_space?(pos)
    Board.in_bounds?(pos) && get_tile(pos) == nil
  end

  def open_space?(pos, color)
    return false unless Board.in_bounds?(pos)
    return true if empty_space?(pos)
    get_tile(pos).color != color
  end

  def self.in_bounds?(pos)
    x,y = pos
    x.between?(0,7) && y.between?(0,7)
  end

  def initialize
    @tiles = build_starting_board
  end

  def build_starting_board
    board = Array.new(8) {Array.new (8)}


    [:white, :black].each do |color|
      # Do the pawn row
      color == :white ? row = 6 : row = 1
      (0..7).each do |column|
        board[row][column] = Pawn.new([row,column], color)
      end
      # Do the first row
      color == :white ? row = 7 : row = 0
      [0,7].each do |column|
        board[row][column] = Rook.new([row, column], color)
      end
      [1,6].each do |column|
        board[row][column] = Knight.new([row,column],color)
      end
      [2,5].each do |column|
        board[row][column] = Bishop.new([row,column],color)
      end
      board[row][3] = Queen.new([row,3],color)
      board[row][4] = King.new([row,4],color)
    end
    board
  end

  def get_tile(pos)
    row, col = pos
    @tiles[row][col]
  end

  def move(old_pos, new_pos, color)
    raise ArgumentError.new "No piece there!" if get_tile(old_pos).nil?
    raise ArgumentError.new "Not your color!" if get_tile(old_pos).color != color
    raise ArgumentError.new "Illegal move" unless get_tile(old_pos).uninhibited_moves(self).include?(new_pos)
    raise ArgumentError.new "That move puts you in check" unless valid_move?(old_pos, new_pos)
    perform_move(old_pos, new_pos)

  end

  def perform_move(old_pos, new_pos)
    x1, y1 = old_pos
    x2, y2 = new_pos
    piece = @tiles[x1][y1]
    @tiles[x2][y2] = piece
    piece.location = [x2, y2]
    @tiles[x1][y1] = nil
  end

  def valid_move?(old_pos,new_pos)
    duped_board = Marshal.load( Marshal.dump(self) )
    duped_board.perform_move(old_pos,new_pos)
    !duped_board.in_check?(get_tile(old_pos).color)
  end

  def king_location(color)
    colored_pieces(color).detect {|piece| piece.is_a?(King)}.location
  end

  def in_check?(color)
    color == :black ? opp_color = :white : opp_color = :black
    colored_pieces(opp_color).any? do |piece|
      piece.uninhibited_moves(self).include?(king_location(color))
    end
  end

  def colored_pieces(color)
    @tiles.flatten.compact.select{|piece| piece.color == color}
  end

  def in_checkmate?(color)
    colored_pieces(color).each do |piece|
      piece.uninhibited_moves(self).each do |move|
        return false if valid_move?(piece.location, move)
      end
    end
    true
  end

  def display
    puts `clear`
    print "    a  b  c  d  e  f  g  h "
    puts ""
    (0..7).each do |x|
      print " #{8-x} "
      (0..7).each do |y|
        if @tiles[x][y] == nil
          print "   "
        else
          print " #{@tiles[x][y].to_s} "
        end
      end
      puts ""
    end
  end

end

class Game
  def initialize(player1, player2)
    @player1 = player1
    @player2 = player2
    @board = Board.new
  end

  def play
    current_color = :white

    until @board.in_checkmate?(current_color)
      @board.display
      puts "It's #{current_color}'s turn to play"
      begin
        old_pos, new_pos = @player1.get_move
        @board.move(old_pos, new_pos, current_color)
      rescue ArgumentError => e
        puts "*********#{e.message}*********"
        retry
      end
      current_color == :white ? current_color = :black : current_color = :white
    end

    display_outcome(current_color)
  end

  def display_outcome(losing_color)
    @board.display
    puts "Game over, #{losing_color} loses!"
  end

end

class HumanPlayer
  attr_reader :name
  def initialize(name)
    @name = name
  end

  def get_move
    puts "Enter move in this format: e4 f6"
    input = gets.scan(/\w+/)
    input.map { |algebraic_coords| convert_move(algebraic_coords) }
  end

  def convert_move(coords)
    letter, num = coords[0], coords[1]
    [8 - num.to_i, "abcdefgh".index(letter)]
  end
end

if __FILE__ == $0
  game = Game.new(HumanPlayer.new("Player1"), HumanPlayer.new("Player2"))
  game.play
end

# board = Board.new
# board.move([6,5], [5,5])
# board.move([1,4], [3,4])
# board.move([6,6], [4,6])
# board.move([0,3], [4,7])