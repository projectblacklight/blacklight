require "spec_helper"

describe Blacklight::SolrResponse::GroupResponse do
  
  let(:response) do
    create_response(sample_response)
  end

  let(:group) do
    response.grouped.select { |x| x.key == "result_group_ssi" }.first
  end

  describe "groups" do
    it "should return an array of Groups" do
      response.grouped.should be_a Array

      expect(group.groups).to have(2).items
      group.groups.each do |group|
        expect(group).to be_a Blacklight::SolrResponse::Group
      end
    end
    it "should include a list of SolrDocuments" do

      group.groups.each do |group|
        group.docs.each do |doc|
          expect(doc).to be_a SolrDocument
        end
      end
    end
  end
  
  describe "total" do
    it "should return the ngroups value" do
      expect(group.total).to eq 3
    end
  end
  
  describe "facets" do
    it "should exist in the response object (not testing, we just extend the module)" do
      expect(group).to respond_to :facets
    end
  end
  
  describe "rows" do
    it "should get the rows from the response" do
      expect(group.rows).to eq 3
    end
  end

  describe "group_field" do
    it "should be the field name for the current group" do
      expect(group.group_field).to eq "result_group_ssi"
    end
  end

  describe "group_limit" do
    it "should be the number of documents to return for a group" do
      expect(group.group_limit).to eq 5
    end
  end
end

def create_response(response, params = {})
  Blacklight::SolrResponse.new(response, params)
end

def sample_response
  {"responseHeader" => {"params" =>{"rows" => 3, "group.limit" => 5}},
   "grouped" => 
     {'result_group_ssi' => 
       {'groups' => [{'groupValue'=>"Group 1", 'doclist'=>{'numFound'=>2, 'docs'=>[{:id=>1}]}},
                     {'groupValue'=>"Group 2", 'doclist'=>{'numFound'=>3, 'docs'=>[{:id=>2}, :id=>3]}}
                    ],
        'ngroups' => "3"
       }
     }
  }
end