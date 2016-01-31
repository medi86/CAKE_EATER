require 'gosu'

class GameWindow < Gosu::Window
  attr_accessor :rows

  def initialize(board, orientation:, tile_width:, tile_height:)
    lines = board.lines.map(&:chomp)
    super lines.first.length*tile_width, lines.length*tile_height
    self.caption = "Robot!"
    self.rows = lines.map.with_index do |line, y|
      line.chars.map.with_index do |char, x|
        case char
        when ' '
          type   = :blank
          colour = Gosu::Color::GRAY
        when '#'
          type   = :wall
          colour = Gosu::Color::WHITE
        when 'f'
          type   = :food
          colour = Gosu::Color::GREEN
        when 'r'
          type   = :robot
          colour = Gosu::Color::FUCHSIA
        else raise "What is the board character #{char.inspect}"
        end
        Tile.new(coords: [x, y], type: type, width: tile_width, height: tile_height, colour: colour)
      end
    end
    each_tile do |tile|
      tile.orient! orientation if tile.robot?
      next unless tile.wall?
      x, y = tile.coords
      tile.connects_left!  if 0   <= x-1           && rows[y][x-1].wall?
      tile.connects_right! if x+1 < rows[0].length && rows[y][x+1].wall?
      tile.connects_up!    if 0   <= y-1           && rows[y-1][x].wall?
      tile.connects_down!  if y+1 < rows.length    && rows[y+1][x].wall?
    end
    # @background_image = Gosu::Image.new("media/space.png", :tileable => true)
  end

  def each_tile
    rows.each do |row|
      row.each { |tile| yield tile }
    end
  end

  def update
    close if pressing_command? && button_down?(Gosu::KbW)
  end

  def pressing_command?
    defined?(Gosu::KbLeftMeta) && button_down?(Gosu::KbLeftMeta)
  end

  def draw
    each_tile do |tile|
      if    tile.food?  then draw_food  tile
      elsif tile.robot? then draw_robot tile
      elsif tile.wall?  then draw_wall  tile
      end
    end
  end

  def draw_circle(x:, y:, width:, height:, colour:, filled: false)
    if filled
      width.times do |xdist|
        xoff  = xdist - width/2.0
        angle = Math.acos(xoff/(width/2))
        yoff  = Math.sin(angle)*height/2
        draw_line x+xoff, y-yoff, colour, x+xoff, y+yoff, colour
      end
    else
      12.times do |i|
        angle1 = i*2*Math::PI/12
        angle2 = i.next*2*Math::PI/12
        draw_line x+Math.cos(angle1)*width/2, y+Math.sin(angle1)*height/2, colour,
                  x+Math.cos(angle2)*width/2, y+Math.sin(angle2)*height/2, colour
      end
    end
  end

  def draw_food(tile)
    draw_circle x: tile.x, y: tile.y, width: tile.width, height: tile.height, colour: tile.colour
  end

  def draw_robot(tile)
    head_center_x = tile.x
    head_center_y = tile.y-tile.height/3.0
    draw_line head_center_x, head_center_y, tile.colour, tile.x-tile.width/3.0-1, tile.y-tile.height*3/4.0, tile.colour
    draw_line head_center_x, head_center_y, tile.colour, tile.x+tile.width/3.0,   tile.y-tile.height*3/4.0, tile.colour
    draw_circle x:      head_center_x,
                y:      head_center_y,
                width:  tile.width*2/3,
                height: tile.height*2/3,
                colour: tile.colour,
                filled: true
    draw_triangle tile.x,                  tile.y-tile.height/4.0, tile.colour,
                  tile.x-tile.width/3.0-2, tile.y+tile.height/4.0, tile.colour,
                  tile.x+tile.width/3.0,   tile.y+tile.height/4.0, tile.colour
    draw_line tile.x-tile.width/5.0, tile.y+tile.height/4.0, tile.colour,
              tile.x-tile.width/5.0, tile.y+tile.height/2.0, tile.colour
    draw_line tile.x+tile.width/5.0, tile.y+tile.height/4.0, tile.colour,
              tile.x+tile.width/5.0, tile.y+tile.height/2.0, tile.colour
  end

  def draw_wall(tile)
    if tile.isolated?
      draw_line tile.x_left,  tile.y_up,   tile.colour, tile.x_right, tile.y_up,   tile.colour
      draw_line tile.x_left,  tile.y_down, tile.colour, tile.x_right, tile.y_down, tile.colour
      draw_line tile.x_left,  tile.y_up,   tile.colour, tile.x_left,  tile.y_down, tile.colour
      draw_line tile.x_right, tile.y_up,   tile.colour, tile.x_right, tile.y_down, tile.colour
    end
    draw_line tile.x, tile.y, tile.colour, tile.x_left,  tile.y,      tile.colour if tile.connects_left?
    draw_line tile.x, tile.y, tile.colour, tile.x_right, tile.y,      tile.colour if tile.connects_right?
    draw_line tile.x, tile.y, tile.colour, tile.x,       tile.y_up,   tile.colour if tile.connects_up?
    draw_line tile.x, tile.y, tile.colour, tile.x,       tile.y_down, tile.colour if tile.connects_down?
  end
