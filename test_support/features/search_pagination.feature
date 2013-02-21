@search_pagination
Feature: Search Pagination
  In order to find lower ranked documents
  As a user
  I want to be able to page through search results and be able to choose how
  many documents to display per page

  Background:
    Given the application is configured to have per page with values "10, 20, 50"

  Scenario: Results Page Supports Paging
    Given I am on the home page
    When I fill in "q" with ""
    And I press "search"
    Then I should see "1 - 10 of"
    When I follow "Next »"
    Then I should see "11 - 20 of"
    When I follow "« Previous"
    Then I should see "1 - 10 of"

  Scenario: Results Page Has Per Page Available
    Given I am on the home page
    When I fill in "q" with ""
    And I press "search"
    Then I should see "per page"
    And I should see the per_page dropdown with values "10, 20, 50"

  Scenario: Results Page Can Display 20 Items Per Page
    Given I am on the home page
    And I fill in "q" with ""
    When I press "search"
    Then I should see "1 - 10 of"
    When I show 20 per page
    Then I should see "1 - 20 of"

  Scenario: Application Can Be Configured for Other Per Page Values
    Given the application is configured to have per page with values "15, 30"
    And I am on the home page
    When I fill in "q" with ""
    And I press "search"
    Then I should see the per_page dropdown with values "15, 30"
    And I should see "1 - 15 of"
    When I show 30 per page
    Then I should see "1 - 30 of"

  Scenario: Page Offset Resets to 1 When Changing Per Page
    Given I am on the home page
    And I fill in "q" with ""
    When I press "search"
    And I follow "Next »"
    Then I should see "11 - 20 of"
    When I show 20 per page
    Then I should see "1 - 20 of"
