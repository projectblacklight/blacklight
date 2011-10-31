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
  
end
