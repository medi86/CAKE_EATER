class NetworkGames
  class Board
    InvalidAscii = Class.new RuntimeError

    class Tile
      attr_reader :x, :y
      def initialize(x:, y:)
        move! x: x, y: y
      end
      def at?(x:, y:)
        x() == x && y() == y
      end
      def position
        {x: x, y: y}
      end
      def move!(x: x, y: y)
        @x, @y = x, y
      end
      def relative_position(x:, y:)
        {x: x()+x, y: y()+y}
      end
      def traversable?
        true
      end
      def type
        self.class.name.to_s.split("::").last.gsub(/([a-z])([A-Z])/, "\\1_\\2").downcase.intern
      end
    end

    class Wall < Tile
      def traversable?
        false
      end
    end

    class Robot < Tile
      def traversable?() true end
    end

    class OffMap < Tile
      def traversable?() false end
    end


    def self.from_ascii(ascii, tiles:)
      rows  = ascii.lines.map(&:chomp).map(&:chars)
      board = new width: rows.fetch(0, []).length, height: rows.length
      rows.each_with_index do |row, y|
        row.each_with_index do |char, x|
          klass = tiles.fetch(rows[y][x]) do
            raise InvalidAscii, "#{char.inspect} not in #{tiles.keys.inspect}"
          end
          next unless klass
          board.add klass.new(x: x, y: y)
        end
      end
      board
    end

    attr_reader :width, :height
    def initialize(width:, height:)
      @width  = width
      @height = height
      @queue  = []
      @tiles  = []
      yield self if block_given?
    end

    def add(obj)
      @tiles << obj
      self
    end

    def remove(obj)
      @tiles.delete obj
      self
    end

    def at(x:, y:)
      if x < 0 || y < 0 || width <= x || height <= y
        return [OffMap.new(x: x, y: y)]
      else
        @tiles.select { |obj| obj.at? x: x, y: y }
      end
    end

    def at_relative(obj, x:0, y:0)
      at obj.relative_position(x: x, y: y)
    end

    def traversable?(x:, y:)
      at(x: x, y: y).all? &:traversable?
    end

    def find_empties
      width.times.flat_map do |x|
        height.times
              .select { |y| at(x: x, y: y).empty? }
              .map    { |y| [x, y] }
      end
    end

    def update
      @queue.each { |object, coords| object.move! coords }
      @queue = []
      self
    end

    def move_relative(obj, xoff: 0, yoff: 0)
      @queue << [obj, obj.relative_position(x: xoff, y: yoff)]
      self
    end

    include Enumerable
    def each(&block)
      @tiles.each &block
    end
  end
end
