/**
 * @description Upserts an External User Story into Copado's User Story.
 *
 * @author Deepak Shukla
 * @version 1.0
 */

public class IM_FetchUserStoryBatch implements Database.Batchable<SObject>,Database.AllowsCallouts, Database.Stateful{

    List<copado__Project__c> listProjects;
    List<Map<String,String>> listJiraStories;
    Map<String,Map<String,String>> mapProjectFieldMap;

    /** 
     * @description constructor to have the projects via schedule class 
     * @param listProjectsParam
    */
    public IM_FetchUserStoryBatch(List<copado__Project__c> listProjectsParam){
        this.listProjects = new List<copado__Project__c>();
        this.listJiraStories = new List<Map<String,String>>();
        this.mapProjectFieldMap = new Map<String,Map<String,String>>();
        this.listProjects = listProjectsParam;
    }

    /** 
     * @description retutn projects
    * @param bc
    * @return Iterable<SObject>
    */
    public Iterable<SObject> start(Database.BatchableContext bc){
        return this.listProjects;
    }

    /** 
    * @description Finds related instance based on external system to use via factory pattern, fetches and parses the JSON
    * @param bc
    * @param scope
    */
    public void execute(Database.BatchableContext bc, List<SObject> scope){
        try{
            for(SObject sobj : scope){
                copado__Project__c gProject = (copado__Project__c)sobj;
                List<Map<String,String>> listJiraStoriesTemp = IntegrationFactory.returnInstance(gProject.Copado_Integration_Setting__r.External_System__c).fetchRecords(gProject);
                this.listJiraStories.addAll(listJiraStoriesTemp);

                Map<String,String> fieldMap = CopadoCCMutilities.returnFieldMap(gProject.Id,' and Exclude_from_su__c = false');
                this.mapProjectFieldMap.put(gProject.Id, fieldMap);
            }
        }
        catch(Exception ex){System.debug(LoggingLevel.DEBUG, 'here is the exception==> ' + ex.getMessage() + ' ' + ex.getStackTraceString());}
    }

    /** 
    * @description to call upsert user stories batch
    * @param bc
    */
    public void finish(Database.BatchableContext bc){
        System.debug(LoggingLevel.DEBUG, 'this.listJiraStories=='+this.listJiraStories.size());
        System.debug(LoggingLevel.DEBUG, 'this.listJiraStories=='+JSON.serialize(this.listJiraStories));
        IM_ExecuteUserStoryUpsert obj = new IM_ExecuteUserStoryUpsert(this.listJiraStories, this.mapProjectFieldMap);
        Database.executeBatch(obj,200);
    }
}