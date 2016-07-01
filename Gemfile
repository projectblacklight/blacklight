source 'https://rubygems.org'

# Please see blacklight.gemspec for dependency information.
gemspec path: File.expand_path('..', __FILE__)

gem 'simplecov', '~> 0.10', require: false
gem 'coveralls', require: false

group :test do
  gem 'activerecord-jdbcsqlite3-adapter', :platform => :jruby
end

# BEGIN ENGINE_CART BLOCK
# engine_cart: 0.8.0
# engine_cart stanza: 0.8.0
# the below comes from engine_cart, a gem used to test this Rails engine gem in the context of a Rails app.
file = File.expand_path("Gemfile", ENV['ENGINE_CART_DESTINATION'] || ENV['RAILS_ROOT'] || File.expand_path(".internal_test_app", File.dirname(__FILE__)))
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
      ENV['ENGINE_CART_RAILS_OPTIONS']= "--edge --skip-turbolinks"
    else
      gem 'rails', ENV['RAILS_VERSION']
    end
  end

  if ENV['RAILS_VERSION'].nil? || ENV['RAILS_VERSION'] =~ /^5\.0/ || ENV['RAILS_VERSION'] == 'edge'
    # noop
  elsif ENV['RAILS_VERSION'] =~ /^4\.2/
    gem 'responders', "~> 2.0"
    gem 'sass-rails', ">= 5.0"
  else
    gem 'bootstrap-sass', '< 3.3.5' # 3.3.5 requires sass 3.3, incompatible with sass-rails 4.x
    gem 'sass-rails', "< 5.0"
  end
end
# END ENGINE_CART BLOCK

eval_gemfile File.expand_path("spec/test_app_templates/Gemfile.extra", File.dirname(__FILE__))
