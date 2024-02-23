# frozen_string_literal: true

RSpec.describe Blacklight::SearchState::PivotFilterField do
  let(:value_class) { described_class::PivotValue }
  let(:search_state) { Blacklight::SearchState.new(params.with_indifferent_access, blacklight_config, controller) }

  let(:params) { { f: { some_field: %w[1 2], some_other_field: ['3'] } } }
  let(:blacklight_config) do
    Blacklight::Configuration.new.configure do |config|
      config.add_facet_field 'pivot_field', pivot: %w[some_field some_other_field], filter_class: described_class
    end
  end
  let(:controller) { double }

  describe '#add' do
    context 'with a string value' do
      it 'adds the parameter to the first pivot\'s filter list' do
        filter = search_state.filter('pivot_field')
        new_state = filter.add('4')

        expect(new_state.filter('some_field').values).to eq %w[1 2 4]
        expect(new_state.filter('pivot_field').values&.map(&:value)).to eq %w[1 2 4]
      end

      context 'without any parameters in the url' do
        let(:params) { {} }

        it 'adds the necessary structure' do
          filter = search_state.filter('some_field')
          new_state = filter.add('1')

          expect(new_state.filter('pivot_field').values&.map(&:value)).to eq %w[1]
          expect(new_state.params).to include(:f)
        end
      end
    end

    context 'with a pivot facet-type item' do
      it 'includes the pivot facet fqs' do
        filter = search_state.filter('pivot_field')
        new_state = filter.add(value_class.new(fq: { some_other_field: '5' }, value: '4'))

        expect(new_state.filter('some_field').values).to eq %w[1 2 4]
        expect(new_state.filter('some_other_field').values).to eq %w[3 5]
      end
    end

    context 'with an array' do
      pending 'decide how inclusive facets should work with pivots'
    end
  end

  describe '#remove' do
    it 'returns a search state without the given filter applied' do
      filter = search_state.filter('some_field')
      new_state = filter.remove('1')

      expect(new_state.filter('pivot_field').values&.map(&:value)).to eq ['2']
    end

    context 'with a pivot facet-type item' do
      it 'includes the pivot facet fqs' do
        filter = search_state.filter('pivot_field')
        new_state = filter.remove(value_class.new(fq: { some_other_field: '3' }, value: '1'))

        expect(new_state.filter('some_field').values).to eq %w[2]
        expect(new_state.filter('some_other_field').values).to eq []
      end
    end

    it 'removes the whole field if there are no filter left for the field' do
      filter = search_state.filter('pivot_field')
      new_state = filter.remove(value_class.new(fq: { some_other_field: '3' }, value: '1'))

      expect(new_state.params[:f]).not_to include :some_other_field
      expect(new_state.filter('pivot_field').values&.map(&:fq)).to eql([some_other_field: nil])
    end

    it 'removes the filter parameter entirely if there are no filters left' do
      filter = search_state.filter('pivot_field')
      new_state = filter.remove(value_class.new(fq: { some_other_field: '3' }, value: '1'))
      new_state = new_state.filter('pivot_field').remove(value_class.new(fq: { some_other_field: '3' }, value: '2'))

      expect(new_state.filter('pivot_field').values).to eq []
      expect(new_state.params).not_to include :f
    end

    context 'with an array' do
      pending 'decide how inclusive facets should work with pivots'
    end

    context "With facet.missing field" do
      pending 'decide how facet.missing should work with pivots'
    end
  end

  describe '#values' do
    it 'returns the currently selected values of the filter' do
      expect(search_state.filter('pivot_field').values.map(&:value)).to eq %w[1 2]
    end

    context 'with an array' do
      pending 'decide how inclusive facets should work with pivots'
    end
  end

  describe '#include?' do
    it 'checks whether the value is currently selected' do
      expect(search_state.filter('some_field').include?('1')).to be true
      expect(search_state.filter('some_field').include?('3')).to be false
    end

    it 'handles value indirection' do
      expect(search_state.filter('some_field').include?(value_class.new(value: '1'))).to be true
    end
  end
end
