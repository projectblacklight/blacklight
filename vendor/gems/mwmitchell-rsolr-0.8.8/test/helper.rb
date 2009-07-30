
require File.join(File.dirname(__FILE__), '..', 'lib', 'rsolr')
require 'test/unit'

# 
class Test::Unit::TestCase
  
  def self.test(name, &block)
    test_name = "test_#{name.gsub(/\s+/,'_')}".to_sym
    defined = instance_method(test_name) rescue false
    raise "#{test_name} is already defined in #{self}" if defined
    if block_given?
      define_method(test_name, &block)
    else
      define_method(test_name) do
        flunk "No implementation provided for #{name}"
      end
    end
  end
  
end

class RSolrBaseTest < Test::Unit::TestCase
  
  def assert_class(expected, instance)
    assert_equal expected, instance.class
  end
  
  def default_test
    
  end
  
end

begin
  require 'rubygems'
  require 'redgreen'
rescue LoadError
end

def mock_query_response
  %({'responseHeader'=>{
    'status'=>0,'QTime'=>43,'params'=>{
      'q'=>'*:*','wt'=>'ruby','echoParams'=>'EXPLICIT'
    }
  },
  'response'=>{
    'numFound'=>26,'start'=>0,'docs'=>[
      {'id'=>'SP2514N','inStock'=>true,'manu'=>'Samsung Electronics Co. Ltd.','name'=>'Samsung SpinPoint P120 SP2514N - hard drive - 250 GB - ATA-133','popularity'=>6,'price'=>92.0,'sku'=>'SP2514N','timestamp'=>'2008-11-21T17:21:55.601Z','cat'=>['electronics','hard drive'],'spell'=>['Samsung SpinPoint P120 SP2514N - hard drive - 250 GB - ATA-133'],'features'=>['7200RPM, 8MB cache, IDE Ultra ATA-133','NoiseGuard, SilentSeek technology, Fluid Dynamic Bearing (FDB) motor']},
      {'id'=>'6H500F0','inStock'=>true,'manu'=>'Maxtor Corp.','name'=>'Maxtor DiamondMax 11 - hard drive - 500 GB - SATA-300','popularity'=>6,'price'=>350.0,'sku'=>'6H500F0','timestamp'=>'2008-11-21T17:21:55.617Z','cat'=>['electronics','hard drive'],'spell'=>['Maxtor DiamondMax 11 - hard drive - 500 GB - SATA-300'],'features'=>['SATA 3.0Gb/s, NCQ','8.5ms seek','16MB cache']},
      {'id'=>'F8V7067-APL-KIT','inStock'=>false,'manu'=>'Belkin','name'=>'Belkin Mobile Power Cord for iPod w/ Dock','popularity'=>1,'price'=>19.95,'sku'=>'F8V7067-APL-KIT','timestamp'=>'2008-11-21T17:21:55.652Z','weight'=>4.0,'cat'=>['electronics','connector'],'spell'=>['Belkin Mobile Power Cord for iPod w/ Dock'],'features'=>['car power adapter, white']},
      {'id'=>'IW-02','inStock'=>false,'manu'=>'Belkin','name'=>'iPod & iPod Mini USB 2.0 Cable','popularity'=>1,'price'=>11.5,'sku'=>'IW-02','timestamp'=>'2008-11-21T17:21:55.657Z','weight'=>2.0,'cat'=>['electronics','connector'],'spell'=>['iPod & iPod Mini USB 2.0 Cable'],'features'=>['car power adapter for iPod, white']},
      {'id'=>'MA147LL/A','inStock'=>true,'includes'=>'earbud headphones, USB cable','manu'=>'Apple Computer Inc.','name'=>'Apple 60 GB iPod with Video Playback Black','popularity'=>10,'price'=>399.0,'sku'=>'MA147LL/A','timestamp'=>'2008-11-21T17:21:55.681Z','weight'=>5.5,'cat'=>['electronics','music'],'spell'=>['Apple 60 GB iPod with Video Playback Black'],'features'=>['iTunes, Podcasts, Audiobooks','Stores up to 15,000 songs, 25,000 photos, or 150 hours of video','2.5-inch, 320x240 color TFT LCD display with LED backlight','Up to 20 hours of battery life','Plays AAC, MP3, WAV, AIFF, Audible, Apple Lossless, H.264 video','Notes, Calendar, Phone book, Hold button, Date display, Photo wallet, Built-in games, JPEG photo playback, Upgradeable firmware, USB 2.0 compatibility, Playback speed control, Rechargeable capability, Battery level indication']},
      {'id'=>'TWINX2048-3200PRO','inStock'=>true,'manu'=>'Corsair Microsystems Inc.','name'=>'CORSAIR  XMS 2GB (2 x 1GB) 184-Pin DDR SDRAM Unbuffered DDR 400 (PC 3200) Dual Channel Kit System Memory - Retail','popularity'=>5,'price'=>185.0,'sku'=>'TWINX2048-3200PRO','timestamp'=>'2008-11-21T17:21:55.706Z','cat'=>['electronics','memory'],'spell'=>['CORSAIR  XMS 2GB (2 x 1GB) 184-Pin DDR SDRAM Unbuffered DDR 400 (PC 3200) Dual Channel Kit System Memory - Retail'],'features'=>['CAS latency 2,	2-3-3-6 timing, 2.75v, unbuffered, heat-spreader']},
      {'id'=>'VS1GB400C3','inStock'=>true,'manu'=>'Corsair Microsystems Inc.','name'=>'CORSAIR ValueSelect 1GB 184-Pin DDR SDRAM Unbuffered DDR 400 (PC 3200) System Memory - Retail','popularity'=>7,'price'=>74.99,'sku'=>'VS1GB400C3','timestamp'=>'2008-11-21T17:21:55.71Z','cat'=>['electronics','memory'],'spell'=>['CORSAIR ValueSelect 1GB 184-Pin DDR SDRAM Unbuffered DDR 400 (PC 3200) System Memory - Retail']},
      {'id'=>'VDBDB1A16','inStock'=>true,'manu'=>'A-DATA Technology Inc.','name'=>'A-DATA V-Series 1GB 184-Pin DDR SDRAM Unbuffered DDR 400 (PC 3200) System Memory - OEM','popularity'=>5,'sku'=>'VDBDB1A16','timestamp'=>'2008-11-21T17:21:55.712Z','cat'=>['electronics','memory'],'spell'=>['A-DATA V-Series 1GB 184-Pin DDR SDRAM Unbuffered DDR 400 (PC 3200) System Memory - OEM'],'features'=>['CAS latency 3,	 2.7v']},
      {'id'=>'3007WFP','inStock'=>true,'includes'=>'USB cable','manu'=>'Dell, Inc.','name'=>'Dell Widescreen UltraSharp 3007WFP','popularity'=>6,'price'=>2199.0,'sku'=>'3007WFP','timestamp'=>'2008-11-21T17:21:55.724Z','weight'=>401.6,'cat'=>['electronics','monitor'],'spell'=>['Dell Widescreen UltraSharp 3007WFP'],'features'=>['30" TFT active matrix LCD, 2560 x 1600, .25mm dot pitch, 700:1 contrast']},
      {'id'=>'VA902B','inStock'=>true,'manu'=>'ViewSonic Corp.','name'=>'ViewSonic VA902B - flat panel display - TFT - 19"','popularity'=>6,'price'=>279.95,'sku'=>'VA902B','timestamp'=>'2008-11-21T17:21:55.734Z','weight'=>190.4,'cat'=>['electronics','monitor'],'spell'=>['ViewSonic VA902B - flat panel display - TFT - 19"'],'features'=>['19" TFT active matrix LCD, 8ms response time, 1280 x 1024 native resolution']}]
    }
  })
end