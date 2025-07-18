# frozen_string_literal: true

require "spec_helper"

RSpec.describe Blacklight::Solr::Response::Group, :api do
  subject do
    group.groups.first
  end

  let(:search_builder) do
    Blacklight::SearchBuilder.new(view_context)
  end

  let(:view_context) do
    double("View context", blacklight_config: CatalogController.blacklight_config.deep_copy)
  end

  let(:response) do
    Blacklight::Solr::Response.new(sample_response, search_builder)
  end

  let(:group) do
    response.grouped.find { |x| x.key == "result_group_ssi" }
  end

  describe "#doclist" do
    it "is the raw list of documents from solr" do
      expect(subject.doclist).to be_a Hash
      expect(subject.doclist['docs'].first[:id]).to eq 1
    end
  end

  describe "#total" do
    it "is the number of results found in a group" do
      expect(subject.total).to eq 2
    end
  end

  describe "#start" do
    it "is the offset for the results in the group" do
      expect(subject.start).to eq 0
    end
  end

  describe "#docs" do
    it "is a list of SolrDocuments" do
      subject.docs.each do |doc|
        expect(doc).to be_a SolrDocument
      end

      expect(subject.docs.first.id).to eq 1
    end
  end

  describe "#field" do
    it "is the field the group belongs to" do
      expect(subject.field).to eq "result_group_ssi"
    end
  end
end

def sample_response
  { "responseHeader" => { "params" => { "rows" => 3, "group.limit" => 5 } },
    "grouped" =>
     { 'result_group_ssi' =>
       { 'groups' => [{ 'groupValue' => "Group 1", 'doclist' => { 'numFound' => 2, 'start' => 0, 'docs' => [{ id: 1 }, { id: 'x' }] } },
                      { 'groupValue' => "Group 2", 'doclist' => { 'numFound' => 3, 'docs' => [{ id: 2 }, id: 3] } }],
         'ngroups' => "3" } } }
end
