# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

require "rake"
describe "solr:marc:*" do
    # saves original $stdout in variable
    # set $stdout as local instance of StringIO
    # yields to code execution
    # returns the local instance of StringIO
    # resets $stout to original value
    def capture_stdout
      out = StringIO.new
      $stdout = out
      yield
      return out.string
    ensure
      $stdout = STDOUT
    end
    
    before(:all) do
      @rake = Rake::Application.new      
      Rake.application = @rake
      Rake.application.rake_require "../lib/railties/solr_marc"
      Rake::Task.define_task(:environment)
    end
        
    describe 'solr:marc:index_test_data' do        
      it 'should print out usage using NOOP=true' do
        root = Rails.root
        ENV['NOOP'] = "true"
        o = capture_stdout do      
          @rake['solr:marc:index_test_data'].invoke      
        end
        
        expect(o).to match(Regexp.escape("SolrMarc command that will be run:"))
      end    
    end
    
    describe "solr:marc:index" do
      it "should produce proper java command" do
        # can NOT figure out how to actually run solr:marc:index and trap
        # it's backtick system call. So we'll run solr:marc:index:info and
        # just test it's dry run output
        ENV["MARC_FILE"] = "dummy.mrc"
        output = capture_stdout do
          @rake['solr:marc:index:info'].invoke
        end
        output =~ /SolrMarc command that will be run:\n\s*\n\s*(.*)\n/
        java_cmd = $1
        
        expect(java_cmd).not_to be_nil
        expect(java_cmd).to match "java -Xmx512m"
        expect(java_cmd).to match /-jar .*\/SolrMarc\.jar/
        expect(java_cmd).to match "#{Rails.root}/config/SolrMarc/config-test.properties dummy.mrc"
        expect(java_cmd).to match "-Dsolr.hosturl=http://127.0.0.1:[0-9]{2,5}/solr"
      end
      
    end  
  end

