# frozen_string_literal: true

RSpec.describe Blacklight::SearchState::FilterField do
  let(:search_state) { Blacklight::SearchState.new(params.with_indifferent_access, blacklight_config, controller) }

  let(:params) { { f: { some_field: %w[1 2], another_field: ['3'] } } }
  let(:blacklight_config) do
    Blacklight::Configuration.new.configure do |config|
      config.add_facet_field 'new_field'
      config.add_facet_field 'another_field', single: true
      simple_facet_fields.each { |simple_facet_field| config.add_facet_field simple_facet_field }
      config.search_state_fields = config.search_state_fields + additional_search_fields
    end
  end
  let(:simple_facet_fields) { [:some_field] }
  let(:additional_search_fields) { [] }
  let(:controller) { double }

  describe '#add' do
    it 'adds the parameter to the filter list' do
      filter = search_state.filter('some_field')
      new_state = filter.add('4')

      expect(new_state.filter('some_field').values).to eq %w[1 2 4]
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
      let(:simple_facet_fields) { [:some_field, :some_other_field] }

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

    context 'with an array' do
      let(:params) do
        { f: { another_field: ['3'] }, f_inclusive: { some_field: %w[a b c] } }
      end

      it 'creates a new group with the new values' do
        filter = search_state.filter('new_field')
        new_state = filter.add(%w[x y z])

        expect(new_state.filter('new_field').values).to eq [%w[x y z]]
      end

      it 'updates any existing groups with the new values' do
        filter = search_state.filter('some_field')
        new_state = filter.add(%w[x y z])

        expect(new_state.filter('some_field').values).to eq [%w[x y z]]
      end

      it 'leaves existing filters alone' do
        filter = search_state.filter('another_field')
        new_state = filter.add(%w[x y z])

        expect(new_state.filter('another_field').values).to eq ['3', %w[x y z]]
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

    context 'with an array' do
      let(:params) do
        { f: { another_field: ['3'] }, f_inclusive: { some_field: %w[a b c], another_field: %w[x y z] } }
      end

      it 'removes groups of values' do
        filter = search_state.filter('some_field')
        new_state = filter.remove(%w[a b c])

        expect(new_state.params[:f_inclusive]).not_to include :some_field
        expect(new_state.filter('some_field').values).to eq []
      end

      it 'can remove single values' do
        filter = search_state.filter('some_field')
        new_state = filter.remove(%w[a])

        expect(new_state.filter('some_field').values).to eq [%w[b c]]
      end

      it 'leaves existing filters alone' do
        filter = search_state.filter('another_field')
        new_state = filter.remove(%w[x y z])

        expect(new_state.filter('another_field').values).to eq ['3']
      end
    end

    context "With facet.missing field" do
      let(:params) do
        { f: { '-some_field': ["[* TO *]"] } }
      end

      it "removes facet.missing facet params" do
        filter = search_state.filter("some_field")
        new_state = filter.remove(OpenStruct.new(key: 'some_field', missing: true))

        expect(new_state.params).to eq({})
      end
    end
  end

  describe '#values' do
    it 'returns the currently selected values of the filter' do
      expect(search_state.filter('some_field').values).to eq %w[1 2]
    end

    context 'with an array' do
      let(:params) do
        { f: { some_field: ['3'] }, f_inclusive: { some_field: %w[a b c] } }
      end

      it 'combines the exclusive and inclusive values' do
        expect(search_state.filter('some_field').values).to eq ['3', %w[a b c]]
      end
    end
  end

  describe '#include?' do
    it 'checks whether the value is currently selected' do
      expect(search_state.filter('some_field').include?('1')).to be true
      expect(search_state.filter('some_field').include?('3')).to be false
    end

    it 'handles value indirection' do
      expect(search_state.filter('some_field').include?(OpenStruct.new(value: '1'))).to be true
    end
  end

  describe '#permitted_params' do
    context 'with a pivot facet' do
      let(:blacklight_config) do
        Blacklight::Configuration.new.configure do |config|
          config.add_facet_field 'my_pivot', pivot: %w[format language_ssim]
        end
      end

      it 'marks all the pivot fields as permitted' do
        field = described_class.new blacklight_config.facet_fields['my_pivot'], search_state
        expect(field.permitted_params).to eq({
                                               f: { "-format" => [], "-language_ssim" => [], "format" => [], "language_ssim" => [] },
                                               f_inclusive: { "format" => [], "language_ssim" => [] }
                                             })
      end
    end
  end
end
