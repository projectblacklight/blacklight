class BlacklightToVersion20090529161304 < ActiveRecord::Migration
  def self.up
    Engines.plugins["blacklight"].migrate(20090529161304)
  end

  def self.down
    Engines.plugins["blacklight"].migrate(20090428182620)
  end
end
