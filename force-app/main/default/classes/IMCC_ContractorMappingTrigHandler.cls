/**
* Created By    :   Girikon[Arushi IMCC-83]
* Created On    :   03/02/2021
* @description  :   Trigger on contractor Mapping object to update the task when it is completed.
* Modified By   :   Girikon(Arushi - [IMCC-91]),Girikon(Garima - [IMCC-4202])
* Modified On   :   25 Feb, 2022,19 Aug, 2022
* @description  :   This class will help Customers to submit the stand design for their booths, if they decide to complete stand submission process.
* Test Class    :   IMCC_ContractorMappingTrigHandler_Test(91%)
*/
public with sharing class IMCC_ContractorMappingTrigHandler {
    /**
    * @description update Contractor Status
    * @param  newConMapList
    */
    public static void updateContractorStatus(List<Contractor_Mapping__c> newConMapList){
        Set<Id> cmId = new Set<Id>();
        for(Contractor_Mapping__c cm : newConMapList){
            cmId.add(cm.Id);
        }
        List<Purchase_Data__c> listPd = [SELECT Id,Contractor_Mapping__c,Contact_Edition_Mapping__c FROM Purchase_Data__c WHERE Contractor_Mapping__c IN:cmId WITH SECURITY_ENFORCED];
        Map<Id,Purchase_Data__c> mapPD = new Map<Id,Purchase_Data__c>();
        for(Purchase_Data__c pd : listPd){
            mapPD.put(pd.Contractor_Mapping__c, pd);
        }

        for(Contractor_Mapping__c cm : newConMapList){
            if(cm.Contractor_CEM__c!=null && (mapPD.get(cm.Id)?.Contact_Edition_Mapping__c == cm.Contractor_CEM__c && cm.Contractor_Status__c == 'Contractor Nominated')){
                cm.Contractor_Status__c = 'Contractor Accepted Nomination';
            }
        }
    }
    
    /**
    * @description update Task Status
    * @param  newConMaps
    * @param  oldConMaps
    */
    public static void updateTaskStatus(Map<Id,Contractor_Mapping__c> newConMaps,Map<Id,Contractor_Mapping__c> oldConMaps){
        Set<Id> editionSet = new Set<Id>();
        set<Id> conIds = new set<Id>();
        set<Id> contractorMappingIds = new set<Id>();
        List<Task> taskList = new List<Task>();
        List<Task> taskToBeUpdated = new List<Task>();
        
        try{
            for(Contractor_Mapping__c cm : newConMaps.Values()){
                if(cm.Contractor_Status__c == 'Contractor Accepted Nomination'){
                    contractorMappingIds.add(cm.Id);
                }
            }
            
            List<Purchase_Data__c> pdList  = [SELECT Contact_Edition_Mapping__r.Contact__c,Contact_Edition_Mapping__r.Edition__c FROM Purchase_Data__c WHERE Contractor_Mapping__c IN:contractorMappingIds WITH SECURITY_ENFORCED];
            
            for(Purchase_Data__c pHData : pdList){
                editionSet.add(pHData.Contact_Edition_Mapping__r.Edition__c);
                conIds.add(pHData.Contact_Edition_Mapping__r.Contact__c);
            }
            
            if((!editionSet.isEmpty() && !conIds.isEmpty()) && Schema.sObjectType.Task.isAccessible()){
                taskList = [SELECT Id, WhoId, WhatId, Subject, ActivityDate, Status, Priority,IsHighPriority, OwnerId, ReminderDateTime FROM Task WHERE WhoId IN:conIds AND WhatId IN:editionSet AND Subject='Nominate the Contractor'];
            }
            
            for(Task t : taskList){
                t.status = 'Completed';
                taskToBeUpdated.add(t);
            }

            if(!taskToBeUpdated.isEmpty() && Schema.sObjectType.Task.isUpdateable()){
                update taskToBeUpdated;
            }
        }
        catch (Exception ex) {
            HandleAllCustomException.logException(ex,'Contractor_Mapping__c', 'After Update');
        }
    }
    
    /**
    * @description send Email And Portal Notifications
    * @param  contractorNewMap
    * @param  contractorOldMap
    * @param  isInsert
    */
    public static void sendEmailAndPortalNotifications(List<Contractor_Mapping__c> contractorNewMap,Map<Id,Contractor_Mapping__c> contractorOldMap,boolean isInsert){
        Profile prf = [SELECT Id,Name FROM Profile WHERE Id=:Userinfo.getProfileid() LIMIT 1];
        Set<Id> setIds = new Set<Id>();
        Map<Id,List<String>> mapCMIdEmailTemplate = new Map<Id,List<String>>();
        for(Contractor_Mapping__c cm : contractorNewMap){
            if(!mapCMIdEmailTemplate.containsKey(cm.Id)){
                mapCMIdEmailTemplate.put(cm.Id, new List<String>());
            }
            List<String> lstET =  mapCMIdEmailTemplate.get(cm.Id);
            Contractor_Mapping__c oldCM = isInsert?null:contractorOldMap.get(cm.Id);
            if(!isInsert && cm.Contractor_Status__c == 'Contractor Accepted Nomination' && cm.Contractor_Status__c!=oldCM.Contractor_Status__c){
                lstET.add('Email:Contractor accepted nomination CUS');
                lstET.add('Portal:Contractor accepted nomination CUS');
                setIds.add(cm.Id);
            }
            if(!isInsert && cm.Contractor_Status__c == 'Contractor Declined Nomination' && cm.Contractor_Status__c!=oldCM.Contractor_Status__c){
                lstET.add('Email:Contractor rejected nomination CUS');
                lstET.add('Portal:Contractor rejected nomination CUS');
                setIds.add(cm.Id);
            }
            if(!isInsert && cm.Contractor_Status__c == 'Contractor Nominated' && oldCM.Contractor_Status__c=='New Contractor Nomination In Review'){
                lstET.add('Email:Ops team accepted New contractor CUS');
                lstET.add('Portal:Ops team accepted New contractor CUS');
                lstET.add('Email:Ops team approve a new contractor CON');
                setIds.add(cm.Id);
            }
            if(!isInsert && cm.Contractor_Status__c == 'New Contractor Nomination Rejected' && cm.Contractor_Status__c!=oldCM.Contractor_Status__c){
                lstET.add('Email:Ops team rejected New contractor CUS');
                lstET.add('Portal:Ops team rejected New contractor CUS');
                setIds.add(cm.Id);
            }
            if(isInsert && cm.Contractor_Status__c == 'Contractor Nominated' && prf.Name != 'IM Customer Community Login User'){
                lstET.add('Email:Ops team nominate a contractor CUS');
                setIds.add(cm.Id);
            }
            if(!isInsert && cm.Contractor_Status__c == 'Permission to Build' && cm.Contractor_Status__c!=oldCM.Contractor_Status__c){
                lstET.add('Email:Stand Design Permission to Build CUS');
                lstET.add('Portal:Stand Design Permission to Build CUS');
                lstET.add('Email:Stand Design Permission to Build CON');
                lstET.add('Portal:Permission to Build Con');
                setIds.add(cm.Id);
            }
            if(cm.Contractor_Status__c == 'Contractor Nominated' && (isInsert || cm.Contractor_Status__c!=oldCM.Contractor_Status__c)){
                lstET.add('Email:Contractor nomination for an event CON');
                lstET.add('Portal:Contractor Nominated Con');
                setIds.add(cm.Id);
            }
            if(!isInsert && cm.Contractor_Status__c == 'In Review' && cm.Contractor_Status__c!=oldCM.Contractor_Status__c){
                lstET.add('Email:Stand Design In Review CON');
                lstET.add('Email:Stand Design Submission OPS');
                lstET.add('Portal:In Review Con');
                setIds.add(cm.Id);
            }
            if(!isInsert && cm.Contractor_Status__c == 'Pending Sales Approval' && cm.Contractor_Status__c!=oldCM.Contractor_Status__c){
                lstET.add('Email:Stand Design Pending Sales Approval CON');
                lstET.add('Portal:Pending Sales Approval Con');
                setIds.add(cm.Id);
            }
            if(!isInsert && cm.Contractor_Status__c == 'Stand Design Rejected/Incomplete' && cm.Contractor_Status__c!=oldCM.Contractor_Status__c){
                lstET.add('Email:Stand Design Rejected CON');
                lstET.add('Portal:Stand Design Rejected/Incomplete Con');
                setIds.add(cm.Id);
            }
            if(!isInsert && cm.Contractor_Status__c == 'Stand Design Resubmitted' && cm.Contractor_Status__c!=oldCM.Contractor_Status__c){
                lstET.add('Email:Stand Design Resubmission OPS');
                lstET.add('Email:Stand Design Resubmitted CON');
                lstET.add('Portal:Stand Design Resubmitted Con');
                setIds.add(cm.Id);
            }
            if(!isInsert && cm.Contractor_Status__c == 'Pending Venue Approval' && cm.Contractor_Status__c!=oldCM.Contractor_Status__c){
                lstET.add('Email:Stand Design Pending Venue Approval CON');
                lstET.add('Portal:Pending Venue Approval Con');
                setIds.add(cm.Id);
            }
            if(!isInsert && cm.Contractor_Status__c == 'Tentative Approval' && cm.Contractor_Status__c!=oldCM.Contractor_Status__c){
                lstET.add('Email:Stand Design Tentative Approval CON');
                lstET.add('Portal:Tentative Approval Con');
                setIds.add(cm.Id);
            }
            if(!isInsert && cm.Contractor_Status__c == 'Cancelled' && cm.Contractor_Status__c!=oldCM.Contractor_Status__c){
                lstET.add('Email:Stand Design Cancelled Status CON');
                lstET.add('Portal:Cancelled Con');
                setIds.add(cm.Id);
            }
            if(isInsert && cm.Contractor_Status__c == 'New Contractor Nomination In Review'){
                lstET.add('Email:New Contractor submission OPS');
                setIds.add(cm.Id);
            }
            mapCMIdEmailTemplate.put(cm.Id, lstET);
        }
            
        if(!setIds.isEmpty()){
            String strQuery = 'SELECT Id,Edition__c,Edition__r.Name,Edition__r.Edition_Code__c,Edition__r.Start_Date__c,Rejection_Reason__c,Contractor_Status__c,Contractor_CEM__c,Contractor_CEM__r.Contact__c,Contractor_CEM__r.Account__r.Id,Account__c,Account__r.Id,Edition__r.Event_Setting__c,Edition__r.Operations_Team__c,Is_Self_Managed__c FROM Contractor_Mapping__c WHERE Id In:setIds';
            List<SObject> listSobject = Database.query(strQuery);
            SendEmailOnFormStatusBatch batch = new SendEmailOnFormStatusBatch(listSobject,'Stand Contractor',mapCMIdEmailTemplate);
            Database.executeBatch(batch,1);
        }
    }
}