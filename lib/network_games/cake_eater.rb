require 'network_games/board'

class NetworkGames
  class CakeEater
    class Cake < Board::Tile
      def traversable?() true end
      def type() :cake end
    end

    class Robot < Board::Robot
      attr_reader :name, :score, :num_moves
      def initialize(name:, score: 0, num_moves: 0, **kwrest)
        super(**kwrest)
        @name      = name
        @score     = score
        @num_moves = num_moves
      end
      def perform_move!
        return unless plan
        @num_moves += 1
        @score     += 1 if plan == :eat
        super
      ensure
        clear_plan!
      end
      def plan_to_eat
        @plan = :eat
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

    def move_north(name) board.move_relative robots[name], x:  0, y: -1 end
    def move_east(name)  board.move_relative robots[name], x:  1, y:  0 end
    def move_south(name) board.move_relative robots[name], x:  0, y:  1 end
    def move_west(name)  board.move_relative robots[name], x: -1, y:  0 end

    def tick
      robots
        .map { |name, robot| robot }
        .each { |robot|
          if robot.plan == :eat
            cake = board.at(robot.position).find { |element| element.type == :cake }
            next unless cake
            board.remove cake
            robot.perform_move!
          else
            next unless robot.move_planned?
            next unless board.traversable?(robot.plan)
            robot.perform_move!
          end
        }
        .each(&:clear_plan!)
      board.update
    end

    def look(name)
      robot = robots[name]
      { name:  robot.name,
        score: robot.score,
        **robot.position,
        grid: robot.grid_coords.map { |coords|
          { **coords, contents: board.at(coords).map { |obj|
              {type: obj.type}.tap { |h| h[:name] = obj.name if obj.type == :robot }
            }
          }
        }
      }
    end

    def eat_cake(name)
      robots[name].plan_to_eat
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
