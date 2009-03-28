= yahoo-music

A Ruby wrapper for the Yahoo! Music APIs.

== Example Usage

=== Artists:

  require 'yahoo-music'
  include Yahoo::Music
  Yahoo::Music.app_id = [Your App ID Here]
  
  artist = Artist.new("Ben Folds Five")
  
  puts artist.name
  puts artist.website
  
  puts '*' * 40
  puts
  
  puts 'Releases'
  artist.releases.each do |release|
    puts "\t- %s" % release.title
  end
  
=== Releases & Tracks:
  
  require 'yahoo-music'
  include Yahoo::Music
  Yahoo::Music.app_id = [Your App ID Here]
  
  album = Album.search("The White Album").first 
  
  puts album.title
  puts album.artist
  puts "Release Date:" + album.released_on.strftime("%m/%d/%Y")
  
  puts '*' * 40
  puts
  
  puts 'Tracks'
  artist.tracks.each_with_index do |track, i|
    puts "\t%d %s \t%2d:%2d" % [i, track.title, track.duration / 60, track.duration % 60]
  end


== REQUIREMENTS:

To use this library, you must have a valid Yahoo! App ID. 
You can get one at http://developer.yahoo.com/wsregapp/

Additionally, yahoo-music has the following gem dependencies:

* Hpricot >= 0.6
* ActiveSupport >= 2.1.0
* FlexMock >= 0.8.2

== INSTALL:

* sudo gem install yahoo-music

== LICENSE:

(The MIT License)

Copyright (c) 2008 Mattt Thompson

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.