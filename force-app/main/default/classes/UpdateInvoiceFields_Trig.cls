/***************************************************************************
* File			: 	UpdateInvoiceFields_Trig
* Project       :   Informa Order Management [IOM-772]
* Created By	: 	Girikon(Ashish)
* Created Date	: 	27th Jan 2022
* Test Class   :    UpdateInvoiceFields_Trig_Test(100%)
* ***************************************************************************
* @description : Utility Class for Updating all Fields updates on Invoice
*****************************************************************************
* Modification Log :
* 1. [IML2R-1264]   - Girikon(Ashish)-  11 April 2022   Add Deafult value in Outstanding Balance
* 2. [IE-10]        - Girikon(Ashish)-  09 AUG 2022     update Invoice Id on Payment_Transactions
* 3. [IE-435]       - Girikon(Ashish)-  21 OCT 2022     update Default OutStandig Balance to Invoice Record
******************************************************************************/
public with sharing class UpdateInvoiceFields_Trig implements TriggerInterface_Invoice.Runnable 
{
    /**
    * @description  This method is execute Trigger
    * @param trig Invoice TriggerInterface    
    */
    public void run(TriggerInterface_Invoice.Trig trig)
    {
        if(trig.isBefore && (trig.isInsert || trig.isUpdate)) 
        {   //Update Account Fields From Order
            updateinvFields(trig.newList,trig.oldMap);
            // Set Print Flag Default Value
            updatePDFtoCustomer(trig.newList);
            // Update Fields
            //updateDefaultValues(trig.newList,trig.oldMap);
            //
            updateInvOutStandingVal(trig.newList,trig.oldMap);
        }
        if(trig.isAfter && (trig.isInsert || trig.isUpdate))
        {   // update Invoice Id on Payment_Transactions [IE-10]
            updatePaymentTrans(trig.newList,trig.oldMap);
        }
        
    }
   
    /**
    * @description  This method is used to update Send PDF to Customer on Invoice
    * @param newInvoiceList new Invoice List
    * @param oldInvoiceMap Old Invoice Map
    */
    private static void updateinvFields(list<blng__Invoice__c> newInvoiceList,Map<Id,blng__Invoice__c>oldInvoiceMap)
    {
        set<Id> orderIds = new set<Id>();
        for(blng__Invoice__c inv:newInvoiceList)
        {
            blng__Invoice__c oldInv = !oldInvoiceMap.isEmpty()?oldInvoiceMap.get(inv.Id):new blng__Invoice__c();
            if(string.isNotBlank(inv.blng__Order__c) && inv.blng__Order__c !=  oldInv.blng__Order__c)
            {
                orderIds.add(inv.blng__Order__c);
            }
        }
        Map<Id,Order> orderMap = new Map<Id,Order>([SELECT Id,Ship_To_Account__c,Opportunity.AdditionalCCEmailAddresses__c,Edition__r.CC_Emails__c,BillToContactId,PoNumber,Legal_Entity__c,Account_Tax_Number__c,Tax_Rule__c,Tax_Exempt1__c FROM Order where Id IN:orderIds]);
        for(blng__Invoice__c inv:newInvoiceList)
        {
            if(orderMap.containsKey(inv.blng__Order__c))
            {
                if((String.isNotBlank(orderMap.get(inv.blng__Order__c).Edition__r.CC_Emails__c)) && (String.isNotBlank(orderMap.get(inv.blng__Order__c).Opportunity.AdditionalCCEmailAddresses__c))){
                    inv.Additional_CC_emails__c = orderMap.get(inv.blng__Order__c).Edition__r.CC_Emails__c+','+orderMap.get(inv.blng__Order__c).Opportunity.AdditionalCCEmailAddresses__c;
                }
                else if((String.isBlank(orderMap.get(inv.blng__Order__c).Opportunity.AdditionalCCEmailAddresses__c))){
                    inv.Additional_CC_emails__c = orderMap.get(inv.blng__Order__c).Edition__r.CC_Emails__c;
                }
                else{
                    inv.Additional_CC_emails__c = orderMap.get(inv.blng__Order__c).Opportunity.AdditionalCCEmailAddresses__c;
                }
                inv.Ship_To_Account__c = orderMap.get(inv.blng__Order__c).Ship_To_Account__c;
                
                inv.blng__BillToContact__c = orderMap.get(inv.blng__Order__c).BillToContactId;
                inv.Legal_Entity__c = orderMap.get(inv.blng__Order__c).Legal_Entity__c;
                inv.PO_Number__c = orderMap.get(inv.blng__Order__c).PoNumber;
                inv.Tax_Registration__c = orderMap.get(inv.blng__Order__c).Account_Tax_Number__c;
                inv.Tax_Rule__c = orderMap.get(inv.blng__Order__c).Tax_Rule__c;
                inv.Tax_Exempt__c = orderMap.get(inv.blng__Order__c).Tax_Exempt1__c;
            }
        }
    }
    
    /**
    * @description  This method is used to update Send PDF to Customer on Invoice
    * @param newInvoiceList new Invoice List
    */
    private static void updatePDFtoCustomer(list<blng__Invoice__c> newInvoiceList)
    {
        set<Id> orderIds = new set<Id>();
        set<Id> entityIds = new set<Id>();
        for(blng__Invoice__c inv:newInvoiceList)
        {
            if(string.isNotBlank(inv.blng__Order__c))
            {
                orderIds.add(inv.blng__Order__c);
            }
            if(string.isNotBlank(inv.Legal_Entity__c)){
                entityIds.add(inv.Legal_Entity__c);
            }
        }
        Map<Id,Order> orderMap = new Map<Id,Order>([SELECT Id,Is_Barter_Opportunity__c FROM Order where Id IN:orderIds]);
        Map<Id,blng__LegalEntity__c> entityMap = new Map<Id,blng__LegalEntity__c>([Select Id, Send_PDF_for_Barter_Sell_to_Customer__c from blng__LegalEntity__c where Id IN: entityIds]);
        for(blng__Invoice__c inv:newInvoiceList)
        {
            inv.Send_PDF_to_Customer__c = 'Y';
            if(orderMap.containsKey(inv.blng__Order__c) && orderMap.get(inv.blng__Order__c).Is_Barter_Opportunity__c == true)
            {
                inv.IsBarter__c = 'Y';
                inv.Send_PDF_to_Customer__c = entityMap.containsKey(inv.Legal_Entity__c) && entityMap.get(inv.Legal_Entity__c).Send_PDF_for_Barter_Sell_to_Customer__c == true ? 'Y' : 'N';
            }
        }
    }
    /**
    * @description  This method is used to update Default vaues to Invoice Record
    * @param newInvoiceList new Invoice List
    * @param oldInvoiceMap Old Invoice Map
    */
    /*
    private static void updateDefaultValues(list<blng__Invoice__c> newInvoiceList, Map<Id,blng__Invoice__c> oldInvoiceMap)
    {    
            
        for(blng__Invoice__c inv:newInvoiceList)
        {
            System.debug('IN updateDefaultValues ');
            blng__Invoice__c oldInv = !oldInvoiceMap.isEmpty()?oldInvoiceMap.get(inv.Id):new blng__Invoice__c();            
            if(inv.Outstanding_Balance__c == null && inv.Tax_Status__c !=  oldInv.Tax_Status__c && inv.Tax_Status__c == 'Tax Complete')
            {
                inv.Outstanding_Balance__c = inv.blng__TotalAmount__c; // IOM-1264                
            }
        } 
    }*/
     /** [IE-435]
    * @description  This method is used to update Default OutStandig Balance to Invoice Record -
    * @param newInvoiceList new Invoice List
    * @param oldInvoiceMap Old Invoice Map
    */
    private static void updateInvOutStandingVal(list<blng__Invoice__c> newInvoiceList, Map<Id,blng__Invoice__c> oldInvoiceMap)
    {     
         Map<Id,Decimal> invOutStandbalcMap = new Map<Id,Decimal>();
        for(blng__Invoice__c inv:newInvoiceList)
        {         
            blng__Invoice__c oldInv = !oldInvoiceMap.isEmpty()?oldInvoiceMap.get(inv.Id):new blng__Invoice__c();            
            if(inv.Outstanding_Balance__c == null && inv.Tax_Status__c !=  oldInv.Tax_Status__c && inv.Tax_Status__c == 'Tax Complete')
            {
                //inv.Outstanding_Balance__c = inv.blng__TotalAmount__c; // IOM-1264
                invOutStandbalcMap.put(inv.id,inv.blng__TotalAmount__c);
            }
        }
    
        for(AggregateResult ar : [SELECT Invoice__c,Sum(Amount__c) total From Payment_Transaction__c WHERE Payment_Type__c != 'Refund' AND Invoice__c in:invOutStandbalcMap.keySet() WITH SECURITY_ENFORCED GROUP BY Invoice__c ])
        {
            Id invId = (Id)ar.get('Invoice__c');
            invOutStandbalcMap.put(invId,invOutStandbalcMap.get(invId)-(Decimal)ar.get('total'));
        }
        
        for(blng__Invoice__c inv:newInvoiceList)
        {
            if(invOutStandbalcMap.containsKey(inv.Id))
            {
                inv.Outstanding_Balance__c = invOutStandbalcMap.get(inv.Id);
            }
        }
        
    }
    /** [IE-10]
    * @description  This method is used add Invoice Id on Payment_Transactions
    * @param newInvoiceList new Invoice List
    * @param oldInvoiceMap Old Invoice Map
    */
    private static void updatePaymentTrans(list<blng__Invoice__c> newInvoiceList,Map<Id,blng__Invoice__c>oldInvoiceMap)
    {
        Map<Id,Id> orderInvMap = new Map<Id,Id>();
        for(blng__Invoice__c inv:newInvoiceList)
        {
            blng__Invoice__c oldInv = !oldInvoiceMap.isEmpty()?oldInvoiceMap.get(inv.Id):new blng__Invoice__c();
            // System.debug('Old Odr : '+oldInv.blng__Order__c+' + new Order :'+inv.blng__Order__c);
            if(string.isNotBlank(inv.blng__Order__c) && inv.blng__Order__c !=  oldInv.blng__Order__c)
            {
                orderInvMap.put(inv.blng__Order__c,inv.Id);
            }
            
        }
       
        if(!orderInvMap.isEmpty())
        {
            List<Payment_Transaction__c> listPaymetTxn = new List<Payment_Transaction__c>();
            for(Payment_Transaction__c payTxn : [SELECT Id,Order__c,Invoice__c FROM Payment_Transaction__c WHERE Order__c IN:orderInvMap.keySet() WITH SECURITY_ENFORCED])
            {
                payTxn.Invoice__c = orderInvMap.get(payTxn.Order__c);
                listPaymetTxn.add(payTxn);
                
             }
           
            if(!listPaymetTxn.isEmpty() && Schema.sObjectType.Payment_Transaction__c.isUpdateable())
            {
                update listPaymetTxn;
            }            
        }     
        
    }
    
}