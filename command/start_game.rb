require_relative './base'

module Command
  class StartGame < Command::Base
    def name
      :start_game
    end

    def requires_game?
      false
    end

    def description
      "Let the game begin!"
    end

    def execute(context:)
      event = context.event
      player = context.player
      game_data = context.game_data

      if context.game
        event.respond(content: "A game is already running!", ephemeral: true)
        return
      end

      unless player.admin
        event.respond(content: "Sorry! Only admins can do this!", ephemeral: true)
        return
      end

      players = Player.all
      world_max = players.count + game_data.world_size_max

      cities = event.options['cities'] ? event.options['cities'] : false
      fog_of_war = event.options['fog_of_war'] ? event.options['fog_of_war'] : false

      city_count = players.count / 2

      game = Game.create!(
        server_id: event.server_id,
        max_x: world_max,
        max_y: world_max,
        cities: cities,
        fog_of_war: fog_of_war
      )

      if cities
        city_count.times do
          available_spawn_point = Command::Helpers::GenerateGrid.new.available_spawn_location(server_id: event.server_id)
          spawn_location = available_spawn_point.sample
          City.create!(x_position: spawn_location[:x], y_position: spawn_location[:y])
        end
      end

      players.each do |player|
        available_spawn_point = Command::Helpers::GenerateGrid.new.available_spawn_location(server_id: event.server_id)
        spawn_location = available_spawn_point.sample
        player.update(x_position: spawn_location[:x], y_position: spawn_location[:y])
      end

      if fog_of_war
        event.respond(content: "The game has begun, what lurks beyond the clouds...")
      else
        event.respond(content: "Generating the grid...", ephemeral: true)

        image_location = ImageGeneration::Grid.new.generate_game_board(
          grid_x: game.max_x,
          grid_y: game.max_y,
          player: player,
          players: players,
          game_data: game_data
        )

        event.channel.send_file File.new(image_location)
        event.delete_response
      end

      BattleLog.reset_log
      BattleLog.logger.info("The game has begun!")
      players = Player.all
      cities = City.all

      players.each do |player|
        BattleLog.logger.info("#{player.username} X: #{player.x_position} Y: #{player.y_position}")
      end

      cities.each do |city|
        BattleLog.logger.info("City X: #{city.x_position} Y: #{city.y_position}")
      end

    rescue => e
      ErrorLog.logger.error("An Error occurred: Command name: #{name}. Error #{e}")
    end

    def options
      [
        Command::Models::Options.new(
          type: 'boolean',
          name: 'cities',
          description: 'Do you want to add cities? (default: false)'
        ),
        Command::Models::Options.new(
          type: 'boolean',
          name: 'fog_of_war',
          description: 'Do you want to enable Fog of War? (default: false)'
        )
      ]
    end
  end
end