end

class Tile
  attr_accessor :coords, :type, :width, :height, :colour, :orientation
  def initialize(coords:, type:, width:, height:, colour: Gosu::Color::WHITE, orientation: :north)
    self.coords      = coords
    self.type        = type
    self.width       = width
    self.height      = height
    self.colour      = colour
    self.orientation = orientation
  end

  def food?()  type == :food  end
  def robot?() type == :robot end
  def wall?()  type == :wall  end

  def orient!(orientation)
    self.orientation = orientation
  end

  def x
    coords[0]*width + width/2
  end

  def y
    coords[1]*width + width/2
  end

  def x_left
    x - width/2
  end

  def x_right
    x + width/2
  end

  def y_up
    y - height/2
  end

  def y_down
    y + height/2
  end

  def isolated?
    !connects_up? && !connects_down? && !connects_right? && !connects_left?
  end
  def connects_up!()    @connects_up    = true end
  def connects_up?()    @connects_up           end
  def connects_down?()  @connects_down         end
  def connects_down!()  @connects_down  = true end
  def connects_left?()  @connects_left         end
  def connects_left!()  @connects_left  = true end
  def connects_right?() @connects_right        end
  def connects_right!() @connects_right = true end
end

window = GameWindow.new <<-BOARD, orientation: :east, tile_width: 10, tile_height: 10
################################################################################
#                                                                              #
#  f                                                                           #
###                                      #                                     #
###############################                                                #
#                             #                                                #
#                             #                                                #
#                    f        #                                                #
#                             #          #    #                                #
#                             #                                                #
#                             #                                                #
#                             #                                                #
#           f                 #                                                #
#                             #                                                #
#                             #   f                                            #
#                             #                                                #
#                             #                                                #
#                    r        ###                                              #
#                                                                              #
#                                                                              #
#                                                                              #
#                                                                              #
#                                                                              #
#                                                                              #
#                                                                              #
#                                                                              #
#                                                                              #
#                                                                              #
#                                                                              #
#                                                                              #
#                                                                              #
#                                                                              #
#                                                                              #
#                                                                              #
#                                                                              #
#                                                                              #
#                                                                              #
#                                                                              #
#                                                                              #
#                                                                              #
#                                                                              #
#                                                                              #
#                                                                              #
#                                                                              #
#                                                                              #
#                                                                              #
#                                                                              #
#                                                                              #
#                                                                              #
#                                                                              #
#                                                                              #
#                                                                              #
#                                                                              #
#                                                                              #
#                                                                              #
#                                                                              #
#                                                                              #
#                                                                              #
#                                                                              #
################################################################################
BOARD

window.show
