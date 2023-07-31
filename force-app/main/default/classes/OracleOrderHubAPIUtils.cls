/**
* File         :   OracleOrderHubAPIUtils 
* Project      :   Order & Billing Plateform [OBP-341]
* Created Date :   01st Oct 2021
* Created By   :   Girikon(Ashish)
* Test Class   :   OracleOrderHubAPIUtils_Test (100%)
* ******************************************************************************************************
* @description : contain the logic that takes invoice/Credit Note Data to Oracle ORDER HUB Database 
********************************************************************************************************
* Modification log :
* 1. 20 Dec 2021 - Girikon(Suresh) [IOM-531]  - Updated code to Update ERP_Sync_Status__c
* 2. 16 Aug 2022 - Girikon(Ashish) [IE-10]    - Added Method for payments POST to OrderHub
* 3. 15 May 2023 - Girikon(Ashish) [GECI-916]  - Amendment process Changes to Allow Multiple Amendments for Order Hub
*/
public with sharing class OracleOrderHubAPIUtils 
{
    private static final String INVOICE_PUSH = 'Push Invoice';
    private static final String PAYMENT_PUSH = 'Payment Invoice';
    private static final String CREDIT_NOTE_PUSH = 'Push Crdit Note';
    private static final String ERROR_CODE = 'ERROR_ORDER_HUB_SYNC';
    private static final String ORACLE_DOCUMENT_SYNC = 'Oracle_Document_Sync';
    private static final String ORACLE_PAYMENT_SYNC = 'Oracle_Payment_Sync';
    private static final String ERP_SYNC_STATUS = 'Sync Required';

     /**
    * @description  map Amendment type & Order Hub request APi Item Type 
    */
    private static Map<String,String> eventTypeOrderHubAPITransMap = new Map<String,String>{        
        'Re-Print for PO number change' => 'document_amend',
        'Re-Print for Contact Details Change' => 'contact_amend',
        'Re-Print for Account Details Change' => 'account_amend',
        'Re-Print for Ship To Account Details Change' => 'account_amend',
        'Re-Print for Bill To Account Details Change' => 'account_amend'
    };
   /**
    * @description   This method is used for Sending  Documents(Invoice/Credit Note) to OrderHub
    * @param  accSyncObj API Synchronization Item
    * @return  String Status 
    */
    public static String syncDocuments2OrderHub(API_Synchronization_Item__c accSyncObj) 
    {
        API_Synchronization_Item__c itemObj = new API_Synchronization_Item__c(Id=accSyncObj.Id);
        String syncType = getSyncType(accSyncObj);
        String calloutStatus = GlobalConstants.PROCESSING;
        Id sObjectId = syncType == INVOICE_PUSH ? accSyncObj.Invoice__c : (syncType == CREDIT_NOTE_PUSH ? accSyncObj.Credit_Note__c:'');

        API_Detail__mdt mtAPIDetails = APISynchronizationHelper.getAPIDetails(ORACLE_DOCUMENT_SYNC, GlobalConstants.ORACLE);

        if(!isDupicate(accSyncObj, syncType)) // Check for dupliacte Record  [GECI-1175]
        {
            String payload = syncType == INVOICE_PUSH ? OrderHubAPIWrapper.getOrderHubInvoicePayload(accSyncObj.Invoice__c): (syncType == CREDIT_NOTE_PUSH ? OrderHubAPIWrapper.getOrderHubCreditNotePayload(accSyncObj.Credit_Note__c) :'');                
        
            //String payload = mockPaylaodJSON;
            HttpResponse res = callOrderHub(mtAPIDetails, payload,'');

            // If valid Response 
            if((res.getStatusCode() == 200 || res.getStatusCode() == 202)&& String.isNotBlank(res.getBody()))
            {
                string resBody =  res.getBody().normalizeSpace();
                
                OrderHubAPIWrapper.Response osRes = (OrderHubAPIWrapper.Response) System.JSON.deserialize(resBody, OrderHubAPIWrapper.Response.class);

                /** UPDATE sObbject */
                updateSyncStatus(sObjectId,syncType,osRes.meta);

                if(osRes.meta.status == GlobalConstants.SUCCESS)
                {                
                    calloutStatus = GlobalConstants.SUCCESS;
                    itemObj.Status__c= GlobalConstants.COMPLETED;
                    itemObj.Error_Message__c= GlobalConstants.BLANK_STRING;
                }else{ // 202/200 + Error  // Error Response  
                    calloutStatus = GlobalConstants.ERROR;
                    itemObj.Status__c= GlobalConstants.ERROR;
                    itemObj.Error_Message__c= osRes.meta.message;                                         
                }
            }else{
                calloutStatus = GlobalConstants.ERROR;
                // Error             
                itemObj.Status__c       = GlobalConstants.ERROR;
                itemObj.Error_Message__c= APISynchronizationHelper.getValueFromjson(res.getbody(),GlobalConstants.ERROR);

                updateSyncStatus(sObjectId,syncType,null);
            }
            itemObj.API_Call_Type__c    = mtAPIDetails.API_Method__c;
            itemObj.Response_Code__c    = String.valueOf(res.getStatusCode());
            itemObj.Request_Body__c     = payload;
            itemObj.Response_Body__c    = res.getbody().normalizeSpace();
        }else{ // Duplicate Error [GECI-1175]
            calloutStatus = GlobalConstants.ERROR;               
            itemObj.Status__c       = GlobalConstants.ERROR;
            itemObj.Error_Message__c= (syncType == CREDIT_NOTE_PUSH ? Label.Duplicate_Credit_Note_Error_Msg:'Duplicate Invoice');
            OrderHubAPIWrapper.Cls_Meta meta = new OrderHubAPIWrapper.Cls_Meta();
            meta.status = GlobalConstants.ERROR; meta.message = itemObj.Error_Message__c;
            updateSyncStatus(sObjectId,syncType,meta);
        }
        APISynchronizationHelper.updateSyncItemStatus(itemObj);

        return calloutStatus;
    }

    /**
    * @description This method to Send Payment Transaction (Invoices) to OrderHub [IE-10]
    * @param accSyncObj API Synchronization Item
    * @return calloutStatus String Status 
    */
    public static String syncPaymentTransaction2OrderHub(API_Synchronization_Item__c accSyncObj) 
    {
        API_Synchronization_Item__c itemObj = new API_Synchronization_Item__c(Id=accSyncObj.Id);
        String calloutStatus = GlobalConstants.PROCESSING;
        API_Detail__mdt mtAPIDetails = APISynchronizationHelper.getAPIDetails(ORACLE_PAYMENT_SYNC, GlobalConstants.ORACLE);

        String syncType = getSyncType(accSyncObj);
        Id invId =  syncType == INVOICE_PUSH ?accSyncObj.Invoice__c:accSyncObj.Credit_Note__r.blng__RelatedInvoice__c;
        String paymentType =  syncType == CREDIT_NOTE_PUSH ?'refund':'payment';
        String payload =  OrderHubAPIWrapper.getPaymentTransactionsPayload(invId,paymentType);
        
        //String payload = mockPaylaodJSON;
        HttpResponse res = callOrderHub(mtAPIDetails, payload,'');

        // If valid Response 
        if((res.getStatusCode() == 200 || res.getStatusCode() == 202)&& String.isNotBlank(res.getBody()))
        {
            string resBody =  res.getBody().normalizeSpace();
            
            OrderHubAPIWrapper.Response osRes = (OrderHubAPIWrapper.Response) System.JSON.deserialize(resBody, OrderHubAPIWrapper.Response.class);    
            updateSyncStatus(accSyncObj.Invoice__c,PAYMENT_PUSH,osRes.meta); 
            if(osRes.meta.status == GlobalConstants.SUCCESS)
            {
                calloutStatus = GlobalConstants.SUCCESS;
                itemObj.Status__c= GlobalConstants.COMPLETED;
                itemObj.Error_Message__c= GlobalConstants.BLANK_STRING;            
            }else{ // 202/200 + Error  // Error Response  
                calloutStatus = GlobalConstants.ERROR;                              
                itemObj.Status__c= GlobalConstants.ERROR;
                itemObj.Error_Message__c= osRes.meta.message;
            }
        }else{
            calloutStatus = GlobalConstants.ERROR;
            // Error             
            itemObj.Status__c       = GlobalConstants.ERROR;
            itemObj.Error_Message__c= APISynchronizationHelper.getValueFromjson(res.getbody(),GlobalConstants.ERROR);
        }
        itemObj.API_Call_Type__c    = mtAPIDetails.API_Method__c;
        itemObj.Response_Code__c    = String.valueOf(res.getStatusCode());
        itemObj.Request_Body__c     = payload;
        itemObj.Response_Body__c    = res.getbody().normalizeSpace();
        APISynchronizationHelper.updateSyncItemStatus(itemObj);

        return calloutStatus;
    }

    /**
    * @description  This method is used for Set Sync Status Error/Success
    * @param  sObjectId sId of Invoice Or Credit Note
    * @param  syncType  Sync type  Push Invoice/Push Credit Note
    * @param  meta  request Meta Body     
    */
    private static void updateSyncStatus(Id sObjectId,String syncType,OrderHubAPIWrapper.Cls_Meta meta)
    {
        list<blng__ErrorLog__c> errorLines = New list<blng__ErrorLog__c>();
        String status = GlobalConstants.ERROR;
        String message;
        if(meta !=null)
        {
            status = meta.status;
            message = meta.message;
            if(meta.detailedMessage != null)
            {
                for(OrderHubAPIWrapper.Cls_Errors error :meta.detailedMessage.errors )
                {
                    blng__ErrorLog__c errorLine = new blng__ErrorLog__c();                    
                    errorLine.Name  = 'ERROR : '+error.documentId ;
                    errorLine.blng__ErrorOrigin__c  = GlobalConstants.ORACLE;
                    errorLine.blng__FullErrorLog__c  = error.message;
                    errorLine.blng__ErrorCode__c  = ERROR_CODE;
                    errorLine.blng__Invoice__c = syncType == INVOICE_PUSH ?sObjectId :null;
                    errorLine.Credit_Note__c = syncType == CREDIT_NOTE_PUSH ? sObjectId :null;
                    errorLines.add(errorLine);
                }
            }
        }
        if(syncType == INVOICE_PUSH && Schema.sObjectType.blng__Invoice__c.isUpdateable()) 
        {
            blng__Invoice__c invoiceObj = New blng__Invoice__c(Id=sObjectId,Order_Hub_Sync_Status__c=status);
            update invoiceObj;
        }
        else if(syncType == CREDIT_NOTE_PUSH && Schema.sObjectType.blng__CreditNote__c.isUpdateable())
        {
            blng__CreditNote__c creditNoteObj = New blng__CreditNote__c(Id=sObjectId,Order_Hub_Sync_Status__c=status);
            if(status == GlobalConstants.ERROR){creditNoteObj.ERPSync_Status__c = status;creditNoteObj.Error_Message__c=message;}
            update creditNoteObj;
        }
       /*else if(syncType == PAYMENT_PUSH && Schema.sObjectType.Payment_Transaction__c.isUpdateable())
        {
            List<Payment_Transaction__c> listPaymentTrans = new List<Payment_Transaction__c>();
            for(Payment_Transaction__c payTrs : [SELECT Id,ERP_Sync_Status__c FROM Payment_Transaction__c WHERE Invoice__c =:sObjectId WITH SECURITY_ENFORCED])
            {
                payTrs.ERP_Sync_Status__c = status != GlobalConstants.ERROR?'Synced':'Error';
                listPaymentTrans.add(payTrs);
            }
            update listPaymentTrans;
        }*/

        if (!errorLines.isEmpty() && Schema.sObjectType.blng__ErrorLog__c.isCreateable())
        {
            insert errorLines;
        }
    }

    /**
    * @description   This method is used for updating Data in Order Hub after the amendment Process
    * @param  accSyncObj API Synchronization Item
    * @return  String Status 
    */
    public static String syncAfterAmendmentData2OrderHub(API_Synchronization_Item__c accSyncObj) 
    {
        API_Synchronization_Item__c itemObj = new API_Synchronization_Item__c(Id=accSyncObj.Id);        
        String calloutStatus = GlobalConstants.PROCESSING;
        API_Detail__mdt mtAPIDetails = APISynchronizationHelper.getAPIDetails(ORACLE_DOCUMENT_SYNC, GlobalConstants.ORACLE);

        // String payload = syncType == INVOICE_PUSH ? OrderHubAPIWrapper.getAfterAmendmentOracleInvoicePayload(accSyncObj): (syncType == CREDIT_NOTE_PUSH ? OrderHubAPIWrapper.getAfterAmendmentOracleCreditNotePayload(accSyncObj) :'');

        String payload = OrderHubAPIWrapper.getAfterAmendmentOraclePayload(accSyncObj); 
        // String payload = OrderHubAPIWrapper.getAfterAmendmentOraclePayload2(accSyncObj); //[GECI-916]
                
        //String payload = mockPaylaodJSON;
        String eventType = eventTypeOrderHubAPITransMap.containsKey(accSyncObj.Type__c)?eventTypeOrderHubAPITransMap.get(accSyncObj.Type__c):'';
        //String endpointSufix = '/events?eventType='+eventType+'&sourceSystem=IOM';

        String endpointSufix = '/events?eventType=full_amend&sourceSystem=IOM'; //[GECI-916]

        HttpResponse res = callOrderHub(mtAPIDetails, payload,endpointSufix);

        // If valid Response 
        if((res.getStatusCode() == 200 || res.getStatusCode() == 202)&& String.isNotBlank(res.getBody()))
        {
            itemObj.Status__c= GlobalConstants.COMPLETED;
            itemObj.Error_Message__c= GlobalConstants.BLANK_STRING;   
            /*
            string resBody =  res.getBody().normalizeSpace();
            
            OrderHubAPIWrapper.Response osRes = (OrderHubAPIWrapper.Response) System.JSON.deserialize(resBody, OrderHubAPIWrapper.Response.class);
            if(osRes.meta.status == GlobalConstants.SUCCESS)
            {                
                calloutStatus = GlobalConstants.SUCCESS;
                itemObj.Status__c= GlobalConstants.COMPLETED;
                itemObj.Error_Message__c= GlobalConstants.BLANK_STRING;                
            }else{ // 202/200 + Error  // Error Response  
                calloutStatus = GlobalConstants.ERROR;                              
                itemObj.Status__c= GlobalConstants.ERROR;
                itemObj.Error_Message__c= osRes.meta.message;                                          
            }*/
        }else{
            calloutStatus = GlobalConstants.ERROR;
            // Error             
            itemObj.Status__c       = GlobalConstants.ERROR;
            itemObj.Error_Message__c= APISynchronizationHelper.getValueFromjson(res.getbody(),GlobalConstants.ERROR);
            
        }
        itemObj.API_Call_Type__c    = mtAPIDetails.API_Method__c;
        itemObj.Response_Code__c    = String.valueOf(res.getStatusCode());
        itemObj.Request_Body__c     = payload;
        itemObj.Response_Body__c    = res.getbody().normalizeSpace();
        APISynchronizationHelper.updateSyncItemStatus(itemObj);

        return calloutStatus;
    }

    /**
    * @description  This method is used for ORDER_HUB Callout
    * @param  mtAPIDetails API Detail
    * @param  jsonBody request Body  
    * @param  endpointSufix 
    * @return response HttpResponse response from ORDER_HUB System
    */
    private static HttpResponse callOrderHub(API_Detail__mdt mtAPIDetails, String jsonBody,String endpointSufix)
    {
        // endPointURL = removeUnUsedPrameters(endPointURL);
        String endPointURL = mtAPIDetails.API_End_Point__c+endpointSufix;
        endPointURL = endPointURL.replaceall(' ', '%20');
        String method = mtAPIDetails.API_Method__c;
        HttpRequest request = new HttpRequest();
        List<String> headers = (String.isNotBlank(mtAPIDetails.Headers__c)?mtAPIDetails.Headers__c.split(','):new List<String>());
        for(String header : headers){
            request.setHeader(header.split('=').get(0), header.split('=').get(1));
        }
        System.debug(LoggingLevel.DEBUG, endPointURL);
        request.setEndpoint('callout:orderHub'+endPointURL);
        request.setTimeout(60000);
        request.setHeader('Content-Type', 'application/json');        
        request.setMethod(method);
        if(method == 'PUT' || method == 'POST')
        {
            jsonBody = (String.isBlank(jsonBody)?'':jsonBody);
            request.setBody(jsonBody);
        }
        Http http = new Http();
        HttpResponse response = http.send(request);
        System.debug(LoggingLevel.DEBUG,'HttpResponse Code -> '+response.getStatusCode()+' : ' +response.getStatus());
        System.debug(LoggingLevel.DEBUG,'HttpResponse Reponse -> '+response.getBody());
        return response;
    }

    /**
    * @description   This method is used for Calculating sObject Sync Type Object
    * @param  accSyncObj API Synchronization Item
    * @return  String Push type Invoice/Credit Note
    */
    private static string getSyncType(API_Synchronization_Item__c accSyncObj)
    {
        return (String.isNotBlank(accSyncObj.Invoice__c) && String.isBlank(accSyncObj.Credit_Note__c))?INVOICE_PUSH: (String.isBlank(accSyncObj.Invoice__c) && String.isNotBlank(accSyncObj.Credit_Note__c))?CREDIT_NOTE_PUSH:'';
    }

    /**
    * @description   This method is check for duplicate Credit Notes [GECI-1174]
    * @param  accSyncObj API Synchronization Item
    * @param  syncType Type of Document Sync to OrderHub
    * @return  Boolean true for duplicate & false for default
    */
    private static Boolean isDupicate(API_Synchronization_Item__c accSyncObj, String syncType)
    {
        Boolean duplicateflag = false; 
        if(syncType == CREDIT_NOTE_PUSH){
            Decimal allCreditNoteSubTotal = 0;
            Integer syncedCreditNoteCount = 0;   
            for(blng__CreditNote__c crdNt : [SELECT Id,blng__Subtotal__c,Order_Hub_Sync_Status__c FROM blng__CreditNote__c WHERE Order_Hub_Sync_Status__c = 'success' AND Id !=: accSyncObj.Credit_Note__c AND blng__RelatedInvoice__c =:accSyncObj.Credit_Note__r.blng__RelatedInvoice__c]){
                allCreditNoteSubTotal = allCreditNoteSubTotal+crdNt.blng__Subtotal__c;
                syncedCreditNoteCount++;
            }

            if((accSyncObj.Credit_Note__r.blng__RelatedInvoice__r.blng__Subtotal__c == allCreditNoteSubTotal && accSyncObj.Credit_Note__r.blng__RelatedInvoice__r.blng__Subtotal__c > 0) || (accSyncObj.Credit_Note__r.blng__RelatedInvoice__r.blng__Subtotal__c == 0 && (syncedCreditNoteCount > 0 || accSyncObj.Credit_Note__r.blng__Subtotal__c > 0))){
                duplicateflag = true;
            }
        }        
        return duplicateflag;
    }
}