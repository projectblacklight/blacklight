module Blacklight::Marc::Citation
  
  def to_apa
    return nil if self.marc.blank?
    apa_citation(self.marc)
  end
  
  def to_mla
    return nil if self.marc.blank?
    mla_citation(self.marc)
  end

  protected
  
  def mla_citation(record)
    text = ''
    authors_final = []
    
    #setup formatted author list
    authors = get_author_list(record)

    if authors.length < 4
      authors.each do |l|
        if l == authors.first #first
          authors_final.push(l)
        elsif l == authors.last #last
          authors_final.push(", and " + name_reverse(l) + ".")
        else #all others
          authors_final.push(", " + name_reverse(l))
        end
      end
      text += authors_final.join
      unless text.blank?
        if text[-1,1] != "."
          text += ". "
        else
          text += " "
        end
      end
    else
      text += authors.first + ", et al. "
    end
    # setup title
    title = setup_title_info(record)
    if !title.nil?
      text += "<u>" + mla_citation_title(title) + "</u> "
    end

    # Edition
    edition_data = setup_edition(record)
    text += edition_data + " " unless edition_data.nil?
    
    # Publication
    text += setup_pub_info(record) + ", " unless setup_pub_info(record).nil?
    
    # Get Pub Date
    text += setup_pub_date(record) unless setup_pub_date(record).nil?
    if text[-1,1] != "."
      text += "." unless text.nil? or text.blank?
    end
    text
  end

  def apa_citation(record)
    text = ''
    authors_list = []
    authors_list_final = []
    
    #setup formatted author list
    authors = get_author_list(record)
    authors.each do |l|
      authors_list.push(abbreviate_name(l)) unless l.nil?
    end
    authors_list.each do |l|
      if l == authors_list.first #first
        authors_list_final.push(l.strip)
      elsif l == authors_list.last #last
        authors_list_final.push(", &amp; " + l.strip)
      else #all others
        authors_list_final.push(", " + l.strip)
      end
    end
    text += authors_list_final.join
    unless text.blank?
      if text[-1,1] != "."
        text += ". "
      else
        text += " "
      end
    end
    # Get Pub Date
    text += "(" + setup_pub_date(record) + "). " unless setup_pub_date(record).nil?
    
    # setup title info
    title = setup_title_info(record)
    text += "<i>" + title + "</i> " unless title.nil?
    
    # Edition
    edition_data = setup_edition(record)
    text += edition_data + " " unless edition_data.nil?
    
    # Publisher info
    text += setup_pub_info(record) unless setup_pub_info(record).nil?
    unless text.blank?
      if text[-1,1] != "."
        text += "."
      end
    end
    text
  end
  def setup_pub_date(record)
    if !record.find{|f| f.tag == '260'}.nil?
      pub_date = record.find{|f| f.tag == '260'}
      if pub_date.find{|s| s.code == 'c'}
        date_value = pub_date.find{|s| s.code == 'c'}.value.gsub(/[^0-9]/, "") unless pub_date.find{|s| s.code == 'c'}.value.gsub(/[^0-9]/, "").blank?
      end
      return nil unless !date_value.nil?
    end
    date_value
  end
  def setup_pub_info(record)
    text = ''
    pub_info_field = record.find{|f| f.tag == '260'}
    if !pub_info_field.nil?
      a_pub_info = pub_info_field.find{|s| s.code == 'a'}
      b_pub_info = pub_info_field.find{|s| s.code == 'b'}
      a_pub_info = clean_end_punctuation(a_pub_info.value.strip) unless a_pub_info.nil?
      b_pub_info = b_pub_info.value.strip unless b_pub_info.nil?
      text += a_pub_info.strip unless a_pub_info.nil?
      if !a_pub_info.nil? and !b_pub_info.nil?
        text += ": "
      end
      text += b_pub_info.strip unless b_pub_info.nil?
    end
    return nil if text.strip.blank?
    clean_end_punctuation(text.strip)
  end

  def mla_citation_title(text)
    no_upcase = ["a","an","but","by","for","it","of","the","to"]
    new_text = []
    word_parts = text.split(" ")
    word_parts.each do |w|
      if !no_upcase.include? w
        new_text.push(w.capitalize)
      else
        new_text.push(w)
      end
    end
    new_text.join(" ")
  end

  def setup_title_info(record)
    text = ''
    title_info_field = record.find{|f| f.tag == '245'}
    if !title_info_field.nil?
      a_title_info = title_info_field.find{|s| s.code == 'a'}
      b_title_info = title_info_field.find{|s| s.code == 'b'}
      a_title_info = clean_end_punctuation(a_title_info.value.strip) unless a_title_info.nil?
      b_title_info = clean_end_punctuation(b_title_info.value.strip) unless b_title_info.nil?
      text += a_title_info unless a_title_info.nil?
      if !a_title_info.nil? and !b_title_info.nil?
        text += ": "
      end
      text += b_title_info unless b_title_info.nil?
    end
    
    return nil if text.strip.blank?
    clean_end_punctuation(text.strip) + "."
    
  end
  
  def clean_end_punctuation(text)
    if [".",",",":",";","/"].include? text[-1,1]
      return text[0,text.length-1]
    end
    text
  end  

  def setup_edition(record)
    edition_field = record.find{|f| f.tag == '250'}
    edition_code = edition_field.find{|s| s.code == 'a'} unless edition_field.nil?
    edition_data = edition_code.value unless edition_code.nil?
    if edition_data.nil? or edition_data == '1st ed.'
      return nil
    else
      return edition_data
    end    
  end
  
  def get_author_list(record)
    author_list = []
    authors_primary = record.find{|f| f.tag == '100'}
    author_primary = authors_primary.find{|s| s.code == 'a'}.value unless authors_primary.nil?
    author_list.push(clean_end_punctuation(author_primary)) unless author_primary.nil?
    authors_secondary = record.find_all{|f| ('700') === f.tag}
    if !authors_secondary.nil?
      authors_secondary.each do |l|
        author_list.push(clean_end_punctuation(l.find{|s| s.code == 'a'}.value)) unless l.find{|s| s.code == 'a'}.value.nil?
      end
    end

    author_list.uniq!
    author_list
  end
  
  def abbreviate_name(name)
    name_parts = name.split(", ")
    first_name_parts = name_parts.last.split(" ")
    temp_name = name_parts.first + ", " + first_name_parts.first[0,1] + "."
    first_name_parts.shift
    temp_name += " " + first_name_parts.join(" ") unless first_name_parts.empty?
    temp_name
  end

  def name_reverse(name)
    name = clean_end_punctuation(name)
    temp_name = name.split(", ")
    return temp_name.last + " " + temp_name.first
  end 
end