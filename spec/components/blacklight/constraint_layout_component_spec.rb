# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::ConstraintLayoutComponent, type: :component do
  subject(:rendered) do
    render_inline_to_capybara_node(described_class.new(**params))
  end

  describe "for simple display" do
    let(:params) do
      { label: "my label", value: "my value" }
    end

    it "renders label and value" do
      expect(rendered).to have_css("span.applied-filter.constraint") do |s|
        expect(s).to have_css("span.constraint-value")
        expect(s).to have_no_css("a.constraint-value")
        expect(s).to have_css "span.filter-name", text: "my label"
        expect(s).to have_css "span.filter-value", text: "my value"
      end
    end
  end

  describe "with remove link" do
    let(:params) do
      { label: "my label", value: "my value", remove_path: "http://remove" }
    end

    it "includes remove link" do
      expect(rendered).to have_css("span.applied-filter") do |s|
        expect(s).to have_css(".remove[href='http://remove']")
      end
    end

    it "has an accessible remove label" do
      expect(rendered).to have_css(".remove") do |s|
        expect(s).to have_css('.visually-hidden', text: 'Remove constraint my label: my value')
      end
    end
  end

  describe "with custom classes" do
    let(:params) do
      { label: "my label", value: "my value", classes: %w[class1 class2] }
    end

    it "includes them" do
      expect(rendered).to have_css("span.applied-filter.constraint.class1.class2")
    end
  end

  describe "with no escaping" do
    let(:params) do
      { label: "<span class='custom_label'>my label</span>".html_safe, value: "<span class='custom_value'>my value</span>".html_safe }
    end

    it "does not escape key and value" do
      expect(rendered).to have_css("span.applied-filter.constraint span.filter-name span.custom_label")
      expect(rendered).to have_css("span.applied-filter.constraint span.filter-value span.custom_value")
    end
  end
end
