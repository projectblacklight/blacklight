# frozen_string_literal: true

RSpec.describe Blacklight::Solr::Response, :api do
  let(:raw_response) { eval(mock_query_response) }

  let(:config) { Blacklight::Configuration.new }

  let(:r) do
    described_class.new(raw_response,
                        raw_response['params'],
                        blacklight_config: config)
  end

  it 'creates a valid response' do
    expect(r).to respond_to(:header)
  end

  it 'has accurate pagination numbers' do
    expect(r.rows).to eq 11
    expect(r.total).to eq 26
    expect(r.start).to eq 0
  end

  it 'creates a valid response class' do
    expect(r).to respond_to(:response)
    expect(r.docs).to have(11).docs
    expect(r.params[:echoParams]).to eq 'EXPLICIT'

    expect(r).to be_a(Blacklight::Solr::Response::Facets)
  end

  it 'provides facet helpers' do
    expect(r.aggregations.size).to eq 2

    field_names = r.aggregations.collect { |_key, facet| facet.name }
    expect(field_names.include?('cat')).to be true
    expect(field_names.include?('manu')).to be true

    first_facet = r.aggregations['cat']
    expect(first_facet.name).to eq 'cat'

    expect(first_facet.items.size).to eq 10

    expected = "electronics - 14, memory - 3, card - 2, connector - 2, drive - 2, graphics - 2, hard - 2, monitor - 2, search - 2, software - 2"
    received = first_facet.items.collect do |item|
      "#{item.value} - #{item.hits}"
    end.join(', ')

    expect(received).to eq expected

    r.aggregations.each_value do |facet|
      expect(facet).to respond_to :name
      expect(facet).to respond_to :sort
      expect(facet).to respond_to :offset
      expect(facet).to respond_to :limit
      facet.items.each do |item|
        expect(item).to respond_to :value
        expect(item).to respond_to :hits
      end
    end
  end

  it 'provides a null-object for facets that are not in the response' do
    expect(r.aggregations).not_to include :some_null_object

    expect(r.aggregations[:some_null_object]).to be_a Blacklight::Solr::Response::FacetField
    expect(r.aggregations[:some_null_object].items).to be_blank
  end

  context 'when aggregations are very large' do
    let(:raw_response) { eval(mock_query_response_with_lots_of_facets) }

    it 'null object generation is relatively performant' do
      expect do
        r.aggregations[:some_null_object]
      end.to perform_at_least(5_000).ips
    end
  end

  it "provides kaminari pagination helpers" do
    expect(r.limit_value).to eq(r.rows)
    expect(r.offset_value).to eq(r.start)
    expect(r.total_count).to eq(r.total)
    expect(r.next_page).to eq(r.current_page + 1)
    expect(r.prev_page).to be_nil
    expect(r.entry_name(count: 1)).to eq 'entry'
    expect(r.entry_name(count: 2)).to eq 'entries'
    expect(r.size).to eq 26
    if Kaminari.config.respond_to? :max_pages
      expect(r.max_pages).to be_nil
    end
    expect(r).to be_a Kaminari::PageScopeMethods
  end

  describe "FacetItem" do
    it "works with a field,value tuple" do
      item = Blacklight::Solr::Response::Facets::FacetItem.new('value', 15)
      expect(item.value).to eq 'value'
      expect(item.hits).to eq 15
    end

    it "works with a field,value + hash triple" do
      item = Blacklight::Solr::Response::Facets::FacetItem.new('value', 15, a: 1, value: 'ignored')
      expect(item.value).to eq 'value'
      expect(item.hits).to eq 15
      expect(item.a).to eq 1
    end

    it "works like an openstruct" do
      item = Blacklight::Solr::Response::Facets::FacetItem.new(value: 'value', hits: 15)

      expect(item.hits).to eq 15
      expect(item.value).to eq 'value'
      expect(item).to be_a(OpenStruct)
    end

    it "provides a label accessor" do
      item = Blacklight::Solr::Response::Facets::FacetItem.new('value', hits: 15)
      expect(item.label).to eq 'value'
    end

    it "uses a provided label" do
      item = Blacklight::Solr::Response::Facets::FacetItem.new('value', 15, label: 'custom label')
      expect(item.label).to eq 'custom label'
    end
  end

  it 'returns the correct value when calling facet_by_field_name' do
    facet = r.aggregations['cat']
    expect(facet.name).to eq 'cat'
  end

  it 'provides the responseHeader params' do
    raw_response = eval(mock_query_response)
    raw_response['responseHeader']['params']['test'] = :test
    r = described_class.new(raw_response, raw_response['params'])
    expect(r.params['test']).to eq :test
  end

  it 'extracts json params' do
    raw_response = eval(mock_query_response)
    raw_response['responseHeader']['params']['test'] = 'from query'
    raw_response['responseHeader']['params'].delete('rows')
    raw_response['responseHeader']['params']['json'] = { limit: 5, params: { test: 'from json params' } }.to_json
    r = described_class.new(raw_response, raw_response['params'])
    expect(r.params['test']).to eq 'from query'
    expect(r.rows).to eq 5
  end

  it 'provides the solr-returned params and "rows" should be 11' do
    raw_response = eval(mock_query_response)
    r = described_class.new(raw_response, {})
    expect(r.params[:rows].to_s).to eq '11'
    expect(r.params[:sort]).to eq 'title_si asc, pub_date_si desc'
  end

  it 'provides the ruby request params if responseHeader["params"] does not exist' do
    raw_response = eval(mock_query_response)
    raw_response.delete 'responseHeader'
    r = described_class.new(raw_response, rows: 999, sort: 'score desc, pub_date_si desc, title_si asc')
    expect(r.params[:rows].to_s).to eq '999'
    expect(r.params[:sort]).to eq 'score desc, pub_date_si desc, title_si asc'
  end

  it 'provides spelling suggestions for regular spellcheck results' do
    raw_response = eval(mock_response_with_spellcheck)
    r = described_class.new(raw_response, {})
    expect(r.spelling.words).to include("dell")
    expect(r.spelling.words).to include("ultrasharp")
  end

  it 'provides spelling suggestions for extended spellcheck results' do
    raw_response = eval(mock_response_with_spellcheck_extended)
    r = described_class.new(raw_response, {})
    expect(r.spelling.words).to include("dell")
    expect(r.spelling.words).to include("ultrasharp")
  end

  it 'provides no spelling suggestions when extended results and suggestion frequency is the same as original query frequency' do
    raw_response = eval(mock_response_with_spellcheck_same_frequency)
    r = described_class.new(raw_response, {})
    expect(r.spelling.words).to eq []
  end

  context "pre solr 5 spellcheck collation syntax" do
    it 'provides spelling suggestions for a regular spellcheck results with a collation' do
      raw_response = eval(mock_response_with_spellcheck_collation)
      r = described_class.new(raw_response, {})
      expect(r.spelling.words).to include("dell")
      expect(r.spelling.words).to include("ultrasharp")
    end

    it 'provides spelling suggestion collation' do
      raw_response = eval(mock_response_with_spellcheck_collation)
      r = described_class.new(raw_response, {})
      expect(r.spelling.collation).to eq 'dell ultrasharp'
    end
  end

  context "solr 5 spellcheck collation syntax" do
    it 'provides spelling suggestions for a regular spellcheck results with a collation' do
      raw_response = eval(mock_response_with_spellcheck_collation_solr5)
      r = described_class.new(raw_response, {})
      expect(r.spelling.words).to include("dell")
      expect(r.spelling.words).to include("ultrasharp")
    end

    it 'provides spelling suggestion collation' do
      raw_response = eval(mock_response_with_spellcheck_collation_solr5)
      r = described_class.new(raw_response, {})
      expect(r.spelling.collation).to eq 'dell ultrasharp'
    end
  end

  context 'solr 6.5 spellcheck collation syntax' do
    it 'provides spelling suggestions for a regular spellcheck results with a collation' do
      raw_response = eval(mock_response_with_spellcheck_collation_solr65)
      r = described_class.new(raw_response, {})
      expect(r.spelling.words).to include("dell")
      expect(r.spelling.words).to include("ultrasharp")
    end
  end

  it "provides MoreLikeThis suggestions" do
    raw_response = eval(mock_response_with_more_like_this)
    r = described_class.new(raw_response, {})
    expect(r.more_like(double(id: '79930185'))).to have(2).items
  end

  it "is empty when the response has no results" do
    r = described_class.new({}, {})
    allow(r).to receive_messages(total: 0)
    expect(r).to be_empty
  end

  describe "#export_formats" do
    it "collects the unique export formats for the current response" do
      r = described_class.new({}, {})
      allow(r).to receive_messages(documents: [double(export_formats: { a: 1, b: 2 }), double(export_formats: { b: 1, c: 2 })])
      expect(r.export_formats).to include :a, :b
    end
  end

  def mock_query_response
    %({'responseHeader'=>{'status'=>0,'QTime'=>5,'params'=>{'facet.limit'=>'10','wt'=>'ruby','rows'=>'11','facet'=>'true','facet.field'=>['cat','manu'],'echoParams'=>'EXPLICIT','q'=>'*:*','facet.sort'=>'true', 'sort'=>'title_si asc, pub_date_si desc'}},'response'=>{'numFound'=>26,'start'=>0,'docs'=>[{'id'=>'SP2514N','inStock'=>true,'manu'=>'Samsung Electronics Co. Ltd.','name'=>'Samsung SpinPoint P120 SP2514N - hard drive - 250 GB - ATA-133','popularity'=>6,'price'=>92.0,'sku'=>'SP2514N','timestamp'=>'2009-03-20T14:42:49.795Z','cat'=>['electronics','hard drive'],'spell'=>['Samsung SpinPoint P120 SP2514N - hard drive - 250 GB - ATA-133'],'features'=>['7200RPM, 8MB cache, IDE Ultra ATA-133','NoiseGuard, SilentSeek technology, Fluid Dynamic Bearing (FDB) motor']},{'id'=>'6H500F0','inStock'=>true,'manu'=>'Maxtor Corp.','name'=>'Maxtor DiamondMax 11 - hard drive - 500 GB - SATA-300','popularity'=>6,'price'=>350.0,'sku'=>'6H500F0','timestamp'=>'2009-03-20T14:42:49.877Z','cat'=>['electronics','hard drive'],'spell'=>['Maxtor DiamondMax 11 - hard drive - 500 GB - SATA-300'],'features'=>['SATA 3.0Gb/s, NCQ','8.5ms seek','16MB cache']},{'id'=>'F8V7067-APL-KIT','inStock'=>false,'manu'=>'Belkin','name'=>'Belkin Mobile Power Cord for iPod w/ Dock','popularity'=>1,'price'=>19.95,'sku'=>'F8V7067-APL-KIT','timestamp'=>'2009-03-20T14:42:49.937Z','weight'=>4.0,'cat'=>['electronics','connector'],'spell'=>['Belkin Mobile Power Cord for iPod w/ Dock'],'features'=>['car power adapter, white']},{'id'=>'IW-02','inStock'=>false,'manu'=>'Belkin','name'=>'iPod & iPod Mini USB 2.0 Cable','popularity'=>1,'price'=>11.5,'sku'=>'IW-02','timestamp'=>'2009-03-20T14:42:49.944Z','weight'=>2.0,'cat'=>['electronics','connector'],'spell'=>['iPod & iPod Mini USB 2.0 Cable'],'features'=>['car power adapter for iPod, white']},{'id'=>'MA147LL/A','inStock'=>true,'includes'=>'earbud headphones, USB cable','manu'=>'Apple Computer Inc.','name'=>'Apple 60 GB iPod with Video Playback Black','popularity'=>10,'price'=>399.0,'sku'=>'MA147LL/A','timestamp'=>'2009-03-20T14:42:49.962Z','weight'=>5.5,'cat'=>['electronics','music'],'spell'=>['Apple 60 GB iPod with Video Playback Black'],'features'=>['iTunes, Podcasts, Audiobooks','Stores up to 15,000 songs, 25,000 photos, or 150 hours of video','2.5-inch, 320x240 color TFT LCD display with LED backlight','Up to 20 hours of battery life','Plays AAC, MP3, WAV, AIFF, Audible, Apple Lossless, H.264 video','Notes, Calendar, Phone book, Hold button, Date display, Photo wallet, Built-in games, JPEG photo playback, Upgradeable firmware, USB 2.0 compatibility, Playback speed control, Rechargeable capability, Battery level indication']},{'id'=>'TWINX2048-3200PRO','inStock'=>true,'manu'=>'Corsair Microsystems Inc.','name'=>'CORSAIR  XMS 2GB (2 x 1GB) 184-Pin DDR SDRAM Unbuffered DDR 400 (PC 3200) Dual Channel Kit System Memory - Retail','popularity'=>5,'price'=>185.0,'sku'=>'TWINX2048-3200PRO','timestamp'=>'2009-03-20T14:42:49.99Z','cat'=>['electronics','memory'],'spell'=>['CORSAIR  XMS 2GB (2 x 1GB) 184-Pin DDR SDRAM Unbuffered DDR 400 (PC 3200) Dual Channel Kit System Memory - Retail'],'features'=>['CAS latency 2,	2-3-3-6 timing, 2.75v, unbuffered, heat-spreader']},{'id'=>'VS1GB400C3','inStock'=>true,'manu'=>'Corsair Microsystems Inc.','name'=>'CORSAIR ValueSelect 1GB 184-Pin DDR SDRAM Unbuffered DDR 400 (PC 3200) System Memory - Retail','popularity'=>7,'price'=>74.99,'sku'=>'VS1GB400C3','timestamp'=>'2009-03-20T14:42:50Z','cat'=>['electronics','memory'],'spell'=>['CORSAIR ValueSelect 1GB 184-Pin DDR SDRAM Unbuffered DDR 400 (PC 3200) System Memory - Retail']},{'id'=>'VDBDB1A16','inStock'=>true,'manu'=>'A-DATA Technology Inc.','name'=>'A-DATA V-Series 1GB 184-Pin DDR SDRAM Unbuffered DDR 400 (PC 3200) System Memory - OEM','popularity'=>5,'sku'=>'VDBDB1A16','timestamp'=>'2009-03-20T14:42:50.004Z','cat'=>['electronics','memory'],'spell'=>['A-DATA V-Series 1GB 184-Pin DDR SDRAM Unbuffered DDR 400 (PC 3200) System Memory - OEM'],'features'=>['CAS latency 3,	 2.7v']},{'id'=>'3007WFP','inStock'=>true,'includes'=>'USB cable','manu'=>'Dell, Inc.','name'=>'Dell Widescreen UltraSharp 3007WFP','popularity'=>6,'price'=>2199.0,'sku'=>'3007WFP','timestamp'=>'2009-03-20T14:42:50.017Z','weight'=>401.6,'cat'=>['electronics','monitor'],'spell'=>['Dell Widescreen UltraSharp 3007WFP'],'features'=>['30" TFT active matrix LCD, 2560 x 1600, .25mm dot pitch, 700:1 contrast']},{'id'=>'VA902B','inStock'=>true,'manu'=>'ViewSonic Corp.','name'=>'ViewSonic VA902B - flat panel display - TFT - 19"','popularity'=>6,'price'=>279.95,'sku'=>'VA902B','timestamp'=>'2009-03-20T14:42:50.034Z','weight'=>190.4,'cat'=>['electronics','monitor'],'spell'=>['ViewSonic VA902B - flat panel display - TFT - 19"'],'features'=>['19" TFT active matrix LCD, 8ms response time, 1280 x 1024 native resolution']},{'id'=>'0579B002','inStock'=>true,'manu'=>'Canon Inc.','name'=>'Canon PIXMA MP500 All-In-One Photo Printer','popularity'=>6,'price'=>179.99,'sku'=>'0579B002','timestamp'=>'2009-03-20T14:42:50.062Z','weight'=>352.0,'cat'=>['electronics','multifunction printer','printer','scanner','copier'],'spell'=>['Canon PIXMA MP500 All-In-One Photo Printer'],'features'=>['Multifunction ink-jet color photo printer','Flatbed scanner, optical scan resolution of 1,200 x 2,400 dpi','2.5" color LCD preview screen','Duplex Copying','Printing speed up to 29ppm black, 19ppm color','Hi-Speed USB','memory card: CompactFlash, Micro Drive, SmartMedia, Memory Stick, Memory Stick Pro, SD Card, and MultiMediaCard']}]},'facet_counts'=>{'facet_queries'=>{},'facet_fields'=>{'cat'=>['electronics',14,'memory',3,'card',2,'connector',2,'drive',2,'graphics',2,'hard',2,'monitor',2,'search',2,'software',2],'manu'=>['inc',8,'apach',2,'belkin',2,'canon',2,'comput',2,'corp',2,'corsair',2,'foundat',2,'microsystem',2,'softwar',2]},'facet_dates'=>{}}})
  end

  # These spellcheck responses are all Solr 1.4 responses
  def mock_response_with_spellcheck
    %({'responseHeader'=>{'status'=>0,'QTime'=>9,'params'=>{'spellcheck'=>'true','spellcheck.collate'=>'true','wt'=>'ruby','q'=>'hell ultrashar'}},'response'=>{'numFound'=>0,'start'=>0,'docs'=>[]},'spellcheck'=>{'suggestions'=>['hell',{'numFound'=>1,'startOffset'=>0,'endOffset'=>4,'suggestion'=>['dell']},'ultrashar',{'numFound'=>1,'startOffset'=>5,'endOffset'=>14,'suggestion'=>['ultrasharp']},'collation','dell ultrasharp']}})
  end

  def mock_response_with_spellcheck_extended
    %({'responseHeader'=>{'status'=>0,'QTime'=>8,'params'=>{'spellcheck'=>'true','spellcheck.collate'=>'true','wt'=>'ruby','spellcheck.extendedResults'=>'true','q'=>'hell ultrashar'}},'response'=>{'numFound'=>0,'start'=>0,'docs'=>[]},'spellcheck'=>{'suggestions'=>['hell',{'numFound'=>1,'startOffset'=>0,'endOffset'=>4,'origFreq'=>0,'suggestion'=>[{'word'=>'dell','freq'=>1}]},'ultrashar',{'numFound'=>1,'startOffset'=>5,'endOffset'=>14,'origFreq'=>0,'suggestion'=>[{'word'=>'ultrasharp','freq'=>1}]},'correctlySpelled',false,'collation','dell ultrasharp']}})
  end

  def mock_response_with_spellcheck_same_frequency
    %({'responseHeader'=>{'status'=>0,'QTime'=>8,'params'=>{'spellcheck'=>'true','spellcheck.collate'=>'true','wt'=>'ruby','spellcheck.extendedResults'=>'true','q'=>'hell ultrashar'}},'response'=>{'numFound'=>0,'start'=>0,'docs'=>[]},'spellcheck'=>{'suggestions'=>['hell',{'numFound'=>1,'startOffset'=>0,'endOffset'=>4,'origFreq'=>1,'suggestion'=>[{'word'=>'dell','freq'=>1}]},'ultrashard',{'numFound'=>1,'startOffset'=>5,'endOffset'=>14,'origFreq'=>1,'suggestion'=>[{'word'=>'ultrasharp','freq'=>1}]},'correctlySpelled',false,'collation','dell ultrasharp']}})
  end

  # it can be the case that extended results are off and collation is on
  def mock_response_with_spellcheck_collation
    %({'responseHeader'=>{'status'=>0,'QTime'=>3,'params'=>{'spellspellcheck.build'=>'true','spellcheck'=>'true','q'=>'hell','spellcheck.q'=>'hell ultrashar','wt'=>'ruby','spellcheck.collate'=>'true'}},'response'=>{'numFound'=>0,'start'=>0,'docs'=>[]},'spellcheck'=>{'suggestions'=>['hell',{'numFound'=>1,'startOffset'=>0,'endOffset'=>4,'suggestion'=>['dell']},'ultrashar',{'numFound'=>1,'startOffset'=>5,'endOffset'=>14,'suggestion'=>['ultrasharp']},'collation','dell ultrasharp']}})
  end

  def mock_response_with_spellcheck_collation_solr5
    %({'responseHeader'=>{'status'=>0,'QTime'=>3,'params'=>{'spellspellcheck.build'=>'true','spellcheck'=>'true','q'=>'hell','spellcheck.q'=>'hell ultrashar','wt'=>'ruby','spellcheck.collate'=>'true'}},'response'=>{'numFound'=>0,'start'=>0,'docs'=>[]},'spellcheck'=>{'suggestions'=>['hell',{'numFound'=>1,'startOffset'=>0,'endOffset'=>4,'suggestion'=>['dell']},'ultrashar',{'numFound'=>1,'startOffset'=>5,'endOffset'=>14,'suggestion'=>['ultrasharp']}],'collations'=>['collation','dell ultrasharp']}})
  end

  def mock_response_with_spellcheck_collation_solr65
    %({'responseHeader'=>{'status'=>0,'QTime'=>3,'params'=>{'spellspellcheck.build'=>'true','spellcheck'=>'true','q'=>'hell','spellcheck.q'=>'hell ultrashar','wt'=>'ruby','spellcheck.collate'=>'true'}},'response'=>{'numFound'=>0,'start'=>0,'docs'=>[]},'spellcheck'=>{'suggestions'=>{'hell'=>{'numFound'=>1,'startOffset'=>0,'endOffset'=>4,'suggestion'=>['dell']},'ultrashar'=>{'numFound'=>1,'startOffset'=>5,'endOffset'=>14,'suggestion'=>['ultrasharp']}},'collations'=>['collation','dell ultrasharp']}})
  end

  def mock_response_with_more_like_this
    %({'responseHeader'=>{'status'=>0,'QTime'=>8,'params'=>{'facet'=>'false','mlt.mindf'=>'1','mlt.fl'=>'subject_tsim','fl'=>'id','mlt.count'=>'3','mlt.mintf'=>'0','mlt'=>'true','q.alt'=>'*:*','qt'=>'search','wt'=>'ruby'}},'response'=>{'numFound'=>30,'start'=>0,'docs'=>[{'id'=>'00282214'},{'id'=>'00282371'},{'id'=>'00313831'},{'id'=>'00314247'},{'id'=>'43037890'},{'id'=>'53029833'},{'id'=>'77826928'},{'id'=>'78908283'},{'id'=>'79930185'},{'id'=>'85910001'}]},'moreLikeThis'=>{'00282214'=>{'numFound'=>0,'start'=>0,'docs'=>[]},'00282371'=>{'numFound'=>0,'start'=>0,'docs'=>[]},'00313831'=>{'numFound'=>1,'start'=>0,'docs'=>[{'id'=>'96933325'}]},'00314247'=>{'numFound'=>3,'start'=>0,'docs'=>[{'id'=>'2008543486'},{'id'=>'96933325'},{'id'=>'2009373513'}]},'43037890'=>{'numFound'=>0,'start'=>0,'docs'=>[]},'53029833'=>{'numFound'=>0,'start'=>0,'docs'=>[]},'77826928'=>{'numFound'=>1,'start'=>0,'docs'=>[{'id'=>'94120425'}]},'78908283'=>{'numFound'=>0,'start'=>0,'docs'=>[]},'79930185'=>{'numFound'=>2,'start'=>0,'docs'=>[{'id'=>'94120425'},{'id'=>'2007020969'}]},'85910001'=>{'numFound'=>0,'start'=>0,'docs'=>[]}}})
  end

  def mock_query_response_with_lots_of_facets
    %({"responseHeader"=>{"zkConnected"=>true, "status"=>0, "QTime"=>1414, "params"=>{"f.access_facet.facet.sort"=>"index", "facet.field"=>["access_facet", "format", "language_facet", "advanced_location_s"], "f.subject_era_facet.facet.limit"=>"11", "f.location.facet.mincount"=>"1", "sort"=>"score desc, pub_date_start_sort desc, title_sort asc", "f.location.facet.sort"=>"index", "rows"=>"20", "f.lc_facet.facet.limit"=>"1001", "f.location.facet.limit"=>"21", "f.subject_topic_facet.facet.limit"=>"11", "f.sudoc_facet.facet.limit"=>"11", "f.advanced_location_s.facet.sort"=>"alpha", "f.geographic_facet.facet.limit"=>"11", "f.format.facet.mincount"=>"1", "f.instrumentation_facet.facet.limit"=>"11", "f.sudoc_facet.facet.sort"=>"index", "f.format.facet.sort"=>"index", "f.lc_facet.facet.sort"=>"index", "f.genre_facet.facet.limit"=>"11", "facet"=>"true", "wt"=>"json", "f.format.facet.limit"=>"16", "f.language_facet.facet.limit"=>"-1", "f.publication_place_facet.facet.limit"=>"11"}}, "response"=>{"numFound"=>22435132, "start"=>0, "maxScore"=>51.0, "docs"=>[]}, "facet_counts"=>{"facet_queries"=>{}, "facet_fields"=>{"access_facet"=>["In the Library", 16308268, "Online", 6218496], "format"=>["Archival item", 545, "Audio", 398574, "Book", 20395416, "Coin", 18210, "Data file", 11285, "Databases", 25454, "Journal", 939342, "Manuscript", 133954, "Map", 97778, "Microform", 339035, "Musical score", 230775, "Senior thesis", 81686, "Video/Projected medium", 162203, "Visual material", 69194], "language_facet"=>["Abkhaz", 109, "Abu' Arapesh", 1, "Achagua", 1, "Achi", 6, "Achinese", 18, "Acoli", 32, "Adangbe", 1, "Adangme", 12, "Adhola", 2, "Adi", 1, "Adygei", 163, "Adyghe", 2, "Afar", 41, "Afrikaans", 7919, "Afroasiatic (Other)", 232, "Agarabi", 1, "Aguacateco", 1, "Agutaynen", 2, "Ainu", 11, "Ajië", 3, "Ak", 1, "Aka", 1, "Akan", 68, "Akei", 1, "Akkadian", 916, "Aklanon", 1, "Albanian", 8135, "Aleut", 23, "Algonquian (Other)", 208, "Algonquin", 1, "Ali", 1, "Aljamía", 13, "Allar", 1, "Altai", 43, "Altaic (Other)", 2857, "Amanab", 1, "Amba (Uganda)", 1, "Ambai", 1, "Ambulas", 1, "American Sign Language", 2, "Amharic", 1858, "Amis", 1, "Ancient Greek (to 1453)", 1, "Angika", 8, "Anglo-Norman", 7, "Angor", 1, "Ankave", 1, "Ansus", 1, "Anuta", 2, "Apache languages", 33, "Apma", 1, "Arabic", 570726, "Aragonese", 56, "Araki", 1, "Aramaic", 1314, "Arapaho", 10, "Arawak", 28, "Arbëreshë Albanian", 1, "Armenian", 25834, "Armenian Sign Language", 1, "Aromanian", 14, "Arosi", 1, "Artificial (Other)", 56, "As", 1, "Assamese", 2521, "Assiniboine", 1, "Asturian", 3, "Asuri", 2, "Atayal", 1, "Athapascan (Other)", 72, "Australian languages", 130, "Austronesian (Other)", 1275, "Avaric", 227, "Avestan", 219, "Awa (Papua New Guinea)", 1, "Awadhi", 346, "Awara", 1, "Awiyaana", 1, "Aymara", 311, "Ayoreo", 1, "Azerbaijani", 10466, "Bable", 130, "Bagheli", 1, "Baki", 1, "Balangingi", 1, "Balinese", 126, "Balti", 1, "Baltic (Other)", 27, "Baluchi", 841, "Bambara", 240, "Bamileke languages", 35, "Bamun", 1, "Banda languages", 17, "Baniva", 1, "Bantu (Other)", 905, "Baruya", 1, "Basa", 86, "Bashkir", 2491, "Basque", 3003, "Batak", 23, "Batak Toba", 1, "Bauchi", 1, "Bavarian", 1, "Beja", 3, "Belarusian", 13924, "Bemba", 98, "Bembe", 1, "Benga", 1, "Bengali", 28657, "Beothuk", 1, "Berber (Other)", 1005, "Berta", 3, "Besisi", 1, "Betawi", 1, "Bhili", 1, "Bhojpuri", 408, "Bihari (Other)", 36, "Bikol", 15, "Bilin", 11, "Bilua", 2, "Binumarien", 1, "Birgit", 1, "Bislama", 31, "Bissa", 2, "Bo-Ung", 1, "Bodo (India)", 1, "Bole", 2, "Bora", 1, "Boruca", 3, "Bosnian", 6084, "Botlikh", 1, "Bouyei", 5, "Brahui", 3, "Braj", 692, "Breton", 1052, "Bribri", 2, "Brooke's Point Palawano", 1, "Budu", 1, "Buginese", 1, "Bugis", 24, "Buhid", 1, "Bukusu", 2, "Bulgarian", 47796, "Bunak", 1, "Bundeli", 4, "Buriat", 221, "Burmese", 1318, "Burmeso", 1, "Buru (Indonesia)", 1, "Burushaski", 1, "Bushi", 1, "Cabiyarí", 1, "Caddo", 9, "Cajun French", 7, "Carib", 46, "Carolinian", 1, "Catalan", 38289, "Caucasian (Other)", 1476, "Cayuga", 1, "Cebuano", 64, "Celtic (Other)", 119, "Cemuhî", 1, "Central American Indian (Other)", 792, "Central Atlas Tamazight", 3, "Central Malay", 1, "Central Yupik", 1, "Chagatai", 201, "Chamacoco", 1, "Chamic languages", 24, "Chamorro", 33, "Chechen", 376, "Cherokee", 78, "Cheyenne", 22, "Chiapanec", 2, "Chibcha", 17, "Chickasaw", 2, "Chiga", 3, "Chinese", 852329, "Chinook", 3, "Chinook jargon", 43, "Chipaya", 1, "Chipewyan", 4, "Chippewa", 3, "Chittagonian", 1, "Choctaw", 80, "Chokwe", 1, "Chol", 6, "Chopi", 1, "Chuave", 1, "Chuj", 8, "Chung", 1, "Church Slavic", 2015, "Chuukese", 16, "Chuvash", 1888, "Classical Armenian", 2, "Coastal Konjo", 1, "Coeur d'Alene", 3, "Colorado", 1, "Coptic", 888, "Cornish", 110, "Corsican", 121, "Cowlitz", 1, "Cree", 233, "Creek", 98, "Creoles and Pidgins (Other)", 341, "Creoles and Pidgins, English-based (Other)", 165, "Creoles and Pidgins, French-based (Other)", 984, "Creoles and Pidgins, Portuguese-based (Other)", 161, "Crimean Tatar", 93, "Croatian", 39834, "Crow", 3, "Cuiba", 1, "Cushitic (Other)", 43, "Czech", 85104, "Da'a Kaili", 1, "Daga", 1, "Dagbani", 3, "Dai", 1, "Dakota", 196, "Dalabon", 1, "Damal", 1, "Dan", 1, "Danish", 57847, "Dargwa", 55, "Dari", 20, "Day", 1, "Dayak", 15, "Dehu", 3, "Dek", 1, "Delaware", 36, "Dharumbal", 1, "Dhivehi", 1, "Dido", 2, "Digo", 1, "Dii", 1, "Dinka", 15, "Divehi", 9, "Dobel", 1, "Dobu", 2, "Dogri", 253, "Dogrib", 2, "Dolgan", 3, "Domu", 1, "Dong", 1, "Dravidian (Other)", 540, "Duala", 46, "Duna", 4, "Dutch", 187124, "Dutch, Middle (ca. 1050-1350)", 233, "Duwet", 1, "Dyula", 70, "Dzongkha", 142, "E", 17, "East Frisian", 5, "East Futuna", 2, "East Kewa", 1, "Eastern Keres", 2, "Eastern Maninkakan", 1, "Edo", 8, "Efik", 61, "Egyptian", 1386, "Egyptian Arabic", 12, "Eipomek", 2, "Ekajuk", 2, "Elamite", 31, "Elfdalian", 1, "Embu", 2, "En", 55, "Enga", 2, "English", 11856054, "English, Middle (1100-1500)", 1644, "English, Old (ca. 450-1100)", 1078, "Epigraphic Mayan", 1, "Erave", 1, "Erromintxela", 1, "Erzya", 115, "Eskimo languages", 127, "Esperanto", 2647, "Estonian", 8154, "Ethiopic", 1071, "Eton (Cameroon)", 1, "Etruscan", 1, "Even", 7, "Evenki", 4, "Ewe", 161, "Ewondo", 28, "Eyak", 1, "Fanagalo", 1, "Fang", 44, "Fanti", 42, "Faroese", 650, "Fasu", 1, "Fijian", 38, "Filipino", 28, "Finnish", 33929, "Finno-Ugrian (Other)", 1603, "Foi", 2, "Fon", 73, "Fortsenal", 1, "French", 1520234, "French, Middle (ca. 1300-1600)", 2373, "French, Old (ca. 842-1300)", 2608, "Frisian", 930, "Friulian", 167, "Fula", 441, "Fulah", 2, "Ga", 7, "Gadsup", 1, "Gagauz", 4, "Galician", 6077, "Ganda", 355, "Garifuna", 7, "Garo", 1, "Gayo", 10, "Gbaya", 8, "Geez", 1, "Gen", 1, "Gende", 1, "Georgian", 11778, "German", 1771128, "German, Middle High (ca. 1050-1500)", 2266, "German, Old High (ca. 750-1050)", 261, "Germanic (Other)", 676, "Gilaki", 1, "Gilbertese", 29, "Giryama", 2, "Gogo", 1, "Gondi", 25, "Gorontalo", 3, "Gothic", 146, "Grebo", 16, "Greek, Ancient (to 1453)", 25025, "Greek, Modern (1453- )", 330, "Greek, Modern (1453-)", 103469, "Gros Ventre", 1, "Guadeloupean Creole French", 1, "Guanano", 1, "Guarani", 543, "Gujarati", 3563, "Gungu", 1, "Gurani", 1, "Gusii", 3, "Gweno", 1, "Gwere", 2, "Gwich'in", 12, "Gã", 117, "Haida", 20, "Haitian", 54, "Haitian French Creole", 555, "Hakka Chinese", 1, "Hamtai", 1, "Han", 13, "Hani", 1, "Hano", 2, "Hanunoo", 2, "Harari", 1, "Haruai", 1, "Hassaniyya", 2, "Hausa", 796, "Hawai'i Creole English", 1, "Hawaiian", 321, "Haya", 3, "Hazaragi", 1, "Hebrew", 267549, "Hehe", 1, "Hemba", 1, "Herero", 80, "Hidatsa", 1, "Hieroglyphic Luwian", 2, "Hiligaynon", 25, "Hindi", 57077, "Hiri Motu", 4, "Hittite", 80, "Hmong", 65, "Ho", 1, "Hopi", 4, "Hoti", 1, "Huastec", 1, "Huichol", 5, "Hula", 2, "Huli", 2, "Hungarian", 53699, "Hupa", 1, "Hurrian", 1, "Iaai", 3, "Iban", 25, "Ibani", 1, "Icelandic", 9446, "Ido", 32, "Idoma", 1, "Igala", 1, "Igbo", 164, "Ijo", 28, "Ikpeng", 1, "Ikulu", 1, "Iloko", 61, "Imonda", 1, "Inari Sami", 2, "Indic (Other)", 1283, "Indigenous Languages (Western Hemisphere)", 8667, "Indo-European (Other)", 180, "Indonesian", 16538, "Indus Kohistani", 1, "Ingrian", 2, "Ingush", 70, "Innu", 1, "Interlingua (International Auxiliary Language Association)", 61, "Interlingue", 7, "Inuktitut", 184, "Inupiaq", 32, "Iquito", 1, "Iranian (Other)", 334, "Irarutu", 1, "Irish", 5431, "Irish, Middle (ca. 1100-1550)", 24, "Irish, Old (to 1100)", 27, "Iroquoian (Other)", 110, "Isnag", 1, "Italian", 896484, "Iwal", 1, "Ixil", 6, "Japanese", 440892, "Javanese", 463, "Jebero", 2, "Jejueo", 2, "Jewish Palestinian Aramaic", 1, "Jita", 4, "Judeo-Arabic", 1157, "Judeo-Persian", 75, "Judeo-Tat", 2, "Jurchen", 1, "K'iche'", 108, "Kabardian", 175, "Kabwa", 1, "Kabyle", 181, "Kachin", 14, "Kaduo", 1, "Kagayanen", 1, "Kaikavian Literary Language", 1, "Kaike", 1, "Kaingang", 1, "Kala Lagaw Ya", 1, "Kalaallisut", 1, "Kalam", 4, "Kalenjin", 1, "Kalmyk", 8, "Kaluli", 1, "Kalâtdlisut", 174, "Kamba", 45, "Kamoro", 1, "Kannada", 5419, "Kanuri", 31, "Kanyok", 1, "Kaonde", 1, "Kapingamarangi", 1, "Kaqchikel", 15, "Kara-Kalpak", 348, "Karachay-Balkar", 68, "Karaim", 3, "Karanga", 1, "Karelian", 72, "Karen languages", 60, "Karok", 1, "Kasem", 1, "Kashmiri", 315, "Kashubian", 52, "Katbol", 1, "Kaulong", 2, "Kavalan", 1, "Kawi", 42, "Kayan", 1, "Kazakh", 8333, "Kekchí", 6, "Kele (Democratic Republic of Congo)", 1, "Ket", 3, "Khakas", 8, "Khalaj", 1, "Khams Tibetan", 1, "Khanty", 7, "Khasi", 268, "Khmer", 366, "Khoekhoe", 1, "Khoisan (Other)", 86, "Khotanese", 18, "Khowar", 1, "Khunsari", 2, "Khvarshi", 1, "Kikuyu", 106, "Kilivila", 11, "Kiliwa", 1, "Kimbundu", 27, "Kinyarwanda", 408, "Kiowa", 1, "Kipsigis", 1, "Kirghiz", 142, "Kistane", 1, "Klingon", 2, "Klingon (Artificial language)", 5, "Koasati", 1, "Kobon", 1, "Komi", 358, "Komi-Permyak", 2, "Komi-Zyrian", 2, "Kongo", 199, "Konkani", 92, "Kootenai", 1, "Korean", 194621, "Koryak", 5, "Kosraean", 10, "Koyukon", 1, "Kpelle", 11, "Krio", 2, "Kriol", 1, "Krisa", 1, "Kru (Other)", 61, "Krymchak", 1, "Kuanyama", 75, "Kudmali", 3, "Kullu Pahari", 1, "Kumam", 2, "Kumaoni", 2, "Kumyk", 57, "Kunbarlang", 1, "Kurdish", 7398, "Kurudu", 1, "Kurukh", 55, "Kwamera", 1, "Kwanga", 1, "Kwangali", 4, "Kwara'ae", 1, "Kyrgyz", 4610, "Laal", 2, "Labo", 1, "Lacandon", 2, "Ladakhi", 1, "Ladin", 14, "Ladino", 666, "Lahndā", 399, "Lahu", 1, "Lak", 8, "Laki", 2, "Lakota", 9, "Lamba (Zambia and Congo)", 16, "Lamenu", 1, "Lao", 266, "Latin", 218297, "Latvian", 15472, "Laz", 10, "Lele (Papua New Guinea)", 1, "Lendu", 1, "Leti (Indonesia)", 1, "Lewo", 2, "Lezghian", 1, "Lezgian", 54, "Lillooet", 2, "Limbu", 1, "Limburgish", 1, "Limos Kalinga", 1, "Lingala", 124, "Lish", 2, "Lisu", 5, "Literary Chinese", 5, "Lithuanian", 11351, "Litzlitz", 1, "Logooli", 1, "Lojban (Artificial language)", 1, "Lonwolwol", 1, "Low German", 136, "Lower Sorbian", 13, "Lozi", 65, "Luba-Katanga", 56, "Luba-Lulua", 19, "Ludian", 1, "Luiseño", 10, "Lule Sami", 9, "Lunda", 15, "Luo (Kenya and Tanzania)", 56, "Luri", 3, "Lusengo", 3, "Lushai", 408, "Luxembourgish", 85, "Luyia", 3, "Lü", 1, "Maasai", 33, "Maay", 1, "Maba (Chad)", 1, "Macedonian", 9412, "Madak", 1, "Madurese", 13, "Magahi", 60, "Mahou", 1, "Mai Brat", 1, "Maiani", 1, "Maisin", 1, "Maithili", 604, "Makasar", 21, "Makonde", 3, "Maku'a", 1, "Malagasy", 723, "Malawi Lomwe", 1, "Malay", 3937, "Malay (individual language)", 3, "Malayalam", 5865, "Malo", 1, "Maltese", 1060, "Malvi", 1, "Mam", 14, "Manchu", 330, "Mandar", 2, "Mandarin Chinese", 17, "Mandingo", 333, "Mandinka", 2, "Mangareva", 1, "Manggarai", 1, "Mangue", 1, "Manipuri", 136, "Manobo languages", 105, "Mansi", 5, "Manx", 47, "Maori", 560, "Mapuche", 187, "Maragus", 1, "Marathi", 3209, "Marau", 1, "Mari", 538, "Marovo", 1, "Marshallese", 33, "Marwari", 95, "Masai", 2, "Maskelynes", 1, "Mayan languages", 2306, "Mayo", 1, "Mbosi", 1, "Mbukushu", 1, "Medumba", 2, "Mele-Fila", 1, "Mende", 55, "Mengisa", 1, "Meriam Mir", 1, "Meru", 2, "Meskwaki", 2, "Mi'kmaq", 1, "Micmac", 49, "Mid Grand Valley Dani", 1, "Middle French (ca. 1400-1600)", 2, "Middle Low German", 1, "Middle Welsh", 1, "Min Bei Chinese", 2, "Min Nan Chinese", 2, "Minangkabau", 29, "Minaveha", 1, "Mirandese", 10, "Miscellaneous languages", 457, "Mising", 2, "Miu", 1, "Mlabri", 1, "Mochi", 1, "Modern Greek (1453-)", 28, "Mohawk", 83, "Mokilese", 1, "Moksha", 83, "Molbog", 1, "Moldavian", 1576, "Mon-Khmer (Other)", 90, "Mongo-Nkundu", 53, "Mongol", 2, "Mongolian", 4492, "Montenegrin", 300, "Mooré", 119, "Mopán Maya", 1, "Morisyen", 7, "Moroccan Arabic", 14, "Morom", 1, "Mota", 1, "Motlav", 2, "Multiple languages", 36044, "Munda", 1, "Munda (Other)", 87, "Mundang", 1, "Munsee", 5, "Murik (Papua New Guinea)", 1, "Mwaghavul", 1, "Myene", 1, "Mískito", 1, "N'Ko", 5, "Nahuatl", 723, "Nakanai", 2, "Nalik", 1, "Nambya", 1, "Nande", 1, "Naskapi", 1, "Nauru", 5, "Navajo", 194, "Naxi", 9, "Ndau", 5, "Ndebele (South Africa)", 30, "Ndebele (Zimbabwe)", 317, "Ndonga", 122, "Neapolitan", 36, "Neapolitan Italian", 139, "Nekgini", 1, "Nemi", 1, "Nenets", 5, "Nengone", 6, "Nepali", 7371, "Nepali (macrolanguage)", 1, "Newari", 897, "Newari, Old", 2, "Nez Perce", 1, "Ngad'a", 1, "Ngaju", 2, "Nganasan", 1, "Ngatik Men's Creole", 2, "Nhengatu", 1, "Nias", 4, "Niger-Kordofanian (Other)", 1724, "Nigerian Pidgin", 1, "Nilo-Saharan (Other)", 321, "Nimadi", 1, "Niuean", 12, "Nivaclé", 1, "Nogai", 24, "Nokuku", 1, "Nomatsiguenga", 1, "Noon", 1, "North Ambrym", 1, "North American Indian (Other)", 396, "North American Indian languages", 1, "North Efate", 1, "North Frisian", 16, "North Marquesan", 3, "North Tairora", 1, "Northern Ping Chinese", 2, "Northern Qiang", 1, "Northern Sami", 54, "Northern Sotho", 129, "Northern Thai", 2, "Northern Uzbek", 2, "Northern Yukaghir", 1, "Norwegian", 32744, "Norwegian (Bokmål)", 1530, "Norwegian (Nynorsk)", 364, "Norwegian Bokmål", 4, "Norwegian Nynorsk", 1, "Notsi", 1, "Nubian languages", 77, "Nuer", 1, "Nukuoro", 1, "Nume", 1, "Nyamwezi", 5, "Nyangumarta", 1, "Nyanja", 347, "Nyankole", 40, "Nyole", 1, "Nyoro", 34, "Nzima", 17, "Nêlêmwa-Nixumwak", 2, "Occitan (post 1500)", 301, "Occitan (post-1500)", 1086, "Ogea", 1, "Oirat", 164, "Ojibwa", 206, "Oko-Eni-Osayen", 1, "Old Norse", 131, "Old Persian (ca. 600-400 B.C.)", 74, "Old Russian", 7, "Old Spanish", 13, "Old Turkish", 5, "Old Uighur", 1, "Oneida", 2, "Onondaga", 1, "Ontong Java", 1, "Opata", 1, "Oriya", 3619, "Orma", 1, "Oromo", 313, "Osage", 8, "Ossetian", 1, "Ossetic", 657, "Otomian languages", 161, "Ottoman Turkish (1500-1928)", 1, "Paama", 2, "Pahlavi", 422, "Paiwan", 1, "Palauan", 38, "Pali", 1402, "Pam", 1, "Pampanga", 17, "Panchpargania", 1, "Pangasinan", 16, "Panjabi", 9344, "Papiamento", 120, "Papuan (Other)", 499, "Parthian", 1, "Patep", 1, "Pazeh", 1, "Pemon", 1, "Pennsylvania German", 4, "Penrhyn", 1, "Persian", 139401, "Philippine (Other)", 262, "Phoenician", 10, "Piapoco", 2, "Picard", 1, "Pijin", 5, "Pileni", 2, "Pima Bajo", 1, "Pingelapese", 1, "Pinyin", 1, "Pipil", 1, "Pitcairn-Norfolk", 2, "Pitjantjatjara", 2, "Plateau Malagasy", 1, "Pnar", 1, "Pohnpeian", 33, "Polish", 180970, "Pom", 1, "Popti'", 5, "Poqomchi'", 7, "Portuguese", 278926, "Prakrit languages", 1398, "Provençal (to 1500)", 1071, "Pukapuka", 1, "Pulaar", 1, "Pular", 8, "Punu", 1, "Purari", 1, "Purepecha", 1, "Puri", 1, "Pushto", 4138, "Q'anjob'al", 2, "Qaqet", 2, "Qashqa'i", 2, "Quechua", 1084, "Quinault", 2, "Raeto-Romance", 768, "Rajasthani", 1542, "Raji", 1, "Rapa", 1, "Rapanui", 24, "Rarotongan", 17, "Romagnol", 1, "Romance (Other)", 1909, "Romani", 833, "Romanian", 34336, "Ron", 1, "Rotuman", 3, "Roviana", 1, "Ruga", 1, "Rukai", 3, "Rundi", 96, "Russian", 767701, "Rusyn", 5, "Ruthenian", 1, "Sacapulteco", 8, "Sadri", 1, "Safeyoka", 1, "Sahu", 1, "Salar", 1, "Saliba", 2, "Salishan languages", 59, "Samaritan", 5, "Samaritan Aramaic", 83, "Samburu", 2, "Sami", 174, "Samoan", 159, "Sandawe", 10, "Sango", 3, "Sango (Ubangi Creole)", 34, "Sanskrit", 27465, "Santali", 22, "Sara", 3, "Sarangani Blaan", 1, "Sardinian", 305, "Sasak", 3, "Sawai", 1, "Scots", 389, "Scottish Gaelic", 661, "Scottish Gaelix", 264, "Sediq", 1, "Selkup", 34, "Semitic (Other)", 165, "Sena", 1, "Seneca", 2, "Serbian", 38227, "Serbo-Croatian", 76, "Serer", 86, "Seri", 1, "Serrano", 1, "Serui-Laut", 1, "Shan", 71, "Sharanahua", 1, "Shawnee", 1, "She", 2, "Shina", 2, "Shipibo-Conibo", 1, "Shona", 662, "Shor", 2, "Shoshoni", 4, "Shuar", 1, "Sichuan Yi", 8, "Sicilian", 13, "Sicilian Italian", 140, "Sidamo", 12, "Sie", 3, "Sign languages", 28, "Sika", 1, "Siksika", 20, "Simbo", 1, "Sindhi", 5326, "Singpho", 1, "Sinhala", 3, "Sinhalese", 2056, "Sino-Tibetan (Other)", 912, "Siouan (Other)", 32, "Sipacapense", 1, "Siraya", 1, "Siwai", 1, "Skolt Sami", 3, "Slavey", 26, "Slavic (Other)", 681, "Slovak", 20507, "Slovenian", 12311, "Soga", 8, "Sogdian", 50, "Som", 1, "Somali", 687, "Songhai", 104, "Soninke", 84, "Sonsorol", 1, "Soqotri", 1, "Sorbian (Other)", 1005, "Sori-Harengan", 1, "Sotho", 412, "South American Indian (Other)", 1174, "South Efate", 2, "South Marquesan", 1, "South West Bay", 1, "Southern Altai", 3, "Southern Ping Chinese", 1, "Southern Qiang", 1, "Southern Sami", 8, "Southern Sotho", 2, "Southern Yukaghir", 1, "Sowanda", 1, "Spanish", 1229068, "Spanish; Castilian", 2, "Sranan", 5, "Sui", 2, "Sukuma", 12, "Sumbwa", 1, "Sumerian", 365, "Sundanese", 121, "Susu", 18, "Svan", 1, "Swahili", 3467, "Swahili (macrolanguage)", 2, "Swati", 1, "Swazi", 121, "Swedish", 83130, "Swiss German", 86, "Sylheti", 1, "Syriac", 381, "Syriac, Modern", 1681, "Tacana", 6, "Tachelhit", 2, "Tagalog", 1011, "Tagbanwa", 1, "Tahitian", 76, "Tai", 7, "Tai (Other)", 135, "Taino", 1, "Tajik", 2975, "Takelma", 1, "Takia", 1, "Takuu", 1, "Tamashek", 68, "Tamil", 23829, "Tanacross", 3, "Tangale", 2, "Tangoa", 1, "Tangut", 6, "Tarifit", 1, "Tatar", 3832, "Tausug", 1, "Tauya", 1, "Tayo", 1, "Tektiteko", 1, "Telugu", 5971, "Temne", 34, "Teop", 1, "Terena", 10, "Teso", 5, "Tetum", 34, "Thai", 2795, "Tharaka", 1, "Thompson", 1, "Tibetan", 15603, "Tigrinya", 243, "Tigré", 32, "Tii", 1, "Tikopia", 2, "Timugon Murut", 1, "Tiruray", 1, "Tiv", 12, "Tlingit", 22, "To", 1, "To'abaita", 3, "Toaripi", 1, "Toba", 3, "Tobelo", 1, "Tobian", 1, "Tojolabal", 9, "Tok Pisin", 36, "Tokelau", 4, "Tokelauan", 10, "Tonga (Nyasa)", 31, "Tonga (Tonga Islands)", 8, "Tongan", 71, "Tonkawa", 1, "Tornedalen Finnish", 1, "Torres Strait Creole", 1, "Tosk Albanian", 1, "Trimuris", 1, "Truk", 5, "Tsakonian", 3, "Tsimshian", 22, "Tsonga", 94, "Tsou", 1, "Tswana", 438, "Tuamotuan", 1, "Tucano", 1, "Tulu", 1, "Tumbuka", 40, "Tupi languages", 37, "Tupuri", 1, "Turkish", 155316, "Turkish, Ottoman", 12301, "Turkmen", 2295, "Tuvalu", 2, "Tuvaluan", 5, "Tuvinian", 96, "Tuyuca", 1, "Twi", 189, "Tz'utujil", 2, "Tzeltal", 26, "Tzotzil", 34, "U", 2, "Ubykh", 1, "Udi", 1, "Udmurt", 447, "Ugaritic", 85, "Uighur", 2749, "Ukrainian", 95159, "Ulithian", 1, "Ulwa", 1, "Uma", 1, "Umbrian", 1, "Umbundu", 30, "Unami", 4, "Undetermined", 3, "Unua", 1, "Upper Sorbian", 28, "Ura (Vanuatu)", 1, "Urdu", 44464, "Uripiv-Wala-Rano-Atchin", 1, "Uru", 2, "Usan", 1, "Usarufa", 1, "Uspanteco", 2, "Uzbek", 9572, "Vai", 10, "Vano", 1, "Venda", 54, "Venetian", 11, "Veps", 2, "Vietnamese", 17468, "Vinmavis", 1, "Volapük", 12, "Votic", 22, "Wa", 2, "Waffa", 1, "Wagdi", 1, "Wailaki", 1, "Waima", 1, "Wakashan languages", 30, "Wallisian", 4, "Walloon", 26, "Walser", 1, "Wampar", 2, "Warao", 5, "Waray", 12, "Waris", 1, "Washoe", 1, "Wayuu", 1, "Welsh", 5779, "West Kewa", 2, "Western Mari", 1, "Western Pahari languages", 116, "Wichí Lhamtés Vejoz", 2, "Wintu", 1, "Woi", 1, "Wolayta", 5, "Wolio", 1, "Wolof", 470, "Wu Chinese", 6, "Wunumara", 1, "Wuvulu-Aua", 1, "Wyandot", 1, "Xhosa", 456, "Xibe", 1, "Xârâgurè", 1, "Yagnobi", 1, "Yakut", 512, "Yale", 1, "Yami", 1, "Yana", 1, "Yandruwandha", 1, "Yao", 5, "Yao (Africa)", 41, "Yapese", 4, "Yaqui", 3, "Yavitero", 1, "Yawa", 1, "Yemba", 1, "Yiddish", 9091, "Yombe", 1, "Yopno", 1, "Yoruba", 675, "Yuanga", 1, "Yucateco", 1, "Yue Chinese", 2, "Yug", 2, "Yupik languages", 221, "Yuracare", 3, "Zabana", 1, "Zaghawa", 1, "Zande languages", 10, "Zapotec", 158, "Zarma", 1, "Zaza", 166, "Zazao", 1, "Zenaga", 10, "Zhuang", 17, "Zigula", 1, "Zinza", 1, "Zo'é", 1, "Zulu", 524, "Zuni", 24, "Záparo", 2, "Ömie", 1, "ǂHua", 1], "advanced_location_s"=>["Architecture Library", 28481, "East Asian Library", 217570, "Electronic Access", 1, "Engineering Library", 27408, "Firestone Library", 1718454, "Forrestal Annex", 333154, "Harold P. Furth Plasma Physics Library", 10175, "Lewis Library", 179829, "Marquand Library", 484278, "Mendel Music Library", 203410, "Mudd Manuscript Library", 91249, "Obsolete Locations", 2, "ReCAP", 12700360, "Special Collections", 415083, "Stokes Library", 29669, "Technical Services", 253, "annex$fst", 205009, "annex$locked", 2006, "annex$noncirc", 229, "annex$princeton", 6692, "annex$reserve", 9197, "annex$sct", 270, "annex$sdt", 26, "annex$set", 44, "annex$sht", 1, "annex$spt", 33, "annex$srt", 25, "annex$stacks", 110246, "annex$t", 43, "arch$UNASSIGNED", 1, "arch$la", 186, "arch$newbook", 2, "arch$pw", 951, "arch$ref", 945, "arch$resclosed", 1, "arch$stacks", 26553, "eastasian$cjk", 141327, "eastasian$cjkref", 9388, "eastasian$gest", 11587, "eastasian$gestpe", 355, "eastasian$gestpr", 13, "eastasian$hy", 41426, "eastasian$hygf", 5412, "eastasian$hype", 878, "eastasian$hyref", 222, "eastasian$pl", 5970, "eastasian$ql", 755, "eastasian$ref", 1224, "eastasian$reserve", 33, "engineer$UNASSIGNED", 1, "engineer$index", 1, "engineer$media", 237, "engineer$mic", 16, "engineer$nb", 21, "engineer$pt", 284, "engineer$ref", 16, "engineer$res", 4, "engineer$scc", 3, "engineer$serial", 252, "engineer$stacks", 26542, "engineer$str", 22, "engineer$theses", 20, "firestone$aas", 1633, "firestone$clas", 50959, "firestone$clasnc", 14, "firestone$dixn", 2516, "firestone$docs", 4084, "firestone$dr", 2823, "firestone$dra", 71, "firestone$drrr", 83, "firestone$dss", 432, "firestone$egsr", 100, "firestone$fac", 1460, "firestone$fis", 599, "firestone$flm", 80245, "firestone$flmb", 740, "firestone$flmm", 258, "firestone$flmp", 20, "firestone$gestf", 2, "firestone$gss", 561, "firestone$hldn", 2588, "firestone$isc", 89, "firestone$law", 2, "firestone$lrc", 106, "firestone$nec", 115779, "firestone$necnc", 2, "firestone$noncirc", 1503, "firestone$nr", 40, "firestone$pb", 2221, "firestone$pf", 26811, "firestone$pr", 31, "firestone$pres", 1559, "firestone$raas", 1, "firestone$res3hr", 7, "firestone$rrel", 1, "firestone$sc", 4382, "firestone$sd", 575, "firestone$se", 5386, "firestone$secw", 34, "firestone$seref", 189, "firestone$sh", 357, "firestone$shs", 405, "firestone$slav", 2066, "firestone$sne", 1282, "firestone$spc", 1354, "firestone$sps", 426, "firestone$srel", 702, "firestone$ssa", 74, "firestone$ssrcdc", 918, "firestone$ssrcfo", 106, "firestone$sss", 22, "firestone$stacks", 1412480, "firestone$trv", 1412, "firestone$un", 716, "firestone$vidl", 391, "firestone$vidlr", 9, "firestone$xl", 491, "firestone$xlnc", 7, "firestone$zeiss", 948, "lewis$doc", 2013, "lewis$efa", 124, "lewis$gis", 103, "lewis$laf", 2847, "lewis$lal", 24, "lewis$ltop", 8, "lewis$map", 8328, "lewis$maplf", 22500, "lewis$maplref", 2790, "lewis$mapmc", 8121, "lewis$mapmcm", 11182, "lewis$media", 185, "lewis$mic", 8876, "lewis$nb", 7, "lewis$pam", 670, "lewis$ph", 3, "lewis$pn", 12110, "lewis$ps", 181, "lewis$ref", 399, "lewis$refid", 17, "lewis$res", 12, "lewis$serial", 6930, "lewis$stacks", 86850, "lewis$sudoc", 205, "lewis$theses", 6200, "marquand$fesrf", 167, "marquand$mic", 7398, "marquand$ph", 1, "marquand$pj", 262417, "marquand$pv", 765, "marquand$pz", 11642, "marquand$ref", 723, "marquand$res", 1, "marquand$saf", 1, "marquand$stacks", 195478, "marquand$t", 160, "marquand$x", 7206, "mendel$av", 1200, "mendel$facs", 3505, "mendel$g", 14, "mendel$locked", 3275, "mendel$nb", 15, "mendel$pe", 565, "mendel$pk", 6636, "mendel$qk", 35479, "mendel$ref", 9796, "mendel$res", 853, "mendel$rg", 11, "mendel$stacks", 144466, "mudd$mic", 10, "mudd$ph", 19644, "mudd$phr", 49, "mudd$prnc", 499, "mudd$scamudd", 3094, "mudd$stacks", 68462, "online$UNASSIGNED", 1, "plasma$la", 68, "plasma$li", 83, "plasma$nb", 5, "plasma$ps", 119, "plasma$rdr", 5290, "plasma$ref", 242, "plasma$rr", 32, "plasma$stacks", 4189, "plasma$theses", 287, "rare$UNASSIGNED", 1, "rare$beac", 1568, "rare$cook", 1156, "rare$crare", 152, "rare$ctsn", 80535, "rare$ctsnrf", 1191, "rare$ed", 70, "rare$ex", 116681, "rare$exb", 552, "rare$exc", 470, "rare$exca", 826, "rare$exf", 677, "rare$exho", 739, "rare$exi", 78, "rare$exka", 1, "rare$exki", 1500, "rare$exl", 72, "rare$exme", 778, "rare$exov", 2667, "rare$expa", 6740, "rare$exrc", 410, "rare$exrl", 3228, "rare$extr", 74, "rare$extsf", 7, "rare$exv", 133, "rare$exw", 1000, "rare$ga", 37643, "rare$garf", 692, "rare$gax", 15174, "rare$gestrare", 15, "rare$hsvc", 4238, "rare$hsve", 55, "rare$hsvg", 217, "rare$hsvm", 15179, "rare$hsvp", 27, "rare$hsvr", 7711, "rare$hsvw", 147, "rare$htn", 647, "rare$hycrare", 1680, "rare$hyjrare", 50, "rare$hykrare", 48, "rare$jrare", 508, "rare$krare", 7, "rare$map", 7932, "rare$mss", 3160, "rare$num", 18833, "rare$numrf", 885, "rare$pb", 244, "rare$ptt", 794, "rare$rht", 32, "rare$scaex", 16, "rare$scagax", 2, "rare$scahsvc", 2, "rare$scahsvm", 104, "rare$scamss", 4801, "rare$scathx", 1, "rare$scawa", 4, "rare$scawhs", 1, "rare$thx", 10802, "rare$vrg", 661, "rare$w", 4499, "rare$wa", 2525, "rare$warf", 138, "rare$whs", 2459, "rare$wit", 954, "rare$xc", 13403, "rare$xcr", 5, "rare$xg", 3666, "rare$xgr", 2, "rare$xm", 42, "rare$xmr", 1002, "rare$xn", 351, "rare$xp", 1285, "rare$xr", 35696, "rare$xrr", 116, "rare$xw", 19693, "rare$xx", 5645, "recap$UNASSIGNED", 1, "recap$gp", 30887, "recap$jq", 1, "recap$pa", 2550683, "recap$pe", 35, "recap$pq", 1, "recap$qv", 26091, "scsbcul", 3672292, "scsbhl", 3627511, "scsbnypl", 2792972, "stokes$mic", 10, "stokes$nb", 13, "stokes$piapr", 1, "stokes$pm", 24, "stokes$ref", 290, "stokes$respiapr", 1, "stokes$spia", 8654, "stokes$spiaps", 142, "stokes$spiaws", 26, "stokes$spir", 56, "stokes$spr", 20364, "stokes$sprps", 279, "stokes$tech", 1, "techserv$UNASSIGNED", 113, "techserv$acqord", 3, "techserv$dc", 137, "zobsolete$zned", 1, "zobsolete$zscl", 1, "هگ", 1]}, "facet_ranges"=>{}, "facet_intervals"=>{}, "facet_heatmaps"=>{}}})
  end
end
