/**
 * An apex page controller that exposes the site login functionality
 * https://github.com/salesforceidentity/basic-custom-login
 */
global with sharing class SigninController {
    global String username {get; set;}
    global String password {get; set;}
    public String orgId {get; set;}
    public String siteURL  {get; set;}
    public String startURL {get; set;}
    public List<AuthProvider> authProviders {get;set;}
    
    global SigninController () {
        orgId = UserInfo.getOrganizationId();
        siteURL  = Site.getBaseUrl();
        startURL = System.currentPageReference().getParameters().get('startURL');
        if (startURL == null) startURL = '/';
        authProviders = [SELECT Id,DeveloperName,FriendlyName,ProviderType FROM AuthProvider];
    }

    global PageReference login() {
        return Site.login(username, password, startUrl);
    }    
}