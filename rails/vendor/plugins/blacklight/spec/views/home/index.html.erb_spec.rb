require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/home/index.html.erb" do

  before(:each) do
    @catalog = mock('mock_cat')
    @catalog.stub!(:total_pages).and_return(0)
    assigns[:catalog] = @catalog

    @controller.template.should_receive(:render).with(:partial => "catalog/facets")

    render 'home/index'
  end

  it "should have search form div with id 'search'" do
    response.should have_tag("div[id=search]")
  end  
end
