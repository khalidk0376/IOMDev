/**
* File         :   CreditNoteRESTService 
* Project      :   Order & Billing Plateform
* Created Date :   25th Jan 2022
* Created By   :   Girikon(Suresh)
* Test Class   :   CreditNoteRESTService_Test
* ******************************************************************************************************
@description : Apex rest class to update CreditNote fields
*******************************************************************************************************
* Modification log : 
* 1.
*/
@RestResource(urlMapping='/Credit/*')
global with sharing class CreditNoteRESTService {
    private Static Final String FILTER_FIELD_API_METANAME = 'Credit_Note_External_No_Field';
    /**
* @description  This method is used to update CreditNote fields
* @param creditNumber Credit Note Number
* @param erpRefrence ERP Refrence Number
* @return String 
*/
    @HttpPatch
    global static ResponseData updateERPRefrenceNumOnCredit(string creditNumber,String erpRefrence) 
    {
        ResponseData resWrap = new ResponseData();
        resWrap.status = 'Unknown';
        resWrap.message = 'Invalid Request Data';
        if(String.isNotBlank(creditNumber))
        {
            // List<blng__CreditNote__c> creditList = new List<blng__CreditNote__c>([Select Id,Name,ERPReference__c,blng__Status__c,ERPSync_Status__c from blng__CreditNote__c where Name =: creditNumber WITH SECURITY_ENFORCED]);

            String filterFieldAPI = GlobalConstants.getValue(FILTER_FIELD_API_METANAME);
            filterFieldAPI = String.isNotBlank(filterFieldAPI)?filterFieldAPI:'Name';
            List<blng__CreditNote__c> creditList = Database.query('Select Id,Name,ERPReference__c,blng__Status__c,ERPSync_Status__c from blng__CreditNote__c where '+String.escapeSingleQuotes(filterFieldAPI)+' = \''+String.escapeSingleQuotes(creditNumber)+'\'');

            resWrap.status = 'Error';
            resWrap.message = 'No Credit Note found with Credit Note Number '+creditNumber;
            if(!creditList.isEmpty() && Schema.sObjectType.blng__CreditNote__c.isUpdateable())
            {   
                blng__CreditNote__c cnote = new blng__CreditNote__c(Id=creditList.get(0).Id);
                cnote.ERPReference__c = erpRefrence;
                cnote.ERPSync_Status__c = 'Synced';
                
                update cnote;
                resWrap.status = 'Success';
                resWrap.message = 'ERP Refrence updated successfully';
            }
        }
        return resWrap;
    }

    /**
    * @description  This Class is to return Reponse Data
    */
    global class ResponseData 
    {
        public String status;	        // Success / Error /Unknown
		public String message;	        // 006
    }
    
}