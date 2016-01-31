class Game
  class Board
    InvalidAscii = Class.new RuntimeError

    def self.from_ascii(ascii, tiles:)
      rows = ascii.lines.map(&:chomp).map(&:chars)
      new width: rows.fetch(0, []).length, height: rows.length do |board|
        board.each_tile do |tile|
          char  = rows[tile.y][tile.x]
          klass = tiles.fetch(char) do
            raise InvalidAscii, "#{char.inspect} not in #{tiles.keys.inspect}"
          end
          tile << klass.new(tile) if klass
        end
      end
    end

    attr_reader :width, :height
    def initialize(width:, height:)
      @width  = width
      @height = height
      @queue  = []
      @rows   = Array.new(height) do |y|
        Array.new(width) { |x| Tile.new x: x, y: y, board: self }
      end
      yield self if block_given?
    end

    def inspect
      "<#{self.class} #{@rows.flatten.map { |t| "\n  #{t.inspect}" }.join}>"
    end

    def each_tile
      @rows.each do |row|
        row.each { |tile| yield tile }
      end
    end

    def [](x, y)
      return nil if x < 0
      return nil if width <= x
      return nil if y < 0
      return nil if height <= y
      @rows[y][x]
    end

    def enqueue(object, action)
      @queue << [object, action]
    end

    def update
      @queue.each do |object, action|
        old_tile = object.tile
        case action
        when :move_east  then new_tile = old_tile.east
        when :move_west  then new_tile = old_tile.west
        when :move_north then new_tile = old_tile.north
        when :move_south then new_tile = old_tile.south
        else raise "Invalid action! #{action.inspect} for #{object.inspect}"
        end
        new_tile << old_tile.delete(object)
      end
      @queue = []
      self
    end
  end
end

class Game
  class Board
    class Tile
      attr_reader :x, :y
      def initialize(x:, y:, board:)
        @x, @y = x, y
        @board = board
        @elements = []
      end

      def <<(element)
        @elements << element
        element.tile = self
        self
      end

      def delete(element)
        @elements.delete element
        element.tile = nil
        element
      end

      def [](index)
        @elements[index]
      end

      def inspect
        "#<Tile x=#{x}, y=#{y} #{@elements.inspect}>"
      end

      def traversable?
        @elements.all? &:traversable?
      end

      def east()  @board[x+1,   y] end
      def west()  @board[x-1,   y] end
      def north() @board[x,   y-1] end
      def south() @board[x,   y+1] end
      def enqueue(object, action)
        @board.enqueue object, action
      end
    end
  end
end

class Game
  class Board
    class Element
      attr_accessor :tile
      def initialize(tile)
        self.tile = tile
      end
      def type
        @type ||= self.class.to_s.downcase.split("::").last.intern
      end
      def inspect
        "#<#{self.class.name.split("::").last}>"
      end
      def traversable?
        true
      end
      def x
        tile.x
      end
      def y
        tile.y
      end
      def enqueue(action)
        tile.enqueue self, action
      end
    end
  end
end

class Game
  class Board
    class Wall < Element
      def traversable?
        false
      end
    end
  end
end

class Game
  class Board
    module Movable
      def move_east()  enqueue :move_east  end
      def move_south() enqueue :move_south end
      def move_north() enqueue :move_north end
      def move_west()  enqueue :move_west  end
    end
  end
end

class Game
  class Board
    class Robot < Element
      include Movable
    end
  end
end
