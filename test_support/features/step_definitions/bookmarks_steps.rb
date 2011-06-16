# -*- encoding : utf-8 -*-
Given /^"([^\"]*)" has bookmarked an item with title "([^\"]*)"$/ do |user, title|
  user = User.find_by_email("#{user}@#{user}.com")
  user.bookmarks <<  Bookmark.create(:title => title, :document_id => "123456")
  user.save!
end
