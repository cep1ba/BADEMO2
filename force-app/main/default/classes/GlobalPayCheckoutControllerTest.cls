/**
 * Created by jay on 01/07/2024.
 */

@IsTest
public with sharing class GlobalPayCheckoutControllerTest {
    @TestSetup
    static void createData() {
        Account acc = TestDataFactory.CreateAccount(null, 1, true)[0];
        //List<Contact> contacts = TestDataFactory.CreateContact(acc, 'Student', 10, true);
        List<Contact> contacts = TestDataFactory.CreateContact('Supervising Pharmacist',acc,'Contact', 2, true);
        List<Student_Number_Generator__c> numbers = [SELECT Name FROM Student_Number_Generator__c];
        List<Contact> insertedContacts = [SELECT AccountId, Name, Student_Number__c FROM Contact];

        Map<String, Contact> mapNumberToContact = new Map<String, Contact>();
        for (Contact c : insertedContacts) {
            mapNumberToContact.put(c.Student_Number__c, c);
        }

        Course__c cs = new Course__c(Name = 'ADAC');
        insert cs;

        Module__c mod = new Module__c (Name = 'ADAC', Course__c = cs.Id);
        insert mod;

        Product2 p = new Product2 (IsActive = TRUE, Name = 'Test product', Module__c = mod.Id);
        insert p;

        List<Enrolment__c> enrolments = new List<Enrolment__c>();
        for (Contact c : insertedContacts) {
            Enrolment__c e = new Enrolment__c();
            e.Contact__c = c.Id;
            e.Module__c = e.Id;
            e.EnrolmentFlowGUID__c = String.valueOf(Math.random());
            enrolments.add(e);
        }
        insert enrolments;
    }

    public class RestMock implements HttpCalloutMock {
        private Integer statusCode = 200; // Default status code
        private String globalPayResponse = '{\n' +
                '            "id": "LNK_gk38t7q59lpcZImLtOE8WNsVXGs726",\n' +
                '            "account_name": "paylink",\n' +
                '            "url":"https://apis.sandbox.globalpay.com/ucp/postback/MjAyMTAzMjJfRU9ROXh2",\n' +
                '            "status": "ACTIVE",\n' +
                '\t\t\t"type" : "PAYMENT",\n' +
                '            "usage_mode": "MULTIPLE",\n' +
                '            "token": "GZ3A97jkjn7usydFi2oRePoOfcj",\n' +
                '            "usage_limit": "1000",\n' +
                '            "reference": "Enrolment Course",\n' +
                '            "name":"NPA Courses",\n' +
                '            "description":"5691a2f3f2df529082756882b56a1905628614-1bb5",\n' +
                '            "shippable": "NO",\n' +
                '            "shipping_amount" : "0",\n' +
                '            "viewed_count": "0",\n' +
                '            "expiration_date": "2026-12-20T00:35:28Z",\n' +
                '            "transactions": {\n' +
                '\t\t\t    "channel": "CNP",\n' +
                '\t\t\t    "amount": "1199",\n' +
                '                "currency": "GBP",\n' +
                '                "country" : "GB",\n' +
                '\t\t\t    "allowed_payment_methods":["CARD"]\n' +
                '\t\t\t},\n' +
                '            "images": [],\n' +
                '            "action": {\n' +
                '                "id": "ACT_gk38t7q59lpcZImLtOE8WNsVXGs726",\n' +
                '                "type": "LINK_CREATE",\n' +
                '                "time_created": "2024-07-01T11:11:30.475Z",\n' +
                '                "result_code": "SUCCESS",\n' +
                '                "app_id": "GZ3AyyW24leqR0h0nrEnFi2oRePoOfcj",\n' +
                '                "app_name": "npaportalrestapi"\n' +
                '            }\n' +
                '        }';

        public String transactionStatusJSONResponse = '  {"merchant_id":"MER_7e3e2c7df34f42819b3edee31022ee3f","merchant_name":"Sandbox_merchant_3","account_id":"TRA_e50028826456453db3d127145655de12",' +
                '"account_name":"paylink","id":"LNK_lLgFKkXxxoQ6Z28zTx6wNSFKc64xpF","url":"https://apis.sandbox.globalpay.com/ucp/postback/MjAyMTAzMjJfa0JZY01E","status":"ACTIVE","type":"PAYMENT",' +
                '"usage_mode":"MULTIPLE","usage_limit":"1000","reference":"Enrolment Course","name":"NPA Courses","description":"5691a2f3f2df529082756882b56a1905628614-1bb5","shippable":"NO","shipping_amount":"0",' +
                '"usage_count":"1","viewed_count":"3","expiration_date":"2026-12-20T00:35:28Z","images":[],"notifications":{"return_url":"https://nationalpharmacyassociation--dev.sandbox.my.site.com/npaportal/s/paymentsuccess",' +
                '"status_url":"","cancel_url":"https://nationalpharmacyassociation--dev.sandbox.my.site.com/npaportal/s/paymentcancel"},"transactions":{"amount":"1199","channel":"CNP","country":"GB","currency":"GBP","allowed_payment_methods":["CARD"],' +
                '"transaction_list":[{"id":"TRN_NS4gQkcuCYpLzfYirOx3FY4PcXp9c6_olmentCourse","time_created":"2024-07-01T13:26:10.497Z","status":"CAPTURED","type":"SALE","channel":"CNP","amount":"1199","currency":"GBP","reference":"Enrolment Course"}]},' +
                '"action":{"id":"ACT_hAncc3fOpLCKyDGn7cmy0jiDf3Ku22","type":"LINK_SINGLE","time_created":"2024-07-01T13:26:18.762Z","result_code":"SUCCESS","app_id":"GZ3AyyW24leqR0h0nrEnFi2oRePoOfcj","app_name":"npaportalrestapi"}}';

        public RestMock(Integer statusCode) {
            this.statusCode = statusCode;
        }

        public HttpResponse respond(HttpRequest req) {
            String fullJson = globalPayResponse;

            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'text/json');
            res.setBody(fullJson);
            res.setStatusCode(statusCode); // Use the dynamically set status code
            return res;
        }
    }

    @IsTest
    static void testSuccessfulAPICall() {
        Enrolment__c enrolment = [SELECT Id, Name, EnrolmentFlowGUID__c FROM Enrolment__c WHERE EnrolmentFlowGUID__c != NULL LIMIT 1];
        System.assertNotEquals(null, enrolment);

        // Set the mock for the HTTP callout
        RestMock mock = new RestMock(200);
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        String paymentURL = GlobalPayCheckoutController.retrieveEnrolment(enrolment.EnrolmentFlowGUID__c, '72', '1x HLC Course', '60', '72');
        Test.stopTest();

        System.assertEquals('"https://apis.sandbox.globalpay.com/ucp/postback/MjAyMTAzMjJfRU9ROXh2"', paymentURL);
    }

    @IsTest
    static void testUnsuccessfulAPICall() {
        // Set the mock for the HTTP callout
        RestMock mock = new RestMock(400);
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        try {
            String paymentURL = GlobalPayCheckoutController.retrieveEnrolment('1', '100', '1', '1', '1');
        } catch (Exception ex) {
            System.assertEquals('Unauthorized', ex.getMessage());
            System.assertEquals(20, ex.getLineNumber());
        }
        Test.stopTest();

    }


    @IsTest
    static void testUnsuccessfulTranStatusCall() {
        Test.startTest();
        // Set the mock for the HTTP callout
        RestMock mock = new RestMock(400);
        HttpRequest request = new HttpRequest();
        request.setBody(mock.transactionStatusJSONResponse);
        mock.respond(request);

        Test.setMock(HttpCalloutMock.class, mock);

        try {
            GlobalPayCheckoutController.checkTransactionStatus('invalidTransactionId');
        } catch (Exception ex) {
            System.assertEquals('Unauthorized', ex.getMessage());
            System.assertEquals(20, ex.getLineNumber());
        }
        Test.stopTest();
    }

    /*
    @IsTest
    static void testSuccessfulTranStatusCall() {
        Test.startTest();
        // Set the mock for the HTTP callout
        RestMock mock = new RestMock(200);
        mock.globalPayResponse = mock.transactionStatusJSONResponse;
        Test.setMock(HttpCalloutMock.class, mock);
        try {
            GlobalPayCheckoutController.checkTransactionStatus('LNK_lLgFKkXxxoQ6Z28zTx6wNSFKc64xpF');
        } catch (Exception ex) {
            //System.assertEquals('Unauthorized', ex.getMessage());
            //System.assertEquals(20, ex.getLineNumber());
        }
        Test.stopTest();
    }

     */

    @IsTest
    static void testUpdateEnrolments() {
        List<String> enrolmentsToUpdate = new List<String>();
        Enrolment__c enrolment = [SELECT Id, Name, EnrolmentFlowGUID__c FROM Enrolment__c WHERE EnrolmentFlowGUID__c != NULL LIMIT 1];
        System.assertNotEquals(null, enrolment);
        enrolmentsToUpdate.add(enrolment.EnrolmentFlowGUID__c);

        Test.startTest();
        GlobalPayEnrolmentUpdate.updateEnrolments(enrolmentsToUpdate, 'Accepted', 'Completed','PaymentRef');
        Test.stopTest();

        Enrolment__c updatedEnrolment = [SELECT Id, Name, EnrolmentFlowGUID__c, Status__c FROM Enrolment__c WHERE EnrolmentFlowGUID__c != NULL AND Id = :enrolment.Id];
        System.assertEquals('Accepted', updatedEnrolment.Status__c);
    }

}