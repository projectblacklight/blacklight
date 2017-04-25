# frozen_string_literal: true

RSpec.describe Blacklight::SearchState do
  let(:blacklight_config) do
    Blacklight::Configuration.new.configure do |config|
      config.index.title_field = 'title_display'
      config.index.display_type_field = 'format'
    end
  end

  let(:parameter_class) { ActionController::Parameters }
  let(:search_state) { described_class.new(params, blacklight_config) }
  let(:params) { parameter_class.new }

  describe '#to_h' do
    let(:data) { { a: '1'} }
    let(:params) { parameter_class.new data }

    it 'returns a copy of the original parameters' do
      expect(search_state.to_h).to eq data.with_indifferent_access
      expect(search_state.to_h.object_id).not_to eq params.object_id
    end

    context 'with AC::Parameters' do
      let(:parameter_class) { ActionController::Parameters }

      it 'returns the hash data' do
        expect(search_state.to_h).to eq data.with_indifferent_access
      end
    end

    context 'with HashWithIndifferentAccess' do
      let(:parameter_class) { HashWithIndifferentAccess }

      it 'returns the hash data' do
        expect(search_state.to_h).to eq data.with_indifferent_access
      end
    end

    context 'with Hash' do
      let(:params) { data }

      it 'returns the hash data' do
        expect(search_state.to_h).to eq data.with_indifferent_access
      end
    end
  end

  describe "params_for_search" do
    let(:params) { parameter_class.new 'default' => 'params' }

    it "takes original params" do
      result = search_state.params_for_search
      expect(result).to eq({ 'default' => 'params' })
      expect(params.object_id).to_not eq result.object_id
    end

    it "accepts params to merge into the controller's params" do
      result = search_state.params_for_search(q: 'query')
      expect(result).to eq('q' => 'query', 'default' => 'params')
    end

    context "when params have blacklisted keys" do
      let(:params) { parameter_class.new action: 'action', controller: 'controller', id: "id", commit: 'commit' }
      it "removes them" do
        result = search_state.params_for_search
        expect(result.keys).to_not include(:action, :controller, :commit, :id)
      end
    end

    context "when params has page" do
      context "and per_page changed" do
        let(:params) { parameter_class.new per_page: 20, page: 5 }
        it "adjusts the current page" do
          result = search_state.params_for_search(per_page: 100)
          expect(result[:page]).to eq 1
        end
      end

      context "and per_page didn't change" do
        let(:params) { parameter_class.new per_page: 20, page: 5 }
        it "doesn't change the current page" do
          result = search_state.params_for_search(per_page: 20)
          expect(result[:page]).to eq 5
        end
      end

      context "and the sort changes" do
        let(:params) { parameter_class.new sort: 'field_a', page: 5 }
        it "adjusts the current page" do
          result = search_state.params_for_search(sort: 'field_b')
          expect(result[:page]).to eq 1
        end
      end

      context "and the sort didn't change" do
        let(:params) { parameter_class.new sort: 'field_a', page: 5 }
        it "doesn't change the current page" do
          result = search_state.params_for_search(sort: 'field_a')
          expect(result[:page]).to eq 5
        end
      end
    end

    context "with a block" do
      let(:params) { parameter_class.new a: 1, b: 2 }
      it "evalutes the block and allow it to add or remove keys" do
        result = search_state.params_for_search(c: 3) do |params|
          params.extract! :a, :b
          params[:d] = 'd'
        end

        expect(result.keys).to_not include(:a, :b)
        expect(result[:c]).to eq 3
        expect(result[:d]).to eq 'd'
      end
    end
  end

  describe "add_facet_params" do
    let(:params_no_existing_facet) do
      parameter_class.new q: "query",
                                       search_field: "search_field",
                                       per_page: "50"
    end
    let(:params_existing_facets) do
      parameter_class.new q: "query",
                                       search_field: "search_field",
                                       per_page: "50",
                                       f: { "facet_field_1" => ["value1"],
                                            "facet_field_2" => ["value2", "value2a"] }
    end

    context "when there are no pre-existing facets" do
      let(:params) { params_no_existing_facet }
      it "adds facet value" do
        result_params = search_state.add_facet_params("facet_field", "facet_value")
        expect(result_params[:f]).to be_a Hash
        expect(result_params[:f]["facet_field"]).to be_a_kind_of(Array)
        expect(result_params[:f]["facet_field"]).to eq ["facet_value"]
      end

      it "leaves non-facet params alone" do
        result_params = search_state.add_facet_params("facet_field_2", "new_facet_value")

        params.each_pair do |key, value|
          next if key == :f
          expect(result_params[key]).to eq params[key]
        end
      end

      it "uses the facet's key in the url" do
        allow(search_state).to receive(:facet_configuration_for_field).with('some_field').and_return(double(single: true, field: "a_solr_field", key: "some_key"))

        result_params = search_state.add_facet_params('some_field', 'my_value')

        expect(result_params[:f]['some_key']).to have(1).item
        expect(result_params[:f]['some_key'].first).to eq 'my_value'
      end
    end

    context "when there are pre-existing facets" do
      let(:params) { params_existing_facets }
      it "adds a facet param to existing facet constraints" do
        result_params = search_state.add_facet_params("facet_field_2", "new_facet_value")

        expect(result_params[:f]).to be_a Hash

        params_existing_facets[:f].each_pair do |facet_field, value_list|
          expect(result_params[:f][facet_field]).to be_a_kind_of(Array)
          if facet_field == 'facet_field_2'
            expect(result_params[:f][facet_field]).to eq (params_existing_facets[:f][facet_field] | ["new_facet_value"])
          else
            expect(result_params[:f][facet_field]).to eq params_existing_facets[:f][facet_field]
          end
        end
      end

      it "leaves non-facet params alone" do
        result_params = search_state.add_facet_params("facet_field_2", "new_facet_value")

        params.each_pair do |key, value|
          next if key == 'f'
          expect(result_params[key]).to eq params[key]
        end
      end
    end

    context "with a facet selected in the params" do
      let(:params) { parameter_class.new f: { 'single_value_facet_field' => 'other_value' } }
      it "replaces facets configured as single" do
        allow(search_state).to receive(:facet_configuration_for_field).with('single_value_facet_field').and_return(double(single: true, key: "single_value_facet_field"))
        result_params = search_state.add_facet_params('single_value_facet_field', 'my_value')

        expect(result_params[:f]['single_value_facet_field']).to have(1).item
        expect(result_params[:f]['single_value_facet_field'].first).to eq 'my_value'
      end
    end

    it "accepts a FacetItem instead of a plain facet value" do
      result_params = search_state.add_facet_params('facet_field_1', double(value: 123))

      expect(result_params[:f]['facet_field_1']).to include(123)
    end

    it "defers to the field set on a FacetItem" do
      result_params = search_state.add_facet_params('facet_field_1', double(:field => 'facet_field_2', :value => 123))

      expect(result_params[:f]['facet_field_1']).to be_blank
      expect(result_params[:f]['facet_field_2']).to include(123)
    end

    it "adds any extra fq parameters from the FacetItem" do
      result_params = search_state.add_facet_params('facet_field_1', double(:value => 123, fq: { 'facet_field_2' => 'abc' }))

      expect(result_params[:f]['facet_field_1']).to include(123)
      expect(result_params[:f]['facet_field_2']).to include('abc')
    end
  end

  describe "add_facet_params_and_redirect" do
    let(:params) { parameter_class.new(
                    q: "query",
                    search_field: "search_field",
                    per_page: "50",
                    page: "5",
                    f: { "facet_field_1" => ["value1"], "facet_field_2" => ["value2", "value2a"] },
                    Blacklight::Solr::FacetPaginator.request_keys[:page] => "100",
                    Blacklight::Solr::FacetPaginator.request_keys[:sort] => "index",
                    id: 'facet_field_name')
    }

    it "does not include request parameters used by the facet paginator" do
      params = search_state.add_facet_params_and_redirect("facet_field_2", "facet_value")

      bad_keys = Blacklight::Solr::FacetPaginator.request_keys.values + [:id]
      bad_keys.each do |paginator_key|
        expect(params.keys).to_not include(paginator_key)
      end
    end

    it 'removes :page request key' do
      params = search_state.add_facet_params_and_redirect("facet_field_2", "facet_value")
      expect(params).to_not have_key(:page)
    end

    it "otherwise does the same thing as add_facet_params" do
      added_facet_params = search_state.add_facet_params("facet_field_2", "facet_value")
      added_facet_params_from_facet_action = search_state.add_facet_params_and_redirect("facet_field_2", "facet_value")

      expect(added_facet_params_from_facet_action).to eq added_facet_params.except(Blacklight::Solr::FacetPaginator.request_keys[:page], Blacklight::Solr::FacetPaginator.request_keys[:sort])
    end
  end

  describe "#remove_facet_params" do
    let(:params) { parameter_class.new 'f' => facet_params }
    let(:facet_params) { { } }
    context "when the facet has multiple values" do
      let(:facet_params) { { 'some_field' => ['some_value', 'another_value'] } }

      it "removes the facet / value tuple from the query parameters" do
        params = search_state.remove_facet_params('some_field', 'some_value')
        expect(params[:f]['some_field']).not_to include 'some_value'
        expect(params[:f]['some_field']).to include 'another_value'
      end
    end

    context "when the facet has configuration" do
      before do
        allow(search_state).to receive(:facet_configuration_for_field).with('some_field').and_return(
          double(single: true, field: "a_solr_field", key: "some_key"))
      end
      let(:facet_params) { { 'some_key' => ['some_value', 'another_value'] } }

      it "uses the facet's key configuration" do
        params = search_state.remove_facet_params('some_field', 'some_value')
        expect(params[:f]['some_key']).not_to eq 'some_value'
        expect(params[:f]['some_key']).to include 'another_value'
      end
    end

    it "removes the facet entirely when the last facet value is removed" do
      facet_params['another_field'] = ['some_value']
      facet_params['some_field'] = ['some_value']

      params = search_state.remove_facet_params('some_field', 'some_value')

      expect(params[:f]).not_to have_key 'some_field'
    end

    it "removes the 'f' parameter entirely when no facets remain" do
      facet_params['some_field'] = ['some_value']

      params = search_state.remove_facet_params('some_field', 'some_value')

      expect(params).not_to have_key :f
    end
  end
end
