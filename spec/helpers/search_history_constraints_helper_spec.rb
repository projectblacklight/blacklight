# frozen_string_literal: true

describe SearchHistoryConstraintsHelper do

  before(:all) do
    @config = Blacklight::Configuration.new do |config|
      config.add_search_field 'default_search_field', :label => 'Default'

      config.add_facet_field 'some_facet', :label => 'Some'
      config.add_facet_field 'other_facet', :label => 'Other'
      config.add_facet_field 'i18n_facet'

      I18n.backend.store_translations(:en, blacklight: {search: {fields: {facet: {i18n_facet: 'English facet label'}}}})
      I18n.backend.store_translations(:de, blacklight: {search: {fields: {facet: {i18n_facet: 'German facet label'}}}})
    end
  end

  before(:each) do
    allow(helper).to receive(:blacklight_config).and_return(@config)
  end

  describe "render_search_to_s_*" do
    describe "render_search_to_s_element" do
      it "renders basic element" do
        response = helper.render_search_to_s_element("key", "value")
        expect(response).to have_selector("span.constraint")  do |span|
          expect(span).to have_selector("span.filterName", :content => "key:")
          expect(span).to have_selector("span.filterValue", :content => "value")
        end
        expect(response).to be_html_safe
      end
      it "escapes them that need escaping" do
        response = helper.render_search_to_s_element("key>", "value>")
        expect(response).to have_selector("span.constraint") do |span|          
          expect(span).to have_selector("span.filterName") do |s2|
            # Note: nokogiri's gettext will unescape the inner html
            # which seems to be what rspecs "contains" method calls on 
            # text nodes - thus the to_s inserted below.
            expect(s2).to match(/key&gt;:/)
          end
          expect(span).to have_selector("span.filterValue") do |s3|            
            expect(s3).to match(/value&gt;/)
          end
        end
        expect(response).to be_html_safe
      end
      it "does not escape with options set thus" do
        response = helper.render_search_to_s_element("key>", "value>", :escape_key => false, :escape_value => false)
        expect(response).to have_selector("span.constraint") do |span|
          expect(span).to have_selector("span.filterName", :content => "key>:")
          expect(span).to have_selector("span.filterValue", :content => "value>")
        end
        expect(response).to be_html_safe
      end
    end

    describe "render_search_to_s" do
      before do
        @params = {:q => "history", :f => {"some_facet" => ["value1", "value1"],  "other_facet" => ["other1"]}}        
      end
      it "calls lesser methods" do
        allow(helper).to receive(:blacklight_config).and_return(@config)
        allow(helper).to receive(:default_search_field).and_return(Blacklight::Configuration::SearchField.new(:key => 'default_search_field', :display_label => 'Default'))
        allow(helper).to receive(:label_for_search_field).with(nil).and_return('')
        # API hooks expect this to be so
        response = helper.render_search_to_s(@params)

        expect(response).to include( helper.render_search_to_s_q(@params))
        expect(response).to include( helper.render_search_to_s_filters(@params))
        expect(response).to be_html_safe
      end
    end
    
    describe "render_search_to_s_filters" do
      it "renders a constraint for a selected facet in the config" do
        response = helper.render_search_to_s_filters(:f => {"some_facet" => ["value1", "value2"]})
        expect(response).to eq("<span class=\"constraint\"><span class=\"filterName\">Some:</span><span class=\"filterValues\"><span class=\"filterValue\">value1</span><span class=\"filterSeparator\"> and </span><span class=\"filterValue\">value2</span></span></span>")
      end

      it "renders a constraint for a selected facet not in the config" do
        response = helper.render_search_to_s_filters(:f => {"undefined_facet" => ["value1", "value2"]})
        expect(response).to eq("<span class=\"constraint\"><span class=\"filterName\">#{'undefined_facet'.humanize}:</span><span class=\"filterValues\"><span class=\"filterValue\">value1</span><span class=\"filterSeparator\"> and </span><span class=\"filterValue\">value2</span></span></span>")
      end

      context 'with I18n translations for selected facet' do
        before do
          @orig_locale = I18n.locale
        end

        after do
          I18n.locale = @orig_locale
        end

        it 'renders the correct I18n label for a selected facet with I18n translations' do
          {en: 'English facet label', de: 'German facet label'}.each do |locale, label|
            I18n.locale = locale
            response = helper.render_search_to_s_filters(f: {'i18n_facet' => ['value1', 'value2']})
            expect(response).to include(label)
          end
        end
      end
    end
  end

end
