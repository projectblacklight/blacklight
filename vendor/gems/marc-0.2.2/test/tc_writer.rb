require 'test/unit'
require 'marc'

class WriterTest < Test::Unit::TestCase

    def test_writer
        writer = MARC::Writer.new('test/writer.dat')
        record = MARC::Record.new()
        record.append(MARC::DataField.new('245', '0', '1', ['a', 'foo']))
        writer.write(record)
        writer.close()

        # read it back to make sure
        reader = MARC::Reader.new('test/writer.dat')
        records = reader.entries()
        assert_equal(records.length(), 1)
        assert_equal(records[0], record)

        # cleanup
        File.unlink('test/writer.dat')
    end

    def test_ampersand
    end


end
