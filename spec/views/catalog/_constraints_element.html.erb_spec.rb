# frozen_string_literal: true

RSpec.describe "catalog/_constraints_element.html.erb" do
  describe "for simple display" do
    before do
      render partial: "catalog/constraints_element", locals: { label: "my label", value: "my value" }
    end

    it "renders label and value" do
      expect(rendered).to have_selector("span.applied-filter.constraint") do |s|
        expect(s).to have_css("span.constraint-value")
        expect(s).not_to have_css("a.constraint-value")
        expect(s).to have_selector "span.filter-name", content: "my label"
        expect(s).to have_selector "span.filter-value", content: "my value"
      end
    end
  end

  describe "with remove link" do
    before do
      render partial: "catalog/constraints_element", locals: { label: "my label", value: "my value", options: { remove: "http://remove" } }
    end

    it "includes remove link" do
      expect(rendered).to have_selector("span.applied-filter") do |s|
        expect(s).to have_selector(".remove[href='http://remove']")
      end
    end
    it "has an accessible remove label" do
      expect(rendered).to have_selector(".remove") do |s|
        expect(s).to have_content("Remove constraint my label: my value")
      end
    end
  end

  describe "with custom classes" do
    before do
      render partial: "catalog/constraints_element", locals: { label: "my label", value: "my value", options: { classes: %w[class1 class2] } }
    end

    it "includes them" do
      expect(rendered).to have_selector("span.applied-filter.constraint.class1.class2")
    end
  end

  describe "with no escaping" do
    before do
      render(partial: "catalog/constraints_element", locals: { label: "<span class='custom_label'>my label</span>".html_safe, value: "<span class='custom_value'>my value</span>".html_safe })
    end

    it "does not escape key and value" do
      expect(rendered).to have_selector("span.applied-filter.constraint span.filter-name span.custom_label")
      expect(rendered).to have_selector("span.applied-filter.constraint span.filter-value span.custom_value")
    end
  end
end
