require 'echoe'
require 'lib/hanna/rdoc_version'

Echoe.new('hanna') do |p|
  p.version = '0.1.7'
  
  p.summary     = "An RDoc template that scales"
  p.description = "Hanna is an RDoc implemented in Haml, making its source clean and maintainable. It's built with simplicity, beauty and ease of browsing in mind."
  
  p.author = 'Mislav Marohnić'
  p.email  = 'mislav.marohnic@gmail.com'
  p.url    = 'http://github.com/mislav/hanna'
  
  p.project = nil
  p.has_rdoc = false
  
  p.runtime_dependencies << ['rdoc', Hanna::RDOC_VERSION_REQUIREMENT]
  p.runtime_dependencies << ['haml', '~> 2.0.4']
  p.runtime_dependencies << ['rake', '~> 0.8.2']
end
