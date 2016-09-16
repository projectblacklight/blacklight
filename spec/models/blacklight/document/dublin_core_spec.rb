# frozen_string_literal: true

RSpec.describe "Blacklight::Document::DublinCore" do
  before(:all) do
    @mock_class = Class.new do
      include Blacklight::Document
    end
    @mock_class.use_extension( Blacklight::Document::DublinCore )
    @mock_class.field_semantics.merge!(
      :title => :title_tsim,
      :non_dc_title => :title_tsim
    )
  end


  it "should register all its export formats" do
    document = @mock_class.new
    expect(document.export_formats.keys).to include :oai_dc_xml, :dc_xml, :xml   
  end

  it "should export oai_dc with the proper namespaces" do
    document = @mock_class.new
    expect(document.export_as_oai_dc_xml).to match 'xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/"'

  end

  it "should include 'dc:'-prefixed semantic fields" do
      data = {'id'=>'123456','title_tsim'=>['654321'] }
      document = @mock_class.new(data)
      expect(document.export_as_oai_dc_xml).to match  'xmlns:dc="http://purl.org/dc/elements/1.1/"'
      expect(document.export_as_oai_dc_xml).to match  '<dc:title>654321</dc:title>'
  end

  it "should work with multi-value fields" do
      data = {'id'=>'123456','title_tsim'=>['654321', '987'] }
      document = @mock_class.new(data)
      expect(document.export_as_oai_dc_xml).to match '<dc:title>654321</dc:title>'
      expect(document.export_as_oai_dc_xml).to match '<dc:title>987</dc:title></oai_dc:dc>'
  end
end

