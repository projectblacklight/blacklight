require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "catalog/_facets.html.erb" do
  describe "facet fields" do
    before do
      view.stub!(:facet_field_names) { ['facet_field_1', 'facet_field_2'] }
    end

    it "should have a header" do
      view.should_receive(:render_facet_limit).with('facet_field_1')
      view.should_receive(:render_facet_limit).with('facet_field_2')
      render
      rendered.should have_selector('h2')
    end
  end

  describe "without configured facet fields" do
    before do
      view.stub!(:facet_field_names) { [] }
    end

    it "should not have a header" do
      render
      rendered.should_not have_selector('h2')
    end

  end
end

