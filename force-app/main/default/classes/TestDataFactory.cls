/** TestDataFactory
 *  @author: Ben Alexander
 *  @date: 19/12/2023
 *  @description: Class for test data generation
 *  @version: 1.0
 */

@IsTest
public class TestDataFactory {    
    public static List<Account> CreateAccount(String recordTypeName, Integer numRecords, Boolean doInsert) {
        Id recTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Subscriber').getRecordTypeId();
        if(String.isNotBlank(recordTypeName)){
            recTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(recordTypeName).getRecordTypeId();
        }
        List<Account> newRecords = new List<Account>();
        for (Integer i = 0; i < numRecords; i++) {
            Account rec = new Account();
            rec.Name = 'Test ' + i +' ' + GenerateHash();
            rec.Phone='+44777444555';
            rec.ShippingStreet='1 Test Rd';
            rec.ShippingCity='Reading';
            rec.ShippingPostalCode='RG1 1TT';
            rec.Join_Date__c=Date.Today();
            newRecords.add(rec);
        }
        if (doInsert) {
            insert newRecords;
        }
        return newRecords ;
    }
    
    public static List<Contact> CreateContact(String type, Account acc,String recordTypeName, Integer numRecords, Boolean doInsert) {
        Id recTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Contact').getRecordTypeId();
        if(String.isNotBlank(recordTypeName)){
            recTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get(recordTypeName).getRecordTypeId();
        }
        List<Contact> newRecords = new List<Contact>();
        for (Integer i = 0; i < numRecords; i++) {
            Contact rec = new Contact();
            rec.AccountId = acc.Id;
            rec.FirstName = 'Ben';
            rec.LastName = 'Test ' + i +' ' + GenerateHash();
            rec.Email = 'test@gmail.com';
            rec.Phone = '+44777444555';
            rec.RecordTypeId = recTypeId;
            rec.Type__c = type;
            newRecords.add(rec);
        }
        if (doInsert) {
            insert newRecords;
        }
        return newRecords ;
    }

    public static List<Enrolment__c> CreateEnrolments(List <Contact> insertedContacts, Boolean doInsert, Id moduleId, Id accId) {
        List<Enrolment__c> newRecords = new List<Enrolment__c>();
        for (Contact c : insertedContacts) {
            Enrolment__c e = new Enrolment__c();
            e.Account__c = accId;
            e.Contact__c = c.Id;
            e.Module__c = moduleId;
            newRecords.add(e);
        }
        system.debug(newRecords);
        if (doInsert) {
            insert newRecords;
        }
        return newRecords;
    }

    public static List<Opportunity> CreateOpportunity(String recordTypeName, Integer numRecords, Boolean doInsert, Id accId) {
        List<Opportunity> newRecords = new List<Opportunity>();
        for (Integer i = 0; i < numRecords; i++) {
            Opportunity rec = new Opportunity();
            rec.AccountId = accId;
            rec.StageName = 'Qualification';
            rec.CloseDate = Date.Today();
            rec.Name = 'Test ' + i +' ' + GenerateHash();
            newRecords.add(rec);
        }
        if (doInsert) {
            insert newRecords;
        }
        return newRecords ;
    }
    
    public static List<Quote> CreateQuote(String recordTypeName, Integer numRecords, Boolean doInsert, Id oppId) {
        List<Quote> newRecords = new List<Quote>();
        for (Integer i = 0; i < numRecords; i++) {
            Quote rec = new Quote();
            rec.OpportunityId = oppId;
            rec.Name ='Test ' +i +' ' +GenerateHash();
            newRecords.add(rec);
        }
        if (doInsert) {
            insert newRecords;
        }
        return newRecords ;
    }


    public static User createUser(Contact contact, String userName, String profileName) {
        Id roleId = getUserRole('NPA_Base_Role').Id;
        String uniqueAlias = getUniqueAlias();
        Id ProfileID = [SELECT Id, UserType FROM Profile WHERE Name = :profileName].Id;
        User newUser = new User(Email = userName, ProfileId = ProfileID,
                Username = userName, Alias = uniqueAlias, CommunityNickname = uniqueAlias,
                TimeZoneSidKey = 'America/New_York', LocaleSidKey = 'en_US', EmailEncodingKey = 'ISO-8859-1',
                LanguageLocaleKey = 'en_US', FirstName = 'Test UserFirstName', LastName = 'Test lastname');
        if (contact != null) {
            newUser.ContactId = contact.Id; //portal user
        } else {
            newUser.UserRoleId = roleId; //Run as user requires roleId. Default VP_Sales
        }

        insert newUser;
        return newUser;
    }
    
    public static User createPortalUser(String conId, Boolean doInsert) {
        String profileId = [SELECT Id FROM Profile WHERE Name = 'Customer Community NPA' LIMIT 1].Id;
        Contact con = [SELECT Id,FirstName, LastName, AccountId, Email FROM Contact WHERE Id = :conId  LIMIT 1];
        
        User portalUser = new User(
            FirstName = con.FirstName,
            LastName = con.LastName,
            Email = con.Email,
            ContactId = conId,
            Username = 'test-' + Math.random() + '@dev.com',
            Alias = 'TestDev',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profileId ,
            LanguageLocaleKey = 'en_US'
        );
        
        if (doInsert) {
            insert portalUser;
        }
        return portalUser;
    }

    public static UserRole getUserRole(final String roleDeveloperName) {
        UserRole role = [SELECT Id FROM UserRole WHERE DeveloperName = :roleDeveloperName];
        System.assertNotEquals(null, role, 'UserRole with DeveloperName ' + roleDeveloperName + ' not found');
        return role;
    }

    //Get unique aliase for the Users
    public static String getUniqueAlias() {
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueOf(Datetime.now())
                .replace(' ', '')
                .replace(':', '')
                .replace('-', '');
        Integer randomInt = Integer.valueOf(Math.rint(Math.random() * 100000));
        String uniqueName = orgId + randomInt + dateString;
        return uniqueName.substring(18, 23);
    }

    public static String GenerateHash() {
        Blob b = Crypto.GenerateAESKey(128);
        String h = EncodingUtil.ConvertTohex(b);
        return h;
    }
}