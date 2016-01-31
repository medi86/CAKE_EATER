require 'game'

RSpec.describe 'Game::Board' do
  it 'blows up if defined from unspecified ascii' do
    Game::Board.from_ascii " ", tiles: {' ' => nil}
    expect { Game::Board.from_ascii " ", tiles: {'a' => nil} }
      .to raise_error Game::Board::InvalidAscii
  end

  def board_for(ascii_map)
    Game::Board.from_ascii ascii_map, tiles: {'W' => Game::Board::Wall , 'R' => Game::Board::Robot, ' ' => nil}
  end

  it 'knows what is on each tile' do
    board = board_for " W\n R"
    expect(board[0, 0][0]).to be_nil
    expect(board[1, 0][0].type).to eq :wall
    expect(board[0, 1][0]).to be_nil
    expect(board[1, 1][0].type).to eq :robot
  end

  it 'can be inspected' do
    board_for(" W\n R").inspect # shouldn't blow up
  end

  it 'knows whether a tile is traversable' do
    board = board_for " W\n R"
    expect(board[0, 0]).to     be_traversable
    expect(board[1, 0]).to_not be_traversable
    expect(board[0, 1]).to     be_traversable
    expect(board[1, 1]).to     be_traversable
  end

  it 'returns nil for tiles that are off the map' do
    board = board_for " "
    expect(board[ 0,  0]).to be_traversable
    expect(board[-1,  0]).to be_nil
    expect(board[ 1,  0]).to be_nil
    expect(board[ 0,  1]).to be_nil
    expect(board[ 0, -1]).to be_nil
  end

  it 'links the tiles to each other' do
    board  = board_for "RW\n  "
    tileNW = board[0, 0]
    tileNE = board[1, 0]
    tileSW = board[0, 1]
    tileSE = board[1, 1]

    expect(tileNW.east).to equal tileNE
    expect(tileNE.west).to equal tileNW

    expect(tileSW.east).to equal tileSE
    expect(tileSE.west).to equal tileSW

    expect(tileNW.south).to equal tileSW
    expect(tileSW.north).to equal tileNW

    expect(tileNE.south).to equal tileSE
    expect(tileSE.north).to equal tileNE
  end

  def assert_robot(board, x:, y:)
    # robot is where we expect
    robot = board[x, y][0]
    expect(robot.type).to eq :robot
    expect(robot.x).to eq x
    expect(robot.y).to eq y

    # and not where we don't expect
    board.width.times do |x_crnt|
      board.height.times do |y_crnt|
        obj = board[x_crnt, y_crnt][0]
        if x_crnt == x && y_crnt == y
          expect(obj.type).to eq :robot
        else
          expect(obj.type).to_not eq :robot if obj
        end
      end
    end
  end

  it 'can move an object around the board, but doesn\'t move them until told to update' do
    board = board_for "R \n  "
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
    assert_robot board, x: 0, y: 1

    robot.move_north
    assert_robot board, x: 0, y: 1
    board.update
    assert_robot board, x: 0, y: 0
  end
end
