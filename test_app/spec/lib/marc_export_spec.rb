require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'rubygems'
require 'marc'

def marc_from_xml(string)    
  reader = MARC::XMLReader.new(StringIO.new(string))
  reader.each {|rec| return rec }
end
  

def standard_citation
"<record>
  <leader>01182pam a22003014a 4500</leader>
  <controlfield tag=\"001\">a4802615</controlfield>
  <controlfield tag=\"003\">SIRSI</controlfield>
  <controlfield tag=\"008\">020828s2003    enkaf    b    001 0 eng  </controlfield>

  <datafield tag=\"110\" ind1=\"1\" ind2=\" \">
    <subfield code=\"a\">Bobs</subfield>
    <subfield code=\"b\">Your Uncle</subfield>
  </datafield>

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

def music_record
"<record>
  <leader>01828cjm a2200409 a 4500</leader>
  <controlfield tag=\"001\">a4768316</controlfield>
  <controlfield tag=\"003\">SIRSI</controlfield>
  <controlfield tag=\"007\">sd fungnnmmned</controlfield>
  <controlfield tag=\"008\">020117p20011990xxuzz    h              d</controlfield>

  <datafield tag=\"245\" ind1=\"0\" ind2=\"0\">
    <subfield code=\"a\">Music for horn</subfield>
    <subfield code=\"h\">[sound recording] /</subfield>
    <subfield code=\"c\">Brahms, Beethoven, von Krufft.</subfield>
  </datafield>

  <datafield tag=\"260\" ind1=\" \" ind2=\" \">
    <subfield code=\"a\">[United States] :</subfield>
    <subfield code=\"b\">Harmonia Mundi USA,</subfield>
    <subfield code=\"c\">p2001.</subfield>
  </datafield>

  <datafield tag=\"700\" ind1=\"1\" ind2=\" \">
    <subfield code=\"a\">Greer, Lowell.</subfield>
  </datafield>

  <datafield tag=\"700\" ind1=\"1\" ind2=\" \">
    <subfield code=\"a\">Lubin, Steven.</subfield>
  </datafield>

  <datafield tag=\"700\" ind1=\"1\" ind2=\" \">
    <subfield code=\"a\">Chase, Stephanie,</subfield>
    <subfield code=\"d\">1957-</subfield>
  </datafield>

  <datafield tag=\"700\" ind1=\"1\" ind2=\"2\">
    <subfield code=\"a\">Brahms, Johannes,</subfield>
    <subfield code=\"d\">1833-1897.</subfield>
    <subfield code=\"t\">Trios,</subfield>
    <subfield code=\"m\">piano, violin, horn,</subfield>
    <subfield code=\"n\">op. 40,</subfield>
    <subfield code=\"r\">E? major.</subfield>
  </datafield>

  <datafield tag=\"700\" ind1=\"1\" ind2=\"2\">
    <subfield code=\"a\">Beethoven, Ludwig van,</subfield>
    <subfield code=\"d\">1770-1827.</subfield>
    <subfield code=\"t\">Sonatas,</subfield>
    <subfield code=\"m\">horn, piano,</subfield>
    <subfield code=\"n\">op. 17,</subfield>
    <subfield code=\"r\">F major.</subfield>
  </datafield>

  <datafield tag=\"700\" ind1=\"1\" ind2=\"2\">
    <subfield code=\"a\">Krufft, Nikolaus von,</subfield>
    <subfield code=\"d\">1779-1818.</subfield>
    <subfield code=\"t\">Sonata,</subfield>
    <subfield code=\"m\">horn, piano,</subfield>
    <subfield code=\"r\">F major.</subfield>
  </datafield>
</record>"
end

def utf8_decomposed_record_xml
 "<record>
    <leader>01341nam  2200301 a 450 </leader>
    <controlfield tag=\"005\">19971120234400.0</controlfield>
    <controlfield tag=\"008\">890316s1988    caua     b    101 0 eng  </controlfield>    
    <datafield tag=\"245\" ind1=\"0\" ind2=\"0\">
      <subfield code=\"a\">Sharīʻat and ambiguity in South Asian Islam /</subfield>
      <subfield code=\"c\">edited by Katherine P. Ewing.</subfield>
    </datafield>
  </record>"
end

