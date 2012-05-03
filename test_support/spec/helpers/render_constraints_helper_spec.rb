require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RenderConstraintsHelper do

  before do
    # the helper methods below infer paths from the current route
    controller.request.path_parameters["controller"] = 'catalog'
  end

  describe '#render_constraints_query' do
    it "should have a link relative to the current url" do
      helper.render_constraints_query(:q=>'foobar', :f=>{:type=>'journal'}).should have_selector "a[href='/?f%5Btype%5D=journal']"
    end
  end

  describe '#render_filter_element' do
    before do
      @config = Blacklight::Configuration.new do |config|
        config.add_facet_field 'type'
      end
      helper.stub(:blacklight_config => @config)
    end
    it "should have a link relative to the current url" do
      result = helper.render_filter_element('type', ['journal'], {:q=>'biz'})
      result.size.should == 1
      # I'm not certain how the ampersand gets in there. It's not important.
      result.first.should have_selector "a[href='/?&q=biz']"
    end
  end

end
