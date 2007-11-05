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

MARCEXT library - extends the MARC library by providing useful mixins
Requires: MARC Gem & Linguistics Gem
Authors:
	Matt Mitchell - mwm4n@virginia.edu
	Bess Sadler - eos8d@virginia.edu

Example:
require 'marc_ext'
require 'marc_ext/record'
class MARC::Record
	include MARCEXT::Record
end