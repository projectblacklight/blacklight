# = A better RDoc HTML template
#
# Authors: Mislav Marohnić <mislav.marohnic@gmail.com>
#          Tony Strauss (http://github.com/DesigningPatterns)
#          Michael Granger <ged@FaerieMUD.org>, who had maintained the original RDoc template

require 'haml'
require 'sass'
require 'rdoc/generator/html'
require 'hanna/template_page_patch'

module RDoc::Generator::HTML::HANNA
  class << self
    def dir
      @dir ||= File.join File.dirname(__FILE__), 'template_files'
    end

    def read(*names)
      content = names.inject('') { |all, name| all << File.read(File.join(dir, name)) }
      extension = names.first =~ /\.(\w+)$/ && $1

      Hanna::TemplateHelpers.silence_warnings do
        case extension
        when 'sass'
          Sass::Engine.new(content)
        when 'haml'
          Haml::Engine.new(content, :format => :html4, :filename => names.join(','))
        else
          content
        end
      end
    end
  end

  STYLE = read('styles.sass')

  CLASS_PAGE  = read('page.haml')
  FILE_PAGE   = CLASS_PAGE
  METHOD_LIST = read('method_list.haml', 'sections.haml')

  FR_INDEX_BODY = BODY = read('layout.haml')

  FILE_INDEX   = read('file_index.haml')
  CLASS_INDEX  = read('class_index.haml')
  METHOD_INDEX = read('method_index.haml')

  INDEX = read('index.haml')
end 
