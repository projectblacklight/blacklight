# frozen_string_literal: true

RSpec.describe Blacklight::RenderPartialsHelperBehavior do
  around { |test| Deprecation.silence(described_class) { test.call } }

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

    context "an array" do
      let(:value) { %w[one two three] }

      it { is_expected.to eq 'one_two_three' }
    end
  end

  describe "#render_document_partials" do
    let(:doc) { double }

    before do
      allow(helper).to receive_messages(document_partial_path_templates: [])
      allow(helper).to receive_messages(document_index_view_type: 'index_header')
    end

    it "gets the document format from document_partial_name" do
      allow(helper).to receive(:document_partial_name).with(doc, :xyz)
      helper.render_document_partial(doc, :xyz)
    end
  end
end
