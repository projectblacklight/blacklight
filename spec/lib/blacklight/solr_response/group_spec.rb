require "spec_helper"

describe Blacklight::SolrResponse::Group do
  
  let(:response) do
    create_response(sample_response)
  end

  let(:group) do
    response.grouped.select { |x| x.key == "result_group_ssi" }.first
  end

  subject do
    group.groups.first
  end

  describe "#doclist" do
    it "should be the raw list of documents from solr" do
      expect(subject.doclist).to be_a Hash
      expect(subject.doclist['docs'].first[:id]).to eq 1
    end
  end

  describe "#total" do
    it "should be the number of results found in a group" do
      expect(subject.total).to eq 2
    end
  end

  describe "#start" do
    it "should be the offset for the results in the group" do
      expect(subject.start).to eq 0
    end
  end

  describe "#docs" do
    it "should be a list of SolrDocuments" do
      subject.docs.each do |doc|
        expect(doc).to be_a_kind_of SolrDocument
      end
    
      expect(subject.docs.first.id).to eq 1
    end
  end

  describe "#field" do
    it "should be the field the group belongs to" do
      expect(subject.field).to eq "result_group_ssi"
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
       {'groups' => [{'groupValue'=>"Group 1", 'doclist'=>{'numFound'=>2, 'start' => 0, 'docs'=>[{:id=>1}, {:id => 'x'}]}},
                     {'groupValue'=>"Group 2", 'doclist'=>{'numFound'=>3, 'docs'=>[{:id=>2}, :id=>3]}}
                    ],
        'ngroups' => "3"
       }
     }
  }
end