# -*- encoding : utf-8 -*-
require 'spec_helper'

# check the methods that do solr requests. Note that we are not testing if
#  solr gives "correct" responses, as that's out of scope (it's a part of
#  testing the solr code itself).  We *are* testing if blacklight code sends
#  queries to solr such that it gets appropriate results. When a user does a search,
#  do we get data back from solr (i.e. did we properly configure blacklight code
#  to talk with solr and get results)? when we do a document request, does
#  blacklight code get a single document returned?)
#
describe Blacklight::SolrHelper do

  # SolrHelper is a controller layer mixin, which depends
  # on being mixed into a class which has #params (from Rails)
  # and #blacklight_config
  class SolrHelperTestClass
    include Blacklight::SolrHelper

    attr_accessor :blacklight_config
    attr_accessor :blacklight_solr

    def initialize blacklight_config, blacklight_solr
      self.blacklight_config = blacklight_config
      self.blacklight_solr = blacklight_solr
    end

    def params
      {}
    end

    def logger
      Rails.logger
    end
  end

  subject { SolrHelperTestClass.new blacklight_config, blacklight_solr }

  let(:blacklight_config) { Blacklight::Configuration.new }
  let(:copy_of_catalog_config) { ::CatalogController.blacklight_config.deep_copy }
  let(:blacklight_solr) { Blacklight.solr }

  before(:each) do
    @all_docs_query = ''
    @no_docs_query = 'zzzzzzzzzzzz'
    @single_word_query = 'include'
    @mult_word_query = 'tibetan history'
  #  f[format][]=Book&f[language_facet][]=English
    @single_facet = {:format=>'Book'}
    @multi_facets = {:format=>'Book', :language_facet=>'Tibetan'}
    @bad_facet = {:format=>'666'}
    @subject_search_params = {:commit=>"search", :search_field=>"subject", :action=>"index", :"controller"=>"catalog", :"rows"=>"10", :"q"=>"wome"}
  end

  describe "#find" do  
    it "should use the configured solr path" do
      blacklight_config.solr_path = 'xyz'
      blacklight_solr.should_receive(:send_and_receive).with('xyz', anything).and_return("{}".to_json)
      expect(subject.find({})).to be_a_kind_of Blacklight::SolrResponse
    end

    it "should override the configured solr path" do
      blacklight_config.solr_path = 'xyz'
      blacklight_solr.should_receive(:send_and_receive).with('abc', anything).and_return("{}".to_json)
      expect(subject.find('abc', {})).to be_a_kind_of Blacklight::SolrResponse
    end

    it "should use a default :qt param" do
      blacklight_config.qt = 'xyz'
      blacklight_solr.should_receive(:send_and_receive).with('select', hash_including(params: { qt: 'xyz'})).and_return("{}".to_json)
      expect(subject.find({})).to be_a_kind_of Blacklight::SolrResponse
    end

    it "should use the provided :qt param" do
      blacklight_config.qt = 'xyz'
      blacklight_solr.should_receive(:send_and_receive).with('select', hash_including(params: { qt: 'abc'})).and_return("{}".to_json)
      expect(subject.find({qt: 'abc'})).to be_a_kind_of Blacklight::SolrResponse
    end

    describe "http_method configuration" do
      describe "using default" do

        it "defaults to get" do
          expect(blacklight_config.http_method).to eq :get
          blacklight_solr.should_receive(:send_and_receive) do |path, params|
            expect(path).to eq 'select'
            expect(params[:method]).to eq :get
            expect(params[:params]).to include(:q)
          end.and_return({'response'=>{'docs'=>[]}})
          subject.find(:q => @all_docs_query)
        end
      end

      describe "setting to post" do
        let (:blacklight_config) {config = Blacklight::Configuration.new; config.http_method=:post; config}

        it "keep value set to post" do
          expect(blacklight_config.http_method).to eq :post
          blacklight_solr.should_receive(:send_and_receive) do |path, params|
            expect(path).to eq 'select'
            expect(params[:method]).to eq :post
            expect(params[:data]).to include(:q)
          end.and_return({'response'=>{'docs'=>[]}})
          subject.find(:q => @all_docs_query)
        end
      end
    end
  end
  
  describe "http_method configuration", :integration => true do
    let (:blacklight_config) {config = Blacklight::Configuration.new; config.http_method=:post; config}

    it "should send a post request to solr and get a response back" do
      response = subject.find(:q => @all_docs_query)
      expect(response.docs.length).to be >= 1
    end
  end

  # SPECS for actual search parameter generation
  describe "solr_search_params" do
    it "allows customization of solr_search_params_logic" do
        # Normally you'd include a new module into (eg) your CatalogController
        # but a sub-class defininig it directly is simpler for test.             
        subject.stub(:add_foo_to_solr_params) do |solr_params, user_params|
          solr_params[:wt] = "TESTING"
        end
                         
        subject.solr_search_params_logic += [:add_foo_to_solr_params]
                
        expect(subject.solr_search_params[:wt]).to eq "TESTING"                
    end
    
    
    describe 'for an entirely empty search' do
      before do
        @produced_params = subject.solr_search_params.with_indifferent_access
      end

      let(:blacklight_config) { copy_of_catalog_config }

      it 'should not have a q param' do
        expect(@produced_params[:q]).to be_nil
        expect(@produced_params["spellcheck.q"]).to be_nil
      end
      it 'should have default rows' do
        expect(@produced_params[:rows]).to eq 10
      end
      it 'should have default facet fields' do
        # remove local params from the facet.field
        expect(@produced_params[:"facet.field"].map { |x| x.gsub(/\{![^}]+\}/, '') }).to match_array ["format", "subject_topic_facet", "pub_date", "language_facet", "lc_1letter_facet", "subject_geo_facet", "subject_era_facet"]
      end
      
      it "should have default qt"  do
        expect(@produced_params[:qt]).to eq "search"
      end
      it "should have no fq" do
        expect(@produced_params[:phrase_filters]).to be_blank
        expect(@produced_params[:fq]).to be_blank
      end
    end


    describe "for an empty string search" do      
      it "should return empty string q in solr parameters" do        
        solr_params = subject.solr_search_params(:q => "")
        expect(solr_params[:q]).to eq ""
        expect(solr_params["spellcheck.q"]).to eq ""
      end
    end

    describe "for request params also passed in as argument" do      
      it "should only have one value for the key 'q' regardless if a symbol or string" do        
        solr_params = subject.solr_search_params( :q => "some query", 'q' => 'another value' )
        expect(solr_params[:q]).to eq 'some query'
        expect(solr_params['q']).to eq 'some query'
      end
    end


    describe "for one facet, no query" do
      it "should have proper solr parameters" do

        solr_params = subject.solr_search_params(:f => @single_facet)

        expect(solr_params[:q]).to be_blank
        expect(solr_params["spellcheck.q"]).to be_blank

        @single_facet.each_value do |value|
          expect(solr_params[:fq]).to include("{!raw f=#{@single_facet.keys[0]}}#{value}")
        end
      end
    end

    describe "with Multi Facets, No Query" do
      it 'should have fq set properly' do
        solr_params = subject.solr_search_params(:f => @multi_facets)

        @multi_facets.each_pair do |facet_field, value_list|
          value_list ||= []
          value_list = [value_list] unless value_list.respond_to? :each
          value_list.each do |value|
            expect(solr_params[:fq]).to include("{!raw f=#{facet_field}}#{value}"  )
          end
        end

      end
    end

    describe "with Multi Facets, Multi Word Query" do
      it 'should have fq and q set properly' do
        solr_params = subject.solr_search_params(:q => @mult_word_query, :f => @multi_facets)

        @multi_facets.each_pair do |facet_field, value_list|
          value_list ||= []
          value_list = [value_list] unless value_list.respond_to? :each
          value_list.each do |value|
            expect(solr_params[:fq]).to include("{!raw f=#{facet_field}}#{value}"  )
          end
        end
        expect(solr_params[:q]).to eq @mult_word_query
      end
    end

    describe "facet_value_to_fq_string" do

      it "should use the raw handler for strings" do
        expect(subject.send(:facet_value_to_fq_string, "facet_name", "my value")).to eq "{!raw f=facet_name}my value" 
      end

      it "should pass booleans through" do
        expect(subject.send(:facet_value_to_fq_string, "facet_name", true)).to eq "facet_name:true"
      end

      it "should pass boolean-like strings through" do
        expect(subject.send(:facet_value_to_fq_string, "facet_name", "true")).to eq "facet_name:true"
      end

      it "should pass integers through" do
        expect(subject.send(:facet_value_to_fq_string, "facet_name", 1)).to eq "facet_name:1"
      end

      it "should pass integer-like strings through" do
        expect(subject.send(:facet_value_to_fq_string, "facet_name", "1")).to eq "facet_name:1"
      end

      it "should pass floats through" do
        expect(subject.send(:facet_value_to_fq_string, "facet_name", 1.11)).to eq "facet_name:1.11"
      end

      it "should pass floats through" do
        expect(subject.send(:facet_value_to_fq_string, "facet_name", "1.11")).to eq "facet_name:1.11"
      end

      it "should pass date-type fields through" do
        blacklight_config.facet_fields.stub(:[]).with('facet_name').and_return(double(:date => true, :query => nil, :tag => nil))

        expect(subject.send(:facet_value_to_fq_string, "facet_name", "2012-01-01")).to eq "facet_name:2012-01-01"
      end

      it "should handle range requests" do
        expect(subject.send(:facet_value_to_fq_string, "facet_name", 1..5)).to eq "facet_name:[1 TO 5]"
      end

      it "should add tag local parameters" do
        blacklight_config.facet_fields.stub(:[]).with('facet_name').and_return(double(:query => nil, :tag => 'asdf', :date => nil))

        expect(subject.send(:facet_value_to_fq_string, "facet_name", true)).to eq "{!tag=asdf}facet_name:true"
        expect(subject.send(:facet_value_to_fq_string, "facet_name", "my value")).to eq "{!raw f=facet_name tag=asdf}my value"
      end
    end

    describe "solr parameters for a field search from config (subject)" do
      let(:solr_params) { subject.solr_search_params @subject_search_params }
      let(:blacklight_config) { copy_of_catalog_config }

      it "should look up qt from field definition" do
        expect(solr_params[:qt]).to eq "search"
      end
      it "should not include weird keys not in field definition" do
        solr_params.to_hash.tap do |h|
          expect(h[:phrase_filters]).to be_nil
          expect(h[:fq]).to be_nil
          expect(h[:commit]).to be_nil
          expect(h[:action]).to be_nil
          expect(h[:controller]).to be_nil
        end
      end
      it "should include proper 'q', possibly with LocalParams" do
        expect(solr_params[:q]).to match(/(\{[^}]+\})?wome/)
      end
      it "should include proper 'q' when LocalParams are used" do
        if solr_params[:q] =~ /\{[^}]+\}/
          expect(solr_params[:q]).to match(/\{[^}]+\}wome/)
        end
      end
      it "should include spellcheck.q, without LocalParams" do
        expect(solr_params["spellcheck.q"]).to eq "wome"
      end

      it "should include spellcheck.dictionary from field def solr_parameters" do
        expect(solr_params[:"spellcheck.dictionary"]).to eq "subject"
      end
      it "should add on :solr_local_parameters using Solr LocalParams style" do
        params = subject.solr_search_params( @subject_search_params )

        #q == "{!pf=$subject_pf $qf=subject_qf} wome", make sure
        #the LocalParams are really there
        params[:q] =~ /^\{!([^}]+)\}/
        key_value_pairs = $1.split(" ")
        expect(key_value_pairs).to include("pf=$subject_pf")
        expect(key_value_pairs).to include("qf=$subject_qf")
      end
    end

    describe "overriding of qt parameter" do
      it "should return the correct overriden parameter" do
        subject.stub(params: { qt: 'overridden' })
        
        expect(subject.solr_search_params[:qt]).to eq "overridden"        
      end
    end

    describe "converts a String fq into an Array" do
      it "should return the correct overriden parameter" do
        solr_parameters = {:fq => 'a string' }
        
        subject.add_facet_fq_to_solr(solr_parameters, {})

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
        
        subject.add_solr_fields_to_query(solr_parameters, {})

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
        
        subject.add_facetting_to_solr(solr_parameters, {})

        solr_parameters
      end

      it "should add sort parameters" do
        expect(solr_parameters[:facet]).to be_true

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
          subject.add_facetting_to_solr(solr_parameters, {})
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
          subject.add_facetting_to_solr(solr_parameters, {})
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

    describe "with a complex parameter environment" do
      let(:blacklight_config) do        
        config = Blacklight::Configuration.new
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
        return config
      end

      before do
        subject.stub params: {:search_field => "test_field", :q => "test query", "facet.field" => "extra_facet"}
      end
      
      it "should merge parameters from search_field definition" do
        solr_params = subject.solr_search_params
        
        expect(solr_params[:qf]).to eq "fieldOne^2.3 fieldTwo fieldThree^0.4"
        expect(solr_params[:spellcheck]).to eq 'false'
      end
      it "should merge empty string parameters from search_field definition" do
        expect(subject.solr_search_params[:pf]).to eq ""        
      end

      describe "should respect proper precedence of settings, " do
        before do
          @produced_params = subject.solr_search_params
        end


        it "should not put :search_field in produced params" do
          expect(@produced_params[:search_field]).to be_nil
        end

        it "should fall through to BL general defaults for qt not otherwise specified " do
          expect(@produced_params[:qt]).to eq blacklight_config[:default_solr_params][:qt]
        end

        it "should take rows from search field definition where specified" do
          expect(@produced_params[:rows]).to eq "55"
        end

        it "should take q from request params" do
          expect(@produced_params[:q]).to eq "test query"
        end

        it "should add in extra facet.field from params" do
          expect(@produced_params[:"facet.field"]).to include("extra_facet")
        end

      end
    end

    describe "sorting" do
      let(:blacklight_config) { copy_of_catalog_config }
      
      it "should send the default sort parameter to solr" do                        
        expect(subject.solr_search_params[:sort]).to eq 'score desc, pub_date_sort desc, title_sort asc'        
      end

      it "should not send a sort parameter to solr if the sort value is blank" do
        blacklight_config.sort_fields = {}
        blacklight_config.add_sort_field('', :label => 'test')

        produced_params = subject.solr_search_params
        expect(produced_params).not_to have_key(:sort)
      end

      it "should pass through user sort parameters" do
        produced_params = subject.solr_search_params( :sort => 'solr_test_field desc' )
        expect(produced_params[:sort]).to eq 'solr_test_field desc'
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
      
      before do        
        subject.stub params: {:search_field => "custom_author_key", :q => "query"}
      end
      
      before do
        @result = subject.solr_search_params
      end

      it "should pass through ordinary params" do
        expect(@result[:qt]).to eq "author_qt"
        expect(@result[:ps]).to eq "2"
        expect(@result[:qf]).to eq "someField^1000"
      end

      it "should include include local params with escaping" do
        expect(@result[:q]).to include('qf=$author_qf')
        expect(@result[:q]).to include('pf=\'you\\\'ll have \\" to escape this\'')
        expect(@result[:q]).to include('pf2=$pf2_do_not_escape_or_quote')
      end
    end
    
    describe "mapping facet.field" do
      let(:blacklight_config) do
        Blacklight::Configuration.new do |config|
          config.add_facet_field 'some_field'
          config.add_facet_fields_to_solr_request!
        end
      end

      it "should add single additional facet.field from app" do
        solr_params = subject.solr_search_params( "facet.field" => "additional_facet" )
        expect(solr_params[:"facet.field"]).to include("additional_facet")
        expect(solr_params[:"facet.field"]).to have(2).fields
      end
      it "should map multiple facet.field to additional facet.field" do
        solr_params = subject.solr_search_params( "facet.field" => ["add_facet1", "add_facet2"] )
        expect(solr_params[:"facet.field"]).to include("add_facet1")
        expect(solr_params[:"facet.field"]).to include("add_facet2")
        expect(solr_params[:"facet.field"]).to have(3).fields
      end
      it "should map facets[fields][] to additional facet.field" do
        solr_params = subject.solr_search_params( "facets" => ["add_facet1", "add_facet2"] )
        expect(solr_params[:"facet.field"]).to include("add_facet1")
        expect(solr_params[:"facet.field"]).to include("add_facet2")
        expect(solr_params[:"facet.field"]).to have(3).fields
      end
    end

 end

  describe "solr_facet_params" do
    before do
      @facet_field = 'format'
      @generated_solr_facet_params = subject.solr_facet_params(@facet_field)

      @sort_key = Blacklight::Solr::FacetPaginator.request_keys[:sort]
      @page_key = Blacklight::Solr::FacetPaginator.request_keys[:page]
    end
    let(:blacklight_config) do
      Blacklight::Configuration.new do |config|
        config.add_facet_fields_to_solr_request!
        config.add_facet_field 'format'
        config.add_facet_field 'format_ordered', :sort => :count
        config.add_facet_field 'format_limited', :limit => 5

      end
    end

    it 'sets rows to 0' do
      expect(@generated_solr_facet_params[:rows]).to eq 0
    end
    it 'sets facets requested to facet_field argument' do
      expect(@generated_solr_facet_params["facet.field".to_sym]).to eq @facet_field
    end
    it 'defaults offset to 0' do
      expect(@generated_solr_facet_params[:"f.#{@facet_field}.facet.offset"]).to eq 0
    end
    it 'uses offset manually set, and converts it to an integer' do
      solr_params = subject.solr_facet_params(@facet_field, @page_key => 2)
      expect(solr_params[:"f.#{@facet_field}.facet.offset"]).to eq 20
    end
    it 'defaults limit to 20' do
      solr_params = subject.solr_facet_params(@facet_field)
      expect(solr_params[:"f.#{@facet_field}.facet.limit"]).to eq 21
    end

    describe 'if facet_list_limit is defined in controller' do
      before do
        subject.stub facet_list_limit: 1000
      end
      it 'uses controller method for limit' do
        solr_params = subject.solr_facet_params(@facet_field)
        expect(solr_params[:"f.#{@facet_field}.facet.limit"]).to eq 1001
      end

      it 'uses controller method for limit when a ordinary limit is set' do
        solr_params = subject.solr_facet_params(@facet_field)
        expect(solr_params[:"f.#{@facet_field}.facet.limit"]).to eq 1001
      end
    end

    it 'uses the default sort' do
      solr_params = subject.solr_facet_params(@facet_field)
      expect(solr_params[:"f.#{@facet_field}.facet.sort"]).to be_blank
    end

    it "uses the field-specific sort" do
      solr_params = subject.solr_facet_params('format_ordered')
      expect(solr_params[:"f.format_ordered.facet.sort"]).to eq :count
    end

    it 'uses sort provided in the parameters' do
      solr_params = subject.solr_facet_params(@facet_field, @sort_key => "index")
      expect(solr_params[:"f.#{@facet_field}.facet.sort"]).to eq 'index'
    end
    it "comes up with the same params as #solr_search_params to constrain context for facet list" do
      search_params = {:q => 'tibetan history', :f=> {:format=>'Book', :language_facet=>'Tibetan'}}
      solr_search_params = subject.solr_search_params( search_params )
      solr_facet_params = subject.solr_facet_params('format', search_params)

      solr_search_params.each_pair do |key, value|
        # The specific params used for fetching the facet list we
        # don't care about.
        next if ['facets', "facet.field", 'rows', 'facet.limit', 'facet.offset', 'facet.sort'].include?(key)
        # Everything else should match
        expect(solr_facet_params[key]).to eq value
      end

    end
  end
  describe "for facet limit parameters config ed" do                
    before do   
      subject.stub params: {:search_field => "test_field", :q => "test query"}
      @generated_params = subject.solr_search_params
    end

    let(:blacklight_config) { copy_of_catalog_config }
    
    it "should include specifically configged facet limits +1" do
      expect(@generated_params[:"f.subject_topic_facet.facet.limit"]).to eq 21      
    end
    it "should not include a facet limit for a nil key in hash" do
      expect(@generated_params).not_to have_key(:"f.format.facet.limit")
      expect(@generated_params).not_to have_key(:"facet.limit")
    end
  end
  
   describe "get_facet_pagination", :integration => true do
    before do
      Deprecation.silence(Blacklight::SolrHelper) do
        @facet_paginator = subject.get_facet_pagination(@facet_field)
      end
    end
    it 'should return a facet paginator' do
      expect(@facet_paginator).to be_a_kind_of(Blacklight::Solr::FacetPaginator)
    end
    it 'with a limit set' do
      expect(@facet_paginator.limit).not_to be_nil
    end
   end

