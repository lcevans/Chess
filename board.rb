
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
    @moves_since_capture = 0
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

  def castle_move(old_king_pos, old_rook_pos, color)
    if old_rook_pos.last == 0
      new_king_pos = [old_king_pos.first, old_king_pos.last-2]
      new_rook_pos = [new_king_pos.first, new_king_pos.last+1]
    else
      new_king_pos = [old_king_pos.first, old_king_pos.last+2]
      new_rook_pos = [new_king_pos.first, new_king_pos.last-1]
    end
    raise ArgumentError.new "That move puts you in check" unless valid_move?(old_king_pos, new_king_pos)
    raise ArgumentError.new "Cannot castle when in check" if in_check?(color)
    perform_move(old_king_pos, new_king_pos)
    perform_move(old_rook_pos, new_rook_pos)
  end

  def perform_move(old_pos, new_pos)
    x1, y1 = old_pos
    x2, y2 = new_pos
    piece = @tiles[x1][y1]
    piece.has_moved = true if piece.is_a?(King) || piece.is_a?(Rook)
    former_occupant = @tiles[x2][y2]
    if former_occupant then @moves_since_capture = 0 else @moves_since_capture += 1 end

    @tiles[x2][y2] = piece
    piece.location = [x2, y2]
    @tiles[x1][y1] = nil
  end

  def valid_move?(old_pos,new_pos)
    duped_board = Marshal.load( Marshal.dump(self) )
    duped_board.perform_move(old_pos,new_pos)
    !duped_board.in_check?(get_tile(old_pos).color)
  end

  def valid_moves(old_pos)
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

  def is_over?(color)
    in_stalemate?(color) || @moves_since_capture > 50
  end

  def in_checkmate?(color)
    in_stalemate?(color) && in_check?(color)
  end

  def in_stalemate?(color)
    colored_pieces(color).each do |piece|
      piece.uninhibited_moves(self).each do |move|
        return false if valid_move?(piece.location, move)
      end
    end
    true
  end

  def check_pawn_promotion(color)
    color == :black ? end_row = 7 : end_row = 0
    colored_pieces(color).detect do |piece|
      piece.location.first == end_row && piece.is_a?(Pawn)
    end
  end

  def promote_pawn(pawn, piece_to_promote)
    valid_pieces = ["queen", "bishop", "rook", "knight"]
    x,y = pawn.location
    color = pawn.color
    case piece_to_promote
    when "queen"
      @tiles[x][y] = Queen.new([x,y], color)
    when "bishop"
      @tiles[x][y] = Bishop.new([x,y], color)
    when "rook"
      @tiles[x][y] = Rook.new([x,y], color)
    when "knight"
      @tiles[x][y] = Knight.new([x,y], color)
    else
      raise ArgumentError.new "Not a valid piece"
    end
  end
end
