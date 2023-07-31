/**
* File         :   ViewDocumentController 
* Project      :   GECI
* Created Date :   3 July 2023
* Created By   :   IBM (Bharath)
* Test Class   :   ViewDocumentController_Test (96%)
* ***************************************************************************************************
* @description : Controller class for View_Document Visualforce Page (GECI-1922)
* ***************************************************************************************************
*/
public with sharing class ViewDocumentController {
    private static final String USCORE = '_';
    private static final String IOM_INVOICE_PDF_RETRIEVAL = 'IOM_Invoice_PDF_Retrieval';

    public transient Blob blobBody;
    /** @description is show error message */
    public Boolean showErrorMessage{set;get;}
    /** @description is response is success*/
    public Boolean positiveResponse{set;get;}
    /** @description file in base64 format */
    public transient String base64String{get;set;}

    /** 
    * @description : method to call external Call
    * @return PageReference
    */
    public PageReference getDocument(){
        Id recordID = ApexPages.CurrentPage().getparameters().get('RecordID').escapeHtml4();
        String erpRef;
        String sObjName = recordID.getSObjectType().getDescribe().getName();
        blng__Invoice__c invoice;blng__CreditNote__c creditNote;
        String legalEntityCode;
        if(sObjName == 'blng__Invoice__c'){
            invoice = [SELECT Id,Name,blng__Order__r.Edition__r.X3rd_Party_ERP_System__c,OpportunityId__c,Legal_Entity_Code__c,ERP_Reference__c FROM blng__Invoice__c WHERE Id=:recordID WITH SECURITY_ENFORCED limit 1];  
            legalEntityCode = invoice.Legal_Entity_Code__c; 
            erpRef = invoice.ERP_Reference__c;
        }
        if(sObjName == 'blng__CreditNote__c'){
            creditNote = [SELECT Id,Name,blng__RelatedInvoice__r.blng__Order__r.Edition__r.X3rd_Party_ERP_System__c,blng__RelatedInvoice__r.OpportunityId__c,Legal_Entity__r.Legal_Entity_Code__c,ERPReference__c FROM blng__CreditNote__c WHERE Id=:recordID WITH SECURITY_ENFORCED limit 1]; 
            legalEntityCode = creditNote.Legal_Entity__r.Legal_Entity_Code__c;
            erpRef = creditNote.ERPReference__c;
        }
        
        API_Detail__mdt mtAPIDetails = APISynchronizationHelper.getAPIDetails(IOM_INVOICE_PDF_RETRIEVAL, GlobalConstants.ORACLE);

        String urlParameter='/download?legalEntity=' + legalEntityCode;
        String endPointURL = mtAPIDetails.API_End_Point__c + erpRef + urlParameter;
        HttpResponse response = viewDocumentController.calltoExternalSystem(erpRef, legalEntityCode, mtAPIDetails);
        Boolean sizelimit = false;
        if((response.getStatusCode() == 200 || response.getStatusCode() == 202) && String.isNotBlank(response.getBody())){
            blobBody = response.getBodyAsBlob();
            String filetype = response.getHeader('Content-Type');
            Decimal fileSizeInBytes = blobBody.size();
            Decimal fileSizeInKB = fileSizeInBytes/1024;
            Decimal fileSizeInMB = fileSizeInKB/1024;
            if(fileSizeInMB < 4.3 || filetype=='application/pdf'){
                sizelimit=true;
            }
            if(sizelimit){
                positiveResponse = true;
                base64String = EncodingUtil.base64Encode(blobBody);
            }
            if(!sizelimit){
                positiveResponse = false;
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,'Please contact system Admin!'));
            } 
        }
        else{
            positiveResponse = false;
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,System.Label.View_Document_Error));
        }
        //create API Records for Tracking
        WrapperListView wrapObj = new WrapperListView(invoice,endPointURL,response.getBody(),sObjName,creditNote,positiveResponse,String.valueOf(response.getStatusCode()));
        viewDocumentController.createAPIrecs(wrapObj);
        return null;
    }

    /**
    * @description : Generic Method for HTTP callout to fetch Invoice/Credit note PDF
    * @param  erpRef ERP Reference
    * @param  legalEntityCode Legal Entity Code
    * @param  mtAPIDetails API_Detail__mdt
    * @return HTTPResponse
    */
    public static HTTPResponse calltoExternalSystem(String erpRef, String legalEntityCode, API_Detail__mdt mtAPIDetails) {
        String endPointURL = '/document/'+erpRef+'/download?legalEntity='+legalEntityCode;
        String method = mtAPIDetails.API_Method__c;
        String headerval = String.ValueOf(mtAPIDetails.Headers__c);  
        HttpRequest request = new HttpRequest();
        request.setHeader('x-api-key', headerval);
        request.setEndpoint('callout:Invoice_PDF_Retrieval'+endPointURL);
        request.setTimeout(60000);
        request.setHeader('Content-Type', 'application/json');        
        request.setMethod(method);
        Http http = new Http();
        HttpResponse response = http.send(request);
        return response;
    }

    /**
    * @description : method to create API Records for History Tracking of callout
    * @param  wrapObj
    * @return String
    */
    public static String createAPIrecs(WrapperListView wrapObj) {
        blng__Invoice__c inv = wrapObj.inv;
        String reqBody = wrapObj.reqBody;
        String responsebody = wrapObj.responsebody;
        String sObjName = wrapObj.sObjName;
        blng__CreditNote__c creditnote = wrapObj.creditnote;
        Boolean positiveResponse = wrapObj.positiveResponse;
        String externalSystem;
        API_Synchronization_Item__c apiSyncItems = new API_Synchronization_Item__c();
        if(sObjName=='blng__Invoice__c'){
            apiSyncItems.Invoice__c = inv.Id;
            apiSyncItems.Response_Body__c = (positiveResponse)?(inv.ERP_Reference__c + USCORE + inv.Legal_Entity_Code__c):responsebody;
            apiSyncItems.Opportunity__c = inv.OpportunityId__c;
            externalSystem = inv.blng__Order__r.Edition__r.X3rd_Party_ERP_System__c;
            apiSyncItems.X3rd_Party_ERP_System__c = externalSystem;
        }

        if(sObjName == 'blng__CreditNote__c'){
            apiSyncItems.Credit_Note__c = creditnote.Id;
            apiSyncItems.Response_Body__c = (positiveResponse)?(creditnote.ERPReference__c+USCORE+ creditnote.Legal_Entity__r.Legal_Entity_Code__c):responsebody;
            apiSyncItems.Opportunity__c = creditnote.blng__RelatedInvoice__r.OpportunityId__c;
            externalSystem = creditNote.blng__RelatedInvoice__r.blng__Order__r.Edition__r.X3rd_Party_ERP_System__c;
            apiSyncItems.X3rd_Party_ERP_System__c = externalSystem;
        }
        apiSyncItems.Status__c = (positiveResponse)?GlobalConstants.COMPLETED:GlobalConstants.ERROR;	
        apiSyncItems.API_Call_Type__c = 'GET';
        apiSyncItems.Type__c = 'Document Pull request from ERP';
        apiSyncItems.Request_Body__c = reqBody;
        apiSyncItems.Response_Code__c = wrapObj.responseCode;

        //create its Transaction record
        API_Synchronization_Transaction__c apiSyncTran = new API_Synchronization_Transaction__c();
        apiSyncTran.Status__c = (positiveResponse)?GlobalConstants.COMPLETED:'Completed With Errors';
        apiSyncTran.X3rd_Party_ERP_System__c = externalSystem;
        apiSyncTran.Started_From__c = (sObjName=='blng__Invoice__c')?'Invoice':'Credit Note';
        apiSyncTran.Type__c = 'GET';
        apiSyncTran.Request_Type__c = GlobalConstants.SYNCHRONOUS;
        if(Schema.sObjectType.API_Synchronization_Transaction__c.isCreateable()){
            insert apiSyncTran;
        }
        apiSyncItems.API_Synchronization_Transaction__c = apiSyncTran.Id;
        
        if(Schema.sObjectType.API_Synchronization_Item__c.isCreateable()){
            insert apiSyncItems;
        }
        return null;
    }

    /**
    * @description  wrapper method for hadling Response data.
    */
    public class WrapperListView {
        public blng__Invoice__c inv;
        public String reqBody;
        public String responsebody;
        public String sObjName;
        public blng__CreditNote__c creditnote;
        public Boolean positiveResponse;
        public String responseCode;

        /** @description to assing variabled on class initiation 
         * @param invtR
         * @param reqBodyR
         * @param responsebodyR
         * @param sObjNameR
         * @param creditnoteR
         * @param posResponse
         * @param responseCodeR
        */
        public wrapperListView(blng__Invoice__c invtR, String reqBodyR,String responsebodyR, String sObjNameR,blng__CreditNote__c creditnoteR,Boolean posResponse, String responseCodeR) {
            inv =  invtR;
            reqBody = reqBodyR;
            responsebody = responsebodyR;
            sObjName = sObjNameR;
            creditnote = creditnoteR;
            positiveResponse = posResponse;
            responseCode = responseCodeR;
        }
    }
}