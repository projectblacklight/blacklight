require 'spec_helper'

def exportable_record
"<record>
  <leader>01828cjm a2200409 a 4500</leader>
  <controlfield tag=\"001\">a4768316</controlfield>
  <controlfield tag=\"003\">SIRSI</controlfield>
  <controlfield tag=\"007\">sd fungnnmmned</controlfield>
  <controlfield tag=\"008\">020117p20011990xxuzz    h              d</controlfield>

  <datafield tag=\"245\" ind1=\"0\" ind2=\"0\">
    <subfield code=\"a\">Music for horn</subfield>
    <subfield code=\"h\">[sound recording] /</subfield>
    <subfield code=\"c\">Brahms, Beethoven, von Krufft.</subfield>
  </datafield>

  <datafield tag=\"260\" ind1=\" \" ind2=\" \">
    <subfield code=\"a\">[United States] :</subfield>
    <subfield code=\"b\">Harmonia Mundi USA,</subfield>
    <subfield code=\"c\">p2001.</subfield>
  </datafield>

  <datafield tag=\"700\" ind1=\"1\" ind2=\" \">
    <subfield code=\"a\">Greer, Lowell.</subfield>
  </datafield>

  <datafield tag=\"700\" ind1=\"1\" ind2=\" \">
    <subfield code=\"a\">Lubin, Steven.</subfield>
  </datafield>

  <datafield tag=\"700\" ind1=\"1\" ind2=\" \">
    <subfield code=\"a\">Chase, Stephanie,</subfield>
    <subfield code=\"d\">1957-</subfield>
  </datafield>

  <datafield tag=\"700\" ind1=\"1\" ind2=\"2\">
    <subfield code=\"a\">Brahms, Johannes,</subfield>
    <subfield code=\"d\">1833-1897.</subfield>
    <subfield code=\"t\">Trios,</subfield>
    <subfield code=\"m\">piano, violin, horn,</subfield>
    <subfield code=\"n\">op. 40,</subfield>
    <subfield code=\"r\">E? major.</subfield>
  </datafield>

  <datafield tag=\"700\" ind1=\"1\" ind2=\"2\">
    <subfield code=\"a\">Beethoven, Ludwig van,</subfield>
    <subfield code=\"d\">1770-1827.</subfield>
    <subfield code=\"t\">Sonatas,</subfield>
    <subfield code=\"m\">horn, piano,</subfield>
    <subfield code=\"n\">op. 17,</subfield>
    <subfield code=\"r\">F major.</subfield>
  </datafield>

  <datafield tag=\"700\" ind1=\"1\" ind2=\"2\">
    <subfield code=\"a\">Krufft, Nikolaus von,</subfield>
    <subfield code=\"d\">1779-1818.</subfield>
    <subfield code=\"t\">Sonata,</subfield>
    <subfield code=\"m\">horn, piano,</subfield>
    <subfield code=\"r\">F major.</subfield>
  </datafield>
</record>"
end

