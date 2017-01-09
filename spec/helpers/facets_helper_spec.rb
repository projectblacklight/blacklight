# frozen_string_literal: true

describe FacetsHelper do
  let(:blacklight_config) { Blacklight::Configuration.new }

  before(:each) do
    allow(helper).to receive(:blacklight_config).and_return blacklight_config
  end

  describe "has_facet_values?" do
    let(:empty) { double(:items => [], :name => 'empty') }

    it "is true if there are any facets to display" do
      a = double(:items => [1, 2], :name => 'a')
      b = double(:items => ['b', 'c'], :name => 'b')
      fields = [a, b, empty]
      expect(helper.has_facet_values?(fields)).to be true
    end

    it "is false if all facets are empty" do
      expect(helper.has_facet_values?([empty])).to be false
    end

    describe "different config" do
      let(:blacklight_config) { Blacklight::Configuration.new { |config| config.add_facet_field 'basic_field', :if => false } }
      it "is false if no facets are displayable" do
        a = double(:items => [1, 2], :name => 'basic_field')
        expect(helper.has_facet_values?([a])).to be false
      end
    end
  end

  describe "should_render_facet?" do
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

    it "renders facets with items" do
      a = double(:items => [1, 2], :name => 'basic_field')
      expect(helper.should_render_facet?(a)).to be true
    end

    it "does not render facets without items" do
      empty = double(:items => [], :name => 'basic_field')
      expect(helper.should_render_facet?(empty)).to be false
    end

    it "does not render facets where show is set to false" do
      a = double(:items => [1, 2], :name => 'no_show')
      expect(helper.should_render_facet?(a)).to be false
    end

    it "calls a helper to determine if it should render a field" do
      allow(controller).to receive_messages(:my_custom_check => true)
      a = double(:items => [1, 2], :name => 'helper_show')
      expect(helper.should_render_facet?(a)).to be true
    end

    it "calls a helper to determine if it should render a field" do
      a = double(:items => [1, 2], :name => 'helper_with_an_arg_show')
      allow(controller).to receive(:my_custom_check_with_an_arg).with(blacklight_config.facet_fields['helper_with_an_arg_show'], a).and_return(true)
      expect(helper.should_render_facet?(a)).to be true
    end

    it "evaluates a Proc to determine if it should render a field" do
      a = double(:items => [1, 2], :name => 'lambda_show')
      expect(helper.should_render_facet?(a)).to be true
      a = double(:items => [1, 2], :name => 'lambda_no_show')
      expect(helper.should_render_facet?(a)).to be false
    end
  end

  describe "should_collapse_facet?" do
    let(:blacklight_config) do
      Blacklight::Configuration.new do |config|
        config.add_facet_field 'basic_field'
        config.add_facet_field 'no_collapse', collapse: false
      end
    end

    it "is collapsed by default" do
      expect(helper.should_collapse_facet?(blacklight_config.facet_fields['basic_field'])).to be true
    end

    it "does not be collapsed if the configuration says so" do
      expect(helper.should_collapse_facet?(blacklight_config.facet_fields['no_collapse'])).to be false
    end

    it "does not be collapsed if it is in the params" do
      params[:f] = ActiveSupport::HashWithIndifferentAccess.new(basic_field: [1], no_collapse: [2])
      expect(helper.should_collapse_facet?(blacklight_config.facet_fields['basic_field'])).to be false
      expect(helper.should_collapse_facet?(blacklight_config.facet_fields['no_collapse'])).to be false
    end
  end

  describe "facet_by_field_name" do
    it "retrieves the facet from the response given a string" do
      facet_config = double(query: nil, field: 'b', key: 'a')
      facet_field = double()
      allow(helper).to receive(:facet_configuration_for_field).with('b').and_return(facet_config)
      @response = instance_double(Blacklight::Solr::Response, aggregations: { 'b' => facet_field })

      expect(helper.facet_by_field_name('b')).to eq facet_field
    end
  end

  describe "render_facet_partials" do
    let(:a) { double(:items => [1, 2]) }
    let(:b) { double(:items => ['b', 'c']) }

    it "tries to render all provided facets" do
      empty = double(:items => [])
      fields = [a, b, empty]
      expect(helper).to receive(:render_facet_limit).with(a, {})
      expect(helper).to receive(:render_facet_limit).with(b, {})
      expect(helper).to receive(:render_facet_limit).with(empty, {})
      helper.render_facet_partials fields
    end

    it "defaults to the configured facets" do
      expect(helper).to receive(:facet_field_names) { [a, b] }
      expect(helper).to receive(:render_facet_limit).with(a, {})
      expect(helper).to receive(:render_facet_limit).with(b, {})
      helper.render_facet_partials
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

    it "sets basic local variables" do
      mock_facet = double(:name => 'basic_field', :items => [1, 2, 3])
      expect(helper).to receive(:render).with(hash_including(:partial => 'facet_limit',
                                                             :locals => {
                                                                :solr_field => 'basic_field',
                                                                :field_name => 'basic_field',
                                                                :facet_field => helper.blacklight_config.facet_fields['basic_field'],
                                                                :display_facet => mock_facet  }
                                                            ))
      helper.render_facet_limit(mock_facet)
    end

    it "renders a facet _not_ declared in the configuration" do
      mock_facet = double(:name => 'asdf', :items => [1, 2, 3])
      expect(helper).to receive(:render).with(hash_including(:partial => 'facet_limit'))
      helper.render_facet_limit(mock_facet)
    end

    it "gets the partial name from the configuration" do
      expect(helper).to receive(:render).with(hash_including(:partial => 'custom_facet_partial'))
      helper.render_facet_limit(mock_custom_facet)
    end

    it "uses a partial layout for rendering the facet frame" do
      expect(helper).to receive(:render).with(hash_including(:layout => 'facet_layout'))
      helper.render_facet_limit(mock_custom_facet)
    end

    it "allows the caller to opt-out of facet layouts" do
      expect(helper).to receive(:render).with(hash_including(:layout => nil))
      helper.render_facet_limit(mock_custom_facet, :layout => nil)
    end

    it "renders the facet_pivot partial for pivot facets" do
      mock_facet = double(:name => 'pivot_facet_field', :items => [1, 2, 3])
      expect(helper).to receive(:render).with(hash_including(:partial => 'facet_pivot'))
      helper.render_facet_limit(mock_facet)
    end

    it "lets you override the rendered partial for pivot facets" do
      mock_facet = double(:name => 'my_pivot_facet_field_with_custom_partial', :items => [1, 2, 3])
      expect(helper).to receive(:render).with(hash_including(:partial => 'custom_facet_partial'))
      helper.render_facet_limit(mock_facet)
    end
  end

  describe "render_facet_limit_list" do
    let(:f1) { Blacklight::Solr::Response::Facets::FacetItem.new(hits: '792', value: 'Book') }
    let(:f2) { Blacklight::Solr::Response::Facets::FacetItem.new(hits: '65', value: 'Musical Score') }
    let(:paginator) { Blacklight::Solr::FacetPaginator.new([f1, f2], limit: 10) }
    subject { helper.render_facet_limit_list(paginator, 'type_solr_field') }
    before do
      allow(helper).to receive(:search_action_path) do |*args|
        search_catalog_path *args
      end
    end

    it "draws a list of elements" do
      expect(subject).to have_selector 'li', count: 2
      expect(subject).to have_selector 'li:first-child a.facet_select', text: 'Book'
      expect(subject).to have_selector 'li:nth-child(2) a.facet_select', text: 'Musical Score'
    end

    context "when one of the facet items is rendered as nil" do
      # An app may override render_facet_item to filter out some undesired facet items by returning nil.
      before { allow(helper).to receive(:render_facet_item).and_return('<a class="facet_select">Book</a>'.html_safe, nil) }

      it "draws a list of elements" do
        expect(subject).to have_selector 'li', count: 1
        expect(subject).to have_selector 'li:first-child a.facet_select', text: 'Book'
      end
    end
  end

  describe "facet_field_in_params?" do
    it "checks if the facet field is selected in the user params" do
      allow(helper).to receive_messages(:params => { :f => { "some-field" => ["x"]}})
      expect(helper.facet_field_in_params?("some-field")).to be_truthy
      expect(helper.facet_field_in_params?("other-field")).to_not be true
    end
  end

  describe "facet_params" do
    it "extracts the facet parameters for a field" do
      allow(helper).to receive_messages(params: { f: { "some-field" => ["x"] }})
      expect(helper.facet_params("some-field")).to match_array ["x"]
    end

    it "uses the blacklight key to extract the right fields" do
      blacklight_config.add_facet_field "some-key", field: "some-field"
      allow(helper).to receive_messages(params: { f: { "some-key" => ["x"] }})
      expect(helper.facet_params("some-key")).to match_array ["x"]
      expect(helper.facet_params("some-field")).to match_array ["x"]
    end
  end

  describe "facet_field_in_params?" do
    it "checks if any value is selected for a given facet" do
      allow(helper).to receive_messages(facet_params: ["x"])
      expect(helper.facet_field_in_params?("some-facet")).to eq true
    end

    it "is false if no value for facet is selected" do
      allow(helper).to receive_messages(facet_params: nil)
      expect(helper.facet_field_in_params?("some-facet")).to eq false
    end
  end

  describe "facet_in_params?" do
    it "checks if a particular value is set in the facet params" do
      allow(helper).to receive_messages(facet_params: ["x"])
      expect(helper.facet_in_params?("some-facet", "x")).to eq true
      expect(helper.facet_in_params?("some-facet", "y")).to eq false
    end

    it "is false if no value for facet is selected" do
      allow(helper).to receive_messages(facet_params: nil)
      expect(helper.facet_in_params?("some-facet", "x")).to eq false
    end
  end

  describe "render_facet_value" do
    let(:item) { double(:value => 'A', :hits => 10) }
    let(:search_state) { double(add_facet_params_and_redirect: { controller: 'catalog' }) }
    before do
      allow(helper).to receive(:facet_configuration_for_field).with('simple_field').and_return(double(:query => nil, :date => nil, :helper_method => nil, :single => false, :url_method => nil))
      allow(helper).to receive(:facet_display_value).and_return('Z')
      allow(helper).to receive(:search_state).and_return(search_state)
      allow(helper).to receive(:search_action_path) do |*args|
        search_catalog_path *args
      end
    end

    describe "simple case" do
      let(:expected_html) { '<span class="facet-label"><a class="facet_select" href="/catalog">Z</a></span><span class="facet-count">10</span>' }

      it "uses facet_display_value" do
        result = helper.render_facet_value('simple_field', item)
        expect(result).to be_equivalent_to(expected_html).respecting_element_order
      end
    end

    describe "when :url_method is set" do
      let(:expected_html) { '<span class="facet-label"><a class="facet_select" href="/blabla">Z</a></span><span class="facet-count">10</span>' }
      it "uses that method" do
        allow(helper).to receive(:facet_configuration_for_field).with('simple_field').and_return(double(:query => nil, :date => nil, :helper_method => nil, :single => false, :url_method => :test_method))
        allow(helper).to receive(:test_method).with('simple_field', item).and_return('/blabla')
        result = helper.render_facet_value('simple_field', item)
        expect(result).to be_equivalent_to(expected_html).respecting_element_order
      end
    end

    describe "when :suppress_link is set" do
      let(:expected_html) { '<span class="facet-label">Z</span><span class="facet-count">10</span>' }
      it "suppresses the link" do
        result = helper.render_facet_value('simple_field', item, :suppress_link => true)
        expect(result).to be_equivalent_to(expected_html).respecting_element_order
      end
    end
  end

  describe "#facet_display_value" do
    it "justs be the facet value for an ordinary facet" do
      allow(helper).to receive(:facet_configuration_for_field).with('simple_field').and_return(double(:query => nil, :date => nil, :helper_method => nil, :url_method => nil))
      expect(helper.facet_display_value('simple_field', 'asdf')).to eq 'asdf'
    end

    it "allows you to pass in a :helper_method argument to the configuration" do
      allow(helper).to receive(:facet_configuration_for_field).with('helper_field').and_return(double(:query => nil, :date => nil, :url_method => nil, :helper_method => :my_facet_value_renderer))
      allow(helper).to receive(:my_facet_value_renderer).with('qwerty').and_return('abc')
      expect(helper.facet_display_value('helper_field', 'qwerty')).to eq 'abc'
    end

    it "extracts the configuration label for a query facet" do
      allow(helper).to receive(:facet_configuration_for_field).with('query_facet').and_return(double(:query => { 'query_key' => { :label => 'XYZ'}}, :date => nil, :helper_method => nil, :url_method => nil))
      expect(helper.facet_display_value('query_facet', 'query_key')).to eq 'XYZ'
    end

    it "localizes the label for date-type facets" do
      allow(helper).to receive(:facet_configuration_for_field).with('date_facet').and_return(double('date' => true, :query => nil, :helper_method => nil, :url_method => nil))
      expect(helper.facet_display_value('date_facet', '2012-01-01')).to eq 'Sun, 01 Jan 2012 00:00:00 +0000'
    end

    it "localizes the label for date-type facets with the supplied localization options" do
      allow(helper).to receive(:facet_configuration_for_field).with('date_facet').and_return(double('date' => { :format => :short }, :query => nil, :helper_method => nil, :url_method => nil))
      expect(helper.facet_display_value('date_facet', '2012-01-01')).to eq '01 Jan 00:00'
    end
  end

  describe "#facet_field_id" do
    it "is the parameterized version of the facet field" do
      expect(helper.facet_field_id double(key: 'some field')).to eq "facet-some-field"
    end
  end
end
