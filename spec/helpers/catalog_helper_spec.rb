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

    mock_response = double("Blacklight::SolrResponse")
    mock_response.stub(:total).and_return(total)
    mock_response.stub(:rows).and_return(per_page)
    mock_response.stub(:start).and_return(start)
    mock_response.stub(:docs).and_return((1..total).to_a.slice(start, per_page))

    mock_response
  end
  
  describe "render_pagination_info" do
    before(:all) do
    end

    it "with no results" do
      @response = mock_response :total => 0

      html = render_pagination_info(@response, { :entry_name => 'entry_name' })
      html.should == "No entry_names found"
      html.html_safe?.should == true
    end

    it "with no results (and no entry_name provided)" do
      @response = mock_response :total => 0

      html = render_pagination_info(@response)
      html.should == "No entries found"
      html.html_safe?.should == true
    end

    it "with a single result" do
      @response = mock_response :total => 1

      html = render_pagination_info(@response, { :entry_name => 'entry_name' })
      html.should == "<strong>1</strong> to <strong>1</strong> of <strong>1</strong>"
      html.html_safe?.should == true
    end

    it "with a single page of results" do
      @response = mock_response :total => 7

      html = render_pagination_info(@response, { :entry_name => 'entry_name' })
      html.should == "<strong>1</strong> - <strong>7</strong> of <strong>7</strong>"
      html.html_safe?.should == true
    end

    it "on the first page of multiple pages of results" do
      @response = mock_response :total => 15, :per_page => 10

      html = render_pagination_info(@response, { :entry_name => 'entry_name' })
      html.should == "<strong>1</strong> - <strong>10</strong> of <strong>15</strong>"
      html.html_safe?.should == true
    end

    it "on the second page of multiple pages of results" do
      @response = mock_response :total => 47, :per_page => 10, :current_page => 2

      html = render_pagination_info(@response, { :entry_name => 'entry_name' })
      html.should == "<strong>11</strong> - <strong>20</strong> of <strong>47</strong>"
      html.html_safe?.should == true
    end

    it "on the last page of results" do
      @response = mock_response :total => 47, :per_page => 10, :current_page => 5

      html = render_pagination_info(@response, { :entry_name => 'entry_name' })
      html.should == "<strong>41</strong> - <strong>47</strong> of <strong>47</strong>"
      html.html_safe?.should == true
    end
    it "should work with rows the same as per_page" do
      @response = mock_response :total => 47, :rows => 20, :current_page => 2

      html = render_pagination_info(@response, { :entry_name => 'entry_name' })
      html.should == "<strong>21</strong> - <strong>40</strong> of <strong>47</strong>"
      html.html_safe?.should == true
    end

  end
end
