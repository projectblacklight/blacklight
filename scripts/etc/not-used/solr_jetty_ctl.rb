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


JAVA='java'
__DIR__=File.expand_path(File.dirname(__FILE__))
SOLR_HOME="#{__DIR__}/../solr-home"
JETTY_APP_HOME="#{__DIR__}/../jetty"
PID_FILE='./solr_jetty.pid'

running = File.file?(PID_FILE)
pid = running ? File.read(PID_FILE).strip.to_i : nil
arg = ARGV.size > 0 ? ARGV[0].strip.downcase : nil

def valid_pid?(pid)
  begin
    Process.kill(0, pid)
    true
  rescue
    false
  end
end

#
#
#
def stop!(pid)
  Process.kill(9, pid)
  File.unlink(PID_FILE)
end

#
# This method is problematic;
# it spans external processes (not child),
# making it impossible to do a single kill
# Have already tried Kernal.fork + Process.detach
#
def start!
  p=nil
  IO.popen("cd #{JETTY_APP_HOME}; #{JAVA} -Dsolr.solr.home=#{SOLR_HOME} -jar start.jar") do |pipe|
    p=$$
  end
  File.open(PID_FILE, File::CREAT|File::TRUNC|File::WRONLY) do |f|
    f.puts p
  end
  p
end

if arg == 'stop'
  if pid.nil?
    puts 'PID not found'
  else
    begin stop!(pid)
      puts 'Stopped OK'
    rescue
      puts $!
    end
  end
  exit
end

if arg == 'init'
  begin
    stop!(pid)
    `rm -Rf ../solr-home/data/index`
    start!
    puts 'Stopped, cleared index and started OK'
  rescue
    puts $!
  end
  exit
end

if arg=='start'
  if running
    puts "Solr/Jetty already running! PID -> #{PID_FILE} -> #{pid}"
    if ! valid_pid?(pid)
      puts "PID is invalid. Try deleting the PID_FILE (#{PID_FILE})"
    end
    exit
  end
  begin
    puts "Started OK. PID=#{start!}"
  rescue
    puts $!
  end
  exit
end

puts "Valid args: start, stop, init (stops, clears index, starts)"