class NetworkGames
  class TimeControl
    def initialize(time_class=Time)
      @time_class = time_class
      @countdowns = {}
    end

    def remaining(name)
      start_time, duration, called, block = @countdowns.fetch name
      duration - seconds_since(start_time)
    end

    def register(name, duration, &block)
      @countdowns[name] = [current_time, duration, false, block]
    end

    def call(name)
      start_time, duration, called, block = @countdowns.fetch name
      @countdowns[name] = start_time, duration, true, block
      block.call
    end

    def check
      @countdowns.select do |name, (start_time, duration, called, block)|
        !called && (duration-seconds_since(start_time)) <= 0
      end.each do |name, (start_time, duration, called, block)|
        call(name)
      end
    end

    private

    def seconds_since(time)
      current_time - time
    end

    def current_time
      @time_class.now
    end
  end
end
