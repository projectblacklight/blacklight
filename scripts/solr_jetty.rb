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

`cd #{JETTY_APP_HOME} && #{JAVA} -Dsolr.solr.home=#{SOLR_HOME} -jar start.jar`