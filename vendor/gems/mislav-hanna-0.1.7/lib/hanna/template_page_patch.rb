require 'hanna/template_helpers'

RDoc::TemplatePage.class_eval do

  include Hanna::TemplateHelpers
  
  # overwrite the original method
  alias :old_write_html_on :write_html_on # suppresses the overwrite warning
  def write_html_on(io, values)
    result = @templates.reverse.inject(nil) do |previous, template|
      case template
      when Haml::Engine
        silence_warnings do
          template.to_html(binding, :values => values) { previous }
        end
      when Sass::Engine
        silence_warnings { template.to_css }
      when String
        ERB.new(template).result(get_binding(values){ previous })
      when nil
        previous
      else
        raise "don't know how to handle a template of class '#{template.class.name}'"
      end
    end

    io.write result
  rescue
    $stderr.puts "error while writing to #{io.inspect}"
    raise
  end

  private

    def get_binding(values = nil)
      binding
    end
end
