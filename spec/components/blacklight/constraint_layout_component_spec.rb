# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::ConstraintLayoutComponent, type: :component do
  subject(:render) do
    render_inline(described_class.new(params))
  end

  let(:rendered) do
    Capybara::Node::Simple.new(render)
  end

  describe "for simple display" do
    let(:params) do
      { label: "my label", value: "my value" }
    end

    it "renders label and value" do
      expect(rendered).to have_selector("span.applied-filter.constraint") do |s|
        expect(s).to have_css("span.constraint-value")
        expect(s).not_to have_css("a.constraint-value")
        expect(s).to have_selector "span.filter-name", text: "my label"
        expect(s).to have_selector "span.filter-value", text: "my value"
      end
    end
  end

  describe "with remove link" do
    let(:params) do
      { label: "my label", value: "my value", remove_path: "http://remove" }
    end

    it "includes remove link" do
      expect(rendered).to have_selector("span.applied-filter") do |s|
        expect(s).to have_selector(".remove[href='http://remove']")
      end
    end

    it "has an accessible remove label" do
      expect(rendered).to have_selector(".remove") do |s|
        expect(s).to have_selector('.sr-only', text: 'Remove constraint my label: my value')
      end
    end
  end

  describe "with custom classes" do
    let(:params) do
      { label: "my label", value: "my value", classes: %w[class1 class2] }
    end

    it "includes them" do
      expect(rendered).to have_selector("span.applied-filter.constraint.class1.class2")
    end
  end

  describe "with no escaping" do
    let(:params) do
      { label: "<span class='custom_label'>my label</span>".html_safe, value: "<span class='custom_value'>my value</span>".html_safe }
    end

    it "does not escape key and value" do
      expect(rendered).to have_selector("span.applied-filter.constraint span.filter-name span.custom_label")
      expect(rendered).to have_selector("span.applied-filter.constraint span.filter-value span.custom_value")
    end
  end
end
