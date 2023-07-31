/**
* File			: 	EditionReQueueAPIItems_Trig_Test
* Project      	:   Order & Billing Plateform
* Created By	: 	Deepak(Girikon)
* Created Date	: 	5th October 2021
* ******************************************************************************************************
* @description : Test Class to provide code covrage to classes - EditionReQueueAPIItems_Trig(96%)
* Last Modified By :
*/

@isTest
private with sharing class EditionReQueueAPIItems_Trig_Test {
    // @description : Setting up all test data
    @testsetup
    static void testData(){
        
        Trigger__c trig = new Trigger__c(Name = 'EditionReQueueAPIItems_Trig' , Trigger_Name_Unique__c='EditionReQueueAPIItems_Trig',Enabled__c=true,Object__c='Edition__c',Run_for_Recordypes__c='All',Recursive_Execution_Allowed__c=true,Execution_Order__c=1,After_Update__c=true);
        Insert trig;

        // create list of edition to be used on the quote
        List<Edition__c> listOfEditions = new List<Edition__c>();
        Edition__c edition = new Edition__c();
        for(Integer i=0;i<500;i++)
        {
            edition =  new Edition__c();
            edition.Name = 'testEdition'+i;
            edition.External_Tax_System__c = GlobalConstants.ONESOURCE;
            edition.External_Relationship__c = true; 
            edition.Edition_Code__c = 'testEdition'+i;
            listOfEditions.add(edition);
        }
        insert listOfEditions;

        Map<Id,API_Synchronization_Transaction__c> mapEdtIdApiTrans = new Map<Id,API_Synchronization_Transaction__c>();
        Map<Id,List<API_Synchronization_Item__c>> mapEdtIdistApiItem = new Map<Id,List<API_Synchronization_Item__c>>();
        for(Edition__c edt : listOfEditions){
            API_Synchronization_Transaction__c apiSyncroTrs = new API_Synchronization_Transaction__c();
            apiSyncroTrs.External_Tax_System__c = GlobalConstants.ONESOURCE;
            apiSyncroTrs.Request_Type__c = GlobalConstants.ASYNCHRONOUS;
            apiSyncroTrs.Started_From__c = 'Order';
            apiSyncroTrs.Status__c = GlobalConstants.PAUSED;
            mapEdtIdApiTrans.put(edt.Id,apiSyncroTrs);

            for(Integer i=0;i<5;i++){
                API_Synchronization_Item__c item = new API_Synchronization_Item__c();
                item.API_Call_Type__c = GlobalConstants.POST;
                item.Status__c = GlobalConstants.PAUSED;
                item.External_Tax_System__c = GlobalConstants.ONESOURCE;
                item.Edition__c = edt.Id;
                List<API_Synchronization_Item__c> listAPIItems = (mapEdtIdistApiItem.containsKey(edt.Id)?mapEdtIdistApiItem.get(edt.Id):new List<API_Synchronization_Item__c>());
                listAPIItems.add(item);
                mapEdtIdistApiItem.put(edt.Id,listAPIItems);
            }
        }

        insert mapEdtIdApiTrans.values();

        List<API_Synchronization_Item__c> listApiItemInsert = new List<API_Synchronization_Item__c>();
        for(Id edtId : mapEdtIdApiTrans.keySet()){
            API_Synchronization_Transaction__c apiSyncroTrs = mapEdtIdApiTrans.get(edtId);
            for(API_Synchronization_Item__c item : mapEdtIdistApiItem.get(edtId)){
                item.API_Synchronization_Transaction__c = apiSyncroTrs.Id;
                listApiItemInsert.add(item);
            }
        }
        insert listApiItemInsert;
    }
    
    // @description : test class is used to create order.
    
    @isTest 
    static void testgetAllEditionsForApiSynchItems()
    {
        Test.startTest();
        List<Edition__c> listEditions = [SELECT Id FROM Edition__c];
        for(Edition__c edt : listEditions){
            edt.External_Status__c = GlobalConstants.ACTIVE;
        }
        update listEditions;
        List<API_Synchronization_Item__c> itemsPaused = [SELECT Id FROM API_Synchronization_Item__c WHERE Status__c=:GlobalConstants.PAUSED];
        List<API_Synchronization_Transaction__c> apiTransPaused = [SELECT Id FROM API_Synchronization_Transaction__c WHERE Status__c=:GlobalConstants.PAUSED];
        List<API_Synchronization_Item__c> itemsQueued = [SELECT Id FROM API_Synchronization_Item__c WHERE Status__c=:GlobalConstants.QUEUED];
        List<API_Synchronization_Transaction__c> apiTransQueued = [SELECT Id FROM API_Synchronization_Transaction__c WHERE Status__c=:GlobalConstants.QUEUED];
        System.assertEquals(0, itemsPaused.size(),'All Items Not Queued.');
        System.assertEquals(0, apiTransPaused.size(),'All API Transactions Not Queued.');
        System.assertEquals(2500, itemsQueued.size(),'All Items Not Queued.');
        System.assertEquals(500, apiTransQueued.size(),'All API Transactions Not Queued.');
        Test.stopTest();
    }
}