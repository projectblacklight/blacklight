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


module Flare::Controller::GET
  
  #
  # TO DO : All of these actions should throw custom exceptions
  #
  # TO DO : prefix all flare attributes with "flare"
  # example: "facet_param" would become "flare_facet_param"
  #
  # TO DO : Make this easier to integrate.
  # => find way to set parent instance variables when including
  # => or implement as proper Rails plugin
  #
  
  attr_reader :page_param, :facet_param, :text_param
  
  def flare_init_controller
    @page_param = :page
    @facet_param = :ff
    @text_param = :tf
  end
  
  def self.included(base)
    
    # NONE OF THESE WORK
    # ONLY WORK AROUND IS TO CALL flare_init_controller
    # IN THE "INCLUDING" CLASS
    
    #base.send(:attr_accessor, :page_param)
    #base.send(:attr_accessor, :facet_param)
    #base.send(:attr_accessor, :text_param)
    
    #base.page_param = :page
    #base.facet_param = :ff
    #base.text_param = :tf
    #base.instance_variable_set(:@page_param, :page)
    #base.instance_variable_set(:@facet_param, :ff)
    #base.instance_variable_set(:@text_param, :tf)
  end
  
  protected
  
  def flare_index
    @facet_params = params[@facet_param]
    @text_params = params[@text_param]
    @page = params[@page_param]
    flare_import_faceted_filter_data(@flare, @facet_params) rescue nil
    flare_import_textual_filter_data(@flare, @text_params) rescue nil
    @flare.search(@page)
  end
  
  def flare_record
    @record = @flare.doc_by_id(params[:id])
  end
  
  #
  # Does't require the facet field suffix (_facet)
  # TO DO : allow filters to be used like flare_index for example...
  #
  def flare_facet
    @flare_facet_data = @flare.facet_values(params[:id] + Flare::Context::FacetedFilter::FIELD_SUFFIX)
  end
  
  NEGATE_CHAR='-'
  
  def flare_import_faceted_filter_data(flare, hash)
    raise 'Faceted filter data must respond_to?(:each_pair)' if ! hash.respond_to?(:each_pair)
    hash.each_pair do |field,values|
      # values of main param should NOT be indexed: ff[field][]=value
      raise "Facet param not an array!" if ! values.is_a? Array
      values.each do |value|
        flare.add_filter(Flare::Context::FacetedFilter.new(
          field,
          value.sub(/^-/, ''),
          value[0,1]==NEGATE_CHAR
        ))
      end
    end
  end
  
  def flare_import_textual_filter_data(flare, array)
    raise 'Textual filter data must be Array, not ' + array.class.to_s if ! array.is_a? Array
    array.each do |value|
      ## values of main param should NOT be indexed: ff[]=value
      raise "Text param not string!" if ! value.is_a? String
      flare.add_filter(Flare::Context::TextualFilter.new(
        value.sub(/^-/, ''),
        value[0,1]==NEGATE_CHAR
      ))
    end
  end
  
end