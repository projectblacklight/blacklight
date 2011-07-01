# -*- encoding : utf-8 -*-
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
  
  describe "link_back_to_catalog" do
    before(:all) do
      @query_params = {:q => "query", :f => "facets", :per_page => "10", :page => "2"}
    end
    it "should build a link tag to catalog using session[:search] for query params" do
      session[:search] = @query_params
      tag = link_back_to_catalog
      tag.should =~ /q=query/
      tag.should =~ /f=facets/
      tag.should =~ /per_page=10/
      tag.should =~ /page=2/
    end
  end
  
  describe "link_to_with_data" do
    it "should generate proper tag for :put and with single :data key and value" do
      assert_dom_equal(
        "<a href='http://www.example.com' onclick=\"var f = document.createElement('form'); f.style.display = 'none'; this.parentNode.appendChild(f); f.method = 'POST'; f.action = this.href;if(event.metaKey || event.ctrlKey){f.target = '_blank';};var d = document.createElement('input'); d.setAttribute('type', 'hidden'); d.setAttribute('name', 'key'); d.setAttribute('value', 'value'); f.appendChild(d);var m = document.createElement('input'); m.setAttribute('type', 'hidden'); m.setAttribute('name', '_method'); m.setAttribute('value', 'put'); f.appendChild(m);f.submit();return false;\">Foo</a>",
        link_to_with_data("Foo", "http://www.example.com", :method => :put, :data => {:key => "value"})
      )
    end
    it "should be html_safe" do
      link_to_with_data("Foo", "http://www.example.com", :method => :put, :data => {:key => "value"}).html_safe?.should == true
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

  describe "search_as_hidden_fields" do
    def params
      {:q => "query", :sort => "sort", :per_page => "20", :search_field => "search_field", :page => 100, :arbitrary_key => "arbitrary_value", :f => {"field" => ["value1", "value2"]}, :controller => "catalog", :action => "index", :commit => "search"}
    end
    describe "for default arguments" do
      it "should default to omitting :page" do
        search_as_hidden_fields.should have_selector("input[type='hidden']", :count =>7)
        search_as_hidden_fields.should_not have_selector("input[name='page']") 
      end
      it "should not return blacklisted elements" do
        search_as_hidden_fields.should_not have_selector("input[name='action']")
        search_as_hidden_fields.should_not have_selector("input[name='controller']")
        search_as_hidden_fields.should_not have_selector("input[name='commit']")
      end
      describe "for omit_keys parameter" do
        it "should not include those keys" do
           generated = search_as_hidden_fields(:omit_keys => [:per_page, :sort])
           
           generated.should_not have_selector("input[name=sort]")
           generated.should_not have_selector("input[name=per_page]")

           generated.should have_selector("input[name=page]")
        end
      end
    end
    
 end

  describe "render_stylesheet_links" do
    def stylesheet_links
      [ 
        ["my_stylesheet", {:plugin => :blacklight}],
        ["other_stylesheet"]
      ]
    end
    it "should render stylesheets specified in controller #stylesheet_links" do
      html = render_stylesheet_includes      
      html.should have_selector("link[href='/stylesheets/my_stylesheet.css'][rel='stylesheet'][type='text/css']")
      html.should have_selector("link[href='/stylesheets/other_stylesheet.css'][rel='stylesheet'][type='text/css']")
      html.html_safe?.should == true
    end
  end
  
  describe "render_js_includes" do
    def javascript_includes
      [ 
        ["some_js.js", {:plugin => :blacklight}],
        ["other_js"]
      ]
    end
    it "should include script tags specified in controller#javascript_includes" do
      html = render_js_includes
      html.should have_selector("script[src='/javascripts/some_js.js'][type='text/javascript']")
      html.should have_selector("script[src='/javascripts/other_js.js'][type='text/javascript']")      

      html.html_safe?.should == true
    end
   end

  describe "render_extra_head_content" do
    def extra_head_content
      ['<link rel="a">', '<link rel="b">']
    end

    it "should include content specified in controller#extra_head_content" do
      html = render_extra_head_content

      html.should have_selector("link[rel=a]")
      html.should have_selector("link[rel=b]")

      html.html_safe?.should == true
    end
  end

   describe "render_head_content" do
    describe "with no methods defined" do
      it "should return empty string without complaint" do
      lambda {render_head_content}.should_not raise_error
      render_head_content.should be_blank
      render_head_content.html_safe?.should == true
      end
    end
    describe "with methods defined" do
      def javascript_includes
        [["my_js"]]
      end
      def stylesheet_links
        [["my_css"]]
      end
      def extra_head_content
        [
          "<madeup_tag></madeup_tag>",
          '<link rel="rel" type="type" href="href">' 
        ]
      end
      before(:each) do
        @output = render_head_content
      end
      it "should include extra_head_content" do
        @output.should have_selector("madeup_tag")
        @output.should have_selector("link[rel=rel][type=type][href=href]")
      end
      it "should include render_javascript_includes" do
        @output.index( render_js_includes ).should_not be_nil
      end
      it "should include render_stylesheet_links" do
        @output.index( render_stylesheet_includes ).should_not be_nil
      end
    end
   end

   describe "render body class" do
      it "should include a serialization of the current controller name" do
        @controller = mock("controller")
        @controller.should_receive(:controller_name).any_number_of_times.and_return("123456")
        @controller.should_receive(:action_name).any_number_of_times.and_return("abcdef")

	render_body_class.split(' ').should include('blacklight-123456')
      end

      it "should include a serialization of the current action name" do
        @controller = mock("controller")
        @controller.should_receive(:controller_name).any_number_of_times.and_return("123456")
        @controller.should_receive(:action_name).any_number_of_times.and_return("abcdef")

	render_body_class.split(' ').should include('blacklight-123456-abcdef')
      end
   end
   
   describe "document_heading" do
     it "should consist of the show heading field when available" do
      @document = SolrDocument.new(Blacklight.config[:show][:heading] => "A Fake Document")

      document_heading.should == "A Fake Document"
     end

     it "should fallback on the document id if no title is available" do
       @document = SolrDocument.new(:id => '123456')
       document_heading.should == '123456'
     end
   end

   describe "render_document_heading" do
     it "should consist of #document_heading wrapped in a <h1>" do
      @document = SolrDocument.new(Blacklight.config[:show][:heading] => "A Fake Document")

      render_document_heading.should have_selector("h1", :content => document_heading, :count => 1)
      render_document_heading.html_safe?.should == true
     end
   end

   describe "document_partial_name" do
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
      link_to_document(@document, { :label => :title_display }).should have_selector("a", :content => '654321', :count => 1)
     end
     it "should accept and return a string label" do
      data = {'id'=>'123456','title_display'=>['654321'] }
      @document = SolrDocument.new(data)
      link_to_document(@document, { :label => "title_display" }).should have_selector("a", :content => 'title_display', :count => 1)
     end
     it "should properly javascript escape the label value" do
       data = {'id'=>'123456','title_display'=>['654321'] }
       @document = SolrDocument.new(data)
       link = link_to_document(@document, { :label => "Apple's Oranges" })
       link.should match(/'Apple\\'s Oranges'/)
       link.should_not match(/'Apple's Oranges'/)
     end
     it "should accept and return a Proc" do
      data = {'id'=>'123456','title_display'=>['654321'] }
      @document = SolrDocument.new(data)
      link_to_document(@document, { :label => Proc.new { |doc, opts| doc.get(:id) + ": " + doc.get(:title_display) } }).should have_selector("a", :content => '123456: 654321', :count => 1)
     end
     it "should return id when label is missing" do
      data = {'id'=>'123456'}
      @document = SolrDocument.new(data)
      link_to_document(@document, { :label => :title_display }).should have_selector("a", :content => '123456', :count => 1)
     end

     it "should be html safe" do
      data = {'id'=>'123456'}
      @document = SolrDocument.new(data)
      link_to_document(@document, { :label => :title_display }).html_safe?.should == true
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
    before(:each) do
      @doc_id = "MOCK_ID1"
      @document = MockDocumentAppHelper.new(:id => @doc_id)
      render_params = {:controller => "controller", :action => "action"}
      helper.stub!(:params).and_return(render_params)
    end
    it "generates <link rel=alternate> tags" do

      response = render_link_rel_alternates(@document)

      @document.export_formats.each_pair do |format, spec|
        response.should have_selector("link[href$='.#{ format  }']") do |matches|
          matches.length.should == 1
          tag = matches[0]
          tag.attributes["rel"].value.should == "alternate"
          tag.attributes["title"].value.should == format.to_s
          tag.attributes["href"].value.should === catalog_url(@doc_id, format)
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
  
  describe "convenience methods" do
    it "should handle the case where we don't have a spellmax set in the config" do
      spell_check_max.should == 5
      sm = Blacklight.config[:spell_max]
      Blacklight.config[:spell_max] = nil
      spell_check_max.should == 0
      Blacklight.config[:spell_max] = sm
    end
  end
end
