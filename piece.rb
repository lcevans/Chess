# encoding: utf-8

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
  attr_accessor :has_moved

  def initialize(pos, color)
    super(pos, color)
    @has_moved = false
  end

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

  def castle_moves(board)
    return [] if @has_moved
    castling_moves = []
    color = self.color
    color == :black ? home_row = 0 : home_row = 7

    left_rook = board.tiles[home_row][0]
    right_rook = board.tiles[home_row][7]

    if left_rook.is_a?(Rook) && !left_rook.has_moved
      if [1,2,3].all? { |row| board.tiles[home_row][row].nil? }
        castling_moves << [[home_row, 4], [home_row, 0]]
      end
    end

    if right_rook.is_a?(Rook) && !right_rook.has_moved
      if [5,6].all? { |row| board.tiles[home_row][row].nil? }
        castling_moves << [[home_row, 4], [home_row, 7]]
      end
    end

    castling_moves
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
  attr_accessor :has_moved

  def initialize(pos, color)
    super(pos, color)
    @has_moved = false
  end

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