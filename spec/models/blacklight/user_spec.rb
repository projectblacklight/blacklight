# frozen_string_literal: true

RSpec.describe "Blacklight::User", :api do
  subject { User.create! email: 'xyz@example.com', password: 'xyz12345' }

  def mock_bookmark document_id
    Bookmark.new document_id: document_id, document_type: SolrDocument.to_s
  end

  describe "#bookmarks_for_documents" do
    before do
      subject.bookmarks << mock_bookmark(1)
      subject.bookmarks << mock_bookmark(2)
      subject.bookmarks << mock_bookmark(3)
    end

    it "returns all the bookmarks that match the given documents" do
      bookmarks = subject.bookmarks_for_documents([SolrDocument.new(id: 1), SolrDocument.new(id: 2)])
      expect(bookmarks).to have(2).items
      expect(bookmarks.first.document_id).to eq "1"
      expect(bookmarks.last.document_id).to eq "2"
    end
  end

  describe "#document_is_bookmarked?" do
    before do
      subject.bookmarks << mock_bookmark(1)
    end

    it "is true if the document is bookmarked" do
      expect(subject).to be_document_is_bookmarked(SolrDocument.new(id: 1))
    end

    it "is false if the document is not bookmarked" do
      expect(subject).not_to be_document_is_bookmarked(SolrDocument.new(id: 2))
    end
  end

  describe "#existing_bookmark_for" do
    before do
      subject.bookmarks << mock_bookmark(1)
    end

    it "returns the bookmark for that document id" do
      expect(subject.existing_bookmark_for(SolrDocument.new(id: 1))).to eq subject.bookmarks.first
    end
  end

  describe '#to_s' do
    it 'is the email by default' do
      expect(subject.to_s).to eq subject.email
    end

    context 'when no email method is provided' do
      let(:old_method) { subject.class.instance_method(:email) }

      before do
        subject.class.send(:undef_method, old_method.name)
      end

      after do
        subject.class.send(:define_method, old_method.name, old_method)
      end

      it 'still provides a string' do
        expect(subject.to_s).to be_a String
      end
    end
  end
end
