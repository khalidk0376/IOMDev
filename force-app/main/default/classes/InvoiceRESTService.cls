/**
* File         :   InvoiceRESTService 
* Project      :   Order & Billing Plateform
* Created Date :   16th Nov 2021
* Created By   :   Girikon(Suresh)
* Test Class   :   InvoiceRestService_Test(100%)
*******************************************************************************************************
@description : Apex rest class to update Invoice fields
*******************************************************************************************************
* Modification log : 
* 1. Girikon (Ashish) [IE-410] 10 Oct 2022 : Update ERP Ref in SAP field incase of SAP ERP 
*/
@RestResource(urlMapping='/Invoice/*')
global with sharing class InvoiceRESTService {
    private Static Final String FILTER_FIELD_API_METANAME = 'Invoice_External_No_Field';
    private Static Final String SYNCED='Synced';
    private static final String ERP_SYNC_STATUS = 'Sync Required';
    /**
* @description  This method is used to update Invoice fields
* @return ResponseData 
*/
    @HttpPatch
    global static ResponseData updateERPRefrenceNumOnInv() 
    {
        ResponseData resWrap = new ResponseData();
        resWrap.status = 'Unknown';
        resWrap.message = 'Invalid Request Data';
        RestRequest req = RestContext.request;
        String requestJSONString = req.requestBody.toString();
        try {
            InvoiceWapper invWrap = (InvoiceWapper)JSON.deserialize(requestJSONString,InvoiceWapper.class);
            Map<Id,Account> accMaptoUpdate = new Map<Id,Account>();
            Map<Id,Payment_Transaction__c> paytransMaptoUpdate = new Map<Id,Payment_Transaction__c>();
            if(String.isNotBlank(invWrap.invoiceNumber))
            {                
                String filterFieldAPI = !Test.isRunningTest()?GlobalConstants.getValue(FILTER_FIELD_API_METANAME):'Name';
                filterFieldAPI = String.isNotBlank(filterFieldAPI)?filterFieldAPI:'Name';
                List<blng__Invoice__c> invList = Database.query('Select Id,Name,ERP_Reference__c,blng__InvoiceStatus__c,blng__Account__c,Ship_To_Account__c,ERP_Sync_Status__c,blng__Order__r.Edition__r.X3rd_Party_ERP_System__c from blng__Invoice__c where '+String.escapeSingleQuotes(filterFieldAPI)+' = \''+String.escapeSingleQuotes(invWrap.invoiceNumber)+'\'');
                
                resWrap.status = 'Error';
                resWrap.message = 'No Invoice found with Invoice Number '+invWrap.invoiceNumber;
                if(!invList.isEmpty() && Schema.sObjectType.blng__Invoice__c.isUpdateable())
                {   
                    blng__Invoice__c inv = new blng__Invoice__c(Id=invList.get(0).Id);
                    inv.ERP_Reference__c = invWrap.erpRefrence;
                    inv.ERP_Sync_Status__c = 'Synced';
                    if(invList.get(0).blng__InvoiceStatus__c != 'Cancelled' && invList.get(0).blng__InvoiceStatus__c != 'Rebilled'){
                        inv.blng__InvoiceStatus__c = 'Posted';
                    }
                    
                    
                    update inv;
                    if(invWrap.erpAccountNumber != null)
                    {   // [IE-410]
                        String erpFieldAPI = String.isNotBlank(invList.get(0).blng__Order__r.Edition__r.X3rd_Party_ERP_System__c) && invList.get(0).blng__Order__r.Edition__r.X3rd_Party_ERP_System__c == 'SAP' ?'SAP_Number__c':'Oracle_Number__c';
                        // Update Sold To Account Oracle number
                        /*if(String.isNotBlank(invList.get(0).blng__Account__c) 
                            && isNotNull(invWrap.erpAccountNumber.soldTo))
                        {                           
                            Account soldAcc = new Account(Id = invList.get(0).blng__Account__c);
                            soldAcc.put(erpFieldAPI,invWrap.erpAccountNumber.soldTo);
                            accMaptoUpdate.put(invList.get(0).Ship_To_Account__c,soldAcc);
                        }*/
                        // Update Ship To Account Oracle number
                        if(String.isNotBlank(invList.get(0).Ship_To_Account__c) 
                            && isNotNull(invWrap.erpAccountNumber.shipTo))
                        {
                            Account shipAcc = new Account(Id = invList.get(0).Ship_To_Account__c);
                            shipAcc.put(erpFieldAPI,invWrap.erpAccountNumber.shipTo);
                            accMaptoUpdate.put(invList.get(0).Ship_To_Account__c,shipAcc);
                        }
                        // Update Bill To Account Oracle number
                        if(String.isNotBlank(invList.get(0).blng__Account__c) 
                            && isNotNull(invWrap.erpAccountNumber.billTo))
                        {
                            Account billAcc = new Account(Id = invList.get(0).blng__Account__c);
                            billAcc.put(erpFieldAPI,invWrap.erpAccountNumber.billTo);
                            accMaptoUpdate.put(invList.get(0).blng__Account__c,billAcc);
                        }
                        
                        if(!accMaptoUpdate.isEmpty() && Schema.sObjectType.Account.isUpdateable()){
                            update accMaptoUpdate.values();
                        }
                    }                    
                    resWrap.status = 'Success';
                    resWrap.message = 'ERP Refrence updated successfully';
                }                
            }

            // If payment tras has ERP Ref [IE-234]
            if(invWrap.payments != null && !invWrap.payments.isEmpty())
            {
                Map<String,String> paymentERPIdMap = new Map<String,String>();
                for(ErpPaymentTras erp : invWrap.payments){
                    paymentERPIdMap.put(erp.paymentId,erp.paymentTransERPRefrence);
                }
                for(Payment_Transaction__c pTrans : [SELECT Id,ERP_Reference__c,Source_Payment_ID__c FROM Payment_Transaction__c WHERE ERP_Sync_Status__c =: ERP_SYNC_STATUS AND Source_Payment_ID__c in:paymentERPIdMap.keySet() WITH SECURITY_ENFORCED])
                {
                    pTrans.ERP_Reference__c = paymentERPIdMap.containsKey(pTrans.Source_Payment_ID__c)?paymentERPIdMap.get(pTrans.Source_Payment_ID__c):null;
                    pTrans.ERP_Sync_Status__c = SYNCED;
                    paytransMaptoUpdate.put(pTrans.Id,pTrans);
                }
                if(!paytransMaptoUpdate.isEmpty() && Schema.sObjectType.Payment_Transaction__c.isUpdateable()){
                    update paytransMaptoUpdate.values();
                }
                resWrap.status = 'Success';
                resWrap.message = 'ERP Refrence updated successfully';
            }

        }catch (Exception e) 
        {
            resWrap.status = 'Error';resWrap.message = e.getMessage();
            system.debug(logginglevel.DEBUG,'Error_Message__c --> '+ resWrap.message +' At Line' + e.getLineNumber()); system.debug(logginglevel.DEBUG,' Trace --> '+ e.getStackTraceString());
        }
        return resWrap;
    }
    /**
    * @description  This method is to Check Null or blank values
    * @param val String value
    * @return Boolean Check  
    */
    private static Boolean isNotNull(String val) 
    {
        return String.isNotBlank(val) && !'null'.equalsIgnoreCase(val);
    }
    /**
    * @description  This Class is to Store Invoice Request Data
    */
    public class InvoiceWapper {
        
        public String invoiceNumber;
        public String erpRefrence;
        public ErpAccountNumber erpAccountNumber;
        public List<ErpPaymentTras> payments;
    }
    /**
    * @description  This Class is to Store ErpAccountNumber Data
    */
    public class ErpAccountNumber {
        public String billTo;
        public String shipTo;
        public String soldTo;
    }
    /**
    * @description  This Class is to Store ErpPaymentTras Data
    */
    public class ErpPaymentTras {
        public String paymentId;
        public String paymentTransERPRefrence;        
    }
    
    
    /**
    * @description  This Class is to return Reponse Data
    */
    global class ResponseData 
    {
        public String status;	        // Success / Error /Unknown
        public String message;	        // 006
    }
    /************************END PONT Deatils**********************
        End point - /services/apexrest/Invoice/
        Method - Patch

    /******************** JSON SAMPLE ******************************
     * 
    ------------- Without  payment Trans [Penton]---------------
    // {"invoiceNumber":"TSINV03301024","erpRefrence":"TSTRN03301024","erpAccountNumber":{"billTo":"69525529","shipTo":"69525530","soldTo":"null"}}

    -------- With payment Trans [payment Portal]-----------------
    //{ "invoiceNumber": "TSINV03301024", "erpRefrence": "TSTRN03301024", "erpAccountNumber": { "billTo": "69525529", "shipTo": "69525530", "soldTo": "null" }, "payments": [ { "paymentId": "txn_AzZl8HSSwHz4E25D", "paymentTransERPRefrence": "002365" } ] }
    */
}