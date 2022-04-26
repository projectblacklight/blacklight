# frozen_string_literal: true

RSpec.describe Blacklight::Component do
  let(:component_class) { Blacklight::DocumentTitleComponent }

  context "subclassed" do
    it "returns our Compiler implementation" do
      expect(component_class.ancestors).to include described_class
      expect(component_class.compiler).to be_a Blacklight::Component::EngineCompiler
    end
  end

  describe Blacklight::Component::EngineCompiler do
    subject(:compiler) { described_class.new(component_class) }

    let(:original_compiler) { ViewComponent::Compiler.new(component_class) }
    let(:original_path) { original_compiler.send(:templates).first[:path] }
    let(:resolved_path) { compiler.templates.first[:path] }

    context "without overrides" do
      it "links to engine template" do
        expect(resolved_path).not_to include(".internal_test_app")
        expect(resolved_path).to eql(original_path)
      end
    end

    context "with overrides" do
      let(:path_match) do
        Regexp.new(Regexp.escape(File.join(".internal_test_app", component_class.view_component_path)))
      end

      before do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(path_match).and_return(true)
      end

      it "links to application template" do
        expect(resolved_path).to include(".internal_test_app")
        expect(resolved_path).not_to eql(original_path)
      end
    end
  end
end
