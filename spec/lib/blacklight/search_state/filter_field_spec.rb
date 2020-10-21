# frozen_string_literal: true

RSpec.describe Blacklight::SearchState::FilterField do
  let(:search_state) { Blacklight::SearchState.new(params.with_indifferent_access, blacklight_config, controller) }

  let(:params) { { f: { some_field: %w[1 2], another_field: ['3'] } } }
  let(:blacklight_config) do
    Blacklight::Configuration.new.configure do |config|
      config.add_facet_field 'some_field'
      config.add_facet_field 'another_field', single: true
    end
  end
  let(:controller) { double }

  describe '#add' do
    it 'adds the parameter to the filter list' do
      filter = search_state.filter('some_field')
      new_state = filter.add('4')

      expect(new_state.filter('some_field').values).to eq %w[1 2 4]
    end

    it 'creates new parameter as needed' do
      filter = search_state.filter('unknown_field')
      new_state = filter.add('4')

      expect(new_state.filter('unknown_field').values).to eq %w[4]
      expect(new_state.params[:f]).to include(:unknown_field)
    end

    context 'without any parameters in the url' do
      let(:params) { {} }

      it 'adds the necessary structure' do
        filter = search_state.filter('some_field')
        new_state = filter.add('1')

        expect(new_state.filter('some_field').values).to eq %w[1]
        expect(new_state.params).to include(:f)
      end
    end

    context 'with a single-valued field' do
      it 'replaces any existing parameter from the filter list' do
        filter = search_state.filter('another_field')
        new_state = filter.add('5')

        expect(new_state.filter('another_field').values).to eq %w[5]
      end
    end

    context 'with a pivot facet-type item' do
      it 'includes the pivot facet fqs' do
        filter = search_state.filter('some_field')
        new_state = filter.add(OpenStruct.new(fq: { some_other_field: '5' }, value: '4'))

        expect(new_state.filter('some_field').values).to eq %w[1 2 4]
        expect(new_state.filter('some_other_field').values).to eq %w[5]
      end

      it 'handles field indirection' do
        filter = search_state.filter('some_field')
        new_state = filter.add(OpenStruct.new(field: 'some_other_field', value: '4'))

        expect(new_state.filter('some_other_field').values).to eq %w[4]
      end

      it 'handles value indirection' do
        filter = search_state.filter('some_field')
        new_state = filter.add(OpenStruct.new(value: '4'))

        expect(new_state.filter('some_field').values).to eq %w[1 2 4]
      end
    end
  end

  describe '#remove' do
    it 'returns a search state without the given filter applied' do
      filter = search_state.filter('some_field')
      new_state = filter.remove('1')

      expect(new_state.filter('some_field').values).to eq ['2']
    end

    it 'removes the whole field if there are no filter left for the field' do
      filter = search_state.filter('another_field')
      new_state = filter.remove('3')

      expect(new_state.filter('another_field').values).to eq []
      expect(new_state.params[:f]).not_to include :another_field
    end

    it 'removes the filter parameter entirely if there are no filters left' do
      new_state = search_state.filter('some_field').remove('1')
      new_state = new_state.filter('some_field').remove('2')
      new_state = new_state.filter('another_field').remove('3')

      expect(new_state.params).not_to include :f
    end

    it 'handles value indirection' do
      filter = search_state.filter('some_field')
      new_state = filter.remove(OpenStruct.new(value: '1'))

      expect(new_state.filter('some_field').values).to eq ['2']
    end
  end

  describe '#values' do
    it 'returns the currently selected values of the filter' do
      expect(search_state.filter('some_field').values).to eq %w[1 2]
    end
  end

  describe '#include?' do
    it 'checks whether the value is currently selected' do
      expect(search_state.filter('some_field').include?('1')).to eq true
      expect(search_state.filter('some_field').include?('3')).to eq false
    end

    it 'handles value indirection' do
      expect(search_state.filter('some_field').include?(OpenStruct.new(value: '1'))).to eq true
    end
  end
end
