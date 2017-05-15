# frozen_string_literal: true

RSpec.describe Blacklight::ThumbnailPresenter do
  include Capybara::RSpecMatchers
  let(:view_context) { double "View context", document_index_view_type: 'list' }
  let(:config) { Blacklight::Configuration.new }
  let(:view_config) { config.view_config(:index) }
  let(:item_presenter) { Blacklight::IndexPresenter.new(document, view_context, config) }
  let(:presenter) { described_class.new(item_presenter, view_config) }
  let(:document) { SolrDocument.new }

  describe "#exists?" do
    subject { presenter.exists? }

    context "when thumbnail_method is configured" do
      let(:view_config) do
        Blacklight::OpenStructWithHashAccess.new(thumbnail_method: :xyz)
      end
      it { is_expected.to be true }
    end

    context "when thumbnail_field is configured as a single field" do
      let(:view_config) do
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
      let(:view_config) do
        Blacklight::OpenStructWithHashAccess.new(thumbnail_field: [:rst, :uvw, :xyz])
      end

      context "and the field exists in the document" do
        let(:document) { SolrDocument.new('xyz' => 'image.png') }

        it { is_expected.to be true }
      end
    end

    context "when default_thumbnail is configured" do
      let(:view_config) do
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

  describe "#thumbnail_tag" do
    subject { presenter.thumbnail_tag }
    context "when thumbnail_method is configured" do
      let(:view_config) do
        Blacklight::OpenStructWithHashAccess.new(thumbnail_method: :xyz)
      end

      context "and the method returns a value" do
        before do
          allow(view_context).to receive_messages(xyz: "some-thumbnail")
        end

        it "calls the provided thumbnail method" do
          expect(view_context).to receive_messages(xyz: "some-thumbnail")
          allow(item_presenter).to receive(:link_to_document).with("some-thumbnail", {})
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
      let(:view_config) do
        Blacklight::OpenStructWithHashAccess.new(thumbnail_field: :xyz)
      end

      it "creates an image tag from the given field" do
        allow(document).to receive(:first).with(:xyz).and_return("http://example.com/some.jpg")
        allow(view_context).to receive(:image_tag).with("http://example.com/some.jpg", {}).and_return('<img src="image.jpg">')
        expect(item_presenter).to receive(:link_to_document).with('<img src="image.jpg">', {})
        subject
      end

      it "returns nil if no thumbnail is in the document" do
        allow(document).to receive(:first).with(:xyz).and_return(nil)
        expect(subject).to be_nil
      end
    end

    context "when thumbnail_field is configured as an array of fields" do
      let(:view_config) do
        Blacklight::OpenStructWithHashAccess.new(thumbnail_field: [:rst, :uvw, :xyz])
      end

      context "and the field exists in the document" do
        let(:document) { SolrDocument.new(xyz: 'http://example.com/some.jpg') }

        it "creates an image tag from the given field" do
          allow(view_context).to receive(:image_tag).with("http://example.com/some.jpg", {}).and_return('<img src="image.jpg">')
          expect(item_presenter).to receive(:link_to_document).with('<img src="image.jpg">', {}).and_return('<a><img></a>')
          expect(presenter.thumbnail_tag).to eq '<a><img></a>'
        end
      end
    end

    context "when default_thumbnail is configured" do
      context "and is a string" do
        let(:view_config) do
          Blacklight::OpenStructWithHashAccess.new(default_thumbnail: 'image.png')
        end

        it "creates an image tag for the given asset" do
          allow(view_context).to receive(:image_tag).with('image.png', {}).and_return('<img src="image.jpg">')
          expect(presenter.thumbnail_tag({}, suppress_link: true)).to eq '<img src="image.jpg">'
        end
      end

      context "and is a symbol" do
        let(:view_config) do
          Blacklight::OpenStructWithHashAccess.new(default_thumbnail: :get_a_default_thumbnail)
        end

        it "calls that helper method" do
          allow(view_context).to receive(:get_a_default_thumbnail).with(document, {}).and_return('<img src="image.jpg">')
          expect(presenter.thumbnail_tag({}, suppress_link: true)).to eq '<img src="image.jpg">'
        end
      end

      context "and is a proc" do
        let(:view_config) do
          Blacklight::OpenStructWithHashAccess.new(default_thumbnail: lambda { |_, _| '<img src="image.jpg">' })
        end

        it "calls that lambda" do
          expect(presenter.thumbnail_tag({}, suppress_link: true)).to eq '<img src="image.jpg">'
        end
      end
    end

    context "when no thumbnail is configured" do
      it { is_expected.to be_nil }
    end
  end
end
