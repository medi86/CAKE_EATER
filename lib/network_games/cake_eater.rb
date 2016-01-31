require 'network_games/board'

class NetworkGames
  class CakeEater
    class Cake
      def traversable?() true end
      def type() :cake end
    end

    class Robot < NetworkGames::Board::Robot
      attr_reader :name, :move, :score, :num_moves
      def initialize(name:, score: 0, num_moves: 0)
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
      robot = Robot.new(name: name)
      robots[name] = robot
      board.add robot, x: x, y: y
      { name: name, x: x, y: y, score: 0 }
    end

    def move_north(name) robots[name].will_move :north end
    def move_east(name)  robots[name].will_move :east  end
    def move_south(name) robots[name].will_move :south end
    def move_west(name)  robots[name].will_move :west  end

    def tick
      robots
        .map { |name, robot| robot }
        .select { |robot| robot.move }
        .each { |robot|
          if robot.move == :eat
            x, y = board.locate(robot)
            cake = board.at(x: x, y: y).find { |element| element.type == :cake }
            next unless cake
            board.remove cake
            robot.make_move
            robot.eat cake
          else
            x, y = board.locate(robot)
            y -= 1 if robot.move == :north
            x += 1 if robot.move == :east
            y += 1 if robot.move == :south
            x -= 1 if robot.move == :west
            next unless board.traversable?(x: x, y: y)
            board.move robot, robot.make_move
          end
          robot.will_move nil
        }
      board.update
    end

    def look(name)
      robot = robots[name]
      x, y = board.locate robot
      { name:  robot.name,
        score: robot.score,
        x: x,
        y: y,
        grid: [-1, 0, 1].flat_map { |yoff|
          [-1, 0, 1].map { |xoff|
            xcrnt    = x + xoff
            ycrnt    = y + yoff
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
      x, y = board.locate robots[name]
      {x: x, y: y}
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
