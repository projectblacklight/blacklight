@search
Feature: Search
  In order to find documents
  As a user
  I want to enter terms, select fields, and select number of results per page
  
  Scenario: Search Page
    When I go to the catalog page
    Then I should see a search field
    And I should see a selectable list with field choices
    And I should see a "search" button
    And I should not see the "startOverLink" element
    And I should see "Welcome!"
    And I should see a stylesheet
  
  Scenario: Search Page's type of search ("fielded search") choices
    When I am on the home page
    Then I should see select list "select#search_field" with field labels "All Fields, Title, Author, Subject"
  
  Scenario: Submitting a Search
    When I am on the home page
    And I fill in "q" with "history"
    And I select "All Fields" from "search_field"
    And I press "search"
    Then I should be on "the catalog page"
    And I should see an rss discovery link
    And I should see "You searched for:"
    And I should see "All Fields"
    And I should see "history"
    And I should see select list "select#search_field" with "All Fields" selected
    And I should see "per page"
    And I should see a selectable list with per page choices
    And I should see "1."
    And I should see "2."
    And I should see "3."
    And I should see "Sort by"
    

  Scenario: Submitting a Search with specific field selected
    When I am on the home page
    And I fill in "q" with "inmul"
    And I select "Title" from "search_field"
    And I press "search"
    Then I should be on "the catalog page"
    And I should see "You searched for:"
    And I should see "Title"
    And I should see "inmul"
    And I should see select list "select#search_field" with "Title" selected
    And I should see "1."
    And I should see "Displaying 1 item"

  Scenario: Results Page Shows Vernacular (Linked 880) Fields
    Given I am on the home page
    And I fill in "q" with "history"
    When I press "search"
    Then I should see "次按驟變"

  Scenario: Results Page Shows Call Numbers
    Given I am on the home page
    And I fill in "q" with "history"
    When I press "search"
    Then I should see "Call number:"
    And I should see "DK861.K3 V5"

  Scenario: Results Page Has Sorting Available
    Given I am on the home page
    And I fill in "q" with "history"
    When I press "search"
    Then I should see select list "select#sort" with field labels "relevance, year, author, title"
  
  Scenario: Can clear a search
    When I am on the home page
    And I fill in "q" with "history"
    And I press "search"
    Then I should be on "the catalog page"
    And I should see "You searched for:"
    And I should see "All Fields"
    And I should see "history"
    And the "search" field should contain "history"
    When I follow "start over"
    Then I should be on "the catalog page"
    And I should see "Welcome!"
    And the "search" field should not contain "history"
    