# SPECS FOR SEARCH RESULTS FOR QUERY
  describe 'Search Results', :integration => true do

    let(:blacklight_config) { copy_of_catalog_config }
    describe 'for a sample query returning results' do

      before do        
        (@solr_response, @document_list) = subject.get_search_results(:q => @all_docs_query)
      end

      it "should use the configured request handler " do
        blacklight_config.stub(:default_solr_params).and_return({:qt => 'custom_request_handler'})
        blacklight_solr.should_receive(:send_and_receive) do |path, params|
          expect(path).to eq 'select'
          expect(params[:params]['facet.field']).to eq ["format", "{!ex=pub_date_single}pub_date", "subject_topic_facet", "language_facet", "lc_1letter_facet", "subject_geo_facet", "subject_era_facet"]
          expect(params[:params]["facet.query"]).to eq ["pub_date:[#{5.years.ago.year} TO *]", "pub_date:[#{10.years.ago.year} TO *]", "pub_date:[#{25.years.ago.year} TO *]"]
          expect(params[:params]).to include('rows' => 10, 'qt'=>"custom_request_handler", 'q'=>"", "spellcheck.q"=>"", "f.subject_topic_facet.facet.limit"=>21, 'sort'=>"score desc, pub_date_sort desc, title_sort asc")
        end.and_return({'response'=>{'docs'=>[]}})
        subject.get_search_results(:q => @all_docs_query)
      end

      it 'should have a @response.docs list of the same size as @document_list' do
        expect(@solr_response.docs).to have(@document_list.length).docs
      end

      it 'should have @response.docs list representing same documents as SolrDocuments in @document_list' do
        @solr_response.docs.each_index do |index|
          mash = @solr_response.docs[index]
          solr_document = @document_list[index]

          expect(Set.new(mash.keys)).to eq Set.new(solr_document.keys)

          mash.each_key do |key|
            expect(mash[key]).to eq solr_document[key]
          end
        end
      end
    end

    describe "for a query returning a grouped response" do
      before do
        (@solr_response, @document_list) = subject.get_search_results({:q => @all_docs_query}, :group => true, :'group.field' => 'pub_date_sort')
      end

      it "should have an empty document list" do
        expect(@document_list).to be_empty
      end

      it "should return a grouped response" do
        expect(@solr_response).to be_a_kind_of Blacklight::SolrResponse::GroupResponse

      end
    end

    describe "for a query returning multiple groups", integration: true do
      let(:blacklight_config) { copy_of_catalog_config }

      before do
        subject.stub grouped_key_for_results: 'title_sort'
        (@solr_response, @document_list) = subject.get_search_results({:q => @all_docs_query}, :group => true, :'group.field' => ['pub_date_sort', 'title_sort'])
      end

      it "should have an empty document list" do
        expect(@document_list).to be_empty
      end

      it "should return a grouped response" do
        expect(@solr_response).to be_a_kind_of Blacklight::SolrResponse::GroupResponse
        expect(@solr_response.group_field).to eq "title_sort"
      end
    end

    describe '#query_solr' do
      it 'should have results' do
        solr_response = subject.query_solr(:q => @single_word_query)
        expect(solr_response.docs).to have_at_least(1).result
      end

    end

    describe 'for All Docs Query, No Facets' do
      it 'should have non-nil values for required doc fields set in initializer' do
        (solr_response, document_list) = subject.get_search_results(:q => @all_docs_query)
        result_docs = document_list
        document = result_docs.first
        expect(document.get(blacklight_config.index.title_field)).not_to be_nil
        expect(document.get(blacklight_config.index.display_type_field)).not_to be_nil
      end
    end



    describe "Single Word Query with no Facets" do
    	
      it 'should have results' do
        solr_response = subject.query_solr(:q => @single_word_query)
        expect(solr_response.docs).to have_at_least(1).result
      end

      it 'should have results' do
        (solr_response, document_list) = subject.get_search_results(:q => @single_word_query)
        expect(solr_response.docs).to have(document_list.size).results
        expect(solr_response.docs).to have_at_least(1).result
      end
    end

    describe "Multiple Words Query with No Facets" do
      it 'should have results' do

        (solr_response, document_list) = subject.get_search_results(:q => @mult_word_query)
        expect(solr_response.docs).to have(document_list.size).results
        expect(solr_response.docs).to have_at_least(1).result
      end
    end

    describe "One Facet, No Query" do
      it 'should have results' do
        (solr_response, document_list) = subject.get_search_results(:f => @single_facet)
        expect(solr_response.docs).to have(document_list.size).results
        expect(solr_response.docs).to have_at_least(1).result
      end
    end

    describe "Mult Facets, No Query" do
      it 'should have results' do
        (solr_response, document_list) = subject.get_search_results(:f => @multi_facets)
        expect(solr_response.docs).to have(document_list.size).results
        expect(solr_response.docs).to have_at_least(1).result
      end
    end

    describe "Single Word Query with One Facet" do
      it 'should have results' do
        (solr_response, document_list) = subject.get_search_results(:q => @single_word_query, :f => @single_facet)
        expect(solr_response.docs).to have(document_list.size).results
        expect(solr_response.docs).to have_at_least(1).result
      end
    end

    describe "Multiple Words Query with Multiple Facets" do
      it 'should have results' do
        (solr_response, document_list) = subject.get_search_results(:q => @mult_word_query, :f => @multi_facets)
        expect(solr_response.docs).to have(document_list.size).results
        expect(solr_response.docs).to have_at_least(1).result
      end
    end

    describe "for All Docs Query and One Facet" do
      it 'should have results' do
        (solr_response, document_list) = subject.get_search_results(:q => @all_docs_query, :f => @single_facet)
        expect(solr_response.docs).to have(document_list.size).results
        expect(solr_response.docs).to have_at_least(1).result
      end
      # TODO: check that number of these results < number of results for all docs query
      #   BUT can't: num docs isn't total, it's the num docs in the single SOLR response (e.g. 10)
    end

    describe "for Query Without Results and No Facet" do
      it 'should have no results and not raise error' do
        (solr_response, document_list) = subject.get_search_results(:q => @no_docs_query)
        expect(document_list).to have(0).results
        expect(solr_response.docs).to have(0).results
      end
    end

    describe "for Query Without Results and One Facet" do
      it 'should have no results and not raise error' do
        (solr_response, document_list) = subject.get_search_results(:q => @no_docs_query, :f => @single_facet)
        expect(document_list).to have(0).results
        expect(solr_response.docs).to have(0).results
      end
    end

    describe "for All Docs Query and Bad Facet" do
      it 'should have no results and not raise error' do
        (solr_response, document_list) = subject.get_search_results(:q => @all_docs_query, :f => @bad_facet)
        expect(document_list).to have(0).results
        expect(solr_response.docs).to have(0).results
      end
    end




  end  # Search Results


