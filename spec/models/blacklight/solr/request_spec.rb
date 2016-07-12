# frozen_string_literal: true

describe Blacklight::Solr::Request do
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
    subject['facet.field'] = [] 
  end
  it "should accept valid parameters" do
    expect(subject.to_hash).to eq({"defType" => "had",
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
       "wt" => "going"
    })
  end

end
