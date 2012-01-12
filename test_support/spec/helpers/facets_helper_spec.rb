require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
describe FacetsHelper do

  describe "should_render_facet?" do
    it "should render facets with items" do
      a = mock(:items => [1,2])
      helper.should_render_facet?(a).should == true
    end
    it "should not render facets without items" do
      empty = mock(:items => [])
      helper.should_render_facet?(empty).should ==  false
    end
  end

  describe "facet_by_field_name" do
    it "should retrieve the facet from the response given a string" do
      a = mock(:name => 'a', :items => [1,2])

      @response = mock()
      @response.should_receive(:facet_by_field_name).with('a') { a }

      helper.facet_by_field_name('a').should == a
    end
  end

  describe "render_facet_partials" do
    it "should try to render all provided facets " do
      a = mock(:items => [1,2])
      b = mock(:items => ['b','c'])
      empty = mock(:items => [])

      fields = [a,b,empty]

      helper.should_receive(:render_facet_limit).with(a, {})
      helper.should_receive(:render_facet_limit).with(b, {})
      helper.should_receive(:render_facet_limit).with(empty, {})

      helper.render_facet_partials fields
    end

    it "should default to the configured facets" do
      a = mock(:items => [1,2])
      b = mock(:items => ['b','c'])
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
        config.add_facet_field 'my_facet_field_with_custom_partial', :partial => 'custom_facet_partial'
      end

      helper.stub(:blacklight_config => @config)
      @response = mock()
    end

    it "should set basic local variables" do
      @mock_facet = mock(:name => 'basic_field', :items => [1,2,3])
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
      @mock_facet = mock(:name => 'asdf', :items => [1,2,3])
      helper.should_receive(:render).with(hash_including(:partial => 'facet_limit'))
      helper.render_facet_limit(@mock_facet)
    end

    it "should get the partial name from the configuration" do
      @mock_facet = mock(:name => 'my_facet_field_with_custom_partial', :items => [1,2,3])
      helper.should_receive(:render).with(hash_including(:partial => 'custom_facet_partial'))
      helper.render_facet_limit(@mock_facet)
    end 

    it "should use a partial layout for rendering the facet frame" do
      @mock_facet = mock(:name => 'my_facet_field_with_custom_partial', :items => [1,2,3])
      helper.should_receive(:render).with(hash_including(:layout => 'facet_layout'))
      helper.render_facet_limit(@mock_facet)
    end

    it "should allow the caller to opt-out of facet layouts" do
      @mock_facet = mock(:name => 'my_facet_field_with_custom_partial', :items => [1,2,3])
      helper.should_receive(:render).with(hash_including(:layout => nil))
      helper.render_facet_limit(@mock_facet, :layout => nil)
    end
  end

  describe "add_facet_params" do
    before do
      @params_no_existing_facet = {:q => "query", :search_field => "search_field", :per_page => "50"}
      @params_existing_facets = {:q => "query", :search_field => "search_field", :per_page => "50", :f => {"facet_field_1" => ["value1"], "facet_field_2" => ["value2", "value2a"]}}
    end

    it "should add facet value for no pre-existing facets" do
      helper.stub!(:params).and_return(@params_no_existing_facet)

      result_params = helper.add_facet_params("facet_field", "facet_value")
      result_params[:f].should be_a_kind_of(Hash)
      result_params[:f]["facet_field"].should be_a_kind_of(Array)
      result_params[:f]["facet_field"].should == ["facet_value"]
    end

    it "should add a facet param to existing facet constraints" do
      helper.stub!(:params).and_return(@params_existing_facets)
      
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
        helper.stub!(:params).and_return(params)

        result_params = helper.add_facet_params("facet_field_2", "new_facet_value")

        params.each_pair do |key, value|
          next if key == :f
          result_params[key].should == params[key]
        end        
      end
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
      helper.stub!(:params).and_return(catalog_facet_params)
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

  describe "facet_in_params?" do

  end
  
end
