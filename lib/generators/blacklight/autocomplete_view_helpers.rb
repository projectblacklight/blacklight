#= Sunspot Autocomplete
#
#Sunspot Autocomplete is a Rails plugin that lets you use Solr and Sunspot for handy autocompletion of your html text inputs.
#
#=== Features:
#
#* Autocomplete: Typing "clo" will yield results that start with "clo", like "cloudy with a chance of meatballs".
#* Autosuggest: Typing "clo" will yield results that contain (or start with) "clo", like "cloudy with a chance of meatballs" and "Jumping like Clowns".
#* Both features are case insenitive.
#* A CSS based view. You can override some style rules to force your look and feel.
#
#== Prerequisites
#
#You should have solr, sunspot and sunspot_rails ON and running.
#
#http://outoftime.github.com/sunspot
#
#== Installation
#
#Download the plugin and place it under vendor/plugins.
#
#Run the following rake task to copy the plugin's assets to your public directory. This will copy jquery.js and solr-autocompleter to your public/javascripts.
#
#  rake sunspot_autocomplete:copy_assets
#
#== Usage
#
# In your solr schema.xml, in addition to field types added by sunspot, add the following field types inside the <types> tag:
#
#  <fieldType name="autocomplete" class="solr.TextField" positionIncrementGap="100">
#    <analyzer type="index">
#      <tokenizer class="solr.KeywordTokenizerFactory"/>
#      <filter class="solr.LowerCaseFilterFactory"/>
#      <filter class="solr.EdgeNGramFilterFactory" minGramSize="1" maxGramSize="25" />
#    </analyzer>
#    <analyzer type="query">
#      <tokenizer class="solr.KeywordTokenizerFactory"/>
#      <filter class="solr.LowerCaseFilterFactory"/>
#    </analyzer>
#  </fieldType>
#  <fieldType name="autosuggest" class="solr.TextField" positionIncrementGap="100">
#    <analyzer type="index">
#      <tokenizer class="solr.LetterTokenizerFactory"/>
#      <filter class="solr.LowerCaseFilterFactory"/>
#      <filter class="solr.EdgeNGramFilterFactory" minGramSize="1" maxGramSize="25" />
#    </analyzer>
#    <analyzer type="query">
#      <tokenizer class="solr.LetterTokenizerFactory"/>
#      <filter class="solr.LowerCaseFilterFactory"/>
#    </analyzer>
#  </fieldType>
#
#Also in your solr schema.xml, in addition to fields added by sunspot, add the following fields inside thw <fields> tag.
#
#  <dynamicField name="*_ac" type="autocomplete" indexed="true"  stored="true"/>
#  <dynamicField name="*_as" type="autosuggest" indexed="true"  stored="true"/>
#
#To be able to autocomplete/autosuggest a model's attribute, call 'autocomplete'/'autosuggest' on it in its 'searchable' block. the field_name used (post_title and post_author in the following example) must be unique across all your autocomplete fields of the application.
#
#  class Post < ActiveRecord::Base
#    searchable do
#      autocomplete :post_title, :using => :title
#      autosuggest :post_author, :using => :author
#    end
#  end
#
#In your view, Add the following script tags (in the given order) to be able to use the view helpers.
#
#  <script type="text/javascript" src="/javascripts/jquery.js"></script>
#  <script type="text/javascript" src="/javascripts/solr-autocomplete/ajax-solr/core/Core.js"></script>
#  <script type="text/javascript" src="/javascripts/solr-autocomplete/ajax-solr/core/AbstractManager.js"></script>
#  <script type="text/javascript" src="/javascripts/solr-autocomplete/ajax-solr/managers/Manager.jquery.js"></script>
#  <script type="text/javascript" src="/javascripts/solr-autocomplete/ajax-solr/core/Parameter.js"></script>
#  <script type="text/javascript" src="/javascripts/solr-autocomplete/ajax-solr/core/ParameterStore.js"></script>
#  <script type="text/javascript" src="/javascripts/solr-autocomplete/jquery-autocomplete/jquery.autocomplete.js"></script>
#
#Also, add the following stylesheet to use the basic style included. Alternatively, you can override those style rules to force your design's look and feel.
#
#  <link type="text/css" rel="stylesheet" href="/javascripts/solr-autocomplete/jquery-autocomplete/jquery.autocomplete.css" />
#
#In your view, to create a text field with autocomplete:
#
#  <%=autocomplete_text_field "post", "title", "http://127.0.0.1:8983/solr/", "post_title"%>
#
#And to create a text field with autosuggest:
#
#  <%=autosuggest_text_field "post", "author", "http://127.0.0.1:8983/solr/", "post_author"%>
#
#You can view documentation for more advanced features of the helpers.
#
#  
module AutocompleteViewHelpers
  
  # Generates a text input using the given <code>object_name</code> and <code>method</code>.
  # The generated text field autocompletes given <code>solr_url</code>: the url to your solr instance (e.g. http://127.0.0.1:8983/solr/)
  # Autocompletion is fetching results that only begins with the given part of word.
  # <code>autocomplete_field_name</code> is the unique field_name assigned in your model's searchable block
  # <code>html_options</code> are regular HTML options like :class and :id
  # <code>autocomplete_options</code> are advanced options for autocompletion http://docs.jquery.com/Plugins/Autocomplete/autocomplete#toptions
  def autocomplete_text_field(object_name, autocomplete_field_name, html_options={}, autocomplete_options={})
	solr_url = Blacklight.solr_config[:url]
    autocomplete_stub object_name, solr_url, autocomplete_field_name, false, html_options, autocomplete_options
  end
  
  # Generates a text input using the given <code>object_name</code> and <code>method</code>.
  # The generated text field autosuggests given <code>solr_url</code>: the url to your solr instance (e.g. http://127.0.0.1:8983/solr/)
  # Autosuggestion is fetching results that begins with/ends with/contains the given part of word.
  # <code>autocomplete_field_name</code> is the unique field_name assigned in your model's searchable block
  # <code>html_options</code> are regular HTML options like :class and :id
  # <code>autocomplete_options</code> are advanced options for autocompletion http://docs.jquery.com/Plugins/Autocomplete/autocomplete#toptions
  def autosuggest_text_field(object_name, autocomplete_field_name, html_options={}, autocomplete_options={})
	solr_url = Blacklight.solr_config[:url]
    autocomplete_stub object_name, solr_url, autocomplete_field_name, true, html_options, autocomplete_options
  end
  
  private
  
  def autocomplete_stub(object_name, url, field_name, suggest=false, html_options={}, autocomplete_options={})
    ac_js_options = "{" + autocomplete_options.collect{|k,v| "#{k.to_s}: #{ v.kind_of?(Numeric) ? v : "'" + v + "'" }"}.join(" , ") + "}"
    result = []
    #result << text_field(object_name, method, html_options)
	#result << "<input type=\"text\" name=\"#{object_name}_#{method}\" id=\"#{object_name}_#{method}\"></input>"
    result << "<script>$('##{object_name}').#{suggest ? 'autosuggest' : 'autocomplete'}('#{url.ends_with?('/') ? url : url + '/'}', '#{field_name}', #{ac_js_options});</script>"
    result.join " "
  end
  
end

ActionView::Base.send :include, AutocompleteViewHelpers