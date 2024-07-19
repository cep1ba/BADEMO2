/******************************************************************************
* Author: BA Westbrook
* Date: 11/06/2024
* Descpription: Knowledge Search
*/

public with sharing class LWCKnowledgeSearchController {

    public class ArticleWrapper {
        @AuraEnabled public List<KnowledgeCategory__mdt> categoryList;
        @AuraEnabled public List<Knowledge__kav> articleList;
        public ArticleWrapper (List<KnowledgeCategory__mdt> categoryList, List<Knowledge__kav> articleList){
            this.categoryList = categoryList;
            this.articleList = articleList;
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static ArticleWrapper getCategoryPlusArticle (String category) {
        return new ArticleWrapper (getCategories(category),null);
        //return new ArticleWrapper (getCategories(category),getKnowledgeByCategory(category));
    }
    
    @AuraEnabled(cacheable=true)
    public static List<KnowledgeCategory__mdt> getCategories (String category) {
        system.debug('category='+category);
        List<KnowledgeCategory__mdt> mdtTypes;
        if(String.isBlank(category)){
            mdtTypes = [SELECT order__c,Label,Summary__c,Style__c,Icon__c,Parent__c,Has_Children__c,URL__c FROM KnowledgeCategory__mdt where Parent__c = null order by order__c];
        }
        else{
            category = category.replace('%20',' ');
            mdtTypes = [SELECT order__c,Label,Summary__c,Style__c,Icon__c,Parent__c,Has_Children__c,URL__c FROM KnowledgeCategory__mdt where Parent__c = :category order by order__c];
        }
        
        system.debug('mdtTypes ='+mdtTypes );
        return mdtTypes ;
    }
    

    @AuraEnabled(cacheable=true)
    public static List<Knowledge__kav> getAll () {
        List<Knowledge__kav> knowledgeList = [SELECT Id, Title, Summary,CreatedDate,ArticleTotalViewCount,KnowledgeArticleId FROM Knowledge__kav where PublishStatus='Online'];
        return knowledgeList;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Knowledge__kav> getKnowledgeByCategory(String category) {
        system.debug('category='+category);
        String query = 'SELECT Id, Title, URL__c, Summary,CreatedDate,ArticleTotalViewCount,KnowledgeArticleId FROM Knowledge__kav';
        query += ' where PublishStatus=\'Online\' AND (Tier1__c INCLUDES (\'' + category + '\') OR Tier2__c INCLUDES (\'' + category + '\'))';
        
        system.debug('query='+query);
        
        List<Knowledge__kav> articles = Database.query(query);
        return articles;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Knowledge__kav> searchKnowledgeArticles(String searchText) {
        system.debug('searchText='+searchText);
        List<Knowledge__kav> knowledgeArticlesList = new List<Knowledge__kav>();
        if (searchText != '' && searchText != null) {
            for(Knowledge__kav kav : [SELECT Id, Title, Summary,URL__c,Description__c,CreatedDate,ArticleTotalViewCount FROM Knowledge__kav where PublishStatus='Online']) {
                if(kav.Title.containsIgnoreCase(searchText) || kav.Description__c.containsIgnoreCase(searchText))
                    knowledgeArticlesList.add(kav);
            }
        }
        return knowledgeArticlesList;
    }
    
    /*@AuraEnabled
    public static Knowledge__kav getArticle(String articleId) {
        Knowledge__kav article = [SELECT Id, Title, Summary,URL__c,Description__c,CreatedDate,ArticleTotalViewCount FROM Knowledge__kav where PublishStatus=:articleId UPDATE VIEWSTAT];
        return article;
    }*/
}