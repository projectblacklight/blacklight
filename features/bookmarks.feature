@bookmarks
Feature: Bookmarks
  In order to collect documents
  As a user
  I want to bookmark documents
  
  Scenario: Bookmarks Menu Link
    Given I am logged in as "user1"
    Then I should see "Welcome user1!"
    When I am on the home page
    Then I should see "Your Bookmarks"
    When I follow "Your Bookmarks"
    Then I should be on the bookmarks page
    And I should see a stylesheet
  
    Scenario: No Bookmarks
      Given I am logged in as "user1"
      When I go to the bookmarks page
      Then I should see "You have no bookmarks"
      
    Scenario: Bookmarks not logged in
      When I go to the bookmarks page
      Then I should see "Please log in to manage and view your bookmarks."
  
    Scenario: User Has Bookmarks
      Given I am logged in as "user1"
      And "user1" has bookmarked an item with title "foo bar"
      When I go to the bookmarks page
      Then I should see "Your Bookmarks"
      And I should see "foo bar"

    Scenario: Deleting a Bookmark
      Given I am logged in as "user1"
      And "user1" has bookmarked an item with title "foo bar"
      And I am on the bookmarks page
      Then I should see "remove"
      When I follow "remove"
      Then I should see "Successfully removed bookmark."

    Scenario: Clearing Bookmarks
      Given I am logged in as "user1"
      And "user1" has bookmarked an item with title "foo bar"
      And "user1" has bookmarked an item with title "boo baz"
      And I am on the bookmarks page
      Then I should see "Clear Bookmarks"
      When I follow "Clear Bookmarks"
      Then I should see "Cleared your bookmarks."
      And I should see "You have no bookmarks"
      
    Scenario: Adding and removing a bookmark from search results
      Given I am logged in as "user1"
      When I am on the home page
      And I fill in "q" with "book"
      And I press "search"
      When I press "Bookmark"
      Then I should see "Successfully added bookmark."
      # We should be back on search results here, but due to
      # what I believe is a bug in Cucumber with query strings
      # and http Referer, we're not, we're on home page, so we'll
      # navigate back, sorry. 
      And I fill in "q" with "book"
      And I press "search"
      Then I press "Remove bookmark"
      And I should see "Successfully removed bookmark."
      
    Scenario: Adding and deleting bookmark from show page
      Given I am logged in as "user1"
      When I am on the document page for id 2007020969
      Then I should see a "Bookmark" button
      And I press "Bookmark"
      #Then I should see "Successfully added bookmark"
      And I should see a "Remove bookmark" button
      And I press "Remove bookmark"
      And I should see "Successfully removed bookmark"

      
    Scenario: Adding bookmarks from Folder
      Given I am logged in as "user1"
      And I have record 2007020969 in my folder
      And I have record 2008308175 in my folder
      And I follow "Selected Items"
      And I press "Add to Bookmarks"
      Then I should see "Successfully added bookmarks."
      
    Scenario: Adding bookmark from Folder
       Given I am logged in as "user1"
       And I have record 2007020969 in my folder
       And I follow "Selected Items"
       And I press "Add to Bookmarks"
       Then I should see "Successfully added bookmarks."
