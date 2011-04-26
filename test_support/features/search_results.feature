@search
Feature: Search Results
  In order to find documents
  As a user
  I want to enter terms, select fields, and select number of results per page
  
    Scenario: Empty query
      Given I am on the catalog page
      When I fill in the search box with ""
      And I press "search"
      Then I should get at least 30 results
      And I should get exactly 30 results
      And I should get at most 30 results
      And I should get id "00282214" in the results
      And I should have more results than a search for "korea"

    Scenario: "inmul" query
      Given I am on the catalog page
      When I fill in the search box with "inmul"
      And I press "search"
      Then I should get exactly 1 result
      And I should get id "77826928" in the results
      And I should not get id "00282214" in the results
      And I should have fewer results than a search for ""

    Scenario: Diacritics stripping  
      Given I am on the catalog page
      When I fill in the search box with "inmül"
      And I press "search"
      Then I should have the same number of results as a search for "inmul"


    Scenario: case-insensitive
      Given I am on the catalog page
      When I fill in the search box with "inmul"
      And I press "search"
      Then I should have the same number of results as a search for "INMUL"

    Scenario: Relevancy ordering
        Given I am on the catalog page
        When I fill in the search box with "Korea"
        And I press "search"
        Then I should get id "77826928" in the first 5 results
        And I should get id "77826928" before id "94120425"
        And I should get id "77826928" and id "94120425" no more than 5 positions from each other

    Scenario: Excluded items
        Given I am on the catalog page
        When I fill in the search box with "Korea"
        And I press "search"
        Then I should not get id "94120425" in the first 1 result

    Scenario: Top 5 results
        Given I am on the catalog page
        When I fill in the search box with "Korea"
        And I press "search"
        Then I should get at least 1 of these ids in the first 5 results: "77826928,94120425"



        
