module CakeEater
  class Cell
    def initialize(cell, data)
      @cell = cell
      update data
    end

    def update(data)
      return if data == @data
      @data = data
      remove
      case data['type']
      when 'cake'
        @img = @cell.image 'cake.png', width: 1.0, height: 1.0
      when 'robot'
        @img  = @cell.image 'robot.png', width: 1.0, height: 0.5
        @para = @cell.para data['name'], width: 1.0, height: 0.5
      when 'wall'
        @img = @cell.image 'tiles.png', width: 1.0, height: 1.0
      when 'empty'
        # noop
      else
        @para = @cell.para width: 1.0, height: 1.0
        @para.text = data['type']
      end
    end

    def remove
      @para && @para.remove
      @img  && @img.remove
      @para = @img = nil
    end
  end

  class Board
    def initialize(app, data)
      @app   = app
      @data  = data
      @stack = @app.stack top: 0, left: 0, height: 1.0
      @stack.background @stack.rgb(0xDD, 0x88, 0xFF)
      @shoes_rows = rows.map do |row|
        shoes_row = @stack.flow height: 1.0/num_rows
        row.map do |cell|
          Cell.new shoes_row.flow(width: 1.0/num_cols, height: 1.0), cell
        end
      end
    end

    def update(data)
      return if data == @data
      @data = data
      rows.each do |row|
        row.each { |cell| @shoes_rows[cell['y']][cell['x']].update(cell) }
      end
    end

    def rows
      rows = Array.new(@data['board']['height']) do |y|
        Array.new(@data['board']['width']) do |x|
          {'type'=>'empty', 'y' => y, 'x' => x, 'traversable' => true}
        end
      end
      @data['board']['tiles'].each do |tile|
        rows[tile['y']][tile['x']] = tile
      end
      rows
    end

    def num_rows
      @data['board']['height']
    end

    def num_cols
      @data['board']['width']
    end
  end
end


if __FILE__ == $PROGRAM_NAME
  filename = File.realdirpath('board.json', __dir__)
  require 'json'
  data     = JSON.parse File.read(filename)
  app      = Shoes.app width: 800, height: 1000
  board    = CakeEater::Board.new(app, data)

  require 'json'

  app.every 0.3 do
    data = JSON.parse File.read(filename)
    board.update data
  end

# {"status":"in_progress",
#  "board":{"height":5,"width":5,"tiles":[{"type":"wall","x":0,"y":0,"traversable":false},{"type":"wall","x":1,"y":0,"traversable":false},{"type":"wall","x":2,"y":0,"traversable":false},{"type":"wall","x":3,"y":0,"traversable":false},{"type":"wall","x":4,"y":0,"traversable":false},{"type":"wall","x":0,"y":1,"traversable":false},{"type":"cake","x":1,"y":1,"traversable":true},{"type":"wall","x":4,"y":1,"traversable":false},{"type":"wall","x":0,"y":2,"traversable":false},{"type":"cake","x":2,"y":2,"traversable":true},{"type":"wall","x":4,"y":2,"traversable":false},{"type":"wall","x":0,"y":3,"traversable":false},{"type":"wall","x":4,"y":3,"traversable":false},{"type":"wall","x":0,"y":4,"traversable":false},{"type":"wall","x":1,"y":4,"traversable":false},{"type":"wall","x":2,"y":4,"traversable":false},{"type":"wall","x":3,"y":4,"traversable":false},{"type":"wall","x":4,"y":4,"traversable":false},{"type":"robot","x":1,"y":3,"traversable":true,"name":"team1","score":0,"num_moves":0,"plan":null},{"type":"robot","x":2,"y":1,"traversable":true,"name":"team2","score":0,"num_moves":0,"plan":null}]},"cake_remaining":2,"leaderboard":[{"name":"team1","score":0},{"name":"team2","score":0}],"users":[{"username":"team1"},{"username":"team2"}]}
end
