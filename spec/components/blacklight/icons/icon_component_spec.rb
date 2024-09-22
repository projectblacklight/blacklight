# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::Icons::IconComponent, type: :component do
  subject(:component) { sub_component.new }

  let(:sub_component) do
    Class.new(described_class) do
      def self.name
        'TestIconComponent'
      end
    end
  end

  context 'when no classes are passed in' do
    subject(:component) { sub_component.new }

    it "renders component" do
      render_inline(component)
      expect(page).to have_css "span[class='blacklight-icons blacklight-icons-test_icon']"
    end
  end

  context 'when classes are passed in' do
    subject(:component) { sub_component.new(classes: 'my-icon') }

    it "renders component" do
      render_inline(component)
      expect(page).to have_css "span[class='my-icon blacklight-icons blacklight-icons-test_icon']"
    end
  end

  context 'when name is passed in' do
    subject(:component) { sub_component.new(name: 'my-icon') }

    it "renders component" do
      render_inline(component)
      expect(page).to have_css "span[class='blacklight-icons blacklight-icons-my-icon']"
    end
  end
end
