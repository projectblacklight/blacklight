require 'spec_helper'

RSpec.describe Blacklight::FacetListPresenter do
  let(:response) { instance_double(Blacklight::Solr::Response) }
  let(:blacklight_config) { Blacklight::Configuration.new }
  let(:controller) { CatalogController.new }
  let(:view_context) { controller.view_context }
  let(:instance) { described_class.new(response, view_context) }


  describe "#values?" do
    subject { instance.values?(fields) }
    let(:empty) { double(:items => [], :name => 'empty') }

    context "if there are any facets to display" do
      let(:a) { double(:items => [1, 2], :name => 'a') }
      let(:b) { double(:items => ['b', 'c'], :name => 'b') }
      let(:fields) { [a, b, empty] }

      it { is_expected.to be true }
    end

    context "if all facets are empty" do
      let(:fields) { [empty] }
      it { is_expected.to be false }
    end

    context "if no facets are displayable" do
      let(:blacklight_config) do
        Blacklight::Configuration.new { |config| config.add_facet_field 'basic_field', if: false }
      end

      before do
        allow(controller).to receive(:blacklight_config).and_return(blacklight_config)
      end

      let(:fields) { [double(:items => [1, 2], :name => 'basic_field')] }
      it { is_expected.to be false }
    end
  end

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
      a = double(:items => [1, 2], :name => 'basic_field')
      expect(instance.render?(a)).to be true
    end

    it "does not render facets without items" do
      empty = double(:items => [], :name => 'basic_field')
      expect(instance.render?(empty)).to be false
    end

    it "does not render facets where show is set to false" do
      a = double(:items => [1, 2], :name => 'no_show')
      expect(instance.render?(a)).to be false
    end

    it "calls a helper to determine if it should render a field" do
      allow(controller).to receive_messages(:my_custom_check => true)
      a = double(:items => [1, 2], :name => 'helper_show')
      expect(instance.render?(a)).to be true
    end

    context "helper with an argument" do
      it "calls a helper to determine if it should render a field" do
        a = double(items: [1, 2], name: 'helper_with_an_arg_show')
        allow(controller).to receive(:my_custom_check_with_an_arg).with(blacklight_config.facet_fields['helper_with_an_arg_show'], a).and_return(true)
        expect(instance.render?(a)).to be true
      end
    end

    it "evaluates a Proc to determine if it should render a field" do
      a = double(:items => [1, 2], :name => 'lambda_show')
      expect(instance.render?(a)).to be true
      a = double(:items => [1, 2], :name => 'lambda_no_show')
      expect(instance.render?(a)).to be false
    end
  end

  describe "render_partials" do
    let(:a) { double(:items => [1, 2]) }
    let(:b) { double(:items => ['b', 'c']) }

    it "tries to render all provided facets" do
      empty = double(:items => [])
      fields = [a, b, empty]
      expect(instance).to receive(:render_facet_limit).with(a, {})
      expect(instance).to receive(:render_facet_limit).with(b, {})
      expect(instance).to receive(:render_facet_limit).with(empty, {})
      instance.render_partials fields
    end

    it "defaults to the configured facets" do
      expect(instance).to receive(:facet_field_names) { [a, b] }
      expect(instance).to receive(:render_facet_limit).with(a, {})
      expect(instance).to receive(:render_facet_limit).with(b, {})
      instance.render_partials
    end
  end

  describe "render_facet_limit_list" do
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


  describe "render_facet_limit" do
    let(:blacklight_config) do
      Blacklight::Configuration.new do |config|
        config.add_facet_field 'basic_field'
        config.add_facet_field 'pivot_facet_field', :pivot => ['a', 'b']
        config.add_facet_field 'my_pivot_facet_field_with_custom_partial', :partial => 'custom_facet_partial', :pivot => ['a', 'b']
        config.add_facet_field 'my_facet_field_with_custom_partial', :partial => 'custom_facet_partial'
      end
    end
    let(:mock_custom_facet) { double(:name => 'my_facet_field_with_custom_partial', :items => [1, 2, 3]) }

    before do
      allow(controller).to receive(:blacklight_config).and_return(blacklight_config)
    end

    it "sets basic local variables" do
      mock_facet = double(:name => 'basic_field', :items => [1, 2, 3])
      expect(instance).to receive(:render).with(hash_including(partial: 'facet_limit',
                                                               locals: {
                                                                 field_name: 'basic_field',
                                                                 facet_field: view_context.blacklight_config.facet_fields['basic_field'],
                                                                 display_facet: mock_facet,
                                                                 presenter: instance
                                                               }
                                                            ))
      instance.render_facet_limit(mock_facet)
    end

    it "renders a facet _not_ declared in the configuration" do
      mock_facet = double(:name => 'asdf', :items => [1, 2, 3])
      expect(view_context).to receive(:render).with(hash_including(:partial => 'facet_limit'))
      instance.render_facet_limit(mock_facet)
    end

    it "gets the partial name from the configuration" do
      expect(view_context).to receive(:render).with(hash_including(:partial => 'custom_facet_partial'))
      instance.render_facet_limit(mock_custom_facet)
    end

    it "uses a partial layout for rendering the facet frame" do
      expect(view_context).to receive(:render).with(hash_including(:layout => 'facet_layout'))
      instance.render_facet_limit(mock_custom_facet)
    end

    it "allows the caller to opt-out of facet layouts" do
      expect(view_context).to receive(:render).with(hash_including(:layout => nil))
      instance.render_facet_limit(mock_custom_facet, :layout => nil)
    end

    it "renders the facet_pivot partial for pivot facets" do
      mock_facet = double(:name => 'pivot_facet_field', :items => [1, 2, 3])
      expect(view_context).to receive(:render).with(hash_including(:partial => 'facet_pivot'))
      instance.render_facet_limit(mock_facet)
    end

    it "lets you override the rendered partial for pivot facets" do
      mock_facet = double(:name => 'my_pivot_facet_field_with_custom_partial', :items => [1, 2, 3])
      expect(view_context).to receive(:render).with(hash_including(:partial => 'custom_facet_partial'))
      instance.render_facet_limit(mock_facet)
    end
  end


end
