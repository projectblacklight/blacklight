
require 'helper'

class MessageTest < RSolrBaseTest
  
  # call all of the simple methods...
  # make sure the xml string is valid
  # ensure the class is actually Solr::XML
  def test_simple_methods
    [:optimize, :rollback, :commit].each do |meth|
      result = RSolr::Message.send(meth)
      assert_equal "<#{meth}/>", result.to_s
      assert_equal String, result.class
    end
  end
  
  def test_add_yields_doc_objects_if_block_given
    documents = [{:id=>1, :name=>'sam', :cat=>['cat 1', 'cat 2']}]
    add_attrs = {:boost=>200.00}
    result = RSolr::Message.add(documents, add_attrs) do |doc|
      doc.field_by_name(:name).attrs[:boost] = 10
      assert_equal 4, doc.fields.size
      assert_equal 2, doc.fields_by_name(:cat).size
    end
    #<add boost="200.0">
      #<doc>
        #<field name="cat">cat 1</field>
        #<field name="cat">cat 2</field>
        #<field name="name" boost="10">sam</field>
        #<field name="id">1</field>
      #</doc>
    #</add>
    assert result =~ %r(name="cat">cat 1</field>)
    assert result =~ %r(name="cat">cat 2</field>)
    assert result =~ %r(<add boost="200.0">)
    assert result =~ %r(boost="10")
    assert result =~ %r(<field name="id">1</field>)
  end
  
  def test_delete_by_id
    result = RSolr::Message.delete_by_id(10)
    assert_equal String, result.class
    assert_equal '<delete><id>10</id></delete>', result.to_s
  end
  
  def test_delete_by_multiple_ids
    result = RSolr::Message.delete_by_id([1, 2, 3])
    assert_equal String, result.class
    assert_equal '<delete><id>1</id><id>2</id><id>3</id></delete>', result.to_s
  end
  
  def test_delete_by_query
    result = RSolr::Message.delete_by_id('status:"LOST"')
    assert_equal String, result.class
    assert_equal '<delete><id>status:"LOST"</id></delete>', result.to_s
  end
  
  def test_delete_by_multiple_queries
    result = RSolr::Message.delete_by_id(['status:"LOST"', 'quantity:0'])
    assert_equal String, result.class
    assert_equal '<delete><id>status:"LOST"</id><id>quantity:0</id></delete>', result.to_s
  end
  
  # add a single hash ("doc")
  def test_add_hash
    data = {
      :id=>1,
      :name=>'matt'
    }
    assert RSolr::Message.add(data).to_s =~ /<field name="name">matt<\/field>/
    assert RSolr::Message.add(data).to_s =~ /<field name="id">1<\/field>/
  end
  
  # add an array of hashes
  def test_add_array
    data = [
      {
        :id=>1,
        :name=>'matt'
      },
      {
        :id=>2,
        :name=>'sam'
      }
    ]
    
    message = RSolr::Message.add(data)
    expected = '<add><doc><field name="id">1</field><field name="name">matt</field></doc><doc><field name="id">2</field><field name="name">sam</field></doc></add>'
    
    assert message.to_s=~/<field name="name">matt<\/field>/
    assert message.to_s=~/<field name="name">sam<\/field>/
  end
  
  # multiValue field support test, thanks to Fouad Mardini!
  def test_add_multi_valued_field
    data = {
      :id   => 1,
      :name => ['matt1', 'matt2']
    }
    
    result = RSolr::Message.add(data)
    
    assert result.to_s =~ /<field name="name">matt1<\/field>/
    assert result.to_s =~ /<field name="name">matt2<\/field>/
  end
  
  def test_add_single_document
    document = RSolr::Message::Document.new
    document.add_field('id', 1)
    document.add_field('name', 'matt', :boost => 2.0)
    result = RSolr::Message.add(document)
    
    assert result.to_s =~ /<field name="id">1<\/field>/
    
    # depending on which ruby version, the attributes can be out of place
    # so we need to test both... there's gotta be a better way to do this?
    assert(
      result.to_s =~ /<field name="name" boost="2.0">matt<\/field>/ || 
      result.to_s =~ /<field boost="2.0" name="name">matt<\/field>/
    )
  end

  def test_add_multiple_documents
    documents = (1..2).map do |i|
      doc = RSolr::Message::Document.new
      doc.add_field('id', i)
      doc.add_field('name', "matt#{i}")
      doc
    end
    result = RSolr::Message.add(documents)

    assert result.to_s =~ /<field name="name">matt1<\/field>/
    assert result.to_s =~ /<field name="name">matt2<\/field>/
  end
end
