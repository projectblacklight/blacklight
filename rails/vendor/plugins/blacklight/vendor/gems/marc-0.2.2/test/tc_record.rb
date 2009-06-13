require 'test/unit'
require 'marc'

class TestRecord < Test::Unit::TestCase

    def test_constructor
        r = MARC::Record.new()
        assert_equal(r.class, MARC::Record)
    end

    def test_xml
      r = get_record()
      doc = r.to_xml
      assert_kind_of REXML::Element, doc
      assert_equal "<record xmlns='http://www.loc.gov/MARC21/slim'><leader>      Z   22        4500</leader><datafield tag='100' ind1='2' ind2='0'><subfield code='a'>Thomas, Dave</subfield></datafield><datafield tag='245' ind1='0' ind2='4'><subfield code='The Pragmatic Programmer'></subfield></datafield></record>", doc.to_s
    end

    def test_append_field
        r = get_record()
        assert_equal(r.fields.length(), 2)
    end

    def test_iterator
        r = get_record()
        count = 0
        r.each {|f| count += 1}
        assert_equal(count,2)
    end

    def test_decode
        raw = IO.read('test/one.dat')
        r = MARC::Record::new_from_marc(raw)
        assert_equal(r.class, MARC::Record)
        assert_equal(r.leader, '00755cam  22002414a 4500')
        assert_equal(r.fields.length(), 18)
        assert_equal(r.find {|f| f.tag == '245'}.to_s,
            '245 10 $a ActivePerl with ASP and ADO / $c Tobias Martinsson. ')
    end

    def test_decode_forgiving
        raw = IO.read('test/one.dat')
        r = MARC::Record::new_from_marc(raw, :forgiving => true)
        assert_equal(r.class, MARC::Record)
        assert_equal(r.leader, '00755cam  22002414a 4500')
        assert_equal(r.fields.length(), 18)
        assert_equal(r.find {|f| f.tag == '245'}.to_s,
            '245 10 $a ActivePerl with ASP and ADO / $c Tobias Martinsson. ')
    end

    def test_encode
        r1 = MARC::Record.new()
        r1.append(MARC::DataField.new('100', '2', '0', ['a', 'Thomas, Dave']))
        r1.append(MARC::DataField.new('245', '0', '0', ['a', 'Pragmatic Programmer']))
        raw = r1.to_marc()
        r2 = MARC::Record::new_from_marc(raw)
        assert_equal(r1, r2)
    end

    def test_lookup_shorthand
        r = get_record
        assert_equal(r['100']['a'], 'Thomas, Dave')
    end

    def get_record
        r = MARC::Record.new()
        r.append(MARC::DataField.new('100', '2', '0', ['a', 'Thomas, Dave'])) 
        r.append(MARC::DataField.new('245', '0', '4', ['The Pragmatic Programmer']))
        return r
    end


end
