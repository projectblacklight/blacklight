# frozen_string_literal: true

module Blacklight
  class AdvancedSearchFormComponent < SearchBarComponent
    include Blacklight::ContentAreasShim

    renders_many :constraints
    renders_many :search_field_controls
    renders_many :search_filter_controls, (lambda do |config:, display_facet:, presenter: nil, component: nil, **kwargs|
      presenter ||= (config.presenter || Blacklight::FacetFieldPresenter).new(config, display_facet, @view_context)
      component = component || config.advanced_search_component || Blacklight::FacetFieldCheckboxesComponent

      component.new(facet_field: presenter, **kwargs)
    end)

    def initialize(response:, **options)
      super(**options)
      @response = response
    end

    def before_render
      initialize_search_field_controls if search_field_controls.blank?
      initialize_search_filter_controls if search_filter_controls.blank?
      initialize_constraints if constraints.blank?
    end

    def default_operator_menu
      options_with_labels = [:must, :should].index_by { |op| t(op, scope: 'blacklight.advanced_search.op') }
      select_tag(:op, options_for_select(options_with_labels, params[:op]), class: 'input-small')
    end

    def sort_fields_select
      options = sort_fields.values.map { |field_config| [@view_context.sort_field_label(field_config.key), field_config.key] }
      select_tag(:sort, options_for_select(options, params[:sort]), class: "form-control sort-select")
    end

    private

    def initialize_search_field_controls
      search_fields.values.each.with_index do |field, i|
        search_field_control do
          fields_for('clause[]', i, include_id: false) do |f|
            content_tag(:div, class: 'form-group advanced-search-field row') do
              f.label(:query, field.display_label('search'), class: "col-sm-3 col-form-label") +
                content_tag(:div, class: 'col-sm-9') do
                  f.hidden_field(:field, value: field.key) +
                    f.text_field(:query, value: query_for_search_clause(field.key), class: 'form-control')
                end
            end
          end
        end
      end
    end

    def initialize_search_filter_controls
      fields = blacklight_config.facet_fields.select { |_k, v| v.include_in_advanced_search || v.include_in_advanced_search.nil? }

      fields.each do |_k, config|
        display_facet = @response.aggregations[config.field]
        search_filter_control(config: config, display_facet: display_facet)
      end
    end

    def initialize_constraints
      constraint do
        params = @view_context.search_state.params_for_search.except :page, :f_inclusive, :q, :search_field, :op, :index, :sort

        params.except!(*search_fields.map { |_key, field_def| field_def[:key] })

        @view_context.render_search_to_s(params)
      end
    end

    def query_for_search_clause(key)
      field = (@params[:clause] || {}).values.find { |value| value['field'].to_s == key.to_s }

      field&.dig('query')
    end

    def search_fields
      blacklight_config.search_fields.select { |_k, v| v.include_in_advanced_search || v.include_in_advanced_search.nil? }
    end

    def sort_fields
      blacklight_config.sort_fields.select { |_k, v| v.include_in_advanced_search || v.include_in_advanced_search.nil? }
    end
  end
end
