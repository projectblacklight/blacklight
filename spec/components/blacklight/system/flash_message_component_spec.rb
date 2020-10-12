# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::System::FlashMessageComponent, type: :component do
  subject(:component) { described_class.new(message: message, type: type) }

  let(:view_context) { controller.view_context }
  let(:render) do
    component.render_in(view_context)
  end

  let(:rendered) do
    Capybara::Node::Simple.new(render)
  end
  let(:message) { 'This is an important message' }
  let(:type) { 'whatever' }

  it 'renders a message inside an alert' do
    expect(rendered).to have_selector 'div.alert.alert-whatever', text: message
  end

  context 'with a success message' do
    let(:type) { 'success' }

    it 'adds some styling' do
      expect(rendered).to have_selector 'div.alert-success'
    end
  end

  context 'with a notice message' do
    let(:type) { 'notice' }

    it 'adds some styling' do
      expect(rendered).to have_selector 'div.alert-info'
    end
  end

  context 'with an alert message' do
    let(:type) { 'alert' }

    it 'adds some styling' do
      expect(rendered).to have_selector 'div.alert-warning'
    end
  end

  context 'with an error message' do
    let(:type) { 'error' }

    it 'adds some styling' do
      expect(rendered).to have_selector 'div.alert-danger'
    end
  end
end
