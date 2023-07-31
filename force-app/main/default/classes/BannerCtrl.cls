/**
*RA, 06/02/2020
*@description controller class for Banner lightning Component
*/
public  with sharing class BannerCtrl {

    /**
   *@description method to retrieve Account record
   *@param recId record Id
   *@return Account  
   */
    @AuraEnabled
    public static Account getAccRecord(String recId){
        String accRecId;
        Account acc;
        Id sId = (Id)recId;
        String sobjectType = sId.getSObjectType().getDescribe().getName();
        
        if(sobjectType == 'Account'){
            accRecId = recId;
        }
        if(sobjectType == 'Contact' && Schema.sObjectType.Contact.isAccessible()){
            Contact cnt = [Select Id, Name, AccountId from Contact Where Id =:recId ];
            accRecId = cnt.AccountId;
        }
        if(sobjectType == 'Opportunity' && Schema.sObjectType.Opportunity.isAccessible()){
            Opportunity opp = [Select Id, Name, Bill_To_Account__c from Opportunity Where Id =:recId ];
          accRecId = opp.Bill_To_Account__c;
        }
        if(accRecId != null && Schema.sObjectType.Account.isAccessible()){
             acc =  [Select Id, Name, Address_Status__c, Accounting_Credit_Hold__c from Account Where Id =:accRecId ];
        }
        return acc;
    }
}