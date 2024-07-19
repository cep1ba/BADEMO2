/**
 * Created by himanshu on 14/12/2023.
 */

public with sharing class Utility {

    public static void InsertToNebula( Database.Error err ) {
        System.debug(err.getStatusCode() + ': ' + err.getMessage());
        Nebula__Log__c log = new Nebula__Log__c();
        log.Nebula__Comments__c = 'Error Account/Number Generator record creation : ' + err.getMessage();
        log.Nebula__LoggedBy__c = UserInfo.getUserId();
        log.Nebula__LoggedByUsername__c = UserInfo.getUserName();
        insert log;
    }
    
    public static String getNonce () {
        return String.valueOf(DateTime.now()).replace(' ','T');
    }
    
    public static String encrypt (String nonce, String appKey) {
        //secret = SHA512(nonce + app_key)
        //String nonce = Utility.getNonce();
        //system.debug(nonce);
        //system.debug(Utility.encrypt(nonce, 'mUcgakHbavlKqthO'));
        
        String secret = nonce + appKey;
        Blob digest = Crypto.generateDigest('SHA-512', Blob.valueOf(secret));
        String encryptedString = EncodingUtil.convertToHex(digest);
        return encryptedString;
    }

    /* method to create a HTTP request, by passing a URL and the call type */
    public static HttpRequest createHTTPHttpRequest(String baseURL, String callType) {
        // Preparing HTTP request
        HttpRequest request = new HttpRequest();
        request.setEndpoint(baseURL);
        request.setMethod(callType);
        request.setHeader('content-type', 'application/json');
        request.setHeader('x-gp-version', '2021-03-22');

        return request;
    }

    /* method to generate an Access token, as a new Access token is needed for each API call */
    public static String generateAccessToken(String accessTokenEndpointURL, String appIdAC, String appKeyAC) {

        String baseUrl = accessTokenEndpointURL;
        String appId = appIdAC;
        String appKey = appKeyAC;
        String encryptedString = Utility.encrypt(System.now().toString(), appKey);

        JSONGenerator.JsonParser jsonBody = new JSONGenerator.JsonParser();
        jsonBody.app_id = appId;
        jsonBody.nonce = System.now().toString();
        jsonBody.secret = encryptedString;
        jsonBody.grant_type = 'client_credentials';

        // Preparing HTTP request
        Http http = new Http();
        HttpRequest request = createHTTPHttpRequest(baseUrl, 'POST');
        request.setHeader('Content-length', String.valueOf(encryptedString.length()));
        request.setBody(JSON.serialize(jsonBody));

        // response from API call and retrieving body of the response
        HttpResponse response = http.send(request);
        String accessToken = response.getBody().substringBetween('token', ',').replace('"', '');

        return accessToken;
    }
}