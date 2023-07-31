/**
* @description                 This class works as utility class and contains reusable methods for forms
* Created By:                  Girikon(Mukesh Gupta)
* Created On:          
* Modified By:                 Girikon(Garima Gupta,Arushi [IMCC-3944])
* Last Modified On:            2 Aug 2022  
* Modification description     Modified to add contact edition mapping lookup on Form Submission status record
* Methods:                     saveFormStatus,sendEmailAfterFormSubmission,insertRecords,updateRecords
* Apex Class:                  FBUtils 
* Apex Test Class:             FBUtilTest(90%)

Insert Security.stripInaccessible(AccessType.CREATABLE, ).getRecords();

Update Security.stripInaccessible(AccessType.UPDATABLE, ).getRecords();

Upsert Security.stripInaccessible(AccessType.UPSERTABLE, ).getRecords();
*/
public without sharing class FBUtils {
    
    /**
* @description  to update form response entry status.
* @param  param
* @return Form_Response_Entry__c  
*/
    public static Form_Response_Entry__c saveFormStatus(Map<String,String> param){
        //get params and save in diff variables
        String status = param.get('status');
        String qId = param.get('qId'); 
        String pageId = param.get('pageId'); 
        Decimal currentPageNo = Decimal.valueOf(param.get('pageNo'));
        Decimal totalPages = Decimal.valueOf(param.get('totalPages'));
        String conEdMapId = param.get('conEdMapId');
        String formDataId = param.get('formDataId');
        String entryId = param.get('entryId');
        String boothId = param.get('boothId');
        String version = param.get('version');
        String recieveEmailCopyToCustomer = param.get('recieveEmailCopy');
        String additionalEmails = param.get('additionalEmails');
        String contentVerId;
        String fileName;
        Boolean isUpdate = false;
        Boolean isUpdateFD = false;
        if(boothId == ''){
            boothId = null;
        }
        
        List<Form_Data__c> listFormData = [SELECT Id,Forms_Permission__r.Form_Allocation__r.Feature_Category__c,Forms_Permission__r.Form_Allocation__r.Form_Entry__c,Forms_Permission__r.Form_Allocation__r.Entry_Limit__c,Forms_Permission__r.Form_Allocation__r.Approval_Required__c,Status1__c,Forms_Permission__r.Form_Allocation__r.Form_Type__c,tolabel(Forms_Permission__r.Form_Allocation__r.Booth_Product_Types__c) FROM Form_Data__c WHERE Id=:formDataId WITH SECURITY_ENFORCED LIMIT 1];
        
        Form_Data__c fd = (listFormData.isEmpty()?(new Form_Data__c()):listFormData.get(0));
        String formDataStatus = 'Not Started';
        
        List<Form_Response_Entry__c> formResponseEntryLst = new List<Form_Response_Entry__c>();
        if(fd.Forms_Permission__r.Form_Allocation__r.Feature_Category__c == 'Form'){
            //if- (entryId and boothId are blank then SOQL will return formResponseEntryLst of Multiple Per Account) or (entryId is blank and boothId is not then SOQL will return formResponseEntryLst of Multiple Per Booth)
            //else- entryId is not blank and Form_Allocation__r.Form_Type__c is equals tp PDF and formResponseEntryLst is not empty then get ContentDocumentLink if exist then delete the existing one and from its ContentVersion list update the variables of contentVerId and fileName
            if(String.isBlank(entryId)){
                if(String.isBlank(boothId)){
                    formResponseEntryLst = [SELECT Id,Rejection_Reason__c,Form_Data__c,Current_Page__c,Current_Page_No__c,Contact_Edition_Mapping__c,Girikon_Form__c,Total_Pages__c,Approval_Status__c,Status__c,Entry_Number__c,Form_Data__r.Forms_Permission__r.Form_Allocation__r.Submission_Deadline__c,Form_Data__r.Forms_Permission__r.Form_Allocation__r.Allow_Submissions_after_Due_date__c,Form_Data__r.Forms_Permission__r.Form_Allocation__r.Approval_Required__c,Form_Unlock__c,Version__c FROM Form_Response_Entry__c WHERE Contact_Edition_Mapping__c =:conEdMapId AND Status__c='Viewed' AND Form_Data__c=:formDataId WITH SECURITY_ENFORCED LIMIT 1];
                }
                else{
                    formResponseEntryLst = [SELECT Id,Rejection_Reason__c,Form_Data__c,Current_Page__c,Current_Page_No__c,Contact_Edition_Mapping__c,Girikon_Form__c,Total_Pages__c,Approval_Status__c,Status__c,Entry_Number__c,Form_Data__r.Forms_Permission__r.Form_Allocation__r.Submission_Deadline__c,Form_Data__r.Forms_Permission__r.Form_Allocation__r.Allow_Submissions_after_Due_date__c,Form_Data__r.Forms_Permission__r.Form_Allocation__r.Approval_Required__c,Form_Unlock__c,Version__c FROM Form_Response_Entry__c WHERE Contact_Edition_Mapping__c =:conEdMapId AND Status__c='Viewed' AND Form_Data__c=:formDataId AND Purchase_Data__c=:boothId WITH SECURITY_ENFORCED LIMIT 1];
                }
                // if- (Form_Allocation__r.Form_Entry__c is equals to One Per Account/One Per Booth and Form_Type__c not equals to Link then SOQL will return formResponseEntryLst of One Per Account/one Per Booth)or (Form_Type__c equals to Link)then SOQL will return formResponseEntryLst
                if(fd.Forms_Permission__r.Form_Allocation__r.Form_Type__c == 'Link' || (fd.Forms_Permission__r.Form_Allocation__r.Form_Type__c != 'Link' && (fd.Forms_Permission__r.Form_Allocation__r.Form_Entry__c == 'One Per Account' || fd.Forms_Permission__r.Form_Allocation__r.Form_Entry__c == 'One Per Booth'))){
                    formResponseEntryLst = [SELECT Id,Rejection_Reason__c,Form_Data__c,Current_Page__c,Current_Page_No__c,Contact_Edition_Mapping__c,Girikon_Form__c,Total_Pages__c,Approval_Status__c,Status__c,Entry_Number__c,Form_Data__r.Forms_Permission__r.Form_Allocation__r.Submission_Deadline__c,Form_Data__r.Forms_Permission__r.Form_Allocation__r.Allow_Submissions_after_Due_date__c,Form_Data__r.Forms_Permission__r.Form_Allocation__r.Approval_Required__c,Form_Unlock__c,Version__c FROM Form_Response_Entry__c WHERE Contact_Edition_Mapping__c =:conEdMapId AND Form_Data__c=:formDataId WITH SECURITY_ENFORCED LIMIT 1];
                }
            }
            else{
                formResponseEntryLst = [SELECT Id,Rejection_Reason__c,Form_Data__c,Current_Page__c,Current_Page_No__c,Contact_Edition_Mapping__c,Girikon_Form__c,Total_Pages__c,Approval_Status__c,Status__c,Entry_Number__c,Form_Data__r.Forms_Permission__r.Form_Allocation__r.Submission_Deadline__c,Form_Data__r.Forms_Permission__r.Form_Allocation__r.Allow_Submissions_after_Due_date__c,Form_Data__r.Forms_Permission__r.Form_Allocation__r.Approval_Required__c,Form_Unlock__c,Version__c FROM Form_Response_Entry__c WHERE Id=:entryId WITH SECURITY_ENFORCED LIMIT 1];
                //status = (formResponseEntryLst.get(0).Status__c=='Resubmitted'?'Submitted':formResponseEntryLst.get(0).Status__c);
                if(fd.Forms_Permission__r.Form_Allocation__r.Form_Type__c == 'PDF'){
                    List<ContentDocumentLink> cntnDocLinkLst;
                    List<ContentDocumentLink> cntnDocLinkDelLst = new List<ContentDocumentLink>();
                    if(!formResponseEntryLst.isEmpty()){
                        cntnDocLinkLst = [SELECT Id, LinkedEntityId, ContentDocumentId, SystemModstamp, Visibility, ShareType FROM ContentDocumentLink where LinkedEntityId=:formResponseEntryLst[0].Id WITH SECURITY_ENFORCED Order By SystemModstamp Desc];
                        
                    }
                    if(!cntnDocLinkLst.isEmpty()){
                        String latestContDocId = cntnDocLinkLst[0].Id;
                        for(ContentDocumentLink contDocLink : cntnDocLinkLst){
                            if(contDocLink.Id != latestContDocId){
                                cntnDocLinkDelLst.add(contDocLink);
                            }
                        }
                        
                        if(Schema.sObjectType.ContentDocumentLink.isDeletable()){
                            delete cntnDocLinkDelLst;
                        }
                        
                        List<ContentVersion> docmList = [select id,Title FROM ContentVersion where contentdocumentid=:cntnDocLinkLst[0].ContentDocumentId and IsLatest = true WITH SECURITY_ENFORCED];
                        if(!docmList.isEmpty()){
                            contentVerId = docmList[0].id;
                            fileName = docmList[0].Title;
                        }   
                    }
                }
            }
        }
        
        List<Form_Response_Entry__c> formResponseEntryLstAll = [SELECT Entry_Number__c,Status__c,Approval_Status__c FROM Form_Response_Entry__c WHERE Contact_Edition_Mapping__c =:conEdMapId AND Form_Data__c=:formDataId WITH SECURITY_ENFORCED ORDER BY Entry_Number__c DESC LIMIT 1];
        if(String.isNotBlank(boothId)){
            formResponseEntryLstAll = [SELECT Entry_Number__c,Status__c,Approval_Status__c FROM Form_Response_Entry__c WHERE Contact_Edition_Mapping__c =:conEdMapId AND Form_Data__c=:formDataId AND Purchase_Data__c=:boothId WITH SECURITY_ENFORCED ORDER BY Entry_Number__c DESC LIMIT 1];
        }
        List<Contact_Edition_Mapping__c> listCEM = [SELECT Id,Account__c,Contact__c,Edition__c,Access_Type__c FROM Contact_Edition_Mapping__c WHERE Id=:conEdMapId WITH SECURITY_ENFORCED];
        
        String approvalStatus = (fd.Forms_Permission__r.Form_Allocation__r.Approval_Required__c?(status!='Submitted'?null:'In Review'):'Not Required');
        
        if(fd.Forms_Permission__r.Form_Allocation__r.Feature_Category__c == 'Manual'){
            approvalStatus = null;
            formDataStatus = (status=='Viewed'?status:'Agreed');
            if(status == 'Viewed'){
                fd.Is_Viewed__c = true;
            }
            else{
                fd.Is_Agreed__c = true;
            }
            isUpdateFD = true;
            boothId = null;
            if(String.isBlank(entryId)){
                formResponseEntryLst = [SELECT Id,Rejection_Reason__c,Form_Data__c,Current_Page__c,Current_Page_No__c,Contact_Edition_Mapping__c,Girikon_Form__c,Total_Pages__c,Approval_Status__c,Status__c,Entry_Number__c,Form_Data__r.Forms_Permission__r.Form_Allocation__r.Submission_Deadline__c,Form_Data__r.Forms_Permission__r.Form_Allocation__r.Allow_Submissions_after_Due_date__c,Form_Data__r.Forms_Permission__r.Form_Allocation__r.Approval_Required__c,Form_Unlock__c,Version__c FROM Form_Response_Entry__c WHERE Contact_Edition_Mapping__c =:conEdMapId AND Form_Data__c=:formDataId WITH SECURITY_ENFORCED LIMIT 1];
            }
            else{
                formResponseEntryLst = [SELECT Id,Rejection_Reason__c,Form_Data__c,Current_Page__c,Current_Page_No__c,Contact_Edition_Mapping__c,Girikon_Form__c,Total_Pages__c,Approval_Status__c,Status__c,Entry_Number__c,Form_Data__r.Forms_Permission__r.Form_Allocation__r.Submission_Deadline__c,Form_Data__r.Forms_Permission__r.Form_Allocation__r.Allow_Submissions_after_Due_date__c,Form_Data__r.Forms_Permission__r.Form_Allocation__r.Approval_Required__c,Form_Unlock__c,Version__c FROM Form_Response_Entry__c WHERE Id=:entryId WITH SECURITY_ENFORCED LIMIT 1];
            }
        }  
        //if-formResponseEntryLst is empty then create Form_Response_Entry__c an add it to the formResponseEntryLst
        //else if - formResponseEntryLst is not empty and status is not viewed then update the formResponseEntryLst[0] fields
        if(formResponseEntryLst.isEmpty()){
            Form_Response_Entry__c fre = new Form_Response_Entry__c();
            fre.Girikon_Form__c = qId;
            fre.Status__c = status;
            fre.User__c = UserInfo.getUserId();
            fre.User_Type1__c = listCEM.get(0).Access_Type__c;
            fre.Contact_Edition_Mapping__c = conEdMapId;
            fre.Company_Name__c = listCEM.get(0).Account__c;
            fre.Event_Name__c = listCEM.get(0).Edition__c;
            fre.Ops_Contact_Name__c = listCEM.get(0).Contact__c;
            fre.Current_Page__c = pageId;   
            fre.Current_Page_No__c = currentPageNo;
            fre.Total_Pages__c = totalPages;
            fre.Form_Data__c = formDataId;
            fre.Approval_Status__c = approvalStatus;
            fre.Purchase_Data__c = boothId;
            fre.Receive_an_Email_Copy__c = recieveEmailCopyToCustomer != null ?Boolean.valueOf(recieveEmailCopyToCustomer):false;
            fre.Additional_Emails__c = additionalEmails;
            fre.Last_Modified_By__c = UserInfo.getUserId();
            fre.Last_Modified_Date__c = system.now();
            fre.Entry_Number__c = (formResponseEntryLstAll.isEmpty()?(1):(formResponseEntryLstAll.get(0).Entry_Number__c+1));
            formResponseEntryLst.add(fre);
            isUpdate = true;
        }
        else if(status != 'Viewed'){
            String approvalStatusTemp = formResponseEntryLst[0].Approval_Status__c;
            String rejectionReason = formResponseEntryLst[0].Rejection_Reason__c;
            String statusTemp = (((String.isNotBlank(rejectionReason) || formResponseEntryLst[0].Form_Unlock__c) && status!='In Progress')?'Resubmitted':((approvalStatusTemp=='Rejected' || approvalStatusTemp=='Approved')?(status!='In Progress'?'Resubmitted':status):status));
            formResponseEntryLst[0].Status__c = statusTemp;
            formResponseEntryLst[0].Current_Page__c = pageId;
            formResponseEntryLst[0].Current_Page_No__c = currentPageNo;
            formResponseEntryLst[0].Total_Pages__c = totalPages;
            formResponseEntryLst[0].Approval_Status__c = approvalStatus;
            formResponseEntryLst[0].Receive_an_Email_Copy__c = recieveEmailCopyToCustomer != null?Boolean.valueOf(recieveEmailCopyToCustomer): false;
            formResponseEntryLst[0].Additional_Emails__c = additionalEmails;
            formResponseEntryLst[0].User_Type1__c = listCEM.get(0).Access_Type__c;
            formResponseEntryLst[0].Last_Modified_By__c = UserInfo.getUserId();
            formResponseEntryLst[0].Last_Modified_Date__c = system.now();
            if(fd.Forms_Permission__r.Form_Allocation__r.Form_Type__c == 'PDF'){
                formResponseEntryLst[0].Content_Version__c = contentVerId;
                formResponseEntryLst[0].File_Name__c = fileName;
            }
            if(status == 'Submitted'){
                formResponseEntryLst[0].Version__c += 1;
                formResponseEntryLst[0].Form_Unlock__c = false;
                formResponseEntryLst[0].Submission_Date__c = system.today();
            }
            isUpdate = true;
        }
        //if- (isUpdate == true) then update the formResponseEntryLst
        if(isUpdate && Schema.sObjectType.Form_Response_Entry__c.isUpdateable() && Schema.sObjectType.Form_Response_Entry__c.isCreateable()){
            Upsert formResponseEntryLst;
        }
        // if- (Form_Allocation__r.Feature_Category__c == 'Form') update the status acc to the form type 
        if(fd.Forms_Permission__r.Form_Allocation__r.Feature_Category__c == 'Form'){
            if(fd.Forms_Permission__r.Form_Allocation__r.Form_Type__c == 'Link'){
                formResponseEntryLstAll = [SELECT Entry_Number__c,Status__c,Approval_Status__c FROM Form_Response_Entry__c WHERE Contact_Edition_Mapping__c =:conEdMapId AND Form_Data__c=:formDataId WITH SECURITY_ENFORCED ORDER BY Entry_Number__c DESC];
                if(!formResponseEntryLstAll.isEmpty()){
                    formDataStatus = formResponseEntryLstAll[0].Status__c;
                }
                isUpdateFD = true;
            }
            
            if(fd.Forms_Permission__r.Form_Allocation__r.Form_Type__c != 'Link' && (fd.Forms_Permission__r.Form_Allocation__r.Form_Entry__c == 'One Per Account' || fd.Forms_Permission__r.Form_Allocation__r.Form_Entry__c == 'One Per Booth')){
                formResponseEntryLstAll = [SELECT Entry_Number__c,Status__c,Approval_Status__c FROM Form_Response_Entry__c WHERE Contact_Edition_Mapping__c =:conEdMapId AND Form_Data__c=:formDataId WITH SECURITY_ENFORCED ORDER BY Entry_Number__c DESC];
                if(!formResponseEntryLstAll.isEmpty()){
                    String tempStatus = formResponseEntryLstAll[0].Status__c;
                    formDataStatus = (tempStatus=='Viewed'?tempStatus:(fd.Forms_Permission__r.Form_Allocation__r.Approval_Required__c?((tempStatus!='Submitted' && tempStatus!='Resubmitted')?tempStatus:'In Review'):tempStatus));
                }
                isUpdateFD = true;
            }
            
            if(fd.Forms_Permission__r.Form_Allocation__r.Form_Type__c != 'Link' && (fd.Forms_Permission__r.Form_Allocation__r.Form_Entry__c == 'Multiple Per Account' || fd.Forms_Permission__r.Form_Allocation__r.Form_Entry__c == 'Multiple Per Booth')){
                formResponseEntryLstAll = [SELECT Entry_Number__c,Status__c,Approval_Status__c FROM Form_Response_Entry__c WHERE Contact_Edition_Mapping__c =:conEdMapId AND Form_Data__c=:formDataId WITH SECURITY_ENFORCED ORDER BY Entry_Number__c DESC];
                for(Form_Response_Entry__c fre : formResponseEntryLstAll){
                    if(fd.Forms_Permission__r.Form_Allocation__r.Approval_Required__c){
                        if(fre.Status__c == 'Viewed' && formDataStatus == 'Not Started'){
                            formDataStatus = fre.Status__c;
                        }
                        if(fre.Status__c == 'In Progress' && formDataStatus != 'In Review' && formDataStatus != 'Approved'){
                            formDataStatus = fre.Status__c;
                        }
                        if((fre.Status__c == 'Submitted' || fre.Status__c == 'Resubmitted') && fre.Approval_Status__c == 'In Review' && formDataStatus != 'Approved'){
                            formDataStatus = 'In Review';
                        }
                        if((fre.Status__c == 'Submitted' || fre.Status__c == 'Resubmitted') && fre.Approval_Status__c == 'Rejected' && formDataStatus != 'In Review' && formDataStatus != 'Approved'){
                            formDataStatus = 'Rejected';
                        }
                        if((fre.Status__c == 'Submitted' || fre.Status__c == 'Resubmitted') && fre.Approval_Status__c == 'Approved'){
                            formDataStatus = 'Approved';
                        }
                    }
                    else{
                        if(fre.Status__c == 'Viewed' && formDataStatus == 'Not Started'){
                            formDataStatus = fre.Status__c;
                        }
                        if(fre.Status__c == 'In Progress' && formDataStatus != 'Submitted'){
                            formDataStatus = fre.Status__c;
                        }
                        if(fre.Status__c == 'Submitted' || fre.Status__c == 'Resubmitted'){
                            formDataStatus = fre.Status__c;
                        }
                    }
                }
                isUpdateFD = true;
            }
        }
        //if- isUpdateFD == true then update the formResponseEntryLst
        if(isUpdateFD && Schema.sObjectType.Form_Data__c.isUpdateable()){
            fd.Status1__c = formDataStatus;
            update fd;
        }
        
        return formResponseEntryLst.isEmpty()?(new Form_Response_Entry__c()):([SELECT Id,Form_Data__c,Current_Page__c,Current_Page_No__c,Contact_Edition_Mapping__c,Girikon_Form__c,Total_Pages__c,Approval_Status__c,Status__c,Entry_Number__c,Form_Data__r.Forms_Permission__r.Form_Allocation__r.Submission_Deadline__c,Form_Data__r.Forms_Permission__r.Form_Allocation__r.Allow_Submissions_after_Due_date__c,Form_Data__r.Forms_Permission__r.Form_Allocation__r.Approval_Required__c,Form_Unlock__c,Version__c,Form_Data__r.Forms_Permission__r.Form_Allocation__r.Send_Response_to_Customer__c FROM Form_Response_Entry__c WHERE Id=:formResponseEntryLst[0].Id WITH SECURITY_ENFORCED LIMIT 1]);
    }
    
    /**
    * @description  use to send Email After FormSubmission
    * @param  qnaireId
    * @return Boolean  
    */
    public static Boolean sendEmailAfterFormSubmission(String qnaireId){
        return true;
    }
    
    /**
* @description  use to insert Records
* @param  objectName
* @param  recordsToInsert
* @return FBResponse  
*/
    public static FBResponse insertRecords(String objectName,Map<Integer,List<KeyValuePair>> recordsToInsert)
    {
        if(objectName.indexOf('__c')>0){
            objectName = ''+objectName;
        }
        
        Schema.SObjectType obj = Schema.getGlobalDescribe().get(objectName);
        List<sObject> recordToInsertList = new List<sObject>();
        FBResponse response = new FBResponse();
        //return recordToInsertList with sObject
        for(Integer key : recordsToInsert.keySet())
        {
            sObject genericObj = obj.newSObject();
            //genericObj with keyValueObj.fieldName,keyValueObj.fieldValue
            for(KeyValuePair keyValueObj : recordsToInsert.get(key)){ 
                keyValueObj.fieldValue = keyValueObj.fieldValue=='null'?'':keyValueObj.fieldValue;
                genericObj.put(keyValueObj.fieldName,keyValueObj.fieldValue);
            }
            recordToInsertList.add(genericObj);
        }
        //try- update recordToInsertList
        //catch- get error message
        try
        {
            SObjectAccessDecision secDec = Security.stripInaccessible(AccessType.CREATABLE, recordToInsertList);
            
            //System.debug(JSON.serialize(secDec.getRecords()));
            Database.insert(secDec.getRecords(), false);
            response.isSuccess=true; 
            response.firstRecordId = secDec.getRecords()[0].Id;
        }
        catch(Exception e)
        {
            response.isSuccess=false;
            response.message = e.getMessage();
        }
        return response;
    }
    
    
    /**
* @description  use to update Records
* @param  objectName
* @param  recordsToInsert
* @return FBResponse  
*/
    public static FBResponse updateRecords(String objectName,Map<Integer,List<KeyValuePair>> recordsToInsert)
    {
        if(objectName.indexOf('__c')>0){
            objectName = ''+objectName;
        }
        Schema.SObjectType obj = Schema.getGlobalDescribe().get(objectName);
        List<sObject> recordToInsertList = new List<sObject>();
        FBResponse response = new FBResponse();
        //return recordToInsertList with sObject
        for(Integer key : recordsToInsert.keySet())
        {
            sObject genericObj = obj.newSObject();
            //genericObj with keyValueObj.fieldName,keyValueObj.fieldValue
            for(KeyValuePair keyValueObj : recordsToInsert.get(key)){                
                keyValueObj.fieldValue = keyValueObj.fieldValue=='null'?'':keyValueObj.fieldValue;
                genericObj.put(keyValueObj.fieldName,keyValueObj.fieldValue);
            }
            recordToInsertList.add(genericObj);
        }
        //try- update recordToInsertList
        //catch- get error message
        try
        {
            SObjectAccessDecision secDec = Security.stripInaccessible(AccessType.UPDATABLE, recordToInsertList);            
            Database.update(secDec.getRecords(), true);
            response.isSuccess=true;            
        }
        catch(Exception e)
        {
            response.isSuccess=false;            
            response.message = e.getMessage();
        }
        return response;
    }    
    
    /**
* @description  use to get sub string of params
* @param  str
* @param  intVal
* @return String  
*/
    public static String subStr(String str, Integer intVal){
        //if- string is not blank return substring
        ////else- return string
        if(String.isNotBlank(str) &&  str.length() > intVal){
            return str.substring(0, intVal);
        }else {
            return str;
        }
    }
    
    /**@description  FBResponse*/
    public class FBResponse{
        public Boolean isSuccess;
        public String message;
        public String firstRecordId;
        public String flsError;
        public String entryNumber;
    }
    
    /**@description  KeyValuePair*/
    public class KeyValuePair{
        public string fieldName;
        public Object fieldValue;
        
        /**
* @description  KeyValuePair constructor
* @param  fieldName
* @param  fieldValue
*/
        public KeyValuePair(string fieldName,Object fieldValue){
            this.fieldName = fieldName;
            this.fieldValue = fieldValue;
        }
    }
    
    /**
* @description  use to insert the question Library
* @return Question_Library__c  
*/
    public static Question_Library__c questionLibrary(){
        Question_Library__c oQL= new Question_Library__c(Name='Global Default',Name__c='Global Default');
        if(Schema.SObjectType.Question_Library__c.isCreateable()){
            insert oQL;
        }
        return oQL;
    } 
    
    /**
* @description  use to create Question
* @param qlId
* @return Question__c  
*/
    public static Question__c createQst(Id qlId){
        //Question__c record by its Id
        Question__c oQue = new Question__c(Name='Test',Help_Text_Required__c=true, Name__c='Test 1', Help_Text__c='Test Help Text', Label__c='Question 1',Question_Library__c=qlId, Required__c=true, Type__c='TextPlain',Allow_Comment__c=true,Allow_Attachments__c=true);
        if(Schema.SObjectType.Question__c.isCreateable()){
            insert oQue;
        }
        return oQue;
    }
}