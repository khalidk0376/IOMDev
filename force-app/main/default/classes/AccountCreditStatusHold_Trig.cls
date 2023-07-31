/**
* File:         AccountCreditStatusHold_Trig
* Project:      Greenfield
* Created Date: 11/06/2019
* Created By:   Yash Gupta
* Test Class:   AccountCreditStatusHold_Trig_Test
* Coverage:     100%
* *******************************************************************************************************
* @description : Sharing Class to update the Opportunity and account Layout.
* *******************************************************************************************************
* History : 
*   Modified by Yash Gupta [11/27/2019], Increase the code coverage.
*   [IML2R-132] - Girikon(Ashish)- 13 Jan 2020, To update Invalid Address Status value on Account incase of Address change
*   [IML2R-243] - Girikon(Ashish)- 20 Jan 2020, To update Awaiting Update Status value on Account incase of Name change 
*   [IML2R-719] - Girikon(Yash Gupta)- 5 Feb 2020, To update credit note status to awating reprint once there is any change in account name. 
*   [IML2R-2018] - Girikon(Prashant)- 27 March 2020, Removed updation of Opportunity record type when Account Credit status is onHold.
*   [IOM-1516]  - Girikon(Ashish)- 15 June 2022, added Logic for RT update
*/
public with sharing class AccountCreditStatusHold_Trig implements TriggerInterface_Account.Runnable {
    
    /*
    * @description [Variable Declarations]
    */
   /* Map<String, Id> typeMap = New Map<String, Id>();
    set<Id> sAccountId = new set<Id>();
    set<Id> sAccountIds = new set<Id>();
    List<Opportunity> lstOpportunityUpdate = new List<Opportunity>();
    Map<id,Account> accIdAccountMap = new Map<id,Account>();
    List<blng__CreditNote__c> lstCreditNoteUpdate = new List<blng__CreditNote__c>();*/
    
    /*
    * @description [Call Interface Class to fetch the new list and old map of account]
    * @param TriggerInterface_Account [fetch the trigger new list and old map]
    */
    public void run(TriggerInterface_Account.Trig trig) {
        /** IOM-1615 Commented for Hold/UnHold Record type */
        /*
        if(trig.newList !=null && trig.oldMap !=null){            
            //accountstatusupdate(trig.newList,trig.oldMap);
        } 
        if(trig.isBefore && trig.isUpdate){
            //creditNoteStatusUpdate(trig.newList,trig.oldMap);
        }	
        if(trig.isBefore &&(trig.isUpdate || trig.isInsert))
        {
            setAccountRecordType(trig);
        }  */      
        system.debug('Debug');
    }
    
    /*
    * Modified By: Girikon(Ashish) (15th June 2022) [IOM-1615]
    * @description This method is used to set the Record Type On Account based On Legacy CRM    
    * @param TriggerInterface_Account [fetch the trigger new list and old map]
    */
   /* Private static void setAccountRecordType(TriggerInterface_Account.Trig trig)
    {
        Map<String,Record_Type_Settings__mdt> recordTypeCRMNameMap = new Map<String,Record_Type_Settings__mdt>();
        for(Record_Type_Settings__mdt rts:[SELECT Id,Legacy_CRM_Instance__c,Record_Type__c,Legacy_CRM_URL__c FROM Record_Type_Settings__mdt WHERE Active__c = true AND Object_Name__c = 'Account' ])
        {
            recordTypeCRMNameMap.put(rts.Legacy_CRM_Instance__c,rts);
        }

        for(Account acc:trig.newList)
        {
            Account oldAcc = trig.isUpdate ? trig.oldMap.get(acc.Id):new Account();
            if(String.isNotBlank(acc.Legacy_CRM_Instance__c) 
                && acc.Legacy_CRM_Instance__c != oldAcc.Legacy_CRM_Instance__c
                && recordTypeCRMNameMap.containsKey(acc.Legacy_CRM_Instance__c))
            {
                string recordTypeDName = recordTypeCRMNameMap.get(acc.Legacy_CRM_Instance__c).Record_Type__c;
                acc.Legacy_CRM_Org_URL__c = recordTypeCRMNameMap.get(acc.Legacy_CRM_Instance__c).Legacy_CRM_URL__c;
                if(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(recordTypeDName) != null)
                {
                    acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(recordTypeDName).getRecordTypeId();
                }                
            }
        }
    }*/
    	
    /********************** Pearpoint Code kept for Refrence(Not in Use under IOM)  *************************/
    		/*********** IOM-1615 Commented for Hold/UnHold Record type *********/
    
    /*
    * Modified By: Yash Gupta (10th Feb 2020)
    * @description This method is used to credit note status to awating reprint as per ticket no IML2R-719
    * @param lstAccount [list of account that are inserted in system]
    * @param oldMapAccount [Map of account id and account]
    */
    /*
    public void creditNoteStatusUpdate ( List <Account> lstAccount , Map<Id , Account> oldMapAccount){
        if(!lstAccount.isEmpty()){
            for(Account acct : lstAccount){
                if(oldMapAccount.get(acct.Id).Name != acct.Name){
                    sAccountIds.add(acct.Id);
                }
            }
            if(!sAccountIds.isEmpty()){
                List<blng__CreditNote__c> lstCreditNote = new List<blng__CreditNote__c>();
                if(Schema.sObjectType.blng__CreditNote__c.isAccessible()){
                    lstCreditNote = [select id,Credit_Note_Print_Status__c,blng__RelatedInvoice__c,blng__Account__c, blng__Status__c, Last_Printed_Version_No__c,AWS_Status__c from blng__CreditNote__c where blng__Account__c IN:sAccountIds AND blng__RelatedInvoice__c!=NULL];
                }
                if(!lstCreditNote.isEmpty()){
                    for(blng__CreditNote__c cn : lstCreditNote){
                        if(cn.blng__Status__c == 'Posted' && cn.Credit_Note_Print_Status__c == 'Printed' && (cn.AWS_Status__c == 'Sync Required' || cn.AWS_Status__c == 'Synced')){
              				cn.Credit_Note_Print_Status__c = 'Awaiting Reprint';
                          lstCreditNoteUpdate.add(cn);                            
                        } else if(cn.blng__Status__c == 'Posted' && cn.Credit_Note_Print_Status__c == 'Reprint Complete' && (cn.AWS_Status__c == 'Sync Required' || cn.AWS_Status__c == 'Synced')){
                            cn.Credit_Note_Print_Status__c = 'Awaiting Reprint';
                          lstCreditNoteUpdate.add(cn);  
                        }
                    }
                    if(!lstCreditNoteUpdate.isEmpty() && Schema.sObjectType.blng__CreditNote__c.isUpdateable()){
                        update lstCreditNoteUpdate;
                    }
                }
            }
        }
    }	*/
    
    /* 
    * @description [this method is used to Check if the Billing Address is Changed OR not]  [IML2R- 132]
    * @param Old Account Instance 
    * @param New Changed Account instance 
    */
    /*Private Boolean validateAddressChange(Account oldAccount,Account newAccount){
        Boolean isChange = false;
        if(oldAccount != null && newAccount != null && newAccount.Address_Status__c == 'Valid' ){
            if((oldAccount.BillingCountryCode != newAccount.BillingCountryCode) || (oldAccount.BillingStateCode != newAccount.BillingStateCode) || (oldAccount.BillingCity != newAccount.BillingCity) || (oldAccount.BillingPostalCode != newAccount.BillingPostalCode) || (oldAccount.BillingStreet != newAccount.BillingStreet)){
                isChange = true;
            }
        }
        return isChange;
    }*/
    
    /* 
    * @description [this method is used to Check if the Account name is Changed OR not]  [IML2R- 243]
    * @param Old Account Instance 
    * @param New Changed Account instance 
    */
    /*Private Boolean validateNameChange(Account oldAccount,Account newAccount){
        Boolean isChange = false;
        if(oldAccount != null && newAccount != null && newAccount.ERP_Sync__c != 'Awaiting Update' ){
            if(oldAccount.name != newAccount.name){
                isChange = true;
            }
        }
        return isChange;
    }*/

    /** IOM-1615 Commented for Hold/UnHold Record type */
    /*
    * @description [this method is used to update account and opportunity  record type ]
    * @param lstAccount [list of account that are inserted in system]
    * @param oldMapAccount [Map of account id and account ]
    */
    /*
    public void accountstatusupdate ( List <Account> lstAccount , Map<Id , Account> oldMapAccount){
        for(RecordType rt: [Select DeveloperName, Id From RecordType Where sObjectType IN  ('Opportunity','Account')]){
            typeMap.put(rt.DeveloperName, rt.Id);
        }
        
        if(lstAccount.size() > 0){
            for (Account oAcc : lstAccount ){
                sAccountId.add(oAcc.id);
                oAcc.RecordTypeId = (oAcc.Accounting_Credit_Hold__c == 'Hold')? typeMap.get('AccountOnHold'):typeMap.get('AccountUnHold');                
                if(oldMapAccount.containsKey(oAcc.Id)){ //Check for update 
                    //Set Address Status invalid incase of any change in it  // [IML2R -132]
                    oAcc.Address_Status__c = validateAddressChange(oldMapAccount.get(oAcc.Id),oAcc) ? 'Invalid' : oAcc.Address_Status__c ;
                    //Set Awaiting Update for ERP in case of Name Change  // [IML2R -243]
                    oAcc.ERP_Sync__c = validateNameChange(oldMapAccount.get(oAcc.Id),oAcc) ? 'Awaiting Update' : oAcc.ERP_Sync__c ;
                }
                // putting value in accIdAccountMap
                accIdAccountMap.put(oAcc.id,oAcc);
            }
        }
        
        // if (!sAccountId.isEmpty()){
        //     for ( opportunity opp : [SELECT Id, AccountId, Account.Name,Account.Accounting_Credit_Hold__c FROM opportunity Where AccountId IN : sAccountId]){
        //         if (accIdAccountMap.get(opp.AccountId).Accounting_Credit_Hold__c == 'Hold') {  
        //             opp.RecordTypeId = typeMap.get('Opportunity_Account_Hold');
        //             lstOpportunityUpdate.add(opp);     
        //         } 
        //     }
        //     if (!lstOpportunityUpdate.isEmpty() && Schema.sObjectType.Opportunity.isUpdateable()){ 
        //         Update lstOpportunityUpdate;
        //     }
        // }
    }*/
}