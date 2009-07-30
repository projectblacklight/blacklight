require 'yaml'
require 'cgi'

module Hanna
  module TemplateHelpers
    protected

    def link_to(text, url = nil, classname = nil)
      class_attr = classname ? %[ class="#{classname}"] : ''
      
      if url
        %[<a href="#{url}"#{class_attr}>#{text}</a>]
      elsif classname
        %[<span#{class_attr}>#{text}</span>]
      else
        text
      end
    end
    
    # +method_text+ is in the form of "ago (ActiveSupport::TimeWithZone)".
    def link_to_method(method_text, url = nil, classname = nil)
      method_text =~ /\A(.+) \((.+)\)\Z/
      method_name, module_name = $1, $2
      link_to %Q(<span class="method_name">#{h method_name}</span> <span class="module_name">(#{h module_name})</span>), url, classname
    end
    
    def read(*names)
      RDoc::Generator::HTML::HANNA.read(*names)
    end

    # We need to suppress warnings before calling into HAML because
    # HAML has lots of uninitialized instance variable accesses.
    def silence_warnings
      save = $-w
      $-w = false
      
      begin
        yield
      ensure
        $-w = save
      end
    end
    module_function :silence_warnings

    def debug(text)
      "<pre>#{h YAML::dump(text)}</pre>"
    end

    def h(html)
      CGI::escapeHTML(html)
    end
    
    # +entries+ is an array of hashes, each which has a "name" and "href" element.
    # An entry name is in the form of "ago (ActiveSupport::TimeWithZone)".
    # +entries+ must be already sorted by name.
    def build_javascript_search_index(entries)
      result = "var search_index = [\n"
      entries.each do |entry|
        entry[:name] =~ /\A(.+) \((.+)\)\Z/
        method_name, module_name = $1, $2
        html = link_to_method(entry[:name], entry[:href])
        result << "  { method: '#{method_name.downcase}', " <<
                      "module: '#{module_name.downcase}', " <<
                      "html: '#{html}' },\n"
      end
      result << "]"
      result
    end

    def methods_from_sections(sections)
      sections.inject(Hash.new {|h, k| h[k] = []}) do |methods, section|
        section[:method_list].each do |ml|
          methods["#{ml[:type]} #{ml[:category]}".downcase].concat ml[:methods]
        end if section[:method_list]
        methods
      end
    end

    def make_class_tree(entries)
      entries.inject({}) do |tree, entry|
        if entry[:href]
          leaf = entry[:name].split('::').inject(tree) do |branch, klass|
            branch[klass] ||= {}
          end
          leaf['_href'] = entry[:href]
        end
        tree
      end
    end

    def render_class_tree(tree, parent = nil)
      parent = parent + '::' if parent
      tree.keys.sort.inject('') do |out, name|
        unless name == '_href'
          subtree = tree[name]
          text = parent ? %[<span class="parent">#{parent}</span>#{name}] : name
          out << '<li>'
          out << (subtree['_href'] ? link_to(text, subtree['_href']) : %[<span class="nodoc">#{text}</span>])
          if subtree.keys.size > 1 || (subtree.keys.size == 1 && !subtree['_href'])
            out << "\n<ol>" << render_class_tree(subtree, parent.to_s + name) << "\n</ol>"
          end
          out << '</li>'
        end
        out
      end
    end
    
    # primarily for removing leading whitespace in <pre> tags
    def sanitize_code_blocks(text)
      text.gsub(/<pre>(.+?)<\/pre>/m) do
        code = $1.sub(/^\s*\n/, '')
        indent = code.gsub(/\n[ \t]*\n/, "\n").scan(/^ */).map{ |i| i.size }.min
        code.gsub!(/^#{' ' * indent}/, '') if indent > 0
        
        "<pre>#{code}</pre>"
      end
    end
  end
end
