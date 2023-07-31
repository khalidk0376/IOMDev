/**
 * @description Schedulable class to retrieve external User Stories on a scheduled basis.
 *
 * @author Deepak Shukla
 * @version 1.0
 */
public without sharing class IM_ScheduleUserStoryFetch implements Schedulable
{
    List<copado__Project__c> listProjects;
    public List<Syncing_Copado_Project__mdt> listSCP;

    /**
    * @description Schedulable class constructor to retrieve external User Stories on a scheduled basis.
    */
    public IM_ScheduleUserStoryFetch(){
        listSCP = Syncing_Copado_Project__mdt.getAll().values();
        if(Test.isRunningTest()){
            listSCP = new List<Syncing_Copado_Project__mdt>();
            List<copado__Project__c> listProj = [SELECT Id FROM copado__Project__c];
            for(copado__Project__c proj : listProj){
                listSCP.add(new Syncing_Copado_Project__mdt(Project_Id__c=proj.Id));
            }
        }
        Set<Id> setIds = new Set<Id>();
        for(Syncing_Copado_Project__mdt scp : listSCP){
            setIds.add(scp.Project_Id__c);
        }

        listProjects = new List<copado__Project__c>();

        listProjects = [SELECT Id,Name, Copado_Integration_Setting__r.External_System__c, Copado_Integration_Setting__r.Named_Credential__c,JQL_Extended_Filter__c,Enable_Logs__c,Project_External_Id__c, Workspace_Id__c FROM copado__Project__c WHERE Id IN:setIds AND copado__Status__c!='Completed' AND Copado_Integration_Setting__r.External_System__c='JIRA'];
    }

    /**
    * @description execute Schedulable class to retrieve external User Stories on a scheduled basis.
    * @param sc
    */
    public void execute(SchedulableContext sc)
    {
        Integer batchSize = (Test.isRunningTest()?(10):(1));
        Database.executeBatch(new IM_FetchUserStoryBatch(this.listProjects),batchSize);
    }
}