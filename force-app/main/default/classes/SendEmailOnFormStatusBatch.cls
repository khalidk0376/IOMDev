/**
* Created/Modified By    : Girikon(Garima)
* Created On             : 31-03-2022
* @description           : This batch class is for sending emails in bulk
* Test Class             : SendEmailOnFormStatusBatch_Test(93%),imcc_Trig_UpdateStatusOnFormData_Test(93%),IMCC_ContractorMappingTrigHandler_Test(93%)
* Code Coverage          : 100%
* Modified by 
**/
public class SendEmailOnFormStatusBatch implements Database.Batchable<sobject>{

    public List<SObject> listSobject = new List<SObject>();
    public String moduleName = '';
    public Map<Id,List<String>> mapRecIdEmailTypes = new Map<Id,List<String>>();
    
    /**
    * @description  SendEmailOnFormStatusBatch Constructor
    * @param  listSobject
    * @param  module
    * @param  mapRecIdEmailTypes
    */
    public SendEmailOnFormStatusBatch(List<SObject> listSobject, String module, Map<Id,List<String>> mapRecIdEmailTypes){
        this.listSobject = listSobject;
        this.moduleName = module;
        this.mapRecIdEmailTypes = mapRecIdEmailTypes;
    }
    
    /**
    * @description  SendEmailOnFormStatusBatch Start Method
    * @param  bc
    * @return List<SObject>
    */
    public List<SObject> start(Database.BatchableContext bc){
        return this.listSobject;
    }

    /**
    * @description  SendEmailOnFormStatusBatch execute Method
    * @param bc
    * @param scope
    */
    public void execute(Database.BatchableContext bc, List<SObject> scope){
        for(SObject sobj : scope){
            if(moduleName == 'Form'){
                Trig_UpdateStatusOnFormData_Handler.processFormResponseEmails((Form_Response_Entry__c)sobj, mapRecIdEmailTypes.get(sobj.Id));
            }
            if(moduleName == 'Stand Contractor'){
                IMCC_ContractorMapNotification.processStandDesignEmails((Contractor_Mapping__c)sobj, mapRecIdEmailTypes.get(sobj.Id));
            }
        }
    }

    /**
    * @description  SendEmailOnFormStatusBatch finish Method
    * @param bc
    */
    public void finish(Database.BatchableContext bc){
        System.debug(LoggingLevel.DEBUG, bc);
    }
}