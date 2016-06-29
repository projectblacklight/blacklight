# frozen_string_literal: true
require 'spec_helper'

describe Bookmark do
  let(:user) { User.create! email: 'xyz@example.com', password: 'xyz12345'}
  subject do
    b = Bookmark.new(user: user)
    b.document = SolrDocument.new(id: 'u001')
    b
  end

  it "is valid" do
    expect(subject).to be_valid
  end

  it "belongs to user" do
    expect(Bookmark.reflect_on_association(:user)).not_to be_nil
  end

  it "is valid after saving" do
    subject.save
    expect(subject).to be_valid
  end
  
  describe "#document_type" do
    it "is the class of the solr document" do
      expect(subject.document_type).to eq SolrDocument
    end
  end
  
  describe "#document" do
    it "is a SolrDocument with just an id field" do
      expect(subject.document).to be_a_kind_of SolrDocument
      expect(subject.document.id).to eq 'u001'
    end
  end
end
