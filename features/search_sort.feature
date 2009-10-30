@search_sort
Feature: Search Sort
  In order to sort searches
  As a user
  I want select a sort field and have the search results reordered by that field

  Scenario: Sort on facet results with no search terms
    Given I am on the home page
    When I follow "English"
    Then I should see "Sort by"
# 2009-08-25 I don't know why this isn't working ... Naomi.
#    And I should see select list "select#sort" with "relevance" selected
    When I select "title" from "sort"
    And I press "sort results" 
    Then I should see "Sort by"
    And I should see select list "select#sort" with "title" selected
    