# 1:100,1:700,245a,0:245b,
def record1_xml
  "<record>
     <leader>01021cam a2200277 a 4500</leader>
     <controlfield tag=\"001\">a1711966</controlfield>
     <controlfield tag=\"003\">SIRSI</controlfield>
     <controlfield tag=\"008\">890421s1988    enka          001 0 eng d</controlfield>

     <datafield tag=\"100\" ind1=\"1\" ind2=\" \">
       <subfield code=\"a\">Janetzky, Kurt.</subfield>
     </datafield>

     <datafield tag=\"245\" ind1=\"1\" ind2=\"4\">
       <subfield code=\"a\">The horn /</subfield>
       <subfield code=\"c\">Kurt Janetzky and Bernhard Bruchle ; translated from the German by James Chater.</subfield>
     </datafield>

     <datafield tag=\"260\" ind1=\" \" ind2=\" \">
       <subfield code=\"a\">London :</subfield>
       <subfield code=\"b\">Batsford,</subfield>
       <subfield code=\"c\">1988.</subfield>
     </datafield>

     <datafield tag=\"700\" ind1=\"1\" ind2=\" \">
       <subfield code=\"a\">Brüchle, Bernhard.</subfield>
     </datafield>
  </record>"
end

# 0:100,0:700,245a,0:245b
def record2_xml
"<record>
  <leader>00903nam a2200253   4500</leader>
  <controlfield tag=\"001\">a543347</controlfield>
  <controlfield tag=\"003\">SIRSI</controlfield>
  <controlfield tag=\"008\">730111s1971    ohu      b    000 0 eng  </controlfield>

  <datafield tag=\"245\" ind1=\"0\" ind2=\"0\">
    <subfield code=\"a\">Final report to the Honorable John J. Gilligan, Governor.</subfield>
  </datafield>

  <datafield tag=\"260\" ind1=\" \" ind2=\" \">
    <subfield code=\"a\">[Columbus,</subfield>
    <subfield code=\"b\">Printed by the State of Ohio, Dept. of Urban Affairs,</subfield>
    <subfield code=\"c\">1971]</subfield>
  </datafield>
</record>"
end

# 4+:athors
def record3_xml
"<record>
  <leader>01828cjm a2200409 a 4500</leader>
  <controlfield tag=\"001\">a4768316</controlfield>
  <controlfield tag=\"003\">SIRSI</controlfield>
  <controlfield tag=\"007\">sd fungnnmmned</controlfield>
  <controlfield tag=\"008\">020117p20011990xxuzz    h              d</controlfield>

  <datafield tag=\"245\" ind1=\"0\" ind2=\"0\">
    <subfield code=\"a\">Music for horn</subfield>
    <subfield code=\"h\">[sound recording] /</subfield>
    <subfield code=\"c\">Brahms, Beethoven, von Krufft.</subfield>
  </datafield>

  <datafield tag=\"260\" ind1=\" \" ind2=\" \">
    <subfield code=\"a\">[United States] :</subfield>
    <subfield code=\"b\">Harmonia Mundi USA,</subfield>
    <subfield code=\"c\">p2001.</subfield>
  </datafield>

  <datafield tag=\"700\" ind1=\"1\" ind2=\" \">
    <subfield code=\"a\">Greer, Lowell.</subfield>
  </datafield>

  <datafield tag=\"700\" ind1=\"1\" ind2=\" \">
    <subfield code=\"a\">Lubin, Steven.</subfield>
  </datafield>

  <datafield tag=\"700\" ind1=\"1\" ind2=\" \">
    <subfield code=\"a\">Chase, Stephanie,</subfield>
    <subfield code=\"d\">1957-</subfield>
  </datafield>

  <datafield tag=\"700\" ind1=\"1\" ind2=\"2\">
    <subfield code=\"a\">Brahms, Johannes,</subfield>
    <subfield code=\"d\">1833-1897.</subfield>
    <subfield code=\"t\">Trios,</subfield>
    <subfield code=\"m\">piano, violin, horn,</subfield>
    <subfield code=\"n\">op. 40,</subfield>
    <subfield code=\"r\">E? major.</subfield>
  </datafield>

  <datafield tag=\"700\" ind1=\"1\" ind2=\"2\">
    <subfield code=\"a\">Beethoven, Ludwig van,</subfield>
    <subfield code=\"d\">1770-1827.</subfield>
    <subfield code=\"t\">Sonatas,</subfield>
    <subfield code=\"m\">horn, piano,</subfield>
    <subfield code=\"n\">op. 17,</subfield>
    <subfield code=\"r\">F major.</subfield>
  </datafield>

  <datafield tag=\"700\" ind1=\"1\" ind2=\"2\">
    <subfield code=\"a\">Krufft, Nikolaus von,</subfield>
    <subfield code=\"d\">1779-1818.</subfield>
    <subfield code=\"t\">Sonata,</subfield>
    <subfield code=\"m\">horn, piano,</subfield>
    <subfield code=\"r\">F major.</subfield>
  </datafield>
</record>"
end

