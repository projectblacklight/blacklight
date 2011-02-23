Given /^"([^\"]*)" has bookmarked an item with title "([^\"]*)"$/ do |user, title|
  user = User.find_by_login(user)
  Bookmark.create(:user_id => user.id, :title => title, :document_id => "123456")
end
