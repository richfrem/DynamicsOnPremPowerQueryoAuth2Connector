// Use this file to write queries to test your data connector
let
    result = DynamicsOnPremOAuth.Contents("https://devorg.dev.jag.gov.bc.ca/api/data/v9.0/")
in
    result