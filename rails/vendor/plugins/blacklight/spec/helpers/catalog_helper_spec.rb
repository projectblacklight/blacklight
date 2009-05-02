require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe CatalogHelper do
  include CatalogHelper
  
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
        "<a href='http://www.example.com' onclick=\"var f = document.createElement('form'); f.style.display = 'none'; this.parentNode.appendChild(f); f.method = 'POST'; f.action = this.href;var d = document.createElement('input'); d.setAttribute('type', 'hidden'); d.setAttribute('name', 'key'); d.setAttribute('value', 'value'); f.appendChild(d);var m = document.createElement('input'); m.setAttribute('type', 'hidden'); m.setAttribute('name', '_method'); m.setAttribute('value', 'put'); f.appendChild(m);f.submit();return false;\">Foo</a>",
        link_to_with_data("Foo", "http://www.example.com", :method => :put, :data => {:key => "value"})
      )
    end
  end
end