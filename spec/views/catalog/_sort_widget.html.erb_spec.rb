# frozen_string_literal: true

RSpec.describe "catalog/_sort_widget" do
  let(:blacklight_config) { Blacklight::Configuration.new }
  let(:response) { instance_double(Blacklight::Solr::Response, empty?: false, sort: 'one') }

  before do
    allow(view).to receive_messages(blacklight_config: blacklight_config)
    assign(:response, response)
    controller.request.path_parameters[:action] = 'index'
  end

  context 'with no sort fields configured' do
    it 'renders nothing' do
      render
      expect(rendered).to be_blank
    end
  end

  context 'with a single sort field configured' do
    before do
      blacklight_config.add_sort_field 'one'
    end
    it 'renders nothing' do
      render
      expect(rendered).to be_blank
    end
  end

  context 'with multiple sort fields configured' do
    before do
      blacklight_config.add_sort_field 'one'
      blacklight_config.add_sort_field 'two'
    end
    it 'renders a dropdown with the various options' do
      render
      
      expect(rendered).to have_button 'One'
      expect(rendered).to have_link 'One'
      expect(rendered).to have_link 'Two'
    end
  end
end
