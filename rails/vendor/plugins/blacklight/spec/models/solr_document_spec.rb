require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'rubygems'
require 'marc'

def get_hash_with_marcxml
  {'responseHeader'=>{'status'=>0,'QTime'=>0,'params'=>{'q'=>'id:00282214','wt'=>'ruby'}},'response'=>{'numFound'=>1,'start'=>0,'docs'=>[{'id'=>'00282214','marc_display'=>'<record xmlns=\'http://www.loc.gov/MARC21/slim\'><leader>00799cam a2200241 a 4500</leader><controlfield tag=\'001\'>   00282214 </controlfield><controlfield tag=\'003\'>DLC</controlfield><controlfield tag=\'005\'>20090120022042.0</controlfield><controlfield tag=\'008\'>000417s1998    pk            000 0 urdo </controlfield><datafield tag=\'010\' ind1=\' \' ind2=\' \'><subfield code=\'a\'>   00282214 </subfield></datafield><datafield tag=\'025\' ind1=\' \' ind2=\' \'><subfield code=\'a\'>P-U-00282214; 05; 06</subfield></datafield><datafield tag=\'040\' ind1=\' \' ind2=\' \'><subfield code=\'a\'>DLC</subfield><subfield code=\'c\'>DLC</subfield><subfield code=\'d\'>DLC</subfield></datafield><datafield tag=\'041\' ind1=\'1\' ind2=\' \'><subfield code=\'a\'>urd</subfield><subfield code=\'h\'>snd</subfield></datafield><datafield tag=\'042\' ind1=\' \' ind2=\' \'><subfield code=\'a\'>lcode</subfield></datafield><datafield tag=\'050\' ind1=\'0\' ind2=\'0\'><subfield code=\'a\'>PK2788.9.A9</subfield><subfield code=\'b\'>F55 1998</subfield></datafield><datafield tag=\'100\' ind1=\'1\' ind2=\' \'><subfield code=\'a\'>Ayaz, Shaikh,</subfield><subfield code=\'d\'>1923-1997.</subfield></datafield><datafield tag=\'245\' ind1=\'1\' ind2=\'0\'><subfield code=\'a\'>Fikr-i Ayāz /</subfield><subfield code=\'c\'>murattibīn, Āṣif Farruk̲h̲ī, Shāh Muḥammad Pīrzādah.</subfield></datafield><datafield tag=\'260\' ind1=\' \' ind2=\' \'><subfield code=\'a\'>Karācī :</subfield><subfield code=\'b\'>Dāniyāl,</subfield><subfield code=\'c\'>[1998]</subfield></datafield><datafield tag=\'300\' ind1=\' \' ind2=\' \'><subfield code=\'a\'>375 p. ;</subfield><subfield code=\'c\'>23 cm.</subfield></datafield><datafield tag=\'546\' ind1=\' \' ind2=\' \'><subfield code=\'a\'>In Urdu.</subfield></datafield><datafield tag=\'520\' ind1=\' \' ind2=\' \'><subfield code=\'a\'>Selected poems and articles from the works of renowned Sindhi poet; chiefly translated from Sindhi.</subfield></datafield><datafield tag=\'700\' ind1=\'1\' ind2=\' \'><subfield code=\'a\'>Farruk̲h̲ī, Āṣif,</subfield><subfield code=\'d\'>1959-</subfield></datafield><datafield tag=\'700\' ind1=\'1\' ind2=\' \'><subfield code=\'a\'>Pīrzādah, Shāh Muḥammad.</subfield></datafield></record>','timestamp'=>'2009-03-26T18:15:31.074Z','material_type_t'=>['375 p'],'title_t'=>['Fikr-i Ayāz'],'author_t'=>['Farruk̲h̲ī, Āṣif','Pīrzādah, Shāh Muḥammad'],'language_facet'=>['Urdu'],'format_code_t'=>['book'],'published_t'=>['Karācī'],'format_facet'=>['Book']}]}}
end
def get_hash_without_marcxml
  {'responseHeader'=>{'status'=>0,'QTime'=>0,'params'=>{'q'=>'id:00282214','wt'=>'ruby'}},'response'=>{'numFound'=>1,'start'=>0,'docs'=>[{'id'=>'00282214','timestamp'=>'2009-03-26T18:15:31.074Z','material_type_t'=>['375 p'],'title_t'=>['Fikr-i Ayāz'],'author_t'=>['Farruk̲h̲ī, Āṣif','Pīrzādah, Shāh Muḥammad'],'language_facet'=>['Urdu'],'format_code_t'=>['book'],'published_t'=>['Karācī'],'format_facet'=>['Book']}]}}
end

  describe SolrDocument do
    before(:each) do
      @hash_with_marcxml = get_hash_with_marcxml['response']['docs'][0]
      @solrdoc = SolrDocument.new(@hash_with_marcxml)
    end

    describe "new" do
      it "should take a Hash as the argument" do
        lambda { SolrDocument.new(@hash_with_marcxml) }.should_not raise_error(ArgumentError)
      end
    end
    
    describe "access methods" do
      it "should have the right value for format_facet" do
        @solrdoc.format_facet[0].should == 'Book'
      end
      it "should provide the item's solr id" do
        @solrdoc.solr_id.should == '00282214'
      end
      it "should have a table method that returns a Hash" do
        @solrdoc.table.should be_instance_of(Hash)
        
      end
      it "should have access methods for all required fields" #do
        # will we have a list of required fields? I really just mean the ones
        # specified in solr.yml
      #end
    end
    
    describe "marc" do
      it "should know the name of the marc field" #do
        # again, from solr.yml. It has to know the value so it can know where to get the stored marc
      #end
      it "should know whether the contents of the marc field are marc21 or marc-xml" #do
        # tabling this until we decide whether we're going to be able to deal with stored marc21
      #end
      
      it "should parse marc-xml correctly" do
        @solrdoc.marc.should be_instance_of(MARC::Record)
      end
      it "should not try to create marc for objects w/out stored marc" #do
        # TODO: Create another mock object that does not have marc-xml in it and make
        # sure everything fails gracefully
#      end
      it "should parse marc21 correctly" #do
          # let's table this until we decide whether we're going to be able to deal with stored marc21
      #end
      it "should create a valid marc object" do
        # find all of the 700 fields, take the second one, and take it's 'a' subfield
        (@solrdoc.marc.find_all {|f| f.tag == '700'})[1]['a'].should == "Pīrzādah, Shāh Muḥammad."
        @solrdoc.marc['546']['a'].should == "In Urdu."
      end
    end
    
    describe "marc_xml" do
      it "should be nil if marc is blank" do
        @hash_without_marcxml = get_hash_without_marcxml['response']['docs'][0]
        @solrdoc = SolrDocument.new(@hash_without_marcxml)
        @solrdoc.marc_xml.should be_nil
      end
      it "should be a string" do
        @solrdoc.marc_xml.should be_a(String)
      end
      it "should not be nil if marc record exists" do
        @solrdoc.marc.should_not be_nil
        @solrdoc.marc_xml.should_not be_nil
      end
      
      it "should return valid MARC XML" do
        @solrdoc.marc_xml.to_s.should match(/<record.*/)
      end
    end
end