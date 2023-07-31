/**
* Created By       :   Girikon(Ashish) [GECI-236]
* Created On       :   05 Dec 2022
* @description     :   Allow to create and get change request detail,update change request,execulete FCR(full cancel & rebill) and unhold all order line items for billing.                      
* Test Class       :   AmendmentUtils_Test(95%)
***********************************************************************************************
* Modification Log :
* 1. [GECI-570]     - Girikon
* 2. [GECI-1098]    - Girikon(Ashish)-  13 march 2023, Added Logic update Account tax number on order
* 3. [GECI-927]     - Girikon(Ashish)-  09 march 2023, For Account & Address Amendments include the translated fields
* 4. [GECI-916]     - Girikon(Ashish)  15 May 2023, Amendment process Changes to Allow Multiple Amendments for Order Hub
*/
public with sharing class AmendmentUtils2 
{
    /**
    * @description   - to update AmendData
    * @param dataObjJSON   change request
    * @return processing status
    */
    @AuraEnabled
    public static String updateChangeRequest(String dataObjJSON)
    {
        String status= 'Processing';
        System.debug(LoggingLevel.Debug, 'dataObjJSON -> '+dataObjJSON);        

        AmendedDataWrapper dataObj = (AmendedDataWrapper) JSON.deserialize(dataObjJSON, AmendedDataWrapper.class);
        
        Savepoint sp = Database.setSavepoint();		
        try {
            System.debug(LoggingLevel.Debug, 'dataObj.amendmentObj.Amendment_Type__c'+dataObj.amendmentObj.Amendment_Type__c);
            String [] amedmentTypes = dataObj.amendmentObj.Amendment_Type__c.split(';');
            // Bill To Account Update
            if(dataObj.billToAccountObj !=null && String.isNotBlank(dataObj.billToAccountObj.Id) && Schema.sObjectType.Account.isUpdateable())
            {
                update dataObj.billToAccountObj;
            }        
            // Ship To Account Update
            if(dataObj.shipToAccountObj !=null && String.isNotBlank(dataObj.shipToAccountObj.Id) && Schema.sObjectType.Account.isUpdateable())
            {
                update dataObj.shipToAccountObj;
            }
            // Billing Contact
            if(dataObj.billToContactObj !=null && String.isNotBlank(dataObj.billToContactObj.Id) && Schema.sObjectType.Contact.isUpdateable())
            {
                update dataObj.billToContactObj;
            }
            // Account tax Number Upsert
            if(amedmentTypes.contains('VAT Registration Number Change'))
            {                
                upsert dataObj.accTaxObj;
            }
            
            // Translations - [GECI-927]
            // Bill To Account Translations
            if(dataObj.billToAccountTransObj !=null && String.isNotBlank(dataObj.billToAccountTransObj.Id) && Schema.sObjectType.Translated_Record__c.isUpdateable())
            {
                update dataObj.billToAccountTransObj;
            }
            // Bill To Contact Translations
            if(dataObj.shipToAccountTransObj !=null && String.isNotBlank(dataObj.shipToAccountTransObj.Id) && Schema.sObjectType.Translated_Record__c.isUpdateable())
            {
                update dataObj.shipToAccountTransObj;
            }
            // Bill To Contact Translations
            // if(dataObj.shipToContactTransObj !=null && String.isNotBlank(dataObj.shipToContactTransObj.Id) && Schema.sObjectType.Contact.isUpdateable())
            // {
            //     update dataObj.shipToContactTransObj;
            // }

            if(dataObj.orderItemsObj != null && !dataObj.orderItemsObj.isEmpty())
            {   
                updateOrderItemsDatesAmount(dataObj.orderItemsObj);
            }
            // Opportunity/Order update Or [GECI-1098]
            if((dataObj.opportunityObj !=null && String.isNotBlank(dataObj.opportunityObj.Id)) || amedmentTypes.contains('VAT Registration Number Change'))
            {
                Boolean isOrderChanged;
                // Set the Data on Order Obj
                List<Order> oppOrders = new List<Order>();
                for(Order ord:[SELECT Id,PoNumber,blng__BillingAccount__c,BillToContactId,Account_Tax_Number__c FROM Order WHERE OpportunityId=:dataObj.amendmentObj.Opportunity__c WITH SECURITY_ENFORCED ORDER BY CreatedDate desc ])
                {
                    isOrderChanged = false;
                    if(amedmentTypes.contains('PO number change')){
                        ord.PoNumber = dataObj.opportunityObj.PO_Number__c;
                        isOrderChanged = true;
                    }
                    if(amedmentTypes.contains('Bill To Account Change')){
                        ord.blng__BillingAccount__c = dataObj.opportunityObj.Bill_To_Account__c;
                        isOrderChanged = true;
                    }
                    if(amedmentTypes.contains('Ship To Account Change')){
                        ord.Ship_To_Account__c = dataObj.opportunityObj.Ship_To_Account__c;
                        isOrderChanged = true;
                    }
                    
                    if(amedmentTypes.contains('Update Bill To Contact')){
                        ord.BillToContactId = dataObj.opportunityObj.Billing_Contact__c;
                        isOrderChanged = true;
                    }
                    if(amedmentTypes.contains('VAT Registration Number Change') && ord.Account_Tax_Number__c != dataObj.accTaxObj.Id){ // [GECI-1098]}                    
                        ord.Account_Tax_Number__c = dataObj.accTaxObj.Id;
                        isOrderChanged = true;
                    }
                    if(isOrderChanged){
                        oppOrders.add(ord);
                    }
                }

                // Update Opp
                if(dataObj.opportunityObj.Id != null && Schema.sObjectType.Opportunity.isUpdateable())
                {
                    update dataObj.opportunityObj;
                }
                
                // Update Orders
                if(!oppOrders.isEmpty() && Schema.sObjectType.Order.isUpdateable())
                {
                    update oppOrders;
                }
            }

            // Update Order Products -- if required .
        
            if(String.isNotBlank(dataObj.amendmentObj.Id))
            {
                update dataObj.amendmentObj;
            }
            status = 'Success';
        }
        catch (Exception e){
            status = 'Error - '+e.getMessage(); Database.rollback(sp);
            System.debug(logginglevel.DEBUG,'Error Message - '+e.getMessage()+' At '+e.getLineNumber()+' : '+e.getStackTraceString());
        }
        return status;
    }


    private static void updateOrderItemsDatesAmount(List<OrderItem> orderItems){

        Map<Id,OrderItem> oldorderItems = new Map<Id,OrderItem>([SELECT Id,OrderId,Order.Status,SBQQ__QuoteLine__c FROM OrderItem where Id in :orderItems]);
        List<OrderItem> toUpdateOLI =  new List<OrderItem>();

        List<OrderItem> oliWithoutQLI =  new List<OrderItem>();        
        List<OrderItem> oliWithQLI =  new List<OrderItem>();

        for(OrderItem oli :orderItems)
        {
            OrderItem oliObj = new OrderItem(Id=oli.Id);
            System.debug(LoggingLevel.Debug, oliObj);
            if(oldorderItems.get(oli.Id).Order.Status == 'Activated')
            {
                toUpdateOLI.add(oli); // update Dates - Start/End Date
                // if(oli.EndDate != null ){
                //     oliObj.EndDate  = oli.EndDate;
                // }else{
                //     oliObj.ServiceDate  = oli.ServiceDate;
                // }
            }else{
                oliWithoutQLI.add(new OrderItem(Id=oli.Id,SBQQ__QuoteLine__c=null)); // ReSet the QLI Refrence
                toUpdateOLI.add(oli);   // update Dates & unit price
                oliWithQLI.add(new OrderItem(Id=oli.Id,SBQQ__QuoteLine__c=oldorderItems.get(oli.Id).SBQQ__QuoteLine__c)); //set the QLI value again.
            }
        }

        if(!oliWithoutQLI.isEmpty() && Schema.sObjectType.OrderItem.isUpdateable()){
            update oliWithoutQLI;
        }

        if(!toUpdateOLI.isEmpty() && Schema.sObjectType.OrderItem.isUpdateable()){
            update toUpdateOLI;
        }

        if(!oliWithQLI.isEmpty() && Schema.sObjectType.OrderItem.isUpdateable()){
            update oliWithQLI;
        }

        // Update Dates & Amount to the OLI
        List<SBQQ__QuoteLine__c> listQuoteLines = new List<SBQQ__QuoteLine__c>();
        for(OrderItem oi : [SELECT Id,ServiceDate,EndDate,UnitPrice,SBQQ__QuoteLine__c FROM OrderItem WHERE Id in :orderItems WITH SECURITY_ENFORCED])
        {        
            // System.debug(' OL - -- '+oi.ServiceDate+' & '+oi.EndDate+' --> '+oldOrderProductsMap.get(oi.Id).ServiceDate);
           
            SBQQ__QuoteLine__c qli      = new SBQQ__QuoteLine__c(Id = oi.SBQQ__QuoteLine__c);
            qli.SBQQ__StartDate__c      = oi.ServiceDate;
            qli.SBQQ__EndDate__c        = oi.EndDate;
            qli.SBQQ__ListPrice__c      = oi.UnitPrice;
            qli.Target_Price__c         = oi.UnitPrice;

            listQuoteLines.add(qli);            
        }
        if(!listQuoteLines.isEmpty() && Schema.sObjectType.SBQQ__QuoteLine__c.isUpdateable())
        {
            Update listQuoteLines;
        }
    }

    /**
    * @description -  to unhold all order line items for billing and requeue tax calculation
    * @param   amendmentOBJ   Amendment request
    */
    @AuraEnabled
    public static void executeReBillOrder(Change_Request__c amendmentOBJ)
    {
        Set<Id> orderIds = AmendmentUtils.getOrderIds(amendmentOBJ);
        // to handle 1 Order per Opportunity
        List<Order> listOfOrderUpdate = new List<Order>();        
        for(Order odr : [SELECT Id,Override_Tax_Status__c,Tax_Status__c,SBQQ__Quote__c,Edition__c,OpportunityId,blng__BillingAccount__c,Status,SBQQ__PaymentTerm__c,Payment_Term_Reason__c FROM Order WHERE Id In:orderIds WITH SECURITY_ENFORCED]){
            odr.Override_Tax_Status__c=true;
            odr.Tax_Status__c='Tax Required';
            // need to fix for multiple Orders 
            CancelAndRebilPostedInvoicesFCR_Trig.inverseCancelInvoicesForOrder(odr);
            listOfOrderUpdate.add(odr);
        }
        // listOfOrderUpdate = PaymentTermOnOrder_Trig.setPaymentTermOnOrder(listOfOrderUpdate, null,Date.today()); // GECI-2008
        if(Schema.sObjectType.Order.isUpdateable() && !listOfOrderUpdate.isEmpty()){
            update listOfOrderUpdate;
        }

        //amendmentOBJ.Current_Processing_Step__c = 'Step 2';
        //AmendmentUtils.updateChangeRequest(amendmentOBJ);        
    }


    /**
    * @description -   to complete Amnedment ,Flag out opp & Create Api Items
    * @param amendmentOBJ  Amendment OBJ 
    * @param externalerp  external erp
    * @return Status
    */
    @AuraEnabled
    public static String completeAmendmentProcess(Change_Request__c amendmentOBJ, String externalerp)
    {
        String status = 'Processing';
        String apiTrnsId01;String apiTrnsId02='Processing';
        String erpRefNos;
        List<String> typeOfChanges = amendmentOBJ.Amendment_Type__c.split(';');
    
        Savepoint sp = Database.setSavepoint();
        try{
            integer totalPendingAmendmentRequest = Database.countQuery('SELECT count() FROM Change_Request__c where Data_Synced__c = false AND Change_Request_Status__c != \'Rejected\' AND Opportunity__c = \''+String.escapeSingleQuotes(amendmentOBJ.Opportunity__c)+'\' AND Id not IN (\''+String.escapeSingleQuotes(amendmentOBJ.Id)+'\')');

            List<Change_Request__c> amendmentRequests = new List<Change_Request__c>();
            amendmentRequests.add(amendmentOBJ);

            Boolean isCRMDataSyncRequired = isCRMSyncRequired(typeOfChanges);

            // Create API Trans for CRM Sync
            CreateApiSyncRecords.ApiSyncRecordsWrapper obj0 = new CreateApiSyncRecords.ApiSyncRecordsWrapper();
            obj0.Type = 'Update';
            obj0.startedFrom = 'Amendment Request';
            obj0.requestType = GlobalConstants.ASYNCHRONOUS; 
            obj0.thirdPartyERPSystem = null;
            obj0.itemType = isCRMDataSyncRequired ? GlobalConstants.AMENDED_DATA_SYNC : GlobalConstants.CHANGE_REQUEST_COMPLETED; 
            obj0.apiCallType = 'POST';
            obj0.listSObject = amendmentRequests;
            obj0.addAmendmentCompleteApiItem = isCRMDataSyncRequired;
            obj0.transactionStatus = GlobalConstants.QUEUED;
            obj0.itemStatus = GlobalConstants.QUEUED; 
            apiTrnsId01 =  CreateApiSyncRecords.insertAllAPISyncItem(obj0);
            //changes
            List<Opportunity> oppList = [SELECT Id FROM Opportunity where Id =: amendmentOBJ.Opportunity__c];
            if(typeOfChanges.contains('Cancellation') && String.isBlank(amendmentOBJ.Invoice_To_Cancel__c)){
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
                objopp.itemStatus = GlobalConstants.QUEUED; 
                apiTrnsId01 =  CreateApiSyncRecords.insertAllAPISyncItem(objopp);
            }
            
            /*amendmentRequests.clear();
            System.debug(logginglevel.DEBUG,'ERP Nos --> '+amendmentOBJ.ERP_Ref_Numbers__c);
            for(String typeOfChange:typeOfChanges)
            {
                if(AmendmentUtils.amendTypeOrderHubAPITransMap.containsKey(typeOfChange))
                {
                    Change_Request__c amdReq = new Change_Request__c(Id=amendmentOBJ.Id);
                    amdReq.Comments__c = AmendmentUtils.amendTypeOrderHubAPITransMap.get(typeOfChange);
                    amendmentRequests.add(amdReq);
                }
            }*/
            

            if(string.isNotBlank(amendmentOBJ.ERP_Ref_Numbers__c) && !amendmentRequests.isEmpty())
            {
                erpRefNos = amendmentOBJ.ERP_Ref_Numbers__c;
                // Create API Trans for Amendment Credit Note & Invoices
                CreateApiSyncRecords.ApiSyncRecordsWrapper obj1 = new CreateApiSyncRecords.ApiSyncRecordsWrapper();
                obj1.Type = 'Update';
                obj1.startedFrom = 'Amendment Request';
                obj1.requestType = GlobalConstants.ASYNCHRONOUS; 
                obj1.thirdPartyERPSystem = externalerp;                 
                obj1.apiCallType = 'POST';
                obj1.listSObject = amendmentRequests;
                obj1.itemType = GlobalConstants.AMENDED_DATA_SYNC_OH; //[GECI-916]
                obj1.transactionStatus = GlobalConstants.QUEUED;
                obj1.itemStatus = GlobalConstants.QUEUED; // pause till API ready
                apiTrnsId02 = CreateApiSyncRecords.insertAllAPISyncItem(obj1);

                // Update Amend Data on Invoice
                AmendmentUtils.setAmendDataOnINV(erpRefNos);
            }
            
            if(Schema.sObjectType.Opportunity.isUpdateable() && String.isNotBlank(amendmentOBJ.Opportunity__c))
            {
                Opportunity opp = new Opportunity(Id=amendmentOBJ.Opportunity__c);
                if(typeOfChanges.contains('Cancellation') && String.isBlank(amendmentOBJ.Invoice_To_Cancel__c))
                {
                    opp.StageName = 'Cancelled';
                    Update opp;
                }else if(totalPendingAmendmentRequest < 1 )
                {
                    opp.Status__c='Awaiting Payment';
                    Update opp;
                }                                
            }

            Change_Request__c changeReqObj = new Change_Request__c(Id=amendmentOBJ.Id,Data_Synced__c=true,ERP_Ref_Numbers__c=erpRefNos);
            if(Schema.sObjectType.Change_Request__c.isUpdateable()){
                update changeReqObj;
            }

            status = 'Success';
            System.debug(logginglevel.DEBUG,'completeAmendmentProcess status--> '+status +' Trans ' +apiTrnsId01+';'+apiTrnsId02);
            if(String.isBlank(apiTrnsId01) || String.isBlank(apiTrnsId02))
            {Database.rollback(sp);status = 'Error';}
        }
        catch(exception e){
            System.debug(logginglevel.DEBUG,'Error in completeAmendmentProcess --> '+e.getMessage() +' At Line' + e.getLineNumber());System.debug(logginglevel.DEBUG,e.getStackTraceString());
            Database.rollback(sp);status = 'Error';HandleAllCustomException.logException(e,amendmentOBJ.Id,'AmendmentUtils');
        }
        return status;
    }

    private static Boolean isCRMSyncRequired(List<String> typeOfChanges)
    {
        Boolean isRequired = false;
        for(String typeOfChange : typeOfChanges)
        {
            if(!AmendmentUtils.amendWithNoDataSyncMAP.containsKey(typeOfChange))
            {
                isRequired = true;
                break;
            }
        }
        return isRequired;
    }

    /**
    * @description -   to complete Amnedment ,Flag out opp & Create Api Items
    * @param invIds  invoice ids for cancellation
    * @return aysnc job id
    */
    @AuraEnabled
    public static String cancleInvoies(List<Id> invIds)
    {
        CancelRebillInvoicesBatch criObj = new CancelRebillInvoicesBatch(new Set<Id>(invIds),false);
        String asyncJobId = Database.executeBatch(criObj,1);
        return asyncJobId;
    }

    /**** Google Address API****/
    /**
    * @description : Auto suggestion Web Service 
    * @param searchKey Search text
    * @return String autocomplete json
    */
    @AuraEnabled
    public static String getAddressAutoComplete(String searchKey) {

        String url = IOM_GlobalConstantsData.getValue('IOM_Google_Autocomplete_API').replaceAll('<key>',IOM_GlobalConstantsData.getValue('IOM_Google_Api_Key')).replaceAll('<searchkey>',EncodingUtil.urlEncode(searchKey, 'UTF-8'));

        return getGoogleHttpResponse(url);
    }
    
    /**
    * @description Place Details Web Service 
    * @param placeId Unique Place Id
    * @return String address json
    */ 
    @AuraEnabled
    public static String getAddressDetails(String placeId) {

        String url = IOM_GlobalConstantsData.getValue('IOM_Google_Place_API').replaceAll('<key>',IOM_GlobalConstantsData.getValue('IOM_Google_Api_Key')).replaceAll('<placeid>',placeId);

        return getGoogleHttpResponse(url);
    }
    /**
    * @description GECI-570 
    * @param fields opportunity fields to get
    * @param oppId Opportunity Id
    * @return Opportunity data
    */ 
    @AuraEnabled
    public static Opportunity getOpportunityRecord(String fields ,String oppId)
    {
        String quote='\'';        
        String finalQuery='SELECT '+String.escapeSingleQuotes(fields)+' FROM Opportunity WHERE Id ='+quote +String.escapeSingleQuotes(oppId)+quote+' LIMIT 1';
        return  Database.query(finalQuery);
    }

    /**
    * @description -  GECI-776
    * @param oppId Opportunity ID
    * @return List of Orders
    */ 
    @AuraEnabled
    public static List<Order> getAllOrders(String oppId)
    {        
        return  [SELECT Id,OrderNumber,Status,(SELECT Id,OrderId,OrderItemNumber,ServiceDate,EndDate,UnitPrice,Product2Id,Product2.Name,SBQQ__BillingFrequency__c,blng__OverrideNextBillingDate__c FROM OrderItems) FROM Order WHERE OpportunityId =:oppId WITH SECURITY_ENFORCED ORDER BY OrderNumber];//Added for GECI-1353
    }

    /**
    * @description -  GECI-776
    * @param oppId Opportunity ID
    * @return Uncalculated Flag
    */ 
    @AuraEnabled
    public static Boolean isQuoteCalculationInProgress(String oppId)
    {        
        return  [SELECT Id,SBQQ__PrimaryQuote__r.SBQQ__Uncalculated__c FROM opportunity WHERE Id =:oppId WITH SECURITY_ENFORCED LIMIT 1].SBQQ__PrimaryQuote__r.SBQQ__Uncalculated__c;
    }
    

    /**
    * @description Common Utility method for making call out
    * @param url API End Point
    * @return String response
    */    
    private static String getGoogleHttpResponse(String url)
    {
        try{            
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(url);
            request.setMethod('GET');
            HttpResponse response = http.send(request);
            // System.debug(response.getBody());
            return response.getBody();
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());}
    } 

    /**
    * @description AmendedDataWrapper class
    */ 
    public class AmendedDataWrapper{

        @AuraEnabled public Change_Request__c amendmentObj;

        @AuraEnabled public opportunity opportunityObj;

        @AuraEnabled public Account billToAccountObj;

        @AuraEnabled public Account shipToAccountObj;

        @AuraEnabled public Contact billToContactObj;

        @AuraEnabled public Account_Tax_Number__c accTaxObj;

        // @AuraEnabled public Order orderItemObj;

        @AuraEnabled public List<OrderItem> orderItemsObj;

        @AuraEnabled public Translated_Record__c billToAccountTransObj;

        @AuraEnabled public Translated_Record__c shipToAccountTransObj;

        @AuraEnabled public Translated_Record__c shipToContactTransObj;
        
    }

}