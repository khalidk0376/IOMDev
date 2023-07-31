/**
* Created/Modified By    : Girikon(Arushi)
* Created On             : 8th July, 2022
* @description           : Using for Excel Report Export from Form Builder 
* Test Class             : IMCC_FormReportCTRL_Test 
* Code Coverage          : 97%
**/
public class IMCC_FormReportCTRL {
    
    /**
    * @description fetch Edition Details
    * @return List<Edition__c>
    */
    @AuraEnabled
    public static List<Edition__c> getEditions(){
        List<Edition__c> lstEdition = [SELECT Id, Name FROM Edition__c WHERE Edition_Status__c='Confirmed' AND Customer_Center_Status__c =: 'Active' AND Form_Setting__c !='' WITH SECURITY_ENFORCED];
        return lstEdition;
    }
    
    /**
    * @description fetch forms for selected edition
    * @param  editionId
    * @return Map<String,Object>
    */
    @AuraEnabled
    public static  Map<String,Object> formPicklistOptions(String editionId){
        List<Edition__c> editionLst = [SELECT Id, Name, Form_Setting__c FROM Edition__c WHERE Id =:String.escapeSingleQuotes(editionId) WITH SECURITY_ENFORCED LIMIT 1];
        
        List<Form_Allocation__c> formAllocLst = [SELECT Id, Name, Form_Setting__c, Form__c, Form__r.Name FROM Form_Allocation__c WHERE Form_Setting__c =: editionLst[0].Form_Setting__c AND Form__c != '' WITH SECURITY_ENFORCED];

        List<Purchase_Data__c> listPD = [SELECT Id, Booth_Number__c, Booth_Product_Type__c, Contact_Edition_Mapping__c FROM Purchase_Data__c WHERE Purchase_Status__c='Active' AND Transaction_Status__c='Active' AND Contact_Edition_Mapping__r.Edition__c=:editionId AND (Booth_Number__c<>null OR Booth_Number__c<>'') WITH SECURITY_ENFORCED];

        return new map<String, object>{
            'formAllocLst'=> formAllocLst,
            'listPD'=> listPD
        };
    }
    
