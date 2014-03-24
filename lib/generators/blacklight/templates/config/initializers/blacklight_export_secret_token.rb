# A secret token used to encrypt user_id's in the Bookmarks#export callback URL
# functionality, for example in Refworks export of Bookmarks. 
Rails.application.config.blacklight_export_secret_token = '<%= SecureRandom.hex(64) %>'