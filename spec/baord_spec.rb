require 'game'

RSpec.describe 'Game::Board' do
  it 'blows up if defined from unspecified ascii' do
    Game::Board.from_ascii " ", tiles: {' ' => :empty}
    expect { Game::Board.from_ascii " ", tiles: {'a' => :empty} }
      .to raise_error Game::Board::InvalidAscii
  end

  def board_for(ascii_map)
    Board.from_ascii " W\nWR", tiles: {'W' => Game::Board::Wall , 'R' => Game::Board::Robot, ' ' => nil}
  end

  it 'knows what is on each tile' do
    board = board_for " W\n R"
    expect(board[0, 0][0]).to be_nil
    expect(board[1, 0][0].type).to :wall
    expect(board[0, 1][0].type).to be_nil
    expect(board[1, 1][0].type).to :robot
  end

  it 'knows whether a tile is traversable' do
    board = board_for " W\n R"
    expect(board[0, 0]).to     be_traversable
    expect(board[1, 0]).to_not be_traversable
    expect(board[0, 1]).to     be_traversable
    expect(board[1, 1]).to     be_traversable
  end

  it 'makes tiles that are off the map untraversable' do
    board = board_for " "
    expect(board[ 0,  0]).to     be_traversable
    expect(board[-1,  0]).to_not be_traversable
    expect(board[ 1,  0]).to_not be_traversable
    expect(board[ 0,  1]).to_not be_traversable
    expect(board[ 0, -1]).to_not be_traversable
  end

  it 'links the tiles to each other' do
    board  = board_for "WW\nWW"
    tile00 = board[0, 0]
    tile01 = board[0, 1]
    tile10 = board[1, 0]
    tile11 = board[1, 1]

    expect(tile00.east).to equal tile01
    expect(tile01.west).to equal tile00

    expect(tile10.east).to equal tile11
    expect(tile11.west).to equal tile10

    expect(tile00.south).to equal tile01
    expect(tile01.north).to equal tile00

    expect(tile10.south).to equal tile11
    expect(tile11.north).to equal tile10
  end

  def assert_robot(board, x:, y:)
    # robot is where we expect
    robot = board[x, y][0]
    expect(robot.type).to eq :robot
    expect(robot.x).to eq x
    expect(robot.y).to ex y

    # and not where we don't expect
    board.width.times do |x_crnt|
      board.height.times do |y_crnt|
        obj = board[x_crnt, y_crnt][0]
        if x_crnt == x && y_crnt == y
          expect(obj.type).to_not eq :robot if obj
        else
          expect(obj.type).to eq :robot
        end
      end
    end
  end

  it 'can move an object around the board, but doesn\'t move them until told to update' do
    board = board_for "  \nR "
    robot = board[0, 0][0]
    assert_robot board, x: 0, y: 0

    robot.move_east
    assert_robot board, x: 0, y: 0
    board.update
    assert_robot board, x: 1, y: 0

    robot.move_south
    assert_robot board, x: 1, y: 0
    board.update
    assert_robot board, x: 1, y: 1

    robot.move_west
    assert_robot board, x: 1, y: 1
    board.update
    assert_robot board, x: 1, y: 1

    robot.move_north
    assert_robot board, x: 1, y: 1
    board.update
    assert_robot board, x: 0, y: 1
  end
end
