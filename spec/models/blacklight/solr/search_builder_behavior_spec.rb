# frozen_string_literal: true

RSpec.describe Blacklight::Solr::SearchBuilderBehavior, :api do
  subject { search_builder.with(user_params) }

  let(:single_facet) { { format: ['Book'] } }
  let(:search_builder_class) do
    Class.new(Blacklight::SearchBuilder) do
      include Blacklight::Solr::SearchBuilderBehavior
    end
  end
  let(:search_builder) { search_builder_class.new(context) }
  let(:multi_facets) { { format: ['Book'], language_ssim: ['Tibetan'] } }
  let(:mult_word_query) { 'tibetan history' }
  let(:subject_search_params) { { commit: "search", search_field: "subject", action: "index", controller: "catalog", rows: "10", q: "wome" } }

  let(:blacklight_config) { CatalogController.blacklight_config.deep_copy }
  let(:user_params) { {} }
  let(:context) { CatalogController.new }

  before { allow(context).to receive(:blacklight_config).and_return(blacklight_config) }

  context "with default processor chain" do
    subject { search_builder }

    it "uses the class-level default_processor_chain" do
      expect(subject.processor_chain).to eq search_builder_class.default_processor_chain
    end
  end

  context 'with merged parameters from the defaults + the search field' do
    before do
      blacklight_config.default_solr_params = { json: { whatever: [1, 2, 3] } }
      blacklight_config.search_fields['all_fields'].solr_parameters = { json: { and_also: [4, 5, 6] } }
    end

    let(:user_params) { { search_field: 'all_fields' } }

    it 'deep merges hash values' do
      expect(subject.to_hash.dig(:json, :whatever)).to eq [1, 2, 3]
      expect(subject.to_hash.dig(:json, :and_also)).to eq [4, 5, 6]
    end
  end

  context "with a complex parameter environment" do
    subject { search_builder.with(user_params).send(:processed_parameters) }

    let(:user_params) do
      { :search_field => "test_field", :q => "test query", "facet.field" => "extra_facet" }
    end

    let(:blacklight_config) do
      Blacklight::Configuration.new.tap do |config|
        config.add_search_field("test_field",
                                display_label: "Test",
                                key: "test_field",
                                solr_parameters: {
                                  qf: "fieldOne^2.3 fieldTwo fieldThree^0.4",
                                  pf: "",
                                  spellcheck: 'false',
                                  sort: "request_params_sort"
                                })
      end
    end

    it "merges parameters from search_field definition" do
      expect(subject[:qf]).to eq "fieldOne^2.3 fieldTwo fieldThree^0.4"
      expect(subject[:spellcheck]).to eq 'false'
    end

    it "merges empty string parameters from search_field definition" do
      expect(subject[:pf]).to eq ""
    end

    describe "should respect proper precedence of settings," do
      it "does not put :search_field in produced params" do
        expect(subject[:search_field]).to be_nil
      end

      it "falls through to BL general defaults for qt not otherwise specified" do
        expect(subject[:qt]).to eq blacklight_config[:default_solr_params][:qt]
      end

      it "takes q from request params" do
        expect(subject[:q]).to eq "test query"
      end
    end
  end

  # SPECS for actual search parameter generation
  describe "#processed_parameters" do
    subject do
      search_builder.with(user_params).send(:processed_parameters)
    end

    context "when search_params_logic is customized" do
      let(:search_builder) { search_builder_class.new(method_chain, context) }
      let(:method_chain) { [:add_foo_to_solr_params] }

      it "allows customization of search_params_logic" do
        allow(search_builder).to receive(:add_foo_to_solr_params) do |solr_params, _user_params|
          solr_params[:wt] = "TESTING"
        end

        expect(subject[:wt]).to eq "TESTING"
      end
    end

    it "generates a facet limit" do
      expect(subject[:'f.subject_ssim.facet.limit']).to eq 21
    end

    context 'with a negative facet limit' do
      before do
        blacklight_config.facet_fields['subject_ssim'].limit = -1
      end

      it 'is negative' do
        expect(subject[:'f.subject_ssim.facet.limit']).to eq(-1)
      end
    end

    context 'with a facet limit set to 0' do
      before do
        blacklight_config.facet_fields['subject_ssim'].limit = 0
      end

      it 'is negative' do
        expect(subject[:'f.subject_ssim.facet.limit']).to eq 0
      end
    end

    it "handles no facet_limits in config" do
      blacklight_config.facet_fields = {}
      expect(subject).not_to have_key(:'f.subject_ssim.facet.limit')
    end

    describe "with max per page enforced" do
      let(:blacklight_config) do
        Blacklight::Configuration.new.tap do |config|
          config.max_per_page = 123
        end
      end

      let(:user_params) { { per_page: 98_765 } }

      it "enforces max_per_page against all parameters" do
        expect(blacklight_config.max_per_page).to eq 123
        expect(subject[:rows]).to eq 123
      end
    end

    context "facet parameters" do
      let(:blacklight_config) do
        Blacklight::Configuration.new.tap do |config|
          config.add_facet_field key: 'param_key', field: 'solr_field', limit: 50, ex: 'other'

          config.add_facet_fields_to_solr_request!
        end
      end

      it "uses the configured solr field name in queries" do
        expect(subject).to include 'f.solr_field.facet.limit': 51,
                                   'facet.field': ['{!ex=other}solr_field']
      end
    end

    describe 'for an entirely empty search' do
      it 'does not have a q param' do
        expect(subject[:q]).to be_nil
        expect(subject["spellcheck.q"]).to be_nil
      end

      it 'has default rows' do
        expect(subject[:rows]).to eq 10
      end

      it 'has default facet fields' do
        # remove local params from the facet.field
        expect(subject[:'facet.field'].map { |x| x.gsub(/\{![^}]+\}/, '') }).to match_array %w[format subject_ssim pub_date_ssim language_ssim lc_1letter_ssim subject_geo_ssim subject_era_ssim]
      end

      it "does not have a default qt" do
        expect(subject[:qt]).to be_nil
      end

      it "has no fq" do
        expect(subject[:phrase_filters]).to be_blank
        expect(subject[:fq]).to be_blank
      end
    end

    describe "for a missing string search" do
      let(:user_params) { { q: nil } }

      it "does not populate the q parameter in solr parameters" do
        expect(subject).not_to have_key :q
      end
    end

    describe "for an empty string search" do
      let(:user_params) { { q: "" } }

      it "returns empty string q in solr parameters" do
        expect(subject[:q]).to eq ""
      end
    end

    describe "for request params also passed in as argument" do
      let(:user_params) { { 'q' => 'another value', q: "some query" } }

      it "only has one value for the key 'q' regardless if a symbol or string" do
        expect(subject[:q]).to eq 'some query'
        expect(subject['q']).to eq 'some query'
      end
    end

    describe "for one facet, no query" do
      let(:user_params) { { f: single_facet } }

      it "has proper solr parameters" do
        expect(subject[:q]).to be_blank
        expect(subject["spellcheck.q"]).to be_blank

        single_facet.each_value do |value|
          value.each do |v|
            expect(subject[:fq]).to include("{!term f=#{single_facet.keys[0]}}#{v}")
          end
        end
      end
    end

    describe "for an empty facet limit param" do
      let(:user_params) { { f: { "format" => [""] } } }

      it "does not add any fq to solr" do
        expect(subject[:fq]).to be_blank
      end
    end

    describe "with Multi Facets, No Query" do
      let(:user_params) { { f: multi_facets } }

      it 'has fq set properly' do
        multi_facets.each_pair do |facet_field, value_list|
          value_list ||= []
          value_list = [value_list] unless value_list.respond_to? :each
          value_list.each do |value|
            expect(subject[:fq]).to include("{!term f=#{facet_field}}#{value}")
          end
        end
      end
    end

    describe "with Multi Facets, Multi Word Query" do
      let(:user_params) { { q: mult_word_query, f: multi_facets } }

      it 'has fq and q set properly' do
        multi_facets.each_pair do |facet_field, value_list|
          value_list ||= []
          value_list = [value_list] unless value_list.respond_to? :each
          value_list.each do |value|
            expect(subject[:fq]).to include("{!term f=#{facet_field}}#{value}")
          end
        end
        expect(subject[:q]).to eq mult_word_query
      end
    end

    describe 'with a facet with a custom filter query builder' do
      let(:user_params) { { f: { some: ['value'] } }.with_indifferent_access }

      before do
        blacklight_config.add_facet_field 'some', filter_query_builder: (lambda do |*_args|
          ['some:filter', { qq1: 'abc' }]
        end)
      end

      it "has proper solr parameters" do
        expect(subject[:fq]).to include('some:filter')
        expect(subject[:qq1]).to include('abc')
      end
    end

    context 'with a facet with a custom filter query builder that returns multiple values' do
      let(:user_params) { { f: { some: ['value'] } }.with_indifferent_access }

      before do
        blacklight_config.add_facet_field 'some', filter_query_builder: (lambda do |*_args|
          [['some:filter', 'another:filter'], { qq1: 'abc' }]
        end)
      end

      it "has proper solr parameters" do
        expect(subject[:fq]).to include('some:filter', 'another:filter')
        expect(subject[:qq1]).to include('abc')
      end
    end

    describe 'with a json facet' do
      let(:user_params) { { f: { json_facet: ['value'] } }.with_indifferent_access }

      before do
        blacklight_config.add_facet_field 'json_facet', field: 'foo', json: { bar: 'baz' }
      end

      it "has proper solr parameters" do
        expect(subject[:fq]).to include('{!term f=foo}value')
        expect(subject.dig(:json, :facet, 'json_facet')).to include(
          field: 'foo',
          type: 'terms',
          bar: 'baz'
        )
      end
    end

    describe 'with multi-valued facets' do
      let(:user_params) { { f_inclusive: { format: %w[Book Movie CD] } } }

      it "has proper solr parameters" do
        expect(subject[:fq]).to include('{!lucene}{!query v=$f_inclusive.format.0} OR {!query v=$f_inclusive.format.1} OR {!query v=$f_inclusive.format.2}')
        expect(subject['f_inclusive.format.0']).to eq '{!term f=format}Book'
        expect(subject['f_inclusive.format.1']).to eq '{!term f=format}Movie'
        expect(subject['f_inclusive.format.2']).to eq '{!term f=format}CD'
      end
    end

    describe "solr parameters for a field search from config (subject)" do
      let(:user_params) { subject_search_params }

      before do
        # The tests below expect pre-solr-7.2 queries with local params
        blacklight_config.search_fields['subject'].solr_local_parameters = {
          qf: '$subject_qf',
          pf: '$subject_pf'
        }
        blacklight_config.search_fields['subject'].clause_params = nil
      end

      it "looks up qt from field definition" do
        expect(subject[:qt]).to eq "search"
      end

      it "does not include weird keys not in field definition" do
        expect(subject[:phrase_filters]).to be_nil
        expect(subject[:commit]).to be_nil
        expect(subject[:action]).to be_nil
        expect(subject[:controller]).to be_nil
      end

      it "includes proper 'q', possibly with LocalParams" do
        expect(subject[:q]).to match(/(\{[^}]+\})?wome/)
      end

      it "includes proper 'q' when LocalParams are used" do
        if /\{[^}]+\}/.match?(subject[:q])
          expect(subject[:q]).to match(/\{[^}]+\}wome/)
        end
      end

      it "includes spellcheck.q, without LocalParams" do
        expect(subject["spellcheck.q"]).to eq "wome"
      end

      it "includes spellcheck.dictionary from field def solr_parameters" do
        expect(subject[:'spellcheck.dictionary']).to eq "subject"
      end

      it "adds on :solr_local_parameters using Solr LocalParams style" do
        # q == "{!pf=$subject_pf $qf=subject_qf} wome", make sure
        # the LocalParams are really there
        subject[:q] =~ /^\{!([^}]+)\}/
        key_value_pairs = Regexp.last_match(1).split
        expect(key_value_pairs).to include("pf=$subject_pf")
        expect(key_value_pairs).to include("qf=$subject_qf")
      end

      context 'when subject field uses JSON query DSL' do
        before do
          blacklight_config.search_fields['subject'].clause_params = {
            edismax: {}
          }
        end

        it "includes spellcheck.q, without LocalParams" do
          expect(subject["spellcheck.q"]).to eq "wome"
        end
      end
    end

    describe "solr json query parameters from the fielded search" do
      let(:user_params) { subject_search_params }

      before do
        blacklight_config.search_fields['subject'].solr_parameters = {
          some: :parameter
        }

        blacklight_config.search_fields['subject'].clause_params = {
          edismax: {
            another: :parameter
          }
        }
      end

      it 'sets solr parameters from the field' do
        expect(subject[:some]).to eq :parameter
      end

      it 'does not set a q parameter' do
        expect(subject).not_to have_key :q
      end

      it 'includes the user query in the JSON query DSL request' do
        expect(subject.dig(:json, :query, :bool, :must, 0, :edismax)).to include query: 'wome'
      end

      it 'includes addtional clause parameters for the field' do
        expect(subject.dig(:json, :query, :bool, :must, 0, :edismax)).to include another: :parameter
      end

      context 'with an empty search' do
        let(:subject_search_params) { { commit: "search", search_field: "subject", action: "index", controller: "catalog", rows: "10", q: nil } }

        it 'does not add nil query value clauses to json query' do
          expect(subject).not_to have_key :json
        end
      end
    end

    describe "sorting" do
      context 'when the user has not provided a value' do
        it 'sends the default sort parameter to solr' do
          expect(subject[:sort]).to eq 'score desc, pub_date_si desc, title_si asc'
        end
      end

      context "when the configured sort field is blank" do
        before do
          blacklight_config.sort_fields = {}
          blacklight_config.add_sort_field('', label: 'test')
        end

        it "does not send a sort parameter to solr if the sort value is blank" do
          expect(subject).not_to have_key(:sort)
        end
      end

      context "when the user provides a valid sort parmeter" do
        let(:user_params) { { sort: 'title_si asc, pub_date_si desc' } }

        it "passes them through" do
          expect(subject[:sort]).to eq 'title_si asc, pub_date_si desc'
        end
      end

      context "when the user provides a valid customized sort parmeter" do
        let(:user_params) { { sort: 'year-desc' } }

        it "passes solr sort paramters through" do
          expect(subject[:sort]).to eq 'pub_date_si desc, title_si asc'
        end
      end

      context "when the user provides an invalid sort parameter" do
        let(:user_params) { { sort: 'bad' } }

        it "removes them" do
          expect(subject).not_to have_key(:sort)
        end
      end
    end

    describe "for :solr_local_parameters config" do
      let(:blacklight_config) do
        config = Blacklight::Configuration.new
        config.add_search_field(
          "custom_author_key",
          display_label: "Author",
          qt: "author_qt",
          key: "custom_author_key",
          solr_local_parameters: {
            qf: "$author_qf",
            pf: "you'll have \" to escape this",
            pf2: "$pf2_do_not_escape_or_quote"
          },
          solr_parameters: {
            qf: "someField^1000",
            ps: "2"
          }
        )
        return config
      end

      let(:user_params) { { search_field: "custom_author_key", q: "query" } }

      it "passes through ordinary params" do
        expect(subject[:qt]).to eq "author_qt"
        expect(subject[:ps]).to eq "2"
        expect(subject[:qf]).to eq "someField^1000"
      end

      it "includes include local params with escaping" do
        expect(subject[:q]).to include('qf=$author_qf')
        expect(subject[:q]).to include('pf=\'you\\\'ll have \\" to escape this\'')
        expect(subject[:q]).to include('pf2=$pf2_do_not_escape_or_quote')
      end
    end

    describe 'the search field query_builder config' do
      let(:blacklight_config) do
        Blacklight::Configuration.new do |config|
          config.add_search_field('built_query', query_builder: ->(builder, *_args) { [builder.blacklight_params[:q].reverse, { qq1: 'xyz' }] })
        end
      end

      let(:user_params) { { search_field: 'built_query', q: 'value' } }

      it 'uses the provided query builder' do
        expect(subject[:q]).to eq 'eulav'
        expect(subject[:qq1]).to eq 'xyz'
      end
    end
  end

  describe "#add_facets_for_advanced_search_form" do
    let(:solr_parameters) { Blacklight::Solr::Request.new }
    let(:mock_controller) { instance_double(CatalogController, action_name: 'advanced_search') }
    let(:mock_search_state) { instance_double(Blacklight::SearchState, controller: mock_controller) }

    before do
      allow(search_builder).to receive(:search_state).and_return(mock_search_state)
    end

    context "when action is advanced_search and form_solr_parameters are configured" do
      before do
        blacklight_config.advanced_search.enabled = true
        blacklight_config.advanced_search.form_solr_parameters = {
          'facet.sort' => 'count',
          'facet.field' => %w[format subject_ssim],
          'f.format.facet.limit' => -1,
          'f.subject_ssim.facet.limit' => -1
        }
      end

      it "merges advanced search form parameters into solr parameters" do
        solr_parameters['existing.param'] = 'keep_me'
        subject.add_facets_for_advanced_search_form(solr_parameters)

        expect(solr_parameters['facet.sort']).to eq 'count'
        expect(solr_parameters['facet.field']).to eq %w[format subject_ssim]
        expect(solr_parameters['f.format.facet.limit']).to eq(-1)
        expect(solr_parameters['f.subject_ssim.facet.limit']).to eq(-1)
        expect(solr_parameters['existing.param']).to eq 'keep_me'
      end
    end

    context "when action is not advanced_search" do
      before do
        allow(mock_controller).to receive(:action_name).and_return('index')
        blacklight_config.advanced_search.enabled = true
        blacklight_config.advanced_search.form_solr_parameters = {
          'facet.sort' => 'count',
          'facet.field' => ['format']
        }
      end

      it "does not merge advanced search form parameters" do
        solr_parameters['f.format.facet.limit'] = 21

        subject.add_facets_for_advanced_search_form(solr_parameters)

        expect(solr_parameters['f.format.facet.limit']).to eq 21
      end
    end
  end

  describe "#add_facet_fq_to_solr" do
    it "converts a String fq into an Array" do
      solr_parameters = { fq: 'a string' }

      subject.add_facet_fq_to_solr(solr_parameters)

      expect(solr_parameters[:fq]).to be_a Array
    end

    context "facet not defined in config" do
      let(:single_facet) { { unknown_facet_field: "foo" } }
      let(:user_params) { { f: single_facet } }

      it "does not add facet to solr_parameters" do
        solr_parameters = Blacklight::Solr::Request.new
        subject.add_facet_fq_to_solr(solr_parameters)
        expect(solr_parameters[:fq]).to be_blank
      end
    end
  end

  describe "#add_solr_fields_to_query" do
    let(:blacklight_config) do
      Blacklight::Configuration.new do |config|
        config.add_index_field 'an_index_field', solr_params: { 'hl.alternativeField' => 'field_x' }
        config.add_show_field 'a_show_field', solr_params: { 'hl.alternativeField' => 'field_y' }
        config.add_field_configuration_to_solr_request!
      end
    end

    let(:solr_parameters) do
      solr_parameters = Blacklight::Solr::Request.new

      subject.add_solr_fields_to_query(solr_parameters)

      solr_parameters
    end

    it "adds any extra solr parameters from index and show fields" do
      expect(solr_parameters[:'f.an_index_field.hl.alternativeField']).to eq "field_x"
      expect(solr_parameters[:'f.a_show_field.hl.alternativeField']).to eq "field_y"
    end
  end

  describe "#add_facetting_to_solr" do
    let(:blacklight_config) do
      Blacklight::Configuration.new do |config|
        config.add_facet_field 'test_field', sort: 'count'
        config.add_facet_field 'some-query', query: { 'x' => { fq: 'some:query' } }, ex: 'xyz'
        config.add_facet_field 'some-pivot', pivot: %w[a b], ex: 'xyz'
        config.add_facet_field 'some-field', solr_params: { 'facet.mincount' => 15 }
        config.add_facet_fields_to_solr_request!
      end
    end

    let(:solr_parameters) do
      solr_parameters = Blacklight::Solr::Request.new

      subject.add_facetting_to_solr(solr_parameters)

      solr_parameters
    end

    it "adds sort parameters" do
      expect(solr_parameters[:facet]).to be true

      expect(solr_parameters[:'facet.field']).to include('test_field')
      expect(solr_parameters[:'f.test_field.facet.sort']).to eq 'count'
    end

    it "adds facet exclusions" do
      expect(solr_parameters[:'facet.query']).to include('{!ex=xyz}some:query')
      expect(solr_parameters[:'facet.pivot']).to include('{!ex=xyz}a,b')
    end

    it "adds any additional solr_params" do
      expect(solr_parameters[:'f.some-field.facet.mincount']).to eq 15
    end

    describe ":include_in_request" do
      let(:solr_parameters) do
        solr_parameters = Blacklight::Solr::Request.new
        subject.add_facetting_to_solr(solr_parameters)
        solr_parameters
      end

      it "respects the include_in_request parameter" do
        blacklight_config.add_facet_field 'yes_facet', include_in_request: true
        blacklight_config.add_facet_field 'no_facet', include_in_request: false

        expect(solr_parameters[:'facet.field']).to include('yes_facet')
        expect(solr_parameters[:'facet.field']).not_to include('no_facet')
      end

      it "defaults to including facets if add_facet_fields_to_solr_request! was called" do
        blacklight_config.add_facet_field 'yes_facet'
        blacklight_config.add_facet_field 'no_facet', include_in_request: false
        blacklight_config.add_facet_fields_to_solr_request!

        expect(solr_parameters[:'facet.field']).to include('yes_facet')
        expect(solr_parameters[:'facet.field']).not_to include('no_facet')
      end
    end

    describe ":add_facet_fields_to_solr_request!" do
      let(:blacklight_config) do
        config = Blacklight::Configuration.new
        config.add_facet_field 'yes_facet', include_in_request: true
        config.add_facet_field 'no_facet', include_in_request: false
        config.add_facet_field 'maybe_facet'
        config.add_facet_field 'another_facet'
        config
      end

      let(:solr_parameters) do
        solr_parameters = Blacklight::Solr::Request.new
        subject.add_facetting_to_solr(solr_parameters)
        solr_parameters
      end

      it "adds facets to the solr request" do
        blacklight_config.add_facet_fields_to_solr_request!
        expect(solr_parameters[:'facet.field']).to match_array %w[yes_facet maybe_facet another_facet]
      end

      it "does not override field-specific configuration by default" do
        blacklight_config.add_facet_fields_to_solr_request!
        expect(solr_parameters[:'facet.field']).not_to include 'no_facet'
      end

      it "allows white-listing facets" do
        blacklight_config.add_facet_fields_to_solr_request! 'maybe_facet'
        expect(solr_parameters[:'facet.field']).to include 'maybe_facet'
        expect(solr_parameters[:'facet.field']).not_to include 'another_facet'
      end

      it "allows white-listed facets to override any field-specific include_in_request configuration" do
        blacklight_config.add_facet_fields_to_solr_request! 'no_facet'
        expect(solr_parameters[:'facet.field']).to include 'no_facet'
      end
    end
  end

  describe "#with_tag_ex" do
    it "adds an !ex local parameter if the facet configuration requests it" do
      expect(subject.with_ex_local_param("xyz", "some-value")).to eq "{!ex=xyz}some-value"
    end

    it "does not add an !ex local parameter if it isn't configured" do
      expect(subject.with_ex_local_param(nil, "some-value")).to eq "some-value"
    end
  end

  context 'with advanced search clause parameters' do
    let(:user_params) { { op: 'must', clause: { '0': { field: 'title', query: 'the book' }, '1': { field: 'author', query: 'the person' } } } }

    it "has proper solr parameters" do
      expect(subject.to_hash.with_indifferent_access.dig(:json, :query, :bool, :must, 0, :edismax, :query)).to eq 'the book'
      expect(subject.to_hash.with_indifferent_access.dig(:json, :query, :bool, :must, 0, :edismax, :qf)).to eq '${title_qf}'
      expect(subject.to_hash.with_indifferent_access.dig(:json, :query, :bool, :must, 1, :edismax, :query)).to eq 'the person'
      expect(subject.to_hash.with_indifferent_access.dig(:json, :query, :bool, :must, 1, :edismax, :qf)).to eq '${author_qf}'
    end
  end

  describe '#where' do
    let(:user_params) { {} }

    it 'adds additional query filters on the search' do
      subject.where(id: [1, 2, 3])
      expect(subject.to_hash).to include q: '{!lucene}id:(1 OR 2 OR 3)'
    end
  end
end
