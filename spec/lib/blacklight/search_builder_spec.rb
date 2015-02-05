require 'spec_helper'

describe Blacklight::SearchBuilder do
  let(:single_facet) { { format: 'Book' } }
  let(:multi_facets) { { format: 'Book', language_facet: 'Tibetan' } }
  let(:mult_word_query) { 'tibetan history' }
  let(:subject_search_params) { { commit: "search", search_field: "subject", action: "index", controller: "catalog", rows: "10", q: "wome" } }

  let(:blacklight_config) { CatalogController.blacklight_config.deep_copy }
  let(:method_chain) { CatalogController.solr_search_params_logic }
  let(:user_params) { Hash.new }
  let(:context) { CatalogController.new }

  before { allow(context).to receive(:blacklight_config).and_return(blacklight_config) }

  let(:search_builder) { described_class.new(user_params, method_chain, context) }

  subject { search_builder.processed_parameters }

  context "with a complex parameter environment" do
    let(:user_params) do
      {:search_field => "test_field", :q => "test query", "facet.field" => "extra_facet"}
    end

    let(:blacklight_config) do
      Blacklight::Configuration.new.tap do |config|
        config.add_search_field("test_field",
                           :display_label => "Test",
                           :key=>"test_field",
                           :solr_parameters => {
                             :qf => "fieldOne^2.3 fieldTwo fieldThree^0.4",
                             :pf => "",
                             :spellcheck => 'false',
                             :rows => "55",
                             :sort => "request_params_sort" }
                          )
      end
    end
    it "should merge parameters from search_field definition" do
      expect(subject[:qf]).to eq "fieldOne^2.3 fieldTwo fieldThree^0.4"
      expect(subject[:spellcheck]).to eq 'false'
    end
    it "should merge empty string parameters from search_field definition" do
      expect(subject[:pf]).to eq ""
    end

    describe "should respect proper precedence of settings, " do
      it "should not put :search_field in produced params" do
        expect(subject[:search_field]).to be_nil
      end

      it "should fall through to BL general defaults for qt not otherwise specified " do
        expect(subject[:qt]).to eq blacklight_config[:default_solr_params][:qt]
      end

      it "should take rows from search field definition where specified" do
        expect(subject[:rows]).to eq "55"
      end

      it "should take q from request params" do
        expect(subject[:q]).to eq "test query"
      end

      it "should add in extra facet.field from params" do
        expect(subject[:"facet.field"]).to include("extra_facet")
      end
    end
  end

  # SPECS for actual search parameter generation
  describe "#processed_parameters" do
    context "when search_params_logic is customized" do
      let(:method_chain) { [:add_foo_to_solr_params] }

      it "allows customization of solr_search_params_logic" do
          # Normally you'd include a new module into (eg) your CatalogController
          # but a sub-class defininig it directly is simpler for test.
          allow(context).to receive(:add_foo_to_solr_params) do |solr_params, user_params|
            solr_params[:wt] = "TESTING"
          end

          expect(subject[:wt]).to eq "TESTING"
      end
    end

    it "should generate a facet limit" do
      expect(subject[:"f.subject_topic_facet.facet.limit"]).to eq 21
    end

    it "should handle no facet_limits in config" do
      blacklight_config.facet_fields = {}
      expect(subject).not_to have_key(:"f.subject_topic_facet.facet.limit")
    end

    describe "with max per page enforced" do
      let(:blacklight_config) do
        Blacklight::Configuration.new.tap do |config|
          config.max_per_page = 123
        end
      end

      let(:user_params) { { per_page: 98765 } }
      it "should enforce max_per_page against all parameters" do
        expect(blacklight_config.max_per_page).to eq 123
        expect(subject[:rows]).to eq 123
      end
    end

    describe 'for an entirely empty search' do

      it 'should not have a q param' do
        expect(subject[:q]).to be_nil
        expect(subject["spellcheck.q"]).to be_nil
      end
      it 'should have default rows' do
        expect(subject[:rows]).to eq 10
      end
      it 'should have default facet fields' do
        # remove local params from the facet.field
        expect(subject[:"facet.field"].map { |x| x.gsub(/\{![^}]+\}/, '') }).to match_array ["format", "subject_topic_facet", "pub_date", "language_facet", "lc_1letter_facet", "subject_geo_facet", "subject_era_facet"]
      end

      it "should have default qt"  do
        expect(subject[:qt]).to eq "search"
      end
      it "should have no fq" do
        expect(subject[:phrase_filters]).to be_blank
        expect(subject[:fq]).to be_blank
      end
    end


    describe "for an empty string search" do
      let(:user_params) { { q: "" } }
      it "should return empty string q in solr parameters" do
        expect(subject[:q]).to eq ""
        expect(subject["spellcheck.q"]).to eq ""
      end
    end

    describe "for request params also passed in as argument" do
      let(:user_params) { { q: "some query", 'q' => 'another value' } }
      it "should only have one value for the key 'q' regardless if a symbol or string" do
        expect(subject[:q]).to eq 'some query'
        expect(subject['q']).to eq 'some query'
      end
    end


    describe "for one facet, no query" do
      let(:user_params) { { f: single_facet } }
      it "should have proper solr parameters" do

        expect(subject[:q]).to be_blank
        expect(subject["spellcheck.q"]).to be_blank

        single_facet.each_value do |value|
          expect(subject[:fq]).to include("{!raw f=#{single_facet.keys[0]}}#{value}")
        end
      end
    end

    describe "for an empty facet limit param" do
      let(:user_params) { { f: { "format" => [""] } } }
      it "should not add any fq to solr" do
        expect(subject[:fq]).to be_blank
      end
    end

    describe "with Multi Facets, No Query" do
      let(:user_params) { { f: multi_facets } }
      it 'should have fq set properly' do
        multi_facets.each_pair do |facet_field, value_list|
          value_list ||= []
          value_list = [value_list] unless value_list.respond_to? :each
          value_list.each do |value|
            expect(subject[:fq]).to include("{!raw f=#{facet_field}}#{value}"  )
          end
        end

      end
    end

    describe "with Multi Facets, Multi Word Query" do
      let(:user_params) { { q: mult_word_query, f: multi_facets } }
      it 'should have fq and q set properly' do
        multi_facets.each_pair do |facet_field, value_list|
          value_list ||= []
          value_list = [value_list] unless value_list.respond_to? :each
          value_list.each do |value|
            expect(subject[:fq]).to include("{!raw f=#{facet_field}}#{value}"  )
          end
        end
        expect(subject[:q]).to eq mult_word_query
      end
    end


    describe "solr parameters for a field search from config (subject)" do
      let(:user_params) { subject_search_params }

      it "should look up qt from field definition" do
        expect(subject[:qt]).to eq "search"
      end

      it "should not include weird keys not in field definition" do
        expect(subject[:phrase_filters]).to be_nil
        expect(subject[:fq]).to eq []
        expect(subject[:commit]).to be_nil
        expect(subject[:action]).to be_nil
        expect(subject[:controller]).to be_nil
      end

      it "should include proper 'q', possibly with LocalParams" do
        expect(subject[:q]).to match(/(\{[^}]+\})?wome/)
      end
      it "should include proper 'q' when LocalParams are used" do
        if subject[:q] =~ /\{[^}]+\}/
          expect(subject[:q]).to match(/\{[^}]+\}wome/)
        end
      end
      it "should include spellcheck.q, without LocalParams" do
        expect(subject["spellcheck.q"]).to eq "wome"
      end

      it "should include spellcheck.dictionary from field def solr_parameters" do
        expect(subject[:"spellcheck.dictionary"]).to eq "subject"
      end
      it "should add on :solr_local_parameters using Solr LocalParams style" do
        #q == "{!pf=$subject_pf $qf=subject_qf} wome", make sure
        #the LocalParams are really there
        subject[:q] =~ /^\{!([^}]+)\}/
        key_value_pairs = $1.split(" ")
        expect(key_value_pairs).to include("pf=$subject_pf")
        expect(key_value_pairs).to include("qf=$subject_qf")
      end
    end

    describe "overriding of qt parameter" do
      let(:user_params) do
        { qt: 'overridden' }
      end

      it "should return the correct overriden parameter" do
        expect(subject[:qt]).to eq "overridden"
      end
    end


    describe "sorting" do
      it "should send the default sort parameter to solr" do
        expect(subject[:sort]).to eq 'score desc, pub_date_sort desc, title_sort asc'
      end

      it "should not send a sort parameter to solr if the sort value is blank" do
        blacklight_config.sort_fields = {}
        blacklight_config.add_sort_field('', :label => 'test')

        expect(subject).not_to have_key(:sort)
      end

      context "when the user provides sort parmeters" do
        let(:user_params) { { sort: 'solr_test_field desc' } }
        it "passes them through" do
          expect(subject[:sort]).to eq 'solr_test_field desc'
        end
      end
    end

    describe "for :solr_local_parameters config" do
      let(:blacklight_config) do
        config = Blacklight::Configuration.new
        config.add_search_field(
          "custom_author_key",
          :display_label => "Author",
          :qt => "author_qt",
          :key => "custom_author_key",
          :solr_local_parameters => {
            :qf => "$author_qf",
            :pf => "you'll have \" to escape this",
            :pf2 => "$pf2_do_not_escape_or_quote"
          },
          :solr_parameters => {
            :qf => "someField^1000",
            :ps => "2"
          }
        )
        return config
      end

      let(:user_params) { { search_field: "custom_author_key", q: "query" } }

      it "should pass through ordinary params" do
        expect(subject[:qt]).to eq "author_qt"
        expect(subject[:ps]).to eq "2"
        expect(subject[:qf]).to eq "someField^1000"
      end

      it "should include include local params with escaping" do
        expect(subject[:q]).to include('qf=$author_qf')
        expect(subject[:q]).to include('pf=\'you\\\'ll have \\" to escape this\'')
        expect(subject[:q]).to include('pf2=$pf2_do_not_escape_or_quote')
      end
    end

    describe "mapping facet.field" do
      let(:blacklight_config) do
        Blacklight::Configuration.new do |config|
          config.add_facet_field 'some_field'
          config.add_facet_fields_to_solr_request!
        end
      end

      context "user provides a single facet.field" do
        let(:user_params) { { "facet.field" => "additional_facet" } }
        it "adds the field" do
          expect(subject[:"facet.field"]).to include("additional_facet")
          expect(subject[:"facet.field"]).to have(2).fields
        end
      end

      context "user provides a multiple facet.field" do
        let(:user_params) { { "facet.field" => ["add_facet1", "add_facet2"] } }
        it "adds the fields" do
          expect(subject[:"facet.field"]).to include("add_facet1")
          expect(subject[:"facet.field"]).to include("add_facet2")
          expect(subject[:"facet.field"]).to have(3).fields
        end
      end

      context "user provides a multiple facets" do
        let(:user_params) { { "facets" => ["add_facet1", "add_facet2"] } }
        it "adds the fields" do
          expect(subject[:"facet.field"]).to include("add_facet1")
          expect(subject[:"facet.field"]).to include("add_facet2")
          expect(subject[:"facet.field"]).to have(3).fields
        end
      end
    end
  end
end
