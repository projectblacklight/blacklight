# -*- encoding : utf-8 -*-
# SolrHelper is a controller layer mixin. It is in the controller scope: request params, session etc.
# 
# NOTE: Be careful when creating variables here as they may be overriding something that already exists.
# The ActionController docs: http://api.rubyonrails.org/classes/ActionController/Base.html
#
# Override these methods in your own controller for customizations:
# 
#   class CatalogController < ActionController::Base
#   
#     include Blacklight::Catalog
#   
#     def solr_search_params
#       super.merge :per_page=>10
#     end
#   end
#
# Or by including in local extensions:
#   module LocalSolrHelperExtension
#     [ local overrides ]
#   end
#
#   class CatalogController < ActionController::Base
#   
#     include Blacklight::Catalog
#     include LocalSolrHelperExtension
#   
#     def solr_search_params
#       super.merge :per_page=>10
#     end
#   end
#
# Or by using ActiveSupport::Concern:
#
#   module LocalSolrHelperExtension
#     extend ActiveSupport::Concern
#     include Blacklight::SolrHelper
#
#     [ local overrides ]
#   end
#
#   class CatalogController < ApplicationController
#     include LocalSolrHelperExtension
#     include Blacklight::Catalog
#   end  

module Blacklight::SolrHelper
  extend Deprecation
  self.deprecation_horizon = 'Blacklight 5.x'

  extend ActiveSupport::Concern
  include Blacklight::SearchFields
  include Blacklight::Facet

  included do
    if self.respond_to?(:helper_method)
      helper_method(:facet_limit_for)
    end

    # We want to install a class-level place to keep 
    # solr_search_params_logic method names. Compare to before_filter,
    # similar design. Since we're a module, we have to add it in here.
    # There are too many different semantic choices in ruby 'class variables',
    # we choose this one for now, supplied by Rails. 
    class_attribute :solr_search_params_logic

    # Set defaults. Each symbol identifies a _method_ that must be in
    # this class, taking two parameters (solr_parameters, user_parameters)
    # Can be changed in local apps or by plugins, eg:
    # CatalogController.include ModuleDefiningNewMethod
    # CatalogController.solr_search_params_logic += [:new_method]
    # CatalogController.solr_search_params_logic.delete(:we_dont_want)
    self.solr_search_params_logic = [:default_solr_parameters , :add_query_to_solr, :add_facet_fq_to_solr, :add_facetting_to_solr, :add_solr_fields_to_query, :add_paging_to_solr, :add_sorting_to_solr, :add_group_config_to_solr ]
  end

  def force_to_utf8(value)
    case value
    when Hash
      value.each { |k, v| value[k] = force_to_utf8(v) }
    when Array
      value.each { |v| force_to_utf8(v) }
    when String
      value.force_encoding("utf-8")  if value.respond_to?(:force_encoding) 
    end
    value
  end
  
  def find(*args)
    path = blacklight_config.solr_path
    response = blacklight_solr.get(path, :params=> args[1])
    Blacklight::SolrResponse.new(force_to_utf8(response), args[1])
  rescue Errno::ECONNREFUSED => e
    raise Blacklight::Exceptions::ECONNREFUSED.new("Unable to connect to Solr instance using #{blacklight_solr.inspect}")
  end
    
  
  # A helper method used for generating solr LocalParams, put quotes
  # around the term unless it's a bare-word. Escape internal quotes
  # if needed. 
  def solr_param_quote(val, options = {})
    options[:quote] ||= '"'
    unless val =~ /^[a-zA-Z0-9$_\-\^]+$/
      val = options[:quote] +
        # Yes, we need crazy escaping here, to deal with regexp esc too!
        val.gsub("'", "\\\\\'").gsub('"', "\\\\\"") + 
        options[:quote]
    end
    return val
  end
    

 # returns a params hash for searching solr.
  # The CatalogController #index action uses this.
  # Solr parameters can come from a number of places. From lowest
  # precedence to highest:
  #  1. General defaults in blacklight config (are trumped by)
  #  2. defaults for the particular search field identified by  params[:search_field] (are trumped by) 
  #  3. certain parameters directly on input HTTP query params 
  #     * not just any parameter is grabbed willy nilly, only certain ones are allowed by HTTP input)
  #     * for legacy reasons, qt in http query does not over-ride qt in search field definition default. 
  #  4.  extra parameters passed in as argument.
  #
  # spellcheck.q will be supplied with the [:q] value unless specifically
  # specified otherwise. 
  #
  # Incoming parameter :f is mapped to :fq solr parameter.
  def solr_search_params(user_params = params || {})
    solr_parameters = {}
    solr_search_params_logic.each do |method_name|
      send(method_name, solr_parameters, user_params)
    end

    return solr_parameters
  end
    
  
    ####
    # Start with general defaults from BL config. Need to use custom
    # merge to dup values, to avoid later mutating the original by mistake.
    def default_solr_parameters(solr_parameters, user_params)
      blacklight_config.default_solr_params.each do |key, value|
        solr_parameters[key] = value.dup rescue value
      end
    end
    
    ###
    # copy paging params from BL app over to solr, changing
    # app level per_page and page to Solr rows and start. 
    def add_paging_to_solr(solr_params, user_params)
      # Deprecated behavior was to pass :per_page to RSolr, and we
      # generated blacklight_config.default_solr_params with that
      # value. Move it over to rows.
      if solr_params.has_key?(:per_page)
        Deprecation.warn self, "Blacklight::SolrHelper#solr_search_params: magic :per_page key deprecated, use :rows instead. (Check default_solr_params in blacklight config?)"
        per_page = solr_params.delete(:per_page)
        solr_params[:rows] ||= per_page
      end

      # Now any over-rides from current URL?
      solr_params[:rows] = user_params[:rows].to_i  unless user_params[:rows].blank?
      solr_params[:rows] = user_params[:per_page].to_i  unless user_params[:per_page].blank?

      # Do we need to translate :page to Solr :start?
      unless user_params[:page].blank?
        # already set solr_params["rows"] might not be the one we just set,
        # could have been from app defaults too. But we need one.
        # raising is consistent with prior RSolr magic keys behavior.
        # We could change this to default to 10, or to raise on startup
        # from config instead of at runtime.
        if solr_params[:rows].blank?
          raise Exception.new("To use pagination when no :per_page is supplied in the URL, :rows must be configured in blacklight_config default_solr_params")
        end
        solr_params[:start] = solr_params[:rows].to_i * (user_params[:page].to_i - 1)
        solr_params[:start] = 0 if solr_params[:start].to_i < 0
      end

      solr_params[:rows] ||= blacklight_config.per_page.first unless blacklight_config.per_page.blank?

      solr_params[:rows] = blacklight_config.max_per_page if solr_params[:rows].to_i > blacklight_config.max_per_page
    end

    ###
    # copy sorting params from BL app over to solr
    def add_sorting_to_solr(solr_parameters, user_params)
      if user_params[:sort].blank? and sort_field = blacklight_config.default_sort_field
        # no sort param provided, use default
        solr_parameters[:sort] = sort_field.sort unless sort_field.sort.blank?
      elsif sort_field = blacklight_config.sort_fields[user_params[:sort]]
        # check for sort field key  
        solr_parameters[:sort] = sort_field.sort unless sort_field.sort.blank?
      else 
        # just pass the key through
        solr_parameters[:sort] = user_params[:sort]
      end
    end

    ##
    # Take the user-entered query, and put it in the solr params, 
    # including config's "search field" params for current search field. 
    # also include setting spellcheck.q. 
    def add_query_to_solr(solr_parameters, user_parameters)
      ###
      # Merge in search field configured values, if present, over-writing general
      # defaults
      ###
      # legacy behavior of user param :qt is passed through, but over-ridden
      # by actual search field config if present. We might want to remove
      # this legacy behavior at some point. It does not seem to be currently
      # rspec'd. 
      solr_parameters[:qt] = user_parameters[:qt] if user_parameters[:qt]
      
      search_field_def = search_field_def_for_key(user_parameters[:search_field])
      if (search_field_def)     
        solr_parameters[:qt] = search_field_def.qt
        solr_parameters.merge!( search_field_def.solr_parameters) if search_field_def.solr_parameters
      end
      
      ##
      # Create Solr 'q' including the user-entered q, prefixed by any
      # solr LocalParams in config, using solr LocalParams syntax. 
      # http://wiki.apache.org/solr/LocalParams
      ##         
      if (search_field_def && hash = search_field_def.solr_local_parameters)
        local_params = hash.collect do |key, val|
          key.to_s + "=" + solr_param_quote(val, :quote => "'")
        end.join(" ")
        solr_parameters[:q] = "{!#{local_params}}#{user_parameters[:q]}"
      else
        solr_parameters[:q] = user_parameters[:q] if user_parameters[:q]
      end
            

      ##
      # Set Solr spellcheck.q to be original user-entered query, without
      # our local params, otherwise it'll try and spellcheck the local
      # params! Unless spellcheck.q has already been set by someone,
      # respect that.
      #
      # TODO: Change calling code to expect this as a symbol instead of
      # a string, for consistency? :'spellcheck.q' is a symbol. Right now
      # rspec tests for a string, and can't tell if other code may
      # insist on a string. 
      solr_parameters["spellcheck.q"] = user_parameters[:q] unless solr_parameters["spellcheck.q"]
    end

    ##
    # Add any existing facet limits, stored in app-level HTTP query
    # as :f, to solr as appropriate :fq query. 
    def add_facet_fq_to_solr(solr_parameters, user_params)   

      # convert a String value into an Array
      if solr_parameters[:fq].is_a? String
        solr_parameters[:fq] = [solr_parameters[:fq]]
      end

      # :fq, map from :f. 
      if ( user_params[:f])
        f_request_params = user_params[:f] 
        
        solr_parameters[:fq] ||= []

        f_request_params.each_pair do |facet_field, value_list|
          Array(value_list).each do |value|
            solr_parameters[:fq] << facet_value_to_fq_string(facet_field, value)
          end              
        end      
      end
    end

    ##
    # Convert a facet/value pair into a solr fq parameter
    def facet_value_to_fq_string(facet_field, value) 
      facet_config = blacklight_config.facet_fields[facet_field]

      local_params = []
      local_params << "tag=#{facet_config.tag}" if facet_config and facet_config.tag

      prefix = ""
      prefix = "{!#{local_params.join(" ")}}" unless local_params.empty?

      fq = case
        when (facet_config and facet_config.query)
          facet_config.query[value][:fq]
        when (facet_config and facet_config.date),
             (value.is_a?(TrueClass) or value.is_a?(FalseClass) or value == 'true' or value == 'false'),
             (value.is_a?(Integer) or (value.to_i.to_s == value if value.respond_to? :to_i)),
             (value.is_a?(Float) or (value.to_f.to_s == value if value.respond_to? :to_f))
             (value.is_a?(DateTime) or value.is_a?(Date) or value.is_a?(Time))
          "#{prefix}#{facet_field}:#{value}"
        when value.is_a?(Range)
          "#{prefix}#{facet_field}:[#{value.first} TO #{value.last}]"
        else
          "{!raw f=#{facet_field}#{(" " + local_params.join(" ")) unless local_params.empty?}}#{value}"
      end


    end
    
    ##
    # Add appropriate Solr facetting directives in, including
    # taking account of our facet paging/'more'.  This is not
    # about solr 'fq', this is about solr facet.* params. 
    def add_facetting_to_solr(solr_parameters, user_params)
      # While not used by BL core behavior, legacy behavior seemed to be
      # to accept incoming params as "facet.field" or "facets", and add them
      # on to any existing facet.field sent to Solr. Legacy behavior seemed
      # to be accepting these incoming params as arrays (in Rails URL with []
      # on end), or single values. At least one of these is used by
      # Stanford for "faux hieararchial facets". 
      if user_params.has_key?("facet.field") || user_params.has_key?("facets")
        solr_parameters[:"facet.field"] ||= []
        solr_parameters[:"facet.field"].concat( [user_params["facet.field"], user_params["facets"]].flatten.compact ).uniq!
      end                


      if blacklight_config.add_facet_fields_to_solr_request
        solr_parameters[:facet] = true
        solr_parameters[:'facet.field'] ||= []
        solr_parameters[:'facet.field'] += blacklight_config.facet_fields_to_add_to_solr
        
        if blacklight_config.facet_fields.any? { |k,v| v[:query] }
          solr_parameters[:'facet.query'] ||= []
        end

        if blacklight_config.facet_fields.any? { |k,v| v[:pivot] }
          solr_parameters[:'facet.pivot'] ||= []
        end
      end
         
      blacklight_config.facet_fields.each do |field_name, facet|

        if blacklight_config.add_facet_fields_to_solr_request
          case 
            when facet.pivot
              solr_parameters[:'facet.pivot'] << with_ex_local_param(facet.ex, facet.pivot.join(","))
            when facet.query
              solr_parameters[:'facet.query'] += facet.query.map { |k, x| with_ex_local_param(facet.ex, x[:fq]) } 
   
            when facet.ex
              if idx = solr_parameters[:'facet.field'].index(facet.field)
                solr_parameters[:'facet.field'][idx] = with_ex_local_param(facet.ex, solr_parameters[:'facet.field'][idx])
              end
          end

          if facet.sort
            solr_parameters[:"f.#{facet.field}.facet.sort"] = facet.sort
          end
        end

        # Support facet paging and 'more'
        # links, by sending a facet.limit one more than what we
        # want to page at, according to configured facet limits.
        solr_parameters[:"f.#{facet.field}.facet.limit"] = (facet_limit_for(field_name) + 1) if facet_limit_for(field_name)
      end
    end

    def with_ex_local_param(ex, value)
      if ex
        "{!ex=#{ex}}#{value}"
      else
        value
      end
    end

    def add_solr_fields_to_query solr_parameters, user_parameters
      return unless blacklight_config.add_field_configuration_to_solr_request
      blacklight_config.index_fields.each do |field_name, field|
        if field.highlight
          solr_parameters[:hl] ||= true
          solr_parameters[:'hl.fl'] ||= []
          solr_parameters[:'hl.fl'] << field.field
        end
      end
    end

    # Remove the group parameter if we've faceted on the group field (e.g. for the full results for a group)
    def add_group_config_to_solr solr_parameters, user_parameters
      if user_parameters[:f] and user_parameters[:f][grouped_key_for_results]
        solr_parameters[:group] = false
      end
    end


  
  # a solr query method
  # given a user query, return a solr response containing both result docs and facets
  # - mixes in the Blacklight::Solr::SpellingSuggestions module
  #   - the response will have a spelling_suggestions method
  # Returns a two-element array (aka duple) with first the solr response object,
  # and second an array of SolrDocuments representing the response.docs
  def get_search_results(user_params = params || {}, extra_controller_params = {})
    solr_response = query_solr(user_params, extra_controller_params)

    case
    when (solr_response.grouped? && grouped_key_for_results)
      [solr_response.group(grouped_key_for_results), []]
    when (solr_response.grouped? && solr_response.grouped.length == 1)
      [solr_response.grouped.first, []]
    else
      document_list = solr_response.docs.collect {|doc| SolrDocument.new(doc, solr_response)} 
      [solr_response, document_list]
    end
  end

  	
  # a solr query method
  # given a user query,
  # Returns a solr response object
  def query_solr(user_params = params || {}, extra_controller_params = {})
    # In later versions of Rails, the #benchmark method can do timing
    # better for us. 
    bench_start = Time.now
    solr_params = self.solr_search_params(user_params).merge(extra_controller_params)
    solr_params[:qt] ||= blacklight_config.qt
    path = blacklight_config.solr_path

    # delete these parameters, otherwise rsolr will pass them through.
    key = blacklight_config.http_method == :post ? :data : :params
    res = blacklight_solr.send_and_receive(path, {key=>solr_params, method:blacklight_config.http_method})
    
    solr_response = Blacklight::SolrResponse.new(force_to_utf8(res), solr_params)

    Rails.logger.debug("Solr query: #{solr_params.inspect}")
    Rails.logger.debug("Solr response: #{solr_response.inspect}") if defined?(::BLACKLIGHT_VERBOSE_LOGGING) and ::BLACKLIGHT_VERBOSE_LOGGING
    Rails.logger.debug("Solr fetch: #{self.class}#query_solr (#{'%.1f' % ((Time.now.to_f - bench_start.to_f)*1000)}ms)")
    

    solr_response
  end
  
  # returns a params hash for finding a single solr document (CatalogController #show action)
  # If the id arg is nil, then the value is fetched from params[:id]
  # This method is primary called by the get_solr_response_for_doc_id method.
  def solr_doc_params(id=nil)
    id ||= params[:id]

    p = blacklight_config.default_document_solr_params.merge({
      :id => id # this assumes the document request handler will map the 'id' param to the unique key field
    })

    p[:qt] ||= 'document'

    p
  end
  
  # a solr query method
  # retrieve a solr document, given the doc id
  def get_solr_response_for_doc_id(id=nil, extra_controller_params={})
    solr_params = solr_doc_params(id).merge(extra_controller_params)
    solr_response = find((blacklight_config.document_solr_request_handler || blacklight_config.qt), solr_params)
    raise Blacklight::Exceptions::InvalidSolrID.new if solr_response.docs.empty?
    document = SolrDocument.new(solr_response.docs.first, solr_response)
    [solr_response, document]
  end
  
  # given a field name and array of values, get the matching SOLR documents
  def get_solr_response_for_field_values(field, values, extra_solr_params = {})
    values ||= []
    values = [values] unless values.respond_to? :each

    q = nil
    if values.empty?
      q = "NOT *:*"
    else
      q = "#{field}:(#{ values.to_a.map { |x| solr_param_quote(x)}.join(" OR ")})"
    end

    solr_params = {
      :defType => "lucene",   # need boolean for OR
      :q => q,
      # not sure why fl * is neccesary, why isn't default solr_search_params
      # sufficient, like it is for any other search results solr request? 
      # But tests fail without this. I think because some functionality requires
      # this to actually get solr_doc_params, not solr_search_params. Confused
      # semantics again. 
      :fl => "*",  
      :facet => 'false',
      :spellcheck => 'false'
    }.merge(extra_solr_params)
    
    solr_response = find(blacklight_config.qt, self.solr_search_params().merge(solr_params) )
    document_list = solr_response.docs.collect{|doc| SolrDocument.new(doc, solr_response) }
    [solr_response,document_list]
  end
  
  # returns a params hash for a single facet field solr query.
  # used primary by the get_facet_pagination method.
  # Looks up Facet Paginator request params from current request
  # params to figure out sort and offset.
  # Default limit for facet list can be specified by defining a controller
  # method facet_list_limit, otherwise 20. 
  def solr_facet_params(facet_field, user_params=params || {}, extra_controller_params={})
    input = user_params.deep_merge(extra_controller_params)

    # First start with a standard solr search params calculations,
    # for any search context in our request params. 
    solr_params = solr_search_params(user_params).merge(extra_controller_params)
    
    # Now override with our specific things for fetching facet values
    solr_params[:"facet.field"] = facet_field


    limit =  
      if respond_to?(:facet_list_limit)
        facet_list_limit.to_s.to_i
      elsif solr_params["facet.limit"] 
        solr_params["facet.limit"].to_i
      else
        20
      end

    # Need to set as f.facet_field.facet.* to make sure we
    # override any field-specific default in the solr request handler. 
    solr_params[:"f.#{facet_field}.facet.limit"]  = limit + 1
    solr_params[:"f.#{facet_field}.facet.offset"] = ( input.fetch(Blacklight::Solr::FacetPaginator.request_keys[:page] , 1).to_i - 1 ) * ( limit )
    solr_params[:"f.#{facet_field}.facet.sort"] = input[  Blacklight::Solr::FacetPaginator.request_keys[:sort] ] if  input[  Blacklight::Solr::FacetPaginator.request_keys[:sort] ]   
    solr_params[:rows] = 0

    return solr_params
  end
  
  # a solr query method
  # used to paginate through a single facet field's values
  # /catalog/facet/language_facet
  def get_facet_pagination(facet_field, user_params=params || {}, extra_controller_params={})
    
    solr_params = solr_facet_params(facet_field, user_params, extra_controller_params)
    
    # Make the solr call
    response =find(blacklight_config.qt, solr_params)

    limit = solr_params[:"f.#{facet_field}.facet.limit"] -1
        
    # Actually create the paginator!
    # NOTE: The sniffing of the proper sort from the solr response is not
    # currently tested for, tricky to figure out how to test, since the
    # default setup we test against doesn't use this feature. 
    return     Blacklight::Solr::FacetPaginator.new(response.facets.first.items, 
      :offset => solr_params[:"f.#{facet_field}.facet.offset"], 
      :limit => limit,
      :sort => response["responseHeader"]["params"][:"f.#{facet_field}.facet.sort"] || response["responseHeader"]["params"]["facet.sort"]
    )
  end
  
  # a solr query method
  # this is used when selecting a search result: we have a query and a 
  # position in the search results and possibly some facets
  # Pass in an index where 1 is the first document in the list, and
  # the Blacklight app-level request params that define the search. 
  def get_single_doc_via_search(index, request_params)
    solr_params = solr_search_params(request_params)

    solr_params[:start] = (index - 1) # start at 0 to get 1st doc, 1 to get 2nd.    
    solr_params[:rows] = 1
    solr_params[:fl] = '*'
    solr_response = find(blacklight_config.qt, solr_params)
    SolrDocument.new(solr_response.docs.first, solr_response) unless solr_response.docs.empty?
  end

  # Get the previous and next document from a search result
  def get_previous_and_next_documents_for_search(index, request_params, extra_controller_params={})

    solr_params = solr_search_params(request_params).merge(extra_controller_params)

    if index > 0
      solr_params[:start] = index - 1 # get one before
      solr_params[:rows] = 3 # and one after
    else
      solr_params[:start] = 0 # there is no previous doc
      solr_params[:rows] = 2 # but there should be one after
    end

    solr_params[:fl] = '*'
    solr_params[:facet] = false
    solr_response = find(blacklight_config.qt, solr_params)

    document_list = solr_response.docs.collect{|doc| SolrDocument.new(doc, solr_response) }

    # only get the previous doc if there is one
    prev_doc = document_list.first if index > 0
    next_doc = document_list.last if (index + 1) < solr_response.total

    [solr_response, [prev_doc, next_doc]]
  end
    
  # returns a solr params hash
  # if field is nil, the value is fetched from blacklight_config[:index][:show_link]
  # the :fl (solr param) is set to the "field" value.
  # per_page is set to 10
  def solr_opensearch_params(field=nil)
    solr_params = solr_search_params
    solr_params[:per_page] = 10
    solr_params[:fl] = blacklight_config.index.show_link
    solr_params
  end
  
  # a solr query method
  # does a standard search but returns a simplified object.
  # an array is returned, the first item is the query string,
  # the second item is an other array. This second array contains
  # all of the field values for each of the documents...
  # where the field is the "field" argument passed in.
  def get_opensearch_response(field=nil, extra_controller_params={})
    solr_params = solr_opensearch_params().merge(extra_controller_params)
    response = find(blacklight_config.qt, solr_params)
    a = [solr_params[:q]]
    a << response.docs.map {|doc| doc[solr_params[:fl]].to_s }
  end
  
  
  
  # Look up facet limit for given facet_field. Will look at config, and
  # if config is 'true' will look up from Solr @response if available. If
  # no limit is avaialble, returns nil. Used from #solr_search_params
  # to supply f.fieldname.facet.limit values in solr request (no @response
  # available), and used in display (with @response available) to create
  # a facet paginator with the right limit. 
  def facet_limit_for(facet_field)
    facet = blacklight_config.facet_fields[facet_field]
    return nil if facet.blank?
        
    limit = facet.limit

    if ( limit == true && @response && 
         @response["responseHeader"] && 
         @response["responseHeader"]["params"])
     limit =
       @response["responseHeader"]["params"]["f.#{facet_field}.facet.limit"] || 
       @response["responseHeader"]["params"]["facet.limit"]
       limit = (limit.to_i() -1) if limit
       limit = nil if limit == -2 # -1-1==-2, unlimited. 
    elsif limit == true
      limit = nil
    end

    return limit
  end

  ##
  # The key to use to retrieve the grouped field to display 
  def grouped_key_for_results
    blacklight_config.index.group
  end

end
