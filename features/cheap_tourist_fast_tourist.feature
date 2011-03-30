Feature: Cheap tourist fast tourist
  In order to get into Ruby Mendicant University's May 2011 Core Skills Course
  As a ruby developer
  I want to solve the "Cheap tourist, fast tourist" puzzle

  Scenario: asking for help
    When I run "cheap_tourist_fast_tourist -h"
    Then the output should contain usage information

  Scenario: fail running with no arguments
    When I run "cheap_tourist_fast_tourist"
    Then the output should contain usage information

  Scenario: fail running with invalid option
    When I run "cheap_tourist_fast_tourist -x"
    Then the output should contain:
      """
      Unknown option -- 'x'
      """
    And the output should contain usage information

  Scenario: fail when passing in non-existent flight data file
    When I run "cheap_tourist_fast_tourist NONEXISTENT.txt"
    Then the output should contain:
      """
      File containing flight data (NONEXISTENT.txt) does not exist
      """
      And the output should contain usage information

  Scenario: OK running with valid data files
    Given a file named "data/input.txt"
    When I run "cheap_tourist_fast_tourist data/input.txt"
    Then the output should not contain usage information
  

  Scenario: Processing test data
     Given a file named "data/sample-input.txt" with:
        """
        2

        3
        A B 09:00 10:00 100.00
        B Z 11:30 13:30 100.00
        A Z 10:00 12:00 300.00

        7
        A B 08:00 09:00 50.00
        A B 12:00 13:00 300.00
        A C 14:00 15:30 175.00
        B C 10:00 11:00 75.00
        B Z 15:00 16:30 250.00
        C B 15:45 16:45 50.00
        C Z 16:00 19:00 100.00
        """
     When I run "cheap_tourist_fast_tourist data/sample-input.txt"
     Then the output should not contain usage information
       And the output should contain:
         """
         09:00 13:30 200.00
         10:00 12:00 300.00

         08:00 19:00 225.00
         12:00 16:30 550.00
         """
  
  
