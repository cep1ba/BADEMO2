/**
 * Created by Jay Halpati on 24/06/2024.
 */

public with sharing class GlobalPayCheckoutController {
    public static String paymentURL;
    public static String transactionStatus;

    // declaring variables for API call
    static String accountId;
    static String accountName;
    static String merchantId;
    static String appKey;
    static String appId;
    static String baseURL;
    static String cancelURL;
    static String returnURL;
    static String accessTokenURL;


    /* method to retrieve an Enrolment record based on an enrolmentId, create a JSON body, make an API call and return a URL */
    @AuraEnabled(Cacheable=true)
    public static String retrieveEnrolment(String enrolmentGroupId, String amount, String description, String coursePrice, String totalPrice) {
        //public static String retrieveEnrolment(String enrolmentGroupId, String amount) {
        String jsonBody = createJSONBody(enrolmentGroupId, amount, description, coursePrice, totalPrice); //creating JSON body
        jsonBody = jsonBody.replace('"customerCurrency"', '"currency"'); //as currency is a reserved word in Apex

        String finalURL = makeAPICall(jsonBody); //making the API call and retrieving the Payment URL
        return finalURL;
    }

    /* method to create JSON body for API call */
    public static String createJSONBody(String enrolmentGroupId, String amount, String description, String coursePrice, String totalPrice) {
        // Declaring required Custom Metadata types for further usage
        List<GlobalPay_Integration_Param__mdt> globalPayCredentials = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox ?
                [SELECT DeveloperName, Merchant_Id__c, Account_Name__c, Account_Id__c, Return_URL__c, Cancel_URL__c, Base_URL__c, App_Id__c, App_Key__c, Access_Token_URL__c FROM GlobalPay_Integration_Param__mdt
                WHERE DeveloperName = 'SANDBOX_Salesforce_to_GlobalPay'] : [SELECT DeveloperName, Merchant_Id__c, Account_Name__c, Account_Id__c, Return_URL__c, Cancel_URL__c, Base_URL__c, App_Id__c, App_Key__c, Access_Token_URL__c FROM GlobalPay_Integration_Param__mdt
                WHERE DeveloperName = 'PRODUCTION_Salesforce_to_GlobalPay'];

        // looping through Integration_Parameter__mdt to assign values to variables needed for http call
        for (GlobalPay_Integration_Param__mdt mdt : globalPayCredentials) {
            accountId = mdt.Account_Id__c;
            accountName = mdt.Account_Name__c;
            merchantId = mdt.Merchant_Id__c;
            appKey = mdt.App_Key__c;
            appId = mdt.App_Id__c;
            baseURL = mdt.Base_URL__c;
            cancelURL = mdt.Cancel_URL__c;
            returnURL = mdt.Return_URL__c;
            accessTokenURL = mdt.Access_Token_URL__c;
        }

        JSONGenerator mt = new JSONGenerator(); // utilising JSONGenerator Apex class
        mt.merchant_id = merchantId;
        mt.account_name = accountName;
        mt.account_id = accountId;
        mt.type = 'PAYMENT';
        mt.usage_mode = 'MULTIPLE';
        mt.usage_limit = '1000';
        mt.reference = enrolmentGroupId;
        //mt.name = 'NPA Courses';
        mt.name = description;
        mt.description = 'Total Price (incl. VAT & Discount) : £' + totalPrice;
        mt.shippable = 'NO';
        mt.expiration_date = String.valueOf(System.today() + 1); // Payment ink will be valid for 24 hours post its creation

        mt.transactions = new JSONGenerator.Transactions();
        mt.transactions.allowed_payment_methods = new List<String>{
                'CARD'
        };

        Decimal calculatedAmount = Decimal.valueOf(amount) * 100;  // amount needs to be calculated by 100; as the APIs amount field is a string and when raw amount is passed, incorrect amount is displayed on the payments page or an error is displayed
        mt.transactions.amount = String.valueOf(calculatedAmount.setScale(0).toPlainString()); // using .toPlainString to get rid of .0 from the decimal Ex: 10.0 will be 10
        mt.transactions.channel = 'CNP';
        mt.transactions.country = 'GB';
        mt.transactions.customerCurrency = 'GBP'; // currency word is reserved

        mt.notifications = new JSONGenerator.Notifications();
        mt.notifications.return_url = returnURL;
        mt.notifications.cancel_url = cancelURL;

        return JSON.serialize(mt);

    }

    //@Future(Callout=true)
    public static String makeAPICall(String jsonBody) {
        // Preparing HTTP request
        Http http = new Http();
        HttpRequest request = Utility.createHTTPHttpRequest(baseURL, 'GET');

        String secret = Utility.generateAccessToken(accessTokenURL, appId, appKey); //utilising a custom method to generate an Access token, as a new Access token is needed for each API call
        String authorizationHeader = 'Bearer ' + secret;
        request.setHeader('Authorization', authorizationHeader.replace(':', '')); //
        request.setBody(jsonBody);

        // response from API call and retrieving body of the response
        HttpResponse response = http.send(request);
        String jsonResponse = response.getBody();

        try {
            if (response.getStatusCode() == 200) {
                String retrievedURL = jsonResponse.substringBetween('url', ',');
                String provURL = retrievedURL.substringAfter(':');
                paymentURL = provURL;
            } else {
                System.debug('An error occurred');
            }

        } catch (Exception ex) {

            return ex.getMessage();
        }
        return paymentURL;
    }

    /* method to retrieve transaction status of a transaction from GlobalPay */
    @AuraEnabled(Cacheable=true)
    public static String checkTransactionStatus(String transactionId) {

        /* Need to retrieve GlobalPay_Integration_Param__mdt again as this is a brand new transaction */
        // Declaring required Custom Metadata types for further usage
        List<GlobalPay_Integration_Param__mdt> globalPayCredentials = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox ?
                [SELECT DeveloperName, Merchant_Id__c, Account_Name__c, Account_Id__c, Return_URL__c, Cancel_URL__c, Base_URL__c, App_Id__c, App_Key__c, Access_Token_URL__c FROM GlobalPay_Integration_Param__mdt
                WHERE DeveloperName = 'SANDBOX_Salesforce_to_GlobalPay'] : [SELECT DeveloperName, Merchant_Id__c, Account_Name__c, Account_Id__c, Return_URL__c, Cancel_URL__c, Base_URL__c, App_Id__c, App_Key__c, Access_Token_URL__c
                FROM GlobalPay_Integration_Param__mdt WHERE DeveloperName = 'PRODUCTION_Salesforce_to_GlobalPay'];

        // looping through Integration_Parameter__mdt to assign values to variables needed for http call
        for (GlobalPay_Integration_Param__mdt mdt : globalPayCredentials) {
            accountId = mdt.Account_Id__c;
            accountName = mdt.Account_Name__c;
            merchantId = mdt.Merchant_Id__c;
            appKey = mdt.App_Key__c;
            appId = mdt.App_Id__c;
            baseURL = mdt.Base_URL__c;
            cancelURL = mdt.Cancel_URL__c;
            returnURL = mdt.Return_URL__c;
            accessTokenURL = mdt.Access_Token_URL__c;
        }


        // Preparing HTTP request
        Http http = new Http();
        HttpRequest request = Utility.createHTTPHttpRequest(baseURL + '/' + transactionId, 'POST');
        String secret = Utility.generateAccessToken(accessTokenURL, appId, appKey); //utilising a custom method to generate an Access token, as a new Access token is needed for each API call
        request.setMethod('GET'); //setting "GET" here as in Utility.generateAccessToken() method is set to "POST"
        String authorizationHeader = 'Bearer ' + secret;
        request.setHeader('Authorization', authorizationHeader.replace(':', ''));


        // response from API call and retrieving body of the response
        HttpResponse response = http.send(request);
        String jsonResponse = response.getBody();

        if (response.getStatusCode() == 200) {
            transactionStatus = jsonResponse;
        } else {
            System.debug('An error occurred');
            transactionStatus = 'An error occurred during the API call';
        }

        return transactionStatus;
    }

}