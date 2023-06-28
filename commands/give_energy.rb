require_relative './base'
require_relative './helpers/generate_grid'
require_relative './helpers/determine_range'

module Commands
  class GiveEnergy < Commands::Base
    def name
      :give_energy
    end

    def description
      "Give energy to someone"
    end

    def execute(event:)
      x = event.options['x']
      y = event.options['y']
      amount_to_give = event.options['amount']
      amount_to_give = 1 if amount_to_give.nil?

      user = event.user
      player = Player.find_by(discord_id: user.id)
      grid = Commands::Helpers::GenerateGrid.new.run

      range_list = Commands::Helpers::DetermineRange.new.build_range_list(player_x: player.x_position, player_y: player.y_position, player_range: player.range)

      unless range_list.include?([y,x])
        event.respond(content: "Not in range!")
        return
      end

      if grid[y][x].nil?
        event.respond(content:"No tank at that location!")
        return
      end

      target = grid[y][x]

      unless target.alive
        event.respond(content:"You can't give energy to a dead player!")
        return
      end

      if player.energy < amount_to_give
        event.respond(content: "You can't give more than you have!")
        return
      end

      player.update(energy: player.energy - amount_to_give)
      target.update(energy: target.energy + amount_to_give)

      event.respond(content: "#{target.username} was given energy by #{player.username}!")

    rescue => e
      event.respond(content: "An error has occurred: #{e}")
    end

    def options
      [
        {
          type: 'integer',
          name: 'x',
          explanation: 'The X coordinate',
          required: true
        },
        {
          type: 'integer',
          name: 'y',
          explanation: 'The Y coordinate',
          required: true
        },
        {
          type: 'integer',
          name: 'amount',
          explanation: 'How much energy you want to give (default is 1)'
        }
      ]
    end
  end
end