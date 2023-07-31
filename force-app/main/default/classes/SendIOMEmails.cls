/**
* Created By       :   IBM(Bharath)
* Created On       :   9 May 2023
* @description     :   [GECI-1528]-Generic class for sending email with custom email tempalte
*                      
* Test Class       :   SendIOMEmails_Test(100%)
***********************************************************************************************
*/
public with sharing class SendIOMEmails {
    /**
    * @description  SendEmailTemplateWithTemplate
    * @param  crrecordId
    * @param  emailTemplate
    */
    @AuraEnabled
	public static void sendEmailTemplateWithTemplate(string crrecordId, string emailTemplate) {
        //system.Debug('recordId==>'+crrecordId);
        Global_Constant__mdt cmeta=[SELECT Id, DeveloperName, Label, Value__c, Description__c, MasterLabel FROM Global_Constant__mdt where DeveloperName='IOM_No_Reply'];

        String orgwideEmail = cmeta.Value__c;
        OrgWideEmailAddress orgEmail = [SELECT Id, Address, DisplayName, IsAllowAllProfiles, Purpose FROM OrgWideEmailAddress WHERE DisplayName=:orgwideEmail];

        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        EmailTemplate emailTemp = [SELECT Id, Subject, Body FROM EmailTemplate WHERE DeveloperName =: emailTemplate WITH SECURITY_ENFORCED];
        Change_Request__c cReq;
        Opportunity opp; 
        String targetEmail;
        Contact con = new Contact();
        if(emailTemplate == 'Amendment_Request_Rejection'){
        	cReq = [SELECT Id, Name, Account__c,Requested_By__c,Opportunity__c,Opportunity__r.Billing_Contact__c FROM Change_Request__c WHERE id=:crrecordId WITH SECURITY_ENFORCED];
            targetEmail = cReq.Requested_By__c;
            con.Id = cReq.Opportunity__r.Billing_Contact__c;
        }

        if(emailTemplate == 'Opportunity_Custom_Billing_Rejection'){
            opp = [SELECT Id,name,Sales_Person__c,Billing_Contact__c FROM Opportunity WHERE id=:crrecordId WITH SECURITY_ENFORCED];
            targetEmail=opp.Sales_Person__c;
            con.Id = opp.Billing_Contact__c;
        }

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTargetObjectId(con.Id);
        mail.setTreatTargetObjectAsRecipient(false);
        
        if(emailTemplate=='Amendment_Request_Rejection'){
            mail.setTemplateId(emailTemp.Id);
          	mail.setWhatId(cReq.Id);  
        }
        if(emailTemplate=='Opportunity_Custom_Billing_Rejection'){
            mail.setTemplateId(emailTemp.Id);
          	mail.setWhatId(opp.Id);  
        }
        //mail.setSenderDisplayName(orgEmail.DisplayName);
   		//mail.setReplyTo(orgEmail.Address);
        mail.setOrgWideEmailAddressId(orgEmail.Id);
        
        mail.setSaveAsActivity(false);
        mail.setToAddresses(new List<String>{targetEmail});
        emailList.add(mail);
        
        if(!emailList.isEmpty()){
            Messaging.sendEmail(emailList);
        }    
    }
    
}