# SPECS FOR SEARCH RESULTS FOR FACETS
  describe 'Facets in Search Results for All Docs Query', :integration => true do

    let(:blacklight_config) { copy_of_catalog_config }

    before do
      (solr_response, document_list) = subject.get_search_results(:q => @all_docs_query)
      @facets = solr_response.facets
    end

    it 'should have more than one facet' do
      expect(@facets).to have_at_least(1).facet
    end
    it 'should have all facets specified in initializer' do
      fields = blacklight_config.facet_fields.reject { |k,v| v.query || v.pivot }
      expect(@facets.map { |f| f.name }).to match_array fields.map { |k, v| v.field }
      fields.each do |key, field|
        expect(@facets.find {|f| f.name == field.field}).not_to be_nil        
      end
    end
    it 'should have at least one value for each facet' do
      @facets.each do |facet|
        expect(facet.items).to have_at_least(1).hit
      end
    end
    it 'should have multiple values for at least one facet' do
      has_mult_values = false
      @facets.each do |facet|
        if facet.items.size > 1
          has_mult_values = true
          break
        end
      end
      expect(has_mult_values).to eq true
    end
    it 'should have all value counts > 0' do
      @facets.each do |facet|
        facet.items.each do |facet_vals|
          expect(facet_vals.hits).to be > 0
        end
      end
    end
  end # facet specs


