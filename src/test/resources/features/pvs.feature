#Test für PVS
@PVS @EREZEPT
Feature: Rezept einstellen (GKV)
  Background:
    Given TGR lösche alle default headers

  Scenario: Vorbedingung: lösche alte Nachrichten
    Given TGR lösche aufgezeichnete Nachrichten

  Scenario: Test: E-Rezept erstellen
    Given TGR pausiere Testausführung mit Nachricht "Bitte erstellen Sie ein E-Rezept."

    And TGR finde die letzte Anfrage mit Pfad ".*" und Knoten "$.body.message.path.basicPath" der mit "/Task/$create" übereinstimmt
    Then TGR prüfe aktuelle Antwort stimmt im Knoten "$.body.message.responseCode" überein mit "201"
    And TGR prüfe aktuelle Antwort stimmt im Knoten "$.body.message.body" nicht überein mit "^Error:.*"

    And TGR speichere Wert des Knotens "$.body.message.body.Task.id.value" der aktuellen Antwort in der Variable "erp.task_id"

  Scenario: Test: E-Rezept signieren
    Given TGR pausiere Testausführung mit Nachricht "Bitte signieren Sie eine Verordnung auf einer Karte der Generation 2.1"

    And TGR finde die letzte Anfrage mit Pfad ".*/SignatureService" und Knoten "$.header.SOAPAction" der mit ".*SignDocument" übereinstimmt
    Then TGR prüfe aktuelle Antwort stimmt im Knoten "$.responseCode" überein mit "200"
    And TGR prüfe aktuelle Antwort stimmt im Knoten "$.body" nicht überein mit "^Error:.*"

  Scenario: Test: E-Rezept wurde korrekt eingestellt
    Given TGR pausiere Testausführung mit Nachricht "Bitte stellen Sie das E-Rezept ein."
    And TGR finde die letzte Anfrage mit Pfad ".*" und Knoten "$.body.message.path.basicPath" der mit "/Task/${erp.task_id}/$activate" übereinstimmt
    Then TGR prüfe aktuelle Antwort stimmt im Knoten "$.body.message.responseCode" überein mit "200"
    And TGR prüfe aktuelle Antwort stimmt im Knoten "$.body.message.body" nicht überein mit "^Error:.*"


