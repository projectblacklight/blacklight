require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

require "rake"

describe 'solr:marc:index_test_data' do
  
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
  
  before do
    @rake = Rake::Application.new
    Rake.application = @rake
    Rake.application.rake_require "lib/tasks/solr_marc"
  end
  
  it 'should only print the java command when using NOOP=true' do
    root = Rails.root
    expected = "java -Xmx512m -Dsolr.indexer.properties=#{root}/config/SolrMarc/index.properties -Done-jar.class.path=#{root}/jetty/webapps/solr.war -Dsolr.path=#{root}/jetty/solr -jar #{root}/solr_marc/SolrMarc.jar #{root}/config/SolrMarc/config.properties #{root}/test-data/test_data.utf8.mrc"
    ENV['NOOP'] = "true"
    o = capture_stdout do
      puts 'BEFORE >>>'
      @rake['solr:marc:index_test_data'].invoke
      puts '<<< AFTER'
    end
    o.should match(Regexp.escape(expected))
  end
  
end