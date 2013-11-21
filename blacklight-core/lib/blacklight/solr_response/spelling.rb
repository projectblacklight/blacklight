# A mixin for making access to the spellcheck component data easy.
#
# response.spelling.words
#
module Blacklight::SolrResponse::Spelling

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
            if suggestions.index("correctlySpelled") #if extended results
              i_stop = suggestions.index("correctlySpelled")
            elsif suggestions.index("collation")
              i_stop = suggestions.index("collation")
            else
              i_stop = suggestions.length
            end
              # step through array in 2s to get info for each term
              0.step(i_stop-1, 2) do |i|
                term = suggestions[i]
                term_info = suggestions[i+1]
                # term_info is a hash:
                #   numFound =>
                #   startOffset =>
                #   endOffset =>
                #   origFreq =>
                #   suggestion =>  [{ frequency =>, word => }] # for extended results
                #   suggestion => ['word'] # for non-extended results
                origFreq = term_info['origFreq']
                if suggestions.index("correctlySpelled")
                  word_suggestions << term_info['suggestion'].map do |suggestion|
                    suggestion['word'] if suggestion['freq'] > origFreq
                  end
                else
                  # only extended suggestions have frequency so we just return all suggestions
                  word_suggestions << term_info['suggestion']
                end
              end
          end
        end
        word_suggestions.flatten.compact.uniq
      )
    end

    def collation
      # FIXME: DRY up with words
      spellcheck = self.response[:spellcheck]
        if spellcheck && spellcheck[:suggestions]
          suggestions = spellcheck[:suggestions]
          unless suggestions.nil?
            if suggestions.index("collation")
              suggestions[suggestions.index("collation") + 1]
            end
          end
        end
    end

  end

end

