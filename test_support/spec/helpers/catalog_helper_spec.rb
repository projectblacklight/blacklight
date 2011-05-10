require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
describe CatalogHelper do
  include CatalogHelper

  def mock_collection args
    current_page = args[:current_page] || 1
    per_page = args[:per_page] || 10
    total = args[:total]
    arr = (1..total).to_a

    page_results = WillPaginate::Collection.create(current_page, per_page, total) do |pager|
      pager.replace(arr.slice(pager.offset, pager.per_page))
    end
  end
  
  describe "page_entries_info" do
    before(:all) do
    end

    it "with no results" do
      @collection = mock_collection :total => 0

      html = page_entries_info(@collection, { :entry_name => 'entry_name' })
      html.should == "No entry_names found"
      html.html_safe?.should == true
    end

    it "with a single result" do
      @collection = mock_collection :total => 1

      html = page_entries_info(@collection, { :entry_name => 'entry_name' })
      html.should == "Displaying <b>1</b> entry_name"
      html.html_safe?.should == true
    end

    it "with a single page of results" do
      @collection = mock_collection :total => 7

      html = page_entries_info(@collection, { :entry_name => 'entry_name' })
      html.should == "Displaying <b>all 7</b> entry_names"
      html.html_safe?.should == true
    end

    it "on the first page of multiple pages of results" do
      @collection = mock_collection :total => 15, :per_page => 10

      html = page_entries_info(@collection, { :entry_name => 'entry_name' })
      html.should == "Displaying entry_names <b>1 - 10</b> of <b>15</b>"
      html.html_safe?.should == true
    end

    it "on the second page of multiple pages of results" do
      @collection = mock_collection :total => 47, :per_page => 10, :current_page => 2

      html = page_entries_info(@collection, { :entry_name => 'entry_name' })
      html.should == "Displaying entry_names <b>11 - 20</b> of <b>47</b>"
      html.html_safe?.should == true
    end

    it "on the last page of results" do
      @collection = mock_collection :total => 47, :per_page => 10, :current_page => 5

      html = page_entries_info(@collection, { :entry_name => 'entry_name' })
      html.should == "Displaying entry_names <b>41 - 47</b> of <b>47</b>"
      html.html_safe?.should == true
    end

  end
end
