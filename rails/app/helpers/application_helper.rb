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

module ApplicationHelper
  
  def truncate_words(text, limit=10, ending='...')
    words = text.split(/ /)
    if words.length > limit
      return words[0,limit].join(' ') + ending
    end
    return text
  end
  
  def sub_description
    # This text will appear in the main application layout...
    # Override/customize this method in the individual helpers
  end
  
end