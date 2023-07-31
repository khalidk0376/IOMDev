/**
* Trigger Name  :   trig_CaptureEvent
* Project       :   Service Console Informa
* Created By    :   Garima Gupta(Girikon)
* Coverage      :   100%
* Created Date  :   3rd Feb 2021
 ******************************************************************************************************
* @description : Populate Edition on Case before insert and Before Update
 ******************************************************************************************************
* Last Modified By :
*/

trigger trig_CaptureEvent on Case (before insert,before update) {
    if(trigger.isInsert){
    for(Case objCase1 : trigger.new){
      if(String.IsNotBlank(objCase1.Edition_Code__c) ){
       
            objCase1.Edition__c = objCase1.Edition_Code__c;
    }
      if(String.IsNotBlank(objCase1.Case_Description__c)){
           objCase1.Description = objCase1.Case_Description__c;
           }
    }
    }
    if(trigger.isUpdate){
      for(Case objCase2 : trigger.new){
      if(String.IsNotBlank(objCase2.Edition_Code__c) && objCase2.Edition_Code__c != trigger.oldMap.get(objCase2.Id).Edition_Code__c){
          System.debug('Updated');
          objCase2.Edition__c = objCase2.Edition_Code__c;
    }
    } 
    }
}