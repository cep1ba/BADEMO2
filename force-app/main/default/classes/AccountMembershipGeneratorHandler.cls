/**
 * Created by himanshu on 09/12/2023.
 */

public without sharing class AccountMembershipGeneratorHandler{

    private final Boolean triggerIsExecuting;
    private final Integer triggerSize;
    public  AccountTriggerHelper helper;
    
    public AccountMembershipGeneratorHandler(Boolean triggerIsExecuting, Integer triggerSize) {
        this.triggerIsExecuting = triggerIsExecuting;
        this.triggerSize = triggerSize;
        this.helper = new AccountTriggerHelper();
    }
    public void beforeInsert(List<Account> newAccounts) {
        helper.GenerateMembershipNumber(newAccounts, null);
    }
    public void beforeUpdate(List<Account> oldAccounts, List<Account> newAccounts, Map<Id, Account> oldAccountMap, Map<Id, Account> newAccountMap) {
        helper.GenerateMembershipNumber(newAccounts, oldAccountMap);
    }
    /*
    public void beforeDelete(List<Account> oldAccounts, Map<Id, SObject> oldAccountMap) {

    }
    public void afterInsert(List<Account> newAccounts, Map<Id, SObject> newAccountMap) {

    }
    public void afterUpdate(List<Account> oldAccounts, List<Account> newAccounts, Map<Id, SObject> oldAccountMap, Map<Id, SObject> newAccountMap) {

    }
    public void afterDelete(List<Account> oldAccounts, Map<Id, SObject> oldAccountMap) {

    }
    public void afterUndelete(List<Account> newAccounts, Map<Id, SObject> newAccountMap) {

    }
    */
}