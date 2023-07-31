/*
* Created/Modified By: Girikon(Keertiraj)
* Created On:          10/11/2021
* Modified By:     Girikon(Garima)
* Modified On:          07/03/2022
* @description : This class is used to send form responses in emails.                   
* Test Class: IMCC_FBUtilsHelper_Test(87%)
*/

public with sharing class IMCC_FBUtilsHelper {
    
    public static Id getFormAllocation(Id formRespEntryId){
        List<Form_Response_Entry__c> listFormResp = new List<Form_Response_Entry__c>();
        Id formAllocId;
        
        try{
        If(formRespEntryId!=null){
            listFormResp = [SELECT Form_Data__r.Forms_Permission__r.Form_Allocation__c,Form_Data__r.Forms_Permission__r.Form_Allocation__r.Name,Form_Data__r.Forms_Permission__r.Form_Allocation__r.Form_Type__c FROM Form_Response_Entry__c WHERE Id=:formRespEntryId WITH SECURITY_ENFORCED];
        }

        System.debug(LoggingLevel.Debug, 'listFormResp'+listFormResp);
        
        if(!listFormResp.isEmpty()){
            formAllocId = listFormResp[0].Form_Data__r.Forms_Permission__r.Form_Allocation__c;
        }
        }
        catch (Exception ex) {
            HandleAllCustomException.logException(ex,'Form_Submission_Status__c', 'Form Submission Status');
        }
        return formAllocId;
    }
   
    public static List<String> getEmailIds(Id formAllocId){
        Form_Allocation__c formAlloc = new Form_Allocation__c();
        String emailTo;
        List<String> emailIds = new List<String>();
        List<Form_Allocation__c> formAllocList = new List<Form_Allocation__c>();
        
        try{
        If(formAllocId!=null && Schema.sObjectType.Form_Allocation__c.isAccessible()){
        formAllocList = [SELECT Id, Name, Email_To__c, Send_individual_forms__c, Form__c FROM Form_Allocation__c WHERE Id=:formAllocId];
        }
        if(!formAllocList.isEmpty()){
            formAlloc = formAllocList[0];
            if(formAlloc.Send_individual_forms__c==true){
                emailTo = formAlloc.Email_To__c;
                emailTo = emailTo.replaceAll('\\s+','').replace(';',',');
                emailIds = emailTo.split(',');
                System.debug('emailTo :'+emailTo);
                System.debug('emailIds1231 :'+emailIds);
            }
        }
        }
        catch (Exception ex) {
            HandleAllCustomException.logException(ex,'Form_Allocation__c', 'Form Allocation');
        }
        return emailIds;
    }
    
    public static void sendEmailFormResponse(Id formRespEntryId){
        List<Form_Response_Entry__c> listFormResp = [SELECT Content_Version__c,Form_Data__r.Forms_Permission__r.Form_Allocation__c,Approval_Status__c,Form_Data__r.Forms_Permission__r.Form_Allocation__r.Approval_Required__c,Contact_Edition_Mapping__r.Edition__r.Name,Girikon_Form__c,Girikon_Form__r.Name,Form_Data__r.Forms_Permission__r.Form_Allocation__r.Name,Form_Data__r.Forms_Permission__r.Form_Allocation__r.Form_Type__c FROM Form_Response_Entry__c WHERE Id=:formRespEntryId WITH SECURITY_ENFORCED];
        List<ContentVersion> files = [Select Id,Title,VersionData,FileType,FileExtension From ContentVersion Where Id=: listFormResp[0].Content_Version__c];
        Id formAllocId = getFormAllocation(formRespEntryId);
        List<String> emailIds = getEmailIds(listFormResp.get(0).Form_Data__r.Forms_Permission__r.Form_Allocation__c);

        Id userId = UserInfo.getUserId();
        Id formTemplateId;
        String formName;
        String editionName;
        System.debug(LoggingLevel.Debug, 'formAllocId :'+formAllocId);
        System.debug(LoggingLevel.Debug, 'emailIds :'+emailIds);
        
        try{
            String [] emailsAsArray = new String [emailIds.size()];
            Integer i = 0;
            for (String singleEmail: emailIds) {
                emailsAsArray[i++] = singleEmail;
            }

            if(!listFormResp.isEmpty()){
                editionName = listFormResp.get(0).Contact_Edition_Mapping__r.Edition__r.Name;
                formTemplateId = listFormResp.get(0).Girikon_Form__c;
                formName = listFormResp.get(0).Form_Data__r.Forms_Permission__r.Form_Allocation__r.Name;
            }
            
            if(!emailIds.isEmpty()){
                
                List<Messaging.SingleEmailMessage> mails =  new List<Messaging.SingleEmailMessage>();
                    if(listFormResp.get(0).Form_Data__r.Forms_Permission__r.Form_Allocation__r.Form_Type__c == 'Online'){
                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        List<String> quesRespId = new List<String>();
                        List<Attachment> attachLst = new List<Attachment>();
                        Map<String,Attachment> mapAttach = new Map<String,Attachment>();
                        String emailSubject;
                        if(listFormResp.get(0).Form_Data__r.Forms_Permission__r.Form_Allocation__r.Approval_Required__c == true && listFormResp.get(0).Approval_Status__c == 'Approved'){
                            emailSubject = 'Form Approved - '+ formName + ' : '+editionName;
                        }
                        else{
                            emailSubject = 'New form submitted - '+ formName + ' : '+editionName;
                        }
                        
                        String htmlValue = getTableEmailBody(formRespEntryId, userId); 
                        List<Question_Response__c> lst = getQuestionResponse(formRespEntryId,userId);
                        System.debug('List12333 :'+lst);
                        for(Question_Response__c qr : lst){
                            quesRespId.add(qr.Id);
                        }
                        System.debug('quesRespId :'+quesRespId);
                        if(!quesRespId.isEmpty()){
                        attachLst= [Select id,Name,Body,parentId from attachment where parentId IN : quesRespId with security_enforced order by CREATEDDATE ASC];
                        System.debug('attachLst 1:'+attachLst); 
                        for(Attachment attach : attachLst){
                            mapAttach.put(attach.parentId,attach);
                        }
                        System.debug('mapAttach :'+mapAttach);
                        }
                        
                         
                        mail.SetSubject(emailSubject);
                        mail.setHtmlBody(htmlValue);  
                        mail.setToAddresses(emailsAsArray);
                        List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
                        for(Attachment file: mapAttach.values()) {
                        Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                        efa.setContentType('application/pdf');
                        efa.setFileName(file.Name);
                        efa.setBody(file.Body);
                        attachments.add(efa);
                        }
                        mail.setFileAttachments(attachments);
                        mails.add(mail);
                    }
                    else if(listFormResp.get(0).Form_Data__r.Forms_Permission__r.Form_Allocation__r.Form_Type__c == 'PDF'){
                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        String emailSubject;
                        if(listFormResp.get(0).Form_Data__r.Forms_Permission__r.Form_Allocation__r.Approval_Required__c == true && listFormResp.get(0).Approval_Status__c == 'Approved'){
                            emailSubject = 'Form Approved - '+ formName + ' : '+editionName; 
                        }
                        else{
                            emailSubject = 'New form submitted - '+ formName + ' : '+editionName;  
                        }
                        String htmlValue = 'Please find the attached Submission';
                        mail.SetSubject(emailSubject);
                        mail.setHtmlBody(htmlValue);
                        mail.setToAddresses(emailsAsArray);
                        List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
                        for(ContentVersion file: files) {
                        Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                        efa.setFileName(file.Title+'.'+file.FileExtension);
                        efa.setBody(file.VersionData);
                        attachments.add(efa);
                        }
                        mail.setFileAttachments(attachments);
                        mails.add(mail);
                        }
                        Messaging.SendEmailResult[] results = Messaging.sendEmail(mails);
                        System.debug(LoggingLevel.Debug, 'results :'+results);
                    }
                
            }
        catch (Exception ex) {
            HandleAllCustomException.logException(ex,'Form_Allocation__c', 'Form Allocation');
        }
           
    }
    
    public static List<Question_Response__c> getQuestionResponse(Id formRespEntryId,Id userId){
        List<String> qestId= new List<String>();
        
        List<Question_Response__c> lst = new List<Question_Response__c>();
        //List<Attachment> attachLst = new List<Attachment>();
        try{
        lst = [SELECT Id,Answer__c, Question__c,Question__r.Label__c,Question__r.Type__c FROM 
                Question_Response__c WHERE Form_Response_Entry__c=:formRespEntryId and Question__r.Type__c NOt IN ('Information','Header/Footer') with security_enforced order by CREATEDDATE ASC];
        System.debug(LoggingLevel.Debug, 'lst1 '+lst);
        // for(Question_Response__c qr : lst){
        //     qestId.add(qr.Question__c);
        // }
        // if(!qestId.isEmpty()){
        //     Map<String,String> optionMap = new Map<String,String>();
        //     for(Question_Option__c  qo : [SELECT Id, Name_Long__c FROM Question_Option__c WHERE Question__c IN :qestId with security_enforced]){
        //         optionMap.put(qo.Id,qo.Name_Long__c);
        //     }
        //     for(Question_Response__c qr : lst){
        //         qr.Answer__c =  optionMap.containsKey(qr.Answer__c)?optionMap.get(qr.Answer__c):qr.Answer__c;
        //     }
        // }
        System.debug(LoggingLevel.Debug, 'lst '+lst);
        }catch (Exception ex) {
            HandleAllCustomException.logException(ex,'Question_Option__c', 'Question Option');
        }
            
        return lst;
    }
    
    public static String getTableEmailBody(Id formRespEntryId, Id userId){
        List<Question_Response__c> lst = getQuestionResponse(formRespEntryId,userId);
        List<String> qestId= new List<String>();
        Map<String,String> optionMap = new Map<String,String>();
        for(Question_Response__c quesRes : lst){
            if(quesRes.Question__r.Type__c == 'Picklist'){
                qestId.add(quesRes.Question__c);
            }
        }
        if(!qestId.isEmpty()){
               
               for(Question_Option__c  qo : [SELECT Id, Name_Long__c,Question__c FROM Question_Option__c WHERE Question__c IN :qestId with security_enforced]){
                    optionMap.put(qo.Id,qo.Name_Long__c);
                 }
                
             }
        String nameOfUser;
        List<User> lstUsr = new List<User>();
        String htmlBody='';
        try{
            if(userId!=null && Schema.sObjectType.User.isAccessible()){
                lstUsr = [Select Id,Name from User WHERE Id =:userId];  
            }     
            if(!lstUsr.isEmpty()){
                nameOfUser = lstUsr[0].Name;   
            }
            
            if(!lst.isEmpty()){
                htmlBody = 'New Form Submission Response from '+nameOfUser+'<br><br>';
                htmlBody += '<table border="1" style="border-collapse:collapse"><tr><th>Question</th><th>Answer</th></tr>';
                for(Question_Response__c qr:lst){
                    String question = qr.Question__r.Label__c;
                    String answer = optionMap.containsKey(qr.Answer__c)?optionMap.get(qr.Answer__c):qr.Answer__c;
                    htmlBody += '<tr><td>'+ question + '</td><td>' + answer + '</td></tr>';
                }
                htmlBody += '</table>';
            
                System.debug('Email Body: '+htmlBody);
            }
        }
        catch (Exception ex) {
            HandleAllCustomException.logException(ex,'Question_Response__c', 'Question Response');
        }
        return htmlBody;   
    }

}