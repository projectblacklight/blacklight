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


require 'rubygems'
require 'solr'

module Flare
  
  #
  # Useful for copying Rails request params
  # my_params = Flare.ezclone(params)
  #
  def self.ezclone(object)
    Marshal.restore(Marshal.dump(object))
  end
  
  module Controller
    
  end
end

$: << File.dirname(__FILE__)

require 'flare/context'
require 'flare/context/filter'
require 'flare/context/textual_filter'
require 'flare/context/faceted_filter'
require 'flare/context/filter_group'