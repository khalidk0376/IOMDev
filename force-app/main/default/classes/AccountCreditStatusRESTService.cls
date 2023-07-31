/**
* File         :   AccountingCreditStatusRESTService 
* Project      :   Order & Billing Plateform
* Created Date :   31th Nov 2021
* Created By   :   Girikon(Ashish)
* Test Class   :   AccountRESTService_Test(100%)
******************************************************************************************************
@description : Apex rest class to update Account Fileds
*******************************************************************************************************
* Modification log : 
* 1.
*/
@RestResource(urlMapping='/accountcreditstatus/*')
global with sharing class AccountCreditStatusRESTService {
    /**
* @description  This method is used to update Accounting Credit Status
* @param imAccountNumber IM Account Number
* @param creditStatus Credit Status [Hold,Warning,OK]
* @return String 
*/
    @HttpPatch
    global static ResponseData updateCreditStatusOnAccount(string imAccountNumber,String creditStatus) 
    {
        ResponseData resWrap = new ResponseData();
        resWrap.status = 'Unknown';
        resWrap.message = 'Invalid Request Data';
        try {
            if(String.isNotBlank(imAccountNumber))
            {
                List<Account> accList = new List<Account>([Select Id,Name,Accounting_Credit_Hold__c from Account where IM_Account_No__c =: imAccountNumber WITH SECURITY_ENFORCED]);
                resWrap.status = 'Error';
                resWrap.message = 'No Account found with IM Account Number '+imAccountNumber;
                if(!accList.isEmpty() && Schema.sObjectType.Account.isUpdateable())
                {   
                    Account acc = new Account(Id=accList.get(0).Id);
                    acc.Accounting_Credit_Hold__c = creditStatus;
                    update acc;

                    resWrap.status = 'Success';
                    resWrap.message = 'Credit Status successfully updated to '+creditStatus;
                }
            }
        }catch (Exception e) 
        {
            resWrap.status = 'Error';resWrap.message = e.getMessage();
            system.debug(logginglevel.DEBUG,'Error_Message__c --> '+ resWrap.message +' At Line' + e.getLineNumber()); system.debug(logginglevel.DEBUG,' Trace --> '+ e.getStackTraceString());
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
    // {"imAccountNumber":"IM-0027","creditStatus":"Hold"}
}