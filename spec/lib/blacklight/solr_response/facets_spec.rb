require 'spec_helper'

describe Blacklight::SolrResponse::Facets do
  describe Blacklight::SolrResponse::Facets::FacetField do

    describe "A field with default options" do
      subject { Blacklight::SolrResponse::Facets::FacetField.new "my_field", [] }

      its(:name) { should eq "my_field" }
      its(:limit) { should eq 100 }
      its(:sort) { should eq 'count' }
      its(:offset) { should eq 0 }
    end

    describe "A field with additional options" do
      subject { Blacklight::SolrResponse::Facets::FacetField.new "my_field", [], limit: 15, sort: 'alpha', offset: 23 }

      its(:name) { should eq "my_field" }
      its(:limit) { should eq 15 }
      its(:sort) { should eq 'alpha' }
      its(:offset) { should eq 23 }
    end
  end

  describe "#facet_by_field_name" do
    let(:facet_field) { ['my_field', []] }
    let(:response_header) { { params: request_params }}
    let(:request_params) { Hash.new }
    subject { Blacklight::SolrResponse.new({responseHeader: response_header, facet_counts: { facet_fields: [facet_field] }}.with_indifferent_access, request_params)  }

    describe "#limit" do
      it "should extract a field-specific limit value" do
        request_params['f.my_field.facet.limit'] = "10"
        request_params['facet.limit'] = "15"
        expect(subject.facet_by_field_name('my_field').limit).to eq 10
      end

      it "should extract a global limit value" do
        request_params['facet.limit'] = "15"
        expect(subject.facet_by_field_name('my_field').limit).to eq 15
      end

      it "should be the solr default limit if no value is found" do
        expect(subject.facet_by_field_name('my_field').limit).to eq 100
      end
    end

    describe "#offset" do
      it "should extract a field-specific offset value" do
        request_params['f.my_field.facet.offset'] = "10"
        request_params['facet.offset'] = "15"
        expect(subject.facet_by_field_name('my_field').offset).to eq 10
      end

      it "should extract a global offset value" do
        request_params['facet.offset'] = "15"
        expect(subject.facet_by_field_name('my_field').offset).to eq 15
      end

      it "should be nil if no value is found" do
        expect(subject.facet_by_field_name('my_field').offset).to eq 0
      end
    end

    describe "#sort" do
      it "should extract a field-specific sort value" do
        request_params['f.my_field.facet.sort'] = "alpha"
        request_params['facet.sort'] = "index"
        expect(subject.facet_by_field_name('my_field').sort).to eq 'alpha'
      end

      it "should extract a global sort value" do
        request_params['facet.sort'] = "alpha"
        expect(subject.facet_by_field_name('my_field').sort).to eq 'alpha'
      end

      it "should default to count if no value is found and the default limit is used" do
        expect(subject.facet_by_field_name('my_field').sort).to eq 'count'
      end
      
      it "should default to index if no value is found and the limit is unlimited" do
        request_params['facet.limit'] = -1
        expect(subject.facet_by_field_name('my_field').sort).to eq 'index'
      end
    end
  end
end
