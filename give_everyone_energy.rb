
require 'discordrb'
require 'active_record'
require 'yaml'
require 'pry'
require_relative './initialise'
require_relative './models/game'
require_relative './models/player'
require_relative './models/city'
require_relative './models/stats'
require_relative './models/global_stats'
require_relative './models/energy_cell'
require_relative './battle_log'
require_relative './command/helpers/generate_grid'
require_relative './config/game_data'


game = Game.first
game_data = Config::GameData.new

unless game
  puts 'No game running!'
  return
end

unless game.started
  puts 'Game has not started!'
  return
end

players = Player.all

BattleLog.logger.info("Daily energy:")
players.each do |player|
  BattleLog.logger.info("#{player.username} X: #{player.x_position} Y: #{player.y_position} Energy: #{player.energy}")
end


City.all.each do |city|
  if city.player
    city.player.update(energy: city.player.energy + game_data.captured_city_reward) if city.player.alive?
    city.player.stats.update(daily_energy_received: city.player.stats.daily_energy_received + game_data.captured_city_reward) if city.player.alive?
    global_player_stats = GlobalStats.find_by(player_discord_id: player.discord_id)
    global_player_stats.update(daily_energy_received: global_player_stats.daily_energy_received + game_data.captured_city_reward) if city.player.alive?
    BattleLog.logger.info("#{city.player.username} has a city. Giving energy. New energy: #{city.player.energy}")
  end
end

players = Player.all

mentions = ""
players.each do |player|
  player.update(energy: player.energy + game_data.daily_energy_amount) if player.alive?
  player.stats.update(daily_energy_received: player.stats.daily_energy_received + game_data.daily_energy_amount) if player.alive?
  global_player_stats = GlobalStats.find_by(player_discord_id: player.discord_id)
  global_player_stats.update(daily_energy_received: global_player_stats.daily_energy_received + game_data.daily_energy_amount) if player.alive?
  BattleLog.logger.info("Giving energy to #{player.username}. New energy: #{player.energy}")
  mentions << "<@#{player.discord_id}> "
end

response = "Energy successfully distributed! #{mentions}"

unless EnergyCell.find_by(collected: false)
  available_spawn_point = Command::Helpers::GenerateGrid.new.available_spawn_location(server_id: game.server_id)
  spawn_location = available_spawn_point.sample

  EnergyCell.create!(x_position: spawn_location[:x], y_position: spawn_location[:y])

  BattleLog.logger.info("An energy cell spawned at X:#{spawn_location[:x]}, Y:#{spawn_location[:y]}")
  response << " An energy cell spawned at X:#{spawn_location[:x]}, Y:#{spawn_location[:y]}."
end

Player.all.each do |player|
  global_player_stats = GlobalStats.find_by(player_discord_id: player.discord_id)

  if player.energy > player.stats.highest_energy
    player.stats.update(highest_energy: player.energy)
  end

  if player.energy > global_player_stats.highest_energy
    global_player_stats.update(highest_energy: player.energy)
  end
end

bot = Discordrb::Bot.new(token: ENV.fetch('SLASH_COMMAND_BOT_TOKEN', nil), intents: [:server_messages])

bot.send_message(ENV.fetch('BOT_CHANNEL', nil), response)