# SPECS FOR SEARCH RESULTS FOR PAGING
  describe 'Paging', :integration => true do
    let(:blacklight_config) { copy_of_catalog_config }

    it 'should start with first results by default' do
      (solr_response, document_list) = subject.get_search_results(:q => @all_docs_query)
      expect(solr_response.params[:start].to_i).to eq 0
    end
    it 'should have number of results (per page) set in initializer, by default' do
      (solr_response, document_list) = subject.get_search_results(:q => @all_docs_query)
      expect(solr_response.docs).to have(blacklight_config[:default_solr_params][:rows]).items
      expect(document_list).to have(blacklight_config[:default_solr_params][:rows]).items
    end

    it 'should get number of results per page requested' do
      num_results = 3  # non-default value
      (solr_response1, document_list1) = subject.get_search_results(:q => @all_docs_query, :per_page => num_results)
      expect(document_list1).to have(num_results).docs
      expect(solr_response1.docs).to have(num_results).docs
    end

    it 'should get number of rows requested' do
      num_results = 4  # non-default value
      (solr_response1, document_list1) = subject.get_search_results(:q => @all_docs_query, :rows => num_results)
      expect(document_list1).to have(num_results).docs
      expect(solr_response1.docs).to have(num_results).docs
    end

    it 'should skip appropriate number of results when requested - default per page' do
      page = 3
      (solr_response2, document_list2) = subject.get_search_results(:q => @all_docs_query, :page => page)
      expect(solr_response2.params[:start].to_i).to eq  blacklight_config[:default_solr_params][:rows] * (page-1)
    end
    it 'should skip appropriate number of results when requested - non-default per page' do
      page = 3
      num_results = 3
      (solr_response2a, document_list2a) = subject.get_search_results(:q => @all_docs_query, :per_page => num_results, :page => page)
      expect(solr_response2a.params[:start].to_i).to eq num_results * (page-1)
    end

    it 'should have no results when prompted for page after last result' do
      big = 5000
      (solr_response3, document_list3) = subject.get_search_results(:q => @all_docs_query, :rows => big, :page => big)
      expect(document_list3).to have(0).docs
      expect(solr_response3.docs).to have(0).docs
    end

    it 'should show first results when prompted for page before first result' do
      # FIXME: should it show first results, or should it throw an error for view to deal w?
      #   Solr throws an error for a negative start value
      (solr_response4, document_list4) = subject.get_search_results(:q => @all_docs_query, :page => '-1')
      expect(solr_response4.params[:start].to_i).to eq 0
    end
    it 'should have results available when asked for more than are in response' do
      big = 5000
      (solr_response5, document_list5) = subject.get_search_results(:q => @all_docs_query, :rows => big, :page => 1)
      expect(solr_response5.docs).to have(document_list5.length).docs
      expect(solr_response5.docs).to have_at_least(1).doc
    end

  end # page specs

  # SPECS FOR SINGLE DOCUMENT REQUESTS
  describe 'Get Document By Id', :integration => true do
    before do
      @doc_id = '2007020969'
      @bad_id = "redrum"
      @response2, @document = subject.get_solr_response_for_doc_id(@doc_id)
    end

    it "should raise Blacklight::InvalidSolrID for an unknown id" do
      expect {
        subject.get_solr_response_for_doc_id(@bad_id)
      }.to raise_error(Blacklight::Exceptions::InvalidSolrID)
    end

    it "should use a provided document request handler " do
      blacklight_config.stub(:document_solr_request_handler => 'document')
      blacklight_solr.should_receive(:send_and_receive).with('select', kind_of(Hash)).and_return({'response'=>{'docs'=>[]}})
      expect { subject.get_solr_response_for_doc_id(@doc_id)}.to raise_error Blacklight::Exceptions::InvalidSolrID
    end

    it "should use a provided document solr path " do
      blacklight_config.stub(:document_solr_path => 'get')
      blacklight_solr.should_receive(:send_and_receive).with('get', kind_of(Hash)).and_return({'response'=>{'docs'=>[]}})
      expect { subject.get_solr_response_for_doc_id(@doc_id)}.to raise_error Blacklight::Exceptions::InvalidSolrID
    end

    it "should have a non-nil result for a known id" do
      expect(@document).not_to be_nil
    end
    it "should have a single document in the response for a known id" do
      expect(@response2.docs.size).to eq 1
    end
    it 'should have the expected value in the id field' do
      expect(@document.id).to eq @doc_id
    end
    it 'should have non-nil values for required fields set in initializer' do
      expect(@document.get(blacklight_config.view_config(:show).title_field)).not_to be_nil
      expect(@document.get(blacklight_config.view_config(:show).display_type_field)).not_to be_nil
    end
  end

  describe "solr_doc_params" do
    it "should default to using the 'document' requestHandler" do
      doc_params = subject.solr_doc_params('asdfg')
      expect(doc_params[:qt]).to eq 'document'
    end

    it "should default to using the id parameter when sending solr queries" do
      doc_params = subject.solr_doc_params('asdfg')
      expect(doc_params[:id]).to eq 'asdfg'
    end

    it "should use the document_unique_id_param configuration" do
      blacklight_config.stub(document_unique_id_param: :ids)
      doc_params = subject.solr_doc_params('asdfg')
      expect(doc_params[:ids]).to eq 'asdfg'
    end

    describe "blacklight config's default_document_solr_parameters" do
      it "should use parameters from the controller's default_document_solr_parameters" do
        blacklight_config.default_document_solr_params = { :qt => 'my_custom_handler', :asdf => '1234' }
        doc_params = subject.solr_doc_params('asdfg')
        expect(doc_params[:qt]).to eq 'my_custom_handler'
        expect(doc_params[:asdf]).to eq '1234'
      end
    end

  end

  describe "Get Document by custom unique id" do
