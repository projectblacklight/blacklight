# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::System::FlashMessageComponent, type: :component do
  subject(:component) { described_class.new(message: message, type: type) }

  before do
    render_inline(component)
  end

  let(:message) { 'This is an important message' }
  let(:type) { 'whatever' }

  it 'renders a message inside an alert' do
    expect(page).to have_css 'div.alert.alert-whatever', text: message
  end

  context 'with a success message' do
    let(:type) { 'success' }

    it 'adds some styling' do
      expect(page).to have_css 'div.alert-success'
    end
  end

  context 'with a notice message' do
    let(:type) { 'notice' }

    it 'adds some styling' do
      expect(page).to have_css 'div.alert-info'
    end
  end

  context 'with an alert message' do
    let(:type) { 'alert' }

    it 'adds some styling' do
      expect(page).to have_css 'div.alert-warning'
    end
  end

  context 'with an error message' do
    let(:type) { 'error' }

    it 'adds some styling' do
      expect(page).to have_css 'div.alert-danger'
    end
  end
end
