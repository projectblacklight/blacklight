xml.instruct!
xml.formats(({:id => @document.id} if @document) || {}) do
  @export_formats.each do |shortname, meta|
    xml.format :name => shortname, :type => meta[:content_type]
  end
end
