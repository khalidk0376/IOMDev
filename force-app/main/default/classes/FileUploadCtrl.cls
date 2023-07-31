/**
* Created/Modified By: Girikon(Mukesh)
* Created On:          9/14/2021
* @description : This class use to upload media file from online form. 
* Modified By:   Girikon(Arushi [IMCC-3994])
* Modified On:   5/08/2022,[IMCC-4762 22-11-2022 by Aishwarya, - added new parameter isAllowMutliple]       
* @description : This class use to upload media file from online form.                   
* Test Class: FileUploadCtrlTest(97%)
*/

public without sharing class FileUploadCtrl 
{
    /**
    * @description  to update form response entry with attachment.
    * @param   entryId
    * @param ceid
    * @param questionId
    * @param questionerId
    * @param questionQuestionnairesId
    * @param fileName
    * @param base64Data
    * @param contentType
    * @param fileId
    * @param fileDescription
    * @param version
    * @param  isAllowMutliple
    * @return String  
    */
    @AuraEnabled
    public static String saveChunk(String entryId,String ceid,String questionId, String questionerId,String questionQuestionnairesId, String fileName, String base64Data, String contentType, String fileId,String fileDescription, String version,boolean isAllowMutliple) {
        //String userId = UserInfo.getUserId();
        // check if fileId id ''(Always blank in first chunk), then call the saveTheFile method,
        //  which is save the check data and return the attachemnt Id after insert, 
        //  next time (in else) we are call the appentTOFile() method
        //   for update the attachment with reamins chunks   
        if (fileId == '') {
            String parentId = getReponseId(entryId,ceid,questionId,questionerId,questionQuestionnairesId,fileName,version,isAllowMutliple);
            fileId = saveTheFile(parentId, fileName, base64Data, contentType,fileDescription);
        } else {
            appendToFile(fileId, base64Data);
        }
        //system.debug('fileId=='+ fileId);
        if(fileId != '' && fileId != null){
            return fileId;
        }
        else{
            //id fileId is null return exception
            throw new AuraHandledException('File has been updated from another place. Please refresh your page.');
        }
        
    }
    
    /**
    * @description  to save the file in attachment.
    * @param  parentId
    * @param  fileName
    * @param  base64Data
    * @param  contentType
    * @param  fileDescription
    * @return Id  
    */
    public static Id saveTheFile(Id parentId, String fileName, String base64Data, String contentType,String fileDescription) {
        Id returnId; //retunId when parentId is null 
        base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8'); 
        Attachment attObj = new Attachment(); 
        //if-parentId is not null and parentId is return value from getResponseId which is Form Response Entry Id
        if(parentId != null){
            if(Schema.SObjectType.Attachment.Fields.ParentId.isCreateable()){
                attObj.ParentId = parentId;
            }
            if(Schema.SObjectType.Attachment.Fields.Description.isCreateable()){
                attObj.Description = fileDescription;
            }
            if(Schema.SObjectType.Attachment.Fields.Body.isCreateable()){
                attObj.Body = EncodingUtil.base64Decode(base64Data);
            }
            if(Schema.SObjectType.Attachment.Fields.Name.isCreateable()){
                attObj.Name = fileName;
            }
            if(Schema.SObjectType.Attachment.Fields.ContentType.isCreateable()){
                attObj.ContentType = contentType;
            }        
            SObjectAccessDecision sd = Security.stripInaccessible(AccessType.CREATABLE, new List<Attachment>{attObj});
            Insert sd.getRecords();    
            return sd.getRecords()[0].Id;
        } 
        else{
            //return returnId if the FRE id is null
            return returnId; 
        }
    }
    
    /**
    * @description  to append the file.
    * @param  fileId
    * @param  base64Data
    */
    private static void appendToFile(Id fileId, String base64Data) {
        //it will append the file
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
    * @description  to get the response Id of Rorm Response Entry.
    * @param  entryId
    * @param  ceid
    * @param  questionId
    * @param  questionerId
    * @param  questionQuestionnairesId
    * @param  fileName
    * @param  version
    * @param  isAllowMutliple
    * @return String  
    */
    @TestVisible
    private static String getReponseId(String entryId,String ceid,String questionId,String questionerId,String questionQuestionnairesId,String fileName,String version,boolean isAllowMutliple)
    {
        List<Question_Response__c> objList = Database.query('SELECT Id, Form_Response_Entry__c,Form_Response_Entry__r.Version__c,Answer_Long__c FROM Question_Response__c WHERE Form_Response_Entry__c=\''+String.escapeSingleQuotes(entryId)+'\' AND Contact_Edition_Mapping__c=:ceid AND Question__c=:questionId AND Question_Questionnaire__c=:questionQuestionnairesId AND Questionnaire__c=:questionerId WITH SECURITY_ENFORCED');
        // if- response exist then return id otherwise create a new response using loggedin user
        // else-response exist then return id if the form version is same else return null to restrict the users for updating the fre on same time with diff tabs
        if(objList.isEmpty()){
            
            List<FBUtils.KeyValuePair> listObj = new List<FBUtils.KeyValuePair>();
            listObj.add(new FBUtils.KeyValuePair('Questionnaire__c',questionerId));
            listObj.add(new FBUtils.KeyValuePair('Question__c',questionId));
            listObj.add(new FBUtils.KeyValuePair('Question_Questionnaire__c',questionQuestionnairesId));
            listObj.add(new FBUtils.KeyValuePair('User__c',UserInfo.getUserId()));            
            listObj.add(new FBUtils.KeyValuePair('Answer__c', fileName));
            listObj.add(new FBUtils.KeyValuePair('Answer_Long__c', fileName));
            listObj.add(new FBUtils.KeyValuePair('Contact_Edition_Mapping__c', ceid));
            listObj.add(new FBUtils.KeyValuePair('Form_Response_Entry__c', entryId));
            
            Map<Integer,List<FBUtils.KeyValuePair>> recordsToInsert = new Map<Integer,List<FBUtils.KeyValuePair>>();
            recordsToInsert.put(0,listObj);
            FBUtils.FBResponse response = FBUtils.insertRecords('Question_Response__c',recordsToInsert);
            return response.firstRecordId;
        }
        else{
            List<Attachment> attachLst = [SELECT Id FROM Attachment WHERE ParentId=:objList[0].Id];
            if (!attachLst.isEmpty() && Schema.sObjectType.Attachment.isDeletable() && !isAllowMutliple) {
                delete attachLst;
            }  
            Question_Response__c quesRes = new Question_Response__c();
            quesRes.Id = objList[0].Id;
            quesRes.Answer__c = null;
            quesRes.Answer_Long__c = (isAllowMutliple?((objList[0].Answer_Long__c==null?'':(objList[0].Answer_Long__c +','))+fileName):fileName);
            Decimal versionTemp =  (Decimal)objList[0].Form_Response_Entry__r.get('Version__c');
            if(version == String.valueOf(versionTemp)){
                if(Schema.SObjectType.Question_Response__c.isUpdateable()){
                    update quesRes;
                }
                return String.valueOf(objList[0].get('Id'));    
            }
            else{
                return null;
            }
        }
    }

    /**
    * @description  to get all attchhments form Question Response.
    * @param  entryId
    * @param  ceid
    * @param  questionId
    * @param  questionerId
    * @param  questionQuestionnairesId
    * @return List<Attachment>  
    */
    @AuraEnabled
    public static List<Attachment> getAllAttchments(String entryId,String ceid,String questionId,String questionerId,String questionQuestionnairesId)
    {
        List<Attachment> attachLst = new  List<Attachment>();
        List<Question_Response__c> objList = Database.query('SELECT Id, Form_Response_Entry__c,Form_Response_Entry__r.Version__c,Answer_Long__c FROM Question_Response__c WHERE Form_Response_Entry__c=\''+String.escapeSingleQuotes(entryId)+'\' AND Contact_Edition_Mapping__c=:ceid AND Question__c=:questionId AND Question_Questionnaire__c=:questionQuestionnairesId AND Questionnaire__c=:questionerId WITH SECURITY_ENFORCED');
        if(!objList.isEmpty()){
            attachLst = [SELECT Id,ParentId,Description,Name,ContentType,SystemModstamp FROM Attachment WHERE ParentId=:objList[0].Id ORDER BY SystemModstamp];
        }
        return attachLst;
    }

    /**
    * @description  to delete attchhment form Question Response.
    * @param  attachId
    * @param  qrid
    * @return List<Attachment>  
    */
    @AuraEnabled
    public static List<Attachment> deleteAllAttchments(String attachId,String qrid)
    {
        List<Attachment> attachLst = new  List<Attachment>();
        delete new Attachment(Id=attachId);
        attachLst = [SELECT Id,ParentId,Description,Name,ContentType,SystemModstamp FROM Attachment WHERE ParentId=:qrid ORDER BY SystemModstamp];
        String fileName = '';
        for(Attachment attach : attachLst){
            fileName += (fileName==''?'':',') + attach.Name;
        }
        update new Question_Response__c(Id=qrid,Answer_Long__c=fileName,Answer__c= null);
        return attachLst;
    }
}