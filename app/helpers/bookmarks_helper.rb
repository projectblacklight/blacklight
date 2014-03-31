module BookmarksHelper

  # A URL to refworks export, with an embedded callback URL to this app. 
  # the callback URL is to bookmarks#export, which delivers a list of 
  # user's bookmarks in 'refworks marc txt' format -- we tell refworks
  # to expect that format. 
  def bookmarks_refworks_export_url(user_id = current_or_guest_user.id)
    callback_url =  bookmarks_url(params_for_search.merge(format: :refworks_marc_txt, encrypted_user_id: encrypt_user_id(current_or_guest_user.id) ))

    "http://www.refworks.com/express/expressimport.asp?vendor=#{CGI.escape(application_name)}&filter=MARC%20Format&encoding=65001&url=#{CGI.escape(callback_url)}"
  end
end
