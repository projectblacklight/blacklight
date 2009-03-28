puts "

* Blacklight was successfully installed!


"
dir = defined?(RAILS_ROOT) ? File.join(RAILS_ROOT, 'vendor', 'plugins', 'blacklight') : File.join(File.dirname(__FILE__))

puts File.read(File.join(dir, 'README.rdoc'))