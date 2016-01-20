# frozen_string_literal: true
require 'spec_helper'

describe Bookmark do
  let(:user) { User.create! email: 'xyz@example.com', password: 'xyz12345'}
  subject do
    b = Bookmark.new(user: user)
    b.document = SolrDocument.new(id: 'u001')
    b
  end

  it "should be valid" do
    expect(subject).to be_valid
  end

  it "should belong to user" do
    expect(Bookmark.reflect_on_association(:user)).not_to be_nil
  end

  it "should be valid after saving" do
    subject.save
    expect(subject).to be_valid
  end
  
  describe "#document_type" do
    it "should be the class of the solr document" do
      expect(subject.document_type).to eq SolrDocument
    end
  end
  
  describe "#document" do
    it "should be a SolrDocument with just an id field" do
      expect(subject.document).to be_a_kind_of SolrDocument
      expect(subject.document.id).to eq 'u001'
    end
  end
end
