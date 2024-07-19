/**
 * An apex page controller that supports self registration of users in communities that allow self registration
 */
public class CommunitiesSelfRegController {
    public String firstName {get; set;}
    public String lastName {get; set;}
    public String email {get; set;}
    public String password {get; set {password = value == null ? value : value.trim(); } }
    public String confirmPassword {get; set { confirmPassword = value == null ? value : value.trim(); } }
    public String postcode { get; set; }
    public String membershipNumber { get; set; }
    
    public CommunitiesSelfRegController() {
        String expid = ApexPages.currentPage().getParameters().get('expid');            
        if (expId != null) {
            Site.setExperienceId(expId); 
        }    
    }

    public PageReference registerUser() {
        String profileId = [SELECT Id, Name FROM Profile where name ='Customer Community NPA'].Id;
        
        if (String.isBlank(password)) {
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Please enter a password');
            ApexPages.addMessage(msg);
            return null;
        }
        if (password != confirmPassword || password.length() < 8) {
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Passwords must match and be longer than 8 characters');
            ApexPages.addMessage(msg);
            return null;
        }
        
        List<User> users = [SELECT Id FROM User WHERE ProfileId = :profileId AND IsActive = true and Email = :email];
        if (!users.isEmpty()) {
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'User exists already exists for that email. Please use the Forget Password Link.');
            ApexPages.addMessage(msg);
            return null;
        }
        
        system.debug('membershipNumber='+membershipNumber);
        system.debug('postcode='+postcode);
        
        List<Account> accs = [SELECT Id FROM Account WHERE Membership_Number__c = :membershipNumber AND ShippingPostalCode = :postcode ORDER BY CreatedDate DESC];
        system.debug('accs='+accs);
        if (accs.isEmpty()) {
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Branch not found for that Memberhsip Number and Postcode');
            ApexPages.addMessage(msg);
            return null;
        }
        
        List<Contact> contacts= [SELECT Id, FirstName FROM Contact WHERE Email = :email AND LastName = :lastName ORDER BY Primary__c,CreatedDate DESC];
        if (contacts.isEmpty()) {
            Contact con = new Contact(
                FirstName = firstName, LastName = lastName, Email = email, AccountId = accs[0].Id, Type__c = 'Supervising Pharmacist'
            );
            insert con;
            contacts= [SELECT Id, FirstName FROM Contact WHERE Email = :email AND LastName = :lastName ORDER BY Primary__c,CreatedDate DESC];
        }

        String accountId = accs[0].Id;

        User u = new User();
        u.Username = email;
        u.Email = email;
        u.FirstName = contacts[0].FirstName;
        u.ContactId = contacts[0].Id;
        u.LastName = lastName;
        u.CommunityNickname = u.FirstName + String.valueOf(Math.abs(Crypto.getRandomInteger())).leftPad(20);
        u.ProfileId = profileId;
        
        String userId;

        try {
            userId = Site.createExternalUser(u, accountId, password);
        } catch(Site.ExternalUserCreateException ex) {
            List<String> errors = ex.getDisplayMessages();
            for (String error : errors)  {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, error));
            }
            
            // This message is used for debugging. Do not display this in the UI to the end user.
            // It has the information around why the user creation failed.
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            System.debug(ex.getMessage());
        }
        
        if (userId != null) { 
            if (password != null && password.length() > 1) {
                return Site.login(email, password, ApexPages.currentPage().getParameters().get('startURL'));
            }
            else {
                PageReference page = System.Page.CommunitiesSelfRegConfirm;
                page.setRedirect(true);
                return page;
            }
        }
        return null;
    }
}