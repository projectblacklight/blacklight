require 'spec_helper'

require 'equivalent-xml'

describe FacetsHelper do
  let(:blacklight_config) { Blacklight::Configuration.new }

  before(:each) do
    helper.stub(:blacklight_config).and_return blacklight_config
  end
  
  describe "has_facet_values?" do
    it "should be true if there are any facets to display" do

      a = double(:items => [1,2])
      b = double(:items => ['b','c'])
      empty = double(:items => [])

      fields = [a,b,empty]
      expect(helper.has_facet_values?(fields)).to be_true
    end

    it "should be false if all facets are empty" do

      empty = double(:items => [])

      fields = [empty]
      expect(helper.has_facet_values?(fields)).to be_false
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

      helper.stub(:blacklight_config => @config)
    end

    it "should render facets with items" do
      a = double(:items => [1,2], :name=>'basic_field')
      expect(helper.should_render_facet?(a)).to be_true
    end
    it "should not render facets without items" do
      empty = double(:items => [], :name=>'basic_field')
      expect(helper.should_render_facet?(empty)).to be_false
    end

    it "should not render facets where show is set to false" do
      a = double(:items => [1,2], :name=>'no_show')
      expect(helper.should_render_facet?(a)).to be_false
    end

    it "should call a helper to determine if it should render a field" do
      helper.stub(:my_helper => true)
      a = double(:items => [1,2], :name=>'helper_show')
      expect(helper.should_render_facet?(a)).to be_true
    end

    it "should call a helper to determine if it should render a field" do
      a = double(:items => [1,2], :name=>'helper_with_an_arg_show')
      helper.should_receive(:my_helper_with_an_arg).with(@config.facet_fields['helper_with_an_arg_show'], a).and_return(true)
      expect(helper.should_render_facet?(a)).to be_true
    end


    it "should evaluate a Proc to determine if it should render a field" do
      a = double(:items => [1,2], :name=>'lambda_show')
      expect(helper.should_render_facet?(a)).to be_true

      a = double(:items => [1,2], :name=>'lambda_no_show')
      expect(helper.should_render_facet?(a)).to be_false
    end
  end

  describe "should_collapse_facet?" do
    before do
      @config = Blacklight::Configuration.new do |config|
        config.add_facet_field 'basic_field'
        config.add_facet_field 'no_collapse', collapse: false
      end

      helper.stub(blacklight_config: @config)
    end

    it "should be collapsed by default" do
      expect(helper.should_collapse_facet?(@config.facet_fields['basic_field'])).to be_true
    end

    it "should not be collapsed if the configuration says so" do
      expect(helper.should_collapse_facet?(@config.facet_fields['no_collapse'])).to be_false
    end

    it "should not be collapsed if it is in the params" do
      params[:f] = { basic_field: [1], no_collapse: [2] }.with_indifferent_access
      expect(helper.should_collapse_facet?(@config.facet_fields['basic_field'])).to be_false
      expect(helper.should_collapse_facet?(@config.facet_fields['no_collapse'])).to be_false
    end

  end

  describe "facet_by_field_name" do
    it "should retrieve the facet from the response given a string" do
      facet_config = double(:query => nil)
      facet_field = double()
      helper.should_receive(:facet_configuration_for_field).with(anything()).and_return(facet_config)

      @response = double()
      @response.should_receive(:facet_by_field_name).with('a').and_return(facet_field)

      expect(helper.facet_by_field_name('a')).to eq facet_field
    end

    it "should also work for facet query fields" do
      facet_config = double(:query => {})
      helper.should_receive(:facet_configuration_for_field).with('a_query_facet_field').and_return(facet_config)
      helper.should_receive(:create_rsolr_facet_field_response_for_query_facet_field).with('a_query_facet_field', facet_config)

      helper.facet_by_field_name 'a_query_facet_field'
    end

    describe "query facets" do
      let(:facet_config) { 
        double(
          :query => {
             'a_simple_query' => { :fq => 'field:search', :label => 'A Human Readable label'},
             'another_query' => { :fq => 'field:different_search', :label => 'Label'},
             'without_results' => { :fq => 'field:without_results', :label => 'No results for this facet'}
             }
        )
      }

      before(:each) do
        helper.should_receive(:facet_configuration_for_field).with(anything()).and_return(facet_config)

        @response = double(:facet_queries => {
          'field:search' => 10,
          'field:different_search' => 2,
          'field:not_appearing_in_the_config' => 50,
          'field:without_results' => 0
        })
      end

      it"should convert the query facets into a double RSolr FacetField" do
        field = helper.facet_by_field_name('my_query_facet_field')
        field.should be_a_kind_of Blacklight::SolrResponse::Facets::FacetField

        expect(field.name).to eq'my_query_facet_field'
        expect(field.items).to have(2).items
        expect(field.items.map { |x| x.value }).to_not include 'field:not_appearing_in_the_config'

        facet_item = field.items.select { |x| x.value == 'a_simple_query' }.first

        expect(facet_item.value).to eq 'a_simple_query'
        expect(facet_item.hits).to eq 10
        expect(facet_item.label).to eq 'A Human Readable label'
      end
    end

    describe "pivot facets" do
      let(:facet_config) {
        double(:pivot => ['field_a', 'field_b'])
      }

      before(:each) do 
        helper.should_receive(:facet_configuration_for_field).with(anything()).and_return(facet_config)
      
        @response = double(:facet_pivot => { 'field_a,field_b' => [{:field => 'field_a', :value => 'a', :count => 10, :pivot => [{:field => 'field_b', :value => 'b', :count => 2}]}]})
      end

      it "should convert the pivot facet into a double RSolr FacetField" do
        field = helper.facet_by_field_name('my_pivot_facet_field')
        field.should be_a_kind_of Blacklight::SolrResponse::Facets::FacetField

        expect(field.name).to eq 'my_pivot_facet_field'

        expect(field.items).to have(1).item

        expect(field.items.first).to respond_to(:items)

        expect(field.items.first.items).to have(1).item
        expect(field.items.first.items.first.fq).to eq({ 'field_a' => 'a' })
      end
    end
  end


  describe "render_facet_partials" do
    it "should try to render all provided facets " do
      a = double(:items => [1,2])
      b = double(:items => ['b','c'])
      empty = double(:items => [])

      fields = [a,b,empty]

      helper.should_receive(:render_facet_limit).with(a, {})
      helper.should_receive(:render_facet_limit).with(b, {})
      helper.should_receive(:render_facet_limit).with(empty, {})

      helper.render_facet_partials fields
    end

    it "should default to the configured facets" do
      a = double(:items => [1,2])
      b = double(:items => ['b','c'])
      helper.should_receive(:facet_field_names) { [a,b] }

      helper.should_receive(:render_facet_limit).with(a, {})
      helper.should_receive(:render_facet_limit).with(b, {})

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

      helper.stub(:blacklight_config => @config)
      @response = double()
    end

    it "should set basic local variables" do
      @mock_facet = double(:name => 'basic_field', :items => [1,2,3])
      helper.should_receive(:render).with(hash_including(:partial => 'facet_limit', 
                                                         :locals => { 
                                                            :solr_field => 'basic_field',
                                                            :facet_field => helper.blacklight_config.facet_fields['basic_field'],
                                                            :display_facet => @mock_facet  }
                                                        ))
      helper.render_facet_limit(@mock_facet)
    end

    it "should render a facet _not_ declared in the configuration" do
      @mock_facet = double(:name => 'asdf', :items => [1,2,3])
      helper.should_receive(:render).with(hash_including(:partial => 'facet_limit'))
      helper.render_facet_limit(@mock_facet)
    end

    it "should get the partial name from the configuration" do
      @mock_facet = double(:name => 'my_facet_field_with_custom_partial', :items => [1,2,3])
      helper.should_receive(:render).with(hash_including(:partial => 'custom_facet_partial'))
      helper.render_facet_limit(@mock_facet)
    end 

    it "should use a partial layout for rendering the facet frame" do
      @mock_facet = double(:name => 'my_facet_field_with_custom_partial', :items => [1,2,3])
      helper.should_receive(:render).with(hash_including(:layout => 'facet_layout'))
      helper.render_facet_limit(@mock_facet)
    end

    it "should allow the caller to opt-out of facet layouts" do
      @mock_facet = double(:name => 'my_facet_field_with_custom_partial', :items => [1,2,3])
      helper.should_receive(:render).with(hash_including(:layout => nil))
      helper.render_facet_limit(@mock_facet, :layout => nil)
    end

    it "should render the facet_pivot partial for pivot facets" do
      @mock_facet = double(:name => 'pivot_facet_field', :items => [1,2,3])
      helper.should_receive(:render).with(hash_including(:partial => 'facet_pivot'))
      helper.render_facet_limit(@mock_facet)
    end 

    it "should let you override the rendered partial for pivot facets" do
      @mock_facet = double(:name => 'my_pivot_facet_field_with_custom_partial', :items => [1,2,3])
      helper.should_receive(:render).with(hash_including(:partial => 'custom_facet_partial'))
      helper.render_facet_limit(@mock_facet)
    end 
  end

  describe "facet_field_in_params?" do
    it "should check if the facet field is selected in the user params" do
      helper.stub(:params => { :f => { "some-field" => ["x"]}})
      expect(helper.facet_field_in_params?("some-field")).to be_true
      expect(helper.facet_field_in_params?("other-field")).to_not be_true
    end
  end

  describe "facet_in_params?" do

  end

  describe "render_facet_value" do
    let (:item) { double(:value => 'A', :hits => 10) }
    before do
      helper.stub(:facet_configuration_for_field).with('simple_field').and_return(double(:query => nil, :date => nil, :helper_method => nil, :single => false))
      helper.should_receive(:facet_display_value).and_return('Z')
      helper.should_receive(:add_facet_params_and_redirect).and_return({controller:'catalog'})
      
      helper.stub(:search_action_path) do |*args|
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
      helper.stub(:facet_configuration_for_field).with('simple_field').and_return(double(:query => nil, :date => nil, :helper_method => nil))
      expect(helper.facet_display_value('simple_field', 'asdf')).to eq 'asdf'
    end

    it "should allow you to pass in a :helper_method argument to the configuration" do
      helper.stub(:facet_configuration_for_field).with('helper_field').and_return(double(:query => nil, :date => nil, :helper_method => :my_facet_value_renderer))
    
      helper.should_receive(:my_facet_value_renderer).with('qwerty').and_return('abc')

      expect(helper.facet_display_value('helper_field', 'qwerty')).to eq 'abc'
    end

    it "should extract the configuration label for a query facet" do
      helper.stub(:facet_configuration_for_field).with('query_facet').and_return(double(:query => { 'query_key' => { :label => 'XYZ'}}, :date => nil, :helper_method => nil))
      expect(helper.facet_display_value('query_facet', 'query_key')).to eq 'XYZ'
    end

    it "should localize the label for date-type facets" do
      helper.stub(:facet_configuration_for_field).with('date_facet').and_return(double('date' => true, :query => nil, :helper_method => nil))
      expect(helper.facet_display_value('date_facet', '2012-01-01')).to eq 'Sun, 01 Jan 2012 00:00:00 +0000'
    end

    it "should localize the label for date-type facets with the supplied localization options" do
      helper.stub(:facet_configuration_for_field).with('date_facet').and_return(double('date' => { :format => :short }, :query => nil, :helper_method => nil))
      expect(helper.facet_display_value('date_facet', '2012-01-01')).to eq '01 Jan 00:00'
    end
  end

  describe "#facet_field_id" do
    it "should be the parameterized version of the facet field" do
      expect(helper.facet_field_id double(field: 'some field')).to eq "facet-some-field"
    end
  end
end
