# frozen_string_literal: true

RSpec.describe Blacklight::DocumentHelperBehavior do
  before do
    allow(helper).to receive(:blacklight_config).and_return(blacklight_config)
  end

  let(:blacklight_config) { Blacklight::Configuration.new }

  describe '#document_presenter' do
    subject { helper.document_presenter(document) }

    let(:document) { SolrDocument.new(id: '123') }

    it { is_expected.to be_a Blacklight::DocumentPresenter }

    context 'in a show context' do
      before do
        blacklight_config.show.document_presenter_class = Blacklight::ShowPresenter

        allow(helper).to receive(:action_name).and_return('show')
      end

      it { is_expected.to be_a Blacklight::ShowPresenter }
    end

    context 'with a provided view config' do
      subject { helper.document_presenter(document, view_config: view_config) }

      let(:view_config) { Blacklight::Configuration::ViewConfig.new(document_presenter_class: stub_class) }
      let(:stub_class) { stub_const('MyDocumentPresenter', Class.new(Blacklight::DocumentPresenter)) }

      it { is_expected.to be_a stub_class }
    end
  end
end
