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

module MARCEXT::Record::FormatType
  
  def is_book?
    format_code =~ /^[at]+$/i
  end
  
  def is_computer_file?
    format_code == 'm'
  end
  
  def is_score?
    format_code =~ /^[cd]+$/i
  end
  
  def is_printed_score?
    format_code == 'c'
  end
  
  def is_manusript_score?
    format_code == 'd'
  end
  
  def is_recording?
    (format_code =~ /^[ji]+$/i) or is_video_recording?
  end

  def is_sound_recording?
    format_code =~ /^[ji]+$/i
  end
  
  ## format_code ==g only means that something is projected media, NOT that it is 
  ## necessarily a videorecording. 
  def is_projected_media?
    format_code == 'g'
  end

  ## This is the only way you can know if something is a videorecording
  def is_video_recording?
    (self.extract('245h')).include? "videorecording"
  end

  def is_musical_recording?
    format_code == 'j'
  end

  def is_non_musical_recording?
    format_code == 'i'
  end
  
end