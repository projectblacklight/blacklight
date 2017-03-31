# frozen_string_literal: true
# A mixin for making access to the spellcheck component data easy.
#
# response.spelling.words
#
module Blacklight::Solr::Response::Spelling
  def spelling
    @spelling ||= Base.new(self)
  end

  class Base
    attr_reader :response

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
      @words ||= begin
        word_suggestions = []
        spellcheck = self.response[:spellcheck]
        if spellcheck && spellcheck[:suggestions]
          suggestions = spellcheck[:suggestions]
          unless suggestions.nil?
            if suggestions.is_a?(Array)
              # Before solr 6.5 suggestions is an array with the following format:
              #    (query term)
              #    (hash of term info and term suggestion)
              #    ...
              #    (query term)
              #    (hash of term info and term suggestion)
              #    'correctlySpelled'
              #    true/false
              #    collation
              #    (suggestion for collation)
              # We turn it into a hash here so that it is the same format as in solr 6.5 and later
              suggestions = Hash[*suggestions].except('correctlySpelled', 'collation')
            end

            suggestions.each do |_, term_info|
              # term_info is a hash:
              #   numFound =>
              #   startOffset =>
              #   endOffset =>
              #   origFreq =>
              #   suggestion =>  [{ frequency =>, word => }] # for extended results
              #   suggestion => ['word'] # for non-extended results
              orig_freq = term_info['origFreq']
              if term_info['suggestion'].first.is_a?(Hash)
                word_suggestions << term_info['suggestion'].map do |suggestion|
                  suggestion['word'] if suggestion['freq'] > orig_freq
                end
              else
                # only extended suggestions have frequency so we just return all suggestions
                word_suggestions << term_info['suggestion']
              end
            end
          end
        end
        word_suggestions.flatten.compact.uniq
      end
    end

    def collation
      # FIXME: DRY up with words
      spellcheck = self.response[:spellcheck]
      return unless spellcheck && spellcheck[:suggestions]
      suggestions = spellcheck[:suggestions]

      if suggestions.index("collation")
        suggestions[suggestions.index("collation") + 1]
      elsif spellcheck.key?("collations")
        spellcheck['collations'].last
      end
    end
  end
end
