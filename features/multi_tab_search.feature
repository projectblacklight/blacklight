@multi_tab_search
Feature: Multi Tab Search
  As a user
  In order to make sure that different simultaneously-open windows preserve their own session[:search] values
  I want to perform two searches in two windows and make sure that as I page through results within each window, the independent results are preserved

  @javascript
  Scenario: Multi-tab search
    Given I have done a search with term "tibetan"
    Then the body tag should contain "1 - 6 of 6"
    Then the body tag should contain "Pluvial nectar of blessings"
    And the body tag should contain "Śes yon"
    Given I have done a search with term "korea"
    Then the body tag should contain "1 - 4 of 4"
    Then the body tag should contain "Koryŏ inmul yŏlchŏn"
    And the body tag should contain "Ajikto kŭrŏk chŏrŏk sasimnikka"

    When I visit the page for the item with id "2008308175" using param last_known_search_json_string = '{"q":"tibetan","action":"index","controller":"catalog","total":6}'
    Then the body tag should contain "| 1 of 6 |"
    Then the body tag should contain "Pluvial nectar of blessings"
    When I follow the Next » link
    And the body tag should contain "| 2 of 6 |"
    Then the body tag should contain "Śes yon"
    When I follow the Next » link
    And the body tag should contain "| 3 of 6 |"
    Then the body tag should contain "Bod kyi naṅ chos ṅo sprod sñiṅ bsdus"

    When I visit the page for the item with id "77826928" using param last_known_search_json_string = '{"q":"korea","action":"index","controller":"catalog","total":4}'
    And the body tag should contain "| 1 of 4 |"
    And the body tag should contain "Koryŏ inmul yŏlchŏn"
    When I follow the Next » link
    And the body tag should contain "| 2 of 4 |"
    Then the body tag should contain "Ajikto kŭrŏk chŏrŏk sasimnikka"
    When I follow the Next » link
    And the body tag should contain "| 3 of 4 |"
    Then the body tag should contain "Pukhan pŏmnyŏngjip"
