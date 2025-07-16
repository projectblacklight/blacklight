# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::ConstraintPresenter, type: :presenter do
  subject(:presenter) do
    described_class.new(facet_item_presenter: facet_item_presenter, field_label: field_label)
  end

  let(:facet_item_presenter) do
    instance_double(Blacklight::FacetItemPresenter, label: 'item 1', remove_href: '/catalog')
  end
  let(:field_label) { 'field 1' }

  describe '#constraint_label' do
    subject { presenter.constraint_label }

    it { is_expected.to eq 'item 1' }
  end

  describe '#field_label' do
    subject { presenter.field_label }

    it { is_expected.to eq 'field 1' }
  end

  describe '#remove_href' do
    subject { presenter.remove_href }

    it { is_expected.to eq '/catalog' }
  end
end
