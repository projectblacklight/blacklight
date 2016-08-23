# frozen_string_literal: true

describe Blacklight::SearchBuilder do
  let(:processor_chain) { [] }
  let(:blacklight_config) { Blacklight::Configuration.new }
  let(:scope) { double blacklight_config: blacklight_config }
  subject { described_class.new processor_chain, scope }

  context "with default processor chain" do
    context "with two arguments" do
      subject do
        Deprecation.silence Blacklight::SearchBuilder do
          described_class.new true, scope
        end
      end
      it "uses the class-level default_processor_chain" do
        expect(subject.processor_chain).to eq []
      end
    end

    context "with one arguments" do
      subject { described_class.new scope }
      it "uses the class-level default_processor_chain" do
        expect(subject.processor_chain).to eq []
      end
    end
  end

  describe "#with" do
    it "sets the blacklight params" do
      params = {}
      subject.with(params)
      expect(subject.blacklight_params).to eq params
    end

    it "dups the params" do
      params = {}
      subject.with(params).where('asdf')
      expect(subject.blacklight_params).not_to eq params
      expect(subject.blacklight_params[:q]).to eq 'asdf'
      expect(params[:q]).not_to eq 'asdf'
    end
  end

  describe "#processor_chain" do
    let(:processor_chain) { [:a, :b, :c] }
    it "is mutable" do
      subject.processor_chain.insert(-1, :d)
      expect(subject.processor_chain).to match_array [:a, :b, :c, :d]
    end
  end

  describe "#append" do
    let(:processor_chain) { [:a, :b, :c] }
    it "provides a new search builder with the processor chain" do
      builder = subject.append(:d, :e)
      expect(subject.processor_chain).to eq processor_chain
      expect(builder.processor_chain).not_to eq subject.processor_chain
      expect(builder.processor_chain).to match_array [:a, :b, :c, :d, :e]
    end
  end

  describe "#except" do
    let(:processor_chain) { [:a, :b, :c, :d, :e] }
    it "provide a new search builder excepting arguments" do
      builder = subject.except(:b, :d, :does_not_exist)
      expect(builder).not_to equal(subject)
      expect(subject.processor_chain).to eq processor_chain
      expect(builder.processor_chain).not_to eq subject.processor_chain
      expect(builder.processor_chain).to match_array [:a, :c, :e]
    end
  end

  describe "#to_hash" do
    it "updates if data is changed" do
      subject.merge(q: 'xyz')
      expect(subject.to_hash).to include q: 'xyz'
      subject.merge(q: 'abc')
      expect(subject.to_hash).to include q: 'abc'
    end
  end

  describe "#merge" do
    let(:processor_chain) { [:pass_through] }
    before do
      allow(subject).to receive(:pass_through) do |req_params|
        req_params.replace subject.blacklight_params
      end
    end
    it "overwrites the processed parameters" do
      actual = subject.with(q: 'abc').merge(q: 'xyz')
      expect(actual[:q]).to eq 'xyz'
    end
  end

  describe "#reverse_merge" do
    let(:processor_chain) { [:pass_through] }
    before do
      allow(subject).to receive(:pass_through) do |req_params|
        req_params.replace subject.blacklight_params
      end
    end

    it "provides default values for parameters" do
      actual = subject.reverse_merge(a: 1)
      expect(actual[:a]).to eq 1
    end

    it "does not overwrite the processed parameters" do
      actual = subject.with(q: 'abc').reverse_merge(q: 'xyz')
      expect(actual[:q]).to eq 'abc'
    end
  end

  describe "#processed_parameters" do
    let(:processor_chain) { [:step_1] }

    it "tries to run the processor method on the search builder" do
      allow(subject).to receive(:step_1) do |req_params|
        req_params[:step_1] = 'builder'
      end

      subject.with(a: 1)
      expect(subject.processed_parameters).to include step_1: 'builder'
    end
  end

  describe "#blacklight_config" do
    it "gets the blacklight_config from the scope" do
      expect(subject.blacklight_config).to eq scope.blacklight_config
    end
  end

  describe "#page" do
    it "is the current user parameter page number" do
      expect(subject.with(page: 2).send(:page)).to eq 2
    end

    it "is page 1 if not page number given" do
      expect(subject.send(:page)).to eq 1
    end

    it "coerces parameters to integers" do
      expect(subject.with(page: '2b').send(:page)).to eq 2
    end
  end

  describe "#rows" do
    it "is nil if no value is set" do
      blacklight_config.default_per_page = nil
      blacklight_config.per_page = []
      expect(subject.rows).to be_nil
    end

    it "sets the number of rows" do
      expect(subject.rows(17).rows).to eq 17
    end

    it "is the per_page parameter" do
      expect(subject.with(per_page: 5).rows).to eq 5
    end

    it "supports the legacy 'rows' parameter" do
      expect(subject.with(rows: 10).rows).to eq 10
    end

    it "is set to the configured default" do
      blacklight_config.default_per_page = 42
      expect(subject.rows).to eq 42
    end

    it "limits the number of rows to the configured maximum" do
      blacklight_config.max_per_page = 1000
      expect(subject.rows(1001).rows).to eq 1000
    end
  end

  describe "#sort" do
    it "passes through the sort parameter" do
      expect(subject.with(sort: 'x').send(:sort)).to eq 'x'
    end

    it "uses the default if no sort parameter is given" do
      blacklight_config.default_sort_field = double(sort: 'x desc')
      expect(subject.send(:sort)).to eq 'x desc'
    end

    it "uses the requested sort field" do
      blacklight_config.add_sort_field 'x', sort: 'x asc'
      expect(subject.with(sort: 'x').send(:sort)).to eq 'x asc'
    end
  end

  describe "#facet" do
    it "is nil if no value is set" do
      expect(subject.facet).to be_nil
    end

    it "sets facet value" do
      expect(subject.facet('format').facet).to eq 'format'
    end
  end

  describe "#search_field" do
    it "uses the requested search field" do
      blacklight_config.add_search_field 'x'
      expect(subject.with(search_field: 'x').send(:search_field)).to eq blacklight_config.search_fields['x']
    end
  end

  describe "#params_changed?" do
    it "is false" do
      expect(subject.send(:params_changed?)).to eq false
    end

    it "is marked as changed when with() changes" do
      subject.with(a: 1)
      expect(subject.send(:params_changed?)).to eq true
    end

    it "is marked as changed when where() changes" do
      subject.where(a: 1)
      expect(subject.send(:params_changed?)).to eq true
    end

    it "is marked as changed when the processor chain changes" do
      subject.append(:a)
      expect(subject.send(:params_changed?)).to eq true
    end

    it "is marked as changed when merged parameters are added" do
      subject.merge(a: 1)
      expect(subject.send(:params_changed?)).to eq true
    end

    it "is marked as changed when reverse merged parameters are added" do
      subject.reverse_merge(a: 1)
      expect(subject.send(:params_changed?)).to eq true
    end

    it "is marked as changed when pagination changes" do
      expect(subject).to receive(:page=).with(1).and_call_original
      subject.page(1)
      expect(subject.send(:params_changed?)).to eq true
    end

    it "is marked as changed when rows changes" do
      expect(subject).to receive(:rows=).with(1).and_call_original
      subject.rows(1)
      expect(subject.send(:params_changed?)).to eq true
    end

    it "is marked as changed when start offset changes" do
      expect(subject).to receive(:start=).with(1).and_call_original
      subject.start(1)
      expect(subject.send(:params_changed?)).to eq true
    end
  end
end
