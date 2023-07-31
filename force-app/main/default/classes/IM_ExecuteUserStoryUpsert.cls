/**
 * @description Upserts an External User Story into Copado's User Story.
 *
 * @author Deepak Shukla
 * @version 1.0
 */

public class IM_ExecuteUserStoryUpsert implements Database.Batchable<Object>{
    List<Map<String,String>> listJiraStories;
    Map<String,Map<String,String>> mapProjectFieldMap;
    List<copado__User_Story__c> userStories2Upsert;
    
    /**
    * @description constructor to have JIRA Stories and Fields Map 
    * @param listJiraStoriesParam
    * @param mapProjectFieldMapParam
    */
    public IM_ExecuteUserStoryUpsert(List<Map<String,String>> listJiraStoriesParam, Map<String,Map<String,String>> mapProjectFieldMapParam){
        this.listJiraStories = new List<Map<String,String>>();
        this.mapProjectFieldMap = new Map<String,Map<String,String>>();
        this.listJiraStories = listJiraStoriesParam;
        this.mapProjectFieldMap = mapProjectFieldMapParam;
    }

    /**
    * @description Finds related instance based on external system to use via factory pattern, fetches and parses the JSON and return to execute method
     * @param bc
     * @return Iterable<Object>
    */
    public Iterable<Object> start(Database.BatchableContext bc){
        return new CallIterable(this.listJiraStories);
    }

    /**
    * @description prepare list of user stories
     * @param bc
     * @param scope
    */
    public void execute(Database.BatchableContext bc, List<Object> scope){
        this.userStories2Upsert = new List<copado__User_Story__c>();
        Map<String,copado__User_Story__c> mapProjectIdJiraIdKeyAndUS = new Map<String,copado__User_Story__c>();
        Set<String> projectIds = new Set<String>();
        Set<String> jiraIds = new Set<String>();
        //loops among user story Items Map
        for(Object usItem:scope){
            Map<String,String> tempMap = (Map<String,String>)usItem;
            String pid = tempMap.get('projectid');
            String jiraid = tempMap.get('id');
            projectIds.add(pid);
            jiraIds.add(jiraid);
            Map<String,String> fieldMap = this.mapProjectFieldMap.get(pid);
            sObject sobj = new copado__User_Story__c();
            //loops among field Mapping items under related project
            for(String s: fieldMap.keyset()){
                s = s.toLowerCase();
                //puts the value on sf Object if the current user story item value Map stores current field Map keyset
                if(tempMap.containsKey(fieldMap.get(s))){
                    sobj.put(s,CopadoCCMutilities.returnCastedValue(tempMap.get(fieldMap.get(s)),s));
                }
            }
            String key = Id.valueOf(pid) + '_' + jiraid;
            mapProjectIdJiraIdKeyAndUS.put(key, (copado__User_Story__c)sobj);
        }

        Boolean isByPass = true;
        Map<String,List<copado__User_Story__c>> mapProjectIdJiraIdKeyAndListUS = new Map<String,List<copado__User_Story__c>>();
        if(Schema.sObjectType.copado__User_Story__c.isAccessible() || isByPass){
            List<copado__User_Story__c> existingUS = [SELECT Id,copado__Project__c,External_Id__c FROM copado__User_Story__c WHERE copado__Project__c IN:projectIds AND External_Id__c IN:jiraIds];
            for(copado__User_Story__c us : existingUS){
                String key = us.copado__Project__c + '_' + us.External_Id__c;
                List<copado__User_Story__c> listUS = (mapProjectIdJiraIdKeyAndListUS.containsKey(key)? mapProjectIdJiraIdKeyAndListUS.get(key):(new List<copado__User_Story__c>()));
                listUS.add(us);
                mapProjectIdJiraIdKeyAndListUS.put(key,listUS);
            }
        }

        for(String key : mapProjectIdJiraIdKeyAndUS.keyset()){
            copado__User_Story__c us = mapProjectIdJiraIdKeyAndUS.get(key);
            Boolean isProcess = true;
            if(mapProjectIdJiraIdKeyAndListUS.containsKey(key)){
                List<copado__User_Story__c> listUS = mapProjectIdJiraIdKeyAndListUS.get(key);
                if(listUS.size() > 1){isProcess = false;System.debug(LoggingLevel.Debug, 'here is the exception==> Duplicate External Id On '+'ProjectId = ' + us.copado__Project__c + ' and External Id = ' + us.External_Id__c);}
                else{us.Id = listUS.get(0).Id;}
            }
            if(isProcess){this.userStories2Upsert.add(us);}
        }

        try {
            //performs upsert based on third party id
            if(!this.userStories2Upsert.isEmpty()){upsert this.userStories2Upsert;}
        }catch(DmlException ex){
            System.debug(LoggingLevel.Debug, 'here is the exception==> '+ex.getMessage());
        }
    }

     /**
    * @description finish method
     * @param bc
    */
    public void finish(Database.BatchableContext bc){
        System.debug(LoggingLevel.Debug, 'Finished');
    }
}