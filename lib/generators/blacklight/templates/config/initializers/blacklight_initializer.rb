# A secret token used to encrypt user_id's in the Bookmarks#export callback URL
# functionality, for example in Refworks export of Bookmarks. In Rails 4, Blacklight
# will use the application's secret key base instead.
#
<% if Rails::VERSION::MAJOR == 4 %>
# Blacklight.secret_key = '<%= SecureRandom.hex(64) %>'
<% else %>
Blacklight.secret_key = '<%= SecureRandom.hex(64) %>'
<% end %>
