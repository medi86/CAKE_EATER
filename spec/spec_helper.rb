require 'simplecov'
SimpleCov.start do
  add_filter "/test/"
end

module SpecHelpers
  def ce_for(ascii_board)
    board = NetworkGames::Board.from_ascii ascii_board, tiles: {
      ' ' => nil,
      '#' => NetworkGames::Board::Wall,
      'C' => NetworkGames::CakeEater::Cake,
    }
    NetworkGames::CakeEater.new(board)
  end
end

RSpec.configure do |config|
  config.include SpecHelpers
end
