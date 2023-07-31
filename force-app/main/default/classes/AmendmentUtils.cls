/**
* Created By       :   Girikon(Ashish)
* Created On       :   19 Feb 2020
* @description     :   This class provides following functionalities:          
*                      Allow to create and get change request detail,update change request,execulete FCR(full cancel & rebill) and unhold all order line items for billing.
*                      There are four AuraEnabled functions
*                      1. getChangeRequest(get change request record detail)
*                      2. updateChangeRequest(update change request)
*                      3. executeFullCancelRebill(execulete FCR(full cancel & rebill) for order(s))
*                      4. executeUnHoldOrder(unhold all order line items for billing and requeue tax calculation)
*                      
* Test Class       :   AmendmentUtils_Test(95%)
***********************************************************************************************
* Modification Log :
* 1. [IML2R-208] - Girikon(Ashish)-  4 march 2020, Add Amendment Functions
* 2. [IML2R-1799] - Girikon(Prashant)-  24 march 2020, Added the 'Full Cancellation' Scenario
* 3. [IOM-775] - Girikon(Ashish) - 23 Feb 22 ,Added method to create API Sync Items
* 4. [IOM-448] - Girikon(Ansh) - 23 Feb 22 ,Added param in method to create API Sync Items
* 5. [IOM-572] - Girikon(Ashish) - 07 March 22 ,Added method to Amend Complete
* 6. [IOM-1804] - Girikon(Ashish) - 18 July 22 ,Added a Pram to executeFullCancelRebill
* 6. [GECI-1394] - Girikon(Ashish) - 14 April 23 ,Added Orderids for specific order Amendment
* 7. [GECI-2037]- IBM(Bharath)- 10 july 23, removed credit notes query in getAllInvoicesAndCreditNotes method
*/
public with sharing  class AmendmentUtils
{
    /**
    * @description  Set od Type of changes for which main Opp as to marked as Closed Lost after Amendment 
    */
    private static Set<String> amendWithClosedLostOppCR = new Set<String>{'Cancellation'};
    
    /**
    * @description  map Amendment type for which No Opp/Order data will be synced with CRM
    */
    public static Map<String,String> amendWithNoDataSyncMAP = new Map<String,String>{
        
        'Cancellation' => GlobalConstants.CHANGE_REQUEST_COMPLETED,
        'Product Upgrade' => GlobalConstants.CHANGE_REQUEST_COMPLETED,
        'Product Downgrade' => GlobalConstants.CHANGE_REQUEST_COMPLETED,
        'Tax Exempt Rebill' => GlobalConstants.CHANGE_REQUEST_COMPLETED
    };

   /**
    * @description  map Amendment type & Order Hub request APi Item Type 
    */
    public static Map<String,String> amendTypeOrderHubAPITransMap = new Map<String,String>{        
        'PO number change' => 'Re-Print for PO number change',
        'Update Bill To Contact' => 'Re-Print for Contact Details Change',
        'Account Name Change' => 'Re-Print for Account Details Change',
        'Shipping Address Change' => 'Re-Print for Ship To Account Details Change',
        'Bill To Account Change' => 'Re-Print for Bill To Account Details Change',
        'Billing Address Change' => 'Re-Print for Bill To Account Details Change',
        'Ship To Account Change' => 'Re-Print for Ship To Account Details Change',
        'Bill to Contact Details Change' => 'Re-Print for Contact Details Change ',
        'VAT Registration Number Change' => 'Re-Print for Bill To Account Details Change '
    };

    /**
    * @description: Asyc Apex Job ID from other class if Asnc process has started which needs a tracking.
    */
    public static string asyncJobId;
    
    /**
    * @description  :   to get change request record detail
    * @param   changeRequestId :   change request Id
    * @return :change request record detail
    */
    @AuraEnabled
    public static Change_Request__c getChangeRequest(Id changeRequestId)
    {
        list<Change_Request__c> lstchangereqList = new List<Change_Request__c>();
        if(Schema.sObjectType.Change_Request__c.isAccessible())
        {
            lstchangereqList = [Select Id,Contract__c,Opportunity__r.Legal_Entity__r.Legal_Entity_Code__c,Opportunity__r.Legacy_CRM_Instance__c,Opportunity__r.Bill_To_Account__r.Region__c,Opportunity__r.Payment_Schedule__c,Amended_Opportunity__c,Opportunity__r.Event_Payment_ScheduleFor__c,Edition__r.X3rd_Party_ERP_System__c,Opportunity__r.Main_Contract__c,Opportunity__r.Bill_To_Account__c,Opportunity__r.Ship_To_Account__c,Opportunity__r.Ship_To_Account__r.BillingStreet,Opportunity__r.Ship_To_Account__r.BillingState,Opportunity__r.Ship_To_Account__r.BillingCountryCode,Opportunity__r.Ship_To_Account__r.BillingStateCode,Opportunity__r.Ship_To_Account__r.BillingPostalCode,Opportunity__r.Ship_To_Account__r.Billing_Address_Line_2__c,Opportunity__r.Ship_To_Account__r.Billing_Address_Line_3__c,Opportunity__r.Ship_To_Account__r.BillingCountry,Opportunity__r.Ship_To_Account__r.BillingCity,Amendment_Type__c,Change_Request_Status__c,Amended_Quote_Id__c,New_Order__c,Type_of_Change__c,Opportunity__c,New_Billing_City__c,New_Billing_Country__c,New_Billing_Postal_Code__c,New_Billing_State__c,New_Billing_Street__c,Current_Processing_Step__c,Opportunity__r.Bill_To_Account__r.BillingStreet,Opportunity__r.Bill_To_Account__r.Billing_Address_Line_2__c,Opportunity__r.Bill_To_Account__r.Billing_Address_Line_3__c,Opportunity__r.Bill_To_Account__r.BillingCity,Opportunity__r.Bill_To_Account__r.BillingCountry,Opportunity__r.Bill_To_Account__r.BillingCountryCode,Opportunity__r.Bill_To_Account__r.BillingState,Opportunity__r.Bill_To_Account__r.BillingStateCode,Opportunity__r.Bill_To_Account__r.BillingPostalCode,Opportunity__r.PO_Number__c,Opportunity__r.Billing_Contact__c,Opportunity__r.Bill_To_Account__r.Name,Opportunity__r.Billing_Contact__r.LastName,Opportunity__r.Billing_Contact__r.FirstName,Opportunity__r.Billing_Contact__r.Email,Opportunity__r.Billing_Contact__r.Phone,Opportunity__r.Billing_Contact__r.MobilePhone,Opportunity__r.Billing_Contact__r.Account.Name,Invoice_To_Cancel__c,Comments__c from Change_Request__c where Id =: changeRequestId];
        }
        Change_Request__c amendmentObj  = lstchangereqList.get(0);

        List<Account_Tax_Number__c> accTaxes = new List<Account_Tax_Number__c>([SELECT Id,Account__c,Tax_ID__c FROM Account_Tax_Number__c WHERE Account__c =:amendmentObj.Opportunity__r.Bill_To_Account__c AND Status__c = 'Valid' WITH SECURITY_ENFORCED ORDER BY LastModifiedDate desc LIMIT 1 ]);

        amendmentObj.Old_Account_Tax_Number__r = !accTaxes.isEmpty()?accTaxes.get(0):new Account_Tax_Number__c();
        amendmentObj.Comments__c =  ''+[Select count() from OrderItem where SBQQ__BillingFrequency__c ='Invoice Plan' And Order.OpportunityId =: amendmentObj.Opportunity__c];

        return amendmentObj;
    }
    
    /**
    * @description   - to update change request
    * @param changeReqobj   change request
    */
    @AuraEnabled
    public static void updateChangeRequest(Change_Request__c changeReqobj)
    {
        if(Schema.sObjectType.Change_Request__c.isUpdateable())
        {            
            update changeReqobj;            
        }
    }
    
    /**
    * @description - to execulete FCR(full cancel & rebill) for order(s)
    * @param  changeReqobj   change request
    * @param  listtoCancelInvId   list of Cancel Inv Id
    * @return  String   apex job id
    */
    @AuraEnabled
    public static String executeFullCancelRebill(Change_Request__c changeReqobj,List<Id> listtoCancelInvId)
    {
        Set<Id> orderIds = getOrderIds(changeReqobj);
        List<OrderItem>  listOfOrderProduct = new List<OrderItem>();
        List<Id> listOfOrderProductId = new List<Id>();

        if(listtoCancelInvId !=null && !listtoCancelInvId.isEmpty())
        {
            listOfOrderProduct = [SELECT Id , blng__LegalEntity__c  FROM OrderItem  WHERE Id in(SELECT blng__OrderProduct__c FROM blng__InvoiceLine__c WHERE blng__Invoice__c in:listtoCancelInvId) AND OrderId In:orderIds WITH SECURITY_ENFORCED];
        }else{
            listOfOrderProduct = [SELECT Id , blng__LegalEntity__c  FROM OrderItem  WHERE OrderId In:orderIds WITH SECURITY_ENFORCED];
        }
        
        for(OrderItem ordProd : listOfOrderProduct){
            listOfOrderProductId.add(ordProd.Id);
        }
        if(!listOfOrderProduct.isEmpty()){ // Added new Pram listtoCancelInvId [IOM-1804]
            CancelAndRebilPostedInvoicesFCR_Trig.cancelInvoicesForOrderProductIds(listOfOrderProductId,listtoCancelInvId);
        }
        updateChangeRequest(new Change_Request__c(Id=changeReqobj.Id,Current_Processing_Step__c= 'Step 1'));
        return asyncJobId;
    }
    /**
    * @description   to execulete FCR(full cancel & rebill) for order(s) After Amendment [IML2R-208]
    * @param   changeReqobj  change request
    */
    @AuraEnabled
    public static void executeFullCancelRebillQuote(Change_Request__c changeReqobj)
    {        
        if(String.isNotBlank(changeReqobj.Amended_Quote_Id__c) && Schema.sObjectType.SBQQ__Quote__c.isUpdateable() && Schema.sObjectType.SBQQ__Quote__c.isAccessible())
        {                
            String amendmentScenarioType = 'FCR with price change'; // inculde Condition if Required
            SBQQ__Quote__c quote = new SBQQ__Quote__c();
            quote = [Select id ,SBQQ__Type__c, Amendment_Scenario_Type__c from SBQQ__Quote__c where id =: changeReqobj.Amended_Quote_Id__c limit 1];
            quote.Amendment_Scenario_Type__c = amendmentScenarioType;
            update quote;
            CancelAndRebilPostedInvoicesFCR_Trig.cancelAndRebilPostedInvoicesFCR(quote);
        }
    }

    /**
    * @description - to execulete PCR(Partial cancel & rebill) for Quotes [IML2R-208]
    * @param  changeReqobj  change request
    */
    @AuraEnabled
    public static void executePartialCreditORAddtionalInvoiceQuote(Change_Request__c changeReqobj)
    {
        if(String.isNotBlank(changeReqobj.Amended_Quote_Id__c) && Schema.sObjectType.SBQQ__Quote__c.isUpdateable())
        {  
            String amendmentScenarioType = '';
            // [IML2R-1799] Added the Full Cancellation Scenario
            if(changeReqobj.Type_of_Change__c == 'Cancellation')
            {
                amendmentScenarioType = 'Full cancellation';
            }else{
                amendmentScenarioType = 'FCR with price change';
            }
             // inculde Condition if Required
            SBQQ__Quote__c quote = new SBQQ__Quote__c(id = changeReqobj.Amended_Quote_Id__c,Amendment_Scenario_Type__c = amendmentScenarioType,SBQQ__Ordered__c = true,SBQQ__Status__c ='Approved');
            update quote;
                        
            // changeReqobj.Change_Request_Status__c = 'Completed';
            changeReqobj.Current_Processing_Step__c = 'Step 2';
            updateChangeRequest(changeReqobj);
        }       
    }
    
    /**
    * @description -  to unhold all order line items for billing and requeue tax calculation
    * @param   changeReqobj   change request
    */
    @AuraEnabled
    public static void executeUnHoldOrder(Change_Request__c changeReqobj)
    {
        Set<Id> orderIds = getOrderIds(changeReqobj);
        List<Order> listOfOrderUpdate = new List<Order>();
        List<OrderItem>  listOfOrderProduct = new List<OrderItem>([SELECT Id , blng__LegalEntity__c  FROM OrderItem  WHERE blng__HoldBilling__c ='Yes' AND OrderId In:orderIds]);
        List<Id> listOfOrderProductId = new List<Id>();
        for(OrderItem ordProd : listOfOrderProduct){
            listOfOrderProductId.add(ordProd.Id);
        }
        if(!listOfOrderProductId.isEmpty()){
            CancelAndRebilPostedInvoicesFCR_Trig.inverseCancelInvoicesForOrderProductIds(listOfOrderProductId);
        }
        for(Id ordId : orderIds){
            // need to fix for Invoice Plan products
            //BillingTransactionGenerator.generateBillingTransaction(new Order(Id=ordId));
            Order ordUpd = new Order(Id=ordId,Override_Tax_Status__c=true,Tax_Status__c='Tax Required');
            listOfOrderUpdate.add(ordUpd);
        }
        if(Schema.sObjectType.Order.isUpdateable() && !listOfOrderUpdate.isEmpty()){
            update listOfOrderUpdate;
        }

        changeReqobj.Current_Processing_Step__c = 'Step 3';
        updateChangeRequest(changeReqobj);        
    }

    /**
    * @description -   to update amendOpportunity
    * @param   changeReqobj change request
    * @return  String amendedQuoteId
    */
    @AuraEnabled
    Public Static String amendOpportunity(Change_Request__c changeReqobj)
    {
        QuoteModel qmodels;
        String amendedQuoteId= '';
        if(String.isNotBlank(changeReqobj.Opportunity__c)&& String.isNotBlank(changeReqobj.Id) && (String.isNotBlank(changeReqobj.Contract__c) || String.isNotBlank(changeReqobj.Opportunity__r.Main_Contract__c)) )
        {
            string contractId = String.isNotBlank(changeReqobj.Contract__c)?changeReqobj.Contract__c :changeReqobj.Opportunity__r.Main_Contract__c;
            
            String qmodelJson = SBQQ.ServiceRouter.load('SBQQ.ContractManipulationAPI.ContractAmender',contractId, null);
            qmodels = (QuoteModel)System.JSON.deserialize(qmodelJson,QuoteModel.class);  
            amendedQuoteId =  qmodels.record.Id;
            cls_amendContract.updateAmendOpptyAndQuote(changeReqobj.Opportunity__c,amendedQuoteId,'','');

            Change_Request__c  changeObj = new Change_Request__c(Id=changeReqobj.Id,Amended_Quote_Id__c=amendedQuoteId,Amended_Opportunity__c=qmodels.record.SBQQ__Opportunity2__c,Current_Processing_Step__c= 'Step 1');

            updateChangeRequest(changeObj);
            
        }
        return amendedQuoteId;
    }

    /**
    * @description -   to get order ids for change request
    * @param    changeReqobj  sObect And Field API
    * @return  get Set Set<Id>
    */
    public static Set<Id> getOrderIds(Change_Request__c changeReqobj) 
    { 
        Set<Id> orderIds = new Set<Id>();
        List<Order> lstOrders = new List<Order>();
        if(changeReqobj.Order_IDs__c == null){
            lstOrders = [SELECT Id FROM Order WHERE OpportunityId=:changeReqobj.Opportunity__c AND Status='Activated' ORDER BY CreatedDate desc ];            
        }
        else{ // [GECI-1394]
            lstOrders = [SELECT Id FROM Order WHERE Id in:changeReqobj.Order_IDs__c.split(',') AND Status='Activated' ORDER BY CreatedDate desc ];
        }
        for(Order ord : lstOrders){
            orderIds.add(ord.Id);
        }
        return orderIds;
    } 
    /**
     * @description -  Inner Wrapper Class QuoteModel
     */
    public class QuoteModel{
        /**
         * @description -  SBQQ__Quote__c record
         */
        public SBQQ__Quote__c record {get; set;}
    }

    /**
    * @description -   to create  API Synchronization Transactions
    * @param amendmentRequests  Amendment Request Objects    
    * @param itemType  Amendment Request Type    
    * @param apiCallType  Amendment Request Call Type    
    * @return API Synchronization Transaction Id
    */
    @AuraEnabled
    public static string createAmendmentTransactionRequests(list<Change_Request__c> amendmentRequests, String itemType, String apiCallType)
    {        
        string apiTransId;
        if(!amendmentRequests.isEmpty())
        {
            CreateApiSyncRecords.ApiSyncRecordsWrapper obj = new CreateApiSyncRecords.ApiSyncRecordsWrapper();
            obj.Type = 'Update';
            obj.startedFrom = 'Amendment Request';
            obj.requestType = GlobalConstants.ASYNCHRONOUS; 
            obj.thirdPartyERPSystem = null;
            obj.itemType = itemType; 
            obj.apiCallType = apiCallType;
            obj.listSObject = amendmentRequests;
            obj.transactionStatus = GlobalConstants.QUEUED;
            obj.itemStatus = GlobalConstants.QUEUED; // pause till API ready
            apiTransId = CreateApiSyncRecords.insertAllAPISyncItem(obj);
        }
        return apiTransId;
    }

    /**
    * @description -   to get All Invoices & Credit notes for a opportunity
    * @param opportnityId  Opportunity Id
    * @return list of all posted invoices & Credit Notes
    */
    @AuraEnabled
    public static string getAllInvoicesAndCreditNotes(string opportnityId)
    {
        List<blng__Invoice__c> invList = new List<blng__Invoice__c>([SELECT Id,Name,blng__TotalAmount__c,blng__DueDate__c,ERP_Reference__c,blng__InvoiceStatus__c,blng__InvoiceDate__c FROM blng__Invoice__c WHERE blng__InvoiceStatus__c ='Posted' AND blng__Order__r.OpportunityId =: opportnityId WITH SECURITY_ENFORCED ORDER BY LastModifiedDate desc]);
		//GECI-2037
       // List<blng__CreditNote__c> creditNoteList = new List<blng__CreditNote__c>([SELECT Id,Name,blng__TotalAmount__c,blng__CreditNoteDate__c,ERPReference__c,blng__Status__c,blng__RelatedInvoice__r.blng__DueDate__c,blng__RelatedInvoice__r.blng__InvoiceDate__c FROM blng__CreditNote__c WHERE blng__Status__c ='Posted' AND blng__RelatedInvoice__r.blng__Order__r.OpportunityId =: opportnityId WITH SECURITY_ENFORCED ORDER BY LastModifiedDate desc ]);

        map<string,Object> dataObj = new map<string,object>();
        dataObj.put('Invoices',invList);
       // dataObj.put('CreditNotes',creditNoteList);

        return JSON.serialize(dataObj);
    }
    /**
    * @description -   to get All Invoices from Change Request
    * @param changeReqobj  CR 
    * @return list of all invoices
    */
    @AuraEnabled
    public static string getAllInvoices(Change_Request__c changeReqobj)
    {
        Set<Id> orderIds = getOrderIds(changeReqobj);

        List<blng__Invoice__c> invList = new List<blng__Invoice__c>([SELECT Id,Name,blng__TotalAmount__c,blng__DueDate__c,ERP_Reference__c,blng__InvoiceStatus__c,blng__InvoiceDate__c FROM blng__Invoice__c WHERE blng__InvoiceStatus__c NOT In('Cancelled','Rebilled') AND Id In(SELECT  blng__Invoice__c FROM blng__InvoiceLine__c WHERE blng__OrderProduct__r.OrderId in :orderIds) WITH SECURITY_ENFORCED ORDER BY blng__InvoiceDate__c desc,CreatedDate desc]);

        map<string,Object> dataObj = new map<string,object>();
        dataObj.put('Invoices',invList);

        return JSON.serialize(dataObj);
    }
    /**
    * @description -   to complete Amnedment ,Flag out opp & Create Api Items
    * @param changeReq  Opportunity Id 
    * @return Status
    */
    @AuraEnabled
    public static string completeAmendmentProcess(Change_Request__c changeReq)
    {
        string status = 'Processing';
        string apiTrnsId01;string apiTrnsId02='Processing';
        string erpRefNos;
        Savepoint sp = Database.setSavepoint();
        try{
            integer totalPendingAmendmentRequest = Database.countQuery('Select count() from Change_Request__c where Data_Synced__c = false And Change_Request_Status__c != \'Rejected\' And Opportunity__c = \''+String.escapeSingleQuotes(changeReq.Opportunity__c)+'\' AND Id not IN (\''+String.escapeSingleQuotes(changeReq.Id)+'\')');

            list<Change_Request__c> amendmentRequests = new list<Change_Request__c>();
            amendmentRequests.add(changeReq);

            // Create API Trans for Amendment Requests
            CreateApiSyncRecords.ApiSyncRecordsWrapper obj0 = new CreateApiSyncRecords.ApiSyncRecordsWrapper();
            obj0.Type = 'Update';
            obj0.startedFrom = 'Amendment Request';
            obj0.requestType = GlobalConstants.ASYNCHRONOUS; 
            obj0.thirdPartyERPSystem = null;
            obj0.itemType = amendWithNoDataSyncMAP.containsKey(changeReq.Type_of_Change__c) ? amendWithNoDataSyncMAP.get(changeReq.Type_of_Change__c) : GlobalConstants.AMENDED_DATA_SYNC; 
            obj0.apiCallType = 'POST';
            obj0.listSObject = amendmentRequests;
            obj0.addAmendmentCompleteApiItem = !amendWithNoDataSyncMAP.containsKey(changeReq.Type_of_Change__c);
            obj0.transactionStatus = GlobalConstants.QUEUED;
            obj0.itemStatus = GlobalConstants.QUEUED; // pause till API ready
            apiTrnsId01 =  CreateApiSyncRecords.insertAllAPISyncItem(obj0);
            //changes
            List<Opportunity> oppList = [SELECT Id FROM Opportunity WHERE Id =:changeReq.Opportunity__c WITH SECURITY_ENFORCED];
            if(amendWithClosedLostOppCR.contains(changeReq.Type_of_Change__c)){
                CreateApiSyncRecords.ApiSyncRecordsWrapper objopp = new CreateApiSyncRecords.ApiSyncRecordsWrapper();
                objopp.Type = 'Update';
                objopp.startedFrom = 'Opportunity';
                objopp.requestType = GlobalConstants.ASYNCHRONOUS; 
                objopp.thirdPartyERPSystem = null;
                objopp.itemType = GlobalConstants.OPPORTUNITY_CLOSED_LOST; 
                objopp.apiCallType = 'POST';
                objopp.listSObject = oppList;
                objopp.addAmendmentCompleteApiItem = false;
                objopp.transactionStatus = GlobalConstants.QUEUED;
                objopp.itemStatus = GlobalConstants.QUEUED; // pause till API ready
                apiTrnsId01 =  CreateApiSyncRecords.insertAllAPISyncItem(objopp);
            }
        
            System.debug(logginglevel.DEBUG,'ERP Nos --> '+changeReq.ERP_Ref_Numbers__c);
            if(string.isNotBlank(changeReq.ERP_Ref_Numbers__c)
            && string.isNotBlank(changeReq.Type_of_Change__c)
            && amendTypeOrderHubAPITransMap.containsKey(changeReq.Type_of_Change__c))
            {
                erpRefNos = changeReq.ERP_Ref_Numbers__c;
                // Create API Trans for Amendment Credit Note & Invoices
                CreateApiSyncRecords.ApiSyncRecordsWrapper obj1 = new CreateApiSyncRecords.ApiSyncRecordsWrapper();
                obj1.Type = 'Update';
                obj1.startedFrom = 'Amendment Request';
                obj1.requestType = GlobalConstants.ASYNCHRONOUS; 
                obj1.thirdPartyERPSystem = GlobalConstants.ORACLE;
                obj1.itemType = amendTypeOrderHubAPITransMap.get(changeReq.Type_of_Change__c); 
                obj1.apiCallType = 'POST';
                obj1.listSObject = amendmentRequests;            
                obj1.transactionStatus = GlobalConstants.QUEUED;
                obj1.itemStatus = GlobalConstants.QUEUED; // pause till API ready
                apiTrnsId02 = CreateApiSyncRecords.insertAllAPISyncItem(obj1);

                // Update Amend Data on Invoice
                setAmendDataOnINV(erpRefNos);
            }

            if(Schema.sObjectType.Opportunity.isUpdateable() && String.isNotBlank(changeReq.Opportunity__c))
            {
                Opportunity opp = new Opportunity(Id=changeReq.Opportunity__c);
                if(amendWithClosedLostOppCR.contains(changeReq.Type_of_Change__c))
                {
                    opp.StageName = 'Cancelled';
                    Update opp;
                }else if(totalPendingAmendmentRequest < 1 )
                {
                    opp.Status__c='Awaiting Payment';
                    Update opp;
                }                                
            }

            Change_Request__c changeReqObj = new Change_Request__c(Id=changeReq.Id,Data_Synced__c=true,ERP_Ref_Numbers__c=erpRefNos,Change_Request_Status__c='Completed');
            update changeReqObj;
            status = 'Success';
            System.debug(logginglevel.DEBUG,'completeAmendmentProcess status--> '+status +' Trans ' +apiTrnsId01+';'+apiTrnsId02);
            if(String.isBlank(apiTrnsId01) || String.isBlank(apiTrnsId02))
            {Database.rollback(sp);status = 'Error';}
        }
        catch(exception e){
            System.debug(logginglevel.DEBUG,'Error in completeAmendmentProcess --> '+e.getMessage() +' At Line' + e.getLineNumber());System.debug(logginglevel.DEBUG,e.getStackTraceString());
            Database.rollback(sp);status = 'Error';
        }
        return status;
    }
    /**
    * @description  This method is used get IOM Amendment Category Details    
    * @return  List IOM Amendment Category Details
    */
    @AuraEnabled( cacheable=true )  
    public static List < IOM_Amendment_Category_Detail__mdt > fetchIOMAmdCatDetails() 
    {        
        return [ SELECT Id, IOM_Description__c,MasterLabel,IOM_New_Label__c FROM IOM_Amendment_Category_Detail__mdt WITH SECURITY_ENFORCED];
    }

    /**
    * @description -   to Update Invoice Data After Amedment Complete
    * @param erpNos  INVOICE ERP Ref Numbers from SAP
    */
    public static void setAmendDataOnINV(string erpNos)
    {
        List<String> invERPNos = String.isNotBlank(erpNos) ? erpNos.split(',') : new List<String>();
        List<blng__Invoice__c> invListToUpdate = new List<blng__Invoice__c>();
        for(blng__Invoice__c inv : [SELECT Id,PO_Number__c,Tax_Registration__c,blng__Order__c,blng__Order__r.Account_Tax_Number__c,blng__Order__r.PoNumber FROM blng__Invoice__c WHERE ERP_Reference__c in : invERPNos WITH SECURITY_ENFORCED])
        {
            inv.PO_Number__c        = inv.blng__Order__r.PoNumber;
            inv.Tax_Registration__c = inv.blng__Order__r.Account_Tax_Number__c;

            invListToUpdate.add(inv);
            //invListToUpdate.add(new blng__Invoice__c())
        }
        if(!invListToUpdate.isEmpty() && Schema.sObjectType.blng__Invoice__c.isUpdateable())
        {
            Update invListToUpdate;
        }
    }
    
}