=begin    
    # Can't test this properly without updating the "document" request handler in solr
    it "should respect the configuration-supplied unique id" do
      SolrDocument.should_receive(:unique_key).and_return("title_display")
      @response, @document = @solr_helper.get_solr_response_for_doc_id('"Strong Medicine speaks"')
      @document.id).to eq '"Strong Medicine speaks"'
      @document.get(:id)).to eq 2007020969
    end
=end
    it "should respect the configuration-supplied unique id" do
      doc_params = subject.solr_doc_params('"Strong Medicine speaks"')
      expect(doc_params[:id]).to eq '"Strong Medicine speaks"'
    end
  end



# SPECS FOR SINGLE DOCUMENT VIA SEARCH
  describe "Get Document Via Search", :integration => true do
    before do
      @doc_row = 3
      @doc = subject.get_single_doc_via_search(@doc_row, :q => @all_docs_query)
    end
=begin
# can't test these here, because the method only returns the document
    it "should get a single document" do
      response.docs.size).to eq 1
    end

    doc2 = get_single_doc_via_search(@all_docs_query, nil, @doc_row, @multi_facets)
    it "should limit search result by facets when supplied" do
      response2.docs.numFound.should_be < response.docs.numFound
    end

    it "should not have facets in the response" do
      response.facets.size).to eq 0
    end
