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


class ML::MarcIndexer
  
  require "fileutils"
  
  
  def initialize(marc_file, mapping, solr_config)
    
    @marc_file=marc_file
    @mapping=mapping
    @solr_config=solr_config
    @already_indexed = "logs/indexed_files.log"
    @log_file = "logs/processing_times.log"
    FileUtils.touch @log_file
    FileUtils.touch @already_indexed
  end
  
  def already_indexed
    @already_indexed
  end
  
  def go!
    if (already_logged?)
      puts "#{@marc_file} was already indexed -- Skipping."
    else
      reader = ML::DataSource.new(@marc_file)
      mapper = ML::Mapper.new(@mapping)
      count = 0
      indexer = Solr::Indexer.new(reader, mapper, @solr_config)
      
      ## indexing large data sets keeps resulting in "execution expired (Timeout::Error)"
      ## I hope this fixes it. --EOS
      #
      # for above... Might want to look at options[:buffer_docs] in the Solr::Indexer class
      # Set this to a number and it'll wait for that number before adding the docs to Solr - mwm4n
      #
      begin
        start_time = Time.new
        result = indexer.index do |orig_data, solr_document|
          
          #STDOUT << solr_document
          
          yield(count, orig_data, solr_document) if block_given?
          count = count + 1
          
          #if(count%1000==0)
          #  indexer.solr.commit
          #  STDOUT << "*************** committing!"
          #end
        end
        end_time = Time.new
        log_file(start_time, end_time, count)
      rescue TimeoutError => timeout_error
        log_error("Solr connection timed out: #{timeout_error}")
        sleep 10
        retry
      rescue
        # capture any other exceptions here.... -mwm4n
        puts "#{$!} - optimize() was not executed!"
        exit
      end
      
      ## after finishing an entire marc file... 
      indexer.solr.commit
      #optimizing slows things down # optimize(indexer)
      result
      
    end
  end
  
  def optimize(indexer)
    count = 0
    begin
      indexer.solr.optimize
    rescue TimeoutError => timeout_error
      count += 1
      log_error("Solr optimize timed out: #{timeout_error}")
      sleep 10
      if(count < 5)
        retry
      end
    rescue
      puts $!
      exit
    end
  end
  
  def log_file(start_time, end_time, count)
    
    begin
      log_file = File.open(@log_file, File::WRONLY|File::APPEND) 
      oldout = $stdout
      $stdout = log_file
      puts "#{Time.new.to_s} :: #{@marc_file} :: processed #{count} records in #{(end_time - start_time).to_s} seconds\n"
      log_file.close
    
      already_indexed = File.open(@already_indexed, File::WRONLY|File::APPEND) 
      $stdout = already_indexed
      puts "#{@marc_file} \n"
      already_indexed.close
    
      $stdout = oldout 
    rescue Exception => e
      puts e
    end
    
  end
  
  def already_logged?
    log_file = File.open(@already_indexed)

    while data = log_file.gets
      if(data.strip == @marc_file)
        return true
      end
    end
    log_file.close
    return false
  end
  
end