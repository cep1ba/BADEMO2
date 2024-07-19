@isTest
public class LWCKnowledgeSearchControllerTest {

    @isTest
    public static void testGetCategories (){
        knowledge__kav newArticle = new knowledge__kav(Title='test',Tier1__c = 'Patient Safety', Tier2__c = 'Incident reporting(UK)', urlname='xyz',Description__c='TESTCLASS');
        insert newArticle;
        
        LWCKnowledgeSearchController.getCategories ('');
    }
    
    @isTest
    public static void testGetAll (){
        insert new knowledge__kav(Title='test',Tier1__c = 'Patient Safety', Tier2__c = 'Incident reporting(UK)', urlname='xyz',Description__c='TESTCLASS');        
        knowledge__kav newArticle = [SELECT KnowledgeArticleId FROM Knowledge__kav limit 1];
        
        KbManagement.PublishingService.publishArticle(newArticle.KnowledgeArticleId , true);
        
        LWCKnowledgeSearchController.getAll();
    }
    
    @isTest
    public static void testGetKnowledgeByCategory (){
        knowledge__kav newArticle = new knowledge__kav(Title='test',Tier1__c = 'Patient Safety', Tier2__c = 'Incident reporting(UK)', urlname='xyz',Description__c='TESTCLASS');
        insert newArticle;
        
        LWCKnowledgeSearchController.getKnowledgeByCategory ('Patient Safety');
    }
    
    @isTest
    public static void testGetKnowledgeArticles(){
        insert new knowledge__kav(Title='test',Tier1__c = 'Patient Safety', Tier2__c = 'Incident reporting(UK)', urlname='xyz',Description__c='TESTCLASS');        
        knowledge__kav newArticle = [SELECT KnowledgeArticleId FROM Knowledge__kav limit 1];
        
        KbManagement.PublishingService.publishArticle(newArticle.KnowledgeArticleId , true);
        
        LWCKnowledgeSearchController.getKnowledgeArticles ('TESTCLASS');
    }
}