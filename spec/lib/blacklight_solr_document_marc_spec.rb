# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')


describe "Blacklight::Solr::Document::Marc" do
  before(:all) do
    @mock_class = Class.new do
      include Blacklight::Solr::Document
    end
    @mock_class.use_extension( Blacklight::Solr::Document::Marc )
    @mock_class.extension_parameters[:marc_source_field] = :marc      
  end

  describe "marc binary mode" do
    before(:each) do
      @mock_class.extension_parameters[:marc_format_type] = :marc21      
    end
    it "should read and parse a marc binary file" do
      document = @mock_class.new(:marc => sample_marc_binary )
      expect(document.to_marc).to eq(marc_from_string(:binary => sample_marc_binary ))
    end
  end

  describe "marcxml mode" do
    before(:each) do
      @mock_class.extension_parameters[:marc_format_type] = :marcxml
    end
    it "should read and parse a marc xml file" do
      document = @mock_class.new(:marc => sample_marc_xml)
      expect(document.to_marc).to eq(marc_from_string(:xml => sample_marc_xml))
    end
  end

  it "should register all its export formats" do
    document = @mock_class.new
    expect(Set.new(document.export_formats.keys)).to  be_superset(Set.new([:marc, :marcxml, :openurl_ctx_kev, :refworks_marc_txt, :endnote, :xml]))    
  end



    def sample_marc_xml
    "<record>
      <leader>01182pam a22003014a 4500</leader>
      <controlfield tag=\"001\">a4802615</controlfield>
      <controlfield tag=\"003\">SIRSI</controlfield>
      <controlfield tag=\"008\">020828s2003    enkaf    b    001 0 eng  </controlfield>
    
      <datafield tag=\"245\" ind1=\"0\" ind2=\"0\">
        <subfield code=\"a\">Apples :</subfield>
        <subfield code=\"b\">botany, production, and uses /</subfield>
        <subfield code=\"c\">edited by D.C. Ferree and I.J. Warrington.</subfield>
      </datafield>
    
      <datafield tag=\"260\" ind1=\" \" ind2=\" \">
        <subfield code=\"a\">Oxon, U.K. ;</subfield>
        <subfield code=\"a\">Cambridge, MA :</subfield>
        <subfield code=\"b\">CABI Pub.,</subfield>
        <subfield code=\"c\">c2003.</subfield>
      </datafield>
    
      <datafield tag=\"700\" ind1=\"1\" ind2=\" \">
        <subfield code=\"a\">Ferree, David C.</subfield>
        <subfield code=\"q\">(David Curtis),</subfield>
        <subfield code=\"d\">1943-</subfield>
      </datafield>
    
      <datafield tag=\"700\" ind1=\"1\" ind2=\" \">
        <subfield code=\"a\">Warrington, I. J.</subfield>
        <subfield code=\"q\">(Ian J.)</subfield>
      </datafield>
    </record>"
  end


  def sample_marc_binary
    "00386pam a22001094a 4500001000900000003000600009008004100015245008900056260005400145700004500199700003200244\036a4802615\036SIRSI\036020828s2003    enkaf    b    001 0 eng  \03600\037aApples :\037bbotany, production, and uses /\037cedited by D.C. Ferree and I.J. Warrington.\036  \037aOxon, U.K. ;\037aCambridge, MA :\037bCABI Pub.,\037cc2003.\0361 \037aFerree, David C.\037q(David Curtis),\037d1943-\0361 \037aWarrington, I. J.\037q(Ian J.)\036\035"
  end
  def marc_from_string(args = {})
    if args[:binary]
      reader = MARC::Reader.new(StringIO.new(args[:binary]))
      reader.each {|rec| return rec }
    elsif args[:xml]
      reader = MARC::XMLReader.new(StringIO.new(args[:xml]))
      reader.each {|rec| return rec }
    end
    return nil
  end
end

