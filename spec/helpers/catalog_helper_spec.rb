# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
describe CatalogHelper do
  include ERB::Util
  include CatalogHelper

  def mock_response args
    current_page = args[:current_page] || 1
    per_page = args[:rows] || args[:per_page] || 10
    total = args[:total]
    start = (current_page - 1) * per_page

    mock_docs = (1..total).to_a.map { {}.with_indifferent_access }
    
    mock_response = Kaminari.paginate_array(mock_docs).page(current_page).per(per_page)

    mock_response.stub(:docs).and_return(mock_docs.slice(start, per_page))
    mock_response
  end

  def render_grouped_response?
    false
  end

  describe "deprecated methods" do
    describe "response_has_no_search_results?" do
      it "should be deprecated" do
        expect(Blacklight::CatalogHelperBehavior.deprecation_behavior.first).to receive(:call)
        assign(:response, double(:empty? => false))
        expect(helper.response_has_no_search_results?).to be_false
      end
    end
    
    describe "paginate_params" do
      let(:response) { double }
      it "should be deprecated" do
        expect(Blacklight::CatalogHelperBehavior.deprecation_behavior.first).to receive(:call)
        assign(:response, response)
        expect(helper.paginate_params(response)).to eq response
      end
    end

    describe "format_num" do
      it "should be deprecated" do
        expect(Blacklight::CatalogHelperBehavior.deprecation_behavior.first).to receive(:call)
        expect(format_num(10000)).to eq '10,000'
      end
    end

  end
  
  describe "page_entries_info" do
    before(:all) do
    end

    it "with no results" do
      @response = mock_response :total => 0

      html = page_entries_info(@response, { :entry_name => 'entry_name' })
      html.should == "No entry_names found"
      html.html_safe?.should == true
    end

    it "with no results (and no entry_name provided)" do
      @response = mock_response :total => 0

      html = page_entries_info(@response)
      html.should == "No entries found"
      html.html_safe?.should == true
    end

    describe "with a single result" do
      it "should use the provided entry name" do
        response = mock_response :total => 1

        html = page_entries_info(response, { :entry_name => 'entry_name' })
        html.should == "<strong>1</strong> entry_name found"
        html.html_safe?.should == true
      end

      it "should infer a name" do
        response = mock_response :total => 1

        html = page_entries_info(response)
        html.should == "<strong>1</strong> entry found"
        html.html_safe?.should == true
      end

      it "should use the model_name from the response" do
        response = mock_response :total => 1
        response.stub(:model_name).and_return(double(:human => 'thingy'))

        html = page_entries_info(response)
        expect(html).to eq "<strong>1</strong> thingy found"
        expect(html).to be_html_safe
      end
    end

    it "with a single page of results" do
      response = mock_response :total => 7

      html = page_entries_info(response, { :entry_name => 'entry_name' })
      html.should == "<strong>1</strong> - <strong>7</strong> of <strong>7</strong>"
      html.html_safe?.should == true
    end

    it "on the first page of multiple pages of results" do
      @response = mock_response :total => 15, :per_page => 10

      html = page_entries_info(@response, { :entry_name => 'entry_name' })
      html.should == "<strong>1</strong> - <strong>10</strong> of <strong>15</strong>"
      html.html_safe?.should == true
    end

    it "on the second page of multiple pages of results" do
      @response = mock_response :total => 47, :per_page => 10, :current_page => 2

      html = page_entries_info(@response, { :entry_name => 'entry_name' })
      html.should == "<strong>11</strong> - <strong>20</strong> of <strong>47</strong>"
      html.html_safe?.should == true
    end

    it "on the last page of results" do
      @response = mock_response :total => 47, :per_page => 10, :current_page => 5

      html = page_entries_info(@response, { :entry_name => 'entry_name' })
      html.should == "<strong>41</strong> - <strong>47</strong> of <strong>47</strong>"
      html.html_safe?.should == true
    end
    it "should work with rows the same as per_page" do
      @response = mock_response :total => 47, :rows => 20, :current_page => 2

      html = page_entries_info(@response, { :entry_name => 'entry_name' })
      html.should == "<strong>21</strong> - <strong>40</strong> of <strong>47</strong>"
      html.html_safe?.should == true
    end

    it "uses delimiters with large numbers" do
      @response = mock_response :total => 5000, :rows => 10, :current_page => 101
      html = page_entries_info(@response, { :entry_name => 'entry_name' })

      html.should == "<strong>1,001</strong> - <strong>1,010</strong> of <strong>5,000</strong>"
    end

    it "should work with an activerecord collection" do
      50.times { b = Bookmark.new;  b.user_id = 1; b.save! }
      html = helper.page_entries_info(Bookmark.page(1).per(25))
      expect(html).to eq "<strong>1</strong> - <strong>25</strong> of <strong>50</strong>"
    end

  end

  describe "should_autofocus_on_search_box?" do
    it "should be focused if we're on a catalog-like index page without query or facet parameters" do
      helper.stub(:controller => CatalogController.new, :action_name => "index", :params => { })
      expect(helper.should_autofocus_on_search_box?).to be_true
    end

    it "should not be focused if we're not on a catalog controller" do
      helper.stub(:controller => ApplicationController.new)
      expect(helper.should_autofocus_on_search_box?).to be_false
    end

    it "should not be focused if we're not on a catalog controller index" do
      helper.stub(:controller => CatalogController.new, :action_name => "show")
      expect(helper.should_autofocus_on_search_box?).to be_false
    end

    it "should not be focused if a search string is provided" do
      helper.stub(:controller => CatalogController.new, :action_name => "index", :params => { :q => "hello"})
      expect(helper.should_autofocus_on_search_box?).to be_false
    end

    it "should not be focused if a facet is selected" do
      helper.stub(:controller => CatalogController.new, :action_name => "index", :params => { :f => { "field" => ["value"]}})
      expect(helper.should_autofocus_on_search_box?).to be_false
    end
  end

  describe "has_thumbnail?" do
    it "should have a thumbnail if a thumbnail_method is configured" do
      helper.stub(:blacklight_config => OpenStruct.new(:index => OpenStruct.new(:thumbnail_method => :xyz) ))
      document = double()
      expect(helper.has_thumbnail? document).to be_true
    end

    it "should have a thumbnail if a thumbnail_field is configured and it exists in the document" do
      helper.stub(:blacklight_config => OpenStruct.new(:index => OpenStruct.new(:thumbnail_field => :xyz) ))
      document = double(:has? => true)
      expect(helper.has_thumbnail? document).to be_true
    end
    
    it "should not have a thumbnail if the thumbnail_field is missing from the document" do
      helper.stub(:blacklight_config => OpenStruct.new(:index => OpenStruct.new(:thumbnail_field => :xyz) ))
      document = double(:has? => false)
      expect(helper.has_thumbnail? document).to be_false
    end

    it "should not have a thumbnail if none of the fields are configured" do
      helper.stub(:blacklight_config => OpenStruct.new(:index => OpenStruct.new()))
      expect(helper.has_thumbnail? double()).to be_false
    end
  end

  describe "render_thumbnail_tag" do
    it "should call the provided thumbnail method" do
      helper.stub(:blacklight_config => double(:index => double(:thumbnail_method => :xyz)))
      document = double()
      helper.stub(:xyz => "some-thumbnail")

      helper.should_receive(:link_to_document).with(document, :label => "some-thumbnail")
      helper.render_thumbnail_tag document
    end

    it "should create an image tag from the given field" do
      helper.stub(:blacklight_config => double(:index => OpenStruct.new(:thumbnail_field => :xyz)))
      document = double()

      document.stub(:has?).with(:xyz).and_return(true)
      document.stub(:first).with(:xyz).and_return("http://example.com/some.jpg")

      helper.should_receive(:link_to_document).with(document, :label => image_tag("http://example.com/some.jpg"))
      helper.render_thumbnail_tag document
    end

    it "should return nil if no thumbnail is available" do
      helper.stub(:blacklight_config => double(:index => OpenStruct.new()))

      document = double()
      expect(helper.render_thumbnail_tag document).to be_nil
    end

    it "should return nil if no thumbnail is returned from the thumbnail method" do
      helper.stub(:blacklight_config => double(:index => OpenStruct.new(:thumbnail_method => :xyz)))
      helper.stub(:xyz => nil)
      document = double()

      expect(helper.render_thumbnail_tag document).to be_nil
    end
  end

  describe "thumbnail_url" do
    it "should pull the configured thumbnail field out of the document" do
      helper.stub(:blacklight_config => double(:index => double(:thumbnail_field => "xyz")))
      document = double()
      document.stub(:has?).with("xyz").and_return(true)
      document.stub(:first).with("xyz").and_return("asdf")
      expect(helper.thumbnail_url document).to eq("asdf")
    end

    it "should return nil if the thumbnail field doesn't exist" do
      helper.stub(:blacklight_config => double(:index => double(:thumbnail_field => "xyz")))
      document = double()
      document.stub(:has?).with("xyz").and_return(false)
      expect(helper.thumbnail_url document).to be_nil
    end
  end

  describe "document_counter_with_offset" do
    it "should render the document index with the appropriate offset" do
      assign(:response, double(:params => { :start => 0 }, :grouped? => false))
      expect(helper.document_counter_with_offset(0)).to be(1)
      expect(helper.document_counter_with_offset(1)).to be(2)
    end

    it "should render the document index with the appropriate offset" do
      assign(:response, double(:params => { :start => 10 }, :grouped? => false))
      expect(helper.document_counter_with_offset(0)).to be(11)
      expect(helper.document_counter_with_offset(1)).to be(12)
    end

    it "should not provide a counter for grouped responses" do
      assign(:response, double(:params => { :start => 10 }, :grouped? => true))
      expect(helper.document_counter_with_offset(0)).to be_nil
    end
  end

end
