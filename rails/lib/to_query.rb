##########################################################################
# Copyright 2008 Rector and Visitors of the University of Virginia
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
##########################################################################


require 'cgi'

class Object
  def to_param #:nodoc:
    to_s
  end

  def to_query(key) #:nodoc:
    "#{CGI.escape(key.to_s)}=#{CGI.escape(to_param.to_s)}"
  end
end

class Array
  def to_query(key) #:nodoc:
    collect { |value| value.to_query("#{key}[]") }.sort * '&'
  end
end

class Hash
  def to_query(namespace = nil)
    collect do |key, value|
      value.to_query(namespace ? "#{namespace}[#{key}]" : key)
    end.sort * '&'
  end
end

module ActionController::Routing
  class Route
    def build_query_string(hash, only_keys = nil)
      elements = []

      (only_keys || hash.keys).each do |key|
        if value = hash[key]
          elements << value.to_query(key)
        end
      end

      elements.empty? ? '' : "?#{elements.sort * '&'}"
    end

    def extract_value
    "#{local_name} = hash[:#{key}] && hash[:#{key}].to_param #{"|| #{default.inspect}" if default}"
    end
  end

  class RouteSet
    def options_as_params(options)
      # If an explicit :controller was given, always make :action explicit
      # too, so that action expiry works as expected for things like
      #
      #   generate({:controller => 'content'}, {:controller => 'content', :action => 'show'})
      #
      # (the above is from the unit tests). In the above case, because the
      # controller was explicitly given, but no action, the action is implied to
      # be "index", not the recalled action of "show".
      #
      # great fun, eh?

      options_as_params = options.clone
      options_as_params[:action] ||= 'index' if options[:controller]
      options_as_params[:action] = options_as_params[:action].to_s if options_as_params[:action]
      options_as_params
    end
  end
end