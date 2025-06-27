# language: de
@EPA
Funktion: Teste ePA

  #Grundlage:
  #  Gegeben sei KOB finde Aktensystem

  Szenario: Erzeuge eine Usersession
    Gegeben sei TGR lösche aufgezeichnete Nachrichten
    Und TGR lösche die benutzerdefinierte Fehlermeldung

    Wenn TGR zeige Banner "Testfall: Aufbau einer User Session mit IDP und Authorization Service"
    # For customers who trigger the OIDC-Flow manually via UI
    Dann TGR pausiere Testausführung mit Nachricht "Bitte initiiere den Aufbau einer User Session mit dem Primärsystem!"

    ### getNonce
    Und TGR finde die letzte Anfrage mit Pfad ".*" und Knoten "$.body.decrypted.path.basicPath" der mit "/epa/authz/v1/getNonce" übereinstimmt
    # outer request
    Und TGR prüfe aktueller Request stimmt im Knoten "$.method" überein mit "POST"
    Und TGR prüfe aktueller Request stimmt im Knoten "$.header.[~'accept']" überein mit ".*application/octet-stream.*"
    Und TGR prüfe aktueller Request stimmt im Knoten "$.header.[~'content-type']" überein mit "application/octet-stream"
    Und TGR prüfe aktueller Request stimmt im Knoten "$.header.[~'VAU-nonPU-Tracing']" überein mit ".* .*"
    Und TGR prüfe aktueller Request stimmt im Knoten "$.header.[~'x-useragent']" überein mit "^[a-zA-Z0-9\-]{1,20}\/[a-zA-Z0-9\-\.]{1,15}$"
    # inner request
    Und TGR prüfe aktueller Request stimmt im Knoten "$.body.decrypted.method" überein mit "GET"
    Und TGR prüfe aktueller Request stimmt im Knoten "$.body.decrypted.header.[~'accept']" überein mit ".*application/json.*"
    Und TGR prüfe aktueller Request stimmt im Knoten "$.body.decrypted.header.[~'x-useragent']" überein mit "^[a-zA-Z0-9\-]{1,20}\/[a-zA-Z0-9\-\.]{1,15}$"
    # outer response
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.header.[~'content-type']" überein mit "application/octet-stream"
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.responseCode" überein mit "200"
    # inner response
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.body.decrypted.responseCode" überein mit "200"
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.body.decrypted.body.nonce" überein mit ".*"
    Und TGR prüfe aktuelle Antwort im Knoten "$.body.decrypted.body" stimmt als JSON überein mit:
    """
    {
      "nonce" : "${json-unit.ignore}"
    }
    """

    ###  send_authorization_request_sc
    Und TGR finde die letzte Anfrage mit Pfad ".*" und Knoten "$.body.decrypted.path.basicPath" der mit "/epa/authz/v1/send_authorization_request_sc" übereinstimmt
    # outer request
    Und TGR prüfe aktueller Request stimmt im Knoten "$.method" überein mit "POST"
    Und TGR prüfe aktueller Request stimmt im Knoten "$.header.[~'accept']" überein mit ".*application/octet-stream.*"
    Und TGR prüfe aktueller Request stimmt im Knoten "$.header.[~'content-type']" überein mit "application/octet-stream"
    Und TGR prüfe aktueller Request stimmt im Knoten "$.header.[~'VAU-nonPU-Tracing']" überein mit ".* .*"
    Und TGR prüfe aktueller Request stimmt im Knoten "$.header.[~'x-useragent']" überein mit "^[a-zA-Z0-9\-]{1,20}\/[a-zA-Z0-9\-\.]{1,15}$"
    # inner request
    Und TGR prüfe aktueller Request stimmt im Knoten "$.body.decrypted.method" überein mit "GET"
    Und TGR prüfe aktueller Request stimmt im Knoten "$.body.decrypted.header.[~'x-useragent']" überein mit "^[a-zA-Z0-9\-]{1,20}\/[a-zA-Z0-9\-\.]{1,15}$"
    # outer response
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.header.[~'content-type']" überein mit "application/octet-stream"
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.responseCode" überein mit "200"
    # inner response
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.body.decrypted.responseCode" überein mit "302"
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.body.decrypted.reasonPhrase" überein mit "(?i)Found"
    # INFO: the internet address is also okay here, because the backend systems in Ru-DEV still sends this back to PS
    # that is not an issue of the PS, so we accept both until backends systems sends only the TI address
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.body.decrypted.header.[~'location']" überein mit "(https://idp-ref.app.ti-dienste.de.*|https://idp-ref.zentral.idp.splitdns.ti-dienste.de.*)"
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.body.decrypted.header.[~'location'].redirect_uri" überein mit ".*"
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.body.decrypted.header.[~'location'].state" überein mit ".*"
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.body.decrypted.header.[~'location'].nonce" überein mit ".*"
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.body.decrypted.header.[~'location'].code_challenge" überein mit ".*"
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.body.decrypted.header.[~'location'].code_challenge_method.value" überein mit "S256"
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.body.decrypted.header.[~'location'].scope.value" überein mit ".*openid.*"
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.body.decrypted.header.[~'location'].response_type.value" überein mit "code"

     ###  send_authcode_sc
    Und TGR finde die letzte Anfrage mit Pfad ".*" und Knoten "$.body.decrypted.path.basicPath" der mit "/epa/authz/v1/send_authcode_sc" übereinstimmt
    # outer request
    Und TGR prüfe aktueller Request stimmt im Knoten "$.method" überein mit "POST"
    Und TGR prüfe aktueller Request stimmt im Knoten "$.header.[~'accept']" überein mit ".*application/octet-stream.*"
    Und TGR prüfe aktueller Request stimmt im Knoten "$.header.[~'content-type']" überein mit "application/octet-stream"
    Und TGR prüfe aktueller Request stimmt im Knoten "$.header.[~'VAU-nonPU-Tracing']" überein mit ".* .*"
    Und TGR prüfe aktueller Request stimmt im Knoten "$.header.[~'x-useragent']" überein mit "^[a-zA-Z0-9\-]{1,20}\/[a-zA-Z0-9\-\.]{1,15}$"
    # inner request
    Und TGR prüfe aktueller Request stimmt im Knoten "$.body.decrypted.method" überein mit "POST"
    Und TGR prüfe aktueller Request stimmt im Knoten "$.body.decrypted.header.[~'content-type']" überein mit "application/json"
    Und TGR prüfe aktueller Request stimmt im Knoten "$.body.decrypted.header.[~'x-useragent']" überein mit "^[a-zA-Z0-9\-]{1,20}\/[a-zA-Z0-9\-\.]{1,15}$"

    Und TGR prüfe aktueller Request im Knoten "$.body.decrypted.body" stimmt als JSON überein mit:
    """
      {
        "authorizationCode" : "${json-unit.ignore}",
        "clientAttest" : "${json-unit.ignore}"
      }
    """
    Und TGR prüfe aktueller Request stimmt im Knoten "$.body.decrypted.body.authorizationCode.content.header.enc" überein mit "A256GCM"
    Und TGR prüfe aktueller Request stimmt im Knoten "$.body.decrypted.body.authorizationCode.content.header.cty" überein mit "NJWT"
    Und TGR prüfe aktueller Request stimmt im Knoten "$.body.decrypted.body.authorizationCode.content.header.exp" überein mit "[\d]*"
    Und TGR prüfe aktueller Request stimmt im Knoten "$.body.decrypted.body.authorizationCode.content.header.alg" überein mit "dir"
    Und TGR prüfe aktueller Request stimmt im Knoten "$.body.decrypted.body.authorizationCode.content.header.kid" überein mit "0001"
    Und TGR prüfe aktueller Request im Knoten "$.body.decrypted.body.authorizationCode.content.header" stimmt als JSON überein mit:
    """
    {
      "enc" : "A256GCM",
      "cty" : "NJWT",
      "exp" : "[\\d]*",
      "alg" : "dir",
      "kid" : "0001"
    }
    """
    Und TGR prüfe aktueller Request stimmt im Knoten "$.body.decrypted.body.clientAttest.content.header.typ" überein mit "JWT"
    Und TGR prüfe aktueller Request stimmt im Knoten "$.body.decrypted.body.clientAttest.content.header.x5c" überein mit ".*"
    # ONLY ECC --> force ES256
    Und TGR prüfe aktueller Request stimmt im Knoten "$.body.decrypted.body.clientAttest.content.header.alg" überein mit "ES256"
    Und TGR prüfe aktueller Request im Knoten "$.body.decrypted.body.clientAttest.content.header" stimmt als JSON überein mit:
    """
      {
      "typ" : "JWT",
      "x5c" : "${json-unit.ignore}",
      "alg" : "${json-unit.ignore}"
      }
    """
    Und TGR prüfe aktueller Request enthält Knoten "$.body.decrypted.body.clientAttest.content.body"
    Und TGR prüfe aktueller Request im Knoten "$.body.decrypted.body.clientAttest.content.body" stimmt als JSON überein mit:
    """
      {
      "nonce" : "${json-unit.ignore}",
      "iat" : "[\\d]*",
      "exp" : "[\\d]*"
      }
    """

    # TODO: Check if signature was created with ECC
    Und TGR prüfe aktueller Request enthält Knoten "$.body.decrypted.body.clientAttest.content.signature"

    # outer response
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.header.[~'content-type']" überein mit "application/octet-stream"
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.responseCode" überein mit "200"
    # inner response
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.body.decrypted.responseCode" überein mit "200"
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.body.decrypted.reasonPhrase" überein mit "OK"
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.body.decrypted.header.[~'content-type']" überein mit "application/json"
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.body.decrypted.body" überein mit ".*"


  Szenario: Einstellen einer Befugnis (setEntitlement)
    Gegeben sei TGR lösche aufgezeichnete Nachrichten
    Und TGR lösche die benutzerdefinierte Fehlermeldung

    Wenn TGR zeige Banner "Testfall: Befugnisvergabe durch ein Primärsystem"
    # For customers who trigger the post request for a new entitlement manually via UI
    Dann TGR pausiere Testausführung mit Nachricht "Bitte initiiere die Befugnisvergabe durch ein Primärsystem!"

    ### set entitlements
    Und TGR finde die letzte Anfrage mit Pfad ".*" und Knoten "$.body.decrypted.path.basicPath" der mit "/epa/basic/api/v1/ps/entitlements" übereinstimmt
    # outer request
    Und TGR prüfe aktueller Request stimmt im Knoten "$.method" überein mit "POST"
    Und TGR prüfe aktueller Request stimmt im Knoten "$.header.[~'accept']" überein mit ".*application/octet-stream.*"
    Und TGR prüfe aktueller Request stimmt im Knoten "$.header.[~'content-type']" überein mit "application/octet-stream"
    Und TGR prüfe aktueller Request stimmt im Knoten "$.header.[~'VAU-nonPU-Tracing']" überein mit ".* .*"
    Und TGR prüfe aktueller Request stimmt im Knoten "$.header.[~'x-useragent']" überein mit "^[a-zA-Z0-9\-]{1,20}\/[a-zA-Z0-9\-\.]{1,15}$"
    # inner request
    Und TGR prüfe aktueller Request stimmt im Knoten "$.body.decrypted.method" überein mit "POST"
    Und TGR prüfe aktueller Request stimmt im Knoten "$.body.decrypted.header.[~'accept']" überein mit ".*application/json.*"
    Und TGR prüfe aktueller Request stimmt im Knoten "$.body.decrypted.header.[~'x-insurantid']" überein mit ".*"
    Und TGR prüfe aktueller Request stimmt im Knoten "$.body.decrypted.header.[~'x-useragent']" überein mit "^[a-zA-Z0-9\-]{1,20}\/[a-zA-Z0-9\-\.]{1,15}$"
    Und TGR prüfe aktueller Request im Knoten "$.body.decrypted.body" stimmt als JSON überein mit:
    """
      {
        "jwt" : "${json-unit.ignore}"
      }
    """

    # ONLY ECC --> force ES256
    Und TGR prüfe aktueller Request stimmt im Knoten "$.body.decrypted.body.jwt.content.header.alg" überein mit "ES256"
    Und TGR prüfe aktueller Request im Knoten "$.body.decrypted.body.jwt.content.header" stimmt als JSON überein mit:
    """
      {
        "typ" : "${json-unit.ignore}",
        "x5c" : "${json-unit.ignore}",
        "alg" : "${json-unit.ignore}"
      }
    """

    Und TGR prüfe aktueller Request im Knoten "$.body.decrypted.body.jwt.content.body" stimmt als JSON überein mit:
    """
      {
        "iat" : "[\\d]*",
        "exp" : "[\\d]*",
        "auditEvidence" : "${json-unit.ignore}"
      }
    """

    # TODO: Check if signature was created with ECC
    Und TGR prüfe aktueller Request enthält Knoten "$.body.decrypted.body.jwt.content.signature"

    # outer response
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.header.[~'content-type']" überein mit "application/octet-stream"
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.responseCode" überein mit "200"

    # inner response
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.body.decrypted.responseCode" überein mit "201"
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.body.decrypted.reasonPhrase" überein mit "(?i)Created"
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.body.decrypted.header.[~'content-type']" überein mit "application/json"
    Und TGR prüfe aktuelle Antwort im Knoten "$.body.decrypted.body" stimmt als JSON überein mit:
    """
    {
      "validTo" : "${json-unit.ignore}"
    }
    """
