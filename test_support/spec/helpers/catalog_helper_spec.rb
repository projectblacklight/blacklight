# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
describe CatalogHelper do
  include ERB::Util
  include CatalogHelper

  def mock_response args
    current_page = args[:current_page] || 1
    per_page = args[:per_page] || 10
    total = args[:total]
    start = (current_page - 1) * per_page

    mock_response = mock("Blacklight::SolrResponse")
    mock_response.stub!(:total).and_return(total)
    mock_response.stub!(:rows).and_return(per_page)
    mock_response.stub!(:start).and_return(start)
    mock_response.stub!(:docs).and_return((1..total).to_a.slice(start, per_page))

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

    it "with a single result" do
      @response = mock_response :total => 1

      html = render_pagination_info(@response, { :entry_name => 'entry_name' })
      html.should == "Displaying <b>1</b> entry_name"
      html.html_safe?.should == true
    end

    it "with a single page of results" do
      @response = mock_response :total => 7

      html = render_pagination_info(@response, { :entry_name => 'entry_name' })
      html.should == "Displaying <b>all 7</b> entry_names"
      html.html_safe?.should == true
    end

    it "on the first page of multiple pages of results" do
      @response = mock_response :total => 15, :per_page => 10

      html = render_pagination_info(@response, { :entry_name => 'entry_name' })
      html.should == "Displaying entry_names <b>1 - 10</b> of <b>15</b>"
      html.html_safe?.should == true
    end

    it "on the second page of multiple pages of results" do
      @response = mock_response :total => 47, :per_page => 10, :current_page => 2

      html = render_pagination_info(@response, { :entry_name => 'entry_name' })
      html.should == "Displaying entry_names <b>11 - 20</b> of <b>47</b>"
      html.html_safe?.should == true
    end

    it "on the last page of results" do
      @response = mock_response :total => 47, :per_page => 10, :current_page => 5

      html = render_pagination_info(@response, { :entry_name => 'entry_name' })
      html.should == "Displaying entry_names <b>41 - 47</b> of <b>47</b>"
      html.html_safe?.should == true
    end

  end
end
