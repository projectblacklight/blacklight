# frozen_string_literal: true

RSpec.describe Blacklight::RenderPartialsHelperBehavior do
  describe "#type_field_to_partial_name" do
    subject { helper.send(:type_field_to_partial_name, document, value) }

    let(:document) { double }

    context "with default value" do
      let(:value) { 'default' }

      it { is_expected.to eq 'default' }
    end

    context "with spaces" do
      let(:value) { 'one two three' }

      it { is_expected.to eq 'one_two_three' }
    end

    context "with hyphens" do
      let(:value) { 'one-two-three' }

      it { is_expected.to eq 'one_two_three' }
    end

    context "with an array" do
      let(:value) { %w[one two three] }

      it { is_expected.to eq 'one_two_three' }
    end
  end

  describe "#render_document_partial" do
    let(:doc) { SolrDocument.new(id: 'x') }
    let(:blacklight_config) { Blacklight::Configuration.new }

    before do
      allow(Blacklight.deprecation).to receive(:warn)
      allow(helper).to receive_messages(blacklight_config: blacklight_config, document_index_view_type: :list)
      allow(helper).to receive(:render).and_return('rendered')
    end

    it "is deprecated and renders the document partial component" do
      expect(helper.render_document_partial(doc, :xyz, a: 1)).to eq 'rendered'
      expect(Blacklight.deprecation).to have_received(:warn).with(/render_document_partial is deprecated/)
      expect(helper).to have_received(:render).with(an_instance_of(Blacklight::Document::PartialComponent))
    end
  end

  describe "#render_xml_partials" do
    let(:doc) { SolrDocument.new(id: 'x') }
    let(:blacklight_config) { Blacklight::Configuration.new }

    before do
      allow(Blacklight.deprecation).to receive(:warn)
      allow(helper).to receive_messages(blacklight_config: blacklight_config, document_index_view_type: :list)
    end

    it "renders a document partial component for each partial" do
      allow(helper).to receive(:render).and_return('a', 'b')
      expect(helper.render_xml_partials(doc, %w[one two])).to eq "a\nb"
      expect(helper).to have_received(:render).with(an_instance_of(Blacklight::Document::PartialComponent)).twice
      expect(Blacklight.deprecation).not_to have_received(:warn)
    end

    it "uses an overridden #render_document_partial" do
      allow(helper).to receive(:render_document_partial).and_return('custom')
      expect(helper.render_xml_partials(doc, %w[one])).to eq 'custom'
      expect(helper).to have_received(:render_document_partial).with(doc, 'one', {})
    end
  end

  describe "#document_partial_name" do
    let(:blacklight_config) { Blacklight::Configuration.new }

    before do
      allow(helper).to receive_messages(blacklight_config: blacklight_config, action_name: 'show')
    end

    context "with a solr document with empty fields" do
      let(:document) { SolrDocument.new }

      it "is the default value" do
        expect(helper.send(:document_partial_name, document)).to eq 'default'
      end
    end

    context "with a solr document with the display type field set" do
      let(:document) { SolrDocument.new 'my_field' => 'xyz' }

      before do
        blacklight_config.show.display_type_field = 'my_field'
      end

      it "uses the value in the configured display type field" do
        expect(helper.send(:document_partial_name, document)).to eq 'xyz'
      end

      it "uses the value in the configured display type field if the action-specific field is empty" do
        expect(helper.send(:document_partial_name, document, :some_action)).to eq 'xyz'
      end
    end

    context "with a solr doucment with an action-specific field set" do
      let(:document) { SolrDocument.new 'my_field' => 'xyz', 'other_field' => 'abc' }

      before do
        blacklight_config.show.media_display_type_field = 'my_field'
        blacklight_config.show.metadata_display_type_field = 'other_field'
      end

      it "uses the value in the action-specific fields" do
        expect(helper.send(:document_partial_name, document, :media)).to eq 'xyz'
        expect(helper.send(:document_partial_name, document, :metadata)).to eq 'abc'
      end
    end
  end
end
