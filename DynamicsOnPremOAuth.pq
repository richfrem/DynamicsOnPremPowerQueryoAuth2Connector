// This file contains your Data Connector logic
section DynamicsOnPremOAuth;

//OAuth2 values
client_id = Text.FromBinary(Extension.Contents("client_id.txt"));
client_secret = Text.FromBinary(Extension.Contents("client_secret.txt"));
//redirect_uri = "https://devorg.dev.jag.gov.bc.ca/api/data/v9.0/";
redirect_uri = "https://devorg.dev.jag.gov.bc.ca/";
token_uri = "https://ststest.gov.bc.ca/adfs/oauth2/token";
authorize_uri = "https://ststest.gov.bc.ca/adfs/oauth2/authorize";
logout_uri = "https://ststest.gov.bc.ca/adfs/ls/?wa=wsignout1.0";

// Login modal window dimensions
windowWidth = 1024;
windowHeight = 2048;

// OAuth2 scope
scope_prefix = "";
scopes = {
    "daily"
};

[DataSource.Kind="DynamicsOnPremOAuth", Publish="DynamicsOnPremOAuth.Publish"]
shared DynamicsOnPremOAuth.Contents = (url as text) =>
    let
        source = Json.Document(Web.Contents(url))
    in
        source; 

// Data Source Kind description
DynamicsOnPremOAuth= [
    TestConnection = (dataSourcePath) => { "DynamicsOnPremOAuth.Contents", dataSourcePath },
    Authentication = [
        OAuth = [
            StartLogin=StartLoginFunction,
            FinishLogin=FinishLogin,
            Refresh=Refresh,
            Logout=Logout
        ]
    ],
    Label = Extension.LoadString("DataSourceLabel")
];

// Data Source UI publishing description
DynamicsOnPremOAuth.Publish = [
    Beta = true,
    Category = "Other",
    ButtonText = { Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp") },
    LearnMoreUrl = "https://powerbi.microsoft.com/",
    SourceImage = DynamicsOnPremOAuth.Icons,
    SourceTypeImage = DynamicsOnPremOAuth.Icons
];

// Helper functions for OAuth2: StartLogin, FinishLogin, Refresh, Logout
StartLoginFunction = (resourceUrl, state, display) =>
    let
        //https://docs.microsoft.com/en-us/azure/active-directory/develop/v2-oauth2-auth-code-flow
        authorizeUrl = authorize_uri & "?" & Uri.BuildQueryString([
            response_type = "code", //"token",  //"code",  //was code, token, id_token
            client_id = client_id,  
            redirect_uri = redirect_uri,
            state = state,
            scope = GetScopeString(scopes, scope_prefix) //, //"openid"
            //response_mode = "form_post",
            //grant_type = "password"
        ])
    in
        [
            LoginUri = authorizeUrl,
            CallbackUri = redirect_uri,
            WindowHeight = 1024,
            WindowWidth = 2048,
            Context = null
        ];

FinishLogin = (context, callbackUri, state) =>
    let
        // parse the full callbackUri, and extract the Query string
       parts = Uri.Parts(callbackUri)[Query],
       
       //// if the query string contains an "error" field, raise an error
       //// otherwise call TokenMethod to exchange our code for an access_token
       //result = if (Record.HasFields(parts, {"error", "error_description"})) then 
             //     error Error.Record(parts[error], parts[error_description], parts)
               // else
                   //TokenMethod(parts[code], "authorization_code", context)   
                   result = TokenMethod("authorization_code", "code", parts[code])
                  //result = TokenMethod("authorization_code", "code", context)
    in
        result;

Refresh = (resourceUrl, refresh_token) => TokenMethod("refresh_token", "refresh_token", refresh_token);

Logout = (token) => logout_uri;

// see "Exchange code for access token: POST /oauth/token" at https://cloud.ouraring.com/docs/authentication for details
TokenMethod = (grantType, tokenField, code) =>
    let
        queryString = [
            grant_type = "authorization_code",
            redirect_uri = redirect_uri,
            client_id = client_id,
            client_secret = client_secret
        ],
        queryWithCode = Record.AddField(queryString, tokenField, code),

        tokenResponse = Web.Contents(token_uri, [
            Content = Text.ToBinary(Uri.BuildQueryString(queryWithCode)),
            Headers = [
                #"Content-type" = "application/x-www-form-urlencoded",
                #"Accept" = "application/json"
            ],
            ManualStatusHandling = {400} 
        ]),
        body = Json.Document(tokenResponse),
        result = if (Record.HasFields(body, {"error", "error_description"})) then 
                    error Error.Record(body[error], body[error_description], body)
                 else
                    body
    in
        result;

Value.IfNull = (a, b) => if a <> null then a else b;

GetScopeString = (scopes as list, optional scopePrefix as text) as text =>
    let
        prefix = Value.IfNull(scopePrefix, ""),
        addPrefix = List.Transform(scopes, each prefix & _),
        asText = Text.Combine(addPrefix, " ")
    in
        asText;
        

DynamicsOnPremOAuth.Icons = [
    Icon16 = { Extension.Contents("DynamicsOnPremOAuth16.png"), Extension.Contents("DynamicsOnPremOAuth.png"), Extension.Contents("DynamicsOnPremOAuth24.png"), Extension.Contents("DynamicsOnPremOAuth32.png") },
    Icon32 = { Extension.Contents("DynamicsOnPremOAuth32.png"), Extension.Contents("DynamicsOnPremOAuth40.png"), Extension.Contents("DynamicsOnPremOAuth48.png"), Extension.Contents("DynamicsOnPremOAuth64.png") }
];
