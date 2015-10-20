require 'spec_helper'

describe RenderConstraintsHelper do

  let(:config) do
    Blacklight::Configuration.new do |config|
      config.add_facet_field 'type'
    end
  end

  before do
    # the helper methods below infer paths from the current route
    controller.request.path_parameters[:controller] = 'catalog'
    allow(helper).to receive(:search_action_path) do |*args|
      catalog_index_path *args
    end
  end

  describe '#render_constraints_query' do
    let(:my_engine) { double("Engine") }
    it "should have a link relative to the current url" do
      expect(helper.render_constraints_query(:q=>'foobar', :f=>{:type=>'journal'})).to have_selector "a[href='/?f%5Btype%5D=journal']"
    end
    it "should accept an optional route set" do
      expect(my_engine).to receive(:url_for).and_return('/?f%5Btype%5D=journal')
      expect(helper.render_constraints_query(:q=>'foobar', :f=>{:type=>'journal'}, :route_set => my_engine)).to have_selector "a[href='/?f%5Btype%5D=journal']"
    end
  end

  describe '#render_filter_element' do
    before do
      allow(helper).to receive(:blacklight_config).and_return(config)
      expect(helper).to receive(:facet_field_label).with('type').and_return("Item Type")
    end
    subject { helper.render_filter_element('type', ['journal'], path) }

    let(:path) { Blacklight::Path.new({:q=>'biz'}, config) }

    it "should have a link relative to the current url" do
      expect(subject).to have_link "Remove constraint Item Type: journal", href: "/catalog?q=biz"
      expect(subject).to have_selector ".filterName", text: 'Item Type'
    end
  end

  describe "#render_constraints_filters" do
    before do
      allow(helper).to receive(:blacklight_config).and_return(config)
    end
    subject { helper.render_constraints_filters(:f=>{'type'=>['']}) }

    it "should render nothing for empty facet limit param" do
      expect(subject).to be_blank
    end
  end
end
