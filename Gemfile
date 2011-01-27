source 'http://rubygems.org'

gem 'rails', '3.0.3'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

if defined?(JRUBY_VERSION)
 gem 'jdbc-sqlite3'
 gem 'activerecord-jdbc-adapter'
 gem 'jdbc-sqlite3'
 gem 'jruby-openssl'
 gem 'jruby-rack'
 gem 'warbler'
else
  gem 'sqlite3-ruby', :require => 'sqlite3'
end

# Add rails upgrade package
gem 'rails-upgrade'

# Gems added from old init.rb
gem 'authlogic', :git => 'git://github.com/binarylogic/authlogic.git'
gem 'marc'
gem 'will_paginate'

source :gemcutter
gem 'rsolr',  '0.12.1'
gem 'rsolr-ext', '0.12.1'

source 'http://rubygems.org'

# paperclip is a lovely bridge for adding images to 
# an activerecord object in a clean and easy way. 
gem 'paperclip'

# Use unicorn as the web server
# gem 'unicorn'

# Deploy with Capistrano
gem 'capistrano'

# Bundle the extra gems:
# gem 'bj'
# gem 'nokogiri'
# gem 'sqlite3-ruby', :require => 'sqlite3'
# gem 'aws-s3', :require => 'aws/s3'

# Cucumber testing
# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
group :development, :test do
      gem 'rcov'
      gem 'database_cleaner'
      gem 'haml'
      gem 'rdoc'
      gem 'hanna', '0.1.12', :require => 'hanna/rdoctask'
      gem 'gherkin'
      gem 'rspec'
      gem 'rspec-rails'
      gem 'cucumber-rails'
      gem 'capybara' # needed for latest cucumber and Rails3
      gem 'webrat'  # needed for view specs
      gem 'database_cleaner'
      gem 'jeweler'
      # To use debugger (ruby-debug for Ruby 1.8.7+, ruby-debug19 for Ruby 1.9.2+)
      # gem 'ruby-debug'
      # gem 'ruby-debug19'
end

