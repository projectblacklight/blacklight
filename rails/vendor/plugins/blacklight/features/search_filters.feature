Feature: Search Filters
  In order constrain searches
  As a user
  I want to filter search results via facets on the search page
  
  Scenario: Filter a blank search
    Given I am on the home page
    When I follow "Tibetan"
    Then I should see "6 results sorted by"
    And I should see "Your empty search limited to"
    And I should see "Language: Tibetan"
    And I should not see "Subject - Geographic: India"
    When I follow "India"
    Then I should see "2 results sorted by"
    And I should see "Subject - Geographic: India"
    And I should see "Language: Tibetan"
  
  Scenario: Search with no filters applied
    When I am on the home page
    And I fill in "q" with "bod"
    And I press "search"
    Then I should be on "the catalog page"
    And I should see "3 results sorted by"
    And I should not see "Your empty search limited to"
    And I should see "You searched for bod"
  
  Scenario: Search with filters applied
    When I am on the home page
    And I fill in "q" with "history"
    And I press "search"
    Then I should be on "the catalog page"
    And I should see "6 results sorted by"
    And I should not see "Your empty search limited to"
    And I should see "You searched for history"
    When I follow "Tibetan"
    Then I should see "2 results sorted by"
    And I should see "You searched for history limited to"
    And I should see "Language: Tibetan"
    When I follow "Kings and rulers"
    Then I should see "1 result"
    And I should see "You searched for history limited to"
    And I should see "Language: Tibetan"
    And I should see "Subject - Geographic: Kings and rulers"
  
  Scenario: Apply and remove filters
    Given I am on the home page
    When I follow "Tibetan"
    Then I should see "Your empty search limited to"
    And I should see "Language: Tibetan [remove]"
    When I follow "remove"
    Then I should not see "Your empty search limited to"
    And I should not see "Language: Tibetan [remove]"
  
  Scenario: Changing search term should retain filters
    When I am on the home page
    And I fill in "q" with "history"
    And I press "search"
    Then I should be on "the catalog page"
    And I should see "You searched for history"
    When I follow "Tibetan"
    And I should see "You searched for history limited to"
    And I should see "Language: Tibetan"
    When I follow "Kings and rulers"
    And I should see "You searched for history limited to"
    And I should see "Language: Tibetan"
    And I should see "Subject - Geographic: Kings and rulers"
    When I fill in "q" with "book"
    And I press "search"
    Then I should be on "the catalog page"
    And I should see "You searched for book limited to"
    And I should see "Language: Tibetan"
    And I should see "Subject - Geographic: Kings and rulers"
  
  Scenario: Sorting results should retain filters
    When I am on the home page
    And I fill in "q" with "history"
    And I press "search"
    Then I should be on "the catalog page"
    And I should see "You searched for history"
    When I follow "Tibetan"
    And I should see "You searched for history limited to"
    And I should see "Language: Tibetan"
    When I select "title" from "sort"
    And I press "sort results" 
    Then I should be on "the catalog page"
    And I should see "You searched for history limited to"
    And I should see "Language: Tibetan"
  
  Scenario: Changing per page number should retain filters
    When I am on the home page
    And I fill in "q" with "history"
    And I press "search"
    Then I should be on "the catalog page"
    And I should see "You searched for history"
    When I follow "Tibetan"
    And I should see "You searched for history limited to"
    And I should see "Language: Tibetan"
    When I select "20" from "per_page"
    And I press "update" 
    Then I should be on "the catalog page"
    And I should see "You searched for history limited to"
    And I should see "Language: Tibetan"
  
