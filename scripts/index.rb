require 'lib/ml'
require 'optparse'
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



require 'ostruct'
require '../lib/marc_ext/lib/marc_ext.rb'
require 'marc_ext/record'
class MARC::Record
  include MARCEXT::Record
end

#################################################################
#################################################################
#################################################################

# IS THIS ACTUALLY USED ANYWHERE???
$KCODE = 'UTF8'

## set default values
## these can be over-ridden with command line flags

solr_config={
  :solr_url => 'http://localhost:8983/solr',
  :debug=>false,
  :timeout=>120,
  :autocommit=>false
}

data_dir = '../data/marc/virgo'
test_dir = '../test/data'
files_to_index_dir = data_dir

## set us up to accept command line flags
## valid options should be:
## -h or --help
## --marcdir [/full/path/to/marcdir]
## -t or --test (this will override other options and load only the test data)
## --csv /path/to/csv (create a csv file instead of posting to solr)
## --solr [http://example.com:8983/solr/update]
options = OpenStruct.new
opts = OptionParser.new do |opts|
  
  ## Specify where the marc files are 
  opts.on("--marcdir PATH", "Specify where the .mrc files that you want to index are, like /full/path/to/marcdir") do |d|
      marc_files = Dir["#{d}/*.mrc"].entries
      if marc_files.length == 0
        puts
        puts #check to see if there are any marc files, if not throw and error and exit
        puts "ERROR: There aren't any marc files in that directory!"
        exit
      else
        files_to_index_dir = d
      end
  end
  
  ## Tell the indexer to only index the test data 
  opts.on("-t","--test", "Load test data only. This will override a --data-dir command.") do 
    puts "Loading test data!"
    files_to_index_dir = test_dir
  end
  
  ## Specify where your solr instance is 
  opts.on("--solr URL", "Specify a solr url like http://hostname.com:8983/solr") do |s|
    solr_config[:solr_url] = s
  end
  
  ## Display help message 
  opts.on_tail("-h","--help", "Show this usage statement") do |h|
    puts opts
    exit
  end
end


## Start parsing the arguments that were passed to the script. 
## This will set certain values that will determine how the index runs.
begin
  opts.parse!(ARGV)
  puts "Posting data to: " + solr_config[:solr_url]
rescue Exception => e
  puts e, "", opts
  exit
end

start_time = Time.new ## start the clock
total_files = 0       ## start the count
require 'virgo_marc_map' ## get the index mapping

## put all of the .mrc files in the directory into an array
marc_files = Dir["#{files_to_index_dir}/*.mrc"].entries

## go through all the .mrc files in the files_to_index_dir and index each one of them
marc_files.each do |marc_file|

  indexer = ML::MarcIndexer.new(marc_file, VIRGO_MARC_MAP, solr_config)

  puts "#{Time.new}: Indexing #{marc_file}..."

  result = indexer.go! do |count, marc_record, solr_doc|
    puts "Indexing #{marc_file} # #{count+1}"
    total_files += 1
    puts "Total files indexed: #{total_files}"
  end

  puts result ? 'COMMIT: YES' : 'COMMIT: NO (debug=true == no commit. Check debug value.)'
end

end_time = Time.new
time_lapsed = end_time - start_time
puts "#{total_files} records indexed in #{time_lapsed} seconds"