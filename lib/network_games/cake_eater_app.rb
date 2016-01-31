require 'network_games/cake_eater'

class NetworkGames
  class TimeControl
    def initialize(time_class=Time)
      @time_class = time_class
      @countdowns = {}
    end

    def remaining(name)
      start_time, duration, block = @countdowns.fetch name
      duration - seconds_since(start_time)
    end

    def register(name, duration, &block)
      @countdowns[name] = [current_time, duration, block]
    end

    def call(name)
      start_time, duration, block = @countdowns.fetch name
      block.call
    end

    private

    def seconds_since(time)
      current_time - time
    end

    def current_time
      @time_class.now
    end
  end

  class CakeEaterApp
    attr_reader :board, :game, :timer, :status
    def initialize(registration_time: 5*60, timer: TimeControl.new, users:[])
      ascii_board = 30.times.map { Array.new(40, ' ').join }.join("\n")
      @board = NetworkGames::Board.from_ascii ascii_board, tiles: {
        ' ' => nil,
        '#' => NetworkGames::Board::Wall,
        'C' => NetworkGames::CakeEater::Cake,
      }

      @game = NetworkGames::CakeEater.new(board)

      users.each { |credentials| @game.join name: credentials.fetch(:username) }

      @users  = users
      @timer  = timer
      @status = :registration
      timer.register :game_start, registration_time do
        @status = :in_progress
      end
    end

    def call(env)
      status, headers, body = 200, {}, []
      case env['PATH_INFO']
      when '/cake_eater'
        json = {status: self.status, cake_remaining: game.cake_remaining, leaderboard: game.leaderboard}
        body << JSON.dump(json)
      when %r(^/cake_eater/robots/(.+))
        team_name = $1
        username  = authenticate(env['HTTP_AUTHORIZATION'])
        if @users.none? { |credentials| credentials[:username] == team_name }
          json = {error: "There is no robot named #{team_name.inspect}, known names: #{@users.map { |credentials| credentials[:username] }.inspect}"}
          body << JSON.dump(json)
          status = 404
        elsif !username
          json = {error: "You need to provide your username and password, eg #{env['rack.url_scheme']}://#{team_name}:SecretPassword@#{env['HTTP_HOST']}#{env['PATH_INFO']}"}
          body << JSON.dump(json)
          status = 401
        elsif username != team_name
          json = {error: "Your credentials do not allow you to see the requested robot" }
          body << JSON.dump(json)
          status = 403
          team_name == username
        else
          json = game.look team_name
          json[:actions] = [:eat_cake, :move_north, :move_east, :move_south, :move_west]
          body << JSON.dump(json)
          status = 200
        end
      else raise "UNHANDLED PATH: #{env['PATH_INFO']}"
      end
      [status, headers, body]
    end

    private

    def authenticate(auth_header)
      username, password = username_and_password(auth_header)
      username &&
        password &&
        @users.find { |credentials| credentials[:username] == username && credentials[:password] == password } &&
        username
    end

    def username_and_password(auth_header)
      authorization = auth_header.to_s.chomp.split.last
      return unless authorization
      username, password = authorization.unpack("m").first.split(":")
    end
  end
end
