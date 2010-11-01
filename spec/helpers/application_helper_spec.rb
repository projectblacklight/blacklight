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
describe ApplicationHelper do
  include ApplicationHelper
  
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
  end
  
  describe "link_to_query" do
    it "should build a link tag to catalog using query string (no other params)" do
      query = "brilliant"
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
  end

  describe "search_as_hidden_fields" do
    def params
      {:q => "query", :sort => "sort", :per_page => "20", :search_field => "search_field", :page => 100, :arbitrary_key => "arbitrary_value", :f => {"field" => ["value1", "value2"]}, :controller => "catalog", :action => "index"}
    end
    describe "for default arguments" do
      it "should default to omitting :page" do
        search_as_hidden_fields.should have_tag("input[type=hidden]", 7)
        search_as_hidden_fields.should_not have_tag("input[name=page]") 
      end
      it "should not return action and controller hidden elements" do
        search_as_hidden_fields.should_not have_tag("input[name=action]")
        search_as_hidden_fields.should_not have_tag("input[name=controller]")
      end
      describe "for omit_keys parameter" do
        it "should not include those keys" do
           generated = search_as_hidden_fields(:omit_keys => [:per_page, :sort])
           
           generated.should_not have_tag("input[name=sort]")
           generated.should_not have_tag("input[name=per_page]")

           generated.should have_tag("input[name=page]")
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
      
      html.should have_tag("link[href=/plugin_assets/blacklight/stylesheets/my_stylesheet.css][rel=stylesheet][type=text/css]")

      html.should have_tag("link[href=/stylesheets/other_stylesheet.css][rel=stylesheet][type=text/css]")
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

      html.should have_tag("script[src=/plugin_assets/blacklight/javascripts/some_js.js][type=text/javascript]")

      html.should have_tag("script[src=/javascripts/other_js.js][type=text/javascript]")      
    end
   end

   describe "render_head_content" do
    describe "with no methods defined" do
      it "should return empty string without complaint" do
      lambda {render_head_content}.should_not raise_error
      render_head_content.should be_blank
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
        @output.should have_tag("madeup_tag")
        @output.should have_tag("link[rel=rel][type=type][href=href]")
      end
      it "should include render_javascript_includes" do
        @output.index( render_js_includes ).should_not be_nil
      end
      it "should include render_stylesheet_links" do
        @output.index( render_stylesheet_includes ).should_not be_nil
      end
    end
   end

   
   
   describe "render_document_heading" do
     it "should consist of #document_heading wrapped in a <h1>" do
      @document = SolrDocument.new(Blacklight.config[:show][:heading] => "A Fake Document")

      render_document_heading.should have_tag("h1", :text => document_heading, :count => 1)
     end
   end

   describe "link_to_document" do
     it "should consist of the document title wrapped in a <a>" do
      data = {'id'=>'123456','title_display'=>['654321'] }
      @document = SolrDocument.new(data)
      link_to_document(@document, { :label => :title_display }).should have_tag("a", :text => '654321', :count => 1)
     end
     it "should accept and return a string label" do
      data = {'id'=>'123456','title_display'=>['654321'] }
      @document = SolrDocument.new(data)
      link_to_document(@document, { :label => "title_display" }).should have_tag("a", :text => 'title_display', :count => 1)
     end
     it "should accept and return a Proc" do
      data = {'id'=>'123456','title_display'=>['654321'] }
      @document = SolrDocument.new(data)
      link_to_document(@document, { :label => Proc.new { |doc, opts| doc.get(:id) + ": " + doc.get(:title_display) } }).should have_tag("a", :text => '123456: 654321', :count => 1)
     end
     it "should return id when label is missing" do
      data = {'id'=>'123456'}
      @document = SolrDocument.new(data)
      link_to_document(@document, { :label => :title_display }).should have_tag("a", :text => '123456', :count => 1)
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
      class MockDocument
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
      MockDocument.use_extension(MockExtension)
    before(:each) do
      @doc_id = "MOCK_ID1"
      @document = MockDocument.new(:id => @doc_id)
      params[:controller] = "controller"
      params[:action] = "action"
    end
    it "generates <link rel=alternate> tags" do


      response = render_link_rel_alternates(@document)

      @document.export_formats.each_pair do |format, spec|
        response.should have_tag("link[href$=.#{ format  }]") do |matches|
          matches.length.should == 1
          tag = matches[0]
          tag.attributes["rel"].should == "alternate"
          tag.attributes["title"].should == format.to_s
          tag.attributes["href"].should === catalog_url(@doc_id, format)
        end        
      end
    end
    it "respects :unique=>true" do
      response = render_link_rel_alternates(@document, :unique => true)
      response.should have_tag("link[type=application/weird]", :count => 1)
    end
    it "excludes formats from :exclude" do
      response = render_link_rel_alternates(@document, :exclude => [:weird_dup])

      response.should_not have_tag("link[href$=.weird_dup]")
    end
    
  end
  
  
end
