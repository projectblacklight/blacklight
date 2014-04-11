require 'spec_helper'

describe BlacklightUrlHelper do

  let(:blacklight_config) do
    @config ||= Blacklight::Configuration.new.configure do |config|
      config.index.title_field = 'title_display'
      config.index.display_type_field = 'format'
    end
  end

  before(:each) do
    helper.stub(:search_action_path) do |*args|
      catalog_index_url *args
    end

    helper.stub(blacklight_config: blacklight_config)
    helper.stub(current_search_session: nil)
    helper.stub(:search_session).and_return({})
  end

  describe "url_for_document" do
    let(:controller_class) { ::CatalogController.new }

    before do
      helper.stub(controller: controller_class)
      helper.stub(controller_name: controller_class.controller_name)
    end

    it "should be a polymorphic routing-ready object" do
      doc = SolrDocument.new
      expect(helper.url_for_document(doc)).to eq doc
    end

    it "should allow for custom show routes" do
      doc = SolrDocument.new
      helper.blacklight_config.show.route = { controller: 'catalog' }
      expect(helper.url_for_document(doc)).to eq({controller: 'catalog', action: :show, id: doc})
    end

    context "within bookmarks" do
      let(:controller_class) { ::BookmarksController.new }

      it "should use polymorphic routing" do
        doc = SolrDocument.new
        expect(helper.url_for_document(doc)).to eq doc
      end
    end

    context "within an alternative catalog controller" do
      let(:controller_class) { ::AlternateController.new }
      before do
        helper.blacklight_config.show.route = { controller: :current }
      end
      it "should support the :current controller configuration" do
        doc = SolrDocument.new
        expect(helper.url_for_document(doc)).to eq({controller: 'alternate', action: :show, id: doc})
      end
    end

    it "should be a polymorphic route if the solr document responds to #to_model with a non-SolrDocument" do
      some_model = double
      doc = SolrDocument.new
      doc.stub(to_model: some_model)
      expect(helper.url_for_document(doc)).to eq doc
    end
  end

  describe "link_back_to_catalog" do
    let(:query_params)  {{:q => "query", :f => "facets", :controller=>'catalog'}}
    let(:bookmarks_query_params) {{ :controller=>'bookmarks'}}

    it "should build a link tag to catalog using session[:search] for query params" do
      helper.stub(:current_search_session).and_return double(:query_params => query_params)
      tag = helper.link_back_to_catalog
      expect(tag).to match /q=query/
      expect(tag).to match /f=facets/
      expect(tag).to_not match /page=/
      expect(tag).to_not match /per_page=/
    end

    it "should build a link tag to bookmarks using session[:search] for query params" do
      helper.stub(:current_search_session).and_return double(:query_params => bookmarks_query_params)
      tag = helper.link_back_to_catalog
      expect(tag).to match /Back to Bookmarks/
      expect(tag).to match /\/bookmarks/
    end

    context "with a search context" do

      it "should use the current search session counter and per page information to construct the appropriate pagination context" do
        helper.stub(current_search_session: double(query_params: query_params))
        helper.stub(search_session: { 'per_page' => 15, 'counter' => 31 })
        tag = helper.link_back_to_catalog
        expect(tag).to match /page=3/
        expect(tag).to match /per_page=15/
      end
      
      it "should omit per_page if the value is the same as the default" do
        helper.stub(current_search_session: double(query_params: query_params))
        helper.stub(search_session: { 'per_page' => 10, 'counter' => 31 })
        tag = helper.link_back_to_catalog
        expect(tag).to match /page=4/
        expect(tag).to_not match /per_page=/
      end
    end

    describe "when an alternate scope is passed in" do
      let(:my_engine) { double("Engine") }

      it "should call url_for on the engine scope" do
        helper.stub(:current_search_session).and_return double(:query_params => query_params)
        expect(my_engine).to receive(:url_for).and_return(url_for(query_params))
        tag = helper.link_back_to_catalog(route_set: my_engine)
        expect(tag).to match /Back to Search/
        expect(tag).to match /q=query/
        expect(tag).to match /f=facets/
      end
    end
  end

  describe "link_to_query" do
    it "should build a link tag to catalog using query string (no other params)" do
      query = "brilliant"
      helper.stub(params: {})
      tag = helper.link_to_query(query)
      expect(tag).to match /q=#{query}/
      expect(tag).to match />#{query}<\/a>/
    end
    it "should build a link tag to catalog using query string and other existing params" do
      query = "wonderful"
      helper.stub(params: {:qt => "title_search", :per_page => "50"})
      tag = helper.link_to_query(query)
      expect(tag).to match /qt=title_search/
      expect(tag).to match /per_page=50/
    end
    it "should ignore existing :page param" do
      query = "yes"
      helper.stub(params: {:page => "2", :qt => "author_search"})
      tag = helper.link_to_query(query)
      expect(tag).to match /qt=author_search/
      expect(tag).to_not match /page/
    end
    it "should be html_safe" do
      query = "brilliant"
      helper.stub(params: {:page => "2", :qt => "author_search"})
      tag = helper.link_to_query(query)
      expect(tag).to be_html_safe
    end
  end

  describe "sanitize_search_params" do
    it "should strip nil values" do
      result = helper.sanitize_search_params(:a => nil, :b => 1)
      expect(result).to_not have_key(:a)
      expect(result[:b]).to eq 1
    end

    it "should remove blacklisted keys" do
      result = helper.sanitize_search_params(:action => true, :controller => true, :id => true, :commit => true, :utf8 => true)
      expect(result).to be_empty
    end
  end

  describe "params_for_search" do
    before do
      helper.stub(params: { 'default' => 'params'})
    end

    it "should default to using the controller's params" do
      result = helper.params_for_search
      expect(result).to eq({ 'default' => 'params' })
      expect(params.object_id).to_not eq result.object_id
    end

    it "should let you pass in params to merge into the controller's params" do
      source_params = { :q => 'query'}
      result = helper.params_for_search( source_params )
      expect(result).to include(:q => 'query', 'default' => 'params')
    end

    it "should not return blacklisted elements" do
      source_params = { :action => 'action', :controller => 'controller', :id => "id", :commit => 'commit'}
      result = helper.params_for_search(source_params)
      expect(result.keys).to_not include(:action, :controller, :commit, :id)
    end

    it "should adjust the current page if the per_page changes" do
      source_params = { :per_page => 20, :page => 5}
      result = helper.params_for_search(source_params, :per_page => 100)
      expect(result[:page]).to eq 1
    end

    it "should not adjust the current page if the per_page is the same as it always was" do
      source_params = { :per_page => 20, :page => 5}
      result = helper.params_for_search(source_params, :per_page => 20)
      expect(result[:page]).to eq 5
    end

    it "should adjust the current page if the sort changes" do
      source_params = { :sort => 'field_a', :page => 5}
      result = helper.params_for_search(source_params, :sort => 'field_b')
      expect(result[:page]).to eq 1
    end

    it "should not adjust the current page if the sort is the same as it always was" do
      source_params = { :sort => 'field_a', :page => 5}
      result = helper.params_for_search(source_params, :sort => 'field_a')
      expect(result[:page]).to eq 5
    end

    describe "params_for_search with a block" do
      it "should evalute the block and allow it to add or remove keys" do
        result = helper.params_for_search({:a => 1, :b => 2}, :c => 3) do |params|
          params.except! :a, :b 
          params[:d] = 'd'
        end

        result.keys.should_not include(:a, :b)
        expect(result[:c]).to eq 3
        expect(result[:d]).to eq 'd'
      end

    end

  end


  describe "start_over_path" do
    it 'should be the catalog path with the current view type' do
      blacklight_config.stub(:view) { { list: nil, abc: nil} }
      helper.stub(:blacklight_config => blacklight_config)
      expect(helper.start_over_path(:view => 'abc')).to eq catalog_index_url(:view => 'abc')
    end

    it 'should not include the current view type if it is the default' do
      blacklight_config.stub(:view) { { list: nil, asdf: nil} }
      helper.stub(:blacklight_config => blacklight_config)
      expect(helper.start_over_path(:view => 'list')).to eq catalog_index_url
    end
  end

  describe "link_to_document" do
    it "should consist of the document title wrapped in a <a>" do
      data = {'id'=>'123456','title_display'=>['654321'] }
      @document = SolrDocument.new(data)
      expect(helper.link_to_document(@document, { :label => :title_display })).to have_selector("a", :text => '654321', :count => 1)
    end

    it "should accept and return a string label" do
      data = {'id'=>'123456','title_display'=>['654321'] }
      @document = SolrDocument.new(data)
      expect(helper.link_to_document(@document, { :label => "title_display" })).to have_selector("a", :text => 'title_display', :count => 1)
    end

    it "should accept and return a Proc" do
      data = {'id'=>'123456','title_display'=>['654321'] }
      @document = SolrDocument.new(data)
      expect(helper.link_to_document(@document, { :label => Proc.new { |doc, opts| doc.get(:id) + ": " + doc.get(:title_display) } })).to have_selector("a", :text => '123456: 654321', :count => 1)
    end

    it "should return id when label is missing" do
      data = {'id'=>'123456'}
      @document = SolrDocument.new(data)
      expect(helper.link_to_document(@document, { :label => :title_display })).to have_selector("a", :text => '123456', :count => 1)
    end

    it "should be html safe" do
      data = {'id'=>'123456'}
      @document = SolrDocument.new(data)
      expect(helper.link_to_document(@document, { :label => :title_display })).to be_html_safe
    end

    it "should convert the counter parameter into a data- attribute" do
      data = {'id'=>'123456','title_display'=>['654321']}
      @document = SolrDocument.new(data)
      expect(helper.link_to_document(@document, { :label => :title_display, :counter => 5  })).to match /\/catalog\/123456\/track\?counter=5/
    end

    it "should merge the data- attributes from the options with the counter params" do
      data = {'id'=>'123456','title_display'=>['654321']}
      @document = SolrDocument.new(data)
      link = helper.link_to_document @document, { data: { x: 1 }  }
      expect(link).to have_selector '[data-x]'
      expect(link).to have_selector '[data-context-href]'
    end

    it "passes on the title attribute to the link_to_with_data method" do
      @document = SolrDocument.new('id'=>'123456')
      expect(helper.link_to_document(@document,:label=>"Some crazy long label...",:title=>"Some crazy longer label")).to match(/title=\"Some crazy longer label\"/)
    end

    it "doesn't add an erroneous title attribute if one isn't provided" do
      @document = SolrDocument.new('id'=>'123456')
      expect(helper.link_to_document(@document,:label=>"Some crazy long label...")).to_not match(/title=/)
    end

    it "should  work with integer ids" do
      data = {'id'=> 123456 }
      @document = SolrDocument.new(data)
      expect(helper.link_to_document(@document)).to have_selector("a")
    end

  end

  describe "link_to_previous_search" do
    it "should link to the given search parameters" do
      params = {}
      helper.should_receive(:render_search_to_s).with(params).and_return "link text"
      expect(helper.link_to_previous_search({})).to eq helper.link_to("link text", helper.search_action_path)
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
      expect(result_params[:f]).to be_a_kind_of(Hash)
      expect(result_params[:f]["facet_field"]).to be_a_kind_of(Array)
      expect(result_params[:f]["facet_field"]).to eq ["facet_value"]
    end

    it "should add a facet param to existing facet constraints" do
      helper.stub(:params).and_return(@params_existing_facets)
      
      result_params = helper.add_facet_params("facet_field_2", "new_facet_value")

      expect(result_params[:f]).to be_a_kind_of(Hash)

      @params_existing_facets[:f].each_pair do |facet_field, value_list|
        expect(result_params[:f][facet_field]).to be_a_kind_of(Array)
        
        if facet_field == 'facet_field_2'
          expect(result_params[:f][facet_field]).to eq (@params_existing_facets[:f][facet_field] | ["new_facet_value"])
        else
          expect(result_params[:f][facet_field]).to eq @params_existing_facets[:f][facet_field]
        end        
      end
    end
    it "should leave non-facet params alone" do
      [@params_existing_facets, @params_no_existing_facet].each do |params|
        helper.stub(:params).and_return(params)

        result_params = helper.add_facet_params("facet_field_2", "new_facet_value")

        params.each_pair do |key, value|
          next if key == :f
          expect(result_params[key]).to eq params[key]
        end        
      end
    end    

    it "should replace facets for facets configured as single" do
      helper.should_receive(:facet_configuration_for_field).with('single_value_facet_field').and_return(double(:single => true))
      params = { :f => { 'single_value_facet_field' => 'other_value'}}
      helper.stub(:params).and_return params

      result_params = helper.add_facet_params('single_value_facet_field', 'my_value')


      expect(result_params[:f]['single_value_facet_field']).to have(1).item
      expect(result_params[:f]['single_value_facet_field'].first).to eq 'my_value'
    end

    it "should accept a FacetItem instead of a plain facet value" do
          
      result_params = helper.add_facet_params('facet_field_1', double(:value => 123))

      expect(result_params[:f]['facet_field_1']).to include(123)
    end

    it "should defer to the field set on a FacetItem" do
          
      result_params = helper.add_facet_params('facet_field_1', double(:field => 'facet_field_2', :value => 123))

      expect(result_params[:f]['facet_field_1']).to be_blank
      expect(result_params[:f]['facet_field_2']).to include(123)
    end

    it "should add any extra fq parameters from the FacetItem" do
          
      result_params = helper.add_facet_params('facet_field_1', double(:value => 123, :fq => {'facet_field_2' => 'abc'}))

      expect(result_params[:f]['facet_field_1']).to include(123)
      expect(result_params[:f]['facet_field_2']).to include('abc')
    end
  end

  describe "add_facet_params_and_redirect" do
    before do
      catalog_facet_params = {:q => "query", 
                :search_field => "search_field", 
                :per_page => "50",
                :page => "5",
                :f => {"facet_field_1" => ["value1"], "facet_field_2" => ["value2", "value2a"]},
                Blacklight::Solr::FacetPaginator.request_keys[:page] => "100",
                Blacklight::Solr::FacetPaginator.request_keys[:sort] => "index",
                :id => 'facet_field_name'
      }
      helper.stub(:params).and_return(catalog_facet_params)
    end
    it "should not include request parameters used by the facet paginator" do
      params = helper.add_facet_params_and_redirect("facet_field_2", "facet_value")

      bad_keys = Blacklight::Solr::FacetPaginator.request_keys.values + [:id]
      bad_keys.each do |paginator_key|
        expect(params.keys).to_not include(paginator_key)        
      end
    end
    it 'should remove :page request key' do
      params = helper.add_facet_params_and_redirect("facet_field_2", "facet_value")
      expect(params.keys).to_not include(:page)
    end
    it "should otherwise do the same thing as add_facet_params" do
      added_facet_params = helper.add_facet_params("facet_field_2", "facet_value")
      added_facet_params_from_facet_action = helper.add_facet_params_and_redirect("facet_field_2", "facet_value")

      expect(added_facet_params_from_facet_action).to eq added_facet_params.except(Blacklight::Solr::FacetPaginator.request_keys[:page], Blacklight::Solr::FacetPaginator.request_keys[:sort])     
    end
  end
  
  describe "#bookmarks_export_url" do
    it "should be the bookmark url with an encrypted user token" do
      helper.stub(encrypt_user_id: 'xyz', current_or_guest_user: double(id: 123))
      url = helper.bookmarks_export_url(:html)
      expect(url).to eq helper.bookmarks_url(format: :html, encrypted_user_id: 'xyz')
    end
  end
end
