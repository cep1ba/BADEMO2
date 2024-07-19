/**
 * Created by himanshu on 14/12/2023.
 */

public without sharing class AccountTriggerHelper {
    public AccountTriggerHelper() {
        System.debug('Inside AccountTriggerHelper Constructor');
    }

    public  void GenerateMembershipNumber( List<Account> accounts, Map<Id, Account> oldAccounts ) {
        List<Membership_Number_Generator__c> generators = new List<Membership_Number_Generator__c>();
        Integer i = 0;
        Set <Id> generatorIds = new Set<Id>();
        for (Account acc : accounts) {
            if(acc.Membership_Number__c == null) {
                if (oldAccounts != null) {
                    if (acc.Join_Date__c != null) {
                        generators.add(new Membership_Number_Generator__c());
                    }
                }
                else if (acc.Join_Date__c != null) {
                     generators.add(new Membership_Number_Generator__c());
                }
            }
        }
        
        system.debug('generators='+generators);
        
        if(!generators.isEmpty()){
            insert generators;
            
            for (Membership_Number_Generator__c g : generators) {
                generatorIds.add(g.Id);
            }
            
            generators = [SELECT Name, Id FROM Membership_Number_Generator__c WHERE Id IN :generatorIds];
    
            for (Account acc : accounts) {
                if(acc.Membership_Number__c == null) {
                    if (oldAccounts != null) {
                        if (acc.Join_Date__c != null) {
                            acc.Membership_Number__c =  generators[i].Name;
                            i++;
                        }
                    }
                    else if (acc.Join_Date__c != null) {
                         acc.Membership_Number__c =  generators[i].Name;
                         i++;
                    }
                }
            }
        }
        system.debug('accounts='+accounts);
    }

}