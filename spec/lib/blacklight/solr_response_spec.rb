require 'spec_helper'

describe Blacklight::SolrResponse do

  def create_response
    raw_response = eval(mock_query_response)
    Blacklight::SolrResponse.new(raw_response, raw_response['params'])
  end

  let(:r) { create_response }

  it 'should create a valid response' do
    expect(r).to respond_to(:header)
  end

  it 'should have accurate pagination numbers' do
    expect(r.rows).to eq 11
    expect(r.total).to eq 26
    expect(r.start).to eq 0
  end

  it 'should create a valid response class' do
    expect(r).to respond_to(:response)
    expect(r.docs).to have(11).docs
    expect(r.params[:echoParams]).to eq 'EXPLICIT'
    
    expect(r).to be_a(Blacklight::SolrResponse::Facets)
  end

  it 'should provide facet helpers' do
    expect(r.facets.size).to eq 2

    field_names = r.facets.collect{|facet|facet.name}
    expect(field_names.include?('cat')).to be true
    expect(field_names.include?('manu')).to be  true

    first_facet = r.facets.select { |x| x.name == 'cat'}.first
    expect(first_facet.name).to eq 'cat'

    expect(first_facet.items.size).to eq 10

    expected = "electronics - 14, memory - 3, card - 2, connector - 2, drive - 2, graphics - 2, hard - 2, monitor - 2, search - 2, software - 2"
    received = first_facet.items.collect do |item|
      item.value + ' - ' + item.hits.to_s
    end.join(', ')

    expect(received).to eq expected

    r.facets.each do |facet|
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

  it "should provide kaminari pagination helpers" do
    expect(r.limit_value).to eq(r.rows)
    expect(r.offset_value).to eq(r.start)
    expect(r.total_count).to eq(r.total)
    expect(r.next_page).to eq(r.current_page + 1)
    expect(r.prev_page).to eq(nil)
    if Kaminari.config.respond_to? :max_pages
      expect(r.max_pages).to be_nil
    end
    expect(r).to be_a_kind_of Kaminari::PageScopeMethods
  end

  it "should provide a model name helper" do
    first_doc_model_name = double(:human => 'xyz')

    allow(r.docs.first).to receive(:model_name).and_return first_doc_model_name

    expect(r.model_name).to eq first_doc_model_name
  end

  describe "FacetItem" do
    it "should work with a field,value tuple" do
      item = Blacklight::SolrResponse::Facets::FacetItem.new('value', 15)
      expect(item.value).to eq 'value'
      expect(item.hits).to eq 15
    end

    it "should work with a field,value + hash triple" do
      item = Blacklight::SolrResponse::Facets::FacetItem.new('value', 15, :a => 1, :value => 'ignored')
      expect(item.value).to eq 'value'
      expect(item.hits).to eq 15
      expect(item.a).to eq 1
    end

    it "should work like an openstruct" do
      item = Blacklight::SolrResponse::Facets::FacetItem.new(:value => 'value', :hits => 15)
      
      expect(item.hits).to eq 15
      expect(item.value).to eq 'value'
      expect(item).to be_a_kind_of(OpenStruct)
    end

    it "should provide a label accessor" do
      item = Blacklight::SolrResponse::Facets::FacetItem.new('value', :hits => 15)
      expect(item.label).to eq 'value'
    end

    it "should use a provided label" do
      item = Blacklight::SolrResponse::Facets::FacetItem.new('value', 15, :label => 'custom label')
      expect(item.label).to eq 'custom label'

    end

  end

  it 'should return the correct value when calling facet_by_field_name' do
    r = create_response
    facet = r.facet_by_field_name('cat')
    expect(facet.name).to eq 'cat'
  end

  it 'should provide the responseHeader params' do
    raw_response = eval(mock_query_response)
    raw_response['responseHeader']['params']['test'] = :test
    r = Blacklight::SolrResponse.new(raw_response, raw_response['params'])
    expect(r.params['test']).to eq :test
  end

  it 'should provide the solr-returned params and "rows" should be 11' do
    raw_response = eval(mock_query_response)
    r = Blacklight::SolrResponse.new(raw_response, {})
    expect(r.params[:rows].to_s).to eq '11'
  end

  it 'should provide the ruby request params if responseHeader["params"] does not exist' do
    raw_response = eval(mock_query_response)
    raw_response.delete 'responseHeader'
    r = Blacklight::SolrResponse.new(raw_response, :rows => 999)
    expect(r.params[:rows].to_s).to eq '999'
  end

  it 'should provide spelling suggestions for regular spellcheck results' do
    raw_response = eval(mock_response_with_spellcheck)
    r = Blacklight::SolrResponse.new(raw_response,  {})
    expect(r.spelling.words).to include("dell")
    expect(r.spelling.words).to include("ultrasharp")
  end

  it 'should provide spelling suggestions for extended spellcheck results' do
    raw_response = eval(mock_response_with_spellcheck_extended)
    r = Blacklight::SolrResponse.new(raw_response, {})
    expect(r.spelling.words).to include("dell")
    expect(r.spelling.words).to include("ultrasharp")
  end

  it 'should provide no spelling suggestions when extended results and suggestion frequency is the same as original query frequency' do
    raw_response = eval(mock_response_with_spellcheck_same_frequency)
    r = Blacklight::SolrResponse.new(raw_response, {})
    expect(r.spelling.words).to eq []
  end

  it 'should provide spelling suggestions for a regular spellcheck results with a collation' do
    raw_response = eval(mock_response_with_spellcheck_collation)
    r = Blacklight::SolrResponse.new(raw_response, {})
    expect(r.spelling.words).to include("dell")
    expect(r.spelling.words).to include("ultrasharp")
  end

  it 'should provide spelling suggestion collation' do
    raw_response = eval(mock_response_with_spellcheck_collation)
    r = Blacklight::SolrResponse.new(raw_response, {})
    expect(r.spelling.collation).to eq 'dell ultrasharp'
  end

  it "should provide MoreLikeThis suggestions" do
    raw_response = eval(mock_response_with_more_like_this)
    r = Blacklight::SolrResponse.new(raw_response, {})
    expect(r.more_like(double(:id => '79930185'))).to have(2).items
  end

  it "should be empty when the response has no results" do
    r = Blacklight::SolrResponse.new({}, {})
    allow(r).to receive_messages(:total => 0)
    expect(r).to be_empty
  end
  
  describe "#export_formats" do
    it "should collect the unique export formats for the current response" do
      r = Blacklight::SolrResponse.new({}, {})
      allow(r).to receive_messages(documents: [double(:export_formats => { a: 1, b: 2}), double(:export_formats => { b: 1, c: 2})])
      expect(r.export_formats).to include :a, :b 
    end
  end

  def mock_query_response
    %({'responseHeader'=>{'status'=>0,'QTime'=>5,'params'=>{'facet.limit'=>'10','wt'=>'ruby','rows'=>'11','facet'=>'true','facet.field'=>['cat','manu'],'echoParams'=>'EXPLICIT','q'=>'*:*','facet.sort'=>'true'}},'response'=>{'numFound'=>26,'start'=>0,'docs'=>[{'id'=>'SP2514N','inStock'=>true,'manu'=>'Samsung Electronics Co. Ltd.','name'=>'Samsung SpinPoint P120 SP2514N - hard drive - 250 GB - ATA-133','popularity'=>6,'price'=>92.0,'sku'=>'SP2514N','timestamp'=>'2009-03-20T14:42:49.795Z','cat'=>['electronics','hard drive'],'spell'=>['Samsung SpinPoint P120 SP2514N - hard drive - 250 GB - ATA-133'],'features'=>['7200RPM, 8MB cache, IDE Ultra ATA-133','NoiseGuard, SilentSeek technology, Fluid Dynamic Bearing (FDB) motor']},{'id'=>'6H500F0','inStock'=>true,'manu'=>'Maxtor Corp.','name'=>'Maxtor DiamondMax 11 - hard drive - 500 GB - SATA-300','popularity'=>6,'price'=>350.0,'sku'=>'6H500F0','timestamp'=>'2009-03-20T14:42:49.877Z','cat'=>['electronics','hard drive'],'spell'=>['Maxtor DiamondMax 11 - hard drive - 500 GB - SATA-300'],'features'=>['SATA 3.0Gb/s, NCQ','8.5ms seek','16MB cache']},{'id'=>'F8V7067-APL-KIT','inStock'=>false,'manu'=>'Belkin','name'=>'Belkin Mobile Power Cord for iPod w/ Dock','popularity'=>1,'price'=>19.95,'sku'=>'F8V7067-APL-KIT','timestamp'=>'2009-03-20T14:42:49.937Z','weight'=>4.0,'cat'=>['electronics','connector'],'spell'=>['Belkin Mobile Power Cord for iPod w/ Dock'],'features'=>['car power adapter, white']},{'id'=>'IW-02','inStock'=>false,'manu'=>'Belkin','name'=>'iPod & iPod Mini USB 2.0 Cable','popularity'=>1,'price'=>11.5,'sku'=>'IW-02','timestamp'=>'2009-03-20T14:42:49.944Z','weight'=>2.0,'cat'=>['electronics','connector'],'spell'=>['iPod & iPod Mini USB 2.0 Cable'],'features'=>['car power adapter for iPod, white']},{'id'=>'MA147LL/A','inStock'=>true,'includes'=>'earbud headphones, USB cable','manu'=>'Apple Computer Inc.','name'=>'Apple 60 GB iPod with Video Playback Black','popularity'=>10,'price'=>399.0,'sku'=>'MA147LL/A','timestamp'=>'2009-03-20T14:42:49.962Z','weight'=>5.5,'cat'=>['electronics','music'],'spell'=>['Apple 60 GB iPod with Video Playback Black'],'features'=>['iTunes, Podcasts, Audiobooks','Stores up to 15,000 songs, 25,000 photos, or 150 hours of video','2.5-inch, 320x240 color TFT LCD display with LED backlight','Up to 20 hours of battery life','Plays AAC, MP3, WAV, AIFF, Audible, Apple Lossless, H.264 video','Notes, Calendar, Phone book, Hold button, Date display, Photo wallet, Built-in games, JPEG photo playback, Upgradeable firmware, USB 2.0 compatibility, Playback speed control, Rechargeable capability, Battery level indication']},{'id'=>'TWINX2048-3200PRO','inStock'=>true,'manu'=>'Corsair Microsystems Inc.','name'=>'CORSAIR  XMS 2GB (2 x 1GB) 184-Pin DDR SDRAM Unbuffered DDR 400 (PC 3200) Dual Channel Kit System Memory - Retail','popularity'=>5,'price'=>185.0,'sku'=>'TWINX2048-3200PRO','timestamp'=>'2009-03-20T14:42:49.99Z','cat'=>['electronics','memory'],'spell'=>['CORSAIR  XMS 2GB (2 x 1GB) 184-Pin DDR SDRAM Unbuffered DDR 400 (PC 3200) Dual Channel Kit System Memory - Retail'],'features'=>['CAS latency 2,	2-3-3-6 timing, 2.75v, unbuffered, heat-spreader']},{'id'=>'VS1GB400C3','inStock'=>true,'manu'=>'Corsair Microsystems Inc.','name'=>'CORSAIR ValueSelect 1GB 184-Pin DDR SDRAM Unbuffered DDR 400 (PC 3200) System Memory - Retail','popularity'=>7,'price'=>74.99,'sku'=>'VS1GB400C3','timestamp'=>'2009-03-20T14:42:50Z','cat'=>['electronics','memory'],'spell'=>['CORSAIR ValueSelect 1GB 184-Pin DDR SDRAM Unbuffered DDR 400 (PC 3200) System Memory - Retail']},{'id'=>'VDBDB1A16','inStock'=>true,'manu'=>'A-DATA Technology Inc.','name'=>'A-DATA V-Series 1GB 184-Pin DDR SDRAM Unbuffered DDR 400 (PC 3200) System Memory - OEM','popularity'=>5,'sku'=>'VDBDB1A16','timestamp'=>'2009-03-20T14:42:50.004Z','cat'=>['electronics','memory'],'spell'=>['A-DATA V-Series 1GB 184-Pin DDR SDRAM Unbuffered DDR 400 (PC 3200) System Memory - OEM'],'features'=>['CAS latency 3,	 2.7v']},{'id'=>'3007WFP','inStock'=>true,'includes'=>'USB cable','manu'=>'Dell, Inc.','name'=>'Dell Widescreen UltraSharp 3007WFP','popularity'=>6,'price'=>2199.0,'sku'=>'3007WFP','timestamp'=>'2009-03-20T14:42:50.017Z','weight'=>401.6,'cat'=>['electronics','monitor'],'spell'=>['Dell Widescreen UltraSharp 3007WFP'],'features'=>['30" TFT active matrix LCD, 2560 x 1600, .25mm dot pitch, 700:1 contrast']},{'id'=>'VA902B','inStock'=>true,'manu'=>'ViewSonic Corp.','name'=>'ViewSonic VA902B - flat panel display - TFT - 19"','popularity'=>6,'price'=>279.95,'sku'=>'VA902B','timestamp'=>'2009-03-20T14:42:50.034Z','weight'=>190.4,'cat'=>['electronics','monitor'],'spell'=>['ViewSonic VA902B - flat panel display - TFT - 19"'],'features'=>['19" TFT active matrix LCD, 8ms response time, 1280 x 1024 native resolution']},{'id'=>'0579B002','inStock'=>true,'manu'=>'Canon Inc.','name'=>'Canon PIXMA MP500 All-In-One Photo Printer','popularity'=>6,'price'=>179.99,'sku'=>'0579B002','timestamp'=>'2009-03-20T14:42:50.062Z','weight'=>352.0,'cat'=>['electronics','multifunction printer','printer','scanner','copier'],'spell'=>['Canon PIXMA MP500 All-In-One Photo Printer'],'features'=>['Multifunction ink-jet color photo printer','Flatbed scanner, optical scan resolution of 1,200 x 2,400 dpi','2.5" color LCD preview screen','Duplex Copying','Printing speed up to 29ppm black, 19ppm color','Hi-Speed USB','memory card: CompactFlash, Micro Drive, SmartMedia, Memory Stick, Memory Stick Pro, SD Card, and MultiMediaCard']}]},'facet_counts'=>{'facet_queries'=>{},'facet_fields'=>{'cat'=>['electronics',14,'memory',3,'card',2,'connector',2,'drive',2,'graphics',2,'hard',2,'monitor',2,'search',2,'software',2],'manu'=>['inc',8,'apach',2,'belkin',2,'canon',2,'comput',2,'corp',2,'corsair',2,'foundat',2,'microsystem',2,'softwar',2]},'facet_dates'=>{}}})
  end

  # These spellcheck responses are all Solr 1.4 responses
  def mock_response_with_spellcheck
    %|{'responseHeader'=>{'status'=>0,'QTime'=>9,'params'=>{'spellcheck'=>'true','spellcheck.collate'=>'true','wt'=>'ruby','q'=>'hell ultrashar'}},'response'=>{'numFound'=>0,'start'=>0,'docs'=>[]},'spellcheck'=>{'suggestions'=>['hell',{'numFound'=>1,'startOffset'=>0,'endOffset'=>4,'suggestion'=>['dell']},'ultrashar',{'numFound'=>1,'startOffset'=>5,'endOffset'=>14,'suggestion'=>['ultrasharp']},'collation','dell ultrasharp']}}|
  end

  def mock_response_with_spellcheck_extended
     %|{'responseHeader'=>{'status'=>0,'QTime'=>8,'params'=>{'spellcheck'=>'true','spellcheck.collate'=>'true','wt'=>'ruby','spellcheck.extendedResults'=>'true','q'=>'hell ultrashar'}},'response'=>{'numFound'=>0,'start'=>0,'docs'=>[]},'spellcheck'=>{'suggestions'=>['hell',{'numFound'=>1,'startOffset'=>0,'endOffset'=>4,'origFreq'=>0,'suggestion'=>[{'word'=>'dell','freq'=>1}]},'ultrashar',{'numFound'=>1,'startOffset'=>5,'endOffset'=>14,'origFreq'=>0,'suggestion'=>[{'word'=>'ultrasharp','freq'=>1}]},'correctlySpelled',false,'collation','dell ultrasharp']}}|
  end

  def mock_response_with_spellcheck_same_frequency
    %|{'responseHeader'=>{'status'=>0,'QTime'=>8,'params'=>{'spellcheck'=>'true','spellcheck.collate'=>'true','wt'=>'ruby','spellcheck.extendedResults'=>'true','q'=>'hell ultrashar'}},'response'=>{'numFound'=>0,'start'=>0,'docs'=>[]},'spellcheck'=>{'suggestions'=>['hell',{'numFound'=>1,'startOffset'=>0,'endOffset'=>4,'origFreq'=>1,'suggestion'=>[{'word'=>'dell','freq'=>1}]},'ultrashard',{'numFound'=>1,'startOffset'=>5,'endOffset'=>14,'origFreq'=>1,'suggestion'=>[{'word'=>'ultrasharp','freq'=>1}]},'correctlySpelled',false,'collation','dell ultrasharp']}}|
  end

  # it can be the case that extended results are off and collation is on
  def mock_response_with_spellcheck_collation
    %|{'responseHeader'=>{'status'=>0,'QTime'=>3,'params'=>{'spellspellcheck.build'=>'true','spellcheck'=>'true','q'=>'hell','spellcheck.q'=>'hell ultrashar','wt'=>'ruby','spellcheck.collate'=>'true'}},'response'=>{'numFound'=>0,'start'=>0,'docs'=>[]},'spellcheck'=>{'suggestions'=>['hell',{'numFound'=>1,'startOffset'=>0,'endOffset'=>4,'suggestion'=>['dell']},'ultrashar',{'numFound'=>1,'startOffset'=>5,'endOffset'=>14,'suggestion'=>['ultrasharp']},'collation','dell ultrasharp']}}|
  end
  
  def mock_response_with_more_like_this
    %({'responseHeader'=>{'status'=>0,'QTime'=>8,'params'=>{'facet'=>'false','mlt.mindf'=>'1','mlt.fl'=>'subject_t','fl'=>'id','mlt.count'=>'3','mlt.mintf'=>'0','mlt'=>'true','q.alt'=>'*:*','qt'=>'search','wt'=>'ruby'}},'response'=>{'numFound'=>30,'start'=>0,'docs'=>[{'id'=>'00282214'},{'id'=>'00282371'},{'id'=>'00313831'},{'id'=>'00314247'},{'id'=>'43037890'},{'id'=>'53029833'},{'id'=>'77826928'},{'id'=>'78908283'},{'id'=>'79930185'},{'id'=>'85910001'}]},'moreLikeThis'=>{'00282214'=>{'numFound'=>0,'start'=>0,'docs'=>[]},'00282371'=>{'numFound'=>0,'start'=>0,'docs'=>[]},'00313831'=>{'numFound'=>1,'start'=>0,'docs'=>[{'id'=>'96933325'}]},'00314247'=>{'numFound'=>3,'start'=>0,'docs'=>[{'id'=>'2008543486'},{'id'=>'96933325'},{'id'=>'2009373513'}]},'43037890'=>{'numFound'=>0,'start'=>0,'docs'=>[]},'53029833'=>{'numFound'=>0,'start'=>0,'docs'=>[]},'77826928'=>{'numFound'=>1,'start'=>0,'docs'=>[{'id'=>'94120425'}]},'78908283'=>{'numFound'=>0,'start'=>0,'docs'=>[]},'79930185'=>{'numFound'=>2,'start'=>0,'docs'=>[{'id'=>'94120425'},{'id'=>'2007020969'}]},'85910001'=>{'numFound'=>0,'start'=>0,'docs'=>[]}}})
  end
end
