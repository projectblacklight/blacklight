# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# A singleton class for starting/stopping a Solr server for testing purposes
# The behavior of TestSolrServer can be modified prior to start() by changing 
# port, solr_home, and quiet properties.

class JettySolrServer
  attr_accessor :port, :jetty_home, :solr_home, :quiet, :sleep_after_start

  # configure the singleton with some defaults
  def initialize(params = {})
    @pid = nil
    self.quiet = params[:quiet] || true
    self.jetty_home = params[:jetty_home]
    self.solr_home = params[:solr_home] || File.expand_path("./solr", self.jetty_home)
    self.port = params[:jetty_port] || 8888
  end

  def wrap        
    puts "JettySolrServer: starting server on #{RUBY_PLATFORM}"
    self.start
    begin
      yield
    ensure      
      puts "JettySolrServer: stopping solr server"
      self.stop
    end
  end
  
  def jetty_command
    "java -Djetty.port=#{@port} -Dsolr.solr.home=#{@solr_home} -jar start.jar"
  end
  
  def start
    puts "executing: #{jetty_command}"
    
    platform_specific_start
    
    if self.sleep_after_start
      puts "sleeping #{self.sleep_after_start}s waiting for startup."
      sleep self.sleep_after_start
    end
  end
  
  def stop
    platform_specific_stop
  end
  
  if RUBY_PLATFORM =~ /mswin32/
    require 'win32/process'

    # start the solr server
    def platform_specific_start
      Dir.chdir(@jetty_home) do
        @pid = Process.create(
              :app_name         => jetty_command,
              :creation_flags   => Process::DETACHED_PROCESS,
              :process_inherit  => false,
              :thread_inherit   => true,
              :cwd              => "#{@jetty_home}"
           ).process_id
      end
    end

    # stop a running solr server
    def platform_specific_stop
      Process.kill(1, @pid)
      Process.wait
    end
  else # Not Windows
    
    def jruby_raise_error?
      raise 'JRuby requires that you start solr manually, then run "rake spec" or "rake features"' if defined?(JRUBY_VERSION)
    end
    
    # start the solr server
    def platform_specific_start
      
      jruby_raise_error?
      
      puts self.inspect
      Dir.chdir(@jetty_home) do
        @pid = fork do
          STDERR.close if @quiet
          exec jetty_command
        end
      end
    end

    # stop a running solr server
    def platform_specific_stop
      jruby_raise_error?
      Process.kill('TERM', @pid)
      Process.wait
    end
  end

end
# 
# puts "hello"
# SOLR_PARAMS = {
#   :quiet => ENV['SOLR_CONSOLE'] ? false : true,
#   :jetty_home => ENV['SOLR_JETTY_HOME'] || File.expand_path('../../jetty'),
#   :jetty_port => ENV['SOLR_JETTY_PORT'] || 8888,
#   :solr_home => ENV['SOLR_HOME'] || File.expand_path('test')
# }
# 
# # wrap functional tests with a test-specific Solr server
# got_error = TestSolrServer.wrap(SOLR_PARAMS) do
#   puts `ps aux | grep start.jar` 
# end
# 
# raise "test failures" if got_error
# 