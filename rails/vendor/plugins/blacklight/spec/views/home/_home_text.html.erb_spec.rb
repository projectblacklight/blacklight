require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/home/_home_text.html.erb" do
  
  before(:each) do
    render :partial => 'home/home_text'
  end

  it "should have an h3" do
    response.should have_tag("h3")
  end


end
