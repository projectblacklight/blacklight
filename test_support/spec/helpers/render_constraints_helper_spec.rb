require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RenderConstraintsHelper do

  before do
    ## Pretend that we're in a controller at /advanced_search
    Journey::Route.any_instance.stub(:format).and_return('/advanced_search')
  end
  describe '#render_constraints_query' do
    it "should have a link relative to the current url" do
      helper.render_constraints_query(:q=>'foobar', :f=>{:type=>'journal'}).should have_selector "a[href='/advanced_search?f%5Btype%5D=journal']"
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
      result.first.should have_selector "a[href='/advanced_search?&q=biz']"
    end
  end

end
