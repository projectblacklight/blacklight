#ste -*- encoding : utf-8 -*-
# -*- coding: UTF-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'marc'
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
      config.show.html_title = "title_display"
      config.show.heading = "title_display"
      config.show.display_type = 'format'

      config.index.show_link = 'title_display'
      config.index.record_display_type = 'format'
    end

    #CatalogController.blacklight_config
    #@config ||= {:show => {:html_title => 'title_display', :heading => 'title_display', :display_type => 'format'}, :index => { :show_link => 'title_display', :record_display_type => 'format' } }
  end

  describe "#application_name", :test => true do
    it "should use the Rails application config application_name if available" do
      Rails.application.config.stub(:application_name => 'asdf')
      Rails.application.config.should_receive(:respond_to?).with(:application_name).and_return(true)
      application_name.should == 'asdf'
    end
    it "should default to 'Blacklight'" do
      application_name.should == "Blacklight"
    end
  end

  describe "link_back_to_catalog" do
    before(:all) do
      @query_params = {:q => "query", :f => "facets", :per_page => "10", :page => "2", :controller=>'catalog'}
      @bookmarks_query_params = { :page => "2", :controller=>'bookmarks'}
    end

    it "should build a link tag to catalog using session[:search] for query params" do
      session[:search] = @query_params
      tag = link_back_to_catalog
      tag.should =~ /q=query/
      tag.should =~ /f=facets/
      tag.should =~ /per_page=10/
      tag.should =~ /page=2/
    end

    it "should build a link tag to bookmarks using session[:search] for query params" do
      session[:search] = @bookmarks_query_params
      tag = link_back_to_catalog
      tag.should =~ /Back to Bookmarks/
      tag.should =~ /\/bookmarks/
      tag.should =~ /page=2/
    end
  end

  describe "link_to_query" do
    it "should build a link tag to catalog using query string (no other params)" do
      query = "brilliant"
      self.should_receive(:params).and_return({})
      tag = link_to_query(query)
      tag.should =~ /q=#{query}/
      tag.should =~ />#{query}<\/a>/
    end
    it "should build a link tag to catalog using query string and other existing params" do
      query = "wonderful"
      self.should_receive(:params).and_return({:qt => "title_search", :per_page => "50"})
      tag = link_to_query(query)
      tag.should =~ /qt=title_search/
      tag.should =~ /per_page=50/
    end
    it "should ignore existing :page param" do
      query = "yes"
      self.should_receive(:params).and_return({:page => "2", :qt => "author_search"})
      tag = link_to_query(query)
      tag.should =~ /qt=author_search/
      tag.should_not =~ /page/
    end
    it "should be html_safe" do
      query = "brilliant"
      self.should_receive(:params).and_return({:page => "2", :qt => "author_search"})
      tag = link_to_query(query)
      tag.html_safe?.should == true
    end
  end

  describe "params_for_search" do
    def params
      { 'default' => 'params'}
    end

    it "should default to using the controller's params" do
      result = params_for_search
      result.should == params
      params.object_id.should_not == result.object_id
    end

    it "should let you pass in params to use" do
      source_params = { :q => 'query'}
      result = params_for_search(:params => source_params )
      source_params.should == result
      source_params.object_id.should_not == result.object_id
    end

    it "should not return blacklisted elements" do
      source_params = { :action => 'action', :controller => 'controller', :id => "id", :commit => 'commit'}
      result = params_for_search(:params => source_params )
      result.keys.should_not include(:action, :controller, :commit, :id)

    end

    it "should adjust the current page if the per_page changes" do
      source_params = { :per_page => 20, :page => 5}
      result = params_for_search(:params => source_params, :per_page => 100)
      result[:page].should == 1
    end

    it "should not adjust the current page if the per_page is the same as it always was" do
      source_params = { :per_page => 20, :page => 5}
      result = params_for_search(:params => source_params, :per_page => 20)
      result[:page].should == 5
    end

    it "should adjust the current page if the sort changes" do
      source_params = { :sort => 'field_a', :page => 5}
      result = params_for_search(:params => source_params, :sort => 'field_b')
      result[:page].should == 1
    end

    it "should not adjust the current page if the sort is the same as it always was" do
      source_params = { :sort => 'field_a', :page => 5}
      result = params_for_search(:params => source_params, :sort => 'field_a')
      result[:page].should == 5
    end

    describe "omit keys parameter" do
      it "should omit keys by key name" do
        source_params = { :a => 1, :b => 2, :c => 3}
        result = params_for_search(:params => source_params, :omit_keys => [:a, :b] )

        result.keys.should_not include(:a, :b)
        result[:c].should == 3
      end

      it "should remove keys if a key/value pair was passed and no values are left for that key" do
        source_params = { :f => ['a']}
        result = params_for_search(:params => source_params, :omit_keys => [{:f => 'a' }])
        result.keys.should_not include(:f)
      end

      it "should only remove keys when a key/value pair is based that are in that pair" do

        source_params = { :f => ['a', 'b']}
        result = params_for_search(:params => source_params, :omit_keys => [{:f => 'a' }])
        result[:f].should_not include('a')
        result[:f].should include('b')
      end
    end

  end

  describe "search_as_hidden_fields" do
    def params
      {:q => "query", :sort => "sort", :per_page => "20", :search_field => "search_field", :page => 100, :arbitrary_key => "arbitrary_value", :f => {"field" => ["value1", "value2"], "other_field" => ['asdf']}, :controller => "catalog", :action => "index", :commit => "search"}
    end
    describe "for default arguments" do
      it "should default to omitting :page" do
        search_as_hidden_fields.should_not have_selector("input[name='page']")
      end
    end
 end


   describe "render body class" do
      it "should include a serialization of the current controller name" do
        @controller = double("controller")
        @controller.stub(:controller_name).and_return("123456")
        @controller.stub(:action_name).and_return("abcdef")

	render_body_class.split(' ').should include('blacklight-123456')
      end

      it "should include a serialization of the current action name" do
        @controller = double("controller")
        @controller.stub(:controller_name).and_return("123456")
        @controller.stub(:action_name).and_return("abcdef")

	render_body_class.split(' ').should include('blacklight-123456-abcdef')
      end
   end

   describe "document_heading" do

     it "should consist of the show heading field when available" do
      @document = SolrDocument.new('title_display' => "A Fake Document")

      document_heading.should == "A Fake Document"
     end

     it "should fallback on the document id if no title is available" do
       @document = SolrDocument.new(:id => '123456')
       document_heading.should == '123456'
     end
   end

   describe "render_document_heading" do
     it "should consist of #document_heading wrapped in a <h1>" do
      @document = SolrDocument.new('title_display' => "A Fake Document")

      render_document_heading.should have_selector("h4", :text => "A Fake Document", :count => 1)
      render_document_heading.html_safe?.should == true
     end
     it "should join the values if it is an array" do
      @document = SolrDocument.new('title_display' => ["A Fake Document", 'Something Else'])

      render_document_heading.should have_selector("h4", :text => "A Fake Document, Something Else", :count => 1)
      render_document_heading.html_safe?.should == true
     end
   end

   describe "document_show_html_title" do
     it "should join the values if it is an array" do
      @document = SolrDocument.new('title_display' => ["A Fake Document", 'Something Else'])
      document_show_html_title.should == "A Fake Document, Something Else"
     end
   end

   describe "document_index_view_type" do
     it "should default to 'list'" do
       document_index_view_type.should == 'list'
     end

     it "should pluck values out of params" do
       blacklight_config.stub(:document_index_view_types) { ['list', 'asdf'] }
       params[:view] = 'asdf'
       document_index_view_type.should == 'asdf'

       params[:view] = 'not_in_list'
       document_index_view_type.should == 'list'
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
       document_partial_name({}).should == "default"
     end
     it "should handle normal formats correctly" do
       document_partial_name({"format" => "myformat"}).should == "myformat"
     end
     it "should handle spaces correctly" do
       document_partial_name({"format" => "my format"}).should == "my_format"
     end
     it "should handle capitalization correctly" do
       document_partial_name({"format" => "MyFormat"}).should == "myformat"
     end
     it "should handle puncuation correctly" do
       document_partial_name({"format" => "My.Format"}).should == "my_format"
     end
     it "should handle multi-valued fields correctly" do
       document_partial_name({"format" => ["My Format", "My OtherFormat"]}).should == "my_format_my_otherformat"
     end
     it "should remove - characters because they will throw errors" do
       document_partial_name({"format" => "My-Format"}).should == "my_format"
       document_partial_name({"format" => ["My-Format",["My Other-Format"]]}).should == "my_format_my_other_format"
     end
   end

   describe "link_to_document" do
     it "should consist of the document title wrapped in a <a>" do
      data = {'id'=>'123456','title_display'=>['654321'] }
      @document = SolrDocument.new(data)
      link_to_document(@document, { :label => :title_display }).should have_selector("a", :text => '654321', :count => 1)
     end
     it "should accept and return a string label" do
      data = {'id'=>'123456','title_display'=>['654321'] }
      @document = SolrDocument.new(data)
      link_to_document(@document, { :label => "title_display" }).should have_selector("a", :text => 'title_display', :count => 1)
     end

     it "should accept and return a Proc" do
      data = {'id'=>'123456','title_display'=>['654321'] }
      @document = SolrDocument.new(data)
      link_to_document(@document, { :label => Proc.new { |doc, opts| doc.get(:id) + ": " + doc.get(:title_display) } }).should have_selector("a", :text => '123456: 654321', :count => 1)
     end
     it "should return id when label is missing" do
      data = {'id'=>'123456'}
      @document = SolrDocument.new(data)
      link_to_document(@document, { :label => :title_display }).should have_selector("a", :text => '123456', :count => 1)
     end

     it "should be html safe" do
      data = {'id'=>'123456'}
      @document = SolrDocument.new(data)
      link_to_document(@document, { :label => :title_display }).html_safe?.should == true
     end

     it "should convert the counter parameter into a data- attribute" do
      data = {'id'=>'123456','title_display'=>['654321']}
      @document = SolrDocument.new(data)
      link_to_document(@document, { :label => :title_display, :counter => 5  }).should =~ /data-counter="5"/
     end

     it "passes on the title attribute to the link_to_with_data method" do
       @document = SolrDocument.new('id'=>'123456')
       link_to_document(@document,:label=>"Some crazy long label...",:title=>"Some crazy longer label").should match(/title=\"Some crazy longer label\"/)
     end

     it "doesn't add an erroneous title attribute if one isn't provided" do
       @document = SolrDocument.new('id'=>'123456')
       link_to_document(@document,:label=>"Some crazy long label...").should_not match(/title=/)
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

      @document.export_formats.each_pair do |format, spec|
        response.should have_selector("link[href$='.#{ format  }']") do |matches|
          matches.length.should == 1
          tag = matches[0]
          tag.attributes["rel"].value.should == "alternate"
          tag.attributes["title"].value.should == format.to_s
          tag.attributes["href"].value.should === mock_document_app_helper_url(@document, :format =>format)
        end
      end
    end
    it "respects :unique=>true" do
      response = render_link_rel_alternates(@document, :unique => true)
      response.should have_selector("link[type='application/weird']", :count => 1)
    end
    it "excludes formats from :exclude" do
      response = render_link_rel_alternates(@document, :exclude => [:weird_dup])

      response.should_not have_selector("link[href$='.weird_dup']")
    end

    it "should be html safe" do
      response = render_link_rel_alternates(@document)
      response.html_safe?.should == true
    end
  end

  describe "with a config" do
    before do
      @config = Blacklight::Configuration.new.configure do |config|
        config.show.html_title = "title_display"
        config.show.heading = "title_display"
        config.show.display_type = 'format'

        config.index.show_link = 'title_display'
        config.index.record_display_type = 'format'
      end

      @document = SolrDocument.new('title_display' => "A Fake Document", 'id'=>'8')
      helper.stub(:blacklight_config).and_return(@config)
      helper.stub(:has_user_authentication_provider?).and_return(true)
      helper.stub(:current_or_guest_user).and_return(User.new)
    end
    describe "render_index_doc_actions" do
      it "should render partials" do
        response = helper.render_index_doc_actions(@document)
        response.should have_selector(".bookmark_toggle")
      end
    end
    describe "render_show_doc_actions" do
      it "should render partials" do
        response = helper.render_show_doc_actions(@document)
        response.should have_selector(".bookmark_toggle")
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
      end
      helper.stub(:blacklight_config).and_return(@config)
    end

    it "should check for an explicit value" do
      doc = double()
      doc.should_not_receive(:get).with('asdf', :sep => nil)
      value = helper.render_index_field_value :value => 'asdf', :document => doc, :field => 'asdf'
      value.should == 'asdf'
    end

    it "should check for a helper method to call" do
      doc = double()
      doc.should_not_receive(:get).with('asdf', :sep => nil)
      helper.stub(:render_asdf_index_field).and_return('custom asdf value')
      value = helper.render_index_field_value :document => doc, :field => 'asdf'
      value.should == 'custom asdf value'
    end

    it "should check for a link_to_search" do
      doc = double()
      doc.should_receive(:get).with('link_to_search_true', :sep => nil).and_return('x')
      value = helper.render_index_field_value :document => doc, :field => 'link_to_search_true'
      value.should == helper.link_to("x", helper.search_action_url(:f => { :link_to_search_true => ['x'] }))
    end

    it "should check for a link_to_search with a field name" do
      doc = double()
      doc.should_receive(:get).with('link_to_search_named', :sep => nil).and_return('x')
      value = helper.render_index_field_value :document => doc, :field => 'link_to_search_named'
      value.should == helper.link_to("x", helper.search_action_url(:f => { :some_field => ['x'] }))
    end

    it "should gracefully handle when no highlight field is available" do
      doc = double()
      doc.should_not_receive(:get)
      doc.should_receive(:has_highlight_field?).and_return(false)
      value = helper.render_index_field_value :document => doc, :field => 'highlight'
      value.should be_blank
    end

    it "should check for a highlighted field" do
      doc = double()
      doc.should_not_receive(:get)
      doc.should_receive(:has_highlight_field?).and_return(true)
      doc.should_receive(:highlight_field).with('highlight').and_return(['<em>highlight</em>'.html_safe])
      value = helper.render_index_field_value :document => doc, :field => 'highlight'
      value.should == '<em>highlight</em>'
    end

    it "should check the document field value" do
      doc = double()
      doc.should_receive(:get).with('qwer', :sep => nil).and_return('document qwer value')
      value = helper.render_index_field_value :document => doc, :field => 'qwer'
      value.should == 'document qwer value'
    end

    it "should work with index fields that aren't explicitly defined" do
      doc = double()
      doc.should_receive(:get).with('mnbv', :sep => nil).and_return('document mnbv value')
      value = helper.render_index_field_value :document => doc, :field => 'mnbv'
      value.should == 'document mnbv value'
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
      end
      helper.stub(:blacklight_config).and_return(@config)
    end

    it "should check for an explicit value" do
      doc = double()
      doc.should_not_receive(:get).with('asdf', :sep => nil)
      helper.should_not_receive(:render_asdf_document_show_field)
      value = helper.render_document_show_field_value :value => 'asdf', :document => doc, :field => 'asdf'
      value.should == 'asdf'
    end

    it "should check for a helper method to call" do
      doc = double()
      doc.should_not_receive(:get).with('asdf', :sep => nil)
      helper.stub(:render_asdf_document_show_field).and_return('custom asdf value')
      value = helper.render_document_show_field_value :document => doc, :field => 'asdf'
      value.should == 'custom asdf value'
    end

    it "should check for a link_to_search" do
      doc = double()
      doc.should_receive(:get).with('link_to_search_true', :sep => nil).and_return('x')
      value = helper.render_document_show_field_value :document => doc, :field => 'link_to_search_true'
      value.should == helper.link_to("x", helper.search_action_url(:f => { :link_to_search_true => ['x'] }))
    end

    it "should check for a link_to_search with a field name" do
      doc = double()
      doc.should_receive(:get).with('link_to_search_named', :sep => nil).and_return('x')
      value = helper.render_document_show_field_value :document => doc, :field => 'link_to_search_named'
      value.should == helper.link_to("x", helper.search_action_url(:f => { :some_field => ['x'] }))
    end

    it "should gracefully handle when no highlight field is available" do
      doc = double()
      doc.should_not_receive(:get)
      doc.should_receive(:has_highlight_field?).and_return(false)
      value = helper.render_document_show_field_value :document => doc, :field => 'highlight'
      value.should be_blank
    end

    it "should check for a highlighted field" do
      doc = double()
      doc.should_not_receive(:get)
      doc.should_receive(:has_highlight_field?).and_return(true)
      doc.should_receive(:highlight_field).with('highlight').and_return(['<em>highlight</em>'.html_safe])
      value = helper.render_document_show_field_value :document => doc, :field => 'highlight'
      value.should == '<em>highlight</em>'
    end


    it "should check the document field value" do
      doc = double()
      doc.should_receive(:get).with('qwer', :sep => nil).and_return('document qwer value')
      value = helper.render_document_show_field_value :document => doc, :field => 'qwer'
      value.should == 'document qwer value'
    end

    it "should work with show fields that aren't explicitly defined" do
      doc = double()
      doc.should_receive(:get).with('mnbv', :sep => nil).and_return('document mnbv value')
      value = helper.render_document_show_field_value :document => doc, :field => 'mnbv'
      value.should == 'document mnbv value'
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
  end


  describe "#should_render_show_field?" do
    it "should if the document has the field value" do
      doc = double()
      doc.stub(:has?).with('asdf').and_return(true)
      field_config = double(:field => 'asdf')
      helper.should_render_show_field?(doc, field_config).should == true
    end

    it "should if the document has a highlight field value" do
      doc = double()
      doc.stub(:has?).with('asdf').and_return(false)
      doc.stub(:has_highlight_field?).with('asdf').and_return(true)
      field_config = double(:field => 'asdf', :highlight => true)
      helper.should_render_show_field?(doc, field_config).should == true
    end
  end

end
