
  describe "should_show_spellcheck_suggestions?" do
    around { |test| Deprecation.silence(Blacklight::BlacklightHelperBehavior) { test.call } }

    before do
      allow(helper).to receive_messages spell_check_max: 5
    end

    it "does not show suggestions if there are enough results" do
      response = double(total: 10)
      expect(helper.should_show_spellcheck_suggestions?(response)).to be false
    end

    it "only shows suggestions if there are very few results" do
      response = double(total: 4, spelling: double(words: [1]))
      expect(helper.should_show_spellcheck_suggestions?(response)).to be true
    end

    it "shows suggestions only if there are spelling suggestions available" do
      response = double(total: 4, spelling: double(words: []))
      expect(helper.should_show_spellcheck_suggestions?(response)).to be false
    end

    it "does not show suggestions if spelling is not available" do
      response = double(total: 4, spelling: nil)
      expect(helper.should_show_spellcheck_suggestions?(response)).to be false
    end
  end
