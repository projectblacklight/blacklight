Feature: Search Filters
  In order constrain searches
  As a user
  I want to filter search results via facets on the search page
  
  Scenario: Filter a blank search
    Given I am on the home page
    When I follow "Tibetan"
    Then I should see "Displaying all 6 items"
    And I should see "No Keywords"
    And I should see the applied filter "Language" with the value "Tibetan (6)"
    When I follow "India"
    Then I should see "Displaying all 2 items"
    And I should see the applied filter "Language" with the value "Tibetan (2)"
    And I should see the applied filter "Subject - Geographic" with the value "India (2)"
  
  Scenario: Search with no filters applied
    When I am on the home page
    And I fill in "q" with "bod"
    And I press "search"
    Then I should be on "the catalog page"
    And I should see "Displaying all 3 items"
    And I should not see "No Keywords"
    And I should see "You searched for:"
    And I should see "Keyword"
    And I should see "bod"
  
  Scenario: Search with filters applied
    When I am on the home page
    And I fill in "q" with "history"
    And I press "search"
    Then I should be on "the catalog page"
    And I should see "Displaying all 6 items"
    And I should not see "No Keywords"
    And I should see "You searched for:"
    And I should see "Keyword"
    And I should see "history"
    When I follow "Tibetan"
    Then I should see "Displaying all 2 items"
    And I should see the applied filter "Language" with the value "Tibetan (2)"
    And I should see "Keyword"
    And I should see "history"
    When I follow "Kings and rulers"
    Then I should see "Displaying 1 item"
    And I should see "You searched for:"
    And I should see the applied filter "Language" with the value "Tibetan (1)"
    And I should see the applied filter "Subject - Geographic" with the value "Kings and rulers (1)"
  
  Scenario: Apply and remove filters
    Given I am on the home page
    When I follow "Tibetan"
    Then I should see "No Keywords"
    And I should see "Language"
    And I should see "Tibetan (6)"
    And I should see "[remove]"
    When I follow "remove"
    Then I should not see "You searched for:"
    And I should not see "Language: Tibetan [remove]"
  	And I should see "Welcome!"

  Scenario: Changing search term should retain filters
    When I am on the home page
    And I fill in "q" with "history"
    And I press "search"
    Then I should be on "the catalog page"
    And I should see "You searched for:"
	And I should see "history"
    When I follow "Tibetan"
    Then I should see "You searched for:"
 	And I should see "history"
    And I should see the applied filter "Language" with the value "Tibetan (2)"
    When I follow "Kings and rulers"
    And I should see "You searched for:"
	And I should see "history"
    And I should see the applied filter "Language" with the value "Tibetan (1)"
    And I should see the applied filter "Subject - Geographic" with the value "Kings and rulers (1)"
    When I fill in "q" with "book"
    And I press "search"
    Then I should be on "the catalog page"
    And I should see "Keyword"
	And I should see "book"
    And I should see the applied filter "Language" with the value "Tibetan (1)"
    And I should see the applied filter "Subject - Geographic" with the value "Kings and rulers (1)"

  
  Scenario: Sorting results should retain filters
    When I am on the home page
    And I fill in "q" with "history"
    And I press "search"
    Then I should be on "the catalog page"
    And I should see "You searched for:"
	And I should see "history"
    When I follow "Tibetan"
    And I should see "You searched for:"
 	And I should see "history"
    And I should see the applied filter "Language" with the value "Tibetan (2)"
    When I select "title" from "sort"
    And I press "sort results" 
    Then I should be on "the catalog page"
    And I should see "You searched for:"
 	And I should see "history"
    And I should see the applied filter "Language" with the value "Tibetan (2)"

  
  Scenario: Changing per page number should retain filters
    When I am on the home page
    And I fill in "q" with "history"
    And I press "search"
    Then I should be on "the catalog page"
    And I should see "You searched for:"
 	And I should see "history"
    When I follow "Tibetan"
    And I should see "You searched for:"
 	And I should see "Keyword"
	And I should see "history"
    And I should see the applied filter "Language" with the value "Tibetan (2)"
    When I select "20" from "per_page"
    And I press "update" 
    Then I should be on "the catalog page"
    And I should see "You searched for:"
 	And I should see "history"
    And I should see the applied filter "Language" with the value "Tibetan (2)"

