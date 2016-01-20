# frozen_string_literal: true
require 'spec_helper'

describe Blacklight::SuggestSearch do
  let(:params) { {q: 'test'} }
  let(:suggest_path) { 'suggest' }
  let(:connection) { double('connection', send_and_receive: 'sent')}
  let(:repository) { double('repository', connection: connection) }
  let(:suggest_search) { described_class.new(params, repository)}
  describe '#suggestions' do
    it 'returns a Blacklight::Suggest::Response' do
      expect(suggest_search).to receive(:suggest_results).and_return([])
      expect(suggest_search).to receive(:suggest_handler_path).and_return(suggest_path)
      expect(suggest_search.suggestions).to be_an Blacklight::Suggest::Response
    end
  end
  describe '#suggest_results' do
    it 'should call send_and_recieve from a repository connection' do
      expect(suggest_search).to receive(:suggest_handler_path).and_return(suggest_path)
      expect(suggest_search.suggest_results).to eq 'sent'
    end
  end
end
