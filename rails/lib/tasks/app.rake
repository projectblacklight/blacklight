namespace :app do
  
  def fetch_env_file
    f = ENV['FILE']
    raise "Invalid file. Set the by using the FILE argument." unless File.exists?(f)
    f
  end
  
  namespace :index do
    
    desc 'Index a marc file at FILE=<location-of-file> using the lib/marc_mapper class.'
    task :marc => :environment do
      
      t = Time.now
      
      marc_file = fetch_env_file
      
      solr = Blacklight.solr
      
      MARCMapper.from_marc_file(marc_file) do |doc,index|
        puts "#{index} -- adding doc w/id : #{doc[:id]} to Solr"
        solr.add(doc)
      end
      
      puts "Sending commit to Solr..."
      solr.commit
      puts "Complete."
      
      puts "Total Time: #{Time.now - t}"
      
    end
    
    #######################
    
    desc "Index an EAD file at FILE=<location-of-file> using the lib/ead_mapper class."
    task :ead=>:environment do
      
      require 'nokogiri'
      
      t = Time.now
      
      raw = File.read(fetch_env_file)
      # remove the default namespace,
      # otherwise every query needs a "default:" prefix,
      # and a namespace option
      raw.gsub!(/xmlns=".*"/, '')
      
      xml = Nokogiri::XML(raw)
      BASE_ID = xml.at('/ead/eadheader/eadid').text.gsub(/\.xml/, '')
      
      Blacklight.solr.delete_by_query "base_id_s:\"#{BASE_ID}\""
      Blacklight.solr.commit
      
      def id(v)
        BASE_ID + '-' + v.downcase.gsub(/\/+/, '_').gsub(/;+|\.+/, '')
      end
      
      base_doc = {
        :format_code_t => 'ead',
        :format_facet => 'EAD',
        :title_t => xml.at('//archdesc[@level="collection"]/did/unittitle').text,
        :institution_t => xml.at('//publicationstmt/publisher').text,
        :language_facet => xml.at('//profiledesc/langusage/language').text.gsub(/\.$/, ''),
        :ead_filename_s => xml.at('//eadheader/eadid').text,
        :base_id_s => BASE_ID
      }
      
      # all solr docs
      solr_docs = []
      
      # the table of contents container
      toc = []
      
      # SUMMARY
      summary_doc = base_doc.dup
      summary_doc[:xml_display] = xml.at("/ead/archdesc/did").to_xml
      summary_doc[:id] = id('summary')
      summary_doc[:title_t] = "#{summary_doc[:title_t]}: Summary Information"
      solr_docs << summary_doc
      toc << {:label=>'Summary Information', :id=>summary_doc[:id], :children=>[]}
      
      create_desc_item = lambda{|node_name, id_suffix|
        doc = base_doc.dup
        node = xml.at('/ead/archdesc/' + node_name)
        break unless node
        doc[:xml_display] = node.to_xml
        doc[:id] = id(id_suffix)
        label = node.at('head').text rescue node_name
        doc[:title_t] = "#{doc[:title_t]}: #{label}"
        solr_docs << doc
        toc << {:label=>label, :id=>doc[:id], :children=>[]}
      }
      
      create_desc_item.call('bioghist', 'Biography/History')
      create_desc_item.call('scopecontent', 'Scope and Content')
      create_desc_item.call('arrangement', 'Arrangement')
      create_desc_item.call('fileplan', 'File Plan')
      
      toc << {:label => 'Collection Inventory', :id=>nil, :children=>[]}
      
      xml.search('ead/archdesc/dsc').each do |n|
        n.search('c[@level="series"]').each_with_index do |s,index|
          sdoc = base_doc.dup
          sdoc[:id] = id(s['id'])
          sdoc[:xml_display] = s.to_xml
          sdoc[:title_t] = "#{sdoc[:title_t]}: #{s.at('did/unittitle').text}"
          solr_docs << sdoc
          toc.last[:id] ||= sdoc[:id]
          toc.last[:children] << {:label=>s.at('did/unittitle').text, :id=>sdoc[:id], :children=>[]}
        end
      end
      
      json_file = File.join(RAILS_ROOT, 'tmp', 'cache', 'json-toc', "#{BASE_ID}.json")
      FileUtils.mkdir_p File.dirname(json_file)
      
      File.open(json_file, File::CREAT|File::TRUNC|File::WRONLY) do |f|
        f.puts toc.to_json
      end
      
      Blacklight.solr.add solr_docs
      Blacklight.solr.commit
      
    end
    
  end
  
end