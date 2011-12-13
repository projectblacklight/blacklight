Rails.configuration.sass.tap do |config|
  require 'compass'
  config.load_paths << "#{Gem.loaded_specs['compass'].full_gem_path}/frameworks/compass/stylesheets"
end
