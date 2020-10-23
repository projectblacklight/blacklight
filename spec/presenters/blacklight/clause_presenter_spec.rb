# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Blacklight::ClausePresenter, type: :presenter do
  subject(:presenter) do
    described_class.new('0', params.with_indifferent_access.dig(:clause, '0'), field_config, controller.view_context, search_state)
  end

  let(:field_config) { Blacklight::Configuration::NullField.new key: 'some_field' }
  let(:search_state) { Blacklight::SearchState.new(params.with_indifferent_access, Blacklight::Configuration.new) }
  let(:params) { {} }

  describe '#field_label' do
    it 'returns a label for the field' do
      expect(subject.field_label).to eq 'Some Field'
    end
  end

  describe '#label' do
    let(:params) { { clause: { '0' => { query: 'some search string' } } } }

    it 'returns the query value for the clause' do
      expect(subject.label).to eq 'some search string'
    end
  end

  describe '#remove_href' do
    let(:params) { { clause: { '0' => { query: 'some_search_string' } } } }

    it 'returns the href to remove the search clause' do
      expect(subject.remove_href).not_to include 'some_search_string'
    end
  end
end
