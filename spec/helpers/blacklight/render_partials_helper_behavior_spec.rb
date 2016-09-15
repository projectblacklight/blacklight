describe Blacklight::RenderPartialsHelperBehavior do
  describe "#type_field_to_partial_name" do
    let(:document) { double }
    context "with default value" do
      subject { helper.type_field_to_partial_name(document, 'default') }
      it { should eq 'default' }
    end
    context "with spaces" do
      subject { helper.type_field_to_partial_name(document, 'one two three') }
      it { should eq 'one_two_three' }
    end
    context "with hyphens" do
      subject { helper.type_field_to_partial_name(document, 'one-two-three') }
      it { should eq 'one_two_three' }
    end
    context "an array" do
      subject { helper.type_field_to_partial_name(document, ['one', 'two', 'three']) }
      it { should eq 'one_two_three' }
    end
  end

  describe "#render_document_partials" do
    let(:doc) { double }
    before do
      allow(helper).to receive_messages(document_partial_path_templates: [])
      allow(helper).to receive_messages(document_index_view_type: 'index_header')
    end

    it "gets the document format from document_partial_name" do
      allow(helper).to receive(:document_partial_name).with(doc, :xyz)
      helper.render_document_partial(doc, :xyz)
    end
  end

  describe "#document_partial_name" do
    let(:blacklight_config) { Blacklight::Configuration.new }
    before do
      allow(helper).to receive_messages(blacklight_config: blacklight_config)
    end

    context "with a solr document with empty fields" do
      let(:document) { SolrDocument.new }
      it "is the default value" do
        expect(helper.document_partial_name(document)).to eq 'default'
      end
    end

    context "with a solr document with the display type field set" do
      let(:document) { SolrDocument.new 'my_field' => 'xyz'}
      before do
        blacklight_config.show.display_type_field = 'my_field'
      end

      it "uses the value in the configured display type field" do
        expect(helper.document_partial_name(document)).to eq 'xyz'
      end
      it "uses the value in the configured display type field if the action-specific field is empty" do
        expect(helper.document_partial_name(document, :some_action)).to eq 'xyz'
      end
    end

    context "with a solr doucment with an action-specific field set" do
      let(:document) { SolrDocument.new 'my_field' => 'xyz', 'other_field' => 'abc' }
      before do
        blacklight_config.show.media_display_type_field = 'my_field'
        blacklight_config.show.metadata_display_type_field = 'other_field'
      end
      it "uses the value in the action-specific fields" do
        expect(helper.document_partial_name(document, :media)).to eq 'xyz'
        expect(helper.document_partial_name(document, :metadata)).to eq 'abc'
      end
    end
  end

end