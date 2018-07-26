# frozen_string_literal: true

RSpec.describe Blacklight::Facet do
  subject do
    Class.new do
      include Blacklight::Facet
      attr_reader :blacklight_config

      def initialize blacklight_config
        @blacklight_config = blacklight_config
      end
    end.new(blacklight_config)
  end

  let(:blacklight_config) { Blacklight::Configuration.new }

  describe "#facet_configuration_for_field" do
    it "looks up fields by key" do
      blacklight_config.add_facet_field 'a'
      expect(subject.facet_configuration_for_field('a')).to eq blacklight_config.facet_fields['a']
    end

    it "looks up fields by field name" do
      blacklight_config.add_facet_field 'a', field: 'b'
      expect(subject.facet_configuration_for_field('b')).to eq blacklight_config.facet_fields['a']
    end

    it "supports both strings and symbols" do
      blacklight_config.add_facet_field 'a', field: :b
      expect(subject.facet_configuration_for_field('b')).to eq blacklight_config.facet_fields['a']
    end
  end
end
