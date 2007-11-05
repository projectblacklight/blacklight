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


require 'lib/flare-bl/lib/flare'
require 'lib/flare-bl/lib/flare/controller/get'
require 'lib/flare-bl/lib/flare/controller/get_helper'

class CatalogController < ApplicationController
  
  include Flare::Controller::GET
  before_filter :init_flare
  layout 'application'
  
  #
  # The list view
  #
  def index
    flare_index
  end
  
  #
  # Action for viewing a facet and/or it's values
  # We handle the errors here
  # instead of Flare::Controller::GET
  #
  def facet
    # redirect to index if facet id is empty
    if params[:id].nil?
      redirect_to :action=>:index
      return false
    end
    # Call the flare facet method to retrieve the facet values
    flare_facet
    # Redirect to index if the facet is invalid (nil name)
    redirect_to :action=>:index if @flare_facet_data.first.name.nil?
  end
  
  #
  # Action for single record
  #
  def record
    flare_record
  end
  
  protected
  
  FACET_VALUES_LIMIT=10
  
  ## to-do: put some of these values in environment.rb
  def init_flare
    flare_init_controller
    @flare_config = {
      :solr_url=>'http://localhost:9009/solr',
      :facet_values_limit=>FACET_VALUES_LIMIT
    }
    @flare = Flare::Context.new(@flare_config)
    # for the flare views:
    ## This dictates the default, you can over-ride these values in a specific controller (e.g., the music_controller)
    @fields_for_facet_list = @flare.facet_fields(:only=>['source_facet','format_facet','library_facet','collection_facet','composition_era_facet'], :except=>[])
    @fields_for_record_details = @flare.fields(:only=>[], :except=>['marc_text','text_text','content_model_facet'])
  end
  
end
