# A mixin for making access to the spellcheck component data easy.
#
# response.spelling.words
#
module RSolr::Ext::Response::Spelling
  
  def spelling
    @spelling ||= Base.new(self)
  end
  
  class Base
    
    attr :response
    
    def initialize(response)
      @response = response
    end
    
    # returns an array of spelling suggestion for specific query words, 
    # as provided in the solr response.  Only includes words with higher
    # frequency of occurrence than word in original query.
    # can't do a full query suggestion because we only get info for each word;  
    # combination of words may not have results.
    # Thanks to Naomi Dushay!
    def words
      @words ||= (
        word_suggestions = []
        spellcheck = self.response[:spellcheck]
        if spellcheck && spellcheck[:suggestions]
          suggestions = spellcheck[:suggestions]
          unless suggestions.nil?
            # suggestions is an array: 
            #    (query term)
            #    (hash of term info and term suggestion) 
            #    ...
            #    (query term)
            #    (hash of term info and term suggestion) 
            #    'correctlySpelled'
            #    true/false
            #    collation
            #    (suggestion for collation)
            i_stop = suggestions.index("correctlySpelled")
            # step through array in 2s to get info for each term
            0.step(i_stop-1, 2) do |i| 
              term = suggestions[i]
              term_info = suggestions[i+1]
              # term_info is a hash:
              #   numFound =>
              #   startOffset =>
              #   endOffset =>
              #   origFreq =>
              #   suggestion =>  { frequency =>, word => }
              origFreq = term_info['origFreq']
              suggFreq = term_info['suggestion']['frequency'] 
              word_suggestions << term_info['suggestion']['word'] if suggFreq > origFreq
            end
          end
        end
        word_suggestions.uniq
      )
    end
    
  end
  
end