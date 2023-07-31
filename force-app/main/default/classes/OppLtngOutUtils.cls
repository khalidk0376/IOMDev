/**
* File			: 	OppLtngOutUtils
* Project       :   Informa Order Management [IOM-519]
* Created By	: 	Girikon(Ashish)
* Created Date	: 	20th Jan 2022
* Test Class   :    OppLtngOutUtils_Test(100%)
* ***************************************************************************
* @description : Utility Class for IOM Lightning Out Appliactions
*****************************************************************************
* Modification log :
* 1. Girikon (Deepak)    [20th Feb 2023 (GECI-835) ] - To Show data if contract is not created
* 2. Girikon (Ashish)    [22nd Feb 20223 (GECI-911)] - show Invoices with Rebilled Status via Lightning Out
*/
public without sharing class OppLtngOutUtils 
{
    /**
    * @description  This method is used to return Set of Order Ids
    * @param imOppNumber Informa opportunity Number
    * @return Set<String>
    */
    public static Set<String> getOrderIds(String imOppNumber)
    {
        Set<String> setOrd = new Set<String>();
        List<Opportunity> listOpp = [SELECT Id, Main_Contract__c FROM Opportunity WHERE IM_Opportunity_No__c =:imOppNumber WITH SECURITY_ENFORCED];
        if(!listOpp.isEmpty()){
            if(String.isNotBlank(listOpp.get(0).Main_Contract__c)){
                List<OrderItem> listOrderItem = [SELECT Id,OrderId FROM OrderItem WHERE SBQQ__Contract__c=:listOpp.get(0).Main_Contract__c AND SBQQ__Activated__c=true WITH SECURITY_ENFORCED];
                for(OrderItem oi : listOrderItem){
                    setOrd.add(oi.OrderId);
                }
            }
            else{
                List<Order> listOrder = [SELECT Id FROM Order WHERE OpportunityId=:listOpp.get(0).Id WITH SECURITY_ENFORCED];
                for(Order ord : listOrder){
                    setOrd.add(ord.Id);
                }
            }
        }
        return setOrd;
    }

    /**
    * @description  This method is used to return list of Collection Notes
    * @param imOppNumber Informa opportunity Number
    * @return list<Collection_Note>
    */
    @AuraEnabled(cacheable = true)
    public static List<Collection_Note__c> getCollectionNotes(String imOppNumber)
    {
        Set<String> setOrd = new Set<String>();
        setOrd = getOrderIds(imOppNumber);
        //for(Opportunity opp : [Select Id, Main_Contract__r.SBQQ__Order__c from Opportunity where IM_Opportunity_No__c =: imOppNumber]){
        //    setOrd.add(opp.Main_Contract__r.SBQQ__Order__c);
        //}
        List<Collection_Note__c> listCollectionNotes = new List<Collection_Note__c>([SELECT Id,NoteID__c,Note_Type__c,Note_Date__c,Invoice__c,Invoice__r.Name,Invoice__r.Outstanding_Balance__c,Invoice__r.blng__InvoiceStatus__c,Invoice__r.CurrencyISOCode,Note__c,User__c FROM Collection_Note__c WHERE Invoice__r.blng__Order__c =: setOrd  WITH SECURITY_ENFORCED ORDER BY CreatedDate LIMIT 1500]);
        
        return listCollectionNotes;
    }
    
    /**
    * @description  This method is used to return list of Invoice and Credit Note
    * @param imOppNumber Informa opportunity Number
    * @return List<Returndata>
    */
    @AuraEnabled(cacheable = true)
    public static List<Returndata> getInvAndCN(String imOppNumber)
    {
        Set<String> setOrd = new Set<String>();
        setOrd = getOrderIds(imOppNumber);
        List<Returndata> recordList = new List<Returndata>(); // [GECI-911] - Removed Rebilled Filter
        //[GECI-1381 Added IM_Invoice_No__c in SOQL]
        for(blng__Invoice__c inv : [SELECT ERP_Reference__c,IM_Invoice_No__c,CurrencyISOCode,Invoice_Number__c,blng__InvoiceDate__c,blng__DueDate__c,blng__TotalAmount__c,Outstanding_Balance__c,blng__InvoiceStatus__c FROM blng__Invoice__c WHERE blng__Order__c IN : setOrd WITH SECURITY_ENFORCED]){
        	Returndata obj = new Returndata();
            obj.ERPReference = inv.ERP_Reference__c;
            obj.IOMNumber = inv.IM_Invoice_No__c;
            obj.InvoiceDate = inv.blng__InvoiceDate__c;
            obj.DueDate = inv.blng__DueDate__c;
            obj.TotalAmount = inv.blng__TotalAmount__c;
            obj.OutstandingBalance = inv.Outstanding_Balance__c;
            obj.Status = inv.blng__InvoiceStatus__c;
            obj.CurrencyISOCode = inv.CurrencyISOCode;
            obj.SourceInvoice = '';
            obj.CNDate = null;
            recordList.add(obj);
        }
        
        for(blng__CreditNote__c cr : [SELECT ERPReference__c,blng__CreditNoteDate__c,Name,CurrencyISOCode,blng__Status__c,blng__RelatedInvoice__r.IM_Invoice_No__c,blng__RelatedInvoice__r.blng__InvoiceDate__c,blng__RelatedInvoice__r.blng__DueDate__c,blng__TotalAmount__c,blng__RelatedInvoice__r.Outstanding_Balance__c FROM blng__CreditNote__c WHERE blng__RelatedInvoice__r.blng__Order__c IN : setOrd WITH SECURITY_ENFORCED]){
        	Returndata obj = new Returndata();
            obj.ERPReference = cr.ERPReference__c;
            obj.IOMNumber = cr.Name;
            obj.InvoiceDate = null;
            obj.DueDate = null;
            obj.TotalAmount = cr.blng__TotalAmount__c;
            obj.OutstandingBalance = null;
            obj.Status = cr.blng__Status__c;
            obj.SourceInvoice = cr.blng__RelatedInvoice__r.IM_Invoice_No__c;
            obj.CurrencyISOCode = cr.CurrencyISOCode;
            obj.CNDate = cr.blng__CreditNoteDate__c;
            recordList.add(obj);
        }
        return recordList;
    }
    
    /**
    * @description  This method is used to return list of Collection Notes
    * @param accId Account Id
    * @return list<Collection_Note>
    */
    @AuraEnabled(cacheable = true)
    public static List<Collection_Note__c> getaccCollectionNotes(String accId)
    {
        Set<String> setOrd = new Set<String>();
        //for(Opportunity opp : [Select Id, Main_Contract__r.SBQQ__Order__c from Opportunity where Account.IM_Account_No__c =: accId]){
        //    setOrd.add(opp.Main_Contract__r.SBQQ__Order__c);
        //}
        List<Opportunity> listOpp = [SELECT Id, Main_Contract__c FROM Opportunity WHERE Account.IM_Account_No__c =: accId WITH SECURITY_ENFORCED];
        if(!listOpp.isEmpty()){
            Set<String> contractIds = new Set<String>();
            Set<String> oppIds = new Set<String>();
            for(Opportunity opp : listOpp){
                if(String.isNotBlank(opp.Main_Contract__c)){
                    contractIds.add(opp.Main_Contract__c);
                }
                else{
                    oppIds.add(opp.Id);
                }
            }
            if(!contractIds.isEmpty()){
                List<OrderItem> listOrderItem = [SELECT Id,OrderId FROM OrderItem WHERE SBQQ__Contract__c IN:contractIds AND SBQQ__Activated__c=true WITH SECURITY_ENFORCED];
                for(OrderItem oi : listOrderItem){
                    setOrd.add(oi.OrderId);
                }
            }
            if(!oppIds.isEmpty()){
                List<Order> listOrder = [SELECT Id FROM Order WHERE OpportunityId IN:oppIds WITH SECURITY_ENFORCED];
                for(Order ord : listOrder){
                    setOrd.add(ord.Id);
                }
            }
        }
        
        List<Collection_Note__c> listCollectionNotes = new List<Collection_Note__c>([SELECT Id,NoteID__c,Note_Type__c,Note_Date__c,Invoice__c,Invoice__r.Name,Invoice__r.Outstanding_Balance__c,Invoice__r.blng__InvoiceStatus__c,Invoice__r.CurrencyISOCode,Note__c,User__c FROM Collection_Note__c WHERE Invoice__r.blng__Order__c =:setOrd  WITH SECURITY_ENFORCED ORDER BY CreatedDate LIMIT 1500]);
        
        return listCollectionNotes;
    }
    
    /**
    * @description  wrapper class
    */
    public class Returndata{
        /** @description erpReference*/
        @AuraEnabled public String erpReference;

        /** @description iomNumber*/
		@AuraEnabled public String iomNumber;

        /** @description invoiceDate*/
		@AuraEnabled public Date invoiceDate;

        /** @description dueDate*/
		@AuraEnabled public Date dueDate;

        /** @description totalAmount*/
		@AuraEnabled public Decimal totalAmount;

        /** @description outstandingBalance*/
		@AuraEnabled public Decimal outstandingBalance;
        
        /** @description currencyISOCode*/
        @AuraEnabled public String currencyISOCode;

        /** @description status*/
		@AuraEnabled public String status;

        /** @description sourceInvoice*/
		@AuraEnabled public String sourceInvoice;
        
        /** @description cnDate*/
        @AuraEnabled public Date cnDate;
    }
}