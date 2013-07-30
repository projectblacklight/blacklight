source 'http://rubygems.org'

# Please see blacklight.gemspec for dependency information.
gemspec

gem 'simplecov', :platform => :mri
gem 'simplecov-rcov', :platform => :mri

group :test do
  gem 'devise'
end
if File.exists?('spec/test_app_templates/Gemfile.extra')
  eval File.read('spec/test_app_templates/Gemfile.extra'), nil, 'spec/test_app_templates/Gemfile.extra'
end