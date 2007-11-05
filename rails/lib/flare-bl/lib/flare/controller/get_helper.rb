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


module Flare::Controller::GETHelper
  
  #
  # Creates a text input field and hidden fields for a search form
  #
  def flare_text_filter_form_params(text_attrs={})
    params = text_field_tag("#{@text_param}[]", nil, text_attrs)
    @flare.filters.textual_filters.each do |tf|
      params += hidden_field_tag("#{@text_param}[]", tf.value)
    end
    @flare.filters.faceted_filters.each do |ff|
      params += hidden_field_tag("#{@facet_param}[#{ff.field}][]", ff.value)
    end
    params
  end
  
  #
  # Should this even be in Flare!?
  #
  def flare_field_value_for_solr_doc(doc, field_name)
    values = doc[field_name]
    # If there is no value for the current field
    # don't even display the field name:
    return nil if values.to_s.empty?
    # Create the text for the field value(s)
    display_value = values.collect {|value|
      flare_field_to_label(value)
    }.join('; ')
  end
  
  # replaces _ with spaces and removes _facet and _text
  def flare_field_to_label(field)
    field.to_s.sub(/_facet$|_text$/, '').sub(/^-/, '').humanize
  end
  
  def flare_field_to_param(field)
    field.to_s.sub(/_facet$|_text$/, '').sub(/^-/, '')
  end
  
  # removes _facet
  def flare_facet_field_to_param(field)
    field.sub(%r(#{Flare::Context::FacetedFilter::FIELD_SUFFIX}$), '').downcase#.to_sym
  end
  
  # adds _facet
  def flare_param_to_facet_field(field)
    field + Flare::Context::FacetedFilter::FIELD_SUFFIX
  end
  
  # removes _text
  def flare_text_field_to_param(field)
    field.sub(%r(#{Flare::Context::TextualFilter::FIELD_SUFFIX}$), '').downcase#.to_sym
  end
  
  # adds _text
  def flare_param_to_text_field(field)
    field + Flare::Context::TextualFilter::FIELD_SUFFIX
  end
  
  # checks params[] if field and value are set
  def flare_facet_value_is_active?(field, value)
    facet = flare_facet_field_to_param(field)
    @facet_params && @facet_params[facet] && @facet_params[facet].include?(value)
  end
  
  #
  # link for adding facet
  #
  def flare_add_facet_filter_link(field, item)
    text = "#{item.name} (#{item.value})"
    if flare_facet_value_is_active?(field, item.name)
      return text# + ' ' + link_to('remove', flare_remove_facet_filter_params(field, item.name))
    end
    link_to(text, flare_add_facet_filter_params(field, item.name))
  end
  
  #
  # param/hash for adding a new facet value to existing params
  #
  def flare_add_facet_filter_params(facet, value)
    p = flare_copy_params_for_filter
    param = flare_facet_field_to_param(facet)#.to_sym
    p[@facet_param] ||= p.class.new
    p[@facet_param][param] ||= []
    p[@facet_param][param] << value
    p[@facet_param][param].uniq!
    p
  end
  
  #
  # param/hash for removing facet a value from existing params
  #
  def flare_remove_facet_filter_params(facet, value)
    p = flare_copy_params_for_filter
    param = flare_facet_field_to_param(facet)#.to_sym
    p[@facet_param] ||= p.class.new
    p[@facet_param][param] ||= []
    p[@facet_param][param].delete(value)
    p
  end
  
  def flare_remove_text_filter_params(value)
    p = flare_copy_params_for_filter
    p[@text_param] ||= Array.new
    p[@text_param].delete(value)
    p
  end
  
  #
  # Inspected the current filters value in the url and returns the correct
  # (The negation character is NOT stored with the filter.value)
  #
  def flare_real_filter_value(filter)
    current_switch = filter.negate ? Flare::Controller::GET::NEGATE_CHAR : ''
    current_switch + filter.value
  end
  
  def flare_invert_filter_link(filter)
    current_value = flare_real_filter_value(filter)
    new_switch = filter.negate ? '' : Flare::Controller::GET::NEGATE_CHAR
    text = filter.negate ? '+' : Flare::Controller::GET::NEGATE_CHAR
    if filter.is_a? Flare::Context::TextualFilter
      params = flare_remove_text_filter_params(current_value)
      params[@text_param] << new_switch + filter.value
      link_to text, params
    elsif filter.is_a? Flare::Context::FacetedFilter
      params = flare_remove_facet_filter_params(filter.field, current_value)
      params[@facet_param][filter.field] << new_switch + filter.value
      link_to text, params
    end
  end
  
  def flare_remove_filter_link(filter)
    text='remove'
    current_value = flare_real_filter_value(filter)
    if filter.is_a? Flare::Context::TextualFilter
      params = flare_remove_text_filter_params(current_value)
      link_to text, params
    elsif filter.is_a? Flare::Context::FacetedFilter
      params = flare_remove_facet_filter_params(filter.field, current_value)
      link_to text, params
    end
  end
  
  #
  # Copies all params, but sets the page param
  #
  def flare_new_page_params(page)
    cp=flare_copy_params
		cp[@page_param] = page
		cp
  end
  
  #
  # Grabs the current params (hopefully created by flare_record_params()),
  # sets the action param and removes the record id param
  #
  def flare_back_params(action=:index)
    p = flare_copy_params
    p.delete :id
    p[:action]=action
    p
  end
  
  #
  # Creates the URL query params for linking to the record (details) action
  # Provides all current params for easy "back" linking
  #
  def flare_record_params(id, action=:record)
		p=flare_copy_params
		p[:action]=action
		p[:id]=id
		p
	end
	
	def flare_facet_params(id, action=:facet)
		p=flare_copy_params
		p[:action]=action
		p[:id]=id
		p
	end
  
  def flare_next_page_params
    flare_new_page_params(@flare.dataset.next_page)
  end
  
  def flare_prev_page_params
    flare_new_page_params(@flare.dataset.prev_page)
  end
  
  def flare_prev_page_link(label='&larr;')
    if @flare.dataset.prev_page?
  		return link_to(label, flare_prev_page_params)
    end
  	label
  end
  
  def flare_next_page_link(label='&rarr;')
    if @flare.dataset.next_page?
  		return link_to(label, flare_next_page_params)
  	end
  	label
	end
  
  def flare_copy_params
    Flare.ezclone(params)
  end
  
  #
  # Returns params needed for a filter link (textual or faceted)
  # removes controller, action and page from the params
  #
  def flare_copy_params_for_filter
    p = flare_copy_params
    p.delete :controller
    p.delete :action
    p.delete @page_param
    p
  end
  
end