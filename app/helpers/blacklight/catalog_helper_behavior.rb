# -*- encoding : utf-8 -*-
module Blacklight::CatalogHelperBehavior

  # Pass in an RSolr::Response (or duck-typed similar) object,
  # it translates to a Kaminari-paginatable
  # object, with the keys Kaminari views expect.
  def paginate_params(response)

    per_page = response.rows
    per_page = 1 if per_page < 1

    current_page = (response.start / per_page).ceil + 1
    num_pages = (response.total / per_page.to_f).ceil

    total_count = response.total

    start_num = response.start + 1
    end_num = start_num + response.docs.length - 1

    OpenStruct.new(:start => start_num,
                   :end => end_num,
                   :per_page => per_page,
                   :current_page => current_page,
                   :num_pages => num_pages,
                   :limit_value => per_page, # backwards compatibility
                   :total_count => total_count,
                   :first_page? => current_page > 1,
                   :last_page? => current_page < num_pages
      )
  end

  # Equivalent to kaminari "paginate", but takes an RSolr::Response as first argument.
  # Will convert it to something kaminari can deal with (using #paginate_params), and
  # then call kaminari paginate with that. Other arguments (options and block) same as
  # kaminari paginate, passed on through.
  # will output HTML pagination controls.
  def paginate_rsolr_response(response, options = {}, &block)
    pagination_info = paginate_params(response)
    paginate Kaminari.paginate_array(response.docs, :total_count => pagination_info.total_count).page(pagination_info.current_page).per(pagination_info.per_page), options, &block
  end

  #
  # shortcut for built-in Rails helper, "number_with_delimiter"
  #
  def format_num(num); number_with_delimiter(num) end

  #
  # Pass in an RSolr::Response. Displays the "showing X through Y of N" message.
  def render_pagination_info(response, options = {})
      pagination_info = paginate_params(response)

   # TODO: i18n the entry_name
      entry_name = options[:entry_name]
      entry_name ||= response.docs.first.class.name.underscore.sub('_', ' ') unless response.docs.empty?
      entry_name ||= t('blacklight.entry_name.default')


      case pagination_info.total_count
        when 0; t('blacklight.search.pagination_info.no_items_found', :entry_name => entry_name.pluralize ).html_safe
        when 1; t('blacklight.search.pagination_info.single_item_found', :entry_name => entry_name).html_safe
        else; t('blacklight.search.pagination_info.pages', :entry_name => entry_name.pluralize, :current_page => pagination_info.current_page, :num_pages => pagination_info.num_pages, :start_num => format_num(pagination_info.start), :end_num => format_num(pagination_info.end), :total_num => pagination_info.total_count, :count => pagination_info.num_pages).html_safe
      end
  end

  # Like  #render_pagination_info above, but for an individual
  # item show page. Displays "showing X of Y items" message. Actually takes
  # data from session though (not a great design).
  # Code should call this method rather than interrogating session directly,
  # because implementation of where this data is stored/retrieved may change.
  def item_page_entry_info
    t('blacklight.search.entry_pagination_info.other', :current => format_num(session[:search][:counter]), :total => format_num(session[:search][:total]), :count => session[:search][:total].to_i).html_safe
  end

  # Look up search field user-displayable label
  # based on params[:qt] and blacklight_configuration.
  def search_field_label(params)
    h( label_for_search_field(params[:search_field]) )
  end

  def current_sort_field
    blacklight_config.sort_fields[params[:sort]] || (blacklight_config.sort_fields.first ? blacklight_config.sort_fields.first.last : nil )
  end

  def current_per_page
    (@response.rows if @response and @response.rows > 0) || params.fetch(:per_page, (blacklight_config.per_page.first unless blacklight_config.per_page.blank?)).to_i
  end

  # Export to Refworks URL, called in _show_tools
  def refworks_export_url(document = @document)
    "http://www.refworks.com/express/expressimport.asp?vendor=#{CGI.escape(application_name)}&filter=MARC%20Format&encoding=65001&url=#{CGI.escape(polymorphic_path(document, :format => 'refworks_marc_txt', :only_path => false))}"
  end

  def render_document_class(document = @document)
   'blacklight-' + document.get(blacklight_config.index.record_display_type).parameterize rescue nil
  end

  def render_document_sidebar_partial(document = @document)
    render :partial => 'show_sidebar'
  end

  def has_search_parameters?
    !params[:q].blank? or !params[:f].blank? or !params[:search_field].blank?
  end

  def show_sort_and_per_page? response = nil
    response ||= @response
    response.total > 1
  end

end
