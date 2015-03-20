require 'spec_helper'

describe Blacklight::SearchBuilder do
  let(:processor_chain) { [] }
  let(:blacklight_config) { Blacklight::Configuration.new }
  let(:scope) { double blacklight_config: blacklight_config }
  subject { described_class.new processor_chain, scope }

  context "with default processor chain" do
    subject { described_class.new true, scope }
    it "should use the class-level default_processor_chain" do
      expect(subject.processor_chain).to eq []
    end
  end

  describe "#with" do
    it "should set the blacklight params" do
      params = {}
      subject.with(params)
      expect(subject.blacklight_params).to eq params
    end

    it "should dup the params" do
      params = {}
      subject.with(params).where('asdf')
      expect(subject.blacklight_params).not_to eq params
      expect(subject.blacklight_params[:q]).to eq 'asdf'
      expect(params[:q]).not_to eq 'asdf'
    end
  end

  describe "#processor_chain" do
    let(:processor_chain) { [:a, :b, :c] }
    it "should be mutable" do
      subject.processor_chain.insert(-1, :d)
      expect(subject.processor_chain).to match_array [:a, :b, :c, :d]
    end
  end

  describe "#append" do
    let(:processor_chain) { [:a, :b, :c] }
    it "should provide a new search builder with the processor chain" do
      builder = subject.append(:d, :e)
      expect(subject.processor_chain).to eq processor_chain
      expect(builder.processor_chain).not_to eq subject.processor_chain
      expect(builder.processor_chain).to match_array [:a, :b, :c, :d, :e]
    end
  end

  describe "#query" do
    it "should append the extra parameters to the result" do
      actual = subject.query({a: 1})
      expect(actual).to include a: 1
    end
  end

  describe "#processed_parameters" do
    let(:processor_chain) { [:step_1] }
    it "should try to run the processor method on the provided scope" do
      allow(scope).to receive(:respond_to?).and_return(true)
      allow(scope).to receive(:step_1) do |req_params, user_params|
        req_params[:step_1] = 'scope'
        req_params[:user_params] = user_params
      end

      Deprecation.silence(Blacklight::SearchBuilder) do
        subject.with(a: 1)
        expect(subject.processed_parameters).to include step_1: 'scope', user_params: { a: 1 }
      end
    end

    it "should try to run the processor method on the search builder" do
      allow(subject).to receive(:step_1) do |req_params|
        req_params[:step_1] = 'builder'
      end

      subject.with(a: 1)
      expect(subject.processed_parameters).to include step_1: 'builder'
    end
  end

  describe "#blacklight_config" do
    it "should get the blacklight_config from the scope" do
      expect(subject.blacklight_config).to eq scope.blacklight_config
    end
  end

  describe "#page" do
    it "should be the current user parameter page number" do
      expect(subject.with(page: 2).send(:page)).to eq 2
    end

    it "should be page 1 if not page number given" do
      expect(subject.send(:page)).to eq 1
    end

    it "should coerce parameters to integers" do
      expect(subject.with(page: '2b').send(:page)).to eq 2
    end
  end

  describe "#rows" do

    it "should be nil if no value is set" do
      blacklight_config.default_per_page = nil
      blacklight_config.per_page = []
      expect(subject.rows).to be_nil
    end

    it "should set the number of rows" do
      expect(subject.rows(17).rows).to eq 17
    end

    it "should be the per_page parameter" do
      expect(subject.with(per_page: 5).rows).to eq 5
    end

    it "should support the legacy 'rows' parameter" do
      expect(subject.with(rows: 10).rows).to eq 10
    end

    it "should be set to the configured default" do
      blacklight_config.default_per_page = 42
      expect(subject.rows).to eq 42
    end

    it "should limit the number of rows to the configured maximum" do
      blacklight_config.max_per_page = 1000
      expect(subject.rows(1001).rows).to eq 1000
    end
  end

  describe "#sort" do
    it "should pass through the sort parameter" do
      expect(subject.with(sort: 'x').send(:sort)).to eq 'x'
    end

    it "should use the default if no sort parameter is given" do
      blacklight_config.default_sort_field = double(sort: 'x desc')
      expect(subject.send(:sort)).to eq 'x desc'
    end

    it "should use the requested sort field" do
      blacklight_config.add_sort_field 'x', sort: 'x asc'
      expect(subject.with(sort: 'x').send(:sort)).to eq 'x asc'
    end
  end

  describe "#search_field" do
    it "should use the requested search field" do
      blacklight_config.add_search_field 'x'
      expect(subject.with(search_field: 'x').send(:search_field)).to eq blacklight_config.search_fields['x']
    end
  end
end