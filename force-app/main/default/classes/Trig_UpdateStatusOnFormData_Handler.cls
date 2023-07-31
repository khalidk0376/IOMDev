/**
* Created/Modified By    : Girikon(Garima)
* Created On             : 03-03-2022
* @description           : This trigger helper class is for updating form data status after approval
* Test Class             : FBUtilTest(39%), imcc_Trig_UpdateStatusOnFormData_Test(86%)
* Code Coverage          : 89%
* Modification Log-----  : [Aishwarya IMCC-1681 12 Apr 2022],[Aishwarya IMCC-3677 16 Aug 2022],[Aishwarya IMCC-4506 05 Sep 2022]
* Modified by            : [Arushi IMCC-4186 5 Aug 2022, IMCC-4976 23 Jan 2023]
**/
public without sharing class Trig_UpdateStatusOnFormData_Handler {
    /**
* @description  to update form data status
* @param  listNewFRE
* @param  oldMapFRE
* @param isDelete
*/
    public static void updateFormDataStatus(List<Form_Response_Entry__c> listNewFRE , Map<Id,Form_Response_Entry__c> oldMapFRE, Boolean isDelete){
        Set<Id> formDataIds = new Set<Id>();
        //Set<Id> formResponseEntryIds = new Set<Id>();
        Set<Id> cemIds = new Set<Id>();
        Set<Id> formRespIds = new Set<Id>();
        for(Form_Response_Entry__c fre : listNewFRE){
            Form_Response_Entry__c oldFRE = (isDelete?null:oldMapFRE.get(fre.Id));
            if(isDelete || ((fre.Approval_Status__c == 'Approved' || fre.Approval_Status__c == 'Rejected' || fre.Approval_Status__c == 'In Review') && oldFRE.Approval_Status__c != fre.Approval_Status__c)){
                formDataIds.add(fre.Form_Data__c);
            }
            if(fre.Approval_Status__c == 'Approved'){
                formRespIds.add(fre.Id);
            }
        }
        
        if(!formDataIds.isEmpty()){
            Map<Id,Form_Data__c> mapFormData = new Map<Id,Form_Data__c>([SELECT Id,Forms_Permission__r.Form_Allocation__r.Feature_Category__c,Forms_Permission__r.Form_Allocation__r.Form_Entry__c,Forms_Permission__r.Form_Allocation__r.Entry_Limit__c,Forms_Permission__r.Form_Allocation__r.Approval_Required__c,Status1__c,Forms_Permission__r.Form_Allocation__r.Form_Type__c,tolabel(Forms_Permission__r.Form_Allocation__r.Booth_Product_Types__c),Contact_Edition_Mapping__c FROM Form_Data__c WHERE Id IN:formDataIds WITH SECURITY_ENFORCED]);
            for(Form_Data__c fd : mapFormData.values()){
                cemIds.add(fd.Contact_Edition_Mapping__c);
            }
            
            List<Form_Response_Entry__c> listFREALL = [SELECT Id,Entry_Number__c,Status__c,Approval_Status__c,Form_Data__c,Purchase_Data__c FROM Form_Response_Entry__c WHERE Form_Data__c IN:formDataIds WITH SECURITY_ENFORCED ORDER BY Entry_Number__c DESC];
            Map<Id,List<Form_Response_Entry__c>> mapFDIdListFRE = new Map<Id,List<Form_Response_Entry__c>>();
            for(Form_Response_Entry__c fre : listFREALL){
                List<Form_Response_Entry__c> listFRE2 = (mapFDIdListFRE.containsKey(fre.Form_Data__c)?mapFDIdListFRE.get(fre.Form_Data__c):(new List<Form_Response_Entry__c>()));
                listFRE2.add(fre);
                mapFDIdListFRE.put(fre.Form_Data__c, listFRE2);
            }   
            
            List<Purchase_Data__c> booths = [SELECT Id,Booth_Number__c,Booth_Product_Type__c,Contact_Edition_Mapping__c FROM Purchase_Data__c WHERE Contact_Edition_Mapping__c IN:cemIds AND Purchase_Status__c='Active' AND (Booth_Number__c<>null OR Booth_Number__c<>'') WITH SECURITY_ENFORCED];
            Map<Id,List<Purchase_Data__c>> mapCEMIdListPD = new Map<Id,List<Purchase_Data__c>>();
            for(Purchase_Data__c pd : booths){
                List<Purchase_Data__c> listPD2 = (mapCEMIdListPD.containsKey(pd.Contact_Edition_Mapping__c)?mapCEMIdListPD.get(pd.Contact_Edition_Mapping__c):(new List<Purchase_Data__c>()));
                listPD2.add(pd);
                mapCEMIdListPD.put(pd.Contact_Edition_Mapping__c, listPD2);
            }
            
            List<Form_Data__c> listFDUpdate = new List<Form_Data__c>(); 
            for(Form_Data__c fd : mapFormData.values()){
                String formDataStatus = 'Not Started';
                if(fd.Forms_Permission__r.Form_Allocation__r.Feature_Category__c == 'Form'){
                    if((fd.Forms_Permission__r.Form_Allocation__r.Form_Type__c != 'Link' && (fd.Forms_Permission__r.Form_Allocation__r.Form_Entry__c == 'One Per Account' || fd.Forms_Permission__r.Form_Allocation__r.Form_Entry__c == 'One Per Booth'))){
                        
                        if(mapFDIdListFRE.containsKey(fd.Id)){
                            List<Form_Response_Entry__c> listFRE2 = mapFDIdListFRE.get(fd.Id);
                            formDataStatus = (fd.Forms_Permission__r.Form_Allocation__r.Approval_Required__c?listFRE2.get(0).Approval_Status__c:listFRE2.get(0).Status__c);
                        }
                    }
                    
                    if(fd.Forms_Permission__r.Form_Allocation__r.Form_Type__c != 'Link' && (fd.Forms_Permission__r.Form_Allocation__r.Form_Entry__c == 'Multiple Per Account' || fd.Forms_Permission__r.Form_Allocation__r.Form_Entry__c == 'Multiple Per Booth')){
                        List<Form_Response_Entry__c> listFRE2 = (mapFDIdListFRE.containsKey(fd.Id)?mapFDIdListFRE.get(fd.Id):(new List<Form_Response_Entry__c>()));
                        for(Form_Response_Entry__c fre : listFRE2){
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
                    }
                }
                listFDUpdate.add(new Form_Data__c(Id=fd.Id, Status1__c=formDataStatus));
            }
            
            if(!listFDUpdate.isEmpty()){
                System.debug(LoggingLevel.debug, '@@@@@@@@@@@@'+listFDUpdate);
                update listFDUpdate;
            }
        }
    }
    
    /**
* @description  IMCC-1681 processFormResponseEmails
* @param  fre
* @param  listEmailTypes
*/
    public static void processFormResponseEmails(Form_Response_Entry__c fre, List<String> listEmailTypes){
        System.debug(LoggingLevel.debug, 'listEmailTypes===='+listEmailTypes);
        Map<Id,User> userMap = new Map<Id,User>();
        Map<String,SObject> mapObjNameSobject = new Map<String,SObject>();
        Set<String> usersSetToSendNotification = new Set<String>();
        List<User> listUsers = new List<User>();
        Set<Id> contactIds = new Set<Id>();
        List<Event_Tabs__c> listEventTabs = [SELECT Id,Tab_Code__c FROM Event_Tabs__c WHERE Event_Setting__c=:fre.Event_Name__r.Event_Setting__c AND Standard_Tab_Type__c='Forms' AND Tab_Type__c='Standard' WITH SECURITY_ENFORCED LIMIT 1];
        mapObjNameSobject.put('Form_Response_Entry__c', fre);
        List<Purchase_Data__c> listPDs = new List<Purchase_Data__c>(); // this list will contain the details of purchase booths
        String purchasedBooths ='';
        if(!listEventTabs.isEmpty()){
            mapObjNameSobject.put('Event_Tabs__c', listEventTabs.get(0));
        }
        if(String.isNotBlank(fre.Event_Name__c)){
            mapObjNameSobject.put(Form_Response_Entry__c.Event_Name__c.getDescribe().getReferenceTo()[0].getDescribe().getName(), fre.getSObject('Event_Name__r'));
        }
        if(String.isNotBlank(fre.Company_Name__c)){
            mapObjNameSobject.put(Form_Response_Entry__c.Company_Name__c.getDescribe().getReferenceTo()[0].getDescribe().getName(), fre.getSObject('Company_Name__r'));
        }
        if(String.isNotBlank(fre.Contact_Edition_Mapping__c)){
            mapObjNameSobject.put(Form_Response_Entry__c.Contact_Edition_Mapping__c.getDescribe().getReferenceTo()[0].getDescribe().getName(), fre.getSObject('Contact_Edition_Mapping__r'));
        }
        if(String.isNotBlank(fre.Contact_Edition_Mapping__c)){
            //mapObjNameSobject.put(Form_Response_Entry__c.User__c.getDescribe().getReferenceTo()[0].getDescribe().getName(), fre.getSObject('User__r'));
            contactIds.add(fre.Contact_Edition_Mapping__r.Contact__c);
            for(Contact_Edition_Mapping__c con : [SELECT Contact__c FROM Contact_Edition_Mapping__c WHERE Primary_Contact_Edition_Mapping__c =: fre.Contact_Edition_Mapping__c AND isSecondary__c = true AND Edition__c =:fre.Event_Name__c WITH SECURITY_ENFORCED])      
            {
                contactIds.add(con.Contact__c);
            }
            
            for(User u : [SELECT Id,Name,UserName,Email,ContactId FROM User WHERE ContactId IN:ContactIds WITH SECURITY_ENFORCED]){
                usersSetToSendNotification.add(u.id);
                listUsers.add(u);
                userMap.put(u.Id,u);
            }
            //IMCC-3677
            //Querying Purchase Data record related to CEM from Form Response Entry record(CEM that will be receiving the email notification)
            listPDs = [Select Id, Booth_Number__c, Booth_Product_Type__c FROM Purchase_Data__c WHERE Contact_Edition_Mapping__c=: fre.Contact_Edition_Mapping__c AND Edition__c =:fre.Event_Name__c AND Purchase_Status__c='Active' AND (Booth_Number__c<>null OR Booth_Number__c<>'') AND Transaction_Status__c ='Active' WITH SECURITY_ENFORCED];   
            
            if(!listPDs.isEmpty()){
                for(Purchase_Data__c pd :listPDs){
                    purchasedBooths += pd.Booth_Number__c +' - '+pd.Booth_Product_Type__c+',<br/>'; //Preparing the String by concatinating the Booth Number and Both Product Type by iterating the listPDs, Final prepared string i.e "purchasedBooths" will be send out in email by replacing the keyword "Selected Booth No"
                }
                purchasedBooths =purchasedBooths.subString(0,purchasedBooths.length()-6); // Removing the last comma from the prepared string
            }
        }
        if(String.isNotBlank(fre.Form_Data__c)){
            mapObjNameSobject.put(Form_Response_Entry__c.Form_Data__c.getDescribe().getReferenceTo()[0].getDescribe().getName(), fre.getSObject('Form_Data__r'));
            mapObjNameSobject.put(Form_Data__c.Forms_Permission__c.getDescribe().getReferenceTo()[0].getDescribe().getName(), fre.getSObject('Form_Data__r').getSObject('Forms_Permission__r'));
            mapObjNameSobject.put(Forms_Permission__c.Form_Allocation__c.getDescribe().getReferenceTo()[0].getDescribe().getName(), fre.getSObject('Form_Data__r').getSObject('Forms_Permission__r').getSObject('Form_Allocation__r'));
        }
        if(String.isNotBlank(fre.Purchase_Data__c)){
            mapObjNameSobject.put(Form_Response_Entry__c.Purchase_Data__c.getDescribe().getReferenceTo()[0].getDescribe().getName(), fre.getSObject('Purchase_Data__r'));
        }
        
        List<Event_Edition_Email_Template__c> listEditionEmailTemplates = [SELECT Id, Name, Subject__c,Content__c,Edition__c,Template_Code__c,From_Email_Address__c,Edition__r.Informa_Logo__c,Edition__r.Informa_logo_url__c FROM Event_Edition_Email_Template__c WHERE Edition__c =:fre.Event_Name__c WITH SECURITY_ENFORCED];
        Map<String,Event_Edition_Email_Template__c> mapEditionEmailTemplates = new Map<String,Event_Edition_Email_Template__c>();
        for(Event_Edition_Email_Template__c temp : listEditionEmailTemplates){
            mapEditionEmailTemplates.put(temp.Template_Code__c,temp);
        }
        
        Map<String,List<Email_Template_Keyword__mdt>> mapObjectNameAndListKeywords = getEmailTemplateKeyWordsByModule('Forms');
        Map<String,Email_Template_Types_Mapping__mdt> mapEmailTemplateTypeMapping = getEmailTemplateTypesByModule('Forms');
        
        System.debug(LoggingLevel.debug, 'mapObjectNameAndListKeywords===='+mapObjectNameAndListKeywords);
        System.debug(LoggingLevel.debug, 'mapEmailTemplateTypeMapping===='+mapEmailTemplateTypeMapping);
        
        List<Operations_Team_Member__c> listOTM = [SELECT Id,Operations_Team__c,User__c,User__r.Email,Team_Roles__c FROM Operations_Team_Member__c WHERE Operations_Team__c =:fre.Event_Name__r.Operations_Team__c AND User__c !=null];
        System.debug(LoggingLevel.debug, '###################'+listOTM);
        
        Map<String,Id> mapAddressOrgwideEmailId = new Map<String,Id>();
        for(OrgWideEmailAddress oea : [SELECT Id,Address FROM OrgWideEmailAddress]){ //WITH SECURITY_ENFORCED
            mapAddressOrgwideEmailId.put(oea.Address, oea.Id);
        }
        System.debug(LoggingLevel.debug, 'mapAddressOrgwideEmailId===='+mapAddressOrgwideEmailId);
        
        List<Question_Response__c> lstQRs = [SELECT Id,Answer__c,Answer_Long__c,Question__c,Question__r.Is_MultiSelect__c,Is_Updated__c,Question__r.Label__c,Question__r.Type__c FROM Question_Response__c WHERE Form_Response_Entry__c=:fre.Id AND Question__r.Type__c NOT IN ('Information','Header/Footer') WITH SECURITY_ENFORCED order by CREATEDDATE ASC];
        if(lstQRs.isEmpty()){
            lstQRs = [SELECT Id,Answer__c,Answer_Long__c,Question__c,Question__r.Is_MultiSelect__c,Is_Updated__c,Question__r.Label__c,Question__r.Type__c FROM Question_Response__c WHERE Form_Response_Entry__c=:fre.Id AND Question__r.Type__c NOT IN ('Information','Header/Footer') AND IsDeleted = true WITH SECURITY_ENFORCED order by CREATEDDATE ASC ALL ROWS];
        }
        
        List<String> quesRespId = new List<String>();
        for(Question_Response__c qr : lstQRs){
            quesRespId.add(qr.Id);
        }
        
        Map<String,Attachment> mapAttach = new Map<String,Attachment>();
        if(!quesRespId.isEmpty()){
            List<Attachment> attachLst = [SELECT Id,Name,Body,parentId FROM attachment WHERE parentId IN:quesRespId WITH SECURITY_ENFORCED ORDER BY CREATEDDATE ASC];
            if(attachLst.isEmpty()){
                attachLst = [SELECT Id,Name,Body,parentId FROM attachment WHERE parentId IN:quesRespId AND IsDeleted = true WITH SECURITY_ENFORCED ORDER BY CREATEDDATE ASC ALL ROWS];
            }
            for(Attachment attach : attachLst){
                mapAttach.put(attach.Id,attach); // IMCC-4762 change attachment ParentId to attachment Id as there can be multiple attachments.
            }
        }
        
        List<ContentVersion> files = [SELECT Id,Title,VersionData,FileType,FileExtension FROM ContentVersion WHERE Id=:fre.Content_Version__c];
        
        List<Messaging.SingleEmailMessage> listEmails = new List<Messaging.SingleEmailMessage>();
        
        String commURL = System.Label.CommunityURL;
        String documentURL = System.Label.Document_URL;
        
        for(String notiType : listEmailTypes){
            String emailType = notiType.replace('Email:', '');
            System.debug(LoggingLevel.debug, 'emailType===='+emailType);
            if(notiType.startsWith('Email:') && mapEmailTemplateTypeMapping.containsKey(emailType)){
                Email_Template_Types_Mapping__mdt ettm = mapEmailTemplateTypeMapping.get(emailType);
                System.debug(LoggingLevel.debug, 'ettm===='+ettm);
                if(mapEditionEmailTemplates.containsKey(ettm.Email_Template_Code__c)){
                    /** fetch Email Template on basis of the matching template title**/
                    Event_Edition_Email_Template__c emailTemplate = mapEditionEmailTemplates.get(ettm.Email_Template_Code__c);
                    String informaLogoURL = '';
                    Boolean isSendAdditionalEmails = false;
                    if(String.isNotBlank(emailTemplate.Edition__r.Informa_Logo__c)){
                        informaLogoURL = '<img src="'+emailTemplate.Edition__r.Informa_logo_url__c+'" />';
                    }
                    
                    System.debug(LoggingLevel.debug, 'emailTemplate===='+emailTemplate);
                    
                    String body = emailTemplate.Content__c;
                    String subject = emailTemplate.Subject__c;
                    /** fetch email from org wide email address matching with the From email address on Email Template**/
                    Id oweaId = mapAddressOrgwideEmailId.get(emailTemplate.From_Email_Address__c);
                    System.debug(LoggingLevel.debug, 'oweaId===='+oweaId);
                    List<String> emailIds = new List<String>();
                    List<String> additionalEmailIds = new List<String>();
                    if(ettm.External__c || Test.isRunningTest()){
                        /** get external email ids from form allocation record **/
                        emailIds = getEmailIds(fre);
                    }
                    if(ettm.Customer_Only__c){
                        if(fre.Form_Data__r.Forms_Permission__r.Form_Allocation__r.Send_Response_to_Customer__c && fre.Form_Data__r.Forms_Permission__r.Form_Allocation__r.Form_Type__c == 'Online'){
                            if(fre.Receive_an_Email_Copy__c){
                                isSendAdditionalEmails = true;
                                if(fre.Additional_Emails__c !='' && fre.Additional_Emails__c != null){
                                additionalEmailIds = getAdditionalEmailIds(fre);
                            }
                        }
                    }
                    }
                    if(ettm.Operations_Team__c && String.isNotBlank(fre.Event_Name__r.Operations_Team__c)){
                        if(!listOTM.isEmpty()){
                            for(Operations_Team_Member__c otm : listOTM){
                                if(!emailIds.contains(otm.User__r.Email)){
                                    emailIds.add(otm.User__r.Email);
                                }
                            }
                        }
                    }
                    System.debug(LoggingLevel.debug, '###################2222'+emailIds);
                    if(!String.isBlank(body) || !String.isBlank(subject)){
                        if(mapObjectNameAndListKeywords.containsKey('Link')){
                            for(Email_Template_Keyword__mdt etk : mapObjectNameAndListKeywords.get('Link')){
                                String value = (etk.Prefix__c==null?'':etk.Prefix__c)+(etk.Field_Name__c==null?'':etk.Field_Name__c);
                                body = body.replace(etk.Keyword__c,value); 
                            }
                        }
                        for(String key : mapObjNameSobject.keySet()){
                            if(mapObjectNameAndListKeywords.containsKey(key)){
                                SObject sobJ = mapObjNameSobject.get(key); 
                                Map<String, Schema.SobjectField> fieldsMap = Id.valueOf(String.valueOf(sobJ.get('Id'))).getSObjectType().getDescribe().fields.getMap();
                                for(Email_Template_Keyword__mdt etk : mapObjectNameAndListKeywords.get(key)){
                                    String value = String.valueOf(sobJ.get(etk.Field_Name__c)==null?'':sobJ.get(etk.Field_Name__c));
                                    if(fieldsMap.get(etk.Field_Name__c).getDescribe().getType() == Schema.DisplayType.DATE) {
                                        //value = value.replace(' 00:00:00',''); //IMCC-4506
                                        if(String.isNotBlank(value)){value = formatDate(Date.valueof(value));} //IMCC-4506
                                    }
                                    body = body.replace(etk.Keyword__c,value); 
                                    subject = subject.replace(etk.Keyword__c,value);
                                }
                            }
                        }
                    }
                    String onlineResp = '';
                    if(fre.Form_Data__r.Forms_Permission__r.Form_Allocation__r.Form_Type__c == 'Online'){
                        onlineResp = getTableEmailBody(lstQRs,emailType);
                    }                  
                    if(ettm.Customer_Only__c){ 
                        if(isSendAdditionalEmails){
                            
                            String bodyTemp = body;
                            String subjectemp = subject;
                            
                            // Define the email
                            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                            
                            bodyTemp = bodyTemp.replace('{Informa Logo}',informaLogoURL);  
                            bodyTemp = bodyTemp.replace('{Purchased Stand No}',purchasedBooths); //IMCC-3677
                            if(fre.Form_Data__r.Forms_Permission__r.Form_Allocation__r.Form_Type__c == 'Online'){
                                bodyTemp = bodyTemp.replace('{Online Form Response}',onlineResp); 
                                List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
                                for(Attachment file: mapAttach.values()) {
                                    Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                                    efa.setContentType('application/pdf');
                                    efa.setFileName(file.Name);
                                    efa.setBody(file.Body);
                                    attachments.add(efa);
                                }
                                email.setFileAttachments(attachments);
                            }
                            if(oweaId !=null){
                                email.setOrgWideEmailAddressId(oweaId);
                            }
                            
                            if(mapObjectNameAndListKeywords.containsKey('User')){
                                SObject sobJ = userMap.get(fre.Last_Modified_By__c); 
                                Map<String, Schema.SobjectField> fieldsMap = Id.valueOf(String.valueOf(sobJ.get('Id'))).getSObjectType().getDescribe().fields.getMap();
                                for(Email_Template_Keyword__mdt etk : mapObjectNameAndListKeywords.get('User')){
                                    String value = String.valueOf(sobJ.get(etk.Field_Name__c)==null?'':sobJ.get(etk.Field_Name__c));
                                    if(fieldsMap.get(etk.Field_Name__c).getDescribe().getType() == Schema.DisplayType.DATE) {
                                        //value = value.replace(' 00:00:00','');
                                        if(String.isNotBlank(value)){value = formatDate(Date.valueof(value));} //IMCC-4506
                                    }
                                    bodyTemp = bodyTemp.replace(etk.Keyword__c,value); 
                                    subjectemp = subjectemp.replace(etk.Keyword__c,value);
                                }
                            }
                            
                            email.setTargetObjectId(userMap.get(fre.Last_Modified_By__c).ContactId);
                            if(additionalEmailIds !=null && !additionalEmailIds.isEmpty()){email.setCcAddresses(additionalEmailIds);}
                            for(String key : mapObjectNameAndListKeywords.keySet()){
                                for(Email_Template_Keyword__mdt etk : mapObjectNameAndListKeywords.get(key)){
                                    bodyTemp = bodyTemp.replace(etk.Keyword__c,''); 
                                    subjectemp = subjectemp.replace(etk.Keyword__c,'');
                                }
                            }
                            
                            System.debug(LoggingLevel.DEBUG, 'bodyTemp==='+bodyTemp);
                            System.debug(LoggingLevel.DEBUG, 'subjectemp==='+subjectemp);
                            
                            //Replace content document image
                            bodyTemp = bodyTemp.replaceAll(documentURL, commURL+'/IMCC');
                            bodyTemp = bodyTemp.replaceAll('\\.\\./servlet/', commURL+'/IMCC/servlet/');
                            bodyTemp = bodyTemp.replace('<table', '<table style="border-collapse:collapse;"');
                            
                            email.setHtmlBody(bodyTemp); 
                            email.setSubject(subjectemp); 
                            email.setSaveAsActivity(false);
                            System.debug('Emails1::'+email);
                            System.debug(LoggingLevel.debug,'testEMAIL::'+email);
                            listEmails.add(email);
                        }
                        else{
                            for(User u : listUsers){
                                
                                String bodyTemp = body;
                                String subjectemp = subject;
                                
                                // Define the email
                                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                                
                                bodyTemp = bodyTemp.replace('{Informa Logo}',informaLogoURL);  
                                bodyTemp = bodyTemp.replace('{Purchased Stand No}',purchasedBooths); //IMCC-3677
                                if(fre.Form_Data__r.Forms_Permission__r.Form_Allocation__r.Form_Type__c == 'Online'){
                                    bodyTemp = bodyTemp.replace('{Online Form Response}',onlineResp); 
                                    List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
                                    for(Attachment file: mapAttach.values()) {
                                        Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                                        efa.setContentType('application/pdf');
                                        efa.setFileName(file.Name);
                                        efa.setBody(file.Body);
                                        attachments.add(efa);
                                    }
                                    email.setFileAttachments(attachments);
                                }
                                if(fre.Form_Data__r.Forms_Permission__r.Form_Allocation__r.Form_Type__c == 'PDF'){
                                    bodyTemp = bodyTemp.replace('{Online Form Response}',''); 
                                    List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
                                    for(ContentVersion file: files) {
                                        Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                                        efa.setFileName(file.Title+'.'+file.FileExtension);
                                        efa.setBody(file.VersionData);
                                        attachments.add(efa);
                                    }
                                    email.setFileAttachments(attachments);
                                }
                                
                                if(oweaId !=null){
                                    email.setOrgWideEmailAddressId(oweaId);
                                }
                                
                                if(mapObjectNameAndListKeywords.containsKey('User')){
                                    SObject sobJ = u; 
                                    Map<String, Schema.SobjectField> fieldsMap = Id.valueOf(String.valueOf(sobJ.get('Id'))).getSObjectType().getDescribe().fields.getMap();
                                    for(Email_Template_Keyword__mdt etk : mapObjectNameAndListKeywords.get('User')){
                                        String value = String.valueOf(sobJ.get(etk.Field_Name__c)==null?'':sobJ.get(etk.Field_Name__c));
                                        if(fieldsMap.get(etk.Field_Name__c).getDescribe().getType() == Schema.DisplayType.DATE) {
                                            //value = value.replace(' 00:00:00','');
                                            if(String.isNotBlank(value)){value = formatDate(Date.valueof(value));} //IMCC-4506
                                        }
                                        bodyTemp = bodyTemp.replace(etk.Keyword__c,value); 
                                        subjectemp = subjectemp.replace(etk.Keyword__c,value);
                                    }
                                }
                                
                                email.setTargetObjectId(u.ContactId);
                                
                                for(String key : mapObjectNameAndListKeywords.keySet()){
                                    for(Email_Template_Keyword__mdt etk : mapObjectNameAndListKeywords.get(key)){
                                        bodyTemp = bodyTemp.replace(etk.Keyword__c,''); 
                                        subjectemp = subjectemp.replace(etk.Keyword__c,'');
                                    }
                                }
                                
                                System.debug(LoggingLevel.DEBUG, 'bodyTemp==='+bodyTemp);
                                System.debug(LoggingLevel.DEBUG, 'subjectemp==='+subjectemp);
                                
                                //Replace content document image
                                bodyTemp = bodyTemp.replaceAll(documentURL, commURL+'/IMCC');
                                bodyTemp = bodyTemp.replaceAll('\\.\\./servlet/', commURL+'/IMCC/servlet/');
                                bodyTemp = bodyTemp.replace('<table', '<table style="border-collapse:collapse;"');
                                
                                email.setHtmlBody(bodyTemp); 
                                email.setSubject(subjectemp); 
                                email.setSaveAsActivity(false);
                                System.debug('Emails2::'+email);
                                System.debug(LoggingLevel.debug,'testEMAIL::'+email);
                                listEmails.add(email);
                            }
                        }
                    }
                    if(ettm.External__c || ettm.Operations_Team__c){
                        // Define the email
                        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                        body = body.replace('{Informa Logo}',informaLogoURL);
                        body = body.replace('{Purchased Stand No}',purchasedBooths); // IMCC-3677
                        if(fre.Form_Data__r.Forms_Permission__r.Form_Allocation__r.Form_Type__c == 'Online'){
                            body = body.replace('{Online Form Response}',onlineResp); 
                            if(ettm.External__c || ettm.Operations_Team__c){
                                List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
                                for(Attachment file: mapAttach.values()) {
                                    Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                                    efa.setContentType('application/pdf');
                                    efa.setFileName(file.Name);
                                    efa.setBody(file.Body);
                                    attachments.add(efa);
                                }
                                email.setFileAttachments(attachments);
                            }
                        }
                        if(fre.Form_Data__r.Forms_Permission__r.Form_Allocation__r.Form_Type__c == 'PDF'){
                            body = body.replace('{Online Form Response}','');
                            if(ettm.External__c || ettm.Operations_Team__c){
                                List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
                                for(ContentVersion file: files) {
                                    Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                                    efa.setFileName(file.Title+'.'+file.FileExtension);
                                    efa.setBody(file.VersionData);
                                    attachments.add(efa);
                                }
                                email.setFileAttachments(attachments);
                            }
                        }
                        
                        if(oweaId !=null){
                            email.setOrgWideEmailAddressId(oweaId);
                        }
                        
                        if(!emailIds.isEmpty()){
                            email.setToAddresses(emailIds);
                        }
                        
                        for(String key : mapObjectNameAndListKeywords.keySet()){
                            for(Email_Template_Keyword__mdt etk : mapObjectNameAndListKeywords.get(key)){
                                body = body.replace(etk.Keyword__c,''); 
                                subject = subject.replace(etk.Keyword__c,'');
                            }
                        }
                        
                        System.debug(LoggingLevel.DEBUG, 'body==='+body);
                        System.debug(LoggingLevel.DEBUG, 'subject==='+subject);
                        
                        //Replace content document image
                        body = body.replaceAll(documentURL, commURL+'/IMCC');
                        body = body.replaceAll('\\.\\./servlet/', commURL+'/IMCC/servlet/');
                        body = body.replace('<table', '<table style="border-collapse:collapse;"');
                        
                        email.setHtmlBody(body); 
                        email.setSubject(subject); 
                        email.setSaveAsActivity(false);
                        System.debug('Emails3::'+email);
                        System.debug(LoggingLevel.debug,'testEMAIL::'+email);
                        listEmails.add(email);
                    }
                }
            }
            else if(notiType.startsWith('Portal:')){
                String portalNotiType = notiType.replace('Portal:', '');
                Boolean isSend = false;
                //User exhibitorUser = (User)mapObjNameSobject.get('User');
                Edition__c edition = (Edition__c)mapObjNameSobject.get('Edition__c');
                Account exhibitorAccount = (Account)mapObjNameSobject.get('Account');
                Event_Tabs__c tabCodeForms = (Event_Tabs__c)mapObjNameSobject.get('Event_Tabs__c');
                Set<String> recipientsIds = new Set<String>();
                String title = 'Form Status';
                String body = '';
                String target = '';
                if((portalNotiType == 'Form Approval' || portalNotiType == 'Form Rejection') && !UsersSetToSendNotification.isEmpty()){
                    isSend = true;
                    target = '{type:"comm__namedPage",attributes:{name: "forms__c"},state:{accId:"'+exhibitorAccount.Id+'",edcode:"'+edition.Edition_Code__c+'",tabId:"'+tabCodeForms.Tab_Code__c+'"}}';
                    body = 'Status of Submission "' + fre.File_Name__c + '" For Form "' + fre.Form_Name__c + '" is changed to "' + fre.Approval_Status__c + '"';
                    if(portalNotiType == 'Form Rejection'){body = body + ' Rejection Reason: "' + fre.Rejection_Reason__c + '"';}
                    recipientsIds.addAll(UsersSetToSendNotification);
                }
                if(isSend){
                    String titleBody = title + '###' + body;
                    IMCC_ContractorMapNotification.notifyUsers(recipientsIds, target, titleBody); 
                }
            }
        }
        
        // Send the email
        if(!listEmails.isEmpty()){
            List<Messaging.SendEmailResult> lst = Messaging.sendEmail(listEmails, false);
            for(Messaging.SendEmailResult res : lst){
                System.debug(Logginglevel.Debug, res.isSuccess());
                System.debug(Logginglevel.Debug, res.getErrors());
            }
        }
    }
    /****** IMCC-4506 Start ******/
    /**
* @description  format dates in dd MMM yyyy
* @param  d
* @return String
*/
    public static String formatDate(Date d){
        String dt = DateTime.newInstance(d.year(),d.month(),d.day()).format('dd MMM yyyy');
        return dt;
    }
    /****** IMCC-4506 End ******/
    
    /**
* @description  IMCC-1681 Method for sending the form related emails
* @param  setIds
* @param oldMapFRE
* @param isDelete
*/
    public static void sendFormResponseEmails(Set<Id> setIds, Map<Id,Form_Response_Entry__c> oldMapFRE, Boolean isDelete){
        Set<Id> recordIds = new Set<Id>();
        Boolean isSendCopyToCustomer = false;
        List<Form_Response_Entry__c> listFormResp = [SELECT Id,Response_Status__c,Approval_Status__c,Status__c,Form_Data__r.Forms_Permission__r.Form_Allocation__r.Approval_Required__c
                                                     ,Form_Data__r.Forms_Permission__r.Form_Allocation__r.Send_Response_to_Customer__c,Form_Data__r.Forms_Permission__r.Form_Allocation__r.Form_Type__c
                                                     ,Receive_an_Email_Copy__c,Additional_Emails__c,Content_Version__c,File_Name__c, Last_Modified_Date__c FROM Form_Response_Entry__c WHERE Id IN:setIds
                                                     AND Form_Data__r.Forms_Permission__r.Form_Allocation__r.Feature_Category__c='Form'
                                                     AND Form_Data__r.Forms_Permission__r.Form_Allocation__r.Form_Type__c IN ('Online','PDF') WITH SECURITY_ENFORCED];
        
        Profile prf = [SELECT Id,Name FROM Profile WHERE Id=:Userinfo.getProfileid() LIMIT 1];
        
        Map<Id,List<String>> mapFREIdEmailTemplate = new Map<Id,List<String>>();
        for(Form_Response_Entry__c fre : listFormResp){
            
            if(!mapFREIdEmailTemplate.containsKey(fre.Id)){
                mapFREIdEmailTemplate.put(fre.Id, new List<String>());
            }
            if(fre.Form_Data__r.Forms_Permission__r.Form_Allocation__r.Send_Response_to_Customer__c && fre.Form_Data__r.Forms_Permission__r.Form_Allocation__r.Form_Type__c == 'Online'){
                if(fre.Receive_an_Email_Copy__c){
                    isSendCopyToCustomer = true;
                }  
            }
            
            if(!isDelete){
                Form_Response_Entry__c oldFRE = oldMapFRE.get(fre.Id);
                System.debug(LoggingLevel.debug, 'Response Status ' +fre.Response_Status__c+'_'+oldFRE.Response_Status__c);
                System.debug(LoggingLevel.debug, 'Status ' +fre.Status__c+'_'+oldFRE.Status__c);
                if((fre.Status__c == 'Submitted'|| fre.Status__c == 'Resubmitted') && oldFRE.Last_Modified_Date__c != fre.Last_Modified_Date__c && prf.Name == 'IM Customer Community Login User'){
                    if(isSendCopyToCustomer){
                        recordIds.add(fre.Id);
                        List<String> lst =  mapFREIdEmailTemplate.get(fre.Id);
                        lst.add('Email:Form Copy');
                        mapFREIdEmailTemplate.put(fre.Id, lst);
                    }
                }
                if(fre.Approval_Status__c == 'Approved' && oldFRE.Approval_Status__c != fre.Approval_Status__c){
                    recordIds.add(fre.Id);
                    List<String> lst =  mapFREIdEmailTemplate.get(fre.Id);
                    lst.add('Email:Form Approval');
                    lst.add('Portal:Form Approval');
                    mapFREIdEmailTemplate.put(fre.Id, lst);
                }
                else if(fre.Approval_Status__c == 'Rejected' && oldFRE.Approval_Status__c != fre.Approval_Status__c){
                    recordIds.add(fre.Id);
                    List<String> lst =  mapFREIdEmailTemplate.get(fre.Id);
                    lst.add('Email:Form Rejection');
                    lst.add('Portal:Form Rejection');
                    mapFREIdEmailTemplate.put(fre.Id, lst);
                }
                else if(fre.Approval_Status__c == 'In Review' && oldFRE.Approval_Status__c != fre.Approval_Status__c){
                    recordIds.add(fre.Id);
                    List<String> lst =  mapFREIdEmailTemplate.get(fre.Id);
                    lst.add('Email:Form In Review');
                    if(fre.Form_Data__r.Forms_Permission__r.Form_Allocation__r.Approval_Required__c){
                        lst.add('Email:Form Approval Required');
                    }
                    mapFREIdEmailTemplate.put(fre.Id, lst);
                }
                else if((fre.Response_Status__c == 'Submitted' && oldFRE.Response_Status__c != fre.Response_Status__c && fre.Form_Data__r.Forms_Permission__r.Form_Allocation__r.Approval_Required__c == false && prf.Name =='IM Customer Community Login User')){
                    recordIds.add(fre.Id);
                    List<String> lst =  mapFREIdEmailTemplate.get(fre.Id);
                    lst.add('Email:Form Submission');
                    mapFREIdEmailTemplate.put(fre.Id, lst);
                }
                else if((fre.Status__c == 'Submitted'|| fre.Status__c == 'Resubmitted') && oldFRE.Status__c != fre.Status__c){
                    if(isSendCopyToCustomer){
                        recordIds.add(fre.Id);
                        List<String> lst =  mapFREIdEmailTemplate.get(fre.Id);
                        lst.add('Email:Form Copy');
                        mapFREIdEmailTemplate.put(fre.Id, lst);
                        system.debug('mapFREIdEmailTemplate=='+ mapFREIdEmailTemplate);
                    }
                }
                else if(((fre.Form_Data__r.Forms_Permission__r.Form_Allocation__r.Form_Type__c == 'Online' && fre.Content_Version__c==oldFRE.Content_Version__c && fre.File_Name__c==oldFRE.File_Name__c) || fre.Form_Data__r.Forms_Permission__r.Form_Allocation__r.Form_Type__c == 'PDF') && fre.Response_Status__c == 'Submitted' && oldFRE.Response_Status__c == fre.Response_Status__c && prf.Name =='IM Customer Community Login User'){
                    recordIds.add(fre.Id);
                    List<String> lst =  mapFREIdEmailTemplate.get(fre.Id);
                    lst.add('Email:Form Updated');
                    mapFREIdEmailTemplate.put(fre.Id, lst);
                }
                else if(((fre.Form_Data__r.Forms_Permission__r.Form_Allocation__r.Form_Type__c == 'Online' && fre.Content_Version__c==oldFRE.Content_Version__c && fre.File_Name__c==oldFRE.File_Name__c) || fre.Form_Data__r.Forms_Permission__r.Form_Allocation__r.Form_Type__c == 'PDF') && fre.Response_Status__c == 'Resubmitted' && oldFRE.Response_Status__c == fre.Response_Status__c && prf.Name =='IM Customer Community Login User' && !fre.Form_Data__r.Forms_Permission__r.Form_Allocation__r.Approval_Required__c){
                    recordIds.add(fre.Id);
                    List<String> lst =  mapFREIdEmailTemplate.get(fre.Id);
                    lst.add('Email:Form Updated');
                    mapFREIdEmailTemplate.put(fre.Id, lst);
                }
                if(fre.Status__c == 'Resubmitted' && oldFRE.Response_Status__c != fre.Response_Status__c && (fre.Response_Status__c == 'In Review' || !fre.Form_Data__r.Forms_Permission__r.Form_Allocation__r.Approval_Required__c)){
                    recordIds.add(fre.Id);
                    List<String> lst =  mapFREIdEmailTemplate.get(fre.Id);
                    lst.add('Email:Form Resubmission');
                    mapFREIdEmailTemplate.put(fre.Id, lst);
                }
            }
            else if(isDelete == true && fre.Status__c != 'In Progress' && fre.Status__c != 'Viewed'){
                recordIds.add(fre.Id);
                List<String> lst =  mapFREIdEmailTemplate.get(fre.Id);
                lst.add('Email:Form Deletion');
                mapFREIdEmailTemplate.put(fre.Id, lst);
            }
        }
        System.debug(LoggingLevel.debug, 'mapFREIdEmailTemplate===='+mapFREIdEmailTemplate);
        if(!recordIds.isEmpty()){
            String query = 'SELECT Id,File_Name__c,Event_Name__c,Event_Name__r.Name,Event_Name__r.Operations_Team__c,Event_Name__r.Event_Setting__c,Response_Status__c,Form_Data__r.Forms_Permission__r.Form_Allocation__c,Approval_Status__c,Form_Data__r.Forms_Permission__r.Form_Allocation__r.Approval_Required__c,Contact_Edition_Mapping__r.Edition__r.Name,Content_Version__c,Form_Data__r.Forms_Permission__r.Form_Allocation__r.Form_Entry__c,Form_Data__r.Forms_Permission__r.Form_Allocation__r.Form_Type__c,Form_Data__r.Forms_Permission__r.Form_Allocation__r.Feature_Category__c,Form_Name__c,Form_Deadline__c,Submission_Date__c,Purchase_Data__c,Purchase_Data__r.Booth_Number__c,Purchase_Data__r.Booth_Dimension__c,Purchase_Data__r.Quantity_Area__c,Event_Name__r.Edition_Code__c,Company_Name__c,Company_Name__r.Name,Form_Type__c,Rejection_Reason__c,Contact_Edition_Mapping__r.Contact__c,User__c,User__r.Name,Form_Data__r.Forms_Permission__r.Form_Allocation__r.Email_To__c, Form_Data__r.Forms_Permission__r.Form_Allocation__r.Send_individual_forms__c ';
            query+= ',Form_Data__r.Forms_Permission__r.Form_Allocation__r.Send_Response_to_Customer__c,Receive_an_Email_Copy__c,Additional_Emails__c,Last_Modified_By__c FROM Form_Response_Entry__c ';
            query += ' WHERE Id IN:recordIds';
            List<SObject> listSobject = Database.query(query);
            SendEmailOnFormStatusBatch batch = new SendEmailOnFormStatusBatch(listSobject,'Form',mapFREIdEmailTemplate);
            Database.executeBatch(batch,1);
        }
    }
    
    /**
* @description  IMCC-1681 getTableEmailBody
* @param  lstQRs
* @param emailType
* @return String
*/
    public static String getTableEmailBody(List<Question_Response__c> lstQRs, String emailType){
        List<String> qestId = new List<String>();
        Map<String,String> optionMap = new Map<String,String>();
        Map<String,List<Question_Option__c>> qIdOptionList = new Map<String,List<Question_Option__c>>();
        for(Question_Response__c quesRes : lstQRs){
            if(quesRes.Question__r.Type__c == 'Picklist' || quesRes.Question__r.Type__c == 'Radio' || quesRes.Question__r.Type__c == 'Switch'){
                qestId.add(quesRes.Question__c);
            }
        }
        if(!qestId.isEmpty()){
            for(Question_Option__c qo : [SELECT Id, Name_Long__c,Question__c FROM Question_Option__c WHERE Question__c IN :qestId with security_enforced]){
                optionMap.put(qo.Id,qo.Name_Long__c);
                List<Question_Option__c> lst = (qIdOptionList.containsKey(qo.Question__c)?qIdOptionList.get(qo.Question__c):(new List<Question_Option__c>()));
                lst.add(qo);
                qIdOptionList.put(qo.Question__c, lst);
            }   
        }
        
        String htmlBody='';
        if(!lstQRs.isEmpty()){
            htmlBody += '<table border="1" style="border-collapse:collapse"><tr><th>Question</th><th>Answer</th></tr>';
            for(Question_Response__c qr : lstQRs){
                String question = qr.Question__r.Label__c;
                String answer = optionMap.containsKey(qr.Answer__c)?optionMap.get(qr.Answer__c):(String.isBlank(qr.Answer_Long__c)?qr.Answer__c:qr.Answer_Long__c);
                    String answer2 = (String.isBlank(qr.Answer_Long__c)?qr.Answer__c:qr.Answer_Long__c);
                if(qr.Answer_Long__c!=null && qr.Question__r.Is_MultiSelect__c){
                    String temp = '';
                    for(String str : qr.Answer_Long__c.split(';')){
                        if(optionMap.containsKey(str)){
                            temp += temp!=''?','+optionMap.get(str):optionMap.get(str);
                        }
                    }
                    answer = temp;
                }
                if(qr.Question__r.Type__c == 'Checkbox'){answer = Boolean.valueOf(answer)?'Checked':'Unchecked';}
                if(qr.Question__r.Type__c == 'Switch' && String.isNotBlank(answer2) && qIdOptionList.containsKey(qr.Question__c)){if(qIdOptionList.get(qr.Question__c).size() == 2){answer = (answer2=='true'?qIdOptionList.get(qr.Question__c)[0].Name_Long__c:qIdOptionList.get(qr.Question__c)[1].Name_Long__c);}}
                if(qr.Question__r.Type__c == 'DateTime' && String.isNotBlank(answer)){answer = ((DateTime)JSON.deserialize('"'+answer+'"', DateTime.class)).format('dd MMM yyyy HH:mm:ss', 
                                                                                                                                                                   'GMT')+'';}
                if(qr.Question__r.Type__c == 'Date' && String.isNotBlank(answer)){answer = ((DateTime)JSON.deserialize('"'+answer+'T00:00:00.000Z"', DateTime.class)).format('dd MMM yyyy', 
                                                                                                                                                                             'GMT')+'';}
                String backColor = (emailType=='Form Updated'?(qr.Is_Updated__c?' style="background-color:yellow;"':''):'');
                htmlBody += '<tr><td'+backColor+'>'+ question + '</td><td'+backColor+'>' + (String.isBlank(answer)?'No Response':answer) + '</td></tr>';
            }
            htmlBody += '</table>';
        }
        return htmlBody;   
    }
    
    /**
* @description  IMCC-1681 getEmailIds
* @param  fre
* @return List<String> 
*/
    public static List<String> getEmailIds(Form_Response_Entry__c fre){
        String emailTo;
        List<String> emailIds = new List<String>();
        
        try{
            if(fre.Form_Data__r.Forms_Permission__r.Form_Allocation__r.Send_individual_forms__c){
                emailTo = fre.Form_Data__r.Forms_Permission__r.Form_Allocation__r.Email_To__c;
                emailTo = emailTo.replaceAll('\\s+','').replace(';',',');
                emailIds = emailTo.split(',');
                System.debug(LoggingLevel.debug,'emailTo :'+emailTo);
                System.debug(LoggingLevel.debug,'emailIds1231 :'+emailIds);
            }
        }
        catch (Exception ex) {
            HandleAllCustomException.logException(ex,'Form_Allocation__c', 'Form Allocation');
        }
        return emailIds;
    }
    
    /**
* @description getAdditionalEmailIds
* @param  fre
* @return List<String> 
*/
    public static List<String> getAdditionalEmailIds(Form_Response_Entry__c fre){
        String emailTo;
        List<String> emailIds = new List<String>();
        
        try{
            if(fre.Form_Data__r.Forms_Permission__r.Form_Allocation__r.Send_Response_to_Customer__c){
                if(fre.Receive_an_Email_Copy__c && fre.Additional_Emails__c != null){
                    emailTo = fre.Additional_Emails__c;
                    emailTo = emailTo.replaceAll('\\s+','').replace(';',',');
                    emailIds = emailTo.split(',');
                    System.debug(LoggingLevel.debug,'emailTo :'+emailTo);
                    System.debug(LoggingLevel.debug,'emailIds1231 :'+emailIds);
                }
            }
        }
        catch (Exception ex) {
            HandleAllCustomException.logException(ex,'Form_Response_Entry__c', 'Form Response Entry');
        }
        return emailIds;
    }
    
    /**
* @description  to update form response status
* @param  listNewFRE
*/
    public static void updateFormResponseEntry(List<Form_Response_Entry__c> listNewFRE){
        Set<id> formDataId = new Set<id>();
        for(Form_Response_Entry__c frmResEntry : listNewFRE){
            formDataId.add(frmResEntry.Form_Data__c);
        }
        Map<Id,Form_Data__c> formDataMap = new Map<Id,Form_Data__c>([Select Id,Forms_Permission__r.Form_Allocation__r.Approval_Required__c,Forms_Permission__r.Form_Allocation__r.Name from Form_Data__c where Id IN:formDataId]);
        for(Form_Response_Entry__c frmResEntry : listNewFRE)
        {
            frmResEntry.Response_Status__c = frmResEntry.Status__c; 
            if(formDataMap.containsKey(frmResEntry.Form_Data__c)){
                
                if(formDataMap.get(frmResEntry.Form_Data__c).Forms_Permission__r.Form_Allocation__r.Approval_Required__c)  {
                    if(frmResEntry.Status__c == 'Submitted' || frmResEntry.Status__c == 'Resubmitted'){
                        frmResEntry.Response_Status__c = frmResEntry.Approval_Status__c;
                    }
                } 
                if(formDataMap.get(frmResEntry.Form_Data__c).Forms_Permission__r.Form_Allocation__r.Name != null)  {
                    frmResEntry.Form_Name2__c = formDataMap.get(frmResEntry.Form_Data__c).Forms_Permission__r.Form_Allocation__r.Name;                     
                }               
            }
        }
    }
    
    /**
* @description  IMCC-1681 getEmailTemplateKeyWordsByModule
* @param  module
* @return  Map<String,List<Email_Template_Keyword__mdt>> 
*/
    public static Map<String,List<Email_Template_Keyword__mdt>> getEmailTemplateKeyWordsByModule(String module){
        Map<String,List<Email_Template_Keyword__mdt>> mapObjectNameAndListKeywords = new Map<String,List<Email_Template_Keyword__mdt>>();
        Map<String, Email_Template_Keyword__mdt> mapKeywords = Email_Template_Keyword__mdt.getAll();
        for(Email_Template_Keyword__mdt etk : mapKeywords.values()){
            if(String.isNotBlank(etk.Object_Name__c) && etk.Group_Name__c == module){
                String key = etk.Object_Name__c;
                List<Email_Template_Keyword__mdt> lst = (mapObjectNameAndListKeywords.containsKey(key)?mapObjectNameAndListKeywords.get(key):(new List<Email_Template_Keyword__mdt>()));
                lst.add(etk);
                mapObjectNameAndListKeywords.put(key,lst);
            }
        }
        return mapObjectNameAndListKeywords;
    }
    
    /**
* @description  IMCC-1681 getEmailTemplateKeyWordsByModuleALL
* @param  module
* @return  List<Email_Template_Keyword__mdt>
*/
    @AuraEnabled
    public static List<Email_Template_Keyword__mdt> getEmailTemplateKeyWordsByModuleALL(String module){
        List<Email_Template_Keyword__mdt> listKeywords = new List<Email_Template_Keyword__mdt>();
        Map<String, Email_Template_Keyword__mdt> mapKeywords = Email_Template_Keyword__mdt.getAll();
        for(Email_Template_Keyword__mdt etk : mapKeywords.values()){
            if(etk.Group_Name__c == module || String.isBlank(module)){
                listKeywords.add(etk);
            }
        }
        return listKeywords;
    }
    
    /**
* @description  IMCC-1681 getEmailTemplateTypesByModule
* @param  module
* @return  Map<String,Email_Template_Types_Mapping__mdt>  
*/
    @AuraEnabled
    public static Map<String,Email_Template_Types_Mapping__mdt> getEmailTemplateTypesByModule(String module){
        Map<String,Email_Template_Types_Mapping__mdt> mapKeywords1 = new Map<String,Email_Template_Types_Mapping__mdt>();
        Map<String, Email_Template_Types_Mapping__mdt> mapKeywords = Email_Template_Types_Mapping__mdt.getAll();
        for(Email_Template_Types_Mapping__mdt ettm : mapKeywords.values()){
            if(ettm.Group_Name__c == module){
                mapKeywords1.put(ettm.Label,ettm);
            }
        }
        return mapKeywords1;
    }
}