# frozen_string_literal: true

RSpec.describe Blacklight::Solr::SearchBuilderBehavior do
  let(:single_facet) { { format: 'Book' } }
  let(:multi_facets) { { format: 'Book', language_facet: 'Tibetan' } }
  let(:mult_word_query) { 'tibetan history' }
  let(:subject_search_params) { { commit: "search", search_field: "subject", action: "index", controller: "catalog", rows: "10", q: "wome" } }

  let(:blacklight_config) { CatalogController.blacklight_config.deep_copy }
  let(:user_params) { Hash.new }
  let(:context) { CatalogController.new }

  before { allow(context).to receive(:blacklight_config).and_return(blacklight_config) }

  let(:search_builder_class) do
    Class.new(Blacklight::SearchBuilder) do
      include Blacklight::Solr::SearchBuilderBehavior
    end
  end
  let(:search_builder) { search_builder_class.new(context) }

  subject { search_builder.with(user_params) }

  context "with default processor chain" do
    subject { search_builder }
    it "uses the class-level default_processor_chain" do
      expect(subject.processor_chain).to eq search_builder_class.default_processor_chain
    end
  end

  context "with a complex parameter environment" do
    subject { search_builder.with(user_params).processed_parameters }

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

      it "should take q from request params" do
        expect(subject[:q]).to eq "test query"
      end
    end
  end

  # SPECS for actual search parameter generation
  describe "#processed_parameters" do
    subject do
      search_builder.with(user_params).processed_parameters
    end

    context "when search_params_logic is customized" do
      let(:search_builder) { search_builder_class.new(method_chain, context) }
      let(:method_chain) { [:add_foo_to_solr_params] }

      it "allows customization of search_params_logic" do
          allow(search_builder).to receive(:add_foo_to_solr_params) do |solr_params, user_params|
            solr_params[:wt] = "TESTING"
          end

          expect(subject[:wt]).to eq "TESTING"
      end
    end

    it "should generate a facet limit" do
      expect(subject[:"f.subject_topic_facet.facet.limit"]).to eq 21
    end

    context 'with a negative facet limit' do
      before do
        blacklight_config.facet_fields['subject_topic_facet'].limit = -1
      end

      it 'is negative' do
        expect(subject[:"f.subject_topic_facet.facet.limit"]).to eq -1
      end
    end

    context 'with a facet limit set to 0' do
      before do
        blacklight_config.facet_fields['subject_topic_facet'].limit = 0
      end

      it 'is negative' do
        expect(subject[:"f.subject_topic_facet.facet.limit"]).to eq 0
      end
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

    context "facet parameters" do
      let(:blacklight_config) do
        Blacklight::Configuration.new.tap do |config|
          config.add_facet_field key: 'param_key', field: 'solr_field', limit: 50, ex: 'other'

          config.add_facet_fields_to_solr_request!
        end
      end

      it "should use the configured solr field name in queries" do
        expect(subject).to include 'f.solr_field.facet.limit': 51,
                                   'facet.field': ['{!ex=other}solr_field']
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

      it "should not have a default qt"  do
        expect(subject[:qt]).to be_nil
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
          expect(subject[:fq]).to include("{!term f=#{single_facet.keys[0]}}#{value}")
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
            expect(subject[:fq]).to include("{!term f=#{facet_field}}#{value}"  )
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
            expect(subject[:fq]).to include("{!term f=#{facet_field}}#{value}"  )
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
    end
  end

  
  describe "#facet_value_to_fq_string" do
    it "should use the configured field name" do
      blacklight_config.add_facet_field :facet_key, field: "facet_name"
      expect(subject.send(:facet_value_to_fq_string, "facet_key", "my value")).to eq "{!term f=facet_name}my value"
    end

    it "should use the raw handler for strings" do
      expect(subject.send(:facet_value_to_fq_string, "facet_name", "my value")).to eq "{!term f=facet_name}my value"
    end

    it "should pass booleans through" do
      expect(subject.send(:facet_value_to_fq_string, "facet_name", true)).to eq '{!term f=facet_name}true'
    end

    it "should pass boolean-like strings through" do
      expect(subject.send(:facet_value_to_fq_string, "facet_name", "true")).to eq '{!term f=facet_name}true'
    end

    it "should pass integers through" do
      expect(subject.send(:facet_value_to_fq_string, "facet_name", 1)).to eq '{!term f=facet_name}1'
    end

    it "should pass integer-like strings through" do
      expect(subject.send(:facet_value_to_fq_string, "facet_name", "1")).to eq '{!term f=facet_name}1'
      expect(subject.send(:facet_value_to_fq_string, "facet_name", -1)).to eq '{!term f=facet_name}-1'
    end

    it "should pass floats through" do
      expect(subject.send(:facet_value_to_fq_string, "facet_name", 1.11)).to eq '{!term f=facet_name}1.11'
    end

    it "should pass floats through" do
      expect(subject.send(:facet_value_to_fq_string, "facet_name", "1.11")).to eq '{!term f=facet_name}1.11'
    end

    context 'date handling' do
      before { allow(blacklight_config.facet_fields).to receive(:[]).with('facet_name').and_return(double(:date => true, :query => nil, :tag => nil, :field => 'facet_name')) }

      it "should pass date-type fields through" do
        expect(subject.send(:facet_value_to_fq_string, "facet_name", "2012-01-01")).to eq '{!term f=facet_name}2012-01-01'
        expect(subject.send(:facet_value_to_fq_string, "facet_name", "2003-04-09T00:00:00Z")).to eq '{!term f=facet_name}2003-04-09T00:00:00Z'
      end

      it "should format Date objects correctly" do
        allow(blacklight_config.facet_fields).to receive(:[]).with('facet_name').and_return(double(:date => nil, :query => nil, :tag => nil, :field => 'facet_name'))
        d = DateTime.parse("2003-04-09T00:00:00")
        expect(subject.send(:facet_value_to_fq_string, "facet_name", d)).to eq '{!term f=facet_name}2003-04-09T00:00:00Z'
      end
    end

    it "should handle range requests" do
      expect(subject.send(:facet_value_to_fq_string, "facet_name", 1..5)).to eq "facet_name:[1 TO 5]"
    end

    it "should add tag local parameters" do
      allow(blacklight_config.facet_fields).to receive(:[]).with('facet_name').and_return(double(:query => nil, :tag => 'asdf', :date => nil, :field => 'facet_name'))

      expect(subject.send(:facet_value_to_fq_string, "facet_name", true)).to eq "{!term f=facet_name tag=asdf}true"
      expect(subject.send(:facet_value_to_fq_string, "facet_name", "my value")).to eq "{!term f=facet_name tag=asdf}my value"
    end
  end

  describe "#add_facet_fq_to_solr" do
    it "converts a String fq into an Array" do
      solr_parameters = {:fq => 'a string' }

      subject.add_facet_fq_to_solr(solr_parameters)

      expect(solr_parameters[:fq]).to be_a_kind_of Array
    end
  end

  describe "#add_solr_fields_to_query" do
    let(:blacklight_config) do
      config = Blacklight::Configuration.new do |config|

        config.add_index_field 'an_index_field', solr_params: { 'hl.alternativeField' => 'field_x'}
        config.add_show_field 'a_show_field', solr_params: { 'hl.alternativeField' => 'field_y'}
        config.add_field_configuration_to_solr_request!
      end
    end

    let(:solr_parameters) do
      solr_parameters = Blacklight::Solr::Request.new

      subject.add_solr_fields_to_query(solr_parameters)

      solr_parameters
    end

    it "should add any extra solr parameters from index and show fields" do
      expect(solr_parameters[:'f.an_index_field.hl.alternativeField']).to eq "field_x"
      expect(solr_parameters[:'f.a_show_field.hl.alternativeField']).to eq "field_y"
    end
  end

  describe "#add_facetting_to_solr" do

    let(:blacklight_config) do
       config = Blacklight::Configuration.new

       config.add_facet_field 'test_field', :sort => 'count'
       config.add_facet_field 'some-query', :query => {'x' => {:fq => 'some:query' }}, :ex => 'xyz'
       config.add_facet_field 'some-pivot', :pivot => ['a','b'], :ex => 'xyz'
       config.add_facet_field 'some-field', solr_params: { 'facet.mincount' => 15 }
       config.add_facet_fields_to_solr_request!

       config
    end

    let(:solr_parameters) do
      solr_parameters = Blacklight::Solr::Request.new
      
      subject.add_facetting_to_solr(solr_parameters)

      solr_parameters
    end

    it "should add sort parameters" do
      expect(solr_parameters[:facet]).to be true

      expect(solr_parameters[:'facet.field']).to include('test_field')
      expect(solr_parameters[:'f.test_field.facet.sort']).to eq 'count'
    end

    it "should add facet exclusions" do
      expect(solr_parameters[:'facet.query']).to include('{!ex=xyz}some:query')
      expect(solr_parameters[:'facet.pivot']).to include('{!ex=xyz}a,b')
    end

    it "should add any additional solr_params" do
      expect(solr_parameters[:'f.some-field.facet.mincount']).to eq 15
    end

    describe ":include_in_request" do
      let(:solr_parameters) do
        solr_parameters = Blacklight::Solr::Request.new
        subject.add_facetting_to_solr(solr_parameters)
        solr_parameters
      end

      it "should respect the include_in_request parameter" do
        blacklight_config.add_facet_field 'yes_facet', include_in_request: true
        blacklight_config.add_facet_field 'no_facet', include_in_request: false
        
        expect(solr_parameters[:'facet.field']).to include('yes_facet')
        expect(solr_parameters[:'facet.field']).not_to include('no_facet')
      end

      it "should default to including facets if add_facet_fields_to_solr_request! was called" do
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

      it "should add facets to the solr request" do
        blacklight_config.add_facet_fields_to_solr_request!
        expect(solr_parameters[:'facet.field']).to match_array ['yes_facet', 'maybe_facet', 'another_facet']
      end

      it "should not override field-specific configuration by default" do
        blacklight_config.add_facet_fields_to_solr_request!
        expect(solr_parameters[:'facet.field']).to_not include 'no_facet'
      end

      it "should allow white-listing facets" do
        blacklight_config.add_facet_fields_to_solr_request! 'maybe_facet'
        expect(solr_parameters[:'facet.field']).to include 'maybe_facet'
        expect(solr_parameters[:'facet.field']).not_to include 'another_facet'
      end

      it "should allow white-listed facets to override any field-specific include_in_request configuration" do
        blacklight_config.add_facet_fields_to_solr_request! 'no_facet'
        expect(solr_parameters[:'facet.field']).to include 'no_facet'
      end
    end
  end

  describe "#add_facet_paging_to_solr" do
    let(:facet_field) { 'format' }
    let(:sort_key) { Blacklight::Solr::FacetPaginator.request_keys[:sort] }
    let(:page_key) { Blacklight::Solr::FacetPaginator.request_keys[:page] }
    let(:prefix_key) { Blacklight::Solr::FacetPaginator.request_keys[:prefix] }

    let(:blacklight_config) do
      Blacklight::Configuration.new do |config|
        config.add_facet_fields_to_solr_request!
        config.add_facet_field 'format'
        config.add_facet_field 'format_ordered', sort: :count
        config.add_facet_field 'format_limited', limit: 5
        config.add_facet_field 'format_more_limited', limit: 5, more_limit: 50
      end
    end

    let(:solr_parameters) do
      solr_parameters = Blacklight::Solr::Request.new
      subject.facet(facet_field).add_facet_paging_to_solr(solr_parameters)
      solr_parameters
    end

    it 'sets rows to 0' do
      expect(solr_parameters[:rows]).to eq 0
    end
    it 'sets facets requested to facet_field argument' do
      expect(solr_parameters["facet.field".to_sym]).to eq facet_field
    end
    it 'defaults offset to 0' do
      expect(solr_parameters[:"f.#{facet_field}.facet.offset"]).to eq 0
    end
    context 'when offset is manually set' do
      let(:user_params) { { page_key => 2 } }
      it 'uses offset manually set, and converts it to an integer' do
        expect(solr_parameters[:"f.#{facet_field}.facet.offset"]).to eq 20
      end
    end

    context 'for a field with a configured more_limit' do
      let(:facet_field) { 'format_more_limited' }

      it 'uses the more_limit configuration' do
        expect(solr_parameters[:"f.#{facet_field}.facet.limit"]).to eq 51
      end
    end

    context 'for a field with a param key different from the field name' do
      let(:user_params) { { page_key => 2, 'facet.sort': 'index', 'facet.prefix': 'x' } }
      let(:facet_field) { 'param_key' }

      let(:blacklight_config) do
        Blacklight::Configuration.new.tap do |config|
          config.add_facet_field key: 'param_key', field: 'solr_field', more_limit: 50, ex: 'other'

          config.add_facet_fields_to_solr_request!
        end
      end

      it "should use the configured solr field name in queries" do
        expect(solr_parameters).to include 'f.solr_field.facet.limit': 51,
                                           'f.solr_field.facet.offset': 50,
                                           'f.solr_field.facet.sort': 'index',
                                           'f.solr_field.facet.prefix': 'x',
                                           'facet.field': '{!ex=other}solr_field'
      end
    end


    it 'defaults limit to 20' do
      expect(solr_parameters[:"f.#{facet_field}.facet.limit"]).to eq 21
    end

    context 'when facet_list_limit is defined in scope' do
      before do
        allow(context).to receive_messages facet_list_limit: 1000
      end
      it 'uses scope method for limit' do
        expect(solr_parameters[:"f.#{facet_field}.facet.limit"]).to eq 1001
      end

      it 'uses controller method for limit when a ordinary limit is set' do
        expect(solr_parameters[:"f.#{facet_field}.facet.limit"]).to eq 1001
      end
    end

    it 'uses the default sort' do
      expect(solr_parameters[:"f.#{facet_field}.facet.sort"]).to be_blank
    end

    context 'when sort is provided' do
      let(:user_params) { { sort_key => 'index' } }
      it 'uses sort provided in the parameters' do
        expect(solr_parameters[:"f.#{facet_field}.facet.sort"]).to eq 'index'
      end
    end

    context 'when a prefix is provided' do
      let(:user_params) { { prefix_key => 'A' } }
      it 'includes the prefix in the query' do
        expect(solr_parameters[:"f.#{facet_field}.facet.prefix"]).to eq 'A'
      end
    end
  end

  describe "#with_tag_ex" do
    it "should add an !ex local parameter if the facet configuration requests it" do
      expect(subject.with_ex_local_param("xyz", "some-value")).to eq "{!ex=xyz}some-value"
    end

    it "should not add an !ex local parameter if it isn't configured" do
      mock_field = double()
      expect(subject.with_ex_local_param(nil, "some-value")).to eq "some-value"
    end
  end
end
