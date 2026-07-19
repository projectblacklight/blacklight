# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::Response::FacetGroupComponent, type: :component do
  before do
    render_inline(instance)
  end

  context 'when classes are passed in' do
    let(:instance) do
      described_class.new(id: 'foo', title: 'bar', body_classes: 'custom-class').tap do |component|
        component.with_body { 'body' }
      end
    end

    it "uses them" do
      within '.facets' do
        expect(page).to have_css 'div.custom-class'
      end
    end
  end

  context 'when classes are not passed in' do
    let(:instance) do
      described_class.new(id: 'foo', title: 'bar').tap do |component|
        component.with_body { 'body' }
      end
    end

    it "uses default classes them" do
      within '.facets' do
        expect(page).to have_css 'div.facets-collapse.d-lg-block.collapse.accordion'
      end
    end
  end

  context "when no facets within the group render" do
    let(:instance) do
      described_class.new(id: 'foo', title: 'bar').tap do |component|
        component.with_body { ViewComponent::Slot.new("\n") }
      end
    end

    it "does not render" do
      expect(instance.render?).to eq false

      within '.facets' do
        expect(page).not_to have_css 'div.facets-collapse.d-lg-block.collapse.accordion'
      end
    end
  end
end
