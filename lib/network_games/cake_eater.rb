require 'network_games/board'

class NetworkGames
  class CakeEater
    class Cake < Board::Tile
      def traversable?() true end
      def type() :cake end
    end

    class Robot < Board::Robot
      attr_reader :name, :move, :score, :num_moves
      def initialize(name:, score: 0, num_moves: 0, **kwrest)
        super(**kwrest)
        @name      = name
        @score     = score
        @num_moves = num_moves
      end
      def will_move(direction)
        @move = direction
      end
      def make_move
        @num_moves += 1
        move_made = move
        @move = nil
        move_made
      end
      def eat(cake)
        @score += 1
      end
    end

    attr_reader :board, :robots
    def initialize(board)
      @board  = board
      @robots = {}
    end

    def join(name:, x: nil, y: nil)
      return nil if @robots.any? { |robot_name, robot| robot_name == name }
      x, y  = find_xy(x, y)
      return nil if !x
      robot = Robot.new(name: name, x: x, y: y)
      robots[name] = robot
      board.add robot
      { name: name, x: x, y: y, score: 0 }
    end

    def move_north(name) robots[name].will_move xoff:  0, yoff: -1 end
    def move_east(name)  robots[name].will_move xoff:  1, yoff:  0 end
    def move_south(name) robots[name].will_move xoff:  0, yoff:  1 end
    def move_west(name)  robots[name].will_move xoff: -1, yoff:  0 end

    def tick
      robots
        .map { |name, robot| robot }
        .select { |robot| robot.move }
        .each { |robot|
          if robot.move == :eat
            cake = board.at(robot.position).find { |element| element.type == :cake }
            next unless cake
            board.remove cake
            robot.make_move
            robot.eat cake
          else
            x = robot.move[:xoff]
            y = robot.move[:yoff]
            xy = robot.relative_position(x: x, y: y)
            next unless board.traversable?(xy)
            board.move_relative robot, robot.make_move
          end
          robot.will_move nil
        }
      board.update
    end

    def look(name)
      robot = robots[name]
      xy    = robot.position
      { name:  robot.name,
        score: robot.score,
        x: xy[:x],
        y: xy[:y],
        grid: [-1, 0, 1].flat_map { |yoff|
          [-1, 0, 1].map { |xoff|
            xcrnt    = xy[:x] + xoff
            ycrnt    = xy[:y] + yoff
            contents = board.at(x: xcrnt, y: ycrnt).map do |obj|
              content = {type: obj.type}
              content[:name] = obj.name if obj.type == :robot
              content
            end
            {x: xcrnt, y: ycrnt, contents: contents }
          }
        }
      }
    end

    def eat_cake(name)
      robots[name].will_move :eat
    end

    def over?
      board.none? { |obj, x, y| obj.type == :cake }
    end

    def num_moves(name)
      robots[name].num_moves
    end

    def coords(name)
      robots[name].position
    end

    def leaderboard
      robots.map { |name, robot| robot }
            .sort_by { |robot| -robot.score }
            .map { |robot| {name: robot.name, score: robot.score} }
    end

    private

    def find_xy(x, y)
      empties = board.find_empties
      if x && y
        empties.find { |newx, newy| x == newx && y == newy }
      elsif x
        empties.select { |newx, newy| newx == x }.sample
      elsif y
        empties.select { |newx, newy| newy == y }.sample
      else
        empties.sample
      end
    end
  end
end
