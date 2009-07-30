##
# Copyright (C) 2005, 2006, 2007, 2008 Gregoire Lejeune <gregoire.lejeune@free.fr>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA
#

require "xml/xslt_lib"

module XML
  class XSLT
    @@extFunctions = {}
    
    # sets up a block for callback when the XPath function 
    # namespace:name( ... ) is encountered in a stylesheet.
    #
    #   XML::XSLT.registerExtFunc(namespace_uri, name) do |*args|
    #     puts args.inspect
    #   end
    #    
    # XPath arguments are converted to Ruby objects accordingly:
    #
    # number (eg. <tt>1</tt>):: Float
    # boolean (eg. <tt>false()</tt>):: TrueClass/FalseClass
    # nodeset (eg. <tt>/entry/*</tt>):: Array of REXML::Elements
    # variable (eg. <tt>$var</tt>):: UNIMPLEMENTED
    #
    # It works the same in the other direction, eg. if the block
    # returns an array of REXML::Elements the value of the function
    # will be a nodeset.
    #
    # Note: currently, passing a nodeset to Ruby or REXML::Elements to
    # libxslt serializes the nodes and then parses them. Doing this
    # with large sets is a bad idea. In the future they'll be passed
    # back and forth using Ruby's libxml2 bindings.
    def self.registerExtFunc(namespace, name, &block)
      @@extFunctions[namespace] ||= {}
      @@extFunctions[namespace][name] = block
      XML::XSLT.registerFunction(namespace, name)
    end

    # deprecated, see +registerExtFunc+
    def self.extFunction(name, ns_uri, receiver) #:nodoc:
      self.registerExtFunc(ns_uri, name) do |*args|
        receiver.send(name.gsub(/-/, "_"), *args)
      end
    end

    # registers a block to be called when libxml2 or libxslt encounter an error
    # eg:
    #
    #   XML::XSLT.registerErrorHandler do |error_str|
    #     $stderr.puts error_str
    #   end
    #
    def self.registerErrorHandler(&block)
      @@error_handler = block
    end

    # set up default error handler
    self.registerErrorHandler do |error_str|
      $stderr.puts error_str
    end
    
    alias :media_type :mediaType
    class <<XML::XSLT
      alias :register_ext_func :registerExtFunc
      alias :register_error_handler :registerErrorHandler
    end
  end
end
