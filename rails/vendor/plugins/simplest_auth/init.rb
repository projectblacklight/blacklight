if config.respond_to?(:gems)
  config.gem 'bcrypt-ruby', :lib => 'bcrypt'
else
  begin
    require 'bcrypt'
  rescue LoadError
    begin
      gem 'bcrypt-ruby'
    rescue Gem::LoadError
      puts "Please install the bcrypt-ruby gem"
    end
  end
end