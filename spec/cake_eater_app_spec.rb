require 'spec_helper'
require 'network_games/cake_eater_app'

RSpec.describe 'NetworkGames::CakeEaterApp' do
  it 'chooses a random board on an a 40x30 grid'
  it 'starts once the registration time is up'

  describe 'GET /cake_eater' do
    specify '200 OK with contents of the leaderboard and the amount of cake remaining'
  end

  describe 'POST /cake_eater/robots' do
    specify '401 Unauthorized unless there is a header with the token'
    specify '400 Bad Request for multiple registration attempts on the same token'
    specify '201 Created adds a robot of the registered name at a random location, with the name, x, and y coordinates, and score'
    specify '503 Service Unavailable if the robot could not be added (eg board is full)'
  end

  describe 'GET /cake_eater/robots/:robot_name' do
    specify '401 Unauthorized unless there is a header with the token'
    specify '404 Not Found if the robot has not been registered'
    specify '200 OK if the robot can look around, body includes name, score, coords, plan, a grid of nearby tiles, the planned action, and available actions'
  end

  describe 'PUTS /cake_eater/robots/:robot_name' do
    specify '401 Unauthorized unless there is a header with the token'
    specify '404 Not Found if the robot has not been registered'
    describe '200 OK' do
      specify 'when the move is technically valid, body is the same as the get request'
      specify 'plans the move'
      specify 'performs the move once the move time is hit'
      specify 'overwrites the old move if the move time hasn\'t been hit yet'
      specify 'valid moves: eat_cake move_north move_east move_south move_west'
    end
  end
end
