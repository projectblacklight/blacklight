require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'rubygems'
require 'marc'

# WARNING!!!
# If you set any values in Blacklight here, you must reset them to the original
# values in an after() block so other tests get expected results. 
# Blacklight is a Singleton for application configuration.
def get_hash_with_marcxml
  {'responseHeader'=>{'status'=>0,'QTime'=>0,'params'=>{'q'=>'id:00282214','wt'=>'ruby'}},'response'=>{'numFound'=>1,'start'=>0,'docs'=>[{'id'=>'00282214', Blacklight.config[:raw_storage_field] =>'<record xmlns=\'http://www.loc.gov/MARC21/slim\'><leader>00799cam a2200241 a 4500</leader><controlfield tag=\'001\'>   00282214 </controlfield><controlfield tag=\'003\'>DLC</controlfield><controlfield tag=\'005\'>20090120022042.0</controlfield><controlfield tag=\'008\'>000417s1998    pk            000 0 urdo </controlfield><datafield tag=\'010\' ind1=\' \' ind2=\' \'><subfield code=\'a\'>   00282214 </subfield></datafield><datafield tag=\'025\' ind1=\' \' ind2=\' \'><subfield code=\'a\'>P-U-00282214; 05; 06</subfield></datafield><datafield tag=\'040\' ind1=\' \' ind2=\' \'><subfield code=\'a\'>DLC</subfield><subfield code=\'c\'>DLC</subfield><subfield code=\'d\'>DLC</subfield></datafield><datafield tag=\'041\' ind1=\'1\' ind2=\' \'><subfield code=\'a\'>urd</subfield><subfield code=\'h\'>snd</subfield></datafield><datafield tag=\'042\' ind1=\' \' ind2=\' \'><subfield code=\'a\'>lcode</subfield></datafield><datafield tag=\'050\' ind1=\'0\' ind2=\'0\'><subfield code=\'a\'>PK2788.9.A9</subfield><subfield code=\'b\'>F55 1998</subfield></datafield><datafield tag=\'100\' ind1=\'1\' ind2=\' \'><subfield code=\'a\'>Ayaz, Shaikh,</subfield><subfield code=\'d\'>1923-1997.</subfield></datafield><datafield tag=\'245\' ind1=\'1\' ind2=\'0\'><subfield code=\'a\'>Fikr-i Ayāz /</subfield><subfield code=\'c\'>murattibīn, Āṣif Farruk̲h̲ī, Shāh Muḥammad Pīrzādah.</subfield></datafield><datafield tag=\'260\' ind1=\' \' ind2=\' \'><subfield code=\'a\'>Karācī :</subfield><subfield code=\'b\'>Dāniyāl,</subfield><subfield code=\'c\'>[1998]</subfield></datafield><datafield tag=\'300\' ind1=\' \' ind2=\' \'><subfield code=\'a\'>375 p. ;</subfield><subfield code=\'c\'>23 cm.</subfield></datafield><datafield tag=\'546\' ind1=\' \' ind2=\' \'><subfield code=\'a\'>In Urdu.</subfield></datafield><datafield tag=\'520\' ind1=\' \' ind2=\' \'><subfield code=\'a\'>Selected poems and articles from the works of renowned Sindhi poet; chiefly translated from Sindhi.</subfield></datafield><datafield tag=\'700\' ind1=\'1\' ind2=\' \'><subfield code=\'a\'>Farruk̲h̲ī, Āṣif,</subfield><subfield code=\'d\'>1959-</subfield></datafield><datafield tag=\'700\' ind1=\'1\' ind2=\' \'><subfield code=\'a\'>Pīrzādah, Shāh Muḥammad.</subfield></datafield></record>','timestamp'=>'2009-03-26T18:15:31.074Z','material_type_t'=>['375 p'],'title_t'=>['Fikr-i Ayāz'],'author_t'=>['Farruk̲h̲ī, Āṣif','Pīrzādah, Shāh Muḥammad'],'language_facet'=>['Urdu'],'format_code_t'=>['book'],'published_t'=>['Karācī'],'format_facet'=>['Book']}]}}
end
def get_hash_without_marcxml
  {'responseHeader'=>{'status'=>0,'QTime'=>0,'params'=>{'q'=>'id:00282214','wt'=>'ruby'}},'response'=>{'numFound'=>1,'start'=>0,'docs'=>[{'id'=>'00282214','timestamp'=>'2009-03-26T18:15:31.074Z','material_type_t'=>['375 p'],'title_t'=>['Fikr-i Ayāz'],'author_t'=>['Farruk̲h̲ī, Āṣif','Pīrzādah, Shāh Muḥammad'],'language_facet'=>['Urdu'],'format_code_t'=>['book'],'published_t'=>['Karācī'],'format_facet'=>['Book']}]}}
end

