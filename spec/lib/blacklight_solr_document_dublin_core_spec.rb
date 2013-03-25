# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Blacklight::Solr::Document::DublinCore" do
  before(:all) do
    @mock_class = Class.new do
      include Blacklight::Solr::Document
    end
    @mock_class.use_extension( Blacklight::Solr::Document::DublinCore )
    @mock_class.field_semantics.merge!(
      :title => :title_display,
      :non_dc_title => :title_display
    )
  end


  it "should register all its export formats" do
    document = @mock_class.new
    Set.new(document.export_formats.keys).should  be_superset(Set.new([:oai_dc_xml,:dc_xml, :xml]))    
  end

  it "should export oai_dc with the proper namespaces" do
    document = @mock_class.new
    document.export_as_oai_dc_xml.should match 'xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/"'

  end

  it "should include 'dc:'-prefixed semantic fields" do
      data = {'id'=>'123456','title_display'=>['654321'] }
      document = @mock_class.new(data)
      document.export_as_oai_dc_xml.should match  'xmlns:dc="http://purl.org/dc/elements/1.1/"'
      document.export_as_oai_dc_xml.should match  '<dc:title>654321</dc:title>'
  end

  it "should work with multi-value fields" do
      data = {'id'=>'123456','title_display'=>['654321', '987'] }
      document = @mock_class.new(data)
      document.export_as_oai_dc_xml.should match '<dc:title>654321</dc:title>'
      document.export_as_oai_dc_xml.should match '<dc:title>987</dc:title></oai_dc:dc>'
  end
end

