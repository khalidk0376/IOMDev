/**
* File			: 	MuleSoftCRMCalloutUtils
* Project       :   Informa Order Management [IOM-521]
* Created By	: 	Girikon(Ashish)
* Created Date	: 	02nd Feb 2022
* Test Class    :   MuleSoftCRMCalloutUtils_Test(100%)
* **************************************************************************************
* @description : Utility Class for Sending Data to MuleSoft & further carry data to CRMS
****************************************************************************************
* Modification log :
* 1. Girikon (Ashish) [IOM-775] 23 Feb 2022 : Amendment/Opportunity Data Update to MuleSoft
* 2. Girikon (Ansh)   [IOM-448] 23 Feb 2022 : Amendment/Opportunity Data Update to MuleSoft
* 3. Girikon (Ashish) [IOM-572] 03 Feb 2022 : Amendment Resquest Data Update to MuleSoft
* 4.Girikon(Ashish) [GECI-916] 15 May 2023, Amendment process Changes to Allow Multiple Amendments for Order Hub
* 4.Girikon(Ashish) [GECI-1793] 05 June 2023, Send ACR Id if Source contact Id blank
*/
public with sharing class MuleSoftCRMCalloutUtils
{
    private static final String CREDIT_NOTE_PUSH = 'Push Crdit Note';
    private static final String MULESOFT_CRM = 'MuleSoft CRM';
    private static final String HOLD_ACCOUNTING_API = 'MuleSoft_Accounting_Status_Sync';
    private static final String AMENDMENT_STATUS_API = 'MuleSoft_Amendment_Status_Sync';
    private static final String AMENDMENT_DATA_API = 'MuleSoft_Amend_Data';
    private static final String MULESOFT_ERP_NO_SYNC = 'MuleSoft_ERP_No_Sync';
    private static final String MILESTONE = 'Milestone_';
    private static final String PERCENT = '_Percent__c';
    private static final String AMOUNT = '_Amount__c';
    private static final String DELIVERY_DATE = '_Delivery_Date__c';

    /**
    * @description   This method is used for Updating Accounting Credit Status In CRM
    * @param  apiSyncObj API Synchronization Item
    * @return  String Status
    */
    public static String updateAccountCreditStatus(API_Synchronization_Item__c apiSyncObj) 
    { 
        API_Synchronization_Item__c itemObj = new API_Synchronization_Item__c(Id=apiSyncObj.Id);        
        String calloutStatus = GlobalConstants.PROCESSING;
        API_Detail__mdt mtAPIDetails = APISynchronizationHelper.getAPIDetails(HOLD_ACCOUNTING_API,MULESOFT_CRM);

        string erpRefAccNo = String.isNotBlank(apiSyncObj.Account__r.Oracle_Number__c)?apiSyncObj.Account__r.Oracle_Number__c:String.isNotBlank(apiSyncObj.Account__r.SAP_Number__c)?apiSyncObj.Account__r.SAP_Number__c:'';
        String payload =  '{"accountId": "'+apiSyncObj.Account__r.IM_Account_No__c+'","CreditStatus": "'+apiSyncObj.Account__r.Accounting_Credit_Hold__c+'","CRMOrg":"'+apiSyncObj.Account__r.Legacy_CRM_Instance__c+'","erpAccountNo":"'+erpRefAccNo+'"}';
        //String payload = mockPaylaodJSON;
        
        if(apiSyncObj.Account__r.Legacy_CRM_Instance__c != null && String.isNotBlank(apiSyncObj.Account__r.Legacy_CRM_Instance__c)){
            HttpResponse res = callMuleSoft(mtAPIDetails, payload);
            // If valid Response 
            if((res.getStatusCode() == 200 || res.getStatusCode() == 202)&& String.isNotBlank(res.getBody()))
            {            
                calloutStatus = GlobalConstants.SUCCESS;
                itemObj.Status__c= GlobalConstants.COMPLETED;
                itemObj.Error_Message__c= GlobalConstants.BLANK_STRING;   
            }else{
                calloutStatus = GlobalConstants.ERROR;
                // Error             
                itemObj.Status__c       = GlobalConstants.ERROR;
                itemObj.Error_Message__c= APISynchronizationHelper.getValueFromjson(res.getbody(),GlobalConstants.ERROR);
            }
            itemObj.Response_Code__c    = String.valueOf(res.getStatusCode());
            itemObj.Response_Body__c    = res.getbody().normalizeSpace();
        }else{
            calloutStatus = GlobalConstants.ERROR;
            // Error             
            itemObj.Status__c       = GlobalConstants.ERROR;
            itemObj.Error_Message__c= 'Legacy CRM on Account is Blank';
        }
        itemObj.API_Call_Type__c    = mtAPIDetails.API_Method__c;
        itemObj.Request_Body__c     = payload;
        APISynchronizationHelper.updateSyncItemStatus(itemObj);

        return calloutStatus;
    }

        /**
    * @description   This method is used for Syncing Documents(Invoice/Credit Note) With CRM
    * @param  apiSyncObj API Synchronization Item
    * @return  String Status
    */
    public static String syncERPDocumnetERPNo(API_Synchronization_Item__c apiSyncObj) 
    { 
        API_Synchronization_Item__c itemObj = new API_Synchronization_Item__c(Id=apiSyncObj.Id);        
        String calloutStatus = GlobalConstants.PROCESSING;
        API_Detail__mdt mtAPIDetails = APISynchronizationHelper.getAPIDetails(MULESOFT_ERP_NO_SYNC,MULESOFT_CRM);
        
        String payload =  '{"IOMDocumentNumber":"'+apiSyncObj.Invoice__r.IM_Invoice_No__c+'","ERPRefNumber":"'+apiSyncObj.Invoice__r.ERP_Reference__c+'","IOMOpportunityId":"'+apiSyncObj.Invoice__r.blng__Order__r.Opportunity.IM_Opportunity_No__c+'","CRMOrg":"'+apiSyncObj.Invoice__r.blng__Order__r.Opportunity.Legacy_CRM_Instance__c+'"}';

        if(apiSyncObj.API_Synchronization_Transaction__r.Started_From__c == 'Credit Note'){
            payload =  '{"IOMDocumentNumber":"'+apiSyncObj.Credit_Note__r.IM_Credit_Note_No__c+'","ERPRefNumber":"'+apiSyncObj.Credit_Note__r.ERPReference__c+'","IOMOpportunityId":"'+apiSyncObj.Credit_Note__r.blng__RelatedInvoice__r.blng__Order__r.Opportunity.IM_Opportunity_No__c+'","CRMOrg":"'+apiSyncObj.Credit_Note__r.blng__RelatedInvoice__r.blng__Order__r.Opportunity.Legacy_CRM_Instance__c+'"}';
        }
        payload = payload.replaceAll(':"null"',':""');
        HttpResponse res = callMuleSoft(mtAPIDetails,payload );

        // If valid Response 
        if((res.getStatusCode() == 200 || res.getStatusCode() == 202)&& String.isNotBlank(res.getBody()))
        {            
            calloutStatus = GlobalConstants.SUCCESS;
            itemObj.Status__c= GlobalConstants.COMPLETED;
            itemObj.Error_Message__c= GlobalConstants.BLANK_STRING;   
        }else{
            calloutStatus = GlobalConstants.ERROR;
            // Error             
            itemObj.Status__c       = GlobalConstants.ERROR;
            itemObj.Error_Message__c= APISynchronizationHelper.getValueFromjson(res.getbody(),GlobalConstants.ERROR);
        }
        itemObj.Response_Code__c    = String.valueOf(res.getStatusCode());
        itemObj.Response_Body__c    = res.getbody().normalizeSpace();
       
        itemObj.API_Call_Type__c    = mtAPIDetails.API_Method__c;
        itemObj.Request_Body__c     = payload;
        APISynchronizationHelper.updateSyncItemStatus(itemObj);

        return calloutStatus;
    }
    
    /**
    * @description   This method is used to Update StageName In CRM
    * @param  apiSyncObj API Synchronization Item
    * @return  String Status
    */
    public static String updateOppStageName(API_Synchronization_Item__c apiSyncObj) 
    { 
        API_Synchronization_Item__c itemObj = new API_Synchronization_Item__c(Id=apiSyncObj.Id);        
        String calloutStatus = GlobalConstants.PROCESSING;
        API_Detail__mdt mtAPIDetails = APISynchronizationHelper.getAPIDetails(AMENDMENT_DATA_API,MULESOFT_CRM);

        MuleSoftCRMWrapper crmDataWrap  = new MuleSoftCRMWrapper();
        crmDataWrap.IOMOpportunityNumber    =   apiSyncObj.Opportunity__r.IM_Opportunity_No__c;
        crmDataWrap.OpportunityStageName  =   apiSyncObj.Opportunity__r.StageName;
        crmDataWrap.CRMOrg              = apiSyncObj.Opportunity__r.Legacy_CRM_Instance__c;
        //String payload = getAfterAmendmentDataPayload(apiSyncObj);

        String payload =  JSON.serialize(crmDataWrap,true);
        
        HttpResponse res = callMuleSoft(mtAPIDetails, payload);

        // If valid Response 
        if((res.getStatusCode() == 200 || res.getStatusCode() == 202)&& String.isNotBlank(res.getBody()))
        {            
            calloutStatus = GlobalConstants.SUCCESS;
            itemObj.Status__c= GlobalConstants.COMPLETED;
            itemObj.Error_Message__c= GlobalConstants.BLANK_STRING;
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
    * @description   This method is used for Updating Opportunity Rejection Notes in CRM
    * @param  apiSyncObj API Synchronization Item
    * @return  String Status
    */
    public static String updateOpportunityRejectionNotes(API_Synchronization_Item__c apiSyncObj) 
    { 
        API_Synchronization_Item__c itemObj = new API_Synchronization_Item__c(Id=apiSyncObj.Id);        
        String calloutStatus = GlobalConstants.PROCESSING;
        API_Detail__mdt mtAPIDetails = APISynchronizationHelper.getAPIDetails(AMENDMENT_DATA_API,MULESOFT_CRM);

        MuleSoftCRMWrapper crmDataWrap  = new MuleSoftCRMWrapper();
        crmDataWrap.CRMOrg                  =   apiSyncObj.Opportunity__r.Legacy_CRM_Instance__c;
        crmDataWrap.IOMOpportunityNumber    =   apiSyncObj.Opportunity__r.IM_Opportunity_No__c;
        crmDataWrap.Opportunity_RejectionNotes  =   apiSyncObj.Opportunity__r.Rejection_Notes__c;
        crmDataWrap.Opportunity_RejectionReason =   apiSyncObj.Opportunity__r.Rejection_Reason__c;

        String payload =  JSON.serialize(crmDataWrap);
        
        HttpResponse res = callMuleSoft(mtAPIDetails, payload);

        // If valid Response 
        if((res.getStatusCode() == 200 || res.getStatusCode() == 202)&& String.isNotBlank(res.getBody()))
        {            
            calloutStatus = GlobalConstants.SUCCESS;
            itemObj.Status__c= GlobalConstants.COMPLETED;
            itemObj.Error_Message__c= GlobalConstants.BLANK_STRING;
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
    * @description   This method is used for Updating Amendment Request Status back to CRM
    * @param  apiSyncObj API Synchronization Item
    * @return  String Status
    */
    public static String updateAmendmentRequestStatus(API_Synchronization_Item__c apiSyncObj) 
    { 
        API_Synchronization_Item__c itemObj = new API_Synchronization_Item__c(Id=apiSyncObj.Id);        
        String calloutStatus = GlobalConstants.PROCESSING;
        API_Detail__mdt mtAPIDetails = APISynchronizationHelper.getAPIDetails(AMENDMENT_STATUS_API,MULESOFT_CRM);

        MuleSoftCRMWrapper.AmendmentRequest amdWrap = new MuleSoftCRMWrapper.AmendmentRequest();
        amdWrap.ChangeRequestNo     = apiSyncObj.Amendment_Request__r.Name;
        amdWrap.AmendmentNumber     = apiSyncObj.Amendment_Request__r.CRM_Change_Request_No__c;
        amdWrap.ChangeRequestStatus = apiSyncObj.Amendment_Request__r.Change_Request_Status__c;
        amdWrap.ActionedBy          = apiSyncObj.Amendment_Request__r.Actioned_By__r.Name;
        amdWrap.ActionedDateTime    = (apiSyncObj.Amendment_Request__r.Actioned_Date_Time__c!=null?String.valueOf(apiSyncObj.Amendment_Request__r.Actioned_Date_Time__c.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'.000Z\'')):'');
        amdWrap.IOMOpportunityId    = apiSyncObj.Amendment_Request__r.IM_Opportunity_No__c;
        amdWrap.CRMOrg              = apiSyncObj.Amendment_Request__r.Legacy_CRM_Instance__c;
        amdWrap.ActionedBy			= apiSyncObj.Amendment_Request__r.LastModifiedBy.Name;
        if(apiSyncObj.Type__c == GlobalConstants.AMENDMENT_REQUEST_APPROVED_REJECTED){
            amdWrap.SalesOperationsComments = apiSyncObj.Amendment_Request__r.Sales_Operations_Comments__c;
        }
        String payload = JSON.serialize(amdWrap,false).replaceAll(':null',':""');
        
        HttpResponse res = callMuleSoft(mtAPIDetails,payload);

        // If valid Response 
        if((res.getStatusCode() == 200 || res.getStatusCode() == 202)&& String.isNotBlank(res.getBody()))
        {                       
            calloutStatus = GlobalConstants.SUCCESS;
            itemObj.Status__c= GlobalConstants.COMPLETED;
            itemObj.Error_Message__c= GlobalConstants.BLANK_STRING;
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
    * @description  This method is used for CRM Mule Soft Callout
    * @param  mtAPIDetails
    * @param  jsonBody  request Body  
    * @return  HttpResponse response from CRM Mule Soft System
    */
    private static HttpResponse callMuleSoft(API_Detail__mdt mtAPIDetails, String jsonBody)
    {
        // endPointURL = removeUnUsedPrameters(endPointURL);
        String endPointURL = mtAPIDetails.API_End_Point__c.replaceall(' ', '%20');
        String method = mtAPIDetails.API_Method__c;
        HttpRequest request = new HttpRequest();
        List<String> headers = (String.isNotBlank(mtAPIDetails.Headers__c)?mtAPIDetails.Headers__c.split(','):new List<String>());
        for(String header : headers){
            request.setHeader(header.split('=').get(0), header.split('=').get(1));
        }
        System.debug(LoggingLevel.DEBUG,'Methord :- '+method+' URL - : '+endPointURL);
        request.setEndpoint('callout:CRM_MuleSoft'+endPointURL);
        request.setTimeout(60000);
        request.setHeader('Content-Type', 'application/json');
        request.setMethod(method);
        if(String.isNotBlank(method) && method != 'GET')
        {
            System.debug(LoggingLevel.DEBUG,'HttpResponse Request Body -> '+jsonBody);
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
    * @description   This method is used to Update StageName In CRM
    * @param  apiSyncObj API Synchronization Item
    * @return  String Status
    */
    public static String updatedataIOMtoCRM(API_Synchronization_Item__c apiSyncObj) 
    { 
        API_Synchronization_Item__c itemObj = new API_Synchronization_Item__c(Id=apiSyncObj.Id);        
        String calloutStatus = GlobalConstants.PROCESSING;
        API_Detail__mdt mtAPIDetails = APISynchronizationHelper.getAPIDetails(AMENDMENT_DATA_API,MULESOFT_CRM);

        String payload = getAfterAmendmentDataPayload(apiSyncObj);
        
        HttpResponse res = callMuleSoft(mtAPIDetails, payload);

        // If valid Response 
        if((res.getStatusCode() == 200 || res.getStatusCode() == 202)&& String.isNotBlank(res.getBody()))
        {            
            calloutStatus = GlobalConstants.SUCCESS;
            itemObj.Status__c= GlobalConstants.COMPLETED;
            itemObj.Error_Message__c= GlobalConstants.BLANK_STRING;
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
    * @description   This method is used to create payload for IOM to CRM after Amedment
    * @param  apiSyncObj API Synchronization Item
    * @return  String JSON Payload
    */
    private static string getAfterAmendmentDataPayload(API_Synchronization_Item__c apiSyncObj)
    {
        //Set<String> amedmentOppTypeStatus = new Set<String>{'Number of Impressions Amendment'};
        Boolean hasAmendmentOpp = String.isNotBlank(apiSyncObj.Amendment_Request__r.Amended_Opportunity__c);
        Id oppId = hasAmendmentOpp ? apiSyncObj.Amendment_Request__r.Amended_Opportunity__c:apiSyncObj.Amendment_Request__r.Opportunity__c;
        Map<String,object> customScheduleMap=new Map<String,object>();  
        List<String> amedmentTypes = apiSyncObj.Amendment_Request__r.Amendment_Type__c.split(';');

        string oppFields = 'Id,Master_Opportunity__r.IM_Opportunity_No__c,Payment_Schedule__c,IM_Opportunity_No__c,Account_Tax_Number__r.Tax_ID__c,PO_Number__c,StageName,Legacy_CRM_Instance__c,Account.Name,Account.IM_Account_No__c,';
        string  accShipFields = 'Account.Billing_Address_Line_2__c,Account.Billing_Address_Line_3__c,Account.ShippingCity,Account.ShippingCountry,Account.ShippingStreet,Account.ShippingStateCode,Account.ShippingPostalCode,';
        string  accBillFields = 'Account.BillingCity,Account.Credit_Status__c,Account.Oracle_Number__c,Account.SAP_Number__c,Account.BillingCountryCode,Account.BillingStreet,Account.BillingStateCode,Account.BillingPostalCode,';
        string billtoconFields = 'Billing_Contact__c,Billing_Contact__r.Account.Billing_Address_Line_2__c,Billing_Contact__r.Account.Billing_Address_Line_3__c,Billing_Contact__r.IM_Contact_No__c,Billing_Contact__r.MailingStreet,Billing_Contact__r.MailingPostalCode,Billing_Contact__r.MailingCity,Billing_Contact__r.MailingCountryCode,Billing_Contact__r.MailingStateCode,Billing_Contact__r.Salutation,Billing_Contact__r.Email,';
        billtoconFields += 'Billing_Contact__r.Account.ShippingCity,Billing_Contact__r.Account.BillingCountryCode,Billing_Contact__r.Account.ShippingCountryCode,Billing_Contact__r.Account.ShippingPostalCode,Billing_Contact__r.Account.Name,';
        billtoconFields += 'Billing_Contact__r.Account.BillingStateCode,Billing_Contact__r.Account.BillingPostalCode,Billing_Contact__r.Account.IM_Account_No__c,Billing_Contact__r.MobilePhone,Billing_Contact__r.AccountId,Billing_Contact__r.Account.ShippingStreet,';
        billtoconFields += 'Billing_Contact__r.Title,Billing_Contact__r.FirstName,Billing_Contact__r.Account.ShippingStateCode,Billing_Contact__r.LastName,Billing_Contact__r.Account.AccountNumber,Billing_Contact__r.Account.BillingStreet,Billing_Contact__r.Account.BillingCity,';
        string billtoaccFields = 'Bill_To_Account__c,Bill_To_Account__r.ShippingStateCode,Bill_To_Account__r.Name,Bill_To_Account__r.BillingPostalCode,Bill_To_Account__r.ShippingPostalCode,Bill_To_Account__r.BillingStreet, Bill_To_Account__r.BillingCity,';
        billtoaccFields += 'Bill_To_Account__r.Billing_Address_Line_2__c,Bill_To_Account__r.Billing_Address_Line_3__c,Bill_To_Account__r.BillingStateCode, Bill_To_Account__r.BillingCountryCode, Bill_To_Account__r.ShippingStreet, Bill_To_Account__r.ShippingCountryCode, Bill_To_Account__r.AccountNumber,Bill_To_Account__r.ShippingCity,Bill_To_Account__r.IM_Account_No__c,';
        string shiptoaccFields = 'Ship_To_Account__r.Billing_Address_Line_2__c,Ship_To_Account__r.Billing_Address_Line_3__c,Ship_To_Account__c,Ship_To_Account__r.ShippingCountryCode,Ship_To_Account__r.Oracle_Number__c,Ship_To_Account__r.SAP_Number__c,Ship_To_Account__r.BillingStateCode, Ship_To_Account__r.BillingCity,Ship_To_Account__r.ShippingPostalCode, Ship_To_Account__r.BillingStreet, Ship_To_Account__r.BillingPostalCode, ';
        shiptoaccFields += 'Ship_To_Account__r.AccountNumber, Ship_To_Account__r.ShippingStreet, Ship_To_Account__r.ShippingStateCode, Ship_To_Account__r.Name, Ship_To_Account__r.ShippingCity, Ship_To_Account__r.BillingCountryCode,Ship_To_Account__r.IM_Account_No__c,';
        String custombillingfields = 'Milestone_1_Amount__c,Milestone_1_Delivery_Date__c,Milestone_1_Percent__c,Milestone_10_Amount__c,Milestone_10_Delivery_Date__c,Milestone_10_Percent__c,Milestone_11_Amount__c,Milestone_11_Delivery_Date__c,Milestone_11_Percent__c,';
        custombillingfields += 'Total_No_of_payment__c,Milestone_12_Amount__c,Milestone_12_Delivery_Date__c,Milestone_12_Percent__c,Milestone_2_Amount__c,Milestone_2_Delivery_Date__c,Milestone_2_Percent__c,Milestone_3_Amount__c,Milestone_3_Delivery_Date__c,Milestone_3_Percent__c,';
        custombillingfields += 'Milestone_4_Amount__c,Milestone_4_Delivery_Date__c,Milestone_4_Percent__c,Milestone_5_Amount__c,Milestone_5_Delivery_Date__c,Milestone_5_Percent__c,Milestone_6_Amount__c,Milestone_6_Delivery_Date__c,Milestone_6_Percent__c,';
        custombillingfields += 'Milestone_7_Amount__c,Milestone_7_Delivery_Date__c,Milestone_7_Percent__c,Milestone_8_Amount__c,Milestone_8_Delivery_Date__c,Milestone_8_Percent__c,Milestone_9_Amount__c,Milestone_9_Delivery_Date__c,Milestone_9_Percent__c,';
        String productLinesQuery = '(SELECT Id,Name,ListPrice,TotalPrice,Quantity,Description,Product2.Name,SBQQ__QuoteLine__r.SBQQ__Quantity__c,SBQQ__QuoteLine__r.SBQQ__ListTotal__c,SBQQ__QuoteLine__r.SBQQ__NetTotal__c,SBQQ__QuoteLine__r.SBQQ__StartDate__c,SBQQ__QuoteLine__r.SBQQ__EndDate__c,Product2.IM_ProductCode__c,SBQQ__QuoteLine__r.Name,SBQQ__QuoteLine__r.CRM_OLI_Number__c FROM OpportunityLineItems Where Quantity > 0) ';
        
        String queryStr = 'Select '+oppFields+ accShipFields+accBillFields+billtoconFields+billtoaccFields+shiptoaccFields+custombillingfields+productLinesQuery+' From Opportunity Where Id =\''+String.escapeSingleQuotes(oppId)+'\'';
        opportunity oppObj = Database.query(queryStr);

        //get Translated Records [GECI-927]
        Map<Id,Translated_Record__c> maplatestTranslatedRecord = getTranslatedRecordMap(new Set<Id>{oppObj.Bill_To_Account__c,oppObj.Ship_To_Account__c});
        MuleSoftCRMWrapper crmDataWrap      = new MuleSoftCRMWrapper();
        crmDataWrap.IOMOpportunityNumber    =  !hasAmendmentOpp?oppObj.IM_Opportunity_No__c:oppObj.Master_Opportunity__r.IM_Opportunity_No__c;
        crmDataWrap.Amendment_IOMOpportunityNumber  =  !hasAmendmentOpp?'':oppObj.IM_Opportunity_No__c;
        crmDataWrap.CRMOrg                  = oppObj.Legacy_CRM_Instance__c;
        
            if(amedmentTypes.contains('Bill to Contact Details Change')||
                amedmentTypes.contains('Update Bill To Contact')||
                amedmentTypes.contains('Bill To Account Change'))
            {
                AccountContactRelation conACR = getAccountContactRelation(oppObj.Bill_To_Account__c,oppObj.Billing_Contact__c,oppObj.Legacy_CRM_Instance__c);

                crmDataWrap.BillingContact_MailingStreet = oppObj.Billing_Contact__r.MailingStreet;
                crmDataWrap.BillingContact_Salutation = oppObj.Billing_Contact__r.Salutation;
                crmDataWrap.BillingContact_MailingPostalCode = oppObj.Billing_Contact__r.MailingPostalCode;
                crmDataWrap.BillingContact_MailingCity = oppObj.Billing_Contact__r.MailingCity;
                // crmDataWrap.BillingContact_IOMNumber = oppObj.Billing_Contact__r.IM_Contact_No__c;
                crmDataWrap.BillingContact_IOMNumber = conACR.IM_Contact_No__c;//[GECI-763]
                crmDataWrap.BillingContact_ACRId = String.isBlank(conACR.Source_Contact_ID__c) ? String.valueOf(conACR.Id):''; //[GECI-1793]
                crmDataWrap.BillingContact_MailingState = oppObj.Billing_Contact__r.MailingStateCode;
                crmDataWrap.BillingContact_MailingCountry = oppObj.Billing_Contact__r.MailingCountryCode;
                crmDataWrap.BillingContact_MobilePhone = oppObj.Billing_Contact__r.MobilePhone;
                crmDataWrap.BillingContact_Email = oppObj.Billing_Contact__r.Email;
                crmDataWrap.BillingContact_Title = oppObj.Billing_Contact__r.Title;
                crmDataWrap.BillingContact_FirstName = oppObj.Billing_Contact__r.FirstName;
                crmDataWrap.BillingContact_AccountShippingState = oppObj.Bill_To_Account__r.ShippingStateCode;
                crmDataWrap.BillingContact_LastName = oppObj.Billing_Contact__r.LastName;
                crmDataWrap.BillingContact_AccountShippingPostalCode = oppObj.Bill_To_Account__r.ShippingPostalCode;
                crmDataWrap.BillingContact_AccountName = oppObj.Bill_To_Account__r.Name;
                crmDataWrap.BillingContact_AccountId = oppObj.Bill_To_Account__c;
                crmDataWrap.BillingContact_IOMAccountNumber = oppObj.Bill_To_Account__r.IM_Account_No__c;
                crmDataWrap.BillingContact_AccountBillingState = oppObj.Bill_To_Account__r.BillingStateCode;
                crmDataWrap.BillingContact_AccountBillingPostalCode = oppObj.Bill_To_Account__r.BillingPostalCode;
                crmDataWrap.BillingContact_AccountShippingStreet = oppObj.Bill_To_Account__r.ShippingStreet;
                crmDataWrap.BillingContact_AccountNumber = oppObj.Bill_To_Account__r.AccountNumber;
                crmDataWrap.BillingContact_AccountBillingStreet = oppObj.Bill_To_Account__r.BillingStreet;
                crmDataWrap.BillingContact_AccountBillingAddressLine2 = oppObj.Bill_To_Account__r.Billing_Address_Line_2__c;
	            crmDataWrap.BillingContact_AccountBillingAddressLine3 = oppObj.Bill_To_Account__r.Billing_Address_Line_3__c;
                crmDataWrap.BillingContact_AccountBillingCity = oppObj.Bill_To_Account__r.BillingCity;
                crmDataWrap.BillingContact_AccountShippingCity = oppObj.Bill_To_Account__r.ShippingCity;
                crmDataWrap.BillingContact_AccountBillingCountry = oppObj.Bill_To_Account__r.BillingCountryCode;
                crmDataWrap.BillingContact_AccountShippingCountry = oppObj.Bill_To_Account__r.ShippingCountryCode;
            }
            Map<String,Object> billToAccTransObj = new Map<String,Object>();

            if(amedmentTypes.contains('Account Name Change'))
            {
                crmDataWrap.AccountName = oppObj.Account.Name;
                crmDataWrap.IOMAccountNumber = oppObj.Account.IM_Account_No__c;
                crmDataWrap.BillingAccount_Name = oppObj.Bill_To_Account__r.Name;
                crmDataWrap.ShippingAccount_Name = oppObj.Ship_To_Account__r.Name;
                crmDataWrap.ShippingAccount_IOMNumber = oppObj.Ship_To_Account__r.IM_Account_No__c;
                crmDataWrap.BillingAccount_IOMNumber = oppObj.Bill_To_Account__r.IM_Account_No__c;

                if(maplatestTranslatedRecord.containsKey(oppObj.Bill_To_Account__c)){ // [GECI-927]
                    Translated_Record__c transObj = maplatestTranslatedRecord.get(oppObj.Bill_To_Account__c);                    
                    billToAccTransObj.put('TranslatedBillingAccountName', getObjectValue(transObj.Translated_Account_Name__c));
                }
            }

            if(amedmentTypes.contains('Shipping Address Change'))
            {
                crmDataWrap.ShippingAccount_IOMNumber = oppObj.Ship_To_Account__r.IM_Account_No__c;
                crmDataWrap.ShippingAccount_Name = oppObj.Ship_To_Account__r.Name;
                crmDataWrap.ShippingAccount_BillingState = oppObj.Ship_To_Account__r.BillingStateCode;
                crmDataWrap.ShippingAccount_BillingCity = oppObj.Ship_To_Account__r.BillingCity;
                crmDataWrap.ShippingAccount_BillingStreet = oppObj.Ship_To_Account__r.BillingStreet;
                crmDataWrap.ShippingAccount_BillingAddressLine2 = oppObj.Ship_To_Account__r.Billing_Address_Line_2__c;
	            crmDataWrap.ShippingAccount_BillingAddressLine3 = oppObj.Ship_To_Account__r.Billing_Address_Line_3__c;
                crmDataWrap.ShippingAccount_BillingPostalCode = oppObj.Ship_To_Account__r.BillingPostalCode;
                crmDataWrap.ShippingAccount_BillingCountry = oppObj.Ship_To_Account__r.BillingCountryCode;

                if(maplatestTranslatedRecord.containsKey(oppObj.Ship_To_Account__c)){ // [GECI-927]
                    Map<String,Object> shipToAccTransObj = new Map<String,Object>();
                    Translated_Record__c transObj = maplatestTranslatedRecord.get(oppObj.Ship_To_Account__c);                    
                    shipToAccTransObj.put('TranslatedShippingAddressLine1', getObjectValue(transObj.Translated_Billing_Address_Line_1__c));
                    shipToAccTransObj.put('TranslatedShippingAddressLine2', getObjectValue(transObj.Translated_Billing_Address_Line_2__c));
                    shipToAccTransObj.put('TranslatedShippingCity', getObjectValue(transObj.Translated_Billing_City__c));
                    
                    crmDataWrap.Translations.add(shipToAccTransObj);
                }
            }

            if(amedmentTypes.contains('Billing Address Change'))
            {
                crmDataWrap.BillingAccount_IOMNumber = oppObj.Bill_To_Account__r.IM_Account_No__c;
                crmDataWrap.BillingAccount_Name = oppObj.Bill_To_Account__r.Name;
                crmDataWrap.BillingAccount_BillingPostalCode = oppObj.Bill_To_Account__r.BillingPostalCode;               
                crmDataWrap.BillingAccount_BillingStreet = oppObj.Bill_To_Account__r.BillingStreet; 
                crmDataWrap.BillingAccount_BillingAddressLine2 =  oppObj.Bill_To_Account__r.Billing_Address_Line_2__c;
	            crmDataWrap.BillingAccount_BillingAddressLine3 =  oppObj.Bill_To_Account__r.Billing_Address_Line_3__c;
                crmDataWrap.BillingAccount_BillingCity = oppObj.Bill_To_Account__r.BillingCity;               
                crmDataWrap.BillingAccount_BillingState= oppObj.Bill_To_Account__r.BillingStateCode;
                crmDataWrap.BillingAccount_BillingCountry =oppObj.Bill_To_Account__r.BillingCountryCode;   

                if(maplatestTranslatedRecord.containsKey(oppObj.Bill_To_Account__c)){ // [GECI-927]
                    Translated_Record__c transObj = maplatestTranslatedRecord.get(oppObj.Bill_To_Account__c);                    
                    billToAccTransObj.put('TranslatedBillingAddressLine1', getObjectValue(transObj.Translated_Billing_Address_Line_1__c));
                    billToAccTransObj.put('TranslatedBillingAddressLine2', getObjectValue(transObj.Translated_Billing_Address_Line_2__c));
                    billToAccTransObj.put('TranslatedBillingCity', getObjectValue(transObj.Translated_Billing_City__c));
                }
            }

            if(!billToAccTransObj.isEmpty()){ // [GECI-927]
                crmDataWrap.Translations.add(billToAccTransObj);
            }

            if(amedmentTypes.contains('Bill To Account Change'))
            {                
                crmDataWrap.BillingAccount_IOMNumber = oppObj.Bill_To_Account__r.IM_Account_No__c; 
                crmDataWrap.BillingAccount_Name = oppObj.Bill_To_Account__r.Name;
                crmDataWrap.BillingAccount_BillingPostalCode = oppObj.Bill_To_Account__r.BillingPostalCode;
                crmDataWrap.BillingAccount_BillingStreet = oppObj.Bill_To_Account__r.BillingStreet; 
                crmDataWrap.BillingAccount_BillingAddressLine2 =  oppObj.Bill_To_Account__r.Billing_Address_Line_2__c;
	            crmDataWrap.BillingAccount_BillingAddressLine3 =  oppObj.Bill_To_Account__r.Billing_Address_Line_3__c;
                crmDataWrap.BillingAccount_BillingCity = oppObj.Bill_To_Account__r.BillingCity;
                crmDataWrap.BillingAccount_BillingState= oppObj.Bill_To_Account__r.BillingStateCode;
                crmDataWrap.BillingAccount_BillingCountry =oppObj.Bill_To_Account__r.BillingCountryCode;
                crmDataWrap.BillingAccount_ShippingStreet = oppObj.Bill_To_Account__r.ShippingStreet;
                crmDataWrap.BillingAccount_ShippingCity = oppObj.Bill_To_Account__r.BillingCity;
                crmDataWrap.BillingAccount_ShippingState = oppObj.Bill_To_Account__r.ShippingStateCode;
                crmDataWrap.BillingAccount_ShippingPostalCode = oppObj.Bill_To_Account__r.ShippingPostalCode;
                crmDataWrap.BillingAccount_ShippingCountry = oppObj.Bill_To_Account__r.ShippingCountryCode;
            }

            if(amedmentTypes.contains('Ship To Account Change'))
            {                
                crmDataWrap.ShippingAccount_IOMNumber = oppObj.Ship_To_Account__r.IM_Account_No__c;                
                crmDataWrap.ShippingAccount_Name = oppObj.Ship_To_Account__r.Name;
                crmDataWrap.ShippingAccount_ShippingCity = oppObj.Ship_To_Account__r.ShippingCity;
                crmDataWrap.ShippingAccount_ShippingStreet = oppObj.Ship_To_Account__r.ShippingStreet;
                crmDataWrap.ShippingAccount_ShippingPostalCode = oppObj.Ship_To_Account__r.ShippingPostalCode;
                crmDataWrap.ShippingAccount_ShippingCountry = oppObj.Ship_To_Account__r.ShippingCountryCode;
                crmDataWrap.ShippingAccount_BillingState = oppObj.Ship_To_Account__r.BillingStateCode;                
                crmDataWrap.ShippingAccount_BillingCity = oppObj.Ship_To_Account__r.BillingCity;
                crmDataWrap.ShippingAccount_BillingStreet = oppObj.Ship_To_Account__r.BillingStreet;
                crmDataWrap.ShippingAccount_BillingAddressLine2 = oppObj.Ship_To_Account__r.Billing_Address_Line_2__c;
	            crmDataWrap.ShippingAccount_BillingAddressLine3 = oppObj.Ship_To_Account__r.Billing_Address_Line_3__c;
                crmDataWrap.ShippingAccount_BillingPostalCode = oppObj.Ship_To_Account__r.BillingPostalCode;
                crmDataWrap.ShippingAccount_BillingCountry = oppObj.Ship_To_Account__r.BillingCountryCode;                
            }

            if(amedmentTypes.contains('VAT Registration Number Change'))
            {               
                Set<Id> setAccIds = new Set<Id>{oppObj.AccountId,oppObj.Bill_To_Account__c,oppObj.Ship_To_Account__c};
                Map<Id,Account_Tax_Number__c> maplatestAccountTaxnumber = getAccountTaxNumberMap(setAccIds);
                // Sold TO Account tax number
                crmDataWrap.VATRegistrationNumber = (String.isNotBlank(oppObj.AccountId) && maplatestAccountTaxnumber.containsKey(oppObj.AccountId))?maplatestAccountTaxnumber.get(oppObj.AccountId).Tax_ID__c:'';
                // Bill TO Account tax number
                crmDataWrap.BillingAccount_VATRegistrationNumber = (String.isNotBlank(oppObj.Bill_To_Account__c) && maplatestAccountTaxnumber.containsKey(oppObj.Bill_To_Account__c))?maplatestAccountTaxnumber.get(oppObj.Bill_To_Account__c).Tax_ID__c:'';
                // Ship TO Account tax number
                crmDataWrap.ShippingAccount_VATRegistrationNumber = (String.isNotBlank(oppObj.Ship_To_Account__c) && maplatestAccountTaxnumber.containsKey(oppObj.Ship_To_Account__c))?maplatestAccountTaxnumber.get(oppObj.Ship_To_Account__c).Tax_ID__c:'';
            }
            
            if(amedmentTypes.contains('PO number change'))
            {
                crmDataWrap.PO_Number =oppObj.PO_Number__c; //String.isNotBlank(oppObj.PO_Number__c)?oppObj.PO_Number__c:'';
            }
            if(amedmentTypes.contains('Billing Schedule Change'))
            {
                List<Object> milestoneList = new List<Object>();
                //crmDataWrap.PaymentSchedule = String.isNotBlank(oppObj.Payment_Schedule__c)?oppObj.Payment_Schedule__c:'';
                if(oppObj.Total_No_of_payment__c != null){
                    for(Integer i=0; i <oppObj.Total_No_of_payment__c;i++ ){
                        Integer fieldcount = i+1;
                        String paymentName = 'CustomBillingSchedule'+fieldcount;
                        Decimal amount = (Decimal)oppObj.get(MILESTONE+fieldcount+AMOUNT);
                        Decimal formattedAmount = amount.setScale(2);
                        Date milestoneDeliveryDate = (Date) oppObj.get(MILESTONE + fieldcount + DELIVERY_DATE);
                        DateTime milestoneDeliveryDateTime = DateTime.newInstance(milestoneDeliveryDate.year(), milestoneDeliveryDate.month(), milestoneDeliveryDate.day());
                        Decimal milestonePercent = (Decimal)oppObj.get(MILESTONE+fieldcount+PERCENT);
                        Decimal formattedPercent = milestonePercent.setScale(2);
                        customScheduleMap.put(paymentName,formattedPercent+','+milestoneDeliveryDateTime.format('MM/dd/yyyy')+','+formattedAmount); 
                    }
                    milestoneList.add(customScheduleMap);
                    crmDataWrap.CustomBillingSchedule = milestoneList;
                }
            }

            if(amedmentTypes.contains('Campaign Run Dates Change')|| 
                amedmentTypes.contains('Number of Impressions Amendment')||
                amedmentTypes.contains('Billing Options Update'))
            {                
                for(OpportunityLineItem oli:oppObj.OpportunityLineItems)
                {
                    MuleSoftCRMWrapper.OpportunityProduct oliWrap = new MuleSoftCRMWrapper.OpportunityProduct();

                    oliWrap.OpportunityProductName = oli.Name;
                    oliWrap.ProductCode = oli.Product2.IM_ProductCode__c; 
                    oliWrap.ListPrice   = String.valueOf(oli.SBQQ__QuoteLine__r.SBQQ__ListTotal__c); 	// oli.ListPrice
                    oliWrap.TotalPrice  = String.valueOf(oli.SBQQ__QuoteLine__r.SBQQ__NetTotal__c); 	// oli.TotalPrice
                    oliWrap.Quantity    = String.valueOf(oli.SBQQ__QuoteLine__r.SBQQ__Quantity__c ); //oli.Quantity
                    oliWrap.ProductName = oli.Product2.Name;
                    oliWrap.StartDate   = String.valueOf(oli.SBQQ__QuoteLine__r.SBQQ__StartDate__c);
                    oliWrap.EndDate     = String.valueOf(oli.SBQQ__QuoteLine__r.SBQQ__EndDate__c); 
                    oliWrap.LineDescription = oli.Description;
                    oliWrap.CRMOLINumber    =   oli.SBQQ__QuoteLine__r.CRM_OLI_Number__c; 
                    oliWrap.IOMQLINumber    =   oli.SBQQ__QuoteLine__r.Name; 

                    crmDataWrap.OpportunityLineItem.add(oliWrap);
                }
            }
        return JSON.serialize(crmDataWrap,false).replaceAll(':null',':" "');// add Blank Space to set null value in CRM.
    }
    
    /**
    * @description   This method is used to create API Sync Trans For Update In CRM
    * @param  orderId order id
    */
    @AuraEnabled
    public static void createAPISyncTransForUpdateInCRM(String orderId){
        List<Order> orderList = [SELECT Id,Edition__c FROM Order WHERE Id=:orderId WITH SECURITY_ENFORCED];

        CreateApiSyncRecords.ApiSyncRecordsWrapper obj = new CreateApiSyncRecords.ApiSyncRecordsWrapper();
        obj.Type = 'Update';
        obj.startedFrom = 'Order';
        obj.requestType = GlobalConstants.ASYNCHRONOUS; 
        obj.thirdPartyERPSystem = null;
        obj.itemType = GlobalConstants.OLI_START_END_AMOUNT_UPDATE; 
        obj.apiCallType = GlobalConstants.POST;
        obj.listSObject = orderList;
        obj.transactionStatus = GlobalConstants.QUEUED;
        obj.itemStatus = GlobalConstants.QUEUED; // pause till API ready
        CreateApiSyncRecords.insertAllAPISyncItem(obj);
    }
    
    /**
    * @description   This method is used to Update StageName In CRM
    * @param  apiSyncObj API Synchronization Item
    * @return  String Status
    */
    public static String updateOppProductsInCRM(API_Synchronization_Item__c apiSyncObj) 
    { 
        API_Synchronization_Item__c itemObj = new API_Synchronization_Item__c(Id=apiSyncObj.Id);        
        String calloutStatus = GlobalConstants.PROCESSING;
        API_Detail__mdt mtAPIDetails = APISynchronizationHelper.getAPIDetails(AMENDMENT_DATA_API,MULESOFT_CRM);

        String payload = getAfterOrderProductUpdateDataPayload(apiSyncObj);
        
        HttpResponse res = callMuleSoft(mtAPIDetails, payload);

        // If valid Response 
        if((res.getStatusCode() == 200 || res.getStatusCode() == 202)&& String.isNotBlank(res.getBody()))
        {            
            calloutStatus = GlobalConstants.SUCCESS;
            itemObj.Status__c= GlobalConstants.COMPLETED;
            itemObj.Error_Message__c= GlobalConstants.BLANK_STRING;
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
    * @description   This method is used to create payload for IOM to CRM after Amedment
    * @param  apiSyncObj API Synchronization Item
    * @return  String JSON Payload
    */
    private static string getAfterOrderProductUpdateDataPayload(API_Synchronization_Item__c apiSyncObj)
    {
        String orderId = apiSyncObj.Order__c;
        String orderFields='Id,Legacy_CRM_Instance__c,Opportunity.IM_Opportunity_No__c,Opportunity.Name,';
        String orderLinesQuery = '(SELECT Id,ListPrice,TotalPrice,Quantity,Description,Product2.Name,ServiceDate,EndDate,Product2.IM_ProductCode__c,SBQQ__QuoteLine__r.Name,SBQQ__QuoteLine__r.CRM_OLI_Number__c FROM OrderItems Where Quantity > 0) ';
        String queryStr = 'Select ' + orderFields + orderLinesQuery + ' From Order Where Id =\''+String.escapeSingleQuotes(orderId)+'\'';
        
        Order orderObj = Database.query(queryStr);

        MuleSoftCRMWrapper crmDataWrap      = new MuleSoftCRMWrapper();
        crmDataWrap.IOMOpportunityNumber    =  orderObj.Opportunity.IM_Opportunity_No__c;
        crmDataWrap.CRMOrg                  = orderObj.Legacy_CRM_Instance__c;
        
        for(OrderItem oli:orderObj.OrderItems){
            
            MuleSoftCRMWrapper.OpportunityProduct oliWrap = new MuleSoftCRMWrapper.OpportunityProduct();
            oliWrap.OpportunityProductName = orderObj.Opportunity.Name+' '+oli.Product2.Name;
            oliWrap.ProductCode = oli.Product2.IM_ProductCode__c; 
            oliWrap.ListPrice   = String.valueOf(oli.ListPrice);
            oliWrap.TotalPrice  = String.valueOf(oli.TotalPrice);
            oliWrap.Quantity    = String.valueOf(oli.Quantity);
            oliWrap.ProductName = oli.Product2.Name;
            oliWrap.StartDate   = String.valueOf(oli.ServiceDate);
            oliWrap.EndDate     = String.valueOf(oli.EndDate); 
            oliWrap.LineDescription = oli.Description;
            oliWrap.CRMOLINumber    =   oli.SBQQ__QuoteLine__r.CRM_OLI_Number__c; 
            oliWrap.IOMQLINumber    =   oli.SBQQ__QuoteLine__r.Name; 
            crmDataWrap.OpportunityLineItem.add(oliWrap);
        }
        return JSON.serialize(crmDataWrap,false).replaceAll(':null',':""');
    }

    /**
    * @description   This method is used to get AccountTaxNumberMap
    * @param  accIds Set of Account Ids
    * @return  Map<Id,Account_Tax_Number__c>
    */
    private Static Map<Id,Account_Tax_Number__c> getAccountTaxNumberMap(set<Id> accIds)
    {
        Map<Id,Account_Tax_Number__c> maplatestAccountTaxnumber = new Map<Id,Account_Tax_Number__c>();
        for(Account_Tax_Number__c accTN:[SELECT Id,Account__c,Tax_ID__c FROM Account_Tax_Number__c WHERE Account__c IN:accIds AND Status__c = 'Valid' WITH SECURITY_ENFORCED ORDER BY Account__c,LastModifiedDate ])
        {
            maplatestAccountTaxnumber.put(accTN.Account__c,accTN);
        }
        return maplatestAccountTaxnumber;
    }
      /**
    * @description   This method is used to get Translated Records
    * @param  sobjectIds Set of Account/Contact Ids
    * @return  Map<Id,Translated_Record__c>
    */
    public Static Map<Id,Translated_Record__c> getTranslatedRecordMap(set<Id> sobjectIds)
    {
        Map<Id,Translated_Record__c> maplatestTranslatedRecord = new Map<Id,Translated_Record__c>();
        for(Translated_Record__c trans:[SELECT Id,Account__c,Contact__c,Translated_Account_Name__c,Translated_Billing_Address_Line_1__c,Translated_Billing_Address_Line_2__c,Translated_Billing_Address_Line_3__c,Translated_Billing_City__c,Translated_Contact_FirstName__c,Translated_Contact_LastName__c,Translated_Contact_Salutation__c,Translated_Language__c FROM Translated_Record__c WHERE Account__c IN:sobjectIds OR Contact__c IN:sobjectIds WITH SECURITY_ENFORCED ORDER BY Account__c,Contact__c,LastModifiedDate ])
        {
            if(String.isNotBlank(trans.Account__c)){maplatestTranslatedRecord.put(trans.Account__c,trans);}
            if(String.isNotBlank(trans.Contact__c)){maplatestTranslatedRecord.put(trans.Contact__c,trans);}            
        }
        return maplatestTranslatedRecord;
    }

      /**
    * @description   This method is used to get AccountContactRelation
    * @param accountId Account Id
    * @param contactId Contact Id
    * @param sourceCRM source CRM
    * @return AccountContactRelation 
    */
    public Static AccountContactRelation getAccountContactRelation(Id accountId,Id contactId,String sourceCRM)
    {
        //System.debug('accountId '+accountId+ '  contactId '+contactId+' sourceCRM '+sourceCRM);
        sourceCRM = Test.isRunningTest()? null:sourceCRM;
        AccountContactRelation accConRel = [SELECT Id,IM_Contact_No__c,SourceOrg__c,Source_Contact_ID__c,AccountId,ContactId FROM AccountContactRelation where IsActive=true AND AccountId =: accountId AND ContactId =: contactId AND SourceOrg__c =:sourceCRM WITH SECURITY_ENFORCED LIMIT 1];
        return accConRel!= null ? accConRel :new AccountContactRelation();
    }

    private static object getObjectValue(object value)
    {
        return value!=null ? value :'';
    }
}