# frozen_string_literal: true

RSpec.describe Blacklight::Solr::Response::Facets, api: true do
  describe Blacklight::Solr::Response::Facets::FacetField do
    describe "A field with default options" do
      subject { described_class.new "my_field", [] }

      its(:name) { is_expected.to eq "my_field" }
      its(:limit) { is_expected.to eq 100 }
      its(:sort) { is_expected.to eq 'count' }
      its(:offset) { is_expected.to eq 0 }
    end

    describe "A field with additional options" do
      subject { described_class.new "my_field", [], limit: 15, sort: 'alpha', offset: 23 }

      its(:name) { is_expected.to eq "my_field" }
      its(:limit) { is_expected.to eq 15 }
      its(:sort) { is_expected.to eq 'alpha' }
      its(:offset) { is_expected.to eq 23 }
    end
  end

  describe "#aggregations" do
    subject { Blacklight::Solr::Response.new({ responseHeader: response_header, facet_counts: { facet_fields: [facet_field] } }, request_params) }

    let(:facet_field) { ['my_field', []] }
    let(:response_header) { { params: request_params } }
    let(:request_params) { {} }

    describe "#limit" do
      it "extracts a field-specific limit value" do
        request_params['f.my_field.facet.limit'] = "10"
        request_params['facet.limit'] = "15"
        expect(subject.aggregations['my_field'].limit).to eq 10
      end

      it "extracts a global limit value" do
        request_params['facet.limit'] = "15"
        expect(subject.aggregations['my_field'].limit).to eq 15
      end

      it "is the solr default limit if no value is found" do
        expect(subject.aggregations['my_field'].limit).to eq 100
      end
    end

    describe "#offset" do
      it "extracts a field-specific offset value" do
        request_params['f.my_field.facet.offset'] = "10"
        request_params['facet.offset'] = "15"
        expect(subject.aggregations['my_field'].offset).to eq 10
      end

      it "extracts a global offset value" do
        request_params['facet.offset'] = "15"
        expect(subject.aggregations['my_field'].offset).to eq 15
      end

      it "is nil if no value is found" do
        expect(subject.aggregations['my_field'].offset).to eq 0
      end
    end

    describe "#sort" do
      it "extracts a field-specific sort value" do
        request_params['f.my_field.facet.sort'] = "alpha"
        request_params['facet.sort'] = "index"
        expect(subject.aggregations['my_field'].sort).to eq 'alpha'
      end

      it "extracts a global sort value" do
        request_params['facet.sort'] = "alpha"
        expect(subject.aggregations['my_field'].sort).to eq 'alpha'
      end

      it "defaults to count if no value is found and the default limit is used" do
        expect(subject.aggregations['my_field'].sort).to eq 'count'
        expect(subject.aggregations['my_field'].count?).to eq true
      end

      it "defaults to index if no value is found and the limit is unlimited" do
        request_params['facet.limit'] = -1
        expect(subject.aggregations['my_field'].sort).to eq 'index'
        expect(subject.aggregations['my_field'].index?).to eq true
      end
    end

    describe '#prefix' do
      it 'extracts field-specific prefix values' do
        request_params['f.my_field.facet.prefix'] = "a"
        request_params['facet.prefix'] = "b"
        expect(subject.aggregations['my_field'].prefix).to eq 'a'
      end

      it "extracts a global sort value" do
        request_params['facet.prefix'] = "abc"
        expect(subject.aggregations['my_field'].prefix).to eq 'abc'
      end

      it "defaults to no prefix value" do
        expect(subject.aggregations['my_field'].prefix).to be_nil
      end
    end
  end

  describe "#merge_facet" do
    let(:response) { Blacklight::Solr::Response.new(facet_counts, {}, {}) }
    let(:facet) { { name: "foo", value: "bar", hits: 1 } }

    before do
      response.merge_facet(facet)
    end

    context "facet does not already exist" do
      it "adds the facet and appends the new field name and value" do
        expect(response.facet_fields["foo"]).to eq(["bar", 1])
      end
    end

    context "facet exists but field does not exist" do
      let(:facet) { { name: "cat", value: "bar", hits: 1 } }

      it "appends the new field name and value" do
        expect(response.facet_fields["cat"]).to eq(["memory", 3, "card", 2, "bar", 1])
      end
    end

    context "facet exists and field exists" do
      let(:facet) { { name: "cat", value: "memory", hits: 4 } }

      it "appends the new field name and value and aggregations uses new value" do
        expect(response.aggregations["cat"].items.count).to eq(2)
        expect(response.aggregations["cat"].items.first.value).to eq("memory")
        expect(response.aggregations["cat"].items.first.hits).to eq(4)
      end
    end

    def facet_counts
      { "facet_counts" => { "facet_fields" => { "cat" => ["memory", 3, "card", 2] } } }
    end
  end

  context "facet.missing" do
    subject { Blacklight::Solr::Response.new(response, {}) }

    let(:response) do
      {
        facet_counts: {
          facet_fields: {
            some_field: ['a', 1, nil, 2]
          }
        }
      }
    end

    it "marks the facet.missing field with a human-readable label and fq" do
      missing = subject.aggregations["some_field"].items.find { |i| i.value.nil? }

      expect(missing.label).to eq "[Missing]"
      expect(missing.fq).to eq "-some_field:[* TO *]"
    end
  end

  describe "query facets" do
    subject { Blacklight::Solr::Response.new(response, {}, blacklight_config: blacklight_config) }

    let(:facet_config) do
      double(
        key: 'my_query_facet_field',
        sort: nil,
        query: {
          'a_simple_query' => { fq: 'field:search', label: 'A Human Readable label' },
          'another_query' => { fq: 'field:different_search', label: 'Label' },
          'query_with_many_results' => { fq: 'field:many_result_search', label: 'Yet another label' },
          'without_results' => { fq: 'field:without_results', label: 'No results for this facet' }
        }
      )
    end

    let(:blacklight_config) { double(facet_fields: { 'my_query_facet_field' => facet_config }) }

    let(:response) do
      {
        facet_counts: {
          facet_queries: {
            'field:search' => 10,
            'field:different_search' => 2,
            'field:many_result_search' => 100,
            'field:not_appearing_in_the_config' => 50,
            'field:without_results' => 0
          }
        }
      }
    end

    it "converts the query facets into a double RSolr FacetField" do
      field = subject.aggregations['my_query_facet_field']

      expect(field).to be_a_kind_of Blacklight::Solr::Response::Facets::FacetField

      expect(field.name).to eq 'my_query_facet_field'
      expect(field.items.size).to eq 3
      expect(field.items.map(&:value)).not_to include 'field:not_appearing_in_the_config'

      facet_item = field.items.find { |x| x.value == 'a_simple_query' }

      expect(facet_item.value).to eq 'a_simple_query'
      expect(facet_item.hits).to eq 10
      expect(facet_item.label).to eq 'A Human Readable label'
    end

    describe 'default/index sorting' do
      it 'returns the results in the order they are requested by default' do
        field = subject.aggregations['my_query_facet_field']
        expect(field.items.map(&:value)).to eq %w[a_simple_query another_query query_with_many_results]
        expect(field.items.map(&:hits)).to eq [10, 2, 100]
      end

      it 'returns the results in the order they are requested by when sort is explicitly set to "index"' do
        allow(facet_config).to receive(:sort).and_return(:index)

        field = subject.aggregations['my_query_facet_field']
        expect(field.items.map(&:value)).to eq %w[a_simple_query another_query query_with_many_results]
        expect(field.items.map(&:hits)).to eq [10, 2, 100]
      end
    end

    describe 'count sorting' do
      it 'returns the results sorted by count when requested' do
        allow(facet_config).to receive(:sort).and_return(:count)

        field = subject.aggregations['my_query_facet_field']
        expect(field.items.map(&:value)).to eq %w[query_with_many_results a_simple_query another_query]
        expect(field.items.map(&:hits)).to eq [100, 10, 2]
      end
    end
  end

  describe "pivot facets" do
    subject { Blacklight::Solr::Response.new(response, {}, blacklight_config: blacklight_config) }

    let(:facet_config) do
      double(key: 'my_pivot_facet_field', query: nil, pivot: %w[field_a field_b])
    end

    let(:blacklight_config) { double(facet_fields: { 'my_pivot_facet_field' => facet_config }) }

    let(:response) do
      {
        facet_counts: {
          facet_pivot: {
            'field_a,field_b' => [
              {
                field: 'field_a',
                value: 'a',
                count: 10,
                pivot: [{ field: 'field_b', value: 'b', count: 2 }]
              }
            ]
          }
        }
      }
    end

    it "converts the pivot facet into a double RSolr FacetField" do
      field = subject.aggregations['my_pivot_facet_field']

      expect(field).to be_a_kind_of Blacklight::Solr::Response::Facets::FacetField

      expect(field.name).to eq 'my_pivot_facet_field'

      expect(field.items.size).to eq 1

      expect(field.items.first).to respond_to(:items)

      expect(field.items.first.items.size).to eq 1
      expect(field.items.first.items.first.fq).to eq('field_a' => 'a')
    end
  end
end
