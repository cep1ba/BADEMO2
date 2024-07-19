/**
 * Created by BA Westbrook on 13/06/24
 */

@IsTest
private class LWCEnrolmentBulkTest {
    @IsTest
    static void test() {
        Account acc = TestDataFactory.CreateAccount(null, 1, true)[0];
        
String body = 'LastName,FirstName,Company,Title,LeadSource,Email, STORE_Verified__c, Targeted__c, Description\n '+
        'me,Test,Test Company ,CEO,Other,me.Test@TestCompany.com,TRUE, 12/01/2022, This is a long text description. Please take a look and then tell us if this has passed.\n' +
        'you,Test,Test Company ,CIO,Other,you.Test@TestCompany.com,TRUE, 12/01/2022, This is a long text description. Please take a look and then tell us if this has passed.\n' +
        'Us,Test,Test Company ,CTO,Other,Us.Test@TestCompany.com,TRUE, 12/01/2022, This is a long text description. Please take a look and then tell us if this has passed.\n' +
        'tester5,Test,Test Company ,CXO,Other,tester5.Test@TestCompany.com,TRUE, 12/01/2022, This is a long text description. Please take a look and then tell us if this has passed.\n' +
        'tester1,Test,Test Company ,COO,Other,tester1.Test@TestCompany.com,TRUE, 12/01/2022, This is a long text description. Please take a look and then tell us if this has passed.\n' +
        'tester2,Test,Test Company ,CSO,Other,tester2.Test@TestCompany.com,TRUE, 12/01/2022, This is a long text description. Please take a look and then tell us if this has passed.\n' +
        'tester3,Test,Test Company ,"Vp, Technology",Other,tester3.Test@TestCompany.com,TRUE, 12/01/2022, This is a long text description. Please take a look and then tell us if this has passed.\n' +
        'tester4,Test,Test Company ,"VP, Clicent Success",Other,tester4.Test@TestCompany.com,TRUE, 12/01/2022, This is a long text description. Please take a look and then tell us if this has passed.';
    
        ContentVersion testConVersion = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'Test Enrolment.csv',
            VersionData = Blob.valueOf(body),
            IsMajorVersion = true
        );
        Insert testConVersion;
        testConVersion = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :testConVersion.Id LIMIT 1];
        ContentDocumentLink testDocLink = new ContentDocumentLink(
            ContentDocumentId = testConVersion.ContentDocumentId,
            LinkedEntityId = acc.Id
        );
        Insert testDocLink;
        
        LWCEnrolmentBulk.loadFile(acc.Id);
    }
}