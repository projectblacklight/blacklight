# frozen_string_literal: true

RSpec.describe Blacklight::ThumbnailPresenter do
  include Capybara::RSpecMatchers
  let(:view_context) { double "View context" }
  let(:config) { Blacklight::Configuration.new.view_config(:index) }
  let(:presenter) { described_class.new(document, view_context, config) }
  let(:document) { SolrDocument.new }

  describe "#exists?" do
    subject { presenter.exists? }

    context "when thumbnail_method is configured" do
      let(:config) do
        Blacklight::OpenStructWithHashAccess.new(thumbnail_method: :xyz)
      end

      it { is_expected.to be true }
    end

    context "when thumbnail_field is configured as a single field" do
      let(:config) do
        Blacklight::OpenStructWithHashAccess.new(thumbnail_field: :xyz)
      end

      context "and the field exists in the document" do
        let(:document) { SolrDocument.new('xyz' => 'image.png') }

        it { is_expected.to be true }
      end

      context "and the field is missing from the document" do
        it { is_expected.to be false }
      end
    end

    context "when thumbnail_field is configured as an array of fields" do
      let(:config) do
        Blacklight::OpenStructWithHashAccess.new(thumbnail_field: [:rst, :uvw, :xyz])
      end

      context "and the field exists in the document" do
        let(:document) { SolrDocument.new('xyz' => 'image.png') }

        it { is_expected.to be true }
      end
    end

    context "when default_thumbnail is configured" do
      let(:config) do
        Blacklight::OpenStructWithHashAccess.new(default_thumbnail: 'image.png')
      end

      context "and the field exists in the document" do
        it { is_expected.to be true }
      end
    end

    context "without any configured options" do
      it { is_expected.to be_falsey }
    end
  end
end
