#Test für PVS
  @PVS
Feature: Rezept einstellen (GKV)
  Background:
    Given TGR clear recorded messages
    Given TGR clear all default headers

  @PVS
  Scenario: Test: E-Rezept erstellen
    Given TGR pause test run execution with message "Bitte erstellen Sie ein E-Rezept."

    And TGR find last request to path ".*" with "$.body.message.path.basicPath" matching "/Task/$create"
    And TGR print current request as rbel-tree
    And TGR print current response as rbel-tree

    Then TGR current response with attribute "$.body.message.responseCode" matches "201"
    And TGR current response with attribute "$.body.message.body" does not match "^Error:.*"

    And TGR store current response node text value at "$.body.message.body.Task.id.value" in variable "erp.task_id"

  @PVS
  Scenario: Test: E-Rezept signieren
    Given TGR pause test run execution with message "Bitte signieren Sie eine Verordnung auf einer Karte der Generation 2.1"

    And TGR find last request to path ".*/SignatureService" with "$.header.SOAPAction" matching ".*SignDocument"
    And TGR print current request as rbel-tree
    And TGR print current response as rbel-tree

    Then TGR current response with attribute "$.responseCode" matches "200"
    And TGR current response with attribute "$.body" does not match "^Error:.*"

  @PVS
  Scenario: Test: E-Rezept wurde korrekt eingestellt
    Given TGR pause test run execution with message "Bitte stellen Sie das E-Rezept ein."

    And TGR find last request to path ".*" with "$.body.message.path.basicPath" matching "/Task/${erp.task_id}/$activate"
    And TGR print current request as rbel-tree
    And TGR print current response as rbel-tree

    Then TGR current response with attribute "$.body.message.responseCode" matches "200"
    And TGR current response with attribute "$.body.message.body" does not match "^Error:.*"


