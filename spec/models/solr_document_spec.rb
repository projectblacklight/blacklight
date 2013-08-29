# -*- encoding : utf-8 -*-

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'rubygems'
require 'marc'

# WARNING!!!
# If you set any values in Blacklight here, you must reset them to the original
# values in an after() block so other tests get expected results. 
# Blacklight is a Singleton for application configuration.

## TODO: ALL these specs probably really ought to be on the modules
# being tested, not on the bare SolrDocument class that has no logic
# of it's own, it just includes modules. No? jrochkind 29 Mar 2010

def get_hash_with_marcxml
  {'responseHeader'=>{'status'=>0,'QTime'=>0,'params'=>{'q'=>'id:00282214','wt'=>'ruby'}},'response'=>{'numFound'=>1,'start'=>0,'docs'=>[{'id'=>'00282214', "marc_display" =>'<record xmlns=\'http://www.loc.gov/MARC21/slim\'><leader>00799cam a2200241 a 4500</leader><controlfield tag=\'001\'>   00282214 </controlfield><controlfield tag=\'003\'>DLC</controlfield><controlfield tag=\'005\'>20090120022042.0</controlfield><controlfield tag=\'008\'>000417s1998    pk            000 0 urdo </controlfield><datafield tag=\'010\' ind1=\' \' ind2=\' \'><subfield code=\'a\'>   00282214 </subfield></datafield><datafield tag=\'025\' ind1=\' \' ind2=\' \'><subfield code=\'a\'>P-U-00282214; 05; 06</subfield></datafield><datafield tag=\'040\' ind1=\' \' ind2=\' \'><subfield code=\'a\'>DLC</subfield><subfield code=\'c\'>DLC</subfield><subfield code=\'d\'>DLC</subfield></datafield><datafield tag=\'041\' ind1=\'1\' ind2=\' \'><subfield code=\'a\'>urd</subfield><subfield code=\'h\'>snd</subfield></datafield><datafield tag=\'042\' ind1=\' \' ind2=\' \'><subfield code=\'a\'>lcode</subfield></datafield><datafield tag=\'050\' ind1=\'0\' ind2=\'0\'><subfield code=\'a\'>PK2788.9.A9</subfield><subfield code=\'b\'>F55 1998</subfield></datafield><datafield tag=\'100\' ind1=\'1\' ind2=\' \'><subfield code=\'a\'>Ayaz, Shaikh,</subfield><subfield code=\'d\'>1923-1997.</subfield></datafield><datafield tag=\'245\' ind1=\'1\' ind2=\'0\'><subfield code=\'a\'>Fikr-i Ayāz /</subfield><subfield code=\'c\'>murattibīn, Āṣif Farruk̲h̲ī, Shāh Muḥammad Pīrzādah.</subfield></datafield><datafield tag=\'260\' ind1=\' \' ind2=\' \'><subfield code=\'a\'>Karācī :</subfield><subfield code=\'b\'>Dāniyāl,</subfield><subfield code=\'c\'>[1998]</subfield></datafield><datafield tag=\'300\' ind1=\' \' ind2=\' \'><subfield code=\'a\'>375 p. ;</subfield><subfield code=\'c\'>23 cm.</subfield></datafield><datafield tag=\'546\' ind1=\' \' ind2=\' \'><subfield code=\'a\'>In Urdu.</subfield></datafield><datafield tag=\'520\' ind1=\' \' ind2=\' \'><subfield code=\'a\'>Selected poems and articles from the works of renowned Sindhi poet; chiefly translated from Sindhi.</subfield></datafield><datafield tag=\'700\' ind1=\'1\' ind2=\' \'><subfield code=\'a\'>Farruk̲h̲ī, Āṣif,</subfield><subfield code=\'d\'>1959-</subfield></datafield><datafield tag=\'700\' ind1=\'1\' ind2=\' \'><subfield code=\'a\'>Pīrzādah, Shāh Muḥammad.</subfield></datafield></record>','timestamp'=>'2009-03-26T18:15:31.074Z','material_type_display'=>['375 p'],'title_display'=>['Fikr-i Ayāz'],'author_display'=>['Farruk̲h̲ī, Āṣif','Pīrzādah, Shāh Muḥammad'],'language_facet'=>['Urdu'],'format'=>['Book'],'published_display'=>['Karācī']}]}}
