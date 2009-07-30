require 'test/unit'
require 'marc'
require 'stringio'

class XMLTest < Test::Unit::TestCase

  def test_xml_entities
    r1 = MARC::Record.new
    r1 << MARC::DataField.new('245', '0', '0', ['a', 'foo & bar & baz'])
    xml = r1.to_xml.to_s
    assert_match /foo &amp; bar &amp; baz/, xml

    reader = MARC::XMLReader.new(StringIO.new(xml))
    r2 = reader.entries[0]
    assert_equal 'foo & bar & baz', r2['245']['a']
  end

  def test_batch
    reader = MARC::XMLReader.new('test/batch.xml')
    count = 0
    for record in reader
      count += 1
      assert_instance_of(MARC::Record, record)
    end
    assert_equal(count, 2)
  end

  def test_read_string
    xml = File.new('test/batch.xml').read
    reader = MARC::XMLReader.new(StringIO.new(xml))
    assert_equal 2, reader.entries.length
  end
  
  def test_non_numeric_fields
    reader = MARC::XMLReader.new('test/non-numeric.xml')
      count = 0
      record = nil
      reader.each do | rec |
        count += 1 
        record = rec
      end
      assert_equal(1, count)
      assert_equal('9780061317842', record['ISB']['a'])
      assert_equal('1', record['LOC']['9'])
    end

  def test_read_no_leading_zero_write_leading_zero
    reader = MARC::XMLReader.new('test/no-leading-zero.xml')
    record = reader.to_a[0]
    assert_equal("042 zz $a dc ", record['042'].to_s)
  end

  def test_leader_from_xml
    reader = MARC::XMLReader.new('test/one.xml')
    record = reader.entries[0]
    assert_equal '     njm a22     uu 4500', record.leader
    # serializing as MARC should populate the record length and directory offset
    record = MARC::Record.new_from_marc(record.to_marc)
    assert_equal '00734njm a2200217uu 4500', record.leader
  end

  def test_read_write
    record1 = MARC::Record.new
    record1.leader =  '00925njm  22002777a 4500'
    record1.append MARC::ControlField.new('007', 'sdubumennmplu')
    record1.append MARC::DataField.new('245', '0', '4', 
      ['a', 'The Great Ray Charles'], ['h', '[sound recording].'])

    writer = MARC::XMLWriter.new('test/test.xml', :stylesheet => 'style.xsl')
    writer.write(record1)
    writer.close

    xml = File.read('test/test.xml')
    assert_match /<controlfield tag='007'>sdubumennmplu<\/controlfield>/, xml
    assert_match /<\?xml-stylesheet type="text\/xsl" href="style.xsl"\?>/, xml

    reader = MARC::XMLReader.new('test/test.xml')
    record2 = reader.entries[0]
    assert_equal(record1, record2)

    File.unlink('test/test.xml')
  end

end

