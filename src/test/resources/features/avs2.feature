#Test für AVS
@AVS @EREZEPT
Feature: PKV-Agbagedatesatz ändern

  Background:
    Given TGR lösche alle default headers

  Scenario: Vorbedingung: lösche alte Nachrichten
    Given TGR lösche aufgezeichnete Nachrichten

  Scenario: Vorbedingung: Als Arztpraxis ein IDP Access Token abholen
    Given TGR setze den default header "X-p12-bytes-base64" auf den Wert "!{resolve(file('src/test/resources/Arztpraxis_SMCB_AUT_E256_X509.p12.base64'))}"
    And TGR setze den default header "X-keystore-password" auf den Wert "00"
    And TGR setze den default header "X-scope" auf den Wert "${data.idp.scope}"
    And TGR setze den default header "X-discovery-document-address" auf den Wert "${data.idp.discoveryDocumentAddress}"
    And TGR setze den default header "X-client-id" auf den Wert "${data.idp.clientId}"
    And TGR setze den default header "X-redirect-uri" auf den Wert "${data.idp.redirectUrl}"
    When TGR sende eine leere GET Anfrage an "${data.idp_client_service}"
    And TGR finde die letzte Anfrage mit Pfad "/" und Knoten "$..receiver" der mit "${data.dockerservices.idp.address}" übereinstimmt
    Then TGR prüfe aktuelle Antwort stimmt im Knoten "$.responseCode" überein mit "200"
    And TGR speichere Wert des Knotens "$.body" der aktuellen Antwort in der Variable "erp.access_token_arztpraxis"

  Scenario: Vorbedingung: Als Arzt ein E-Rezept erstellen
    And TGR setze folgende default headers:
  """
    Content-Type  = application/fhir+xml; charset=UTF-8
    Accept        = application/fhir+xml; charset=UTF-8
    Authorization = Bearer ${erp.access_token_arztpraxis}
    User-Agent    = ${data.user_agent_pvs}
  """

    When TGR sende eine POST Anfrage an "${data.address_fachdienst}/Task/$create" mit folgenden mehrzeiligen Daten:
  """
  <Parameters xmlns="http://hl7.org/fhir">
    <parameter>
      <name value="workflowType"/>
      <valueCoding>
        <system value="https://gematik.de/fhir/erp/CodeSystem/GEM_ERP_CS_FlowType"/>
        <code value="200"/>
      </valueCoding>
    </parameter>
  </Parameters>
  """
    And TGR finde die letzte Anfrage mit dem Pfad "/Task/$create"

    Then TGR prüfe aktuelle Antwort stimmt im Knoten "$.responseCode" überein mit "201"
    And TGR prüfe aktuelle Antwort stimmt im Knoten "$.body" nicht überein mit "^Error:.*"

    And TGR speichere Wert des Knotens "$.body.Task.id.value" der aktuellen Antwort in der Variable "erp.task_id"
    And TGR speichere Wert des Knotens "$.body.Task.identifier[?(lowerCase(@.system.value.basicPath) =$ 'accesscode')].value.value" der aktuellen Antwort in der Variable "erp.task_access_code"
    And TGR speichere Wert des Knotens "$.body.Task.identifier[?(lowerCase(@.system.value.basicPath) =$ 'prescriptionid')].value.value" der aktuellen Antwort in der Variable "erp.task_prescription_id"

  Scenario: Vorbedingung: als Arzt das KBV Bundle signieren
    Given TGR setze globale Variable "erp.rnd_nr" auf "!{randomHex(12)}"
    And Als Patient speichere ich meine KVNR in der Variable "erp.kvnr"
    And Speichere das aktuelle Datum in "erp.current_date"
    Then Als Arzt signiere ich "!{resolve(file('src/test/resources/Bundle_Arzt.xml'))}" und speichere es in der Variable in "erp.signed_document"

  Scenario: Vorbedingung: Als Arzt das E-Rezept einstellen
    And TGR setze folgende default headers:
  """
    Content-Type  = application/fhir+xml; charset=UTF-8
    Accept        = application/fhir+xml; charset=UTF-8
    Authorization = Bearer ${erp.access_token_arztpraxis}
    X-AccessCode  = ${erp.task_access_code}
  """

    When TGR sende eine POST Anfrage an "${data.address_fachdienst}/Task/${erp.task_id}/$activate" mit folgenden mehrzeiligen Daten:
  """
  <Parameters xmlns="http://hl7.org/fhir">
    <parameter>
        <name value="ePrescription"/>
        <resource>
            <Binary>
                <contentType value="application/pkcs7-mime"/>
                <data value="${erp.signed_document}"/>
            </Binary>
        </resource>
    </parameter>
  </Parameters>
  """
    And TGR finde die letzte Anfrage mit dem Pfad "/Task/${erp.task_id}/$activate"

    Then TGR prüfe aktuelle Antwort stimmt im Knoten "$.responseCode" überein mit "200"
    And TGR prüfe aktuelle Antwort stimmt im Knoten "$.body" nicht überein mit "^Error:.*"

  Scenario: Als Apotheker das E-Rezept abrufen
    Given TGR print variable "erp.task_access_code"
    Then TGR print variable "erp.task_id"
    Given TGR pausiere Testausführung mit Nachricht "Bitte rufen Sie als Apotheker das E-Rezept mit TaskId: ${erp.task_id} und AccessCode: ${erp.task_access_code} ab."
    And TGR finde die letzte Anfrage mit Pfad ".*" und Knoten "$.body.message.path.basicPath" der mit "/Task/${erp.task_id}/$accept" übereinstimmt
    Then TGR prüfe aktuelle Antwort stimmt im Knoten "$.body.message.responseCode" überein mit "200"
    And TGR speichere Wert des Knotens "$.body..identifier[?(lowerCase(@.system.value.basicPath) =$ 'secret')].value.value" der aktuellen Antwort in der Variable "erp.task_secret"
    And TGR speichere Wert des Knotens "$.body..Binary.data.value" der aktuellen Antwort in der Variable "erp.signed_document"
    And TGR speichere Wert des Knotens "$.body..identifier[?(lowerCase(@.system.value.basicPath) =$ 'prescriptionid')].value.value" der aktuellen Antwort in der Variable "erp.aps_prescription_id"

    And TGR setze globale Variable "erp.binary_data_value" auf "!{base64Decode(getValue('erp.signed_document'))}"
    And TGR setze globale Variable "erp.aps_medication" auf "!{'<Medication>' + subStringBefore(subStringAfter(getValue('erp.binary_data_value'), '<Medication>') , '</Medication>') + '</Medication>'}"
    And TGR setze globale Variable "erp.aps_medication_id" auf "!{subStringBefore(subStringAfter(getValue('erp.aps_medication'), '<id value=\"'), '\"')}"

  Scenario: Als Apotheker die E-Rezept-Abgabe vollziehen
    Given TGR print variable "erp.task_access_code"
    Then TGR print variable "erp.task_id"
    Then TGR print variable "erp.task_secret"
    Then TGR print variable "erp.aps_medication"
    Then TGR print variable "erp.aps_medication_id"

    Given TGR pausiere Testausführung mit Nachricht "Bitte vollziehen Sie als Apotheker die E-Rezept-Abgabe."
    And TGR finde die letzte Anfrage mit Pfad ".*" und Knoten "$.body.message.path.basicPath" der mit "/Task/${erp.task_id}/$close" übereinstimmt
    Then TGR prüfe aktuelle Antwort stimmt im Knoten "$.body.message.responseCode" überein mit "200"
    And TGR prüfe aktuelle Antwort stimmt im Knoten "$.body.message.body" nicht überein mit "^Error:.*"

  Scenario: Als Apotheker PKV-Abgabedatensatz signieren
    Given TGR pausiere Testausführung mit Nachricht "Bitte signieren Sie als Apotheker den PKV-Abgabedatensatz auf einer HBA mit Generation 2.1."
    And TGR finde die letzte Anfrage mit Pfad ".*/SignatureService" und Knoten "$.header.SOAPAction" der mit ".*SignDocument" übereinstimmt
    Then TGR prüfe aktuelle Antwort stimmt im Knoten "$.responseCode" überein mit "200"
    And TGR prüfe aktuelle Antwort stimmt im Knoten "$.body" nicht überein mit "^Error:.*"

  Scenario: Als Apotheker PKV-Abrechnungsinformationen bereitstellen
    Given TGR pausiere Testausführung mit Nachricht "Bitte stellen Sie als Apotheker für das E-Rezept eine Abrechnungsinformation bereit."
    And TGR finde die letzte Anfrage mit Pfad ".*" und Knoten "$.body.message.path.basicPath" der mit "/ChargeItem" übereinstimmt
    Then TGR prüfe aktuelle Antwort stimmt im Knoten "$.body.message.responseCode" überein mit "201"
    And TGR prüfe aktuelle Antwort stimmt im Knoten "$.body.message.body" nicht überein mit "^Error:.*"

  Scenario: Vorbedingung: Als Patient ein IDP Access Token abholen
    Given TGR setze den default header "X-p12-bytes-base64" auf den Wert "!{resolve(file('src/test/resources/Patient_AUT_E256.p12.base64'))}"
    And TGR setze den default header "X-keystore-password" auf den Wert "00"
    And TGR setze den default header "X-scope" auf den Wert "${data.idp.scope}"
    And TGR setze den default header "X-discovery-document-address" auf den Wert "${data.idp.discoveryDocumentAddress}"
    And TGR setze den default header "X-client-id" auf den Wert "${data.idp.clientId}"
    And TGR setze den default header "X-redirect-uri" auf den Wert "${data.idp.redirectUrl}"
    When TGR sende eine leere GET Anfrage an "${data.idp_client_service}"
    And TGR finde die letzte Anfrage mit Pfad "/" und Knoten "$..receiver" der mit "${data.dockerservices.idp.address}" übereinstimmt
    Then TGR prüfe aktuelle Antwort stimmt im Knoten "$.responseCode" überein mit "200"
    And TGR speichere Wert des Knotens "$.body" der aktuellen Antwort in der Variable "erp.access_token_patient"
    And TGR speichere Wert des Knotens "$.body.body.idNummer" der aktuellen Antwort in der Variable "erp.kvnr"

  Scenario: Vorbedingung: Als Patient den AccessCode des ChargeItems auslesen
    And TGR setze folgende default headers:
  """
    Content-Type  = application/fhir+xml; charset=UTF-8
    Accept        = application/fhir+xml; charset=UTF-8
    Authorization = Bearer ${erp.access_token_patient}
    User-Agent    = eRp-App-iOS/1.1 GMTK/eRezeptApp
    X-api-key     = DEpsSHb/5DKJwV3TjhZQXw==
  """

    When TGR sende eine leere GET Anfrage an "${data.address_fachdienst_fdv}/ChargeItem/${erp.task_id}"

    And TGR finde die letzte Anfrage mit dem Pfad "/ChargeItem/${erp.task_id}"
    Then TGR prüfe aktuelle Antwort stimmt im Knoten "$.responseCode" überein mit "200"
    And TGR prüfe aktuelle Antwort stimmt im Knoten "$.body" nicht überein mit "^Error:.*"
    And TGR speichere Wert des Knotens "$.body..identifier[?(lowerCase(@.system.value.basicPath) =$ 'accesscode')].value.value" der aktuellen Antwort in der Variable "erp.patient_access_code"

  Scenario: Als Apotheker den geänderten PKV-Abgabedaten signieren
    Given TGR pausiere Testausführung mit Nachricht "Bitte signieren Sie als Apotheker den geänderten PKV-Abgabedaten auf einer HBA der Generation 2.1."
    And TGR finde die letzte Anfrage mit Pfad ".*/SignatureService" und Knoten "$.header.SOAPAction" der mit ".*SignDocument" übereinstimmt
    Then TGR prüfe aktuelle Antwort stimmt im Knoten "$.responseCode" überein mit "200"
    And TGR prüfe aktuelle Antwort stimmt im Knoten "$.body" nicht überein mit "^Error:.*"

  Scenario: Test: PKV-Abgabedatensatz ändern
    Then TGR print variable "erp.task_id"
    Then TGR print variable "erp.task_secret"
    Given TGR pausiere Testausführung mit Nachricht "Bitte ändern Sie als Apotheker den PKV-Abgabedatensatz mit dem AccessCode des Patienten: ${erp.patient_access_code}"
    Then TGR finde die letzte Anfrage mit Pfad ".*" und Knoten "$.body.message.path.basicPath" der mit "/ChargeItem/${erp.task_id}" übereinstimmt
    Then TGR prüfe aktuelle Antwort stimmt im Knoten "$.body.message.responseCode" überein mit "200"
