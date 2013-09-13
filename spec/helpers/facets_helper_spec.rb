require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
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
      helper.has_facet_values?(fields).should be_true
    end

    it "should be false if all facets are empty" do

      empty = double(:items => [])

      fields = [empty]
      helper.has_facet_values?(fields).should_not be_true
    end
  end

  describe "should_render_facet?" do
    before do
      @config = Blacklight::Configuration.new do |config|
        config.add_facet_field 'basic_field'
        config.add_facet_field 'no_show', :show=>false
      end

      helper.stub(:blacklight_config => @config)
    end
    it "should render facets with items" do
      a = double(:items => [1,2], :name=>'basic_field')
      helper.should_render_facet?(a).should == true
    end
    it "should not render facets without items" do
      empty = double(:items => [], :name=>'basic_field')
      helper.should_render_facet?(empty).should ==  false
    end

    it "should not render facets where show is set to false" do
      a = double(:items => [1,2], :name=>'no_show')
      helper.should_render_facet?(a).should ==  false
    end
  end

  describe "facet_by_field_name" do
    it "should retrieve the facet from the response given a string" do
      facet_config = double(:query => nil)
      facet_field = double()
      helper.should_receive(:facet_configuration_for_field).with(anything()).and_return(facet_config)

      @response = double()
      @response.should_receive(:facet_by_field_name).with('a').and_return(facet_field)

      helper.facet_by_field_name('a').should == facet_field
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

        field.name.should == 'my_query_facet_field'
        field.items.length.should == 2
        field.items.map { |x| x.value }.should_not include 'field:not_appearing_in_the_config'

        facet_item = field.items.select { |x| x.value == 'a_simple_query' }.first

        facet_item.value.should == 'a_simple_query'
        facet_item.hits.should == 10
        facet_item.label.should == 'A Human Readable label'
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

        field.name.should == 'my_pivot_facet_field'

        field.items.length.should == 1

        field.items.first.should respond_to(:items)

        field.items.first.items.length.should == 1
        field.items.first.items.first.fq.should == { 'field_a' => 'a' }
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
                                                            :solr_fname => 'basic_field',
                                                            :facet_field => helper.blacklight_config.facet_fields['basic_field'],
                                                            :display_facet => @mock_facet  }
                                                        ))
      helper.render_facet_limit(@mock_facet)
    end

    it "should send a deprecation warning if the method is called using the old-style signature" do
      helper.should_receive(:render_facet_partials).with(['asdf'])
      $stderr.should_receive(:puts)
      helper.render_facet_limit('asdf')
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

  describe "add_facet_params" do
    before do
      @params_no_existing_facet = {:q => "query", :search_field => "search_field", :per_page => "50"}
      @params_existing_facets = {:q => "query", :search_field => "search_field", :per_page => "50", :f => {"facet_field_1" => ["value1"], "facet_field_2" => ["value2", "value2a"]}}
    end

    it "should add facet value for no pre-existing facets" do
      helper.stub(:params).and_return(@params_no_existing_facet)

      result_params = helper.add_facet_params("facet_field", "facet_value")
      result_params[:f].should be_a_kind_of(Hash)
      result_params[:f]["facet_field"].should be_a_kind_of(Array)
      result_params[:f]["facet_field"].should == ["facet_value"]
    end

    it "should add a facet param to existing facet constraints" do
      helper.stub(:params).and_return(@params_existing_facets)
      
      result_params = helper.add_facet_params("facet_field_2", "new_facet_value")

      result_params[:f].should be_a_kind_of(Hash)

      @params_existing_facets[:f].each_pair do |facet_field, value_list|
        result_params[:f][facet_field].should be_a_kind_of(Array)
        
        if facet_field == 'facet_field_2'
          result_params[:f][facet_field].should == (@params_existing_facets[:f][facet_field] | ["new_facet_value"])
        else
          result_params[:f][facet_field].should ==  @params_existing_facets[:f][facet_field]
        end        
      end
    end
    it "should leave non-facet params alone" do
      [@params_existing_facets, @params_no_existing_facet].each do |params|
        helper.stub(:params).and_return(params)

        result_params = helper.add_facet_params("facet_field_2", "new_facet_value")

        params.each_pair do |key, value|
          next if key == :f
          result_params[key].should == params[key]
        end        
      end
    end    

    it "should replace facets for facets configured as single" do
      helper.should_receive(:facet_configuration_for_field).with('single_value_facet_field').and_return(double(:single => true))
      params = { :f => { 'single_value_facet_field' => 'other_value'}}
      helper.stub(:params).and_return params

      result_params = helper.add_facet_params('single_value_facet_field', 'my_value')


      result_params[:f]['single_value_facet_field'].length.should == 1
      result_params[:f]['single_value_facet_field'].first.should == 'my_value'
    end

    it "should accept a FacetItem instead of a plain facet value" do
          
      result_params = helper.add_facet_params('facet_field_1', double(:value => 123))

      result_params[:f]['facet_field_1'].should include(123)
    end

    it "should defer to the field set on a FacetItem" do
          
      result_params = helper.add_facet_params('facet_field_1', double(:field => 'facet_field_2', :value => 123))

      result_params[:f]['facet_field_1'].should be_blank
      result_params[:f]['facet_field_2'].should include(123)
    end

    it "should add any extra fq parameters from the FacetItem" do
          
      result_params = helper.add_facet_params('facet_field_1', double(:value => 123, :fq => {'facet_field_2' => 'abc'}))

      result_params[:f]['facet_field_1'].should include(123)
      result_params[:f]['facet_field_2'].should include('abc')
    end
  end

  describe "add_facet_params_and_redirect" do
    before do
      catalog_facet_params = {:q => "query", 
                :search_field => "search_field", 
                :per_page => "50",
                :page => "5",
                :f => {"facet_field_1" => ["value1"], "facet_field_2" => ["value2", "value2a"]},
                Blacklight::Solr::FacetPaginator.request_keys[:offset] => "100",
                Blacklight::Solr::FacetPaginator.request_keys[:sort] => "index",
                :id => 'facet_field_name'
      }
      helper.stub(:params).and_return(catalog_facet_params)
    end
    it "should redirect to 'index' action" do
      params = helper.add_facet_params_and_redirect("facet_field_2", "facet_value")

      params[:action].should == "index"
    end
    it "should not include request parameters used by the facet paginator" do
      params = helper.add_facet_params_and_redirect("facet_field_2", "facet_value")

      bad_keys = Blacklight::Solr::FacetPaginator.request_keys.values + [:id]
      bad_keys.each do |paginator_key|
        params.keys.should_not include(paginator_key)        
      end
    end
    it 'should remove :page request key' do
      params = helper.add_facet_params_and_redirect("facet_field_2", "facet_value")

      params.keys.should_not include(:page)
    end
    it "should otherwise do the same thing as add_facet_params" do
      added_facet_params = helper.add_facet_params("facet_field_2", "facet_value")
      added_facet_params_from_facet_action = helper.add_facet_params_and_redirect("facet_field_2", "facet_value")

      added_facet_params_from_facet_action.each_pair do |key, value|
        next if key == :action
        value.should == added_facet_params[key]
      end      
    end
  end

  describe "remove_facet_params" do

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
    it "should use facet_display_value" do
      helper.stub(:facet_configuration_for_field).with('simple_field').and_return(double(:query => nil, :date => nil, :helper_method => nil, :single => false))
 
      helper.should_receive(:facet_display_value).and_return('Z')
      helper.should_receive(:add_facet_params_and_redirect).and_return('link')
      helper.render_facet_value('simple_field', double(:value => 'A', :hits => 10)).should == (helper.link_to("Z", "link", :class => "facet_select") + " " + (helper.content_tag :span, 10, :class => 'count')).html_safe
    end


    it "should suppress the link" do
      helper.stub(:facet_configuration_for_field).with('simple_field').and_return(double(:query => nil, :date => nil, :helper_method => nil, :single => false))
 
      helper.should_receive(:facet_display_value).and_return('Z')
      helper.should_receive(:add_facet_params_and_redirect).and_return('link')
      helper.render_facet_value('simple_field', double(:value => 'A', :hits => 10), :suppress_link => true).should == "Z <span class=\"count\">10</span>"
    end
  end
 
  describe "#facet_display_value" do
    it "should just be the facet value for an ordinary facet" do
      helper.stub(:facet_configuration_for_field).with('simple_field').and_return(double(:query => nil, :date => nil, :helper_method => nil))
      helper.facet_display_value('simple_field', 'asdf').should == 'asdf'
    end

    it "should allow you to pass in a :helper_method argument to the configuration" do
      helper.stub(:facet_configuration_for_field).with('helper_field').and_return(double(:query => nil, :date => nil, :helper_method => :my_facet_value_renderer))
    
      helper.should_receive(:my_facet_value_renderer).with('qwerty').and_return('abc')

      helper.facet_display_value('helper_field', 'qwerty').should == 'abc'
    end

    it "should extract the configuration label for a query facet" do
      helper.stub(:facet_configuration_for_field).with('query_facet').and_return(double(:query => { 'query_key' => { :label => 'XYZ'}}, :date => nil, :helper_method => nil))
      helper.facet_display_value('query_facet', 'query_key').should == 'XYZ'
    end

    it "should localize the label for date-type facets" do
      helper.stub(:facet_configuration_for_field).with('date_facet').and_return(double('date' => true, :query => nil, :helper_method => nil))
      helper.facet_display_value('date_facet', '2012-01-01').should == 'Sun, 01 Jan 2012 00:00:00 +0000'
    end

    it "should localize the label for date-type facets with the supplied localization options" do
      helper.stub(:facet_configuration_for_field).with('date_facet').and_return(double('date' => { :format => :short }, :query => nil, :helper_method => nil))
      helper.facet_display_value('date_facet', '2012-01-01').should == '01 Jan 00:00'
    end
  end
end
