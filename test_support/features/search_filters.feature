Feature: Search Filters
  In order constrain searches
  As a user
  I want to filter search results via facets on the search page
  
  Scenario: Filter a blank search
    Given I am on the home page
    When I follow "Tibetan"
    Then I should see "1 - 6 of 6"    
    And I should see the applied facet "Language" with the value "Tibetan 6"
    When I follow "India"
    Then I should see "1 - 2 of 2"
    And I should see the applied facet "Language" with the value "Tibetan 2"
    And I should see the applied facet "Region" with the value "India 2"
  
  Scenario: Search with no filters applied
    When I am on the home page
    And I fill in "q" with "bod"
    And I press "search"
    Then I should be on "the catalog page"
    And I should see "1 - 3 of 3"
    And I should not see "No Keywords"
    And I should see "You searched for:"
    And I should see "All Fields"
    And I should see "bod"
  
  Scenario: Search with filters applied
    When I am on the home page
    And I fill in "q" with "history"
    And I press "search"
    Then I should be on "the catalog page"
    And I should see "1 - 9 of 9"
    And I should not see "No Keywords"
    And I should see "You searched for:"
    And I should see "All Fields"
    And I should see "history"
    When I follow "Tibetan"
    Then I should see "1 - 2 of 2"
    And I should see the applied facet "Language" with the value "Tibetan 2"
    And I should see "All Fields"
    And I should see "history"
    When I follow "2004"
    Then I should see "1 to 1 of 1"
    And I should see "You searched for:"
    And I should see the applied facet "Language" with the value "Tibetan 1"
    And I should see the applied facet "Publication Year" with the value "2004 1"
  
  Scenario: Apply and remove filters
    Given I am on the home page
    When I follow "Tibetan"
    And I should see "Language"
    And I should see "Tibetan 6"
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
    And I should see the applied facet "Language" with the value "Tibetan 2"
    When I follow "2004"
    And I should see "You searched for:"
	And I should see "history"
    And I should see the applied facet "Language" with the value "Tibetan 1"
    And I should see the applied facet "Publication Year" with the value "2004 1"
    When I fill in "q" with "china"
    And I press "search"
    Then I should be on "the catalog page"
    And I should see "All Fields"
	And I should see "china"
    And I should see the applied facet "Language" with the value "Tibetan 1"
    And I should see the applied facet "Publication Year" with the value "2004 1"

  
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
    And I should see the applied facet "Language" with the value "Tibetan 2"
    When I sort by "title"
    Then I should be on "the catalog page"
    And I should see "You searched for:"
 	And I should see "history"
    And I should see the applied facet "Language" with the value "Tibetan 2"

  
  Scenario: Changing per page number should retain filters
    When I am on the home page
    And I fill in "q" with "history"
    And I press "search"
    Then I should be on "the catalog page"
    And I should see "You searched for:"
 	And I should see "history"
    When I follow "Tibetan"
    And I should see "You searched for:"
 	And I should see "All Fields"
	And I should see "history"
    And I should see the applied facet "Language" with the value "Tibetan 2"
    When I show 20 per page
    Then I should be on "the catalog page"
    And I should see "You searched for:"
 	And I should see "history"
    And I should see the applied facet "Language" with the value "Tibetan 2"

