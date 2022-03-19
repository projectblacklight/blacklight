# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::SidecarDemonstrationComponent, type: :component do
  subject(:rendered) do
    render_inline(component)
  end

  let(:component) { described_class.new }

  it 'renders from the application template' do
    # described_class.compiler.compile
    element = rendered.css('h1.application').first
    expect(element.text).to eql "Application Translation"
  end
end