    /**
    * @description fetch forms responses for selected edition
    * @param  editionId
    * @param  formAllocId
    * @param  qstIds
    * @param  entryIds
    * @return Map<String,Object>
    */
    @AuraEnabled
    public static Map<String,Object> getReportData(String editionId, String formAllocId,List<String> qstIds, List<Id> entryIds){
        String formTempId = getGirikonForm(formAllocId);
        Map<String,String> lstKeys = new Map<String,String>();
        List<Id> idSet = new List<Id>();
        
        List<Question_Questionnaire__c> quest;
        if(qstIds.isEmpty()){
            quest = [SELECT Question__c, Question__r.Label__c,Question_Group__r.Sort_Order__c,Question_Order__c,Related_To_Column__c FROM Question_Questionnaire__c WHERE Questionnaire__c=:formTempId AND is_Delete__c=false AND Question__r.Type__c!='Information' AND Question__r.Type__c!='Header/Footer' AND Question__c!=null WITH SECURITY_ENFORCED ORDER BY Question_Group__r.Sort_Order__c,Related_To_Column__c,Question_Order__c ASC];
        }
        else{
            quest = [SELECT Question__c, Question__r.Label__c,Question_Group__r.Sort_Order__c,Question_Order__c,Related_To_Column__c FROM Question_Questionnaire__c WHERE Question__c IN:qstIds WITH SECURITY_ENFORCED ORDER BY Question_Group__r.Sort_Order__c,Related_To_Column__c,Question_Order__c ASC];
        }
        
        for(Question_Questionnaire__c quest2 : quest){
            if(String.isNotBlank(quest2.Question__r.Label__c)){
                idSet.add(String.escapeSingleQuotes(quest2.Question__c));
                lstKeys.put(quest2.Question__c, quest2.Question__r.Label__c.stripHtmlTags());
            }
        }   
        
        Integer totalQuestions = (idSet.size()==0?(1):idSet.size());
        Integer maxEntry = (50000 / totalQuestions); 
        Integer soqlLimit = (maxEntry*totalQuestions);

        if(entryIds == null){
            entryIds = new List<Id>();
        }
        List<Form_Response_Entry__c> formResponseEntries = [SELECT Id FROM Form_Response_Entry__c WHERE Form_Data__r.Forms_Permission__r.Form_Allocation__c =: formAllocId AND Contact_Edition_Mapping__r.Edition__c=:editionId WITH SECURITY_ENFORCED];
        if(entryIds.isEmpty()){
            for(Form_Response_Entry__c fre : formResponseEntries){
                if(entryIds.size() == maxEntry){
                    break;
                }
                entryIds.add(fre.Id);
            }
        }
        
        List<Question_Response__c> questAns = [SELECT Id, Answer__c, Question__c, Question__r.Allow_Attachments__c, 
                                               Question__r.Type__c,Question__r.Is_MultiSelect__c, Form_Response_Entry__c, 
                                               Form_Response_Entry__r.Contact_Edition_Mapping__r.Account__r.Name, 
                                               Form_Response_Entry__r.Contact_Edition_Mapping__r.Contact__r.Name, 
                                               Form_Response_Entry__r.Contact_Edition_Mapping__r.Contact__r.Email, 
                                               Form_Response_Entry__r.Purchase_Data__c, Form_Response_Entry__r.Purchase_Data__r.Booth_Number__c, 
                                               Form_Response_Entry__r.Purchase_Data__r.Booth_Product_Type__c, Form_Response_Entry__r.Submission_Date__c,
                                               Form_Response_Entry__r.Contact_Edition_Mapping__c,Form_Response_Entry__r.Last_Modified_By__c,
                                               Form_Response_Entry__r.Last_Modified_By__r.Name,Form_Response_Entry__r.Last_Modified_Date__c,
                                               Form_Response_Entry__r.Response_Status__c, 
                                               (SELECT Id, Name FROM Attachments) FROM Question_Response__c WHERE Contact_Edition_Mapping__r.Edition__c=:editionId
                                               AND Form_Response_Entry__r.Form_Data__r.Forms_Permission__r.Form_Allocation__c =: formAllocId
                                               AND Question__c  IN:idSet AND Form_Response_Entry__c IN:entryIds WITH SECURITY_ENFORCED ORDER BY  Form_Response_Entry__c, Question_Questionnaire__r.Question_Group__c,Question__c ASC LIMIT:soqlLimit];

        Map<String, Question_Option__c> optionMap = new Map<String, Question_Option__c>([SELECT Id, Name,Question__c FROM Question_Option__c WHERE Name!='true' AND Name!='false' AND Question__c IN:idSet]);
        
        return new map<String, object>{
            'quest'=> quest,
            'questAns'=> questAns,
            'lstKeys'=> lstKeys,
            'optionMap'=> optionMap,
            'formResponseEntries'=> formResponseEntries,
            'maxEntry'=> maxEntry
        };
    }

    /**
    * @description fetch forms Questions
    * @param  formAllocId
    * @return List<Question_Questionnaire__c>
    */
    @AuraEnabled
    public static List<Question_Questionnaire__c> getFormQuestions(String formAllocId){
        String formTempId = getGirikonForm(formAllocId);
        
        List<Question_Questionnaire__c> quest = [SELECT Question__c, Question__r.Label__c,Question_Group__r.Sort_Order__c,Question_Order__c,Related_To_Column__c FROM Question_Questionnaire__c WHERE Questionnaire__c=:formTempId AND is_Delete__c=false AND Question__r.Type__c!='Information' AND Question__r.Type__c!='Header/Footer' AND Question__c!=null WITH SECURITY_ENFORCED ORDER BY Question_Group__r.Sort_Order__c,Related_To_Column__c,Question_Order__c ASC];
        
        return quest;
    }
    
