require 'active_record'

class Player < ActiveRecord::Base
  has_one :peace_vote
  has_one :stats
  has_one :shot
  has_many :city

  validates :discord_id, :username, :energy, :hp, :range, presence: true
  validates :discord_id, :username, uniqueness: true


  def alive?
    hp > 0
  end

  def disabled?
    return false if disabled_until.nil?

    disabled_until > DateTime.now
  end
end
