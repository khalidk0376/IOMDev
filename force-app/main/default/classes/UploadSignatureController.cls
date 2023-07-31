/**
* Created/Modified By    : Girikon(Mukesh)
* Created On             : 14 Sept, 2021
* @description           : Use to upload user signature
* Test Class             : UploadSignatureControllerTest 
* Code Coverage          : 98%
* Modification Log
* Modified by            : Girikon(Mukesh)
* Modified By    : Girikon(Arushi [IMCC-3994])
* Modified On             : 4 Aug 2022
**/
public with sharing class UploadSignatureController {
    
    /**
* @description  to save the signature on form response entry.
* @param   formResponseEntryId,String boothId,String conEdMapId,questionId,questionerId,questionQuestionnairesId,base64Data,siteUrl, version
* @return String  
*/
    @AuraEnabled
    public static String saveSignatureResponse(String formResponseEntryId, String boothId, String conEdMapId, String questionId, String questionerId, String questionQuestionnairesId, String base64Data, String siteUrl, String version)
    {
        boothId = boothId!=null && boothId!='' && boothId!='null'?boothId:null;
        //FBResponse is the wrapper class 
        FBUtils.FBResponse response = new FBUtils.FBResponse();
        
        response.isSuccess = false;
        response.message = 'Failed!';
        //set user response data
        List<FBUtils.KeyValuePair> listObj = new List<FBUtils.KeyValuePair>();
        listObj.add(new FBUtils.KeyValuePair('Questionnaire__c',questionerId));
        listObj.add(new FBUtils.KeyValuePair('Question__c',questionId));
        listObj.add(new FBUtils.KeyValuePair('Question_Questionnaire__c',questionQuestionnairesId));
        listObj.add(new FBUtils.KeyValuePair('User__c',UserInfo.getUserId()));
        listObj.add(new FBUtils.KeyValuePair('Contact_Edition_Mapping__c',conEdMapId));
        listObj.add(new FBUtils.KeyValuePair('Form_Response_Entry__c',formResponseEntryId));
        Map<Integer,List<FBUtils.KeyValuePair>> recordsToInsert = new Map<Integer,List<FBUtils.KeyValuePair>>();
        
        //list of Questin Response that match the where clause  
        List<Question_Response__c> objList = Database.query('SELECT Id,Form_Response_Entry__c,Form_Response_Entry__r.Version__c,Answer__c,Answer_Long__c,Comment__c,Question__c,Question_Questionnaire__c,Questionnaire__c FROM Question_Response__c WHERE Questionnaire__c=\''+String.escapeSingleQuotes(questionerId)+'\' AND Question__c=\''+String.escapeSingleQuotes(questionId)+'\' AND Contact_Edition_Mapping__c=\''+String.escapeSingleQuotes(conEdMapId)+'\' AND Form_Response_Entry__c=\''+String.escapeSingleQuotes(formResponseEntryId)+'\' WITH SECURITY_ENFORCED');
        
        siteUrl = siteUrl+'/servlet/servlet.FileDownload?file=';
        if(siteUrl.indexOf('/apex/')>0){
            siteUrl = '../'+siteUrl.split('/apex/')[1];
        }
        
        if(objList.isEmpty()){
            // create new response for a question            
            recordsToInsert.put(0,listObj);
            response = FBUtils.insertRecords('Question_Response__c', recordsToInsert);
            String id =  saveTheFile(response.firstRecordId,base64Data);
            recordsToInsert.clear();
            listObj.add(new FBUtils.KeyValuePair('Id',response.firstRecordId));
            listObj.add(new FBUtils.KeyValuePair('Answer__c', siteUrl+id));
            listObj.add(new FBUtils.KeyValuePair('Answer_Long__c', siteUrl+id));               
            recordsToInsert.put(0,listObj);
            FBUtils.updateRecords('Question_Response__c', recordsToInsert);
            return JSON.serialize(response);
        }
        else{
            // else-response exist then return responsewrapper if the form version is same else return null to restrict the users for updating the fre on same time with diff tabs
            Decimal versionTemp =  (Decimal)objList[0].Form_Response_Entry__r.get('Version__c');
            if(version == String.valueOf(versionTemp)){
                //If exist answer by user for same question then upload signature only
                String id = saveTheFile(String.valueOf(objList[0].get('Id')), base64Data);
                
                if(id!=''){
                    listObj.add(new FBUtils.KeyValuePair('Id',objList[0].get('Id')));
                    listObj.add(new FBUtils.KeyValuePair('Answer__c', siteUrl+id)); 
                    listObj.add(new FBUtils.KeyValuePair('Answer_Long__c', siteUrl+id));               
                    recordsToInsert.put(0,listObj);
                    FBUtils.updateRecords('Question_Response__c', recordsToInsert);
                    response.isSuccess = true;
                    response.message = 'Signature uploaded successfully';    
                }
                return JSON.serialize(response);
            }
            else{
                throw new AuraHandledException('Signature has been already updated. Please refresh the page.');
            }
        }
    }
    
    /**
* @description  to save the file of signature in Attachment.
* @param   parentId, String base64Data
* @return String  
*/
    public static String saveTheFile(Id parentId, String base64Data) { 
        //System.debug(base64Data);
        String fileName = UserInfo.getName()+' Signature.png';
        
        //if- deleting the attachment if already exist one on FRE with same fileName and created by same user
        if(Schema.SObjectType.Attachment.isDeletable()){
            delete([Select Id from Attachment WHERE Name =: String.escapeSingleQuotes(fileName) AND ParentId=:String.escapeSingleQuotes(parentId) AND CreatedById=:UserInfo.getUserId() WITH SECURITY_ENFORCED]);    
        }
        
        base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
        //set the new attachment data
        Attachment a = new Attachment();
        if(Schema.SObjectType.Attachment.Fields.ParentId.isCreateable()){
            a.parentId = parentId;
        }
        if(Schema.SObjectType.Attachment.Fields.Body.isCreateable()){
            a.Body = EncodingUtil.base64Decode(base64Data);
        }
        if(Schema.SObjectType.Attachment.Fields.Name.isCreateable()){
            a.Name = fileName;
        }
        // insertion of new attachment created above and return the attachmentId
        SObjectAccessDecision securityDecision = Security.stripInaccessible(AccessType.CREATABLE, new List<Attachment>{a});
        Insert securityDecision.getRecords();
        return securityDecision.getRecords()[0].Id;
    }
}