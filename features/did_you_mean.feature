@did_you_mean
Feature: Did You Mean
  As a user
  In order to get great search results
  I want to get "did you mean" suggestions for poor queries
  
  Scenario: All Fields search - No Results with spelling suggestion
    When I am on the home page
    And I fill in "q" with "politica"
    And I select "All Fields" from "qt"
    And I press "search"
    Then I should see "Did you mean"
    When I follow "policy"
    Then I should get results
  
  Scenario: Title search - No Results with spelling suggestion
    When I am on the home page
    # yehudiyam is one letter away from a title word
    And I fill in "q" with "yehudiyam"
    And I select "Title" from "qt"
    And I press "search"
    Then I should see "Did you mean"
    When I follow "yehudiyim"
    Then I should get results
    # TODO:  it should be an title search, but I can't get step def right
    #  (it works in the code)
    # TODO: false positive?
    # And I should see select list "select#qt" with "Title" selected
  
  Scenario: Author search - No Results with spelling suggestion
    When I am on the home page
    # shirma is one letter away from an author word
    And I fill in "q" with "shirma"
    And I select "Author" from "qt"
    And I press "search"
    Then I should see "Did you mean"
    When I follow "sharma"
    Then I should get results
    # TODO:  it should be an author search, but I can't get step def right
    #  (it works in the code)
    # TODO: false positive?
    #And I should see select list "select#qt" with "Author" selected
  
  Scenario: Subject search - No Results with spelling suggestion
    When I am on the home page
    # shirma is one letter away from an author word
    And I fill in "q" with "wome"
    And I select "Subject" from "qt"
    And I press "search"
    Then I should see "Did you mean"
    When I follow "women"
    Then I should get results
    # TODO:  it should be an author search, but I can't get step def right
    #  (it works in the code)

  Scenario: No Results - and no close spelling suggestions
    When I am on the home page
    And I fill in "q" with "ooofda ooofda"
    And I press "search"
    Then I should not see "Did you mean"

  Scenario: No Results - multiword query should be separate links
    When I am on the home page
    And I fill in "q" with "politica boo"
    And I select "All Fields" from "qt"
    And I press "search"
    Then I should see "Did you mean"
    When I follow "policy"
    Then I should get results
    
  Scenario: No Results - multiword query
    When I am on the home page
    And I fill in "q" with "politica boo"
    And I select "All Fields" from "qt"
    And I press "search"
    Then I should see "Did you mean"
    When I follow "bon"
    Then I should get results

# can't get this to work with 30 rec index: 
#    need something to give results and give suggestion with MORE results
#  Scenario: Num Results low enough to warrant spelling suggestion
#    Given I am on the home page
    # aya gives a single results;  bya gives more
#    And I fill in "q" with "aya"
#    And I press "search"
#    Then I should get results
#    And I should see "Did you mean"
#    When I follow "bya"
#    Then I should get results
  
  Scenario: Too many results for spelling suggestion
    Given I am on the home page
    # histori gives 9 results in 30 record demo index
    And I fill in "q" with "histori"
    And I press "search"
    Then I should not see "Did you mean"
  
  Scenario: Exact Threshold number of results for spelling suggestion
    Given I am on the home page
    # polit gives 5 results in 30 record demo index - 5 is default cutoff
    And I fill in "q" with "polit"
    And I press "search"
    Then I should see "Did you mean"
  
  Scenario: Same number of results as spelling suggestion
    Given I am on the home page
    # den gives 1 result in 30 record demo index - suggestion don is 1 result also
    And I fill in "q" with "den"
    And I press "search"
    Then I should not see "Did you mean"

  Scenario: Multiple terms should have individual links, not single query link
    Given I am on the home page
    And I fill in "q" with "politica boo"
    And I press "search"
    Then I should see "Did you mean"
    And I should see "policy"
    And I should see "bon"
    And I should not see "policy bon"

  Scenario: Repeated terms should only give a single suggestion
    Given I am on the home page
    And I fill in "q" with "boo boo"
    And I press "search"
    Then I should see "Did you mean"
    And I should see "bon"
    And I should not see "bon bon"
  