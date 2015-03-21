require 'spec_helper'

require 'equivalent-xml'

describe FacetsHelper do
  let(:blacklight_config) { Blacklight::Configuration.new }

  before(:each) do
    allow(helper).to receive(:blacklight_config).and_return blacklight_config
  end
  
  describe "has_facet_values?" do
    it "should be true if there are any facets to display" do

      a = double(:items => [1,2])
      b = double(:items => ['b','c'])
      empty = double(:items => [])

      fields = [a,b,empty]
      expect(helper.has_facet_values?(fields)).to be true
    end

    it "should be false if all facets are empty" do

      empty = double(:items => [])

      fields = [empty]
      expect(helper.has_facet_values?(fields)).to be false
    end
  end

  describe "should_render_facet?" do
    before do
      @config = Blacklight::Configuration.new do |config|
        config.add_facet_field 'basic_field'
        config.add_facet_field 'no_show', :show => false
        config.add_facet_field 'helper_show', :show => :my_helper
        config.add_facet_field 'helper_with_an_arg_show', :show => :my_helper_with_an_arg
        config.add_facet_field 'lambda_show', :show => lambda { |context, config, field| true }
        config.add_facet_field 'lambda_no_show', :show => lambda { |context, config, field| false }
      end

      allow(helper).to receive_messages(:blacklight_config => @config)
    end

    it "should render facets with items" do
      a = double(:items => [1,2], :name=>'basic_field')
      expect(helper.should_render_facet?(a)).to be true
    end
    it "should not render facets without items" do
      empty = double(:items => [], :name=>'basic_field')
      expect(helper.should_render_facet?(empty)).to be false
    end

    it "should not render facets where show is set to false" do
      a = double(:items => [1,2], :name=>'no_show')
      expect(helper.should_render_facet?(a)).to be false
    end

    it "should call a helper to determine if it should render a field" do
      allow(helper).to receive_messages(:my_helper => true)
      a = double(:items => [1,2], :name=>'helper_show')
      expect(helper.should_render_facet?(a)).to be true
    end

    it "should call a helper to determine if it should render a field" do
      a = double(:items => [1,2], :name=>'helper_with_an_arg_show')
      allow(helper).to receive(:my_helper_with_an_arg).with(@config.facet_fields['helper_with_an_arg_show'], a).and_return(true)
      expect(helper.should_render_facet?(a)).to be true
    end


    it "should evaluate a Proc to determine if it should render a field" do
      a = double(:items => [1,2], :name=>'lambda_show')
      expect(helper.should_render_facet?(a)).to be true

      a = double(:items => [1,2], :name=>'lambda_no_show')
      expect(helper.should_render_facet?(a)).to be false
    end
  end

  describe "should_collapse_facet?" do
    before do
      @config = Blacklight::Configuration.new do |config|
        config.add_facet_field 'basic_field'
        config.add_facet_field 'no_collapse', collapse: false
      end

      allow(helper).to receive_messages(blacklight_config: @config)
    end

    it "should be collapsed by default" do
      expect(helper.should_collapse_facet?(@config.facet_fields['basic_field'])).to be true
    end

    it "should not be collapsed if the configuration says so" do
      expect(helper.should_collapse_facet?(@config.facet_fields['no_collapse'])).to be false
    end

    it "should not be collapsed if it is in the params" do
      params[:f] = { basic_field: [1], no_collapse: [2] }.with_indifferent_access
      expect(helper.should_collapse_facet?(@config.facet_fields['basic_field'])).to be false
      expect(helper.should_collapse_facet?(@config.facet_fields['no_collapse'])).to be false
    end

  end

  describe "facet_by_field_name" do
    it "should retrieve the facet from the response given a string" do
      facet_config = double(:query => nil, field: 'a', key: 'a')
      facet_field = double()
      allow(helper).to receive(:facet_configuration_for_field).with(anything()).and_return(facet_config)

      @response = double()
      allow(@response).to receive(:aggregations).and_return('a' => facet_field)

      expect(helper.facet_by_field_name('a')).to eq facet_field
    end
  end


  describe "render_facet_partials" do
    it "should try to render all provided facets " do
      a = double(:items => [1,2])
      b = double(:items => ['b','c'])
      empty = double(:items => [])

      fields = [a,b,empty]

      allow(helper).to receive(:render_facet_limit).with(a, {})
      allow(helper).to receive(:render_facet_limit).with(b, {})
      allow(helper).to receive(:render_facet_limit).with(empty, {})

      helper.render_facet_partials fields
    end

    it "should default to the configured facets" do
      a = double(:items => [1,2])
      b = double(:items => ['b','c'])
      allow(helper).to receive(:facet_field_names) { [a,b] }

      allow(helper).to receive(:render_facet_limit).with(a, {})
      allow(helper).to receive(:render_facet_limit).with(b, {})

      helper.render_facet_partials
    end

  end

  describe "render_facet_limit" do
    before do

      @config = Blacklight::Configuration.new do |config|
        config.add_facet_field 'basic_field'
        config.add_facet_field 'pivot_facet_field', :pivot => ['a', 'b']
        config.add_facet_field 'my_pivot_facet_field_with_custom_partial', :partial => 'custom_facet_partial', :pivot => ['a', 'b']
        config.add_facet_field 'my_facet_field_with_custom_partial', :partial => 'custom_facet_partial'
      end

      allow(helper).to receive_messages(:blacklight_config => @config)
      @response = double()
    end

    it "should set basic local variables" do
      @mock_facet = double(:name => 'basic_field', :items => [1,2,3])
      allow(helper).to receive(:render).with(hash_including(:partial => 'facet_limit', 
                                                         :locals => { 
                                                            :solr_field => 'basic_field',
                                                            :field_name => 'basic_field',
                                                            :facet_field => helper.blacklight_config.facet_fields['basic_field'],
                                                            :display_facet => @mock_facet  }
                                                        ))
      helper.render_facet_limit(@mock_facet)
    end

    it "should render a facet _not_ declared in the configuration" do
      @mock_facet = double(:name => 'asdf', :items => [1,2,3])
      allow(helper).to receive(:render).with(hash_including(:partial => 'facet_limit'))
      helper.render_facet_limit(@mock_facet)
    end

    it "should get the partial name from the configuration" do
      @mock_facet = double(:name => 'my_facet_field_with_custom_partial', :items => [1,2,3])
      allow(helper).to receive(:render).with(hash_including(:partial => 'custom_facet_partial'))
      helper.render_facet_limit(@mock_facet)
    end 

    it "should use a partial layout for rendering the facet frame" do
      @mock_facet = double(:name => 'my_facet_field_with_custom_partial', :items => [1,2,3])
      allow(helper).to receive(:render).with(hash_including(:layout => 'facet_layout'))
      helper.render_facet_limit(@mock_facet)
    end

    it "should allow the caller to opt-out of facet layouts" do
      @mock_facet = double(:name => 'my_facet_field_with_custom_partial', :items => [1,2,3])
      allow(helper).to receive(:render).with(hash_including(:layout => nil))
      helper.render_facet_limit(@mock_facet, :layout => nil)
    end

    it "should render the facet_pivot partial for pivot facets" do
      @mock_facet = double(:name => 'pivot_facet_field', :items => [1,2,3])
      allow(helper).to receive(:render).with(hash_including(:partial => 'facet_pivot'))
      helper.render_facet_limit(@mock_facet)
    end 

    it "should let you override the rendered partial for pivot facets" do
      @mock_facet = double(:name => 'my_pivot_facet_field_with_custom_partial', :items => [1,2,3])
      allow(helper).to receive(:render).with(hash_including(:partial => 'custom_facet_partial'))
      helper.render_facet_limit(@mock_facet)
    end 
  end

  describe "render_facet_limit_list" do
    let(:f1) { Blacklight::SolrResponse::Facets::FacetItem.new(hits: '792', value: 'Book') }
    let(:f2) { Blacklight::SolrResponse::Facets::FacetItem.new(hits: '65', value: 'Musical Score') }
    let(:paginator) { Blacklight::Solr::FacetPaginator.new([f1, f2], limit: 10) }
    subject { helper.render_facet_limit_list(paginator, 'type_solr_field') }
    before do
      allow(helper).to receive(:search_action_path) do |*args|
        catalog_index_path *args
      end
    end
    it "should draw a list of elements" do
      expect(subject).to have_selector 'li', count: 2
      expect(subject).to have_selector 'li:first-child a.facet_select', text: 'Book' 
      expect(subject).to have_selector 'li:nth-child(2) a.facet_select', text: 'Musical Score' 
    end

    context "when one of the facet items is rendered as nil" do
      # An app may override render_facet_item to filter out some undesired facet items by returning nil.
      
      before { allow(helper).to receive(:render_facet_item).and_return("<a class=\"facet_select\">Book</a>".html_safe, nil) }

      it "should draw a list of elements" do
        expect(subject).to have_selector 'li', count: 1
        expect(subject).to have_selector 'li:first-child a.facet_select', text: 'Book' 
      end

    end
  end

  describe "facet_field_in_params?" do
    it "should check if the facet field is selected in the user params" do
      allow(helper).to receive_messages(:params => { :f => { "some-field" => ["x"]}})
      expect(helper.facet_field_in_params?("some-field")).to be_truthy
      expect(helper.facet_field_in_params?("other-field")).to_not be true
    end
  end

  describe "facet_params" do
    it "should extract the facet parameters for a field" do
      allow(helper).to receive_messages(params: { f: { "some-field" => ["x"] }})
      expect(helper.facet_params("some-field")).to match_array ["x"]
    end

    it "should use the blacklight key to extract the right fields" do
      blacklight_config.add_facet_field "some-key", field: "some-field"
      allow(helper).to receive_messages(params: { f: { "some-key" => ["x"] }})
      expect(helper.facet_params("some-key")).to match_array ["x"]
      expect(helper.facet_params("some-field")).to match_array ["x"]
    end
  end

  describe "facet_field_in_params?" do
    it "should check if any value is selected for a given facet" do
      allow(helper).to receive_messages(facet_params: ["x"])
      expect(helper.facet_field_in_params?("some-facet")).to eq true
    end

    it "should be false if no value for facet is selected" do
      allow(helper).to receive_messages(facet_params: nil)
      expect(helper.facet_field_in_params?("some-facet")).to eq false
    end
  end

  describe "facet_in_params?" do
    it "should check if a particular value is set in the facet params" do
      allow(helper).to receive_messages(facet_params: ["x"])
      expect(helper.facet_in_params?("some-facet", "x")).to eq true
      expect(helper.facet_in_params?("some-facet", "y")).to eq false
    end

    it "should be false if no value for facet is selected" do
      allow(helper).to receive_messages(facet_params: nil)
      expect(helper.facet_in_params?("some-facet", "x")).to eq false
    end
  end

  describe "render_facet_value" do
    let (:item) { double(:value => 'A', :hits => 10) }
    before do
      allow(helper).to receive(:facet_configuration_for_field).with('simple_field').and_return(double(:query => nil, :date => nil, :helper_method => nil, :single => false))
      allow(helper).to receive(:facet_display_value).and_return('Z')
      allow(helper).to receive(:add_facet_params_and_redirect).and_return({controller:'catalog'})
      
      allow(helper).to receive(:search_action_path) do |*args|
        catalog_index_path *args
      end
    end
    describe "simple case" do
      let(:expected_html) { "<span class=\"facet-label\"><a class=\"facet_select\" href=\"/catalog\">Z</a></span><span class=\"facet-count\">10</span>" }
      it "should use facet_display_value" do
        result = helper.render_facet_value('simple_field', item)
        expect(result).to be_equivalent_to(expected_html).respecting_element_order
      end
    end

    describe "when :suppress_link is set" do
      let(:expected_html) { "<span class=\"facet-label\">Z</span><span class=\"facet-count\">10</span>" }
      it "should suppress the link" do
        result = helper.render_facet_value('simple_field', item, :suppress_link => true)
        expect(result).to be_equivalent_to(expected_html).respecting_element_order
      end
    end
  end
 
  describe "#facet_display_value" do
    it "should just be the facet value for an ordinary facet" do
      allow(helper).to receive(:facet_configuration_for_field).with('simple_field').and_return(double(:query => nil, :date => nil, :helper_method => nil))
      expect(helper.facet_display_value('simple_field', 'asdf')).to eq 'asdf'
    end

    it "should allow you to pass in a :helper_method argument to the configuration" do
      allow(helper).to receive(:facet_configuration_for_field).with('helper_field').and_return(double(:query => nil, :date => nil, :helper_method => :my_facet_value_renderer))
    
      allow(helper).to receive(:my_facet_value_renderer).with('qwerty').and_return('abc')

      expect(helper.facet_display_value('helper_field', 'qwerty')).to eq 'abc'
    end

    it "should extract the configuration label for a query facet" do
      allow(helper).to receive(:facet_configuration_for_field).with('query_facet').and_return(double(:query => { 'query_key' => { :label => 'XYZ'}}, :date => nil, :helper_method => nil))
      expect(helper.facet_display_value('query_facet', 'query_key')).to eq 'XYZ'
    end

    it "should localize the label for date-type facets" do
      allow(helper).to receive(:facet_configuration_for_field).with('date_facet').and_return(double('date' => true, :query => nil, :helper_method => nil))
      expect(helper.facet_display_value('date_facet', '2012-01-01')).to eq 'Sun, 01 Jan 2012 00:00:00 +0000'
    end

    it "should localize the label for date-type facets with the supplied localization options" do
      allow(helper).to receive(:facet_configuration_for_field).with('date_facet').and_return(double('date' => { :format => :short }, :query => nil, :helper_method => nil))
      expect(helper.facet_display_value('date_facet', '2012-01-01')).to eq '01 Jan 00:00'
    end
  end

  describe "#facet_field_id" do
    it "should be the parameterized version of the facet field" do
      expect(helper.facet_field_id double(key: 'some field')).to eq "facet-some-field"
    end
  end
end
