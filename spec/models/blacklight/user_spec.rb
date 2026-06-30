# frozen_string_literal: true

RSpec.describe "Blacklight::User", :api do
  subject { create_user email: 'xyz@example.com', password: 'xyz12345' }

  def mock_bookmark document_id
    Bookmark.new document_id: document_id, document_type: SolrDocument.to_s
  end

  describe ".blacklight_email_column" do
    it "returns the email column the model actually has" do
      expected = User.column_names.include?("email_address") ? :email_address : :email
      expect(User.blacklight_email_column).to eq expected
    end
  end

  describe ".create_guest_user!" do
    it "creates a persisted user with a generated, unique identifier" do
      guest = User.create_guest_user!

      expect(guest).to be_persisted
      expect(guest.public_send(User.blacklight_email_column)).to match(/^guest_.*@example\.com$/)
    end

    it "generates a distinct identifier each time" do
      one = User.create_guest_user!
      two = User.create_guest_user!

      expect(one.public_send(User.blacklight_email_column))
        .not_to eq(two.public_send(User.blacklight_email_column))
    end
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
    it 'is the configured display key by default' do
      display_key = User.column_names.include?("email_address") ? :email_address : :email

      expect(subject.to_s).to eq subject.public_send(display_key)
    end

    context 'when no configured display key method is provided' do
      let(:display_key) { User.column_names.include?("email_address") ? :email_address : :email }
      let(:old_method) { subject.class.instance_method(display_key) }

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
