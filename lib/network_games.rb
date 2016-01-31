require 'network_games/board'

class NetworkGames
  class Board
    class Wall
      def traversable?
        false
      end
      def type
        :wall
      end
    end

    class Robot
      def traversable?
        true
      end
      def type
        :robot
      end
    end

    class Offmap
      def traversable?
        false
      end
      def type
        :off_map
      end
    end
  end
end
