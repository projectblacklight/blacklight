# frozen_string_literal: true

RSpec.describe Blacklight::Component, type: :component do
  let(:component_class) { Blacklight::System::ModalComponent }

  before do
    component_class.reset_compiler!
    ViewComponent::CompileCache.invalidate!

    component_class.class_eval do
      undef :call if method_defined?(:call)
    end
  end

  after do
    component_class.reset_compiler!
    ViewComponent::CompileCache.invalidate!

    component_class.class_eval do
      undef :call if method_defined?(:call)
    end
  end

  context "without overrides" do
    it "renders the engine template" do
      render_inline(component_class.new)
      expect(page).to have_css('.modal-header')
    end
  end

  context "with overrides" do
    around do |ex|
      FileUtils.mkdir_p(Rails.root.join('app/components/blacklight/system'))
      Rails.root.join("app/components/blacklight/system/modal_component.html.erb").open("w") do |f|
        f.puts '<div class="custom-modal">Overridden</div>'
      end

      ex.run
    ensure
      Rails.root.join('app/components/blacklight/system/modal_component.html.erb').unlink
    end

    it "renders to application template" do
      render_inline(component_class.new)
      expect(page).to have_css('.custom-modal')
    end
  end
end
