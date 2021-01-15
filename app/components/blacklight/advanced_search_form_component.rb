# frozen_string_literal: true

module Blacklight
  class AdvancedSearchFormComponent < SearchBarComponent
    with_content_areas :constraints, :search_field_controls, :search_filter_controls

    def initialize(response:, **options)
      super(**options)
      @response = response
    end

    def default_operator_menu
      options_with_labels = [:must, :should].index_by { |op| t(op, scope: 'blacklight.advanced_search.op') }
      select_tag(:op, options_for_select(options_with_labels, params[:op]), class: 'input-small')
    end

    # Rubocop is just wrong here, so...:
    # rubocop:disable Rails/ContentTag
    def search_field_controls
      @search_field_controls || safe_join(search_fields.values.map.with_index do |field, i|
        fields_for('clause[]', i, include_id: false) do |f|
          content_tag(:div, class: 'form-group advanced-search-field row') do
            f.label(:query, field.display_label('search'), class: "col-sm-3 col-form-label") +
            content_tag(:div, class: 'col-sm-9') do
              f.hidden_field(:field, value: field.key) +
              f.text_field(:query, value: query_for_search_clause(field.key), class: 'form-control')
            end
          end
        end
      end, "\n")
    end
    # rubocop:enable Rails/ContentTag

    def query_for_search_clause(key)
      field = (@params[:clause] || {}).values.find { |value| value['field'].to_s == key.to_s }

      field&.dig('query')
    end

    def search_filter_controls
      return @search_filter_controls if @search_filter_controls

      fields = blacklight_config.facet_fields.select { |_k, v| v.include_in_advanced_search || v.include_in_advanced_search.nil? }

      safe_join(fields.map do |_k, config|
        display_facet = @response.aggregations[config.field]

        presenter = (config.presenter || Blacklight::FacetFieldPresenter).new(config, display_facet, @view_context)
        component = config.advanced_search_component || Blacklight::FacetFieldCheckboxesComponent
        @view_context.render(component.new(facet_field: presenter))
      end, "\n")
    end

    def constraints
      params = @view_context.search_state.params_for_search.except :page, :f_inclusive, :q, :search_field, :op, :index, :sort

      params.except!(*search_fields.map { |_key, field_def| field_def[:key] })

      @view_context.render_search_to_s(params)
    end

    def sort_fields_select
      options = sort_fields.values.map { |field_config| [@view_context.sort_field_label(field_config.key), field_config.key] }
      select_tag(:sort, options_for_select(options, params[:sort]), class: "form-control sort-select")
    end

    def search_fields
      blacklight_config.search_fields.select { |_k, v| v.include_in_advanced_search || v.include_in_advanced_search.nil? }
    end

    def sort_fields
      blacklight_config.sort_fields.select { |_k, v| v.include_in_advanced_search || v.include_in_advanced_search.nil? }
    end
  end
end
