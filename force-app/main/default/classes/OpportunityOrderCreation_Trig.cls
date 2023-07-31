/**
* File:         OpportunityOrderCreation_Trig [IML2R-129]
* Created Date: 26 Dec 2019
* Created By:   Girikon(Ashish)
* Test Class:   OpportunityOrderCreation_Trig_Test (94%)
* @description : Sharing Class to update the Record Type on opportunity.
* *******************************************************************************************************
* Modification History :
*  1. [IML2R-208] - Girikon(Ashish)-  4 mar 2020, Add Amendment Functions
*  2. [IOM-530]  - Girikon(Suresh)- 22 Jan 2021, Updated Ordered Functionality on Quote
*  3. [IOM-480]  - Girikon(Ashish)- 07 Feb 2021, Incase of Custom Billing,SSC Approval is required
*  3. [GECI-1622]  - Girikon(Ashish)- 22 May 2023, Restrict Ocder Creation in case of amber countries
*/

public with sharing class OpportunityOrderCreation_Trig implements TriggerInterface_Opportunity.Runnable {

    private static final String CLOSED_WON = 'Closed Won';
    private static final String PENDING_ACCOUNTING_APPROVAL = 'Pending Accounting Approval';
    private static final String AWAITING_PAYMENT = 'Awaiting Payment';
    private static final String APPROVAL_REQUIRED = 'Approval Required';
    private static final String APPROVED = 'Approved';
    
    /**
* 	@description [Call Interface Class to fetch the new list and old map of opportunity]
* 	@param trig TriggerInterface_Opportunity [fetch the trigger new list and old map]
*/
    public void run(TriggerInterface_Opportunity.Trig trig) 
    {
        // Set<Id> setPrimaryQuoteids = new set<Id>();
        if(Trig.isBefore && Trig.isUpdate){
            processClosedWonOppsBefore(trig.newList,trig.oldMap);
        }
        if (Trig.isAfter && Trig.isupdate)             
        {
            processClosedWonOpps(trig.newList,trig.oldMap);
            cancelOrders(trig.newList,trig.oldMap);
            createAccountContactRelation(trig.newList,trig.oldMap);
        }
    }
    
    private static void processClosedWonOppsBefore(list<Opportunity> newOpplist,map<Id,Opportunity> oldOppMap){
        set<Id> edIds = new Set<Id>();
        set<Id> accIds = new Set<Id>();      
        for(Opportunity opp : newOpplist){
            if(opp.StageName == CLOSED_WON && opp.Status__c == PENDING_ACCOUNTING_APPROVAL && String.isNotBlank(opp.Default_Edition__c))
            {
                edIds.add(opp.Default_Edition__c);
                accIds.add(opp.AccountId);
            }
        }
        Map<Id,Edition__c> mapOfed = new Map<Id,Edition__c>([SELECT Id,Opportunity_Status_When_Ordering__c,Require_SSC_Approval__c,Edition_Code__c FROM Edition__c WHERE Id in:edIds WITH SECURITY_ENFORCED]);
        Map<Id,Account> mapAccs = new Map<Id,Account>([SELECT Id,BillingCountryCode FROM Account WHERE Id in:accIds WITH SECURITY_ENFORCED]);
        
        List<String> amberCountries = GlobalConstants.getValue('Amber_Countries').split(','); //[GECI-1622]
        // MAP of Edtion Code & Legacy CRM With Edition Settings
        Map<String,Edition_Setting__mdt> mapEditionSt = InvoiceTaxApiSynchronization_Trig.getEditionSettingsMapOnEditionCodeLegacyCRM();

        for(Opportunity opp : newOpplist)
        {
            String key = mapOfed.containsKey(opp.Default_Edition__c)  ? mapOfed.get(opp.Default_Edition__c).Edition_Code__c+'_'+opp.Legacy_CRM_Instance__c :'';

            if(opp.StageName == CLOSED_WON 
                && opp.Status__c == PENDING_ACCOUNTING_APPROVAL
                && opp.Is_Custom_Billing_Required__c == false   //[IOM-480]
                && String.isNotBlank(opp.Default_Edition__c) 
                && mapOfed.containsKey(opp.Default_Edition__c) 
                && mapOfed.get(opp.Default_Edition__c).Require_SSC_Approval__c == false
                && ( checkForAmberCountry(mapEditionSt,key) == false //[GECI-1622]
                    || !amberCountries.contains(mapAccs.get(opp.AccountId).BillingCountryCode) //[GECI-1622]
                    )
                )
            {
                opp.Status__c = AWAITING_PAYMENT;
            }
        }
    }

    private static boolean checkForAmberCountry( Map<String,Edition_Setting__mdt> mapEditionSt,string key)
    {
        return mapEditionSt.containsKey(key)?mapEditionSt.get(key).Amber_Countries_Needs_SalesOps_Approval__c:false;
    }
    
    private static void processClosedWonOpps(list<Opportunity> newOpplist,map<Id,Opportunity> oldOppMap)
    {        
        Set<Id> setToOrderQuoteids = new set<Id>();        
        map<Id,Opportunity> mapAmendmentOppids = new map<Id,Opportunity>();
        for(Opportunity opp : newOpplist)
        {
            if(opp.StageName == CLOSED_WON  && String.isNotBlank(opp.SBQQ__PrimaryQuote__c))
            {
                if(String.isNotBlank(opp.SBQQ__AmendedContract__c ) && oldOppMap.get(opp.Id).StageName != CLOSED_WON) // Amendment Case [IML2R-208]
                {
                    mapAmendmentOppids.put(opp.Id,opp);
                }
                if(String.isBlank(opp.SBQQ__AmendedContract__c ) && oldOppMap.get(opp.Id).Status__c != opp.Status__c)
                {
                    setToOrderQuoteids.add(opp.SBQQ__PrimaryQuote__c);
                }
            }
            if(opp.StageName == CLOSED_WON && String.isNotBlank(opp.SBQQ__AmendedContract__c ) && opp.Status__c == AWAITING_PAYMENT && oldOppMap.get(opp.Id).Status__c != AWAITING_PAYMENT)
            {
                mapAmendmentOppids.put(opp.Id,opp);
            }
        }  
        if(!setToOrderQuoteids.isEmpty())
        {
            createOrderonQuotes(setToOrderQuoteids);
        }
        if(!mapAmendmentOppids.isEmpty())
        {
            updateChangeRequestStatus(mapAmendmentOppids);
        }
    }
    
    /**
    * 	@description [Order status in IM should be Cancelled or Draft for Closed Lost Opps] - [GECI-1416]
    * 	@param newOpplist New Opp List
    * 	@param oldOppMap Old Opp Map
    */
    private static void cancelOrders(list<Opportunity> newOpplist,map<Id,Opportunity> oldOppMap)
    {
        set<Id> lostOppIds = new set<Id>();
        for(Opportunity opp : newOpplist)
        {
            if(opp.StageName == 'Cancelled'  && oldOppMap.get(opp.Id).StageName != opp.StageName)
            {
                lostOppIds.add(opp.Id);
            }
        }
        // Get all Orders to Cancel
        List<Order> listOrdersPreUpdate = new List<Order>();
        List<Order> listOrdersUpdate = new List<Order>();
        for(Order odr:[SELECT Id,SBQQ__Contracted__c,blng__InvoiceBatch__c FROM Order WHERE OpportunityId =: lostOppIds AND Status != 'Cancelled' WITH SECURITY_ENFORCED]){
            if(odr.SBQQ__Contracted__c = true){
                odr.SBQQ__Contracted__c = false;             
                listOrdersPreUpdate.add(odr);
            }            
            listOrdersUpdate.add(new Order(Id=odr.Id,Status='Cancelled',blng__InvoiceBatch__c = null));
        }

        if(Schema.sObjectType.Order.isUpdateable() && !listOrdersPreUpdate.isEmpty()){
            update listOrdersPreUpdate; // Set the Contracted as false
        }

        if(Schema.sObjectType.Order.isUpdateable() && !listOrdersUpdate.isEmpty()){
            update listOrdersUpdate;    // Update Status
        }
    }

    /**
* 	@description [update Change Request Status]
* 	@param mapAmendmentOppids of Opp Ids
*/
    Public Static void updateChangeRequestStatus(map<Id,Opportunity> mapAmendmentOppids)
    {
        list<Change_Request__c> toUpdateChangeRequestList = new List<Change_Request__c>();
        for(Change_Request__c cr : [SELECT Id,Amended_Opportunity__c,Change_Request_Status__c FROM Change_Request__c WHERE Amended_Opportunity__c in:mapAmendmentOppids.keySet() WITH SECURITY_ENFORCED])
        {
            cr.Change_Request_Status__c =  mapAmendmentOppids.get(cr.Amended_Opportunity__c).Status__c !=AWAITING_PAYMENT ? APPROVAL_REQUIRED : APPROVED;
            toUpdateChangeRequestList.add(cr);
        }
        /*
        if(!toUpdateChangeRequestList.isEmpty())
        {
            Database.SaveResult[] srList = Database.update(toUpdateChangeRequestList, false);
            //System.debug(LoggingLevel.DEBUG,' toUpdateChangeRequestList SaveResult : '+ JSON.serialize(srList));
        }*/
    }
    
    /**
* 	@description [Call Interface Class to fetch the new list and old map of opportunity]
* 	@param setPrimaryQuoteids [Quote Ids]
*/
    @future
    public Static void createOrderonQuotes(Set<Id> setPrimaryQuoteids)
    {
        list<SBQQ__Quote__c> listQuotes = new list<SBQQ__Quote__c>();
        for(SBQQ__Quote__c quotes :[SELECT id,CreatedDate,SBQQ__Opportunity2__r.StageName,SBQQ__Opportunity2__r.Status__c,Edition__r.Opportunity_Status_When_Ordering__c FROM SBQQ__Quote__c WHERE id in:setPrimaryQuoteids AND SBQQ__Status__c = 'Approved' AND SBQQ__Ordered__c = false AND Edition__r.Order_Creation__c = true AND Edition__r.No_Order_Creation__c = false WITH SECURITY_ENFORCED])
        {
            if(quotes.SBQQ__Opportunity2__r.StageName == CLOSED_WON && (quotes.SBQQ__Opportunity2__r.Status__c == quotes.Edition__r.Opportunity_Status_When_Ordering__c || String.isBlank(quotes.Edition__r.Opportunity_Status_When_Ordering__c)))
            {
                if(quotes.CreatedDate.addMinutes(3) < DateTime.now())	
                {	
                    quotes.SBQQ__Ordered__c = true;	
                	listQuotes.add(quotes);	
                }  
            }
        }
        // System.debug( ' listQuotes : ' +listQuotes);
        if(!listQuotes.isEmpty())
        {            
            Database.SaveResult[] srList = Database.update(listQuotes, false);
            System.debug(LoggingLevel.DEBUG,' listQuotes SaveResult : '+ JSON.serialize(srList));
			}
			}

    /**
    * 	@description [To Create Account Contact Relation if it is not found] - [GECI-1793]
    * 	@param newOpportunityList New Opp List
    * 	@param oldOpportunityMap Old Opp Map
    */
    private static void createAccountContactRelation(List<Opportunity> newOpportunityList, Map<Id, Opportunity> oldOpportunityMap) {
        Set<Id> accountIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        Set<String> legacyCRMs = new Set<String>();
        Set<String> setKeys = new Set<String>();
        
        for(Opportunity opp : newOpportunityList) {
            Opportunity oldOpp = oldOpportunityMap.get(opp.Id);
            if(opp.StageName == 'Closed Won' && opp.Bill_To_Account__c != null && opp.Billing_Contact__c != null && (opp.Bill_To_Account__c != oldOpp.Bill_To_Account__c || opp.Billing_Contact__c != oldOpp.Billing_Contact__c)) {
                accountIds.add(opp.Bill_To_Account__c);
                contactIds.add(opp.Billing_Contact__c);
                legacyCRMs.add(opp.Legacy_CRM_Instance__c);
                String key = opp.Bill_To_Account__c + '_' + opp.Billing_Contact__c + '_' + opp.Legacy_CRM_Instance__c;
                setKeys.add(key);
            }
        }

        List<AccountContactRelation> listACR = [SELECT Id,AccountId,ContactId,SourceOrg__c,Source_Contact_ID__c FROM AccountContactRelation WHERE AccountId IN:accountIds AND ContactId IN:contactIds AND SourceOrg__c IN:legacyCRMs WITH SECURITY_ENFORCED];

        Map<String,AccountContactRelation> mapACR = new Map<String,AccountContactRelation>();
        for(AccountContactRelation acr : listACR){
            String key = acr.AccountId + '_' + acr.ContactId + '_' + acr.SourceOrg__c;
            mapACR.put(key,acr);
        }

        List<AccountContactRelation> listACR2 = [SELECT Id,AccountId,ContactId,SourceOrg__c,Source_Contact_ID__c FROM AccountContactRelation WHERE ContactId IN:contactIds AND SourceOrg__c IN:legacyCRMs AND Source_Contact_ID__c!=null WITH SECURITY_ENFORCED];

        Map<String,AccountContactRelation> maponContactidandLegacyCRLToACR = new Map<String,AccountContactRelation>();
        for(AccountContactRelation acr : listACR2){
            String key = acr.ContactId + '_' + acr.SourceOrg__c;
            maponContactidandLegacyCRLToACR.put(key,acr);
        }
        
        List<AccountContactRelation> acrListInsert = new List<AccountContactRelation>();
        for(String key : setKeys){
            if(!mapACR.containsKey(key)){
                List<String> listString = key.split('_');
                AccountContactRelation acr = new AccountContactRelation();
                acr.AccountId = listString.get(0);
                acr.ContactId = listString.get(1);
                acr.SourceOrg__c = listString.get(2);
                acr.IsActive = true;
                String key2 = listString.get(1) + '_' + listString.get(2);
                if(maponContactidandLegacyCRLToACR.containsKey(key2)){
                    acr.Source_Contact_ID__c = maponContactidandLegacyCRLToACR.get(key2).Source_Contact_ID__c;
                }
                acrListInsert.add(acr);
            }
        }

        if(Schema.sObjectType.AccountContactRelation.isCreateable() && !acrListInsert.isEmpty()) {
            insert acrListInsert;
        }
    }
}