=end

    it 'should have a doc id field' do
      expect(@doc[:id]).not_to be_nil
    end

    it 'should have non-nil values for required fields set in initializer' do
      expect(@doc[blacklight_config.view_config(:show).title_field]).not_to be_nil
      expect(@doc[blacklight_config.view_config(:show).display_type_field]).not_to be_nil
    end

    it "should limit search result by facets when supplied" do
      doc2 = subject.get_single_doc_via_search(@doc_row , :q => @all_docs_query, :f => @multi_facets)
      expect(doc2[:id]).not_to be_nil
    end

  end

# SPECS FOR SPELLING SUGGESTIONS VIA SEARCH
  describe "Searches should return spelling suggestions", :integration => true do
    it 'search results for just-poor-enough-query term should have (multiple) spelling suggestions' do
      (solr_response, document_list) = subject.get_search_results({:q => 'boo'})
      expect(solr_response.spelling.words).to include('bon')
      expect(solr_response.spelling.words).to include('bod')  #for multiple suggestions
    end

    it 'search results for just-poor-enough-query term should have multiple spelling suggestions' do
      (solr_response, document_list) = subject.get_search_results({:q => 'politica'})
      expect(solr_response.spelling.words).to include('policy') # less freq
      expect(solr_response.spelling.words).to include('politics') # more freq
      expect(solr_response.spelling.words).to include('political') # more freq
