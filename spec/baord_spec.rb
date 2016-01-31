require 'simplecov'
SimpleCov.start
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
    expect(board.at(x: 0, y: 0).map(&:type)).to eq []
    expect(board.at(x: 1, y: 0).map(&:type)).to eq [:wall]
    expect(board.at(x: 0, y: 1).map(&:type)).to eq []
    expect(board.at(x: 1, y: 1).map(&:type)).to eq [:robot]
  end

  it 'can be inspected' do
    board_for(" W\n R").inspect # shouldn't blow up
  end

  it 'knows whether a tile is traversable' do
    board = board_for " W\n R"
    expect(board).to     be_traversable(x: 0, y: 0)
    expect(board).to_not be_traversable(x: 1, y: 0)
    expect(board).to     be_traversable(x: 0, y: 1)
    expect(board).to     be_traversable(x: 1, y: 1)
  end

  it 'marks tiles off the map as off_map' do
    board = board_for "R"
    expect(board.at(x:  0, y:  0).map(&:type)).to eq [:robot]
    expect(board.at(x: -1, y:  0).map(&:type)).to eq [:off_map]
    expect(board.at(x:  1, y:  0).map(&:type)).to eq [:off_map]
    expect(board.at(x:  0, y:  1).map(&:type)).to eq [:off_map]
    expect(board.at(x:  0, y: -1).map(&:type)).to eq [:off_map]
  end

  specify 'off_map tiles are not traversable' do
    board = board_for " "
    expect(board).to     be_traversable(x:  0, y:  0)
    expect(board).to_not be_traversable(x: -1, y:  0)
  end

  it 'knows the relative positions of tiles' do
    board = board_for "WW\nWW"
    nw    = board.at(x: 0, y: 0)[0]
    ne    = board.at(x: 1, y: 0)[0]
    sw    = board.at(x: 0, y: 1)[0]
    se    = board.at(x: 1, y: 1)[0]

    expect(board.at_relative nw, x:  1).to eq [ne]
    expect(board.at_relative ne, x: -1).to eq [nw]

    expect(board.at_relative sw, x:  1).to eq [se]
    expect(board.at_relative se, x: -1).to eq [sw]

    expect(board.at_relative nw, y:  1).to eq [sw]
    expect(board.at_relative sw, y: -1).to eq [nw]

    expect(board.at_relative ne, y:  1).to eq [se]
    expect(board.at_relative se, y: -1).to eq [ne]
  end

  def assert_robot(board, x:, y:)
    # robot is where we expect
    robot = board.at(x: x, y: y)[0]
    expect(robot.type).to eq :robot

    # and not where we don't expect
    board.width.times do |x_crnt|
      board.height.times do |y_crnt|
        next if x_crnt == x && y_crnt == y
        obj = board.at(x: x_crnt, y: y_crnt)[0]
        expect(obj.type).to_not eq :robot if obj
      end
    end
  end

  it 'can move an object around the board, but doesn\'t move them until told to update' do
    board = board_for "R \n  "
    robot = board.at(x: 0, y: 0)[0]
    assert_robot board, x: 0, y: 0

    board.move_east(robot)
    assert_robot board, x: 0, y: 0
    board.update
    assert_robot board, x: 1, y: 0

    board.move_south(robot)
    assert_robot board, x: 1, y: 0
    board.update
    assert_robot board, x: 1, y: 1

    board.move_west(robot)
    assert_robot board, x: 1, y: 1
    board.update
    assert_robot board, x: 0, y: 1

    board.move_north(robot)
    assert_robot board, x: 0, y: 1
    board.update
    assert_robot board, x: 0, y: 0
  end
end
