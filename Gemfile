source 'http://rubygems.org'

# Please see blacklight.gemspec for dependency information.
gemspec

group :test do
  gem 'devise'
  gem 'devise-guests'
  gem "bootstrap-sass"
  gem 'turbolinks'
  gem 'sass-rails'
end

if File.exists?('spec/test_app_templates/Gemfile.extra')
  eval File.read('spec/test_app_templates/Gemfile.extra'), nil, 'spec/test_app_templates/Gemfile.extra'
end
