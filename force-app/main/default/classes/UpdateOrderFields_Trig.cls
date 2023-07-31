/**
* File			: 	UpdateOrderFields_Trig
* Project       :   Informa Order Management [IOM-772]
* Created By	: 	Girikon(Ashish)
* Created Date	: 	27th Jan 2022
* Test Class   :    UpdateOrderFields_Trig_Test(100%)
* ***************************************************************************
* @description : Utility Class for Updating all Fields updates on Order
*****************************************************************************
* Modification Log :
* 1. [IOM-1873] - Girikon(Ashish)-  27 July 2022, Added Logic to add Owner ID from Opp
*/
public with sharing class UpdateOrderFields_Trig implements TriggerInterface_Order.Runnable 
{
    /**
    * @description  This method is execute Trigger
    * @param trig Order TriggerInterface
    */
    public void run(TriggerInterface_Order.Trig trig)
    {
        if(trig.isBefore && (trig.isInsert || trig.isUpdate))
        {
            updateFieldsFromOpportunity(trig);
            // Update Account Tax Number
            updateAccountTaxNumber(trig);
            // Updates fields if no Opp is avaliable [Direct Order Creation] - [IE-30]
            updateFieldsWithoutOpportunity(trig);
            //GECI-393
            updatePaymentTermOrder(trig);
        }
        if(trig.isBefore && trig.isInsert){
            updateOrderTransStatus(trig);
        }
    }
    private static void updateOrderTransStatus(TriggerInterface_Order.Trig trig){
        // MAP of Edtion Code & Legacy CRM With Edition Settings
        Map<String,Edition_Setting__mdt> mapEditionSt = InvoiceTaxApiSynchronization_Trig.getEditionSettingsMapOnEditionCodeLegacyCRM();

        Set<Id> setIdEditions = new set<Id>();
        Set<Id> qtIds = new Set<Id>();
        for(Order o : trig.newList){
            setIdEditions.add(o.Edition__c);
            if(String.isNotBlank(o.SBQQ__Quote__c))
            {
                qtIds.add(o.SBQQ__Quote__c);
            }
        }
        //Get Edition Data
        map<Id,Edition__c> mapEditions  = new map<Id,Edition__c>([select id,Edition_Code__c,Name from Edition__c where id in : setIdEditions]);
        // get Quote Data
        Map<Id,SBQQ__Quote__c> qtMap = new Map<Id,SBQQ__Quote__c>([SELECT Id,Show_on_Action_Dashboard__c FROM SBQQ__Quote__c where Id IN:qtIds WITH SECURITY_ENFORCED]);
        for(Order odr : trig.newList)
        {
            string key = String.isNotBlank(odr.Edition__c) && mapEditions.containskey(odr.Edition__c) ? mapEditions.get(odr.Edition__c).Edition_Code__c+'_'+odr.Legacy_CRM_Instance__c :'';

            Boolean overrideTranslationStatus =  String.isNotBlank(key) && mapEditionSt.containsKey(key)?(mapEditionSt.get(key)?.Order_Translation_Status_override__c):false;

            odr.Order_Translation_Status__c = overrideTranslationStatus ?'Completed': odr.Order_Translation_Status__c;

            if(String.isNotBlank(odr.SBQQ__Quote__c) && qtMap.containsKey(odr.SBQQ__Quote__c))
            {
                SBQQ__Quote__c qt = qtMap.get(odr.SBQQ__Quote__c);
                if(qt.Show_on_Action_Dashboard__c == true){
                    odr.Order_Translation_Status__c = 'Pending';
                }
            }
        }
    }
    /**
    * @description  This method is used to update Ship TO account on ORDER
    * @param trig 
    */
    private static void updateFieldsFromOpportunity(TriggerInterface_Order.Trig trig)
    {
        Set<Id> oppIds = new Set<Id>();        
        for(Order odr : trig.newList)
        {
            Order oldOrder = !trig.oldMap.isEmpty()?trig.oldMap.get(odr.Id):new Order();
            if(String.isNotBlank(odr.OpportunityId) && odr.OpportunityId != oldOrder.OpportunityId)
            {
                oppIds.add(odr.OpportunityId);
            }
        }

        Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>([SELECT Id,Ship_To_Account__c,Billing_Contact__c,Bill_To_Account__c,Account_Tax_Number__c,PO_Number__c,Tax_Rule__c,StageName,OwnerId,Legacy_CRM_Instance__c,Payment_Term_Code__c FROM opportunity where Id IN:oppIds WITH SECURITY_ENFORCED]);
        for(Order odr : trig.newList)
        {
            if(String.isNotBlank(odr.OpportunityId) && oppMap.containsKey(odr.OpportunityId))
            {
                Opportunity opp = oppMap.get(odr.OpportunityId);
                odr.Ship_To_Account__c = opp.Ship_To_Account__c;
                if(trig.isInsert){

                    if(String.isNotBlank(opp.Billing_Contact__c)){
                        odr.BillToContactId = opp.Billing_Contact__c;
                        // odr.Bill_To_Contact__c = opp.Billing_Contact__c; //Custom Fields Not In Use
                    }

                    if(String.isNotBlank(opp.Bill_To_Account__c)){
                        // odr.Bill_To_Account__c = opp.Bill_To_Account__c;
                        odr.blng__BillingAccount__c = opp.Bill_To_Account__c; 
                    }
                    odr.Payment_Term_Code__c = opp.Payment_Term_Code__c; // Added for [IE-30]
                    odr.Legacy_CRM_Instance__c = opp.Legacy_CRM_Instance__c; // Added for [IE-28]
                    odr.OwnerId = opp.OwnerId;  // Added Logic to add Owner ID from Opp [IOM-1873] 
                    /*
                    if(String.isNotBlank(opp.Account_Tax_Number__c)){
                        odr.Account_Tax_Number__c = opp.Account_Tax_Number__c;
                    }
                    */
                    if(String.isNotBlank(opp.PO_Number__c)){
                        odr.PoNumber = opp.PO_Number__c;
                    }

                    if(String.isNotBlank(opp.Tax_Rule__c) && opp.StageName == 'Closed Won'){
                        odr.Tax_Rule__c = opp.Tax_Rule__c;
                    }
                }
            }
        }
    }

    /**
    * @description  This method is used to update Account Tax Number on ORDER
    * @param trig 
    */
    private static void updateAccountTaxNumber(TriggerInterface_Order.Trig trig)
    {
        Set<Id> accIds = new Set<Id>();        
        for(Order odr : trig.newList)
        {
            Order oldOrder = !trig.oldMap.isEmpty()?trig.oldMap.get(odr.Id):new Order();
            if(String.isNotBlank(odr.blng__BillingAccount__c) && odr.blng__BillingAccount__c != oldOrder.blng__BillingAccount__c)
            {
                accIds.add(odr.blng__BillingAccount__c);
            }
        }
        Map<Id,Id> maplatestAccountTaxnumber = new Map<Id,Id>();
        for(Account_Tax_Number__c accTN:[SELECT Id,Account__c FROM Account_Tax_Number__c WHERE Account__c IN:accIds AND Status__c = 'Valid' WITH SECURITY_ENFORCED ORDER BY Account__c,LastModifiedDate])
        {
            maplatestAccountTaxnumber.put(accTN.Account__c,accTN.Id);
        }
        
        for(Order odr : trig.newList)
        {
            if(String.isNotBlank(odr.blng__BillingAccount__c) && maplatestAccountTaxnumber.containsKey(odr.blng__BillingAccount__c))
            {
                odr.Account_Tax_Number__c = maplatestAccountTaxnumber.get(odr.blng__BillingAccount__c);
            }
        }
    }
    /**
    * @description  [IE-17] This method is used to update Order Fields if no Opp is found
    * @param trig 
    */
    private static void updateFieldsWithoutOpportunity(TriggerInterface_Order.Trig trig)
    {
        Set<Id> editionIds = new Set<Id>();        
        for(Order odr : trig.newList)
        {
           
            if(String.isBlank(odr.OpportunityId) && String.isNotBlank(odr.Edition__c))
            {
                editionIds.add(odr.Edition__c);
            }
        }

        if(!editionIds.isEmpty())
        {
            Map<Id,Edition__c> editionMap = new Map<Id,Edition__c>([SELECT Id,Name,Invoice_to_be_issued_before__c,Part_of_Series__r.Legal_Entity__c FROM Edition__c WHERE ID in: editionIds WITH SECURITY_ENFORCED]);

            // Get payment Term Code Map
            Map<String,string> editionPaymentCodeMap = OpportunityBillToAccount_Trig.getEditionPaymentTermCode(editionIds);

            for(Order odr : trig.newList)
            {
                Order oldOrder = !trig.oldMap.isEmpty()?trig.oldMap.get(odr.Id):new Order();

                if(String.isBlank(odr.OpportunityId) && String.isNotBlank(odr.Edition__c) && odr.Edition__c != oldOrder.Edition__c && editionMap.containsKey(odr.Edition__c))
                {
                    Edition__c edtn = editionMap.get(odr.Edition__c);
                    // Added for [IE-17]
                    //odr.SBQQ__PaymentTerm__c  = edtn.Invoice_to_be_issued_before__c == '0'?'Due on receipt':'Net '+edtn.Invoice_to_be_issued_before__c;
                    // Added for [IE-30]
                    odr.Payment_Term_Code__c = editionPaymentCodeMap.containsKey(odr.Edition__c)? editionPaymentCodeMap.get(odr.Edition__c):'';
                    
                    odr.Legal_Entity__c = edtn.Part_of_Series__r.Legal_Entity__c;
                }
            }
        }        
    }
    /**
    * @description  [GECI-393] This method is used to update Payment term on Order
    * @param trig 
    */
    private static void updatePaymentTermOrder(TriggerInterface_Order.Trig trig){
        Set<Id> qtIds = new Set<Id>();
        Set<Id> edIds = new Set<Id>();
        Set<Id> accIds = new Set<Id>();
        for(Order odr : trig.newList)
        {
            qtIds.add(odr.SBQQ__Quote__c);
            edIds.add(odr.Edition__c);
            accIds.add(odr.blng__BillingAccount__c);
            
        }
        Map<Id,SBQQ__Quote__c> qtMap = new Map<Id,SBQQ__Quote__c>([SELECT Id,SBQQ__PaymentTerms__c FROM SBQQ__Quote__c WHERE ID in: qtIds WITH SECURITY_ENFORCED]);
        Map<Id,Account>  accMap = new Map<Id,Account>([Select Id,Payment_Term__c from Account where Id IN: accIds WITH SECURITY_ENFORCED]);
        Map<Id,Edition__c> edMap = new Map<Id,Edition__c>([SELECT Id,Name,Invoice_to_be_issued_before__c,Edition_Cut_Off_days__c,Start_Date__c FROM Edition__c WHERE ID in: edIds WITH SECURITY_ENFORCED]);
        
        for(Order odr : trig.newList){
            Order oldOrder = (trig.isUpdate?trig.oldMap.get(odr.Id):new Order());
            if(odr.Status != 'Cancelled' && oldOrder.Status != odr.Status)
            {
                odr.SBQQ__PaymentTerm__c = 'Net 30';// Default value if neither conditions matches
                if(String.isNotBlank(odr.OpportunityId) && String.isNotBlank(odr.SBQQ__Quote__c) && qtMap.containsKey(odr.SBQQ__Quote__c) && qtMap.get(odr.SBQQ__Quote__c).SBQQ__PaymentTerms__c != null){
                    odr.SBQQ__PaymentTerm__c = qtMap.get(odr.SBQQ__Quote__c).SBQQ__PaymentTerms__c;
                }else if(String.isNotBlank(odr.blng__BillingAccount__c) && accMap.containsKey(odr.blng__BillingAccount__c) && accMap.get(odr.blng__BillingAccount__c).Payment_Term__c != null){
                    odr.SBQQ__PaymentTerm__c = accMap.get(odr.blng__BillingAccount__c).Payment_Term__c;
                }else if(String.isNotBlank(odr.Edition__c) && edMap.containsKey(odr.Edition__c) && edMap.get(odr.Edition__c).Invoice_to_be_issued_before__c != null){
                    odr.SBQQ__PaymentTerm__c = edMap.get(odr.Edition__c).Invoice_to_be_issued_before__c == '0'?'Due on receipt':'Net '+edMap.get(odr.Edition__c).Invoice_to_be_issued_before__c;
                }
                // Set Due on receipt if No of Days for Edition to Start is less than Edition_Cut_Off_days__c [|Migrated from PaymentTermOnOrder_Trig|] // [GECI-2008]
                if(edMap.get(odr.Edition__c)?.Start_Date__c !=null  && edMap.get(odr.Edition__c)?.Edition_Cut_Off_days__c!=null  
                    && edMap.get(odr.Edition__c).Start_Date__c.addDays( -1 *integer.valueof(edMap.get(odr.Edition__c).Edition_Cut_Off_days__c)) <= Date.today())
                {
                    odr.SBQQ__PaymentTerm__c ='Due on receipt';
                    odr.Payment_Term_Reason__c ='No of Days for Edition to Start is less then Edition_Cut_Off_days';     
                }
            }
        }
    }
}