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
  
    Scenario: No Bookmarks
      Given I am logged in as "user1"
      When I go to the bookmarks page
      Then I should see "You have no bookmarks"
      
    Scenario: Bookmarks not logged in
      When I go to the bookmarks page
      Then I should see "Please log in to see your bookmarks."
      And I should not see "delete"
      And I should not see "Clear bookmarks"
  
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
      Then I should see "Successfully removed that bookmark."

    Scenario: Clearing Bookmarks
      Given I am logged in as "user1"
      And "user1" has bookmarked an item with title "foo bar"
      And "user1" has bookmarked an item with title "boo baz"
      And I am on the bookmarks page
      Then I should see "Clear Bookmarks"
      When I follow "Clear Bookmarks"
      Then I should see "Cleared your bookmarks."
      And I should see "You have no bookmarks"
      
    Scenario: Adding a bookmark from search results
      Given I am logged in as "user1"
      When I am on the home page
      And I fill in "q" with "book"
      And I press "search"
      When I press "Bookmark this item"
      Then I should see "Successfully added bookmark."
    