def get_hash_with_marc21
  reader = MARC::Reader.new(File.dirname(__FILE__) + '/../data/test_data.utf8.mrc')
  # doing weird i= stuff to get only first record.  reader.first, or i = 0, i+1 didn't work and this was the only way I could get it working.  Needs refactoring.
  i = "1st"
  for record in reader
   if i == "1st"
     first_rec = record.to_marc
   end
   i = "not1st"
  end
  {'responseHeader'=>{'status'=>0,'QTime'=>0,'params'=>{'q'=>'id:00282214','wt'=>'ruby'}},'response'=>{'numFound'=>1,'start'=>0,'docs'=>[{'id'=>'00282214', Blacklight.config[:raw_storage_field] => first_rec, 'timestamp'=>'2009-03-26T18:15:31.074Z','material_type_t'=>['375 p'],'title_t'=>['Fikr-i Ayāz'],'author_t'=>['Farruk̲h̲ī, Āṣif','Pīrzādah, Shāh Muḥammad'],'language_facet'=>['Urdu'],'format_code_t'=>['book'],'published_t'=>['Karācī'],'format_facet'=>['Book']}]}}
end

describe BlacklightMarc do
  before(:all) do
    @original_raw_storage_type = Blacklight.config[:raw_storage_type]
    @original_raw_storage_field = Blacklight.config[:raw_storage_field]
    Blacklight.config[:raw_storage_type] = 'marcxml'
    Blacklight.config[:raw_storage_field] = 'marc_display'
    @hash_with_marcxml = get_hash_with_marcxml['response']['docs'][0]
    @bl_marc_doc = BlacklightMarc::Document.new(@hash_with_marcxml)
  end
  after(:all) do
    Blacklight.config[:raw_storage_type] = @original_raw_storage_type
    Blacklight.config[:raw_storage_field] = @original_raw_storage_field
  end
  describe "Document" do
    describe "new" do
      it "should take a Hash as the argument" do
        lambda { BlacklightMarc::Document.new(@hash_with_marcxml) }.should_not raise_error(ArgumentError)
      end
    end
    describe "marc" do
      it "should create a marc object from marcxml with correct content" do
        # find all of the 700 fields, take the second one, and take it's 'a' subfield
        (@bl_marc_doc.marc.find_all {|f| f.tag == '700'})[1]['a'].should == "Pīrzādah, Shāh Muḥammad."
        @bl_marc_doc.marc['546']['a'].should == "In Urdu."
      end
    end
    describe "marc_xml method" do
      it "should be nil if marc is blank" do
        @hash_without_marcxml = get_hash_without_marcxml['response']['docs'][0]
        @bl_marc_doc = BlacklightMarc::Document.new(@hash_without_marcxml)
        @bl_marc_doc.marc_xml.should be_nil
      end
      it "should be a string" do
        @bl_marc_doc.marc_xml.should be_a(String)
      end
      it "should not be nil if marc record exists" do
        @bl_marc_doc.should_not be_nil
        @bl_marc_doc.marc_xml.should_not be_nil
      end
      it "should return valid MARC XML" do
        @bl_marc_doc.marc_xml.to_s.should match(/<record.*/)
      end
    end
    
    #Marc21 Tests
    before(:all) do
      @original_raw_storage_type = Blacklight.config[:raw_storage_type]
      @original_raw_storage_field = Blacklight.config[:raw_storage_field]
      Blacklight.config[:raw_storage_type] = 'marc21'
      Blacklight.config[:raw_storage_field] = 'raw_marc_display'
      @hash_with_marc21 = get_hash_with_marc21['response']['docs'][0]
      @raw_marc_21 = BlacklightMarc::Document.new(@hash_with_marc21)
    end
    after(:all) do
      Blacklight.config[:raw_storage_type] = @original_raw_storage_type
      Blacklight.config[:raw_storage_field] = @original_raw_storage_field
    end
    describe "marc21" do
      it "should know whether the contents of the marc field are marc21 or marc-xml" do
        Blacklight.config[:raw_storage_type].should_not be_nil
        Blacklight.config[:raw_storage_type].should be_a(String)
      end

      it "should be a string" do
        @raw_marc_21.marc_xml.should be_a(String)
      end

      it "should return valid MARC XML" do
        @raw_marc_21.marc_xml.to_s.should match(/<record.*/)
      end
      
      it "should not be nil if marc record exists" do
        @raw_marc_21.marc_xml.should_not be_nil
      end
      
      it "should parse marc21 correctly" do
        # Had to use this form of the string.  Taken directly from binary data.
        (@raw_marc_21.marc.find_all {|f| f.tag == '700'})[1]['a'].should == "Pīrzādah, Shāh Muḥammad."
        @raw_marc_21.marc['546']['a'].should == "In Urdu."
      end
    end
    
  end
  
end