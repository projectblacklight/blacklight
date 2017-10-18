source 'https://rubygems.org'

# Please see blacklight.gemspec for dependency information.
gemspec path: File.expand_path('..', __FILE__)

group :test do
  gem 'activerecord-jdbcsqlite3-adapter', platform: :jruby
end

# BEGIN ENGINE_CART BLOCK
# engine_cart: 0.10.0
# engine_cart stanza: 0.10.0
# the below comes from engine_cart, a gem used to test this Rails engine gem in the context of a Rails app.
file = File.expand_path('Gemfile', ENV['ENGINE_CART_DESTINATION'] || ENV['RAILS_ROOT'] || File.expand_path('.internal_test_app', File.dirname(__FILE__)))
if File.exist?(file)
  begin
    eval_gemfile file
  rescue Bundler::GemfileError => e
    Bundler.ui.warn '[EngineCart] Skipping Rails application dependencies:'
    Bundler.ui.warn e.message
  end
else
  Bundler.ui.warn "[EngineCart] Unable to find test application dependencies in #{file}, using placeholder dependencies"

  if ENV['RAILS_VERSION']
    if ENV['RAILS_VERSION'] == 'edge'
      gem 'rails', github: 'rails/rails'
      ENV['ENGINE_CART_RAILS_OPTIONS'] = '--edge --skip-turbolinks'
    else
      gem 'rails', ENV['RAILS_VERSION']
    end
  end

  case ENV['RAILS_VERSION']
  when /^4.2/
    gem 'responders', '~> 2.0'
    gem 'sass-rails', '>= 5.0'
    gem 'coffee-rails', '~> 4.1.0'
    gem 'json', '~> 1.8'
  when /^4.[01]/
    gem 'sass-rails', '< 5.0'
  end
end
# END ENGINE_CART BLOCK

eval_gemfile File.expand_path("spec/test_app_templates/Gemfile.extra", File.dirname(__FILE__))
