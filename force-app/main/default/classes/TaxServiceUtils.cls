/**
* File         :   TaxServiceUtils 
* Project      :   Order & Billing Plateform
* Created Date :   09th Sept 2021
* Created By   :   Girikon(Ashish)
* Test Class   :   TaxServiceUtils_Test (93%)
* ****************************************************************************************************
* @description : contain the logic that applies tax to the order and invoice line items using Billing tax engine methods(OBP-77)
****************************************************************************************************
* Modification log :
* 1. Girikon (Ashish)  [29 Sept 2021 (OBP-81)] Error Logging for Tax Callouts
*/
public with sharing class TaxServiceUtils
{
    private static final String TAX_COMPLETE = 'Tax Complete';
    private static final String TAX_REQUIRED = 'Tax Required';
    private static final String INVOICE_TAX = 'Invoice Tax';
    private static final String ORDER_TAX = 'Order Tax';
    private static final String UNKNOWN = 'Unknown';
    
    private static final String ONESOURCE_CALCULATE_TAX = 'Onesource_Calculate_Tax';

    /**
    * @description   This method is used for Calculating Tax 
    * @param  accSyncObj API Synchronization Item
    * @return  String Status
    */
    public static String calculateTax(API_Synchronization_Item__c accSyncObj) 
    { 
        String taxType = getTaxType(accSyncObj);
        String calloutStatus = GlobalConstants.PROCESSING;
        API_Detail__mdt mtAPIDetails = APISynchronizationHelper.getAPIDetails(ONESOURCE_CALCULATE_TAX, GlobalConstants.ONESOURCE);

        String payload = taxType == ORDER_TAX ? OneSourceAPIWrapper.getOneSourceOrderTaxPayload(accSyncObj.Order__c): (taxType == INVOICE_TAX ? OneSourceAPIWrapper.getOneSourceInvoiceTaxPayload(accSyncObj.Invoice__c) :'');
        
        Id sObjectId = taxType == ORDER_TAX ? accSyncObj.Order__c : (taxType == INVOICE_TAX ? accSyncObj.Invoice__c:'');
        
        //String payload = mockPaylaodJSON;
        HttpResponse res = callOneSource(mtAPIDetails.API_End_Point__c,mtAPIDetails.API_Method__c,payload);

        // If valid Response 
        if((res.getStatusCode() == 200 || res.getStatusCode() == 400)&& String.isNotBlank(res.getBody()))
        {
            string resBody =  res.getBody();
            resBody = resBody.replace('"currency":','"strCurrency":').normalizeSpace();
            OneSourceAPIWrapper.Reponse osRes = (OneSourceAPIWrapper.Reponse) System.JSON.deserialize(resBody, OneSourceAPIWrapper.Reponse.class);

            if(osRes.meta.code == '200' && osRes.meta.status == GlobalConstants.SUCCESS)
            {
                if(taxType == ORDER_TAX)
                {
                    setOrderTax(accSyncObj.Order__c,osRes.data); 
                }else if(taxType == INVOICE_TAX)
                {
                    setInvoiceTax(accSyncObj.Invoice__c,osRes.data);
                }
                calloutStatus = GlobalConstants.SUCCESS;
                APISynchronizationHelper.updateSyncItemStatus(New API_Synchronization_Item__c(Id=accSyncObj.id,Status__c= +GlobalConstants.COMPLETED,Error_Message__c='',API_Call_Type__c=mtAPIDetails.API_Method__c,Response_Code__c= String.valueOf(res.getStatusCode())+'|'+osRes.meta.code,Request_Body__c=payload,Response_Body__c =res.getbody().normalizeSpace()));
            }else{ // 400 + Meta.Code =400/null
                calloutStatus = GlobalConstants.ERROR;
                // Error Response
                APISynchronizationHelper.updateSyncItemStatus(New API_Synchronization_Item__c(Id=accSyncObj.id,Status__c= GlobalConstants.ERROR,Error_Message__c=osRes.meta.message,API_Call_Type__c=mtAPIDetails.API_Method__c,Response_Code__c= String.valueOf(res.getStatusCode())+'|'+osRes.meta.code,Request_Body__c=payload,Response_Body__c =res.getbody().normalizeSpace()));
                // Insert Error Line
                createErrorLogs(sObjectId,taxType,osRes.meta);
                             
            }
        }else{
            calloutStatus = GlobalConstants.ERROR;
            // Error 
            String error = APISynchronizationHelper.getValueFromjson(res.getbody(),GlobalConstants.ERROR);
            APISynchronizationHelper.updateSyncItemStatus(New API_Synchronization_Item__c(Id=accSyncObj.id,Status__c= GlobalConstants.ERROR,Error_Message__c=error,API_Call_Type__c=mtAPIDetails.API_Method__c,Response_Code__c= String.valueOf(res.getStatusCode()),Request_Body__c=payload,Response_Body__c =res.getbody().normalizeSpace()));
            createErrorLogs(sObjectId,taxType,null);
        }
        
        return calloutStatus;
    }

   
     /**
    * @description   This method is used for Save/update order Tax 
    * @param  orderId Order Id
    * @param  data onceSource Data
    */
    private static void setOrderTax(Id orderId,OneSourceAPIWrapper.Cls_data data)
    {        
        list<Tax_Lines__c> listTaxLines = new list<Tax_Lines__c>();
        list<Tax_Lines__c> dellistTaxLines = new list<Tax_Lines__c>();
        list<OrderItem> listOrderItems = new list<OrderItem>();
        map<String,OrderItem> orderItemMap = new map<String,OrderItem>();
        Order orderObj = New Order(Id=orderId,Tax_Status__c=TAX_REQUIRED);

        for(OrderItem orderItem : [SELECT Id,Line_Item_Number__c, (SELECT Id FROM Tax_Lines__r) FROM OrderItem WHERE orderId =:orderId WITH SECURITY_ENFORCED])
        {
            orderItemMap.put(String.valueOf(orderItem.Line_Item_Number__c),orderItem);
            dellistTaxLines.addAll(orderItem.Tax_Lines__r);
        }

        Map<String,Map<String,List<API_Field_Mapping__mdt>>> mapObjectMapFielListAFM = getFieldMappingForAPIResponse('Response',ORDER_TAX,GlobalConstants.ONESOURCE);

        // Data
        for(OneSourceAPIWrapper.Cls_lines line : data.lines)
        {
            if(orderItemMap.containskey(line.itemNumber))
            {
                OneSourceAPIWrapper.WrapperParametrs params = new OneSourceAPIWrapper.WrapperParametrs();
                params.objectName = 'OrderItem';
                params.mapObjectApiNameAndListAFM = mapObjectMapFielListAFM;
                OrderItem orderItem = (OrderItem)getSObjectFromAPIResponse(params,((OneSourceAPIWrapper.OneSourceTaxResponseInterface)line));
                orderItem.Id = orderItemMap.get(line.itemNumber).Id;
                orderItem.Tax_Status__c = TAX_COMPLETE;
                orderItem.blng__TaxErrorMessage__c = GlobalConstants.BLANK_STRING;
                if(orderItem.blng__TaxPercentageApplied__c != null){orderItem.blng__TaxPercentageApplied__c = orderItem.blng__TaxPercentageApplied__c*100;}
                orderItem.blng__TaxStatus__c = GlobalConstants.COMPLETED;
                orderObj.Tax_Status__c = TAX_COMPLETE;
                
                // Add Tax line 
                if(line.taxes != null){
                 	for(OneSourceAPIWrapper.Cls_taxes itemTax : line.taxes )
                    {
                        params = new OneSourceAPIWrapper.WrapperParametrs();
                        params.objectName = 'Tax_Lines__c';
                        params.mapObjectApiNameAndListAFM = mapObjectMapFielListAFM;
                        Tax_Lines__c taxLine = (Tax_Lines__c)getSObjectFromAPIResponse(params,((OneSourceAPIWrapper.OneSourceTaxResponseInterface)itemTax));
                        taxLine.Order_Product__c = orderItem.Id;
                        //if(String.isNotBlank(taxLine.Authority_Name__c)){taxLine.Name = taxLine.Authority_Name__c;}
                        if(taxLine.Tax_Rate__c != null){taxLine.Tax_Rate__c = taxLine.Tax_Rate__c*100;}
                        listTaxLines.add(taxLine);
                    }   
                }                
                listOrderItems.add(orderItem);
            }
        }


        // Insert/Update Tax
        if (!listOrderItems.isEmpty() && Schema.sObjectType.OrderItem.isUpdateable() )
        {
            update listOrderItems;
        }

        if (!listTaxLines.isEmpty() && Schema.sObjectType.Tax_Lines__c.isCreateable())
        {
            insert listTaxLines;
        }

        if (!dellistTaxLines.isEmpty() && Schema.sObjectType.Tax_Lines__c.isDeletable()) {
            delete dellistTaxLines;
        }

        if (Schema.sObjectType.Order.isUpdateable())
        {
            update orderObj;
        }
    }

     /**
    * @description   This method is used for Save/update Invoice Tax 
    * @param  invoiceId Invoice Id
    * @param  data onceSource Data
    */
    private static void setInvoiceTax(Id invoiceId,OneSourceAPIWrapper.Cls_data data)
    {        
        list<Tax_Lines__c> listTaxLines = new list<Tax_Lines__c>();
        list<Tax_Lines__c> dellistTaxLines = new list<Tax_Lines__c>();
        list<blng__InvoiceLine__c> listinvoiceItems = new list<blng__InvoiceLine__c>();
        map<String,blng__InvoiceLine__c> invoiceItemMap = new map<String,blng__InvoiceLine__c>();
        
        blng__Invoice__c invoiceObj = New blng__Invoice__c(Id=invoiceId,Tax_Status__c=TAX_REQUIRED,blng__TaxStatus__c=GlobalConstants.QUEUED,blng__TaxErrorMessage__c = GlobalConstants.BLANK_STRING);
        
        List<blng__Invoice__c> listInvoices = new List<blng__Invoice__c>([SELECT Id,blng__Order__r.Opportunity.Default_Edition__r.Invoice_Posting__c FROM blng__Invoice__c WHERE Id=:invoiceId WITH SECURITY_ENFORCED]);
        // Check If Automatic Invoice Posting & OrderHub Sync Enabled for the Edition
        Boolean invoicePostingAllowed = !listInvoices.isEmpty() ?listInvoices.get(0).blng__Order__r.Opportunity.Default_Edition__r.Invoice_Posting__c : false;

        for(blng__InvoiceLine__c invoiceItem : [SELECT Id,Line_Item_Number__c, (SELECT Id FROM Tax_Lines__r) FROM blng__InvoiceLine__c WHERE blng__Invoice__c =:invoiceId WITH SECURITY_ENFORCED])
        {
            invoiceItemMap.put(String.valueOf(invoiceItem.Line_Item_Number__c),invoiceItem);
            dellistTaxLines.addAll(invoiceItem.Tax_Lines__r);
        }

        Map<String,Map<String,List<API_Field_Mapping__mdt>>> mapObjectMapFielListAFM = getFieldMappingForAPIResponse('Response',INVOICE_TAX,GlobalConstants.ONESOURCE);

        // Data
        for(OneSourceAPIWrapper.Cls_lines line : data.lines)
        {
            if(invoiceItemMap.containskey(line.itemNumber))
            {
                OneSourceAPIWrapper.WrapperParametrs params = new OneSourceAPIWrapper.WrapperParametrs();
                params.objectName = 'blng__InvoiceLine__c';
                params.mapObjectApiNameAndListAFM = mapObjectMapFielListAFM;
                blng__InvoiceLine__c invoiceLine = (blng__InvoiceLine__c)getSObjectFromAPIResponse(params,((OneSourceAPIWrapper.OneSourceTaxResponseInterface)line));
                invoiceLine.Id = invoiceItemMap.get(line.itemNumber).Id;
                invoiceLine.Tax_Status__c = TAX_COMPLETE;
                invoiceLine.blng__TaxStatus__c = GlobalConstants.COMPLETED;
                invoiceLine.blng__TaxErrorMessage__c = GlobalConstants.BLANK_STRING;
                if(invoiceLine.blng__TaxPercentageApplied__c != null){invoiceLine.blng__TaxPercentageApplied__c = invoiceLine.blng__TaxPercentageApplied__c*100;}
                invoiceObj.Tax_Status__c = TAX_COMPLETE;
                invoiceObj.blng__TaxStatus__c = GlobalConstants.COMPLETED;
                invoiceObj.ERP_Sync_Status__c = invoicePostingAllowed ? GlobalConstants.SYNC_REQUIRED :null;
                // Add Tax line 
                if( line.taxes != null) // Added for GECI-386
                {
                    for(OneSourceAPIWrapper.Cls_taxes itemTax : line.taxes )
                    {                
                        params = new OneSourceAPIWrapper.WrapperParametrs();
                        params.objectName = 'Tax_Lines__c';
                        params.mapObjectApiNameAndListAFM = mapObjectMapFielListAFM;
                        Tax_Lines__c taxLine = (Tax_Lines__c)getSObjectFromAPIResponse(params,((OneSourceAPIWrapper.OneSourceTaxResponseInterface)itemTax));
                        taxLine.Invoice_Line__c = invoiceLine.Id;  
                        //if(String.isNotBlank(taxLine.Authority_Name__c)){taxLine.Name = taxLine.Authority_Name__c;}   
                        if(taxLine.Tax_Rate__c != null){taxLine.Tax_Rate__c = taxLine.Tax_Rate__c*100;}               
                        listTaxLines.add(taxLine);
                    }
                }
                listinvoiceItems.add(invoiceLine);
            }
        }

        // Insert/Update Tax
        if (!listinvoiceItems.isEmpty() && Schema.sObjectType.blng__InvoiceLine__c.isUpdateable() )
        {
            update listinvoiceItems;
        }

        if (!listTaxLines.isEmpty() && Schema.sObjectType.Tax_Lines__c.isCreateable())
        {
            insert listTaxLines;
        }

        if (!dellistTaxLines.isEmpty() && Schema.sObjectType.Tax_Lines__c.isDeletable()) {
            delete dellistTaxLines;
        }
        if (Schema.sObjectType.blng__Invoice__c.isUpdateable())
        {
            update invoiceObj;
        }
    }

    /**
    * @description  This method is used for ONE_SOURCE Callout
    * @param  endPointURL Callout End Point Url
    * @param  method  Callout request method [GET , PUT , POST]
    * @param  jsonBody  request Body  
    * @return  HttpResponse response from ONE_SOURCE System
    */
    private static HttpResponse callOneSource(String endPointURL,string method,String jsonBody)
    {
        // endPointURL = removeUnUsedPrameters(endPointURL);
        endPointURL = endPointUrl.replaceall(' ', '%20');
        System.debug(LoggingLevel.DEBUG, endPointURL);
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:Onesource'+endPointURL);
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
    * @description  This method is used for Set Error Details After tax Callout
    * @param  sObjectId sId of Invoice Or order
    * @param  taxType  tax type  Order Tax /Invoice Tax
    * @param  meta  request Meta Body  
    * @auther Girikon (Ashish)  [29 Sept 2021 (OBP-81)] Error Logging for Tax Callouts
    */
    private static void createErrorLogs(Id sObjectId,String taxType,OneSourceAPIWrapper.Cls_meta meta)
    {
        list<blng__ErrorLog__c> errorLines = New list<blng__ErrorLog__c>();

        if(taxType == ORDER_TAX)
        {
            map<String,OrderItem> orderItemMap = new map<String,OrderItem>();
            for(OrderItem orderItem : [SELECT Id,Line_Item_Number__c, (SELECT Id FROM Tax_Lines__r) FROM OrderItem WHERE orderId =:sObjectId WITH SECURITY_ENFORCED])
            {
                orderItem.blng__TaxStatus__c = GlobalConstants.ERROR;
                orderItem.Tax_Status__c = GlobalConstants.ERROR;
                orderItem.blng__TaxErrorMessage__c = GlobalConstants.BLANK_STRING;
                orderItemMap.put(String.valueOf(orderItem.Line_Item_Number__c),orderItem);                
            }
            Order orderObj = New Order(Id=sObjectId,Tax_Status__c=GlobalConstants.ERROR);

            if(meta != null)
            {
                for(OneSourceAPIWrapper.Cls_partnerMessages ptMsg : meta.partnerMessages)
                {   
                    if(ptMsg.status == GlobalConstants.ERROR && orderItemMap.containsKey(ptMsg.locationId))
                    {
                        OrderItem orderItem = orderItemMap.get(ptMsg.locationId);
                        blng__ErrorLog__c errorLine = new blng__ErrorLog__c();
                        errorLine.blng__OrderProduct__c = orderItem.Id;
                        errorLine.Name  = ptMsg.location +' : '+ptMsg.code;
                        errorLine.blng__ErrorOrigin__c  = ptMsg.location;
                        errorLine.blng__FullErrorLog__c  = ptMsg.message;
                        errorLine.blng__ErrorCode__c  = String.isNotBlank(ptMsg.code)?ptMsg.code:UNKNOWN;
                        orderItem.blng__TaxErrorMessage__c = ptMsg.code;
                        errorLines.add(errorLine);
                        orderItemMap.put(ptMsg.locationId,orderItem);
                    }
                }
                blng__ErrorLog__c errorLine = new blng__ErrorLog__c();
                errorLine.blng__Order__c = sObjectId;
                errorLine.Name  = meta.code ;                
                errorLine.blng__FullErrorLog__c  = meta.message ;
                errorLine.blng__ErrorCode__c  = String.isNotBlank(meta.code)?meta.code:UNKNOWN;
                errorLines.add(errorLine);
            }
             // Insert/Update Tax
            if (!orderItemMap.isEmpty() && Schema.sObjectType.OrderItem.isUpdateable() )
            {
                update orderItemMap.values();
            }
            if (Schema.sObjectType.Order.isUpdateable())
            {
                update orderObj;
            }
            
        }else if(taxType == INVOICE_TAX)
        {
            map<String,blng__InvoiceLine__c> invoiceItemMap = new map<String,blng__InvoiceLine__c>();
            for(blng__InvoiceLine__c invoiceItem : [SELECT Id,Line_Item_Number__c, (SELECT Id FROM Tax_Lines__r) FROM blng__InvoiceLine__c WHERE blng__Invoice__c =:sObjectId WITH SECURITY_ENFORCED])
            {
                invoiceItem.blng__TaxStatus__c = GlobalConstants.ERROR;
                invoiceItem.Tax_Status__c = GlobalConstants.ERROR;
                invoiceItem.blng__TaxErrorMessage__c = GlobalConstants.BLANK_STRING;
                invoiceItemMap.put(String.valueOf(invoiceItem.Line_Item_Number__c),invoiceItem);   
            }           
            blng__Invoice__c invoiceObj = New blng__Invoice__c(Id=sObjectId,Tax_Status__c=GlobalConstants.ERROR,blng__TaxStatus__c=GlobalConstants.ERROR);

            if(meta != null)
            {
                for(OneSourceAPIWrapper.Cls_partnerMessages ptMsg : meta.partnerMessages)
                {   
                    if(ptMsg.status == GlobalConstants.ERROR && invoiceItemMap.containsKey(ptMsg.locationId))
                    {
                        blng__InvoiceLine__c invoiceItem = invoiceItemMap.get(ptMsg.locationId);
                        blng__ErrorLog__c errorLine = new blng__ErrorLog__c();
                        errorLine.blng__InvoiceLine__c = invoiceItem.Id;
                        errorLine.Name  = ptMsg.location +' : '+ptMsg.code;
                        errorLine.blng__ErrorOrigin__c  = ptMsg.location;
                        errorLine.blng__FullErrorLog__c  = ptMsg.message;
                        errorLine.blng__ErrorCode__c  = String.isNotBlank(ptMsg.code)?ptMsg.code:UNKNOWN;
                        invoiceItem.blng__TaxErrorMessage__c = ptMsg.code;
                        errorLines.add(errorLine);
                        invoiceItemMap.put(ptMsg.locationId,invoiceItem);
                    }
                }
                blng__ErrorLog__c errorLine = new blng__ErrorLog__c();
                errorLine.blng__Invoice__c = sObjectId;
                errorLine.Name  = meta.code ;                
                errorLine.blng__FullErrorLog__c  = meta.message ;
                errorLine.blng__ErrorCode__c  = String.isNotBlank(meta.code)?meta.code:UNKNOWN;
                invoiceObj.blng__TaxErrorMessage__c = meta.code;
                errorLines.add(errorLine);
            }

            // Insert/Update Tax
            if (!invoiceItemMap.isEmpty() && Schema.sObjectType.blng__InvoiceLine__c.isUpdateable() )
            {
                update invoiceItemMap.values();
            }

            if (Schema.sObjectType.blng__Invoice__c.isUpdateable())
            {
                update invoiceObj;
            }
        }

        if (!errorLines.isEmpty() && Schema.sObjectType.blng__ErrorLog__c.isCreateable())
        {
            insert errorLines;
        }
    }

    /**
    * @description : get field mapping for parsing API Response.
    * @param jsonTypeName
    * @param taxCallTypename
    * @param thirdParty
    * @return Map<String,Map<String,List<API_Field_Mapping__mdt>>>
    **/
    private static Map<String,Map<String,List<API_Field_Mapping__mdt>>> getFieldMappingForAPIResponse(String jsonTypeName, String taxCallTypename, String thirdParty){
        Map<String,Map<String,List<API_Field_Mapping__mdt>>> mapReturn = new Map<String,Map<String,List<API_Field_Mapping__mdt>>>();
        if(Schema.sObjectType.API_Field_Mapping__mdt.isAccessible()) {
            List<API_Field_Mapping__mdt> lstAFM = [SELECT API_Node_Name__c,API_Node_Value__c,Field_Name__c,Field_Name__r.QualifiedApiName,Field_Name__r.DataType,Object_Field_Value__c,API_Call_Name__c,Object_Name__r.QualifiedApiName FROM API_Field_Mapping__mdt WHERE JSON_Type__c=:jsonTypeName AND API_Call_Name__c=:taxCallTypename AND API_3rd_Party_Name__c=:thirdParty AND Do_Not_Use_in_API_Mapping__c=false]; 
            for(API_Field_Mapping__mdt afm : lstAFM){
                Map<String,List<API_Field_Mapping__mdt>> tempMap = (mapReturn.containsKey(afm.Object_Name__r.QualifiedApiName)?mapReturn.get(afm.Object_Name__r.QualifiedApiName):new Map<String,List<API_Field_Mapping__mdt>>());
                List<API_Field_Mapping__mdt> lstTempAFM = (tempMap.containsKey(afm.Field_Name__r.QualifiedApiName)?tempMap.get(afm.Field_Name__r.QualifiedApiName):(new List<API_Field_Mapping__mdt>()));
                lstTempAFM.add(afm);
                tempMap.put(afm.Field_Name__r.QualifiedApiName,lstTempAFM);
                mapReturn.put(afm.Object_Name__r.QualifiedApiName,tempMap);
            }
        }
        return mapReturn;
    }

    /**
    * @description to get Asset object from Expocad booth
    * @param  params
    * @param  otriObj
    * @return SObject 
    */
    public static SObject getSObjectFromAPIResponse(OneSourceAPIWrapper.WrapperParametrs params, OneSourceAPIWrapper.OneSourceTaxResponseInterface otriObj)
    {
        SObject sObj = Schema.getGlobalDescribe().get(params.objectName).newSObject();
        Map<String,List<API_Field_Mapping__mdt>> mapFieldNameAndMappings = params.mapObjectApiNameAndListAFM.get(params.objectName);
        for(String fieldApiName : mapFieldNameAndMappings.keyset()){
            String value = '';
            String dataType = '';
            for(API_Field_Mapping__mdt afm : mapFieldNameAndMappings.get(fieldApiName)){
                dataType = afm.Field_Name__r.DataType;
                if(String.isBlank(afm.API_Node_Name__c)){
                    value = afm.Object_Field_Value__c;
                }
                else{
                    value = String.valueOf(OneSourceAPIWrapper.getJSONNodeValue(afm.API_Node_Name__c,otriObj));
                }
            }
            if(dataType.startsWith('Number') || dataType.startsWith('Currency') || dataType.startsWith('Percent')){
                if(String.isNotBlank(value)){sObj.put(fieldApiName,Decimal.valueOf(value));}
            }
            else if(dataType.startsWith('Date')){
                if(String.isNotBlank(value)){sObj.put(fieldApiName,onesourceDateToDateObject(String.valueOf(value)));}
            }
            else if(dataType.startsWith('Checkbox')){
                if(String.isNotBlank(value)){sObj.put(fieldApiName,Boolean.valueOf(value));}
            }
            else{
                if(String.isNotBlank(value)){sObj.put(fieldApiName,String.valueOf(value));}
            }
        }
        return sobj;
    }

    /**
    * @description : to convert expoCad Date To Apex Date Object.
    * @param strDate
    * @return Date
    **/
    public static Date onesourceDateToDateObject(String strDate){
        Date dt;
        if(String.isNotBlank(strDate) && strDate.length() == 10){
            dt = date.newinstance(Integer.valueOf(strDate.left(4)), Integer.valueOf(strDate.substring(5, 7)), Integer.valueOf(strDate.right(2)));
        }
        return dt;
    }

    /**
    * @description   This method is used for Calculating Tax Type Object
    * @param  accSyncObj API Synchronization Item
    * @return  String Tax type Invoice/Order
    */
    private static string getTaxType(API_Synchronization_Item__c accSyncObj)
    {
        return (String.isNotBlank(accSyncObj.Invoice__c) && String.isBlank(accSyncObj.Order__c))?INVOICE_TAX: (String.isBlank(accSyncObj.Invoice__c) && String.isNotBlank(accSyncObj.Order__c))?ORDER_TAX:'';
    }
}