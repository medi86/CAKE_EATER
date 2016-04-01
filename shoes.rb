class Cell
  def initialize(cell, data)
    @cell = cell
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
  def initialize(app)
    @app  = app
    @data = nil
  end


  def update(data)
    return if data == @data
    @stack && @stack.remove
    @stack = @app.stack top: 0, left: 0, height: 1.0
    @stack.background @stack.rgb(0xDD, 0x88, 0xFF)
    @data = data

    num_rows = data['board']['height']
    num_cols = data['board']['width']
    rows = Array.new(data['board']['height']) do |y|
      Array.new(data['board']['width']) do |x|
        {'type'=>'empty', 'y' => y, 'x' => x}
      end
    end
    data['board']['tiles'].each do |tile|
      rows[tile['y']][tile['x']] = tile
    end

    rows.map do |row|
      shoes_row = @stack.flow height: 1.0/num_rows
      row.each do |cell|
        Cell.new shoes_row.flow(width: 1.0/num_cols, height: 1.0), cell
      end
    end
  end
end


if __FILE__ == $PROGRAM_NAME
  app   = Shoes.app width: 900, height: 1000
  board = Board.new(app)

  require 'json'

  app.every 0.3 do
    filename = 'board.json'
    if File.exist? filename
      data = JSON.parse File.read(filename)
      board.update data
    end
  end

  # File.write filename, '{"status":"in_progress","board":{"height":5,"width":5,"tiles":[{"type":"wall","x":0,"y":0,"traversable":false},{"type":"wall","x":1,"y":0,"traversable":false},{"type":"wall","x":2,"y":0,"traversable":false},{"type":"wall","x":3,"y":0,"traversable":false},{"type":"wall","x":4,"y":0,"traversable":false},{"type":"wall","x":0,"y":1,"traversable":false},{"type":"cake","x":1,"y":1,"traversable":true},{"type":"wall","x":4,"y":1,"traversable":false},{"type":"wall","x":0,"y":2,"traversable":false},{"type":"cake","x":2,"y":2,"traversable":true},{"type":"wall","x":4,"y":2,"traversable":false},{"type":"wall","x":0,"y":3,"traversable":false},{"type":"wall","x":4,"y":3,"traversable":false},{"type":"wall","x":0,"y":4,"traversable":false},{"type":"wall","x":1,"y":4,"traversable":false},{"type":"wall","x":2,"y":4,"traversable":false},{"type":"wall","x":3,"y":4,"traversable":false},{"type":"wall","x":4,"y":4,"traversable":false},{"type":"robot","x":1,"y":3,"traversable":true,"name":"team1","score":0,"num_moves":0,"plan":null},{"type":"robot","x":2,"y":1,"traversable":true,"name":"team2","score":0,"num_moves":0,"plan":null}]},"cake_remaining":2,"leaderboard":[{"name":"team1","score":0},{"name":"team2","score":0}],"users":[{"username":"team1"},{"username":"team2"}]}'

  # json1 = JSON.parse <<-JSON
# {"status":"in_progress","board":{"height":5,"width":5,"tiles":[{"type":"wall","x":0,"y":0,"traversable":false},{"type":"wall","x":1,"y":0,"traversable":false},{"type":"wall","x":2,"y":0,"traversable":false},{"type":"wall","x":3,"y":0,"traversable":false},{"type":"wall","x":4,"y":0,"traversable":false},{"type":"wall","x":0,"y":1,"traversable":false},{"type":"cake","x":1,"y":1,"traversable":true},{"type":"wall","x":4,"y":1,"traversable":false},{"type":"wall","x":0,"y":2,"traversable":false},{"type":"cake","x":2,"y":2,"traversable":true},{"type":"wall","x":4,"y":2,"traversable":false},{"type":"wall","x":0,"y":3,"traversable":false},{"type":"wall","x":4,"y":3,"traversable":false},{"type":"wall","x":0,"y":4,"traversable":false},{"type":"wall","x":1,"y":4,"traversable":false},{"type":"wall","x":2,"y":4,"traversable":false},{"type":"wall","x":3,"y":4,"traversable":false},{"type":"wall","x":4,"y":4,"traversable":false},{"type":"robot","x":1,"y":3,"traversable":true,"name":"team1","score":0,"num_moves":0,"plan":null},{"type":"robot","x":2,"y":1,"traversable":true,"name":"team2","score":0,"num_moves":0,"plan":null}]},"cake_remaining":2,"leaderboard":[{"name":"team1","score":0},{"name":"team2","score":0}],"users":[{"username":"team1"},{"username":"team2"}]}
  # JSON
  # json2 = JSON.parse <<-JSON
# {"status":"in_progress","board":{"height":5,"width":5,"tiles":[{"type":"empty","x":0,"y":0,"traversable":false},{"type":"wall","x":1,"y":0,"traversable":false},{"type":"wall","x":2,"y":0,"traversable":false},{"type":"wall","x":3,"y":0,"traversable":false},{"type":"wall","x":4,"y":0,"traversable":false},{"type":"wall","x":0,"y":1,"traversable":false},{"type":"cake","x":1,"y":1,"traversable":true},{"type":"wall","x":4,"y":1,"traversable":false},{"type":"wall","x":0,"y":2,"traversable":false},{"type":"cake","x":2,"y":2,"traversable":true},{"type":"wall","x":4,"y":2,"traversable":false},{"type":"wall","x":0,"y":3,"traversable":false},{"type":"wall","x":4,"y":3,"traversable":false},{"type":"wall","x":0,"y":4,"traversable":false},{"type":"wall","x":1,"y":4,"traversable":false},{"type":"wall","x":2,"y":4,"traversable":false},{"type":"wall","x":3,"y":4,"traversable":false},{"type":"wall","x":4,"y":4,"traversable":false},{"type":"robot","x":1,"y":3,"traversable":true,"name":"team1","score":0,"num_moves":0,"plan":null},{"type":"robot","x":2,"y":1,"traversable":true,"name":"team2","score":0,"num_moves":0,"plan":null}]},"cake_remaining":2,"leaderboard":[{"name":"team1","score":0},{"name":"team2","score":0}],"users":[{"username":"team1"},{"username":"team2"}]}
  # JSON

  # jsons = [json1, json2].cycle

  # app.animate do |i|
  #   if i % 100
  #     board.update(jsons.next)
  #   end
  # end
end
