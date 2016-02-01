class NetworkGames
  class Board
    InvalidAscii = Class.new RuntimeError

    class Tile
      attr_reader :x, :y, :plan
      def initialize(x:, y:)
        move! x: x, y: y
      end
      def at?(x:, y:)
        x() == x && y() == y
      end
      def position
        {x: x, y: y}
      end
      def plan_move(x: x(), y: y())
        @plan = {x: x, y: y}
      end
      def clear_plan!
        @plan = nil
      end
      def perform_move!
        move! @plan if move_planned?
      ensure
        clear_plan!
      end
      def move!(x: x(), y: y())
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
      def move_planned?
        @plan && @plan.kind_of?(Hash) && plan.keys.sort == [:x, :y]
      end
      def grid_coords
        [-1, 0, 1].flat_map do |yoff|
          [-1, 0, 1].map { |xoff| relative_position x: xoff, y: yoff }
        end
      end
      def as_json
        {type: type, x: x, y: y, traversable: traversable?}
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

    def at(coords)
      return [OffMap.new(coords)] unless on_board? coords
      @tiles.select { |obj| obj.at? coords }
    end

    def on_board?(x:, y:)
      0 <= x && 0 <= y && x < width && y < height
    end

    def at_relative(obj, x:0, y:0)
      at obj.relative_position(x: x, y: y)
    end

    def traversable?(x:, y:)
      at(x: x, y: y).all? &:traversable?
    end

    def find_empties
      width.times.flat_map do |x|
        height.times.select { |y| at(x: x, y: y).empty? }.map { |y| [x, y] }
      end
    end

    def update
      @tiles.each { |object| object.perform_move! }
      self
    end

    def move_relative(obj, x: 0, y: 0)
      obj.plan_move obj.relative_position(x: x, y: y)
      self
    end

    include Enumerable
    def each(&block)
      @tiles.each &block
    end

    def as_json
      { height: height, width:  width, tiles:  @tiles.map(&:as_json) }
    end
  end
end