end
def get_hash_without_marcxml
  {'responseHeader'=>{'status'=>0,'QTime'=>0,'params'=>{'q'=>'id:00282214','wt'=>'ruby'}},'response'=>{'numFound'=>1,'start'=>0,'docs'=>[{'id'=>'00282214','timestamp'=>'2009-03-26T18:15:31.074Z','material_type_display'=>['375 p'],'title_display'=>['Fikr-i Ayāz'],'author_display'=>['Farruk̲h̲ī, Āṣif','Pīrzādah, Shāh Muḥammad'],'language_facet'=>['Urdu'],'format'=>['Book'],'published_display'=>['Karācī']}]}}
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
  return {'responseHeader'=>{'status'=>0,'QTime'=>0,'params'=>{'q'=>'id:00282214','wt'=>'ruby'}},'response'=>{'numFound'=>1,'start'=>0,'docs'=>[{'id'=>'00282214', "marc_display" => first_rec, 'timestamp'=>'2009-03-26T18:15:31.074Z','material_type_display'=>['375 p'],'title_display'=>['Fikr-i Ayāz'],'author_display'=>['Farruk̲h̲ī, Āṣif','Pīrzādah, Shāh Muḥammad'],'language_facet'=>['Urdu'],'format'=>['Book'],'published_display'=>['Karācī']}]}}
end
  
  describe SolrDocument do
    
    before(:each) do
      @hash_with_marcxml = get_hash_with_marcxml['response']['docs'][0]
      SolrDocument.extension_parameters[:marc_source_field]  = :marc_display
      SolrDocument.extension_parameters[:marc_format_type]   = :marcxml

      # rsolr seems to reload SolrDocument from time to time, so we can't
      # count on the initializer to register the extension, need to re-register
      # it.
      SolrDocument.registered_extensions = nil
      SolrDocument.use_extension( Blacklight::Solr::Document::Marc ) { |document| document.has_key?(:marc_display)}
      
      @solrdoc = SolrDocument.new(@hash_with_marcxml)

    end
    
    describe "new" do
      it "should take a Hash as the argument" do
        lambda { SolrDocument.new(@hash_with_marcxml) }.should_not raise_error
      end
    end
    
    describe "access methods" do

      it "should have the right value for title_display" do
        @solrdoc[:title_display].should_not be_nil
      end
      
      it "should have the right value for format" do
        @solrdoc[:format][0].should == 'Book'
      end
      
      it "should provide the item's solr id" do
        @solrdoc.id.should == '00282214'
      end
    end
    
    describe "ruby marc creation" do
 
      it "should have a valid to_marc" do
        @solrdoc = SolrDocument.new(@hash_with_marcxml)

        @solrdoc.should respond_to(:to_marc)
        @solrdoc.to_marc.should be_kind_of(MARC::Record)        
      end
      
      it "should not try to create marc for objects w/out stored marc (marcxml test only at this time)" do
        # TODO: Create another double object that does not have marc-xml in it and make
        # sure everything fails gracefully
        @hash_without_marcxml = get_hash_without_marcxml['response']['docs'][0]
        @solrdoc_without_marc = SolrDocument.new(@hash_without_marcxml)
        @solrdoc_without_marc.should_not respond_to(:to_marc)
        # legacy check
      #        @solrdoc_without_marc.should respond_to(:marc)
      #        @solrdoc_without_marc.marc.should == nil
      end
    end
    
    
    

    
   

 
    
    
end