describe BlacklightHelper do
  include ERB::Util
  include BlacklightHelper
  include Devise::TestHelpers
  def blacklight_config
    @config ||= Blacklight::Configuration.new.configure do |config|
      config.index.title_field = 'title_display'
      config.index.display_type_field = 'format'
    end
  end

  before(:each) do
    helper.stub(:search_action_url) do |*args|
      catalog_index_url *args
    end
  end

  def current_search_session

  end

  describe "#application_name", :test => true do
    it "should use the Rails application config application_name if available" do
      Rails.application.config.stub(:application_name => 'asdf')
      Rails.application.config.should_receive(:respond_to?).with(:application_name).and_return(true)
      expect(application_name).to eq 'asdf'
    end
    it "should default to 'Blacklight'" do
      expect(application_name).to eq "Blacklight"
    end
  end

  describe "link_back_to_catalog" do
    let(:query_params)  {{:q => "query", :f => "facets", :per_page => "10", :page => "2", :controller=>'catalog'}}
    let(:bookmarks_query_params) {{ :page => "2", :controller=>'bookmarks'}}

    it "should build a link tag to catalog using session[:search] for query params" do
      helper.stub(:current_search_session).and_return double(:query_params => query_params)
      tag = helper.link_back_to_catalog
      expect(tag).to match /q=query/
      expect(tag).to match /f=facets/
      expect(tag).to match /per_page=10/
      expect(tag).to match /page=2/
    end

    it "should build a link tag to bookmarks using session[:search] for query params" do
      helper.stub(:current_search_session).and_return double(:query_params => bookmarks_query_params)
      tag = helper.link_back_to_catalog
      expect(tag).to match /Back to Bookmarks/
      expect(tag).to match /\/bookmarks/
      expect(tag).to match /page=2/
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
        expect(tag).to match /per_page=10/
        expect(tag).to match /page=2/
      end
    end
  end

  describe "link_to_query" do
    it "should build a link tag to catalog using query string (no other params)" do
      query = "brilliant"
      self.should_receive(:params).and_return({})
      tag = link_to_query(query)
      expect(tag).to match /q=#{query}/
      expect(tag).to match />#{query}<\/a>/
    end
    it "should build a link tag to catalog using query string and other existing params" do
      query = "wonderful"
      self.should_receive(:params).and_return({:qt => "title_search", :per_page => "50"})
      tag = link_to_query(query)
      expect(tag).to match /qt=title_search/
      expect(tag).to match /per_page=50/
    end
    it "should ignore existing :page param" do
      query = "yes"
      self.should_receive(:params).and_return({:page => "2", :qt => "author_search"})
      tag = link_to_query(query)
      expect(tag).to match /qt=author_search/
      expect(tag).to_not match /page/
    end
    it "should be html_safe" do
      query = "brilliant"
      self.should_receive(:params).and_return({:page => "2", :qt => "author_search"})
      tag = link_to_query(query)
      expect(tag).to be_html_safe
    end
  end

  describe "sanitize_search_params" do
    it "should strip nil values" do
      result = sanitize_search_params(:a => nil, :b => 1)
      expect(result).to_not have_key(:a)
      expect(result[:b]).to eq 1
    end

    it "should remove blacklisted keys" do
      result = sanitize_search_params(:action => true, :controller => true, :id => true, :commit => true, :utf8 => true)
      expect(result).to be_empty
    end
  end

  describe "params_for_search" do
    def params
      { 'default' => 'params'}
    end

    it "should default to using the controller's params" do
      result = params_for_search
      expect(result).to eq params
      expect(params.object_id).to_not eq result.object_id
    end

    it "should let you pass in params to merge into the controller's params" do
      source_params = { :q => 'query'}
      result = params_for_search( source_params )
      expect(result).to include(:q => 'query', 'default' => 'params')
    end

    it "should not return blacklisted elements" do
      source_params = { :action => 'action', :controller => 'controller', :id => "id", :commit => 'commit'}
      result = params_for_search(source_params)
      expect(result.keys).to_not include(:action, :controller, :commit, :id)
    end

    it "should adjust the current page if the per_page changes" do
      source_params = { :per_page => 20, :page => 5}
      result = params_for_search(source_params, :per_page => 100)
      expect(result[:page]).to eq 1
    end

    it "should not adjust the current page if the per_page is the same as it always was" do
      source_params = { :per_page => 20, :page => 5}
      result = params_for_search(source_params, :per_page => 20)
      expect(result[:page]).to eq 5
    end

    it "should adjust the current page if the sort changes" do
      source_params = { :sort => 'field_a', :page => 5}
      result = params_for_search(source_params, :sort => 'field_b')
      expect(result[:page]).to eq 1
    end

    it "should not adjust the current page if the sort is the same as it always was" do
      source_params = { :sort => 'field_a', :page => 5}
      result = params_for_search(source_params, :sort => 'field_a')
      expect(result[:page]).to eq 5
    end

    describe "params_for_search with a block" do
      it "should evalute the block and allow it to add or remove keys" do
        result = params_for_search({:a => 1, :b => 2}, :c => 3) do |params|
          params.except! :a, :b 
          params[:d] = 'd'
        end

        result.keys.should_not include(:a, :b)
        expect(result[:c]).to eq 3
        expect(result[:d]).to eq 'd'
      end

    end

  end

   describe "render body class" do
      it "should include a serialization of the current controller name" do
        @controller = double("controller")
        @controller.stub(:controller_name).and_return("123456")
        @controller.stub(:action_name).and_return("abcdef")

	      expect(render_body_class.split(' ')).to include('blacklight-123456')
      end

      it "should include a serialization of the current action name" do
        @controller = double("controller")
        @controller.stub(:controller_name).and_return("123456")
        @controller.stub(:action_name).and_return("abcdef")

	      expect(render_body_class.split(' ')).to include('blacklight-123456-abcdef')
      end
   end

   describe "document_heading" do

     it "should consist of the show heading field when available" do
      @document = SolrDocument.new('title_display' => "A Fake Document")

      expect(document_heading).to eq "A Fake Document"
     end

     it "should fallback on the document id if no title is available" do
       @document = SolrDocument.new(:id => '123456')
       expect(document_heading).to eq '123456'
     end
   end

   describe "render_document_heading" do
     it "should consist of #document_heading wrapped in a <h1>" do
      @document = SolrDocument.new('title_display' => "A Fake Document")

      expect(render_document_heading).to have_selector("h4", :text => "A Fake Document", :count => 1)
      expect(render_document_heading).to be_html_safe
     end

     it "should have a schema.org itemprop for name" do
      @document = SolrDocument.new('title_display' => "A Fake Document")

      expect(render_document_heading).to have_selector("h4[@itemprop='name']", :text => "A Fake Document")
     end

     it "should join the values if it is an array" do
      @document = SolrDocument.new('title_display' => ["A Fake Document", 'Something Else'])

      expect(render_document_heading).to have_selector("h4", :text => "A Fake Document, Something Else", :count => 1)
      expect(render_document_heading).to be_html_safe
     end
   end

   describe "document_show_html_title" do
     it "should join the values if it is an array" do
      @document = SolrDocument.new('title_display' => ["A Fake Document", 'Something Else'])
      expect(document_show_html_title).to eq "A Fake Document, Something Else"
     end
   end

   describe "document_index_view_type" do
     it "should default to 'list'" do
       expect(document_index_view_type).to eq :list
     end

     it "should pluck values out of params" do
       blacklight_config.stub(:view) { { list: nil, asdf: nil} }
       params[:view] = 'asdf'
       expect(document_index_view_type).to eq :asdf

       params[:view] = 'not_in_list'
       expect(document_index_view_type).to eq :list
     end

     it "should pluck values from supplied params" do
       blacklight_config.stub(:view) { { list: nil, asdf: nil} }
       params[:view] = 'asdf'
       expect(document_index_view_type(:view => 'list')).to eq :list
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

   describe "render_document_index" do
     it "should render the document_list" do
       @document_list = ['a', 'b']
       self.should_receive(:render).with(hash_including(:partial => 'document_gallery'))
       render_document_index_with_view 'gallery', @document_list
     end

     it "should fall back on more specific templates" do
       ex = ActionView::MissingTemplate.new [], '', '', '',''
       self.should_receive(:render).with(hash_including(:partial => 'document_gallery')).and_raise(ex)
       self.should_receive(:render).with(hash_including(:partial => 'catalog/document_gallery')).and_raise(ex)
       self.should_receive(:render).with(hash_including(:partial => 'catalog/document_list'))
       render_document_index_with_view 'gallery', @document_list
     end
   end

   describe "document_partial_name" do
     it "should default to 'default' when a format blank" do
       expect(document_partial_name({})).to eq "default"
     end
     it "should handle normal formats correctly" do
       expect(document_partial_name({"format" => "myformat"})).to eq "myformat"
     end
     it "should handle spaces correctly" do
       expect(document_partial_name({"format" => "my format"})).to eq "my_format"
     end
     it "should handle capitalization correctly" do
       expect(document_partial_name({"format" => "MyFormat"})).to eq "myformat"
     end
     it "should handle puncuation correctly" do
       expect(document_partial_name({"format" => "My.Format"})).to eq "my_format"
     end
     it "should handle multi-valued fields correctly" do
       expect(document_partial_name({"format" => ["My Format", "My OtherFormat"]})).to eq "my_format_my_otherformat"
     end
     it "should remove - characters because they will throw errors" do
       expect(document_partial_name({"format" => "My-Format"})).to eq "my_format"
       expect(document_partial_name({"format" => ["My-Format",["My Other-Format"]]})).to eq "my_format_my_other_format"
     end
   end

   describe "link_to_document" do
     it "should consist of the document title wrapped in a <a>" do
      data = {'id'=>'123456','title_display'=>['654321'] }
      @document = SolrDocument.new(data)
      expect(link_to_document(@document, { :label => :title_display })).to have_selector("a", :text => '654321', :count => 1)
     end

     it "should accept and return a string label" do
      data = {'id'=>'123456','title_display'=>['654321'] }
      @document = SolrDocument.new(data)
      expect(link_to_document(@document, { :label => "title_display" })).to have_selector("a", :text => 'title_display', :count => 1)
     end

     it "should accept and return a Proc" do
      data = {'id'=>'123456','title_display'=>['654321'] }
      @document = SolrDocument.new(data)
      expect(link_to_document(@document, { :label => Proc.new { |doc, opts| doc.get(:id) + ": " + doc.get(:title_display) } })).to have_selector("a", :text => '123456: 654321', :count => 1)
     end
     it "should return id when label is missing" do
      data = {'id'=>'123456'}
      @document = SolrDocument.new(data)
      expect(link_to_document(@document, { :label => :title_display })).to have_selector("a", :text => '123456', :count => 1)
     end

     it "should be html safe" do
      data = {'id'=>'123456'}
      @document = SolrDocument.new(data)
      expect(link_to_document(@document, { :label => :title_display })).to be_html_safe
     end

     it "should convert the counter parameter into a data- attribute" do
      data = {'id'=>'123456','title_display'=>['654321']}
      @document = SolrDocument.new(data)
      expect(link_to_document(@document, { :label => :title_display, :counter => 5  })).to match /data-counter="5"/
     end

     it "passes on the title attribute to the link_to_with_data method" do
       @document = SolrDocument.new('id'=>'123456')
       expect(link_to_document(@document,:label=>"Some crazy long label...",:title=>"Some crazy longer label")).to match(/title=\"Some crazy longer label\"/)
     end

     it "doesn't add an erroneous title attribute if one isn't provided" do
       @document = SolrDocument.new('id'=>'123456')
       expect(link_to_document(@document,:label=>"Some crazy long label...")).to_not match(/title=/)
     end
   end


  describe "render_link_rel_alternates" do
      class MockDocumentAppHelper
        include Blacklight::Solr::Document
      end
      module MockExtension
         def self.extended(document)
           document.will_export_as(:weird, "application/weird")
           document.will_export_as(:weirder, "application/weirder")
           document.will_export_as(:weird_dup, "application/weird")
         end
         def export_as_weird ; "weird" ; end
         def export_as_weirder ; "weirder" ; end
         def export_as_weird_dup ; "weird_dup" ; end
      end
      MockDocumentAppHelper.use_extension(MockExtension)
      def mock_document_app_helper_url *args
        solr_document_url(*args)
      end
    before(:each) do
      @doc_id = "MOCK_ID1"
      @document = MockDocumentAppHelper.new(:id => @doc_id)
      render_params = {:controller => "controller", :action => "action"}
      helper.stub(:params).and_return(render_params)
    end
    it "generates <link rel=alternate> tags" do

      response = render_link_rel_alternates(@document)

      tmp_value = Capybara.ignore_hidden_elements
      Capybara.ignore_hidden_elements = false
      @document.export_formats.each_pair do |format, spec|
        response.should have_selector("link[href$='.#{ format  }']") do |matches|
          expect(matches).to have(1).match
          tag = matches[0]
          expect(tag.attributes["rel"].value).to eq "alternate"
          expect(tag.attributes["title"].value).to eq format.to_s
          expect(tag.attributes["href"].value).to eq mock_document_app_helper_url(@document, :format =>format)
        end
      end
      Capybara.ignore_hidden_elements = tmp_value
    end
    it "respects :unique=>true" do
      response = render_link_rel_alternates(@document, :unique => true)
      tmp_value = Capybara.ignore_hidden_elements
      Capybara.ignore_hidden_elements = false
      expect(response).to have_selector("link[type='application/weird']", :count => 1)
      Capybara.ignore_hidden_elements = tmp_value
    end
    it "excludes formats from :exclude" do
      response = render_link_rel_alternates(@document, :exclude => [:weird_dup])

      tmp_value = Capybara.ignore_hidden_elements
      Capybara.ignore_hidden_elements = false
      expect(response).to_not have_selector("link[href$='.weird_dup']")
      Capybara.ignore_hidden_elements = tmp_value
    end

    it "should be html safe" do
      response = render_link_rel_alternates(@document)
      expect(response).to be_html_safe
    end
  end

  describe "with a config" do
    before do
      @config = Blacklight::Configuration.new.configure do |config|
        config.index.title_field = 'title_display'
        config.index.display_type_field = 'format'
      end

      @document = SolrDocument.new('title_display' => "A Fake Document", 'id'=>'8')
      helper.stub(:blacklight_config).and_return(@config)
      helper.stub(:has_user_authentication_provider?).and_return(true)
      helper.stub(:current_or_guest_user).and_return(User.new)
    end
    describe "render_index_doc_actions" do
      it "should render partials" do
        response = helper.render_index_doc_actions(@document)
        expect(response).to have_selector(".bookmark_toggle")
      end
    end
    describe "render_show_doc_actions" do
      it "should render partials" do
        response = helper.render_show_doc_actions(@document)
        expect(response).to have_selector(".bookmark_toggle")
      end
    end
  end

  describe "render_index_field_value" do
    before do
      @config = Blacklight::Configuration.new.configure do |config|
        config.add_index_field 'qwer'
        config.add_index_field 'asdf', :helper_method => :render_asdf_index_field
        config.add_index_field 'link_to_search_true', :link_to_search => true
        config.add_index_field 'link_to_search_named', :link_to_search => :some_field
        config.add_index_field 'highlight', :highlight => true
        config.add_index_field 'solr_doc_accessor', :accessor => true
        config.add_index_field 'explicit_accessor', :accessor => :solr_doc_accessor
        config.add_index_field 'explicit_accessor_with_arg', :accessor => :solr_doc_accessor_with_arg
      end
      helper.stub(:blacklight_config).and_return(@config)
    end

    it "should check for an explicit value" do
      doc = double()
      doc.should_not_receive(:get).with('asdf', :sep => nil)
      value = helper.render_index_field_value :value => 'asdf', :document => doc, :field => 'asdf'
      expect(value).to eq 'asdf'
    end

    it "should check for a helper method to call" do
      doc = double()
      doc.should_receive(:get).with('asdf', :sep => nil)
      helper.stub(:render_asdf_index_field).and_return('custom asdf value')
      value = helper.render_index_field_value :document => doc, :field => 'asdf'
      expect(value).to eq 'custom asdf value'
    end

    it "should check for a link_to_search" do
      doc = double()
      doc.should_receive(:get).with('link_to_search_true', :sep => nil).and_return('x')
      value = helper.render_index_field_value :document => doc, :field => 'link_to_search_true'
      expect(value).to eq helper.link_to("x", helper.search_action_url(:f => { :link_to_search_true => ['x'] }))
    end

    it "should check for a link_to_search with a field name" do
      doc = double()
      doc.should_receive(:get).with('link_to_search_named', :sep => nil).and_return('x')
      value = helper.render_index_field_value :document => doc, :field => 'link_to_search_named'
      expect(value).to eq helper.link_to("x", helper.search_action_url(:f => { :some_field => ['x'] }))
    end

    it "should gracefully handle when no highlight field is available" do
      doc = double()
      doc.should_not_receive(:get)
      doc.should_receive(:has_highlight_field?).and_return(false)
      value = helper.render_index_field_value :document => doc, :field => 'highlight'
      expect(value).to be_blank
    end

    it "should check for a highlighted field" do
      doc = double()
      doc.should_not_receive(:get)
      doc.should_receive(:has_highlight_field?).and_return(true)
      doc.should_receive(:highlight_field).with('highlight').and_return(['<em>highlight</em>'.html_safe])
      value = helper.render_index_field_value :document => doc, :field => 'highlight'
      expect(value).to eq '<em>highlight</em>'
    end

    it "should check the document field value" do
      doc = double()
      doc.should_receive(:get).with('qwer', :sep => nil).and_return('document qwer value')
      value = helper.render_index_field_value :document => doc, :field => 'qwer'
      expect(value).to eq 'document qwer value'
    end

    it "should work with index fields that aren't explicitly defined" do
      doc = double()
      doc.should_receive(:get).with('mnbv', :sep => nil).and_return('document mnbv value')
      value = helper.render_index_field_value :document => doc, :field => 'mnbv'
      expect(value).to eq 'document mnbv value'
    end

    it "should call an accessor on the solr document" do
      doc = double(:solr_doc_accessor => "123")
      value = helper.render_index_field_value :document => doc, :field => 'solr_doc_accessor'
      expect(value).to eq "123"
    end

    it "should call an explicit accessor on the solr document" do
      doc = double(:solr_doc_accessor => "123")
      value = helper.render_index_field_value :document => doc, :field => 'explicit_accessor'
      expect(value).to eq "123"
    end

    it "should call an implicit accessor on the solr document" do
      doc = double()
      expect(doc).to receive(:solr_doc_accessor_with_arg).with('explicit_accessor_with_arg').and_return("123")
      value = helper.render_index_field_value :document => doc, :field => 'explicit_accessor_with_arg'
      expect(value).to eq "123"
    end
  end


  describe "render_document_show_field_value" do
    before do
      @config = Blacklight::Configuration.new.configure do |config|
        config.add_show_field 'qwer'
        config.add_show_field 'asdf', :helper_method => :render_asdf_document_show_field
        config.add_show_field 'link_to_search_true', :link_to_search => true
        config.add_show_field 'link_to_search_named', :link_to_search => :some_field
        config.add_show_field 'highlight', :highlight => true
        config.add_show_field 'solr_doc_accessor', :accessor => true
        config.add_show_field 'explicit_accessor', :accessor => :solr_doc_accessor
        config.add_show_field 'explicit_array_accessor', :accessor => [:solr_doc_accessor, :some_method]
        config.add_show_field 'explicit_accessor_with_arg', :accessor => :solr_doc_accessor_with_arg
      end

      helper.stub(:blacklight_config).and_return(@config)
    end

    it "should check for an explicit value" do
      doc = double()
      doc.should_not_receive(:get).with('asdf', :sep => nil)
      helper.should_not_receive(:render_asdf_document_show_field)
      value = helper.render_document_show_field_value :value => 'asdf', :document => doc, :field => 'asdf'
      expect(value).to eq 'asdf'
    end

    it "should check for a helper method to call" do
      doc = double()
      doc.should_receive(:get).with('asdf', :sep => nil)
      helper.stub(:render_asdf_document_show_field).and_return('custom asdf value')
      value = helper.render_document_show_field_value :document => doc, :field => 'asdf'
      expect(value).to eq 'custom asdf value'
    end

    it "should check for a link_to_search" do
      doc = double()
      doc.should_receive(:get).with('link_to_search_true', :sep => nil).and_return('x')
      value = helper.render_document_show_field_value :document => doc, :field => 'link_to_search_true'
      expect(value).to eq helper.link_to("x", helper.search_action_url(:f => { :link_to_search_true => ['x'] }))
    end

    it "should check for a link_to_search with a field name" do
      doc = double()
      doc.should_receive(:get).with('link_to_search_named', :sep => nil).and_return('x')
      value = helper.render_document_show_field_value :document => doc, :field => 'link_to_search_named'
      expect(value).to eq helper.link_to("x", helper.search_action_url(:f => { :some_field => ['x'] }))
    end

    it "should gracefully handle when no highlight field is available" do
      doc = double()
      doc.should_not_receive(:get)
      doc.should_receive(:has_highlight_field?).and_return(false)
      value = helper.render_document_show_field_value :document => doc, :field => 'highlight'
      expect(value).to be_blank
    end

    it "should check for a highlighted field" do
      doc = double()
      doc.should_not_receive(:get)
      doc.should_receive(:has_highlight_field?).and_return(true)
      doc.should_receive(:highlight_field).with('highlight').and_return(['<em>highlight</em>'.html_safe])
      value = helper.render_document_show_field_value :document => doc, :field => 'highlight'
      expect(value).to eq '<em>highlight</em>'
    end


    it "should check the document field value" do
      doc = double()
      doc.should_receive(:get).with('qwer', :sep => nil).and_return('document qwer value')
      value = helper.render_document_show_field_value :document => doc, :field => 'qwer'
      expect(value).to eq 'document qwer value'
    end

    it "should work with show fields that aren't explicitly defined" do
      doc = double()
      doc.should_receive(:get).with('mnbv', :sep => nil).and_return('document mnbv value')
      value = helper.render_document_show_field_value :document => doc, :field => 'mnbv'
      expect(value).to eq 'document mnbv value'
    end

    it "should call an accessor on the solr document" do
      doc = double(:solr_doc_accessor => "123")
      value = helper.render_document_show_field_value :document => doc, :field => 'solr_doc_accessor'
      expect(value).to eq "123"
    end

    it "should call an explicit accessor on the solr document" do
      doc = double(:solr_doc_accessor => "123")
      value = helper.render_document_show_field_value :document => doc, :field => 'explicit_accessor'
      expect(value).to eq "123"
    end

    it "should call an explicit array-style accessor on the solr document" do
      doc = double(:solr_doc_accessor => double(:some_method => "123"))
      value = helper.render_document_show_field_value :document => doc, :field => 'explicit_array_accessor'
      expect(value).to eq "123"
    end

    it "should call an accessor on the solr document with the field as an argument" do
      doc = double()
      expect(doc).to receive(:solr_doc_accessor_with_arg).with('explicit_accessor_with_arg').and_return("123")
      value = helper.render_document_show_field_value :document => doc, :field => 'explicit_accessor_with_arg'
      expect(value).to eq "123"
    end
  end

  describe "#should_render_index_field?" do
    it "should if the document has the field value" do
      doc = double()
      doc.stub(:has?).with('asdf').and_return(true)
      field_config = double(:field => 'asdf')
      helper.should_render_index_field?(doc, field_config).should == true
    end

    it "should if the document has a highlight field value" do
      doc = double()
      doc.stub(:has?).with('asdf').and_return(false)
      doc.stub(:has_highlight_field?).with('asdf').and_return(true)
      field_config = double(:field => 'asdf', :highlight => true)
      helper.should_render_index_field?(doc, field_config).should == true
    end

    it "should if the field has a model accessor" do
      doc = double()
      doc.stub(:has?).with('asdf').and_return(false)
      doc.stub(:has_highlight_field?).with('asdf').and_return(false)
      field_config = double(:field => 'asdf', :highlight => true, :accessor => true)
      helper.should_render_index_field?(doc, field_config).should == true
    end
  end


  describe "#should_render_show_field?" do
    it "should if the document has the field value" do
      doc = double()
      doc.stub(:has?).with('asdf').and_return(true)
      field_config = double(:field => 'asdf')
      expect(helper.should_render_show_field?(doc, field_config)).to be_true
    end

    it "should if the document has a highlight field value" do
      doc = double()
      doc.stub(:has?).with('asdf').and_return(false)
      doc.stub(:has_highlight_field?).with('asdf').and_return(true)
      field_config = double(:field => 'asdf', :highlight => true)
      expect(helper.should_render_show_field?(doc, field_config)).to be_true
    end

    it "should if the field has a model accessor" do
      doc = double()
      doc.stub(:has?).with('asdf').and_return(false)
      doc.stub(:has_highlight_field?).with('asdf').and_return(false)
      field_config = double(:field => 'asdf', :highlight => true, :accessor => true)
      helper.should_render_show_field?(doc, field_config).should == true
    end
  end


  describe "render_grouped_response?" do
    it "should check if the response ivar contains grouped data" do
      assign(:response, double("SolrResponse", :grouped? => true))
      expect(helper.render_grouped_response?).to be_true
    end


    it "should check if the response param contains grouped data" do
      response = double("SolrResponse", :grouped? => true)
      expect(helper.render_grouped_response?(response)).to be_true
    end
  end

  describe "render_grouped_document_index" do

  end

  describe "render_field_value" do
    it "should join and html-safe values" do
      expect(helper.render_field_value(['a', 'b'])).to eq "a, b"
    end

    it "should join values using the field_value_separator" do
      helper.stub(:field_value_separator).and_return(" -- ")
      expect(helper.render_field_value(['a', 'b'])).to eq "a -- b"
    end

    it "should use the separator from the Blacklight field configuration by default" do
      expect(helper.render_field_value(['c', 'd'], double(:separator => '; ', :itemprop => nil))).to eq "c; d"
    end

    it "should include schema.org itemprop attributes" do
      expect(helper.render_field_value('a', double(:separator => nil, :itemprop => 'some-prop'))).to have_selector("span[@itemprop='some-prop']", :text => "a") 
    end
  end

  describe "link_to_previous_search" do
    it "should link to the given search parameters" do
      params = {}
      helper.should_receive(:render_search_to_s).with(params).and_return "link text"
      expect(helper.link_to_previous_search({})).to eq helper.link_to("link text", catalog_index_path)
    end
  end

  describe "should_show_spellcheck_suggestions?" do
    before :each do
      helper.stub spell_check_max: 5
    end
    it "should not show suggestions if there are enough results" do
      response = double(total: 10)
      expect(helper.should_show_spellcheck_suggestions? response).to be_false
    end

    it "should only show suggestions if there are very few results" do
      response = double(total: 4, spelling: double(words: [1]))
      expect(helper.should_show_spellcheck_suggestions? response).to be_true
    end

    it "should show suggestions only if there are spelling suggestions available" do
      response = double(total: 4, spelling: double(words: []))
      expect(helper.should_show_spellcheck_suggestions? response).to be_false
    end
  end
end
