#Test für AVS
@AVS
Feature: PKV-Abrechnungsinformationen bereitstellen

  Background:
    Given TGR clear recorded messages
    Given TGR clear all default headers

  @AVS
  Scenario: Vorbedingung: Als Arztpraxis ein IDP Access Token abholen
    Given TGR set default header "X-p12-bytes-base64" to "!{resolve(file('src/test/resources/Arztpraxis_SMCB_AUT_E256_X509.p12.base64'))}"
    And TGR set default header "X-keystore-password" to "00"
    And TGR set default header "X-scope" to "${data.idp.scope}"
    And TGR set default header "X-discovery-document-address" to "${data.idp.discoveryDocumentAddress}"
    And TGR set default header "X-client-id" to "${data.idp.clientId}"
    And TGR set default header "X-redirect-uri" to "${data.idp.redirectUrl}"
    When TGR send empty GET request to "${data.idp_client_service}"
    And TGR find last request to path "/" with "$..receiver" matching "${data.dockerservices.idp.address}"
    Then TGR current response with attribute "$.responseCode" matches "200"
    And TGR store current response node text value at "$.body" in variable "erp.access_token_arztpraxis"

  @AVS
  Scenario: Vorbedingung: Als Arzt ein E-Rezept erstellen
    And TGR set default headers:
  """
    Content-Type  = application/fhir+xml; charset=UTF-8
    Accept        = application/fhir+xml; charset=UTF-8
    Authorization = Bearer ${erp.access_token_arztpraxis}
    User-Agent    = ${data.user_agent_pvs}
  """

    When TGR send POST request to "${data.address_fachdienst}/Task/$create" with multiline body:
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
    And TGR find last request to path "/Task/$create"
    And TGR print current request as rbel-tree
    And TGR print current response as rbel-tree

    Then TGR current response with attribute "$.responseCode" matches "201"
    And TGR current response with attribute "$.body" does not match "^Error:.*"

    And TGR store current response node text value at "$.body.Task.id.value" in variable "erp.task_id"
    And TGR store current response node text value at "$.body.Task.identifier[?(lowerCase(@.system.value.basicPath) =$ 'accesscode')].value.value" in variable "erp.task_access_code"
    And TGR store current response node text value at "$.body.Task.identifier[?(lowerCase(@.system.value.basicPath) =$ 'prescriptionid')].value.value" in variable "erp.task_prescription_id"

  @AVS
  Scenario: Vorbedingung: als Arzt das KBV Bundle signieren
    Given TGR set global variable "erp.rnd_nr" to "!{randomHex(12)}"
    And Als Patient speichere ich meine KVNR in der Variable "erp.kvnr"
    And Speichere das aktuelle Datum in "erp.current_date"
    Then Als Arzt signiere ich "!{resolve(file('src/test/resources/Bundle_Arzt.xml'))}" und speichere es in der Variable in "erp.signed_document"

  @AVS
  Scenario: Vorbedingung: Als Arzt das E-Rezept einstellen
    And TGR set default headers:
  """
    Content-Type  = application/fhir+xml; charset=UTF-8
    Accept        = application/fhir+xml; charset=UTF-8
    Authorization = Bearer ${erp.access_token_arztpraxis}
    X-AccessCode  = ${erp.task_access_code}
  """

    When TGR send POST request to "${data.address_fachdienst}/Task/${erp.task_id}/$activate" with multiline body:
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
    And TGR find last request to path "/Task/${erp.task_id}/$activate"
    And TGR print current request as rbel-tree
    And TGR print current response as rbel-tree

    Then TGR current response with attribute "$.responseCode" matches "200"
    And TGR current response with attribute "$.body" does not match "^Error:.*"

  @AVS
  Scenario: Als Apotheker das E-Rezept abrufen
    Given TGR print variable "erp.task_access_code"
    Then TGR print variable "erp.task_id"
    Given TGR pause test run execution with message "Bitte rufen Sie als Apotheker das E-Rezept mit TaskId: ${erp.task_id} und AccessCode: ${erp.task_access_code} ab."
    And TGR find last request to path ".*" with "$.body.message.path.basicPath" matching "/Task/${erp.task_id}/$accept"
    And TGR print current response as rbel-tree
    Then TGR current response with attribute "$.body.message.responseCode" matches "200"
    And TGR store current response node text value at "$.body..identifier[?(lowerCase(@.system.value.basicPath) =$ 'secret')].value.value" in variable "erp.task_secret"
    And TGR store current response node text value at "$.body..Binary.data.value" in variable "erp.signed_document"
    And TGR store current response node text value at "$.body..identifier[?(lowerCase(@.system.value.basicPath) =$ 'prescriptionid')].value.value" in variable "erp.aps_prescription_id"

    And TGR set global variable "erp.binary_data_value" to "!{base64Decode(getValue('erp.signed_document'))}"
    And TGR set global variable "erp.aps_medication" to "!{'<Medication>' + subStringBefore(subStringAfter(getValue('erp.binary_data_value'), '<Medication>') , '</Medication>') + '</Medication>'}"
    And TGR set global variable "erp.aps_medication_id" to "!{subStringBefore(subStringAfter(getValue('erp.aps_medication'), '<id value=\"'), '\"')}"

  @AVS
  Scenario: Als Apotheker die E-Rezept-Abgabe vollziehen
    Given TGR print variable "erp.task_access_code"
    Then TGR print variable "erp.task_id"
    Then TGR print variable "erp.task_secret"
    Then TGR print variable "erp.aps_medication"
    Then TGR print variable "erp.aps_medication_id"

    Given TGR pause test run execution with message "Bitte vollziehen Sie als Apotheker die E-Rezept-Abgabe."
    And TGR find last request to path ".*" with "$.body.message.path.basicPath" matching "/Task/${erp.task_id}/$close"
    And TGR print current request as rbel-tree
    And TGR print current response as rbel-tree
    Then TGR current response with attribute "$.body.message.responseCode" matches "200"
    And TGR current response with attribute "$.body.message.body" does not match "^Error:.*"

  @AVS
  Scenario: Als Apotheker den PKV-Abgabedatensatz signieren
    Given TGR pause test run execution with message "Bitte signieren Sie als Apotheker den PKV-Abgabedatensatz auf einer HBA mit Generation 2.1."
    And TGR find last request to path ".*/SignatureService" with "$.header.SOAPAction" matching ".*SignDocument"    
    And TGR print current request as rbel-tree
    And TGR print current response as rbel-tree
    Then TGR current response with attribute "$.responseCode" matches "200"
    And TGR current response with attribute "$.body" does not match "^Error:.*"

  @AVS
  Scenario: Als Apotheker PKV-Abrechnungsinformationen bereitstellen
    Given TGR pause test run execution with message "Bitte stellen Sie als Apotheker für das E-Rezept eine Abrechnungsinformation bereit."
    Then TGR find last request to path ".*" with "$.body.message.path.basicPath" matching "/ChargeItem"
    And TGR print current request as rbel-tree
    And TGR print current response as rbel-tree
    Then TGR current response with attribute "$.body.message.responseCode" matches "201"
    And TGR current response with attribute "$.body.message.body" does not match "^Error:.*"