=begin
      #  when we can have multiple suggestions
      solr_response.spelling.words.should_not include('policy') # less freq
      solr_response.spelling.words).to include('politics') # more freq
      solr_response.spelling.words).to include('political') # more freq
=end
    end

    it "title search results for just-poor-enough query term should have spelling suggestions" do
      (solr_response, document_list) = subject.get_search_results({:q => 'yehudiyam', :qt => 'search', :"spellcheck.dictionary" => "title"})
      expect(solr_response.spelling.words).to include('yehudiyim')
    end

    it "author search results for just-poor-enough-query term should have spelling suggestions" do
      (solr_response, document_list) = subject.get_search_results({:q => 'shirma', :qt => 'search', :"spellcheck.dictionary" => "author"})
      expect(solr_response.spelling.words).to include('sharma')
    end

    it "subject search results for just-poor-enough-query term should have spelling suggestions" do
      (solr_response, document_list) = subject.get_search_results({:q => 'wome', :qt => 'search', :"spellcheck.dictionary" => "subject"})
      expect(solr_response.spelling.words).to include('women')
    end

    it 'search results for multiple terms query with just-poor-enough-terms should have spelling suggestions for each term' do
     pending
#     get_spelling_suggestion("histo politica").should_not be_nil
    end

  end

  describe "facet_limit_for" do
    let(:blacklight_config) { copy_of_catalog_config }

    it "should return specified value for facet_field specified" do
      expect(subject.facet_limit_for("subject_topic_facet")).to eq blacklight_config.facet_fields["subject_topic_facet"].limit
    end
    it "should generate proper solr param" do
      expect(subject.solr_search_params[:"f.subject_topic_facet.facet.limit"]).to eq 21
    end
    
    it "facet_limit_hash should return hash with key being facet_field and value being configured limit" do
      # facet_limit_hash has been removed from solrhelper in refactor. should it go back?
      pending "facet_limit_hash has been removed from solrhelper in refactor. should it go back?"
      expect(subject.facet_limit_hash).to eq blacklight_config[:facet][:limits]
    end
    it "should handle no facet_limits in config" do
      blacklight_config.facet_fields = {}
            
      expect(subject.facet_limit_for("subject_topic_facet")).to be_nil
      
      expect(subject.solr_search_params).not_to have_key(:"f.subject_topic_facet.facet.limit")
      
    end
    
    describe "for 'true' configured values" do
      let(:blacklight_config) do
        config = Blacklight::Configuration.new
        config.add_facet_field "language_facet", limit: true
        config
      end
      it "should return nil if no @response available" do
        expect(subject.facet_limit_for("some_unknown_field")).to be_nil
      end
      it "should get from @response facet.limit if available" do        
        @response = double()
        @response.stub(:facet_by_field_name).with("language_facet").and_return(double(limit: nil))
        subject.instance_variable_set(:@response, @response)
        blacklight_config.facet_fields['language_facet'].limit = 10
        expect(subject.facet_limit_for("language_facet")).to eq 10
      end
      it "should get the limit from the facet field in @response" do
        @response = double()
        @response.stub(:facet_by_field_name).with("language_facet").and_return(double(limit: 16))
        subject.instance_variable_set(:@response, @response)
        expect(subject.facet_limit_for("language_facet")).to eq 15
      end
    end
  end

    describe "with max per page enforced" do
      let(:blacklight_config) do        
        config = Blacklight::Configuration.new
        config.max_per_page = 123
        return config
      end

      it "should enforce max_per_page against all parameters" do
        expect(blacklight_config.max_per_page).to eq 123
        expect(subject.solr_search_params(:per_page => 98765)[:rows]).to eq 123
      end              
    end

    describe "#get_solr_response_for_field_values" do
      before do
        @mock_response = double()
        @mock_response.stub(:docs => [])
      end
      it "should contruct a solr query based on the field and value pair" do
        subject.should_receive(:find).with(hash_including(:q => "field_name:(value)")).and_return(@mock_response)
        subject.get_solr_response_for_field_values('field_name', 'value')
      end

      it "should OR multiple values together" do
        subject.should_receive(:find).with(hash_including(:q => "field_name:(a OR b)")).and_return(@mock_response)
        subject.get_solr_response_for_field_values('field_name', ['a', 'b'])
      end

      it "should escape crazy identifiers" do
        subject.should_receive(:find).with(hash_including(:q => "field_name:(\"h://\\\"\\\'\")")).and_return(@mock_response)
        subject.get_solr_response_for_field_values('field_name', 'h://"\'')
      end
    end

