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


#
#
# Notice: This controller extends the CatalogController
# The default controller allready instantiates flare,
# so here we just configure it
class MusicController < CatalogController
#
#
#
  
  before_filter :setup
  
  alias orig_index index
  def index
    # special field setup for result list
    @fields_for_record_details = @flare.fields(
      :only=>[
        'title_text',
        'author_text',
        'published_text',
        'material_type_text',
        'notes_text'
      ]
    )
    orig_index
  end
  
  def setup
    @fields_for_facet_list = @flare.facet_fields(
      :only=>['recordings_and_scores_facet','source_facet','composition_era_facet','library_facet', 'recording_format_facet','language_facet','instrument_facet','topic_form_genre_facet','subject_geographic_facet'],
      :except=>[]
    )
    # These fields are used in the record details view
    # The index AND record actions use these.
    # By putting this in each of the actions,
    # the fields can be customized per/action.
    @fields_for_record_details = @flare.fields(
      :only=>[
        'author_text',
        'composition_era_facet',
        'library_facet',
        'topic_form_genre_facet',
        'subject_geographic_facet',
        'recording_format_facet',
        'language_facet',
        'instrument_facet'
      ],
      :except=>[]
    )
    @flare.config[:facet_field_params] = {
      :library_facet => {:sort=> :alpha},
      :format_facet => {:sort => :alpha },
      :language_facet => {:sort => :alpha, :mincount => 6, :missing => false },
      :subject_geographic_facet => {:limit => FACET_VALUES_LIMIT, :sort => :count},
      :topic_form_genre_facet => {:limit => FACET_VALUES_LIMIT, :sort => :count }
    }
  end
  
end
