require 'spec_helper'
require 'network_games/cake_eater'

RSpec.describe 'NetworkGames::CakeEater' do
  it 'allows robots to join the game' do
    ce = ce_for <<~BOARD
      #####
      #C  #
      # C #
      #   #
      #####
    BOARD
    json = ce.join name: 'Josh', x: 2, y: 1
    expect(json[:name]).to eq 'Josh'
    expect(json[:x]).to    eq 2
    expect(json[:y]).to    eq 1
  end

  it 'assigns a random non-occupied space to each robot that joins' do
    xy_coords = 100.times.map do
      json = ce_for("# \n C").join(name: 'Josh')
      [json[:x], json[:y]]
    end
    expect(xy_coords.uniq.sort).to eq [[0, 1], [1, 0]]
  end

  it 'lets multiple robots join' do
    ce = ce_for("# \n C")
    expect(ce.join name: 'p1').to be_a_kind_of Hash
    expect(ce.join name: 'p2').to be_a_kind_of Hash
  end

  it 'does not allow multiple players to join with the same name' do
    ce = ce_for("  \n  ")
    expect(ce.join(name: 'p1', x: 1, y: 0)).to be_a_kind_of Hash
    expect(ce.join(name: 'p1', x: 0, y: 0)).to eq nil
    expect(ce.join(name: 'p2', x: 0, y: 0)).to be_a_kind_of Hash
  end

  it 'does not allow robots to join the game once it has reached its capacity' do
    ce = ce_for("# \n C")
    expect(ce.join name: 'p1').to be_a_kind_of Hash
    expect(ce.join name: 'p2').to be_a_kind_of Hash
    expect(ce.join name: 'p3').to eq nil
  end

  it 'is over when all the cake is eaten' do
    ce = ce_for("C \n C")
    ce.join(name: 'p1', x: 1, y: 0)
    ce.move_west('p1')
    ce.tick
    ce.eat_cake('p1')
    ce.tick
    ce.move_south('p1')
    ce.tick
    ce.move_east('p1')
    ce.tick
    ce.eat_cake('p1')
    expect(ce).to_not be_over
    ce.tick
    expect(ce).to     be_over
  end

  it 'records each robot\'s number of moves' do
    ce = ce_for("  \n C")
    ce.join(name: 'p1', x: 1, y: 0)
    ce.move_west('p1')
    expect(ce.num_moves 'p1').to eq 0
    ce.tick
    expect(ce.num_moves 'p1').to eq 1
    ce.tick
    expect(ce.num_moves 'p1').to eq 1
  end

  specify 'multiple moves in the same clock tick override each other' do
    ce = ce_for("# \n C")
    ce.join(name: 'p1', x: 1, y: 0)
    ce.move_west('p1')
    ce.move_south('p1')
    ce.tick
    expect(ce.num_moves 'p1').to eq 1
    expect(ce.coords 'p1').to eq x: 1, y: 1
  end

  it 'sets the winner to be the robot that ate the most cake' do
    ce = ce_for("  \n C\nCC")
    ce.join(name: 'p1', x: 1, y: 0)
    ce.join(name: 'p2', x: 0, y: 0)
    ce.move_south('p1')
    ce.move_south('p2')
    ce.tick
    ce.eat_cake('p1')
    ce.tick
    ce.move_south('p1')
    ce.move_south('p2')
    ce.tick
    ce.eat_cake('p1')
    ce.eat_cake('p2')
    ce.tick
    expect(ce).to be_over
    expect(ce.leaderboard).to eq [
      {name: 'p1', score: 2},
      {name: 'p2', score: 1},
    ]
  end

  it 'starts players with a score of 0, and gives them 1 point for each piece of cake they eat' do
    ce = ce_for("  \n C\nCC")
    p1 = ce.join(name: 'p1', x: 1, y: 0)
    expect(p1[:score]).to eq 0
    ce.move_south('p1')
    ce.tick
    ce.eat_cake('p1')
    expect(ce.look('p1')[:score]).to eq 0
    ce.tick
    expect(ce.look('p1')[:score]).to eq 1
  end

  it 'allows the robot to look around' do
    ce = ce_for("  \n C")
    ce.join(name: 'p1', x: 1, y: 0)
    ce.join(name: 'p2', x: 0, y: 0)

    expected = {name: 'p1', x: 1, y: 0, score: 0, plan: nil, grid: [
      {x: 0, y: -1, contents: [{type: :off_map}]},
      {x: 1, y: -1, contents: [{type: :off_map}]},
      {x: 2, y: -1, contents: [{type: :off_map}]},
      {x: 0, y:  0, contents: [{type: :robot, name: 'p2'}]},
      {x: 1, y:  0, contents: [{type: :robot, name: 'p1'}]},
      {x: 2, y:  0, contents: [{type: :off_map}]},
      {x: 0, y:  1, contents: []},
      {x: 1, y:  1, contents: [{type: :cake}]},
      {x: 2, y:  1, contents: [{type: :off_map}]},
    ]}

    expect(ce.look 'p1').to eq expected
    ce.eat_cake 'p1'
    expect(ce.look 'p1').to eq expected.merge(plan: :eat)
  end

  it 'allows multiple looks per robot per tick of the clock, they are not moves' do
    ce = ce_for("  \n C")
    ce.join(name: 'p1', x: 1, y: 0)
    expect(ce.look('p1')[:x]).to eq 1
    ce.move_west('p1')
    expect(ce.look('p1')[:x]).to eq 1
    expect(ce.look('p1')[:x]).to eq 1
    expect(ce.num_moves 'p1').to eq 0
    ce.tick
    expect(ce.look('p1')[:x]).to eq 0
    expect(ce.num_moves 'p1').to eq 1
  end

  it 'allows players to move north/east/south/west' do
    ce = ce_for("  \n C")
    ce.join(name: 'p1', x: 0, y: 0)

    ce.move_east('p1')
    ce.tick
    expect(ce.coords 'p1').to eq x: 1, y: 0

    ce.move_south('p1')
    ce.tick
    expect(ce.coords 'p1').to eq x: 1, y: 1

    ce.move_west('p1')
    ce.tick
    expect(ce.coords 'p1').to eq x: 0, y: 1

    ce.move_north('p1')
    ce.tick
    expect(ce.coords 'p1').to eq x: 0, y: 0
  end

  it 'does not allow players to move into walls or off the board' do
    ce = ce_for(" #\n  ")
    ce.join(name: 'p1', x: 0, y: 0)

    # into walls
    ce.move_east 'p1'
    expect(ce.look('p1')[:x]).to eq 0
    ce.tick
    expect(ce.look('p1')[:x]).to eq 0

    # off the board
    ce.move_west 'p1'
    ce.tick
    expect(ce.look('p1')[:x]).to eq 0

    # into available space
    expect(ce.look('p1')[:y]).to eq 0
    ce.move_south 'p1'
    ce.tick
    expect(ce.look('p1')[:y]).to eq 1
  end
end

# talk to it:
#   RestClient.post 'localhost:9296', JSON.dump(omg: 123), content_type: :json
# games:
#   cake eater (eat all the cake, fastest time wins)
#   hunter gatherer (eat all the cake, you are not told where it is)
#   maze solver (find a path out of a maze)
