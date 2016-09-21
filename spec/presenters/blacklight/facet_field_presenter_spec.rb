# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::FacetFieldPresenter do
  let(:controller) { CatalogController.new }
  let(:view_context) { controller.view_context }
  let(:facet) { instance_double(Blacklight::Solr::Response::Facets::FacetField,
                                     name: 'basic_field',
                                     items: [1, 2, 3]) }

  let(:instance) { described_class.new(facet, view_context) }

  describe "#render?" do
    let(:blacklight_config) do
      Blacklight::Configuration.new do |config|
        config.add_facet_field 'basic_field'
        config.add_facet_field 'no_show', :show => false
        config.add_facet_field 'helper_show', :show => :my_custom_check
        config.add_facet_field 'helper_with_an_arg_show', :show => :my_custom_check_with_an_arg
        config.add_facet_field 'lambda_show',    :show => lambda { |context, config, field| true }
        config.add_facet_field 'lambda_no_show', :show => lambda { |context, config, field| false }
      end
    end

    before do
      allow(controller).to receive(:blacklight_config).and_return(blacklight_config)
    end

    it "renders facets with items" do
      expect(instance.render?).to be true
    end

    context "facet has no items" do
      let(:facet) { instance_double(Blacklight::Solr::Response::Facets::FacetField,
                                         name: 'basic_field',
                                         items: []) }
      it "does not render facets without items" do
        expect(instance.render?).to be false
      end
    end

    context "where show is set to false" do
      let(:facet) { instance_double(Blacklight::Solr::Response::Facets::FacetField,
                                         name: 'no_show',
                                         items: [1, 2]) }
      it "does not render facets" do
        expect(instance.render?).to be false
      end
    end

    context "with an show option pointing at a method" do
      let(:facet) { instance_double(Blacklight::Solr::Response::Facets::FacetField,
                                         name: 'helper_show',
                                         items: [1, 2]) }
      it "calls the method to determine if it should render a field" do
        allow(controller).to receive_messages(:my_custom_check => true)
        expect(instance.render?).to be true
      end
    end

    context "with an show option pointing at a method that takes arguments" do
      let(:facet) { instance_double(Blacklight::Solr::Response::Facets::FacetField,
                                         name: 'helper_with_an_arg_show',
                                         items: [1, 2]) }
      it "calls a method to determine if it should render a field" do
        allow(controller).to receive(:my_custom_check_with_an_arg).with(blacklight_config.facet_fields['helper_with_an_arg_show'], facet).and_return(true)
        expect(instance.render?).to be true
      end
    end

    context "with a proc" do
      context "that evaluates to true" do
        let(:facet) { instance_double(Blacklight::Solr::Response::Facets::FacetField,
                                      name: 'lambda_show',
                                      items: [1, 2]) }
        it "evaluates a Proc to determine if it should render a field" do
          expect(instance.render?).to be true
        end
      end

      context "that evaluates to false" do
        let(:facet) { instance_double(Blacklight::Solr::Response::Facets::FacetField,
                                      name: 'lambda_no_show',
                                      items: [1, 2]) }
        it "evaluates a Proc to determine if it should render a field" do
          expect(instance.render?).to be false
        end
      end
    end
  end

  describe "#render_facet_limit_list" do
    let(:f1) { Blacklight::Solr::Response::Facets::FacetItem.new(hits: '792', value: 'Book') }
    let(:f2) { Blacklight::Solr::Response::Facets::FacetItem.new(hits: '65', value: 'Musical Score') }
    let(:paginator) { Blacklight::Solr::FacetPaginator.new([f1, f2], limit: 10) }
    subject { Capybara::Node::Simple.new(value) }
    let(:value) { instance.render_facet_limit_list(paginator, 'type_solr_field') }

    before do
      allow(controller).to receive(:params).and_return({})
      allow(view_context).to receive(:search_action_path) do |*args|
        Rails.application.routes.url_helpers.search_catalog_path *args
      end
    end

    it "draws a list of elements" do
      expect(subject).to have_selector 'li', count: 2
      expect(subject).to have_selector 'li:first-child a.facet-select', text: 'Book'
      expect(subject).to have_selector 'li:nth-child(2) a.facet-select', text: 'Musical Score'
    end

    context "when one of the facet items is rendered as nil" do
      # An app may override render_facet_item to filter out some undesired facet items by returning nil.
      let(:facet_item_presenter) { instance_double(Blacklight::FacetItemPresenter) }
      before do
        allow(Blacklight::FacetItemPresenter).to receive(:new).and_return(facet_item_presenter)
        allow(facet_item_presenter).to receive(:render_item).and_return('<a class="facet-select">Book</a>'.html_safe, nil)
      end

      it "draws a list of elements" do
        expect(subject).to have_selector 'li', count: 1
        expect(subject).to have_selector 'li:first-child a.facet-select', text: 'Book'
      end
    end
  end

  describe "#render_facet_limit" do
    let(:blacklight_config) do
      Blacklight::Configuration.new do |config|
        config.add_facet_field 'basic_field'
        config.add_facet_field 'pivot_facet_field', :pivot => ['a', 'b']
        config.add_facet_field 'my_pivot_facet_field_with_custom_partial', partial: 'custom_facet_partial', pivot: ['a', 'b']
        config.add_facet_field 'my_facet_field_with_custom_partial', partial: 'custom_facet_partial'
      end
    end
    before do
      allow(controller).to receive(:blacklight_config).and_return(blacklight_config)
    end

    it "sets basic local variables" do
      expect(view_context).to receive(:render).with(hash_including(partial: 'facet_limit',
                                                               locals: {
                                                                 field_name: 'basic_field',
                                                                 facet_field: view_context.blacklight_config.facet_fields['basic_field'],
                                                                 display_facet: facet,
                                                                 presenter: instance
                                                               }
                                                            ))
      instance.render_facet_limit()
    end

    context "when facet is not in the configuration" do
      let(:facet) { instance_double(Blacklight::Solr::Response::Facets::FacetField,
                                    name: 'asdf',
                                    items: [1, 2, 3]) }
      it "renders a facet _not_ declared in the configuration" do
        expect(view_context).to receive(:render).with(hash_including(:partial => 'facet_limit'))
        instance.render_facet_limit
      end
    end

    context "when facet has a custom partal" do
      let(:facet) { instance_double(Blacklight::Solr::Response::Facets::FacetField,
                                     name: 'my_facet_field_with_custom_partial',
                                     items: [1, 2, 3]) }
      it "gets the partial name from the configuration" do
        expect(view_context).to receive(:render).with(hash_including(:partial => 'custom_facet_partial'))
        instance.render_facet_limit
      end
    end

    it "uses a partial layout for rendering the facet frame" do
      expect(view_context).to receive(:render).with(hash_including(layout: 'facet_layout'))
      instance.render_facet_limit
    end

    it "allows the caller to opt-out of facet layouts" do
      expect(view_context).to receive(:render).with(hash_including(layout: nil))
      instance.render_facet_limit(layout: nil)
    end

    context "for pivot facet" do
      let(:facet) { instance_double(Blacklight::Solr::Response::Facets::FacetField,
                                    name: 'pivot_facet_field',
                                    items: [1, 2, 3]) }
      it "renders the facet_pivot partial for pivot facets" do
        expect(view_context).to receive(:render).with(hash_including(partial: 'facet_pivot'))
        instance.render_facet_limit
      end
    end

    context "for pivot facet with a custom partial" do
      let(:facet) { instance_double(Blacklight::Solr::Response::Facets::FacetField,
                                    name: 'my_pivot_facet_field_with_custom_partial',
                                    items: [1, 2, 3]) }
      it "lets you override the rendered partial for pivot facets" do
        expect(view_context).to receive(:render).with(hash_including(partial: 'custom_facet_partial'))
        instance.render_facet_limit
      end
    end
  end
end
