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


class Flare::Context::Filter
  
  attr_reader :value, :negate
  
  def initialize(value, negate=false)
    @value = value
    @negate = !! negate
  end
  
  def negate!(string)
    @negate ? "-#{string}" : string
  end
  
  def to_query
    negate!("(#{@value})")
  end
  
  def to_s
    "
    value: #{@value}
    negate: #{@negate}
    query: #{to_query}
    "
  end
  
end