# TODO:  more complex queries!  phrases, offset into search results, non-latin, boosting(?)
#  search within query building (?)
#  search + facets (search done first; facet selected first, both selected)

# TODO: maybe eventually check other types of solr requests
#  more like this
#  nearby on shelf
  it "should raise a Blacklight exception if RSolr can't connect to the Solr instance" do
    blacklight_solr.stub(:send_and_receive).and_raise(Errno::ECONNREFUSED)
    expect { subject.find(:a => 123) }.to raise_exception(/Unable to connect to Solr instance/)
  end

  describe "grouped_key_for_results" do
    it "should pull the grouped key out of the config" do
      blacklight_config.index.group = 'xyz'
      expect(subject.grouped_key_for_results).to eq('xyz')
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

  describe "#get_previous_and_next_documents_for_search" do
    before do
      @full_response, @all_docs = subject.get_search_results({:q => ''}, :rows => 1000)
    end

    it "should return the previous and next documents for a search" do
      response, docs = subject.get_previous_and_next_documents_for_search(4, :q => '')

      expect(docs.first.id).to eq @all_docs[3].id
      expect(docs.last.id).to eq @all_docs[5].id
    end

    it "should return only the next document if the counter is 0" do
      response, docs = subject.get_previous_and_next_documents_for_search(0, :q => '')

      expect(docs.first).to be_nil
      expect(docs.last.id).to eq @all_docs[1].id
    end

    it "should return only the previous document if the counter is the total number of documents" do
      response, docs = subject.get_previous_and_next_documents_for_search(@full_response.total - 1, :q => '')
      expect(docs.first.id).to eq @all_docs.slice(-2).id
      expect(docs.last).to be_nil
    end

    it "should return an array of nil values if there is only one result" do
      response, docs = subject.get_previous_and_next_documents_for_search(0, :q => 'id:2007020969')
      expect(docs.last).to be_nil
      expect(docs.first).to be_nil
    end
  end
end