# No elements that can be put into a citation
def no_good_data_xml
"<record>
  <leader>01828cjm a2200409 a 4500</leader>
  <controlfield tag=\"001\">a4768316</controlfield>
  <controlfield tag=\"003\">SIRSI</controlfield>
  <controlfield tag=\"007\">sd fungnnmmned</controlfield>
  <controlfield tag=\"008\">020117p20011990xxuzz    h              d</controlfield>
  
  <datafield tag=\"024\" ind1=\"1\" ind2=\" \">
    <subfield code=\"a\">713746703721</subfield>
  </datafield>

  <datafield tag=\"028\" ind1=\"0\" ind2=\"0\">
    <subfield code=\"a\">HCX 3957037</subfield>
    <subfield code=\"b\">Harmonia Mundi USA</subfield>
  </datafield>

  <datafield tag=\"033\" ind1=\"2\" ind2=\"0\">
    <subfield code=\"a\">19901203</subfield>
    <subfield code=\"a\">19901206</subfield>
  </datafield>

  <datafield tag=\"035\" ind1=\" \" ind2=\" \">
    <subfield code=\"a\">(OCoLC-M)48807235</subfield>
  </datafield>

  <datafield tag=\"040\" ind1=\" \" ind2=\" \">
    <subfield code=\"a\">WC4</subfield>
    <subfield code=\"c\">WC4</subfield>
    <subfield code=\"d\">CSt</subfield>
  </datafield>

  <datafield tag=\"041\" ind1=\"0\" ind2=\" \">
    <subfield code=\"g\">engfre</subfield>
  </datafield>
</record>"
end