    /**
    * @description fetch form id from form Allocation
    * @param  formAllocId
    * @return String
    */
    @AuraEnabled
    public static String getGirikonForm(String formAllocId){
        String formTemplateId;
        if(String.isNotBlank(formAllocId)){
            List<Form_Allocation__c> formAllocLst = [SELECT Id, Name, Form__c FROM Form_Allocation__c WHERE Id=: formAllocId AND Form__c != '' WITH SECURITY_ENFORCED LIMIT 1];
            if(!formAllocLst.isEmpty()){
                formTemplateId = formAllocLst[0].Form__c;
            }
        }
        return formTemplateId;
    }
    
    /**
    * @description Save chunk of file
    * @param  parentId
    * @param  fileId
    * @param  base64Data
    * @return Id id of file
    */
    @AuraEnabled
    public static Id saveChunk(String parentId, String fileId, String base64Data) {
        System.debug(Logginglevel.Debug, 'fileId=='+fileId);
        System.debug(Logginglevel.Debug, 'base64Data=='+base64Data);
           
        if (fileId == '') {        	
            fileId = saveTheFile(parentId, base64Data);
        } 
        else {
            appendToFile(fileId, base64Data);
        }
 
        return Id.valueOf(fileId);
    }
    
    /**
    * @description Save file
    * @param  parentId
    * @param  base64Data
    * @return Id id of file
    */
    public static Id saveTheFile(Id parentId, String base64Data) {
        base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8'); 
        Attachment attObj = new Attachment();        
        attObj.ParentId = parentId;
		attObj.Description = 'Online form report';
		attObj.Body = EncodingUtil.base64Decode(base64Data);
		attObj.Name = 'Online form.xls';
		attObj.ContentType = 'application/vnd.ms-excel';		
        SObjectAccessDecision sd = Security.stripInaccessible(AccessType.CREATABLE, new List<Attachment>{attObj});
        Insert sd.getRecords();    
        return sd.getRecords()[0].Id;
    }
 
    private static void appendToFile(Id fileId, String base64Data) {
        base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
        Attachment a = [SELECT Id, Body FROM Attachment WHERE Id =:String.escapeSingleQuotes(fileId) WITH SECURITY_ENFORCED];
        String existingBody = EncodingUtil.base64Encode(a.Body);
        if(Schema.SObjectType.Attachment.Fields.Body.isUpdateable()){
            a.Body = EncodingUtil.base64Decode(existingBody + base64Data);     
        }
        if(Schema.SObjectType.Attachment.isUpdateable()){
            Update Security.stripInaccessible(AccessType.UPDATABLE, new List<Attachment>{a}).getRecords();            
        }    
    }

    /**
    * @description Send report in email
    * @param  emails
    * @param  emailSub
    * @param  emailBody
    * @param  attId
    */
    @AuraEnabled(cacheable=false)
    public static void sendMail(List<String> emails, String emailSub, String emailBody,String attId){
        
        string userId = UserInfo.getUserId();
        User u = [Select id,email from User where id =: userId WITH SECURITY_ENFORCED];
       
        //system.debug('Get Content ' +ref.getContent())
        Blob b = Blob.valueOf('test');
        if(attId!=null && attId!=''){
            b = [Select Body From Attachment Where Id=:attId][0].Body;
        }
        // Define the email
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        String[] ccAddresses = new String[] {u.email};
        email.setHtmlBody(emailBody); 
        email.setSubject(emailSub); 
        email.setToAddresses(emails);
        email.setccAddresses(ccAddresses);
        system.debug(Logginglevel.Debug, emails);
        // Create the email attachment    
        Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
        efa.setFileName('OnlineFormReport.xls');
        efa.setBody(b);
        efa.setContentType('application/vnd.ms-excel');
        efa.setInline(true);
        // Attach file using setFileAttachments function
        email.setFileAttachments(new Messaging.EmailFileAttachment[] {efa});
        
        // Sends the email
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
    }   
}