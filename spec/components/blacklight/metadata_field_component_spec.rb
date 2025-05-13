# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::MetadataFieldComponent, type: :component do
  let(:view_context) { vc_test_controller.view_context }
  let(:document) { SolrDocument.new('field' => ['Value']) }
  let(:field_config) { Blacklight::Configuration::Field.new(key: 'field', field: 'field', label: 'Field label') }

  let(:field) do
    Blacklight::FieldPresenter.new(view_context, document, field_config)
  end

  context "from index view" do
    before do
      render_inline(described_class.new(field: field))
    end

    it 'renders the field label' do
      expect(page).to have_css 'dt.blacklight-field', text: 'Field label'
    end

    it 'renders the field value' do
      expect(page).to have_css 'dd.blacklight-field', text: 'Value'
    end
  end

  context 'from a show view' do
    before do
      allow(field).to receive(:label).with('show').and_return('custom label')

      render_inline(described_class.new(field: field, show: true))
    end

    it 'renders the right field label' do
      expect(page).to have_css 'dt.blacklight-field', text: 'custom label'
    end
  end
end