describe Blacklight::Solr::Document::MarcExport do
  
  before(:all) do
    dclass = Class.new do
      include Blacklight::Solr::Document::MarcExport
      attr_accessor :to_marc
      def initialize(marc_xml_str)
        self.to_marc = marc_from_xml(marc_xml_str)
      end
    end

    @typical_record                     = dclass.new( standard_citation )
    @music_record                       = dclass.new( music_record )
    @record_without_245b                = dclass.new( record1_xml )
    @record_without_authors             = dclass.new( record2_xml )
    @record_with_4plus_authors          = dclass.new( record3_xml )
    @record_without_citable_data        = dclass.new( no_good_data_xml )
    @record_utf8_decomposed = dclass.new( utf8_decomposed_record_xml )

  end
  
  describe "export_as_apa_citation_txt" do
    it "should format a standard citation correctly" do
      @typical_record.export_as_apa_citation_txt.should == "Ferree, D. C, &amp; Warrington, I. J. (2003). <i>Apples : botany, production, and uses.</i> Oxon, U.K.: CABI Pub."
    end
    
    it "should format a citation without a 245b field correctly" do
      @record_without_245b.export_as_apa_citation_txt.should == "Janetzky, K., &amp; Brüchle, B. (1988). <i>The horn.</i> London: Batsford."
    end
    
    it "should format a citation without any authors correctly" do
      @record_without_authors.export_as_apa_citation_txt.should == "(1971). <i>Final report to the Honorable John J. Gilligan, Governor.</i> [Columbus: Printed by the State of Ohio, Dept. of Urban Affairs."
    end
    
    it "should not fail if there is no citation data" do
      @record_without_citable_data.export_as_apa_citation_txt.should == ""
    end
    
  end
  
  describe "export_as_mla_citation_txt" do
    it "should format a standard citation correctly" do
      @typical_record.export_as_mla_citation_txt.should == "Ferree, David C, and I. J Warrington. <i>Apples : Botany, Production, and Uses.</i> Oxon, U.K.: CABI Pub., 2003."
    end
    
    it "should format a citation without a 245b field correctly" do
      @record_without_245b.export_as_mla_citation_txt.should == "Janetzky, Kurt, and Bernhard Brüchle. <i>The Horn.</i> London: Batsford, 1988."
    end
    
    it "should format a citation without any authors correctly" do
      @record_without_authors.export_as_mla_citation_txt.should == "<i>Final Report to the Honorable John J. Gilligan, Governor.</i> [Columbus: Printed by the State of Ohio, Dept. of Urban Affairs, 1971."
    end
    
    it "should format a citation with 4+ authors correctly" do
      @record_with_4plus_authors.export_as_mla_citation_txt.should == "Greer, Lowell, et al. <i>Music for Horn.</i> [United States]: Harmonia Mundi USA, 2001."
    end
    
    it "should not fail if there is no citation data" do
      @record_without_citable_data.export_as_mla_citation_txt.should == ""      
    end
  end
  
  describe "export_as_openurl_ctx_kev" do
    it "should create the appropriate context object for books" do
      record = @typical_record.export_as_openurl_ctx_kev('Book')
      record.should match(/.*mtx%3Abook.*rft.genre=book.*rft.btitle=Apples\+%3A\+botany%2C\+production%2C\+and\+uses.*rft.aucorp=Bobs\+Your\+Uncle.*rft.date=c2003.*rft.place=Oxon%2C\+U.K.*rft.pub=CABI\+Pub.*rft.isbn=/) and
      record.should_not match(/.*rft.genre=article.*rft.issn=.*/)
    end
    it "should create the appropriate context object for journals" do
      record = @typical_record.export_as_openurl_ctx_kev('Journal')
      record_journal_other = @typical_record.export_as_openurl_ctx_kev('Journal/Magazine')
      record.should match(/.*mtx%3Ajournal.*rft.genre=article.*rft.title=Apples\+%3A\+botany%2C\+production%2C\+and\+uses.*rft.atitle=Apples\+%3A\+botany%2C\+production%2C\+and\+uses.*rft.aucorp=Bobs\+Your\+Uncle.*rft.date=c2003.*rft.issn=/) and
      record_journal_other.should == record and
      record.should_not match(/.*rft.genre=book.*rft.isbn=.*/)
    end
    it "should create the appropriate context object for other content" do
      record = @typical_record.export_as_openurl_ctx_kev('NotARealFormat')
      record.should match(/.*mtx%3Adc.*rft.title=Apples\+%3A\+botany%2C\+production%2C\+and\+uses.*rft.creator=.*rft.aucorp=Bobs\+Your\+Uncle.*rft.date=c2003.*rft.place=Oxon%2C\+U.K.*rft.pub=CABI\+Pub.*rft.format=notarealformat/) and
      record.should_not match(/.*rft.isbn=.*/) and
      record.should_not match(/.*rft.issn=.*/)
    end
  end

  describe "export_as_marc binary" do
    it "should export_as_marc" do
      @typical_record.export_as_marc.should == @typical_record.to_marc.to_marc
    end
  end

  describe "export_as_marcxml" do
    it "should export_as_marcxml" do
      marc_from_xml(@typical_record.export_as_marcxml).should == marc_from_xml(@typical_record.to_marc.to_xml.to_s)
    end
  end

  describe "export_as_xml" do
    it "should export marcxml as xml" do
      marc_from_xml(@typical_record.export_as_xml).should == marc_from_xml(@typical_record.export_as_marcxml)
    end
  end

  describe "export_as_refworks_marc_txt" do
    it "should export correctly" do
      @music_record.export_as_refworks_marc_txt.should == "LEADER 01828cjm a2200409 a 4500001    a4768316\n003    SIRSI\n007    sd fungnnmmned\n008    020117p20011990xxuzz    h              d\n245 00 Music for horn |h[sound recording] / |cBrahms, Beethoven, von Krufft.\n260    [United States] : |bHarmonia Mundi USA, |cp2001.\n700 1  Greer, Lowell.\n700 1  Lubin, Steven.\n700 1  Chase, Stephanie, |d1957-\n700 12 Brahms, Johannes, |d1833-1897. |tTrios, |mpiano, violin, horn, |nop. 40, |rE? major.\n700 12 Beethoven, Ludwig van, |d1770-1827. |tSonatas, |mhorn, piano, |nop. 17, |rF major.\n700 12 Krufft, Nikolaus von, |d1779-1818. |tSonata, |mhorn, piano, |rF major.\n"
    end
    describe "for UTF-8 record" do
      before do
        @utf8_exported = @record_utf8_decomposed.export_as_refworks_marc_txt
      end
      it "should export in Unicode normalized C form" do
        @utf8_exported.should_not include("\314\204\312\273") # decomposed
        @utf8_exported.should include("\304\253\312\273") # C-form normalized
      end
    end
  end

  describe "export_as_endnote" do
    it "should export_correctly" do
      endnote_file = @music_record.export_as_endnote
      # We have to parse it a bit to check it.
      endnote_entries = Hash.new {|hash, key| hash[key] = Set.new }
      endnote_file.each_line do |line|
        line =~ /\%(..?) (.*)$/
        endnote_entries[$1] << $2
      end

      endnote_entries["0"].should == Set.new("Format") # I have no idea WHY this is correct, it is definitely not legal, but taking from earlier test for render_endnote in applicationhelper, the previous version of this.  jrochkind.
      endnote_entries["D"].should == Set.new("p2001. ")
      endnote_entries["C"].should == Set.new("[United States] : ")
      endnote_entries["E"].should == Set.new(["Greer, Lowell. ", "Lubin, Steven. ", "Chase, Stephanie, ", "Brahms, Johannes, ", "Beethoven, Ludwig van, ", "Krufft, Nikolaus von, "])
      endnote_entries["I"].should == Set.new("Harmonia Mundi USA, ")
      endnote_entries["T"].should == Set.new("Music for horn ")

      #nothing extra
      Set.new(endnote_entries.keys).should == Set.new(["0", "C", "D", "E", "I", "T"])      
    end
  end
end