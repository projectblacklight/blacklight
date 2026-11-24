# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::Document::PartialComponent, type: :component do
  subject(:component) { described_class.new(document: document, base_name: base_name, **attr) }

  let(:attr) { {} }
  let(:base_name) { 'custom' }
  let(:document) { SolrDocument.new(id: 'x', format: format_value) }
  let(:format_value) { nil }
  let(:blacklight_config) { CatalogController.blacklight_config.deep_copy }
  let(:templates) do
    {
      'application/_custom_default.html.erb' => 'default partial for <%= document.id %><%= local_assigns[:extra] %>',
      'application/_custom_book.html.erb' => 'book partial',
      'application/_custom_gallery_default.html.erb' => 'gallery partial'
    }
  end
  let(:view_context) { vc_test_controller.view_context }

  before do
    vc_test_controller.prepend_view_path(ActionView::FixtureResolver.new(templates))
    allow(vc_test_controller).to receive_messages(view_context: view_context, blacklight_config: blacklight_config)
    allow(view_context).to receive_messages(document_index_view_type: :list)
  end

  it 'renders the default partial for the base name' do
    render_inline component

    expect(page).to have_text 'default partial for x'
  end

  context 'with locals' do
    let(:attr) { { locals: { extra: '!!' } } }

    it 'passes the locals through to the partial' do
      render_inline component

      expect(page).to have_text 'default partial for x!!'
    end
  end

  context 'with a document with a display type' do
    let(:format_value) { 'Book' }

    it 'renders the display type specific partial' do
      render_inline component

      expect(page).to have_text 'book partial'
    end
  end

  context 'with a view type specific partial' do
    let(:attr) { { view_type: 'gallery' } }

    it 'renders the view type specific partial' do
      render_inline component

      expect(page).to have_text 'gallery partial'
    end
  end

  context 'when no partial is found' do
    let(:base_name) { 'missing' }

    it 'renders nothing and logs a warning' do
      allow(view_context.logger).to receive(:warn)

      expect(render_inline(component).to_s).to be_blank
      expect(view_context.logger).to have_received(:warn).with(/No template was found for base_name: 'missing'/)
    end
  end

  describe 'choosing a partial by display type' do
    let(:templates) do
      super().merge(
        'application/_custom_one_two_three.html.erb' => 'one_two_three partial',
        'application/_custom_xyz.html.erb' => 'xyz partial',
        'application/_media_xyz.html.erb' => 'media xyz partial',
        'application/_metadata_abc.html.erb' => 'metadata abc partial'
      )
    end

    {
      'one two three' => 'one_two_three',
      'one-two-three' => 'one_two_three',
      %w[one two three] => 'one_two_three'
    }.each do |value, expected|
      context "with a display type of #{value.inspect}" do
        let(:format_value) { value }

        it "renders the #{expected} partial" do
          render_inline component
          expect(page).to have_text "#{expected} partial"
        end
      end
    end

    context 'with a solr document with the display type field set' do
      let(:document) { SolrDocument.new 'my_field' => 'xyz' }

      before do
        blacklight_config.index.display_type_field = 'my_field'
      end

      it 'uses the value in the configured display type field' do
        render_inline component
        expect(page).to have_text 'xyz partial'
      end
    end

    context 'with a solr document with an action-specific field set' do
      let(:document) { SolrDocument.new 'my_field' => 'xyz', 'other_field' => 'abc' }

      before do
        blacklight_config.index.media_display_type_field = 'my_field'
        blacklight_config.index.metadata_display_type_field = 'other_field'
      end

      it 'uses the value in the action-specific fields' do
        render_inline described_class.new(document: document, base_name: :media)
        expect(page).to have_text 'media xyz partial'

        render_inline described_class.new(document: document, base_name: :metadata)
        expect(page).to have_text 'metadata abc partial'
      end
    end
  end

  context 'when an application overrides the legacy helper methods' do
    before do
      allow(Blacklight.deprecation).to receive(:warn)
    end

    it 'uses an overridden #type_field_to_partial_name' do
      allow(view_context).to receive(:type_field_to_partial_name).and_return('book')

      render_inline component

      expect(page).to have_text 'book partial'
      expect(Blacklight.deprecation).to have_received(:warn).with(/type_field_to_partial_name/)
    end

    it 'uses an overridden #document_partial_name' do
      allow(view_context).to receive(:document_partial_name).with(document, base_name).and_return('book')

      render_inline component

      expect(page).to have_text 'book partial'
      expect(Blacklight.deprecation).to have_received(:warn).with(/document_partial_name/)
    end

    it 'uses an overridden #document_partial_path_templates' do
      allow(view_context).to receive(:document_partial_path_templates).and_return(['%{action_name}_gallery_default'])

      render_inline component

      expect(page).to have_text 'gallery partial'
      expect(Blacklight.deprecation).to have_received(:warn).with(/document_partial_path_templates/)
    end
  end
end
