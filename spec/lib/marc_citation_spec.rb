require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'rubygems'
require 'marc'

def standard_citation
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

describe Blacklight::Marc::Citation do
  
  before(:all) do
    dclass = Blacklight::Marc::Document
    @record_with_standard_citation_data = dclass.new(standard_citation, :marcxml)
    @record_without_245b                = dclass.new(record1_xml, :marcxml)
    @record_without_authors             = dclass.new(record2_xml, :marcxml)
    @record_with_4plus_authors          = dclass.new(record3_xml, :marcxml)
    @record_without_citable_data        = dclass.new(no_good_data_xml, :marcxml)
  end
  
  describe "to_apa" do
    it "should format a standard citation correctly" do
      @record_with_standard_citation_data.to_apa.should == "Ferree, D. C, &amp; Warrington, I. J. (2003). <i>Apples : botany, production, and uses.</i> Oxon, U.K.: CABI Pub."
    end
    
    it "should format a citation without a 245b field correctly" do
      @record_without_245b.to_apa.should == "Janetzky, K., &amp; Brüchle, B. (1988). <i>The horn.</i> London: Batsford."
    end
    
    it "should format a citation without any authors correctly" do
      @record_without_authors.to_apa.should == "(1971). <i>Final report to the Honorable John J. Gilligan, Governor.</i> [Columbus: Printed by the State of Ohio, Dept. of Urban Affairs."
    end
    
    it "should not fail if there is no citation data" do
      @record_without_citable_data.to_apa.should == ""
    end
    
  end
  
  describe "to_mla" do
    it "should format a standard citation correctly" do
      @record_with_standard_citation_data.to_mla.should == "Ferree, David C, and I. J Warrington. <i>Apples : Botany, Production, and Uses.</i> Oxon, U.K.: CABI Pub., 2003."
    end
    
    it "should format a citation without a 245b field correctly" do
      @record_without_245b.to_mla.should == "Janetzky, Kurt, and Bernhard Brüchle. <i>The Horn.</i> London: Batsford, 1988."
    end
    
    it "should format a citation without any authors correctly" do
      @record_without_authors.to_mla.should == "<i>Final Report to the Honorable John J. Gilligan, Governor.</i> [Columbus: Printed by the State of Ohio, Dept. of Urban Affairs, 1971."
    end
    
    it "should format a citation with 4+ authors correctly" do
      @record_with_4plus_authors.to_mla.should == "Greer, Lowell, et al. <i>Music for Horn.</i> [United States]: Harmonia Mundi USA, 2001."
    end
    
    it "should not fail if there is no citation data" do
      @record_without_citable_data.to_mla.should == ""      
    end
  end
  
  describe "to_zotero" do
    it "should display the appropriate COinS metadata for books" do
      record = @record_with_standard_citation_data.to_zotero('Book')
      record.should match(/<span class='Z3988'.*mtx%3Abook.*rft.genre=book.*rft.btitle=Apples\+%3A\+botany%2C\+production%2C\+and\+uses.*rft.date=c2003.*rft.pub=Oxon%2C\+U.K.*rft.isbn='><\/span>/) and
      record.should_not match(/.*rft.genre=article.*rft.issn=.*/)
    end
    it "should display the appropriate COinS metadata for journals" do
      record = @record_with_standard_citation_data.to_zotero('Journal')
      record_journal_other = @record_with_standard_citation_data.to_zotero('Journal/Magazine')
      record.should match(/<span class='Z3988'.*mtx%3Ajournal.*rft.genre=article.*rft.title=Apples\+%3A\+botany%2C\+production%2C\+and\+uses.*rft.atitle=Apples\+%3A\+botany%2C\+production%2C\+and\+uses.*rft.date=c2003.*rft.issn='><\/span>/) and
      record_journal_other.should == record and
      record.should_not match(/.*rft.genre=book.*rft.isbn=.*/)
    end
    it "should display the appropriate COinS metadata for other content" do
      record = @record_with_standard_citation_data.to_zotero('NotARealFormat')
      record.should match(/<span class='Z3988'.*mtx%3Adc.*rft.title=Apples\+%3A\+botany%2C\+production%2C\+and\+uses.*rft.creator=.*rft.date=c2003.*rft.pub=Oxon%2C\+U.K.*rft.format=notarealformat'><\/span>/) and
      record.should_not match(/.*rft.isbn=.*/) and
      record.should_not match(/.*rft.issn=.*/)
    end
  end
end