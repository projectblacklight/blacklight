# frozen_string_literal: true

RSpec.describe Blacklight::Rendering::Pipeline do
  include Capybara::RSpecMatchers
  let(:document) { instance_double(SolrDocument) }
  let(:context) { double }
  let(:options) { {} }

  describe '.render' do
    subject(:rendered) { described_class.render(values, field_config, document, context, options) }

    let(:values) { %w[a b] }
    let(:field_config) { Blacklight::Configuration::NullField.new }

    it { is_expected.to eq %w[a b] }

    context "when itemprop is in the config" do
      let(:values) { ['a'] }
      let(:field_config) { Blacklight::Configuration::NullField.new(itemprop: 'some-prop', separator_options: nil) }

      it 'renders the expected markup' do
        expect(rendered.first).to have_css("span[@itemprop='some-prop']", text: "a")
      end
    end

    it 'sets the operations on the instance as equal to the class variable' do
      allow(described_class).to receive(:new)
        .and_return(instance_double(described_class, render: true))
      subject
      expect(described_class).to have_received(:new)
        .with(values, field_config, document, context, described_class.operations, options)
    end

    context 'outside of an HTML context' do
      context 'when options determines format' do
        let(:options) { { format: 'text' } }

        let(:values) { ['"blah"', "<notatag>"] }
        let(:field_config) { Blacklight::Configuration::NullField.new itemprop: 'some-prop' }

        it 'does not HTML escape values or inject HTML tags' do
          expect(rendered).to eq ['"blah"', "<notatag>"]
        end
      end

      context 'when context determines format' do
        let(:values) { ['"blah"', "<notatag>"] }
        let(:field_config) { Blacklight::Configuration::NullField.new itemprop: 'some-prop' }
        let(:controller) { CatalogController.new }
        let(:search_state) { Blacklight::SearchState.new({ format: 'text' }, controller.blacklight_config, controller) }

        before { allow(context).to receive(:search_state).and_return(search_state) }

        it 'does not HTML escape values or inject HTML tags' do
          expect(rendered).to eq ['"blah"', '<notatag>']
        end
      end
    end

    context 'when link_to_facet is in the config' do
      let(:values) { %w[book manuscript] }
      let(:field_config) { Blacklight::Configuration::Field.new(field: 'format', key: 'format', link_to_facet: true) }
      let(:controller) { CatalogController.new }
      let(:search_state) { Blacklight::SearchState.new({}, controller.blacklight_config, controller) }

      before do
        allow(context).to receive(:search_state).and_return(search_state)
        allow(context).to receive(:search_action_path) { |f| "/catalog?f[format][]=#{f['f']['format'].first}" }
        allow(context).to receive(:link_to) { |value, link|  ActiveSupport::SafeBuffer.new("<a href=#{link}>#{value}</a>") }
      end

      it 'renders html' do
        expect(rendered).to eq ["<a href=/catalog?f[format][]=book>book</a>", "<a href=/catalog?f[format][]=manuscript>manuscript</a>"]
      end

      context 'outside html context' do
        let(:values) { %w[book manuscript] }
        let(:field_config) { Blacklight::Configuration::Field.new(field: 'format', link_to_facet: true) }
        let(:search_state) { Blacklight::SearchState.new({ format: 'json' }, CatalogController.blacklight_config, CatalogController.new) }

        it 'does not render html' do
          expect(rendered).to eq %w[book manuscript]
        end
      end
    end

    context 'when joining values' do
      context 'with join in the config' do
        let(:field_config) { Blacklight::Configuration::NullField.new(join: true) }

        it 'joins the values' do
          expect(rendered).to eq ['a and b']
        end
      end

      context 'with join is in the options' do
        let(:options) { { join: true } }
        let(:field_config) { Blacklight::Configuration::NullField.new }

        it 'joins the values' do
          expect(rendered).to eq ['a and b']
        end
      end

      context 'with separator_options in the config' do
        let(:values) { %w[c d] }
        let(:field_config) { Blacklight::Configuration::NullField.new(separator_options: { two_words_connector: '; ' }) }

        it { is_expected.to eq ["c; d"] }
      end

      context 'with a single value' do
        let(:values) { [1] }
        let(:field_config) { Blacklight::Configuration::NullField.new(join: true) }

        it 'does not run the join step' do
          expect(rendered).to eq [1]
        end
      end

      context 'with a single html value' do
        let(:values) { ['<b>value</b>'] }
        let(:field_config) { Blacklight::Configuration::NullField.new(join: true) }

        it 'does not escape the html' do
          expect(rendered).to eq ['<b>value</b>']
        end

        it 'does not mark the value as html_safe' do
          expect(rendered.first).not_to be_html_safe
        end
      end

      context 'with an array of values containing unsafe characters' do
        let(:values) { ['<a', 'b'] }
        let(:field_config) { Blacklight::Configuration::NullField.new(join: true) }

        it 'escapes the unsafe characters' do
          expect(rendered).to eq ["&lt;a and b"]
        end

        it 'marks the joined value as html_safe' do
          expect(rendered.first).to be_html_safe
        end
      end

      context 'outside the html context' do
        let(:values) { %w[a b <c] }
        let(:field_config) { Blacklight::Configuration::Field.new(join: true) }
        let(:options) { { format: 'json' } }

        it 'does not run the join step' do
          expect(rendered).to eq %w[a b <c]
        end

        it 'does not escape unsafe html characters' do
          expect(rendered.last).to eq '<c'
        end

        it 'does not mark the values as html_safe' do
          expect(rendered.none?(&:html_safe?)).to be true
        end
      end
    end
  end

  describe '.operations' do
    subject { described_class.operations }

    it {
      expect(subject).to eq [Blacklight::Rendering::HelperMethod,
                             Blacklight::Rendering::LinkToFacet,
                             Blacklight::Rendering::Microdata,
                             Blacklight::Rendering::Join]
    }
  end

  describe '#operations' do
    subject(:operations) { presenter.operations }

    let(:presenter) { described_class.new(values, field_config, document, context, steps, options) }
    let(:steps) { [Blacklight::Rendering::HelperMethod] }
    let(:values) { ['a'] }
    let(:field_config) { Blacklight::Configuration::NullField.new }

    it 'sets the operations to the value passed to the initializer' do
      expect(operations).to eq steps
    end
  end
end
