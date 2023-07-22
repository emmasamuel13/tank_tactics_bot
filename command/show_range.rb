require_relative './base'
require_relative '../image_generation/grid'

module Command
  class ShowRange < Command::Base
    def name
      :show_range
    end

    def description
      "Show your tanks range"
    end

    def execute(event:, game_data:, bot:)
      show_everyone = event.options['show_everyone'].nil? ? false : event.options['show_everyone']
      user = event.user
      player = Player.find_by(discord_id: user.id)

      game = Game.find_by(server_id: event.server_id)

      show_everyone = false if game.fog_of_war

      if game.fog_of_war
        ImageGeneration::Grid.new.generate_fog_of_war_board(grid_x: game.max_x, grid_y: game.max_y, player: player, server_id: event.server_id, for_range: true)
      else
        ImageGeneration::Grid.new.generate_range(grid_x: game.max_x, grid_y: game.max_y, player: player, server_id: event.server_id)
      end

      image_location = ENV.fetch('TT_IMAGE_LOCATION', '.')

      if show_everyone
        event.respond(content: "Generating the grid...", ephemeral: true)
        event.channel.send_file File.new(image_location + '/range_grid.png')
        event.delete_response
      else
        event.respond(content: "Sending you a dm", ephemeral: true)
        event.user.send_file File.new(image_location + '/range_grid.png')
      end

    rescue => e
      event.respond(content: "An error has occurred: #{e}")
    end

    def options
      [
        Command::Models::Options.new(
          type: 'boolean',
          name: 'show_everyone',
          description: 'This will show the map to everyone'
        )
      ]
    end
  end
end
