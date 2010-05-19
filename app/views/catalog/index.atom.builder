require 'base64'

xml.instruct!(:xml, :encoding => "UTF-8")

xml.feed "xmlns" => "http://www.w3.org/2005/Atom" do

  xml.title   application_name + " Search Results"
  # an author is required, so we'll just use the app name
  xml.author application_name
  
  xml.link    "rel" => "self", "href" => url_for(params.merge(:only_path => false))
  xml.link    "rel" => "alternate", "href" => url_for(params.merge(:only_path => false, :format => "html")), "type" => "text/html"
  xml.id      url_for(params.merge(:only_path => false, :format => "html")), "type" => "text/html"

  # updated is required, for now we'll just set it to now, sorry
  xml.updated Time.now.strftime("%Y-%m-%dT%H:%M:%SZ")
  
  @document_list.each do |doc|
    xml.entry do
      xml.title   doc.to_semantic_values[:title][0] || doc[:id]

      # updated is required, for now we'll just set it to now, sorry
      xml.updated Time.now.strftime("%Y-%m-%dT%H:%M:%SZ")
      
      xml.link    "rel" => "alternate", "type" => "text/html", "href" => catalog_url(doc[:id])
      # add other doc-specific formats, atom only lets us have one per
      # content type, so the first one in the list wins.
      seen = Set.new
      doc.export_formats.each_pair do |format, spec|
        unless seen.include?( spec[:content_type] )      
          xml.link "rel" => "alternate", "type" => spec[:content_type], :href => catalog_url(doc[:id], format)
          seen.add( spec[:content_type])
        end
      end
      
      
      xml.id      catalog_url(doc[:id])
      
      
      if doc.to_semantic_values[:author][0]   
        xml.author(doc.to_semantic_values[:author][0])
      end
      
      
      # xml.summary "type" => "html" do
        # xml.text! render_document_partial(doc, :index)
      # end

      #If they asked for a format, give it to them. 
      if (params["content_format"] &&
          doc.export_formats[params["content_format"].to_sym])
          
          type = doc.export_formats[params["content_format"].to_sym][:content_type]
          
          xml.content :type => type do |content_element|
            data = doc.export_as(params["content_format"])
                    
            # encode properly. See:
            # http://tools.ietf.org/html/rfc4287#section-4.1.3.3
            type = type.downcase
            if (type.downcase =~ /\+|\/xml$/)
              # xml, just put it right in              
              content_element << data
            elsif (type.downcase =~ /text\//)
              # text, escape
              content_element.text! data
            else
              #something else, base64 encode it
              content_element << Base64.encode64(data)
            end
          end
          
      end

      
    end
  end

end





