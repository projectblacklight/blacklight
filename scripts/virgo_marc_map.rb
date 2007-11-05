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


#
# The mapping (acts as the schema) is passed to an instance of MarcMapper (below)
# How the value types of the mapping are used:
#
# String: the string is used as is
# Proc: The Proc is called (passed a MARC::Record instance) and returns a string
# Symbol: The MarcMapper.field_data(MARC::Record r, String field) method is called
# Enumerable/Array: Each item is treated as a key=>field and mapped again for each item
#

load 'helpers.rb'

VIRGO_MARC_MAP = {
  
  # TODO: Extract sort fields: author, title, date (first value of each): _sort and _sort_i
  # TODO: hardcode field names without suffixes into schema
  
  :source_facet => "Library Catalog",
  :author_text => [:'100a', :'110a', :'111a', :'130a'],
  :published_text => :'260a',
  :material_type_text => :'300a',
  :notes_text => [:'500a', :'505a'],
  :uniform_title_text => :'240a',
  :marc_text => Proc.new {|r| r.to_s },
  :subject_era_facet => [:'650d', :'650y', :'651y', :'655y'],
  :topic_form_genre_facet => [:'650a', :'650b', :'650x', :'655a'],
  
  #:subject_topic_facet => [:'650a', :'650b', :'650x'],
  #:subject_genre_facet => [:'600v', :'610v', :'611v', :'650v', :'651v', :'655a'],
  :subject_geographic_facet => [:'650c', :'650z', :'651a', :'651x', :'651z', :'655z'],
  
  # The Control Number field (001)
  :id => Proc.new do |r|    # TODO: namespace the id, something like "catalog:u1"
    # There are multiple '001' items, only use the one that starts with 'u'
    r.extract('001').find {|f| f =~ /^u|^fake/}
  end,
  
  :marc_display => Proc.new do |r|
    r.to_marc
  end,
  
  # These 2 fields should be weighted heavier during querying
  # Title Statement/Title Proper
  #:title_text => :'245a',
  :title_text => Proc.new do |r|
    title = r.extract('245a').to_s
    subtitle = r.extract('245b').to_s.strip
    fulltitle = ''
    if subtitle.length > 0 ## if we have a subtitle, append it to the title nicely 
      #if(fulltitle =~ /[:/,]$/  )
      fulltitle = title + " " + subtitle.chomp('/')
    else
      fulltitle = title.strip.chomp("/")
    end
    fulltitle
  end,
  
  # index year, but no facet
  #:year_facet => Proc.new do |r|  # TODO: pull from 008 instead
  #  r.extract('260c').collect {|f| f.scan(/\d\d\d\d/)}.flatten
  #end,
  
  :year_multisort_i => Proc.new do |r|  # TODO: pull from 008 instead
    r.extract('260c').collect {|f| f.scan(/\d\d\d\d/)}.flatten
  end,
  
  :call_number_facet => Proc.new do |r|
    r.extract('999a').collect{|callnum| callnum[0..1]}.uniq
  end,
  
  # TODO - Don't display LOST, LOSTCLOSED etc. in location facet
  
 :location_facet => Proc.new do |r|
    labels = {
      'Alderman Stacks' => %W(ALD-STKS),
      'Brown Science and Engineering Library Stacks' => %W(SEL-STKS),
      'Internet' => %W(INTERNET),
      'By Request' => %W(BY-REQUEST),
      'Government Documents' => %W(DOC-US),
      'Ivy Annex' => %W(IVYANNEX),
      'Special Collections' => %W(SC-STKS SC-BARR-ST),
      'Alderman Microform Room' => %W(AL-MICFORM),
      'Clemons Stacks' => %W(CLEM-STKS),
      'Law Library Stacks' => %W(LAW-STKS),
      'Law Library Documents' => %W(LAW2-DOCS),
      'Fine Arts Library Stacks' => %W(FA-STKS),
      'Fine Arts Library Oversized Books' => %W(FA-OVERSIZE),
      'Music Library Stacks' => %W(MU-STKS),
      'Darden Library Stacks' => %W(DARD-STKS),
      'Education Library Stacks' => %W(EDUC-STKS),
      'Law Library Third Floor' => %W(LAW-FLOOR3)
      #'' => %W(CHECKEDOUT LOST LOSTCLOSED WITHDRAWN)
    }
    values_to_labels((r.extract('999k') + r.extract('999l')).uniq, labels)
  end,
  
  ############################################
  
  :library_facet => Proc.new do |r|
    labels = {
      'Alderman' => 'ALDERMAN',
      'Clemons' => 'CLEMONS',
      'Ivy Annex' => 'IVY',
      'Fine Arts' => 'FINE-ARTS',
      'Robertson Media Center' => 'MEDIA-CTR',
      'Astronomy' => 'ASTRONOMY',
      'Music' => 'MUSIC',
      'Brown SEL' => 'SCI-ENG',
      'Special Collections' => 'SPEC-COLL',
      'Darden Business School' => 'DARDEN',
      'Health Sciences' => 'HEALTHSCI',
      'Semester At Sea' => 'ATSEA',
      'Math' => 'MATH',
      'Chemistry' => 'CHEMISTRY'
    }
    values_to_labels(r.extract('999m'), labels)
  end,
  
  ############################################
  
  #:format_facet => :'999t',
  :format_facet => Proc.new do |r|
    labels = {
        'Archives' => %W(ARCHIVES),
        'Audio CD' => %W(MUSIC-CD RSRV-CD AUDIO-CD),
        'Book' => %W(BOOK IVY-BOOK RAREBOOK BOOK-NC BOOK-30DAY RSRV-BOOK BOOK-1DAY RSRV-BK-NC ILL-BOOK REFERENCE RSRV-BK-2H JUV-BOOK TIBET-BOOK OFFICECOPY RSRV-BK-4 RSRV-BK-24 BOOK-21DAY RSRV-BK-2D RSRV-BK-7D RSRV-PRS2D),
        'Digital Media' => %W(COMPUTFILE DISKETTE DISKETT-NC RSRV-DISK),
        'Cassette' => %W(AUDIO-CASS MUSIC-CASS RSRV-CASS RSRV-AUD RSRV-CAS2D),
        'CD-ROM' => %W(CD-ROM CD-ROM-NC CD-ROM-4HR RSRV-CDROM CDROM-JRNL),
        'Document' => %W(DOCUMENT MANUSCRIPT DOC-NC RSRV-PHOCO BROADSIDE POSTER REPORT RSRV-PHCOP PAMPHLET RSRV-PHO4H PRINTS),
        'DVD' => %W(DVD HS-VDVD HS-VDVD3 RSRV-VDVD ),
        'Equipment' => %W(HS-DVDPLYR EQUIP-3DAY CELLPHONE CALCULATOR LCDPANEL HSLAPTOP PROJSYSTEM HSWIRELESS EQUIP-2HR DIGITALCAM AUDIO-VIS LAPTOP EQUIP-3HR CAMCORDER AV-7DAY EQUIPMENT),
        'Internet' => %W(INTERNET E-JRNL E-BOOK E-DATABASE WEBSITE E-NEWSLET HS-EGUIDE E-EXHIBIT),
        'Journal' => %W(BOUND-JRNL IVY-JRNL BD-JRNL-NC CUR-PER JRNL1WK JRNL2WK JRNL4HR RAREJRNL E-JRNL CUR-PER-NC VIDEOJRNL HS-JRLNC AUDIOJRNL CDROM-JRNL),
        'LP' => %W(LP IVY-LP MUSIC-LP),
        'Map' => %W(MAP MAP-NC),
        'Microform' => %W(MICROFICHE IVY-MFICHE MICROFILM MICROCARD IVY-MFILM IVY-MCARD),
        'Music' => %W(MUSIC),
        'Musical Score' => %W(MUSI-SCORE IVY-SCORE MUSCORE-NC),
        'Newspaper' => %W(NEWSPAPER IVY-NEWS),
        'Open Reel Tape' => %W(OPENREEL),
        'Room' => %W(MEETING-RM CLASSROOM CARREL),
        'Slide' => %W(SLIDE ),
        'Thesis' => %W(THESIS THESIS-DIS THESIS-4TH IVY-THESIS),
        'Unknown' => %W(UNKNOWN RSRV-PERS ANALYTIC),
        'VHS' => %W(VIDEO-CASS RSRV-VCASS),
        'Video Disc' => %W(VIDEO-DISC RSRV-VDISC)
      }
      values_to_labels(r.extract('999t'), labels)
    end,
  
    ############################################

    ## broad formats facet
    ## Mary and Erin have asked for a facet listing much broader 
    ## categories of format, specifically:
    ## book, musical score, sound recording, spoken word recording,
    ## video, or microform

    :broad_formats_facet => Proc.new do |r|
      if r.is_score?
        "Musical Score"
      elsif r.is_book?
        "Book"
      elsif r.is_musical_recording?
        "Musical Recording"
      elsif r.is_non_musical_recording?
        "Non-musical Recording"
      elsif r.is_video_recording?
        "Video"
      elsif r.is_computer_file?
        "Computer file"
      end
    end,
  
  ############################################
  
  ## recordings and scores facet
  ## If an item is a score or a recording, it should get a "Recordings or Scores" label
  ## in addition to its "recording" or "score" label 
  ## This is so you can limit your search to recordings, to scores, or to anything
  ## that is either a recording or a score
  
  :recordings_and_scores_facet => Proc.new do |r|
    if r.is_score?
      ["Scores","Recordings and/or Scores"]
    elsif r.is_recording?
      ["Recordings","Recordings and/or Scores"]
    end
  end, 
  
  ############################################
  ## instruments facet 
  ## CAUTION : These labels are backwards from the way
  ## most the other ones are formatted.
  ## The values_to_labels handles this with a single Boolean argument
  
  :instrument_facet => Proc.new do |r|
    
    labels = {
    "vu"=>"Voices, Unknown",
    "vb"=>"Mezzo soprano voice",
    "cb"=>"Chorus, Women's",
    "ec"=>"Computer",
    "eu"=>"Electronic, Unknown",
    "kf"=>"Celeste",
    "ta"=>"Harp",
    "oz"=>"Larger ensemble, Other",
    "vc"=>"Alto voice",
    "ed"=>"Ondes Martinot",
    "cu"=>"Chorus, Unknown",
    "ky"=>"Keyboard, Ethnic",
    "tb"=>"Guitar",
    "wn"=>"Woodwinds, Unspecified",
    "vd"=>"Tenor voice",
    "tu"=>"Plucked Strings, Unknown",
    "pa"=>"Timpani",
    "kz"=>"Keyboard, Other",
    "tc"=>"Lute",
    "cc"=>"Choruses, Men's",
    "ve"=>"Baritone voice",
    "td"=>"Mandolin",
    "pb"=>"Xylophone",
    "cd"=>"Choruses, Children's",
    "vf"=>"Bass voice",
    "pc"=>"Marimba",
    "pu"=>"Percussion, Unknown",
    "sn"=>"Bowed Strings, Unspecified",
    "bn"=>"Brass, Unspecified",
    "vy"=>"Voices, Ethnic",
    "vg"=>"Counter tenor voice",
    "ez"=>"Electronic, Other",
    "pd"=>"Drum",
    "cy"=>"Choruses, Ethnic",
    "vh"=>"High voice",
    "ty"=>"Plucked Strings, Ethnic",
    "on"=>"Larger ensemble, Unspecified",
    "vi"=>"Medium voice",
    "tz"=>"Plucked Strings, Other",
    "wa"=>"Flute",
    "vj"=>"Low voice",
    "py"=>"Percussion, Ethnic",
    "wu"=>"Woodwinds, Unknown",
    "wb"=>"Oboe",
    "pz"=>"Percussion, Other",
    "ba"=>"Horn",
    "kn"=>"Keyboard, Unspecified",
    "zn"=>"Unspecified instruments",
    "wc"=>"Clarinet",
    "sa"=>"Violin",
    "wd"=>"Bassoon",
    "bu"=>"Brass, Unknown",
    "sb"=>"Viola",
    "bb"=>"Trumpet",
    "we"=>"Piccolo",
    "vn"=>"Voices, Unspecified",
    "en"=>"Electronic, Unspecified",
    "oa"=>"Full orchestra",
    "sc"=>"Violoncello",
    "su"=>"Bowed Strings, Unknown",
    "bc"=>"Cornet",
    "wf"=>"English horn",
    "tn"=>"Plucked Strings, Unspecified",
    "ob"=>"Chamber orchestra",
    "sd"=>"Double bass",
    "bd"=>"Trombone",
    "cn"=>"Choruses, Unspecified",
    "wy"=>"Woodwinds, Ethnic",
    "wg"=>"Bass clarinet",
    "oc"=>"String orchestra",
    "se"=>"Viol",
    "ou"=>"Larger ensemble, Unknown",
    "be"=>"Tuba",
    "ka"=>"Piano",
    "wz"=>"Woodwinds, Other",
    "wh"=>"Recorder",
    "od"=>"Band",
    "pn"=>"Percussion, Unspecified",
    "sf"=>"Viola d'amore",
    "bf"=>"Baritone horn",
    "by"=>"Brass, Ethnic",
    "kb"=>"Organ",
    "wi"=>"Saxophone",
    "ku"=>"Keyboard, Unknown",
    "sg"=>"Viola da gamba",
    "sy"=>"Bowed Strings, Ethnic",
    "bz"=>"Brass, Other",
    "kc"=>"Harpsichord",
    "oe"=>"Dance orchestra",
    "zu"=>"Unknown",
    "sz"=>"Bowed Strings, Other",
    "ea"=>"Synthesizer",
    "kd"=>"Clavichord",
    "of"=>"Brass band",
    "va"=>"Soprano voice",
    "oy"=>"Larger ensemble, Ethnic",
    "ca"=>"Choruses, Mixed",
    "eb"=>"Electronic Tape",
    "ke"=>"Continuo"
    }
    values_to_labels(r.extract('048a').collect{|f| f[0..1]}.uniq, labels, true, true)
  end,
  
  :recording_format_facet => Proc.new do |r|
    labels = {
      'CD' => %W(MUSIC-CD RSRV-CD AUDIO-CD),
      'Cassette' => %W(AUDIO-CASS MUSIC-CASS RSRV-CASS RSRV-AUD RSRV-CAS2D),
      'LP' => %W(LP IVY-LP MUSIC-LP),
      'Open Reel Tape' => %W(OPENREEL),
      'DVD' => %W(DVD HS-VDVD HS-VDVD3 RSRV-VDVD),
      'VHS' => %W(VIDEO-CASS RSRV-VCASS),
      'Video Disc' => %W(VIDEO-DISC RSRV-VDISC)
    }
    if r.is_recording?
      values_to_labels(r.extract('999t'), labels, false)
    end
  end,
  
  :recording_type_facet => Proc.new do |r|
    if r.is_musical_recording?
      'Musical'
    elsif r.is_non_musical_recording?
      'Non-Musical'
    end
  end,
  
  :music_category_facet => Proc.new do |r|
    call = r.extract('999a').find do |v|
      v =~ /^m[lt23\s]+/i
    end
    value = call.to_s[0..1]
    labels = {
      'Printed Music'=>'M',
      'Music Literature'=>'ML',
      'Music Theory'=>'MT',
      'Monuments of Music'=>'M2',
      'Composers\' Collected Works'=>'M3'
    }
    values_to_labels(value, labels, false)
  end,
  
  :language_facet => Proc.new do |r|
    labels =  {
      "sus"=>"Susu",
      "hmn"=>"Hmong",
      "ina"=>"Interlingua (International Auxiliary Language Association)",
      "ara"=>"Arabic",
      "bul"=>"Bulgarian",
      "lat"=>"Latin",
      "hmo"=>"Hiri Motu",
      "mla"=>"Malagasy",
      "lui"=>"Luiseno",
      "kmb"=>"Kimbundu",
      "inc"=>"Indic (Other)",
      "arc"=>"Aramaic",
      "awa"=>"Awadhi",
      "efi"=>"Efik",
      "ind"=>"Indonesian",
      "non"=>"Old Norse",
      "lav"=>"Latvian",
      "sid"=>"Sidamo",
      "fiu"=>"Finno-Ugrian (Other)",
      "sna"=>"Shona",
      "amh"=>"Amharic",
      "umb"=>"Umbundu",
      "sux"=>"Sumerian",
      "ine"=>"Indo-European (Other)",
      "lun"=>"Lunda",
      "arg"=>"Aragonese Spanish",
      "khi"=>"Khoisan (Other)",
      "iii"=>"Sichuan Yi",
      "bur"=>"Burmese",
      "tvl"=>"Tuvaluan",
      "ssa"=>"Nilo-Saharan (Other)",
      "gem"=>"Germanic (Other)",
      "mlg"=>"Malagasy",
      "luo"=>"Luo (Kenya and Tanzania)",
      "new"=>"Newari",
      "nor"=>"Norwegian",
      "snd"=>"Sindhi",
      "inh"=>"Ingush",
      "goh"=>"German, Old High (ca. 750-1050)",
      "nym"=>"Nyamwezi",
      "ido"=>"Ido",
      "geo"=>"Georgian",
      "nyn"=>"Nyankole",
      "urd"=>"Urdu",
      "khm"=>"Khmer",
      "nyo"=>"Nyoro",
      "lus"=>"Lushai",
      "snh"=>"Sinhalese",
      "ger"=>"German",
      "arm"=>"Armenian",
      "kho"=>"Khotanese",
      "yao"=>"Yao (Africa)",
      "arn"=>"Mapuche",
      "dyu"=>"Dyula",
      "yap"=>"Yapese",
      "sin"=>"Sinhalese",
      "gon"=>"Gondi",
      "dra"=>"Dravidian (Other)",
      "hai"=>"Haida",
      "snk"=>"Soninke",
      "sio"=>"Siouan (Other)",
      "epo"=>"Esperanto",
      "arp"=>"Arapaho",
      "bih"=>"Bihari",
      "ypk"=>"Yupik languages",
      "wln"=>"Walloon",
      "gor"=>"Gorontalo",
      "kro"=>"Kru",
      "raj"=>"Rajasthani",
      "vie"=>"Vietnamese",
      "bik"=>"Bikol",
      "afa"=>"Afroasiatic (Other)",
      "mlt"=>"Maltese",
      "int"=>"Interlingua (International Auxiliary Language Association)",
      "got"=>"Gothic",
      "art"=>"Artificial (Other)",
      "kaa"=>"Kara-Kalpak",
      "iba"=>"Iban",
      "gez"=>"Ethiopic",
      "sit"=>"Sino-Tibetan (Other)",
      "sso"=>"Sotho",
      "kab"=>"Kabyle",
      "ceb"=>"Cebuano",
      "bin"=>"Edo",
      "aka"=>"Akan",
      "kac"=>"Kachin",
      "tel"=>"Telugu",
      "pli"=>"Pali",
      "arw"=>"Arawak",
      "tog"=>"Tonga (Nyasa)",
      "tem"=>"Temne",
      "lim"=>"Limburgish",
      "kru"=>"Kurukh",
      "hat"=>"Haitian French Creole",
      "lin"=>"Lingala",
      "rap"=>"Rapanui",
      "apa"=>"Apache languages",
      "hau"=>"Hausa",
      "sga"=>"Irish, Old (to 1100)",
      "bis"=>"Bislama",
      "afh"=>"Afrihili (Artificial language)",
      "rar"=>"Rarotongan",
      "haw"=>"Hawaiian",
      "xho"=>"Xhosa",
      "ssw"=>"Swazi",
      "sla"=>"Slavic (Other)",
      "grb"=>"Grebo",
      "ter"=>"Terena",
      "grc"=>"Greek, Ancient (to 1453)",
      "ile"=>"Interlingue",
      "ton"=>"Tongan",
      "kal"=>"Kalatdlisut",
      "lit"=>"Lithuanian",
      "cel"=>"Celtic (Other)",
      "bnt"=>"Bantu (Other)",
      "eng"=>"English",
      "hun"=>"Hungarian",
      "osa"=>"Osage",
      "kua"=>"Kuanyama",
      "yid"=>"Yiddish",
      "tet"=>"Tetum",
      "gre"=>"Greek, Modern (1453- )",
      "kam"=>"Kamba",
      "akk"=>"Akkadian",
      "rum"=>"Romanian",
      "kpe"=>"Kpelle",
      "kan"=>"Kannada",
      "gmh"=>"German, Middle High (ca. 1050-1500)",
      "hup"=>"Hupa",
      "run"=>"Rundi",
      "ibo"=>"Igbo",
      "aar"=>"Afar",
      "aze"=>"Azerbaijani",
      "moh"=>"Mohawk",
      "bla"=>"Siksika",
      "men"=>"Mende",
      "wel"=>"Welsh",
      "kar"=>"Karen",
      "afr"=>"Afrikaans",
      "uzb"=>"Uzbek",
      "esk"=>"Eskimo languages",
      "kas"=>"Kashmiri",
      "enm"=>"English, Middle (1100-1500)",
      "rus"=>"Russian",
      "sgn"=>"Sign languages",
      "gwi"=>"Gwich'in",
      "wen"=>"Sorbian languages",
      "tha"=>"Thai",
      "mol"=>"Moldavian",
      "kau"=>"Kanuri",
      "ilo"=>"Iloko",
      "nah"=>"Nahuatl",
      "cop"=>"Coptic",
      "dak"=>"Dakota",
      "mon"=>"Mongolian",
      "grn"=>"Guarani",
      "dua"=>"Duala",
      "nai"=>"North American Indian (Other)",
      "wol"=>"Wolof",
      "kaw"=>"Kawi",
      "jrb"=>"Judeo-Arabic",
      "cor"=>"Cornish",
      "slo"=>"Slovak",
      "ada"=>"Adangme",
      "esp"=>"Esperanto",
      "cos"=>"Corsican",
      "kum"=>"Kumyk",
      "dan"=>"Danish",
      "tyv"=>"Tuvinian",
      "gaa"=>"Ga",
      "ukr"=>"Ukrainian",
      "aus"=>"Australian languages",
      "kaz"=>"Kazakh",
      "nub"=>"Nubian languages",
      "cha"=>"Chamorro",
      "mos"=>"Moore",
      "est"=>"Estonian",
      "myn"=>"Mayan languages",
      "chb"=>"Chibcha",
      "dar"=>"Dargwa",
      "hil"=>"Hiligaynon",
      "xal"=>"Kalmyk",
      "nap"=>"Neapolitan Italian",
      "kur"=>"Kurdish",
      "gae"=>"Scottish Gaelic",
      "him"=>"Himachali",
      "tmh"=>"Tamashek",
      "oss"=>"Ossetic",
      "kus"=>"Kusaie",
      "slv"=>"Slovenian",
      "hin"=>"Hindi",
      "kut"=>"Kutenai",
      "peo"=>"Old Persian (ca. 600-400 B.C.)",
      "gag"=>"Galician",
      "cmc"=>"Chamic languages",
      "che"=>"Chechen",
      "fon"=>"Fon",
      "zen"=>"Zenaga",
      "pol"=>"Polish",
      "dum"=>"Dutch, Middle (ca. 1050-1350)",
      "chg"=>"Chagatai",
      "per"=>"Persian",
      "nau"=>"Nauru",
      "day"=>"Dayak",
      "ang"=>"English, Old (ca. 450-1100)",
      "nav"=>"Navajo",
      "nzi"=>"Nzima",
      "ita"=>"Italian",
      "gua"=>"Guarani",
      "chi"=>"Chinese",
      "gal"=>"Oromo",
      "hit"=>"Hittite",
      "pon"=>"Ponape",
      "twi"=>"Twi",
      "cre"=>"Cree",
      "chk"=>"Truk",
      "dzo"=>"Dzongkha",
      "und"=>"Undetermined",
      "uig"=>"Uighur",
      "chm"=>"Mari",
      "crh"=>"Crimean Tatar",
      "por"=>"Portuguese",
      "chn"=>"Chinook jargon",
      "kik"=>"Kikuyu",
      "dut"=>"Dutch",
      "cho"=>"Choctaw",
      "sel"=>"Selkup",
      "udm"=>"Udmurt",
      "sog"=>"Sogdian",
      "chp"=>"Chipewyan",
      "sem"=>"Semitic (Other)",
      "que"=>"Quechua",
      "kin"=>"Kinyarwanda",
      "nia"=>"Nias",
      "guj"=>"Gujarati",
      "chr"=>"Cherokee",
      "asm"=>"Assamese",
      "ijo"=>"Ijo",
      "tru"=>"Truk",
      "nde"=>"Ndebele (Zimbabwe)",
      "nic"=>"Niger-Kordofanian (Other)",
      "zha"=>"Zhuang",
      "tag"=>"Tagalog",
      "chu"=>"Church Slavic",
      "kir"=>"Kyrgyz",
      "bej"=>"Beja",
      "tah"=>"Tahitian",
      "chv"=>"Chuvash",
      "crp"=>"Creoles and Pidgins (Other)",
      "gay"=>"Gayo",
      "ady"=>"Adygei",
      "som"=>"Somali",
      "tai"=>"Tai (Other)",
      "pra"=>"Prakrit languages",
      "bel"=>"Belarusian",
      "son"=>"Songhai",
      "taj"=>"Tajik",
      "fre"=>"French",
      "bem"=>"Bemba",
      "egy"=>"Egyptian",
      "chy"=>"Cheyenne",
      "ben"=>"Bengali",
      "cad"=>"Caddo",
      "ast"=>"Bable",
      "phi"=>"Philippine (Other)",
      "elx"=>"Elamite",
      "tam"=>"Tamil",
      "din"=>"Dinka",
      "fri"=>"Frisian",
      "mac"=>"Macedonian",
      "ndo"=>"Ndonga",
      "alb"=>"Albanian",
      "ber"=>"Berber (Other)",
      "mad"=>"Madurese",
      "sot"=>"Sotho",
      "kbd"=>"Kabardian",
      "mwr"=>"Marwari",
      "btk"=>"Batak",
      "ice"=>"Icelandic",
      "ven"=>"Venda",
      "scc"=>"Serbian",
      "cai"=>"Central American Indian (Other)",
      "phn"=>"Phoenician",
      "uga"=>"Ugaritic",
      "tpi"=>"Tok Pisin",
      "tkl"=>"Tokelauan",
      "lol"=>"Mongo-Nkundu",
      "ale"=>"Aleut",
      "mag"=>"Magahi",
      "tar"=>"Tatar",
      "syr"=>"Syriac",
      "nds"=>"Low German",
      "abk"=>"Abkhaz",
      "frm"=>"French, Middle (ca. 1400-1600)",
      "jav"=>"Javanese",
      "mah"=>"Marshallese",
      "jpn"=>"Japanese",
      "alg"=>"Algonquian (Other)",
      "ira"=>"Iranian (Other)",
      "mai"=>"Maithili",
      "ava"=>"Avaric",
      "vol"=>"Volapuk",
      "tat"=>"Tatar",
      "cpe"=>"Creoles and Pidgins, English-based (Other)",
      "cam"=>"Khmer",
      "nno"=>"Norwegian (Nynorsk)",
      "sma"=>"Southern Sami",
      "fro"=>"French, Old (ca. 842-1400)",
      "cpf"=>"Creoles and Pidgins, French-based (Other)",
      "div"=>"Divehi",
      "mak"=>"Makasar",
      "bos"=>"Bosnian",
      "tuk"=>"Turkmen",
      "ota"=>"Turkish, Ottoman",
      "mal"=>"Malayalam",
      "jpr"=>"Judeo-Persian",
      "ave"=>"Avestan",
      "niu"=>"Niuean",
      "pro"=>"Provencal (to 1500)",
      "nso"=>"Northern Sotho",
      "tum"=>"Tumbuka",
      "sme"=>"Northern Sami",
      "man"=>"Mandingo",
      "mkh"=>"Mon-Khmer (Other)",
      "wak"=>"Wakashan languages",
      "swa"=>"Swahili",
      "car"=>"Carib",
      "gil"=>"Gilbertese",
      "mao"=>"Maori",
      "paa"=>"Papuan (Other)",
      "oji"=>"Ojibwa",
      "wal"=>"Walamo",
      "srd"=>"Sardinian",
      "lez"=>"Lezgian",
      "cze"=>"Czech",
      "eth"=>"Ethiopic",
      "map"=>"Austronesian (Other)",
      "heb"=>"Hebrew",
      "tup"=>"Tupi languages",
      "cat"=>"Catalan",
      "vot"=>"Votic",
      "sco"=>"Scots",
      "cau"=>"Caucasian (Other)",
      "smi"=>"Sami",
      "iri"=>"Irish",
      "mar"=>"Marathi",
      "tur"=>"Turkish",
      "smj"=>"Lule Sami",
      "mas"=>"Masai",
      "swe"=>"Swedish",
      "bra"=>"Braj",
      "fry"=>"Frisian",
      "shn"=>"Shan",
      "tut"=>"Altaic (Other)",
      "loz"=>"Lozi",
      "pag"=>"Pangasinan",
      "sho"=>"Shona",
      "war"=>"Waray",
      "tib"=>"Tibetan",
      "scr"=>"Croatian",
      "cpp"=>"Creoles and Pidgins, Portuguese-based (Other)",
      "was"=>"Washo",
      "smn"=>"Inari Sami",
      "bre"=>"Breton",
      "smo"=>"Samoan",
      "iro"=>"Iroquoian (Other)",
      "roa"=>"Romance (Other)",
      "ltz"=>"Letzeburgesch",
      "mul"=>"Multiple languages",
      "fan"=>"Fang",
      "max"=>"Manx",
      "fao"=>"Faroese",
      "gba"=>"Gbaya",
      "may"=>"Malay",
      "pal"=>"Pahlavi",
      "nbl"=>"Ndebele (South Africa)",
      "mun"=>"Munda (Other)",
      "tig"=>"Tigre",
      "pam"=>"Pampanga",
      "oto"=>"Otomian languages",
      "sms"=>"Skolt Sami",
      "cus"=>"Cushitic (Other)",
      "pan"=>"Panjabi",
      "far"=>"Faroese",
      "bho"=>"Bhojpuri",
      "yor"=>"Yoruba",
      "srr"=>"Serer",
      "pap"=>"Papiamento",
      "fat"=>"Fanti",
      "roh"=>"Raeto-Romance",
      "gla"=>"Scottish Gaelic",
      "mus"=>"Creek",
      "her"=>"Herero",
      "sad"=>"Sandawe",
      "dgr"=>"Dogrib",
      "zap"=>"Zapotec",
      "mic"=>"Micmac",
      "ful"=>"Fula",
      "tsi"=>"Tsimshian",
      "sag"=>"Sango (Ubangi Creole)",
      "rom"=>"Romani",
      "gle"=>"Irish",
      "pau"=>"Palauan",
      "sah"=>"Yakut",
      "sai"=>"South American Indian (Other)",
      "oci"=>"Occitan (post-1500)",
      "mnc"=>"Manchu",
      "tir"=>"Tigrinya",
      "glg"=>"Galician",
      "spa"=>"Spanish",
      "tsn"=>"Tswana",
      "sal"=>"Salishan languages",
      "bad"=>"Banda",
      "zul"=>"Zulu",
      "tso"=>"Tsonga",
      "swz"=>"Swazi",
      "ath"=>"Athapascan (Other)",
      "fur"=>"Friulian",
      "sam"=>"Samaritan Aramaic",
      "ewe"=>"Ewe",
      "ajm"=>"Aljamia",
      "zun"=>"Zuni",
      "tiv"=>"Tiv",
      "lad"=>"Ladino",
      "san"=>"Sanskrit",
      "mni"=>"Manipuri",
      "sao"=>"Samoan",
      "min"=>"Minangkabau",
      "bai"=>"Bamileke languages",
      "pus"=>"Pushto",
      "kok"=>"Konkani",
      "ipk"=>"Inupiaq",
      "ori"=>"Oriya",
      "mdr"=>"Mandar",
      "lah"=>"Lahnda",
      "bak"=>"Bashkir",
      "kom"=>"Komi",
      "bua"=>"Buriat",
      "sas"=>"Sasak",
      "bal"=>"Baluchi",
      "kon"=>"Kongo",
      "tsw"=>"Tswana",
      "sat"=>"Santali",
      "aym"=>"Aymara",
      "bam"=>"Bambara",
      "mno"=>"Manobo languages",
      "mis"=>"Miscellaneous languages",
      "orm"=>"Oromo",
      "ban"=>"Balinese",
      "nob"=>"Norwegian (Bokmal)",
      "vai"=>"Vai",
      "suk"=>"Sukuma",
      "del"=>"Delaware",
      "ewo"=>"Ewondo",
      "lua"=>"Luba-Lulua",
      "lam"=>"Lamba",
      "iku"=>"Inuktitut",
      "lub"=>"Luba-Katanga",
      "kor"=>"Korean",
      "fij"=>"Fijian",
      "lan"=>"Occitan (post-1500)",
      "den"=>"Slave",
      "glv"=>"Manx",
      "doi"=>"Dogri",
      "baq"=>"Basque",
      "kos"=>"Kusaie",
      "sun"=>"Sundanese",
      "lao"=>"Lao",
      "nya"=>"Nyanja",
      "bug"=>"Bugis",
      "znd"=>"Zande",
      "bas"=>"Basa",
      "ace"=>"Achinese",
      "nog"=>"Nogai",
      "lap"=>"Sami",
      "tgk"=>"Tajik",
      "bat"=>"Baltic (Other)",
      "fin"=>"Finnish",
      "eka"=>"Ekajuk",
      "tli"=>"Tlingit",
      "tgl"=>"Tagalog",
      "lug"=>"Ganda",
      "mga"=>"Irish, Middle (ca. 1100-1550)",
      "kha"=>"Khasi",
      "nep"=>"Nepali",
      "ach"=>"Acoli",
      "zxx"=>"No linguistic content"
    }
    languages = (r.extract('008') + r.extract('041a') + r.extract('041d'))
    languages = languages.uniq.collect{|f| f[35..37]}.compact
    languages.delete 'zxx'
    languages.delete '???'
    values_to_labels(languages, labels, true, true)
  end,
  
  :composition_era_facet => Proc.new do |r|
    eras = r.unique_045_eras
  #  #puts eras.inspect
    eras.empty? ? nil : eras
  end
}