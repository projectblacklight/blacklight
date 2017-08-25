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

    context "when thumbnail_field is configured" do
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

    context "without any configured options" do
      it { is_expected.to be_falsey }
    end
  end

  describe "#thumbnail_tag" do
    subject { presenter.thumbnail_tag }
    context "when thumbnail_method is configured" do
      let(:config) do
        Blacklight::OpenStructWithHashAccess.new(thumbnail_method: :xyz)
      end

      context "and the method returns a value" do
        before do
          allow(view_context).to receive_messages(xyz: "some-thumbnail")
        end

        it "calls the provided thumbnail method" do
          expect(view_context).to receive_messages(xyz: "some-thumbnail")
          allow(view_context).to receive(:link_to_document).with(document, "some-thumbnail", {})
            .and_return("link")
          expect(subject).to eq "link"
        end

        context "and url options have :suppress_link" do
          subject { presenter.thumbnail_tag({}, suppress_link: true) }

          it "does not link to the document" do
            expect(subject).to eq "some-thumbnail"
          end
        end
      end

      context "and no value is returned from the thumbnail method" do
        before do
          allow(view_context).to receive_messages(xyz: nil)
        end
        it { is_expected.to be nil }
      end
    end

    context "when thumbnail_field is configured" do
      let(:config) do
        Blacklight::OpenStructWithHashAccess.new(thumbnail_field: :xyz)
      end

      it "creates an image tag from the given field" do
        #allow(document).to receive(:has?).with(:xyz).and_return(true)
        allow(document).to receive(:first).with(:xyz).and_return("http://example.com/some.jpg")
        allow(view_context).to receive(:image_tag).with("http://example.com/some.jpg", {}).and_return('<img src="image.jpg">')
        expect(view_context).to receive(:link_to_document).with(document, '<img src="image.jpg">', {})
        subject
      end

      it "returns nil if no thumbnail is in the document" do
        allow(document).to receive(:first).with(:xyz).and_return(nil)
        expect(subject).to be_nil
      end
    end

    context "when no thumbnail is configured" do
      it { is_expected.to be_nil }
    end
  end
end
