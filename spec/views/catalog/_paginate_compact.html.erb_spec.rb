require 'spec_helper'

describe "catalog/_paginate_compact.html.erb" do

  describe "with a real solr response", :integration => true do  
    def blacklight_config
      @config ||= CatalogController.blacklight_config
    end
    
    def blacklight_config=(config)
      @config = config
    end

    def blacklight_solr
      Blacklight.solr
    end

    def facet_limit_for *args
      0
    end

    include Blacklight::SolrHelper

    it "should render solr responses" do
      solr_response, document_list = get_search_results(:q => '')
      assign :response, solr_response
      render :partial => 'catalog/paginate_compact'
      expect(rendered).to have_selector "a[@rel=next]"
    end
  end

  it "should render paginatable arrays" do
    assign :response, Kaminari.paginate_array([], total_count: 145).page(1).per(10)
    render :partial => 'catalog/paginate_compact'
    expect(rendered).to have_selector "a[@rel=next]"
  end

  it "should render ActiveRecord collections" do
    50.times { b = Bookmark.new;  b.user_id = 1; b.save! }
    assign :response, Bookmark.page(1).per(25)
    render :partial => 'catalog/paginate_compact'
    expect(rendered).to have_selector "a[@rel=next]"
  end
end