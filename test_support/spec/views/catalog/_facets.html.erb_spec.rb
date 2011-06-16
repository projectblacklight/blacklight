# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/catalog/_facets.html.erb" do
  
  before(:each) do

    # create mock facets to be retrieved from the response
    @solr_item00 = stub("solr_item00")
    @solr_item00.stub!(:value).and_return("val_0_0")
    @solr_item00.stub!(:hits).and_return("90")
    @solr_item01 = stub("solr_item01")
    @solr_item01.stub!(:value).and_return("val_0_1")
    @solr_item01.stub!(:hits).and_return("91")
    @facet0 = stub("facet0")
    @solr_fname0 = Blacklight.config[:facet][:field_names].last
    @facet0.stub!(:name).and_return(@solr_fname0);
    @solr_items0 = [@solr_item00, @solr_item01]
    @facet0.stub!(:items).and_return(@solr_items0);

    @solr_item10 = stub("solr_item10")
    @solr_item10.stub!(:value).and_return("val_1_0")
    @solr_item10.stub!(:hits).and_return("10")
    @solr_item11 = stub("solr_item11")
    @solr_item11.stub!(:value).and_return("val_1_1")
    @solr_item11.stub!(:hits).and_return("11")
    @facet1 = stub("facet1")
    @solr_fname1 = Blacklight.config[:facet][:field_names][1]
    @facet1.stub!(:name).and_return(@solr_fname1);
    @solr_items1 = [@solr_item10, @solr_item11]
    @facet1.stub!(:items).and_return(@solr_items1);

    @solr_item20 = stub("solr_item20")
    @solr_item20.stub!(:value).and_return("val_2_0")
    @solr_item20.stub!(:hits).and_return("20")
    @solr_item21 = stub("solr_item21")
    @solr_item21.stub!(:value).and_return("val_2_1")
    @solr_item21.stub!(:hits).and_return("21")
    @facet2 = stub("facet2")
    @solr_fname2 = Blacklight.config[:facet][:field_names][0]
    @facet2.stub!(:name).and_return(@solr_fname2);
    @solr_items2 = [@solr_item20, @solr_item21]
    @facet2.stub!(:items).and_return(@solr_items2);

    @solr_item30 = stub("solr_item30")
    @solr_item30.stub!(:value).and_return("val_3_0")
    @solr_item30.stub!(:hits).and_return("30")
    @solr_item31 = stub("solr_item31")
    @solr_item31.stub!(:value).and_return("val_3_1")
    @solr_item31.stub!(:hits).and_return("31")
    @facet3 = stub("facet3")
    @solr_fname3 = "solr_field_not_in_initializer_facet"
    @facet3.stub!(:name).and_return(@solr_fname3);
    @solr_items3 = [@solr_item30, @solr_item31]
    @facet3.stub!(:items).and_return(@solr_items3);

    @facets = [@facet0, @facet1, @facet2, @facet3]
    @response.stub!(:facets).and_return(@facets) 

    # one facet is selected
    selected_facet = {@solr_fname1 => [@solr_item10.value]}
    params[:f] = selected_facet

    assigns[:response] = @response    

    render :partial => 'catalog/facets'
  end
    
# There is a problem with link_to and rspec-rails.  See:
#  http://www.nabble.com/Rails:-View-specs-and-implicit-parameters-in-link_to()-td20011051.html
# This spec will run cleanly if the implicit routes are added to the plugin
#  level routes.rb file:   (at the bottom of the file)
#
#  map.connect ':controller/:action/:id'
#  map.connect ':controller/:action/:id.:format'

# If someone can find a better workaround, that would be mega-spiffy.
#
# For now, I am commenting out this spec because I'm not sure if adding those
#  routes will affect anything else.  Similar comments are in routes.rb 
#   - Naomi  2009-04-19

=begin
    
  it "should have div tag with id=facets" do
    response.should have_selector('div[id=facets]')
  end
  
  it "should not have facets that aren't specified in initializer" do
    response.should_not include_text(@solr_fname3)
  end

  it "should skip over facets specified in the initializer that aren't in the response" do
    solr_field = Blacklight.config[:facet][:field_names][2]
    label = Blacklight.config[:facet][:labels][solr_field]
    response.should_not include_text(label)
  end

  it "should have all facets specified in initializer that are included in solr response" do
    solr_field1 = Blacklight.config[:facet][:field_names].last
    response.should include_text(solr_field1)
    
    solr_field2 = Blacklight.config[:facet][:field_names][1]
    response.should include_text(solr_field2)

    solr_field3 = Blacklight.config[:facet][:field_names][0]
    response.should include_text(solr_field3)
  end 

  it "should use the labels specified in initializer" do
    label1 = Blacklight.config[:facet][:labels][@solr_fname0]
    response.should include_text(label1)
    
    label2 = Blacklight.config[:facet][:labels][@solr_fname1]
    response.should include_text(label2)

    label3 = Blacklight.config[:facet][:labels][@solr_fname2]
    response.should include_text(label3)
  end
  
# TODO:  check the display order of the facets.  Naomi can't figure this out
#  it "should display the facets in the order specified in the initializer" do
#    pending
#  end
#
#    output is:
#    <div id="facets">
#      <div>
#        <h3>Format</h3>
#        <ul>
#          <li>Book</li>
#          <li>Online</li>
#        </ul>
#      </div>
#      <div>
#        <h3>Language</h3>
#        <ul>
#          <li>English</li>
#          <li>Urdu/li>
#        </ul>
#      </div>
#    </div>
#
#   can't test for ordering of h3 contents:
#     they are not immediate children of  <div id="facets">
#
#   perhaps use Cucumber?

  
  it "should have values for displayed facets" do
    response.should have_selector("li") do
      with_tag("a", @solr_item00.value)
      with_tag("a", @solr_item01.value)
#      with_tag("a", @solr_item10.value)  # this facet is selected
      with_tag("a", @solr_item11.value)
      with_tag("a", @solr_item20.value)
      with_tag("a", @solr_item21.value)
    end
  end

  it "should have numbers of hits for displayed facets" do
    response.should include_text(@solr_item00.hits)
    response.should include_text(@solr_item01.hits)
    response.should include_text(@solr_item10.hits)
    response.should include_text(@solr_item11.hits)
    response.should include_text(@solr_item20.hits)
    response.should include_text(@solr_item21.hits)
  end
  
  it "should have links to include facet values in solr query" do
    response.should have_selector("a", :text => @solr_item00.value)
    response.should include_text("f%5B"+@solr_fname0 + "%5D%5B%5D=" + @solr_item00.value)
    response.should have_selector("a", :text => @solr_item11.value)
    response.should include_text("f%5B"+@solr_fname1 + "%5D%5B%5D=" + @solr_item11.value)
  end

  it "should display selected facets properly" do
      response.should have_selector("span[class=selected]", :text => /#{@solr_item10.value}/)
  end
  
=end
  
end
