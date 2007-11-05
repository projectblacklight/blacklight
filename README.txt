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


Bess Sadler
eos8d@virginia.edu - 23-JAN-08:

How to use this project:
	1. Check out the entire project from https://aleph.lib.virginia.edu/svn/music-lib/trunk/
	2. start solr: cd scripts; ruby solr_jetty.rb
		This will start solr via jetty on port 8983
	3. index some data. You can index a very small test set like this:
		cd scripts; ruby index.rb --test
	   Or you can index a larger test set like this:
		cd scripts; ruby index.rb
	   Or you can index your own data like this:
		cd scripts; ruby index.rb --marcdir /path/to/your/marcdir
	 
		The indexing script expects to receive a directory full of binary marc files
		
	4. Start ruby: cd rails; ./script server
		This will start ruby on port 3000

(If the program is using sessions you'll also need to create a mysql database for them and edit config/database.yml appropriately)
	
	Matt Mitchell
	mwm4n@virginia.edu - 11-06-07:
	* To re-initialize an existing Solr index:
		1. stop Solr
		2. remove the entire solr-home/data/index directory: "rm -Rf solr-home/data/index"
		3. start Solr
		4. Re-index Solr


Matt Mitchell
mwm4n@virginia.edu - 10-24-07:

Directories:
	data - marc data/data for solr indexing
	jetty - jetty installation for running solr
	lib - "3rd party" code & generic utilities
	rails - the Rails application, front-end
	scripts - indexing scripts and code for Solr/Marc
	solr-home - schema for solr and the indexed data
	test - general tests and test data