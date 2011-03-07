require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
describe CatalogHelper do
  include CatalogHelper

  class MockResponse
    attr_reader :total

    def initialize args
      @total = args[:total]
    end
  end

#  In case RSolr's duck typing diverages from WillPaginate::Collection  
  class MockCollection
    attr_reader :current_page, :per_page

    def initialize args
      @current_page= args[:current_page] || 1
      @total = args[:total] || 0
      @per_page = args[:per_page] || 10
    end  

    def previous_page
      [@current_page - 1, 1].max
    end

    def next_page
      @current_page + 1
    end

    def total_pages
      (@total.to_f / @per_page).ceil 
    end

    def size
      return @per_page unless @current_page * @per_page > @total
      @total % @per_page 
    end
  end

  def mock_collection args
    current_page = args[:current_page] || 1
    per_page = args[:per_page] || 10
    total = args[:total]
    arr = (1..total).to_a

    page_results = WillPaginate::Collection.create(current_page, per_page, total) do |pager|
      pager.replace(arr)
    end
  end
  
  describe "page_entries_info" do
    before(:all) do
    end

    it "with no results" do
      @response = MockResponse.new :total => 0
      @collection = MockCollection.new :total => @response.total

      page_entries_info(@collection, { :entry_name => 'entry_name' }).should == "No entry_names found"
    end

    it "with a single result" do
      @response = MockResponse.new :total => 1
      @collection = MockCollection.new :total => @response.total

      page_entries_info(@collection, { :entry_name => 'entry_name' }).should == "Displaying <b>1</b> entry_name"
    end

    it "with a single page of results" do
      @response = MockResponse.new :total => 7
      @collection = MockCollection.new :total => @response.total

      page_entries_info(@collection, { :entry_name => 'entry_name' }).should == "Displaying <b>all 7</b> entry_names"
    end

    it "on the first page of multiple pages of results" do
      @response = MockResponse.new :total => 15
      @collection = MockCollection.new :total => @response.total, :per_page => 10

      page_entries_info(@collection, { :entry_name => 'entry_name' }).should == "Displaying entry_names <b>1 - 10</b> of <b>15</b>"
    end

    it "on the second page of multiple pages of results" do
      @response = MockResponse.new :total => 47
      @collection = MockCollection.new :total => @response.total, :per_page => 10, :current_page => 2

      page_entries_info(@collection, { :entry_name => 'entry_name' }).should == "Displaying entry_names <b>11 - 20</b> of <b>47</b>"
    end

    it "on the last page of results" do
      @response = MockResponse.new :total => 47
      @collection = MockCollection.new :total => @response.total, :per_page => 10, :current_page => 5

      page_entries_info(@collection, { :entry_name => 'entry_name' }).should == "Displaying entry_names <b>41 - 47</b> of <b>47</b>"
    end

  end
end
