class NetworkGames
  class Board
    InvalidAscii = Class.new RuntimeError

    class Wall
      def traversable?() false end
      def type() :wall end
    end

    class Robot
      def traversable?() true end
      def type() :robot end
    end

    class Offmap
      def traversable?() false end
      def type() :off_map end
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
          board.add klass.new, x: x, y: y
        end
      end
      board
    end

    attr_reader :width, :height
    def initialize(width:, height:)
      @width  = width
      @height = height
      @queue  = []
      @tiles  = {}
      yield self if block_given?
    end

    def add(obj, x:, y:)
      @tiles[obj.object_id] = [obj, x, y]
    end

    def at(x:, y:)
      return [Offmap.new] if x < 0 || y < 0 || width <= x || height <= y
      @tiles.select { |id, (obj, objx, objy)| x == objx && y == objy }
            .map    { |id, (obj, objx, objy)| obj }
    end

    def at_relative(obj, x:0, y:0)
      x, y = relative_position(obj, x: x, y: y)
      at x: x, y: y
    end

    def traversable?(x:, y:)
      at(x: x, y: y).all? &:traversable?
    end

    def update
      @queue.each do |object, x, y|
        @tiles[object.object_id] = [object, x, y]
      end
      @queue = []
      self
    end

    def relative_position(obj, x:0, y:0)
      _, objx, objy = @tiles[obj.object_id]
      [objx+x, objy+y]
    end

    def move_east(obj)  @queue << [obj, *relative_position(obj, x:  1)] end
    def move_west(obj)  @queue << [obj, *relative_position(obj, x: -1)] end
    def move_south(obj) @queue << [obj, *relative_position(obj, y:  1)] end
    def move_north(obj) @queue << [obj, *relative_position(obj, y: -1)] end
  end
end
