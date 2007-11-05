##########################################################################
# Copyright 2008 Rector and Visitors of the University of Virginia
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
##########################################################################



$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
$:.unshift File.join(File.dirname(__FILE__), "../../lib")
$:.unshift File.join("/opt/local/lib/ruby/gems/1.8/gems/solr-ruby-0.0.5/lib/")
$:.unshift File.join(File.dirname(__FILE__), "..")
$:.unshift File.join(File.dirname(__FILE__), '../../lib/marc_ext/lib/marc_ext.rb')
$:.unshift File.join(File.dirname(__FILE__), '../../lib/marc_ext/lib/marc_ext/record.rb')
$:.unshift File.join(File.dirname(__FILE__), '../../lib/marc_ext/lib/marc_ext/record/field_045.rb')
$:.unshift File.join(File.dirname(__FILE__), '../../lib/marc_ext/lib/marc_ext/record/format_type.rb')



## print out the load path
#puts $:

require 'test/unit'
require 'solr'
include Solr
include Solr::Importer
require 'virgo_marc_map' ## get the index mapping
require 'lib/ml'
require '../../lib/marc_ext/lib/marc_ext.rb'
require 'marc_ext/record'
class MARC::Record
  include MARCEXT::Record
end
require "fileutils"


class MappingTest < Test::Unit::TestCase
  
  
  def setup
    @solr_config={
      ## to-do: this should grab solr value from environment.rb
      :solr_url => 'http://localhost:8983/solr',
      :debug=>false,
      :timeout=>120
    }
    @test_dir = File.join(File.dirname(__FILE__), '../../test/data')
    @total_indexed = 0
    @total_should_be = 15
  end
  
  ########################################################
  ## This is the main test                              ##
  ## These tests must be run in order to make any sense ##
  ########################################################
  
  def test_all
    
    ## test low-level stuff
    subtest_bad_url
    subtest_connection_initialize
    subtest_marc_files_exist
    
    ## test log files and data load
    clean_log
    subtest_log_is_empty
    subtest_load_data
    subtest_log_is_not_empty
    subtest_load_data_again ## it shouldn't load it the second time, since the log file should show that this file was already indexed
    
    
    #subtest_recording_is_recording?
    
    
    ## test deleting data and cleanup
    subtest_delete_data 
    ## should also test to make sure the test data is really gone
    clean_log
    subtest_log_is_empty
  end
  
  ########################################################
  ## These are the sub-tests                            ##
  ########################################################
  
  ## assert that the test file has not been recorded as logged
  def subtest_log_is_empty
    marc_file = Dir["#{@test_dir}/*.mrc"].entries[0]
    indexer = ML::MarcIndexer.new(marc_file, VIRGO_MARC_MAP, @solr_config)
    assert !indexer.already_logged?
  end
  
  ## assert that the test file has been recorded as logged
  def subtest_log_is_not_empty
    marc_file = Dir["#{@test_dir}/*.mrc"].entries[0]
    indexer = ML::MarcIndexer.new(marc_file, VIRGO_MARC_MAP, @solr_config)
    assert indexer.already_logged?
  end
  
  ## generic task to clean the log file
  def clean_log
    marc_file = Dir["#{@test_dir}/*.mrc"].entries[0]
    indexer = ML::MarcIndexer.new(marc_file, VIRGO_MARC_MAP, @solr_config)
    FileUtils.rm indexer.already_indexed
    FileUtils.touch indexer.already_indexed
  end
  
  ## index an item that is known to be a recording and make sure it got
  ## marked as format type recording
  def subtest_recording_is_recording?
    conn = Solr::Connection.new(@solr_config[:solr_url], :autocommit => :on)
    response = conn.query('id:fake399')
    assert true
  end
  
  ## delete the test data
  def subtest_delete_data
      conn = Solr::Connection.new(@solr_config[:solr_url], :autocommit => :on)
      request = Solr::Request::Standard.new(:query => 'id:fake*', :start => 0, :rows => 50,
            :field_list => ['id','score'], :operator => :or)
      assert_equal 0, request.to_hash[:start]
      assert_equal 50, request.to_hash[:rows]
      raw_response = conn.send(request)
      
      ## after indexing, check to see we indexed the correct number of records
      assert @total_indexed == @total_should_be
      
      ## after indexing, there should be the same number of records matching the query
      ## as there were when we ran the add test
      assert raw_response.total_hits == @total_indexed
      response = raw_response.data['response']
      response['docs'].each do |r|
          conn.delete(r['id'])
      end
      assert conn.commit
      assert conn.optimize
      ## after deleting fake data, there should be 0 records matching the query
      raw_response = conn.send(request)
      assert raw_response.total_hits == 0 
  end
  
  ## make sure the test data is loaded 
  def subtest_load_data 
    assert load_data
  end
  
  ## try it again, and this time it should skip the file, 
  ## because it should see that this file was indexed already
  def subtest_load_data_again
    assert !load_data
  end
  
  ## load the test data, in a generic method so it can be re-used
  ## return true if file is indexed, false if file is skipped
  def load_data
    total_files = 0
    
    ## put all of the .mrc files in the directory into an array
    marc_files = Dir["#{@test_dir}/*.mrc"].entries[0]

    ## go through all the .mrc files in the files_to_index_dir and index each one of them
    marc_files.each do |marc_file|

      indexer = ML::MarcIndexer.new(marc_file, VIRGO_MARC_MAP, @solr_config)
      if(indexer.already_logged?) 
        return false
      end

      puts "#{Time.new}: Indexing #{marc_file}..."

      result = indexer.go! do |count, marc_record, solr_doc|
        puts "adding record # #{count+1}"
        #puts solr_doc
        total_files += 1
        #puts result ? 'COMMIT: YES' : 'COMMIT: NO (debug=true == no commit. Check debug value.)'
      end
     #puts result ? 'COMMIT: YES' : 'COMMIT: NO (debug=true == no commit. Check debug value.)'
      @total_indexed = total_files
      return result
    end
  end
  
  ## Are there marc files in the test directory? 
  def subtest_marc_files_exist
    marc_files = Dir["#{@test_dir}/*.mrc"].entries
    assert marc_files.length > 0
  end

  ## connect to a bad URL and ensure that you raise a Runtime Error
  def subtest_bad_url
    assert_raise(RuntimeError) do
      Connection.new("ftp://localhost:9999")
    end
  end

  ## connect to a valid solr URL and ensure that the URL is what you think it is
  def subtest_connection_initialize
    connection = Solr::Connection.new(@solr_config[:solr_url])
    assert_equal 'localhost', connection.url.host
    assert_equal 8983, connection.url.port
    assert_equal '/solr', connection.url.path
    assert true
  end
  
  def test_field_set
    assert true
  end
  
end