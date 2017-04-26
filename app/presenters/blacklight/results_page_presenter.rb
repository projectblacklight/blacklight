module Blacklight
  class ResultsPagePresenter
    class_attribute :facet_list_presenter, :value_presenter
    self.facet_list_presenter = Blacklight::FacetListPresenter
    self.value_presenter = Blacklight::FacetValuePresenter

    # @param response [Blacklight::Solr::Response]
    # @param view_context [#default_search_field, #blacklight_config]
    def initialize(response, view_context)
      @response = response
      @view_context = view_context
    end

    attr_reader :view_context

    delegate :empty?, to: :@response

    # The presenter class for each result on the page
    def presenter_class
      configuration.index.document_presenter_class
    end

    def facets
      @facets_presenter ||= facet_list_presenter.new(@response, view_context)
    end

    # @param params [#[]]
    def search_to_page_title(params)
      constraints = []

      if params['q'].present?
        q_label = view_context.label_for_search_field(params[:search_field]) unless view_context.default_search_field && params[:search_field] == view_context.default_search_field[:key]

        constraints += if q_label.present?
                         [I18n.t('blacklight.search.page_title.constraint', label: q_label, value: params['q'])]
                       else
                         [params['q']]
                       end
      end

      if params['f'].present?
        constraints += params['f'].to_unsafe_h.collect { |key, value| search_to_page_title_filter(key, value) }
      end

      constraints.join(' / ')
    end

    private

    def configuration
      view_context.blacklight_config
    end

    def search_to_page_title_filter(facet, values)
      facet_config = configuration.facet_configuration_for_field(facet)
      filter_value = if values.size < 3
                       values.map { |value| value_presenter.new(facet, value, view_context).display }.to_sentence
                     else
                       I18n.t('blacklight.search.page_title.many_constraint_values', values: values.size)
                     end
      I18n.t('blacklight.search.page_title.constraint', label: facet_config.facet_field_label,
                                                        value: filter_value)
    end
  end
end
