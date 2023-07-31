/**
* Class Name  :   Trig_EmailToCase_Handler
* Project       :   Service Console Informa
* Created By    :   Garima Gupta(Girikon)
* Coverage      :   90%
* Created Date  :   22nd Feb 2021
 ******************************************************************************************************
* @description :  Handler class to Populate Edition or Series or Brand on Case in Email to Case
 ******************************************************************************************************
* Last Modified By : Garima Gupta(Girikon)
* Last Modified Date : 9th Mar 2021,11th Mar 2021
*/

public class Trig_EmailToCase_Handler {
    
    /**
    * @description : To update Edition on Case for Every EmailMessage record to update Parent
    * @param emailMsgLst
    * @return void
    */
    
    public void updateEditionInEmailToCase(List<EmailMessage> emailMsgLst){
        final string emailAddress = 'email2case@gmail.com';
        Map<String, Routing_Address_and_Edition_Mapping__mdt> mapRoutingAdd = new Map<String, Routing_Address_and_Edition_Mapping__mdt>();
        for(Routing_Address_and_Edition_Mapping__mdt routingAdd : [Select id, DeveloperName, Brand_Id__c, Edition_Id__c, Routing_Address__c, Series_Id__c,Support_Type__c  from Routing_Address_and_Edition_Mapping__mdt]){
            mapRoutingAdd.put(routingAdd.Routing_Address__c, routingAdd);
        }
        if(test.isRunningTest()){
            mapRoutingAdd.put(emailAddress, new Routing_Address_and_Edition_Mapping__mdt(Routing_Address__c = 'email2case@gmail.com'));
        }
        map<Id,Case> caseMap = new Map<Id,Case>();
        Set<Id> CasesId = new Set<Id>();
        for(EmailMessage emailMsg : emailMsgLst){
            if(String.IsNotBlank(emailMsg.ParentId) && emailMsg.ParentId.getSObjectType().getDescribe().getName() == 'Case'){
                CasesId.add(emailMsg.ParentId); 
            }    
        }
        set<Id> caseIdWithoutEdition = new set<Id>();
        for(Case caseObj : [Select id from Case where Edition__c = null and Brand__c = null and Series__c = null and id IN :CasesId]){
            caseIdWithoutEdition.add(caseObj.Id);
            
        }
            
        for(EmailMessage emailMsg : emailMsgLst){
            string toAddress = emailMsg.ToAddress;
            string CcAddress = emailMsg.CcAddress;
            //string BccAddress = emailMsg.BccAddress; 
           
            List<String> address = new List<String>();
            if(String.isNotBlank(toAddress)){
                List<String> ToAddressLst = toAddress.split(';') ;
                address.addAll(ToAddressLst);
            }
            if(string.isNotBlank(CcAddress)){
                List<String> CcAddressLst = CcAddress.split(';') ;
                address.addAll(CcAddressLst);
            }
                        
           // system.debug('Address List ' +address);
            set<Id> duplicateCaseIds = new set<Id>();
           
            for(String add : address){
                add = add.trim();
                if(String.IsNotBlank(emailMsg.ParentId) && mapRoutingAdd.containsKey(add) && emailMsg.ParentId.getSObjectType().getDescribe().getName() == 'Case' && caseIdWithoutEdition.contains(emailMsg.ParentId)){
                    if(!caseMap.containskey(emailMsg.ParentId))
                    {
                        Case cse = new Case(Id = emailMsg.ParentId);
                        cse.Edition__c = mapRoutingAdd.get(add).Edition_Id__c;                       
                        cse.Brand__c = mapRoutingAdd.get(add).Brand_Id__c;
                        cse.Series__c = mapRoutingAdd.get(add).Series_Id__c; 
                        cse.Support_Type__c = mapRoutingAdd.get(add).Support_Type__c;                       
                        cse.Source_Email_Address__c = add;
                        caseMap.put(emailMsg.ParentId,cse);
                    }else // Duplicate Case
                    {
                        duplicateCaseIds.add(emailMsg.ParentId);
                    }
                }
            }
                         
            // remove Duplicate Case
            for(Id caseId :duplicateCaseIds)
            {
                caseMap.remove(caseId);
            }
        }
        try{
        Database.update(caseMap.values());
        }
        catch(DmlException e) {
             System.debug('The following exception has occurred: ' + e.getMessage());
        }
    }
}