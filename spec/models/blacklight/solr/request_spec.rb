# frozen_string_literal: true

RSpec.describe Blacklight::Solr::Request, api: true do
  context 'with some solr parameter keys' do
    before do
      subject[:qt] = 'hey'
      subject[:fq] = ["what's up.", "dood"]
      subject['q'] = "what's"
      subject[:wt] = "going"
      subject[:start] = "on"
      subject[:rows] = "Man"
      subject['hl'] = "I"
      subject['hl.fl'] = "wish"
      subject['group'] = "I"
      subject['defType'] = "had"
      subject['spellcheck'] = "a"
      subject['spellcheck.q'] = "fleece"
      subject['f.title_facet.facet.limit'] = "vest"
    end

    it "accepts valid parameters" do
      expect(subject.to_hash).to eq("defType" => "had",
                                    "f.title_facet.facet.limit" => "vest",
                                    "fq" => ["what's up.", "dood"],
                                    "group" => "I",
                                    "hl" => "I",
                                    "hl.fl" => "wish",
                                    "q" => "what's",
                                    "qt" => "hey",
                                    "rows" => "Man",
                                    "spellcheck" => "a",
                                    "spellcheck.q" => "fleece",
                                    "start" => "on",
                                    "wt" => "going")
    end
  end

  describe '#append_query' do
    it 'populates the q parameter' do
      subject.append_query 'this is my query'
      expect(subject['q']).to eq 'this is my query'
    end

    it 'handles multiple queries by converting it to a boolean query' do
      subject.append_query 'this is my query'
      subject.append_query 'another:query'
      expect(subject).not_to have_key 'q'
      expect(subject.dig('json', 'query', 'bool', 'must')).to match_array ['this is my query', 'another:query']
    end
  end

  describe '#append_boolean_query' do
    it 'populates the boolean query with the queries' do
      subject.append_boolean_query :must, 'required'
      subject.append_boolean_query :should, 'optional'
      subject.append_boolean_query :should, 'also optional'

      expect(subject.dig('json', 'query', 'bool')).to include should: ['optional', 'also optional'], must: ['required']
    end

    it 'converts existing q parameters to a boolean query' do
      subject['q'] = 'some query'
      subject.append_boolean_query :must, 'also required'

      expect(subject.dig('json', 'query', 'bool', 'must')).to match_array ['some query', 'also required']
    end
  end
end
