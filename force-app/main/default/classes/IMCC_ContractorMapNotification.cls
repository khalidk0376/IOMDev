/**
* Created/Modified By    : Girikon(Arushi)
* Created On             : 06-05-2022
* @description           : This trigger helper class is for Contractor Mapping
* Test Class             : IMCC_ContractorMappingTrigHandler_Test
* Code Coverage          : 96%
* Modification Log-----  : 
* Modified by 
**/
public without sharing class IMCC_ContractorMapNotification {
    /**
    * @description  IMCC-201 processStandDesignEmails
    * @param  cm
    * @param  listEmailTypes
    */
    public static void processStandDesignEmails(Contractor_Mapping__c cm, List<String> listEmailTypes){
        Map<String,SObject> mapObjNameSobject = new Map<String,SObject>();
        
        List<Event_Tabs__c> listEventTabsSC = [SELECT Id,Tab_Code__c FROM Event_Tabs__c WHERE Event_Setting__c=:cm.Edition__r.Event_Setting__c AND Standard_Tab_Type__c='Stand Contractors' AND Tab_Type__c='Standard' WITH SECURITY_ENFORCED LIMIT 1];
        
        List<Event_Tabs__c> listEventTabsSD = [SELECT Id,Tab_Code__c FROM Event_Tabs__c WHERE Event_Setting__c=:cm.Edition__r.Event_Setting__c AND Standard_Tab_Type__c='Stand Design' AND Tab_Type__c='Standard' WITH SECURITY_ENFORCED LIMIT 1];
        
        Set<String> usersSetToSendNotification = new Set<String>();
        Set<String> userSetofEmailAddress = new Set<String>();
	    Set<Id> contactIds = new Set<Id>();

        mapObjNameSobject.put('Contractor_Mapping__c', cm);
        if(!listEventTabsSC.isEmpty()){
            mapObjNameSobject.put('EventTabStandDesign', listEventTabsSC.get(0));
        }
        if(!listEventTabsSD.isEmpty()){
            mapObjNameSobject.put('EventTabMyExhibitor', listEventTabsSD.get(0));
        }
        if(String.isNotBlank(cm.Contractor_CEM__c)){
            List<User> contractorUser = [Select Id,Name,UserName From User Where ContactId=:cm.Contractor_CEM__r.Contact__c WITH SECURITY_ENFORCED LIMIT 1];
            if(!contractorUser.isEmpty()){
                mapObjNameSobject.put('Contractor_User', contractorUser.get(0));
            }
            mapObjNameSobject.put('ContractorAccount', cm.getSObject('Contractor_CEM__r').getSObject('Account__r'));
        }
        String cemId = '';
        String exhibitorContact = '';
        if(String.isNotBlank(cm.Id)){
            List<Purchase_Data__c> listPD = [SELECT Id,Booth_Dimension__c,Booth_Number__c,Quantity_Area__c,Contact_Edition_Mapping__c,Contact_Edition_Mapping__r.Contact__c,Contact_Edition_Mapping__r.Account__c,Contact_Edition_Mapping__r.Account__r.Name,Contact_Edition_Mapping__r.Account__r.BillingCountry FROM Purchase_Data__c WHERE Contractor_Mapping__c=:cm.Id WITH SECURITY_ENFORCED LIMIT 1];
            if(!listPD.isEmpty()){
                cemId = listPD.get(0).Contact_Edition_Mapping__c;
                mapObjNameSobject.put('Purchase_Data__c', listPD.get(0));
                ContactIds.add(listPD.get(0).Contact_Edition_Mapping__r.Contact__c);	
                exhibitorContact = listPD.get(0).Contact_Edition_Mapping__r.Contact__c;
                mapObjNameSobject.put('Exhibitor_Account', listPD.get(0).getSObject('Contact_Edition_Mapping__r').getSObject('Account__r'));
            }
        }
        if(String.isNotBlank(cemId)){  
            for(Contact_Edition_Mapping__c con : [SELECT Contact__c FROM Contact_Edition_Mapping__c WHERE Primary_Contact_Edition_Mapping__c =:cemId AND isSecondary__c = true AND Edition__c =:cm.Edition__c WITH SECURITY_ENFORCED])	  
            {
                ContactIds.add(Con.Contact__c);
            }       
            for( User u : [SELECT Id,Name,UserName,Email FROM User WHERE ContactId=:ContactIds WITH SECURITY_ENFORCED])
            {
                UsersSetToSendNotification.add(u.id);
                UserSetofEmailAddress.add(u.Email);
            }          
            List<User> exhUser = [Select Id,Name,UserName From User Where ContactId=:exhibitorContact WITH SECURITY_ENFORCED LIMIT 1];
            if(!exhUser.isEmpty()){
                mapObjNameSobject.put('Exhibitor_User', exhUser.get(0));
            }
        }
        if(String.isNotBlank(cm.Edition__c)){
            mapObjNameSobject.put(Contractor_Mapping__c.Edition__c.getDescribe().getReferenceTo()[0].getDescribe().getName(), cm.getSObject('Edition__r'));
        }
        if(String.isNotBlank(cm.Account__c)){
            mapObjNameSobject.put('ContractorAccount', cm.getSObject('Account__r'));
        }

        List<Stand_Detail__c> lisSD = [SELECT Id,Is_Three_side_open_stand__c,IsRigging__c,Is_Two_side_open_stand__c,Rigging_Height__c,Stand_Height__c,Stand_Type__c,Stand_Detail_Submitted_On__c,Is_One_side_open_stand__c,IsDoubleDecker__c,Is_Heavy_Machinery__c,Island_Booth_4_sides__c,Rejection_Reason__c From Stand_Detail__c Where Contractor_Mapping__c=:cm.Id WITH SECURITY_ENFORCED LIMIT 1];
        if(!lisSD.isEmpty()){
            mapObjNameSobject.put('Stand_Detail__c', lisSD.get(0));
        }

        List<Event_Edition_Email_Template__c> listEditionEmailTemplates = [SELECT Id, Name, Subject__c,Content__c,Edition__c,Template_Code__c,From_Email_Address__c,Edition__r.Informa_Logo__c,Edition__r.Informa_logo_url__c FROM Event_Edition_Email_Template__c WHERE Edition__c =:cm.Edition__c WITH SECURITY_ENFORCED];
        Map<String,Event_Edition_Email_Template__c> mapEditionEmailTemplates = new Map<String,Event_Edition_Email_Template__c>();
        for(Event_Edition_Email_Template__c temp : listEditionEmailTemplates){
            mapEditionEmailTemplates.put(temp.Template_Code__c,temp);
        }

        Map<String,List<Email_Template_Keyword__mdt>> mapObjectNameAndListKeywords = Trig_UpdateStatusOnFormData_Handler.getEmailTemplateKeyWordsByModule('Stand Contractor');
        Map<String,Email_Template_Types_Mapping__mdt> mapEmailTemplateTypeMapping = Trig_UpdateStatusOnFormData_Handler.getEmailTemplateTypesByModule('Stand Contractor');

        List<Operations_Team_Member__c> listOTM = [SELECT Operations_Team__c,User__c,User__r.Email,Team_Roles__c FROM Operations_Team_Member__c WHERE Operations_Team__c =:cm.Edition__r.Operations_Team__c AND User__c !=null WITH SECURITY_ENFORCED];
        System.debug(LoggingLevel.debug, '###################'+listOTM);
        
        Map<String,Id> mapAddressOrgwideEmailId = new Map<String,Id>();
        for(OrgWideEmailAddress oea : [SELECT Id,Address FROM OrgWideEmailAddress]){ //WITH SECURITY_ENFORCED
            mapAddressOrgwideEmailId.put(oea.Address, oea.Id);
        }

        List<Messaging.SingleEmailMessage> listEmails = new List<Messaging.SingleEmailMessage>();
        
        String commURL = System.Label.CommunityURL;
        String documentURL = System.Label.Document_URL;

        for(String notiType : listEmailTypes){
            
            String emailType = notiType.replace('Email:', '');
            if(notiType.startsWith('Email:') && mapEmailTemplateTypeMapping.containsKey(emailType)){
                Email_Template_Types_Mapping__mdt ettm = mapEmailTemplateTypeMapping.get(emailType);
                if(mapEditionEmailTemplates.containsKey(ettm.Email_Template_Code__c)){
                    /** fetch Email Template on basis of the matching template title**/
                    Event_Edition_Email_Template__c emailTemplate = mapEditionEmailTemplates.get(ettm.Email_Template_Code__c);

                    String informaLogoURL = '';
                    if(String.isNotBlank(emailTemplate.Edition__r.Informa_Logo__c)){
                        informaLogoURL = '<img src="'+emailTemplate.Edition__r.Informa_logo_url__c+'" />';
                    }

                    String body = emailTemplate.Content__c;
                    String subject = emailTemplate.Subject__c;
                    /** fetch email from org wide email address matching with the From email address on Email Template**/
                    Id oweaId = mapAddressOrgwideEmailId.get(emailTemplate.From_Email_Address__c);
                    List<String> emailIds = new List<String>();
                    
                    if(ettm.Operations_Team__c && String.isNotBlank(cm.Edition__r.Operations_Team__c)){
                        if(!listOTM.isEmpty()){
                            for(Operations_Team_Member__c otm : listOTM){
                                if(!emailIds.contains(otm.User__r.Email)){
                                    emailIds.add(otm.User__r.Email);
                                }
                            }
                        }
                    }
                    //System.debug(LoggingLevel.debug, '###################2222'+emailIds);
                    if(!String.isBlank(body) || !String.isBlank(subject)){
                        body = body.replace('{Informa Logo}',informaLogoURL); 
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
                                        value = value.replace(' 00:00:00','');
                                    }
                                    body = body.replace(etk.Keyword__c,value); 
                                    subject = subject.replace(etk.Keyword__c,value);
                                }
                            }
                        }
                    }
                    
                    // Define the email
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    for(String key : mapObjectNameAndListKeywords.keySet()){
                        for(Email_Template_Keyword__mdt etk : mapObjectNameAndListKeywords.get(key)){
                            body = body.replace(etk.Keyword__c,''); 
                            subject = subject.replace(etk.Keyword__c,'');
                        }
                    }
                    
                    //System.debug(LoggingLevel.DEBUG, 'body==='+body);
                    //System.debug(LoggingLevel.DEBUG, 'subject==='+subject);

                    if(oweaId !=null){
                        email.setOrgWideEmailAddressId(oweaId);
                    }
                    //Replace content document image
                    body = body.replaceAll(documentURL, commURL+'/IMCC');
                    body = body.replace('<table', '<table style="border-collapse:collapse;"');

                    email.setHtmlBody(body); 
                    email.setSubject(subject); 
                    email.setSaveAsActivity(false);                  
                    if(ettm.Customer_Only__c){ 
                        email.setTargetObjectId(exhibitorContact);
                        emailIds.addAll(UserSetofEmailAddress);
                    }
                    if(ettm.Contractor__c && String.isNotBlank(cm.Contractor_CEM__c)){ 
                        email.setTargetObjectId(cm.Contractor_CEM__r.Contact__c);
                        if(cm.Is_Self_Managed__c) {
                            emailIds.addAll(UserSetofEmailAddress);
                        }
                    }
                    if(!emailIds.isEmpty()){
                        email.setToAddresses(emailIds);
                    }
                    //System.debug(LoggingLevel.debug,'testEMAIL::'+email);
                    listEmails.add(email);
                }
            }
            else if(notiType.startsWith('Portal:')){
                String portalNotiType = notiType.replace('Portal:', '');
                Purchase_Data__c pd = (Purchase_Data__c)mapObjNameSobject.get('Purchase_Data__c');
                Account exhibitorAccount = (Account)mapObjNameSobject.get('Exhibitor_Account');
                Edition__c edition = (Edition__c)mapObjNameSobject.get('Edition__c');
                Event_Tabs__c tabCodeStandDesign = (Event_Tabs__c)mapObjNameSobject.get('EventTabStandDesign');
                Account contractorAccount = (Account)mapObjNameSobject.get('ContractorAccount');
                Event_Tabs__c tabCodeMyExhibitor = (Event_Tabs__c)mapObjNameSobject.get('EventTabMyExhibitor');
                User exhibitorUser = (User)mapObjNameSobject.get('Exhibitor_User');
                User contractorUser = (User)mapObjNameSobject.get('Contractor_User');
                Stand_Detail__c sd = (Stand_Detail__c)mapObjNameSobject.get('Stand_Detail__c');
                Boolean isSend = false;
                Set<String> recipientsIds = new Set<String>();
                String title = 'Stand Design: ' + pd.Booth_Number__c;
                String body = '';
                String target = '';
                if(portalNotiType == 'Contractor accepted nomination CUS' && exhibitorUser != null && contractorUser != null && exhibitorAccount!=null && tabCodeStandDesign!=null){
                    isSend = true;
                    target = '{type:"comm__namedPage",attributes:{name: "StandContractors__c"},state:{accId:"'+exhibitorAccount.Id+'",edcode:"'+edition.Edition_Code__c+'",tabId:"'+tabCodeStandDesign.Tab_Code__c+'"}}';
                    body = 'Contractor ' +contractorUser.Name+ ' has accepted the nomination.';
                    recipientsIds.addAll(UsersSetToSendNotification);
                }
                if(portalNotiType == 'Contractor rejected nomination CUS' && exhibitorUser != null && contractorUser != null && tabCodeStandDesign!=null){
                    isSend = true;
                    target = '{type:"comm__namedPage",attributes:{name: "StandContractors__c"},state:{accId:"'+exhibitorAccount.Id+'",edcode:"'+edition.Edition_Code__c+'",tabId:"'+tabCodeStandDesign.Tab_Code__c+'"}}';
                    body = 'Contractor ' +contractorUser.Name+ ' has rejected the nomination. Rejection Reason: "'+cm.Rejection_Reason__c+ '"';
                    recipientsIds.addAll(UsersSetToSendNotification);
                }
                if(portalNotiType == 'Ops team accepted New contractor CUS' && exhibitorUser != null && tabCodeStandDesign!=null){
                    isSend = true;
                    target = '{type:"comm__namedPage",attributes:{name: "StandContractors__c"},state:{accId:"'+exhibitorAccount.Id+'",edcode:"'+edition.Edition_Code__c+'",tabId:"'+tabCodeStandDesign.Tab_Code__c+'"}}';
                    body = 'Operations team has accepted the new contractor.';
                    recipientsIds.addAll(UsersSetToSendNotification);
                }
                if(portalNotiType == 'Ops team rejected New contractor CUS' && exhibitorUser != null && tabCodeStandDesign!=null){
                    isSend = true;
                    target = '{type:"comm__namedPage",attributes:{name: "StandContractors__c"},state:{accId:"'+exhibitorAccount.Id+'",edcode:"'+edition.Edition_Code__c+'",tabId:"'+tabCodeStandDesign.Tab_Code__c+'"}}';
                    body = 'Operations team has rejected the new contractor. Rejection Reason: "'+cm.Rejection_Reason__c+ '"';
                    recipientsIds.addAll(UsersSetToSendNotification);
                }
                if(portalNotiType == 'Stand Design Permission to Build CUS' && exhibitorUser != null && tabCodeStandDesign!=null){
                    isSend = true;
                    target = '{type:"comm__namedPage",attributes:{name: "StandContractors__c"},state:{accId:"'+exhibitorAccount.Id+'",edcode:"'+edition.Edition_Code__c+'",tabId:"'+tabCodeStandDesign.Tab_Code__c+'"}}';
                    body = 'Stand design status has been update to "Permission to Build"';
                    recipientsIds.addAll(UsersSetToSendNotification);
                }


                if(portalNotiType == 'Contractor Nominated Con' && !cm.Is_Self_Managed__c && contractorUser != null && exhibitorUser!=null && tabCodeMyExhibitor!=null){
                    isSend = true;
                    target = '{type:"comm__namedPage",attributes:{name: "StandDesign__c"},state:{accId:"'+contractorAccount.Id+'",edcode:"'+edition.Edition_Code__c+'",tabId:"'+tabCodeMyExhibitor.Tab_Code__c+'"}}';
                    body = 'Exhibitor ' +exhibitorUser.Name+ 'has nominated you as contractor.';
                    recipientsIds.add(contractorUser.Id);
                }
                if(portalNotiType == 'In Review Con' && contractorUser != null && tabCodeMyExhibitor!=null){
                    isSend = true;
                    target = '{type:"comm__namedPage",attributes:{name: "StandDesign__c"},state:{accId:"'+contractorAccount.Id+'",edcode:"'+edition.Edition_Code__c+'",tabId:"'+tabCodeMyExhibitor.Tab_Code__c+'"}}';
                    body = 'Stand design status has been update to "In Review"';
                    if(cm.Is_Self_Managed__c){recipientsIds.addAll(UsersSetToSendNotification);}else{recipientsIds.add(contractorUser.Id);}
                }
                if(portalNotiType == 'Pending Sales Approval Con' && contractorUser != null && tabCodeMyExhibitor!=null){
                    isSend = true;
                    target = '{type:"comm__namedPage",attributes:{name: "StandDesign__c"},state:{accId:"'+contractorAccount.Id+'",edcode:"'+edition.Edition_Code__c+'",tabId:"'+tabCodeMyExhibitor.Tab_Code__c+'"}}';
                    body = 'Stand design status has been update to "Pending Sales Approval"';
                    if(cm.Is_Self_Managed__c){recipientsIds.addAll(UsersSetToSendNotification);}else{recipientsIds.add(contractorUser.Id);}
                }
                if(portalNotiType == 'Stand Design Rejected/Incomplete Con' && contractorUser != null && tabCodeMyExhibitor!=null){
                    isSend = true;
                    target = '{type:"comm__namedPage",attributes:{name: "StandDesign__c"},state:{accId:"'+contractorAccount.Id+'",edcode:"'+edition.Edition_Code__c+'",tabId:"'+tabCodeMyExhibitor.Tab_Code__c+'"}}';
                    body = 'Stand design status has been update to "Stand Design Rejected/Incomplete" Rejection Reason: "'+sd.Rejection_Reason__c+ '".';
                    if(cm.Is_Self_Managed__c){recipientsIds.addAll(UsersSetToSendNotification);}else{recipientsIds.add(contractorUser.Id);}
                }
                if(portalNotiType == 'Stand Design Resubmitted Con' && contractorUser != null && tabCodeMyExhibitor!=null){
                    isSend = true;
                    target = '{type:"comm__namedPage",attributes:{name: "StandDesign__c"},state:{accId:"'+contractorAccount.Id+'",edcode:"'+edition.Edition_Code__c+'",tabId:"'+tabCodeMyExhibitor.Tab_Code__c+'"}}';
                    body = 'Stand design status has been update to "Stand Design Resubmitted"';
                    if(cm.Is_Self_Managed__c){recipientsIds.addAll(UsersSetToSendNotification);}else{recipientsIds.add(contractorUser.Id);}
                }
                if(portalNotiType == 'Pending Venue Approval Con' && contractorUser != null && tabCodeMyExhibitor!=null){
                    isSend = true;
                    target = '{type:"comm__namedPage",attributes:{name: "StandDesign__c"},state:{accId:"'+contractorAccount.Id+'",edcode:"'+edition.Edition_Code__c+'",tabId:"'+tabCodeMyExhibitor.Tab_Code__c+'"}}';
                    body = 'Stand design status has been update to "Pending Venue Approval"';
                    if(cm.Is_Self_Managed__c){recipientsIds.addAll(UsersSetToSendNotification);}else{recipientsIds.add(contractorUser.Id);}
                }
                if(portalNotiType == 'Tentative Approval Con' && contractorUser != null && tabCodeMyExhibitor!=null){
                    isSend = true;
                    target = '{type:"comm__namedPage",attributes:{name: "StandDesign__c"},state:{accId:"'+contractorAccount.Id+'",edcode:"'+edition.Edition_Code__c+'",tabId:"'+tabCodeMyExhibitor.Tab_Code__c+'"}}';
                    body = 'Stand design status has been update to "Tentative Approval"';
                    if(cm.Is_Self_Managed__c){recipientsIds.addAll(UsersSetToSendNotification);}else{recipientsIds.add(contractorUser.Id);}
                }
                if(portalNotiType == 'Cancelled Con' && contractorUser != null && tabCodeMyExhibitor!=null){
                    isSend = true;
                    target = '{type:"comm__namedPage",attributes:{name: "StandDesign__c"},state:{accId:"'+contractorAccount.Id+'",edcode:"'+edition.Edition_Code__c+'",tabId:"'+tabCodeMyExhibitor.Tab_Code__c+'"}}';
                    body = 'Stand design status has been update to "Cancelled"';
                    if(cm.Is_Self_Managed__c){recipientsIds.addAll(UsersSetToSendNotification);}else{recipientsIds.add(contractorUser.Id);}
                }
                if(portalNotiType == 'Permission to Build Con' && contractorUser != null && tabCodeMyExhibitor!=null){
                    isSend = true;
                    target = '{type:"comm__namedPage",attributes:{name: "StandDesign__c"},state:{accId:"'+contractorAccount.Id+'",edcode:"'+edition.Edition_Code__c+'",tabId:"'+tabCodeMyExhibitor.Tab_Code__c+'"}}';
                    body = 'Stand design status has been update to "Permission to Build"';
                    if(cm.Is_Self_Managed__c){recipientsIds.addAll(UsersSetToSendNotification);}else{recipientsIds.add(contractorUser.Id);}
                }
                if(isSend){
                    String titleBody = title + '###' + body;
                    notifyUsers(recipientsIds, target, titleBody); 
                }
            }
        }

        // Send the email
        if(!listEmails.isEmpty()){
            Messaging.sendEmail(listEmails, false);
        }
    }

    /**
    * @description  IMCC-208 notifyUsers
    * @param  recipientsIds
    * @param  target
    * @param  titleBody
    */
    public static void notifyUsers(Set<String> recipientsIds, String target, String titleBody) {

        // Get the Id for our custom notification type
        CustomNotificationType notificationType = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName='Send_Status_Notification'];
        
        // Create a new custom notification
        Messaging.CustomNotification notification = new Messaging.CustomNotification();

        // Set the contents for the notification
        notification.setTitle(titleBody.split('###')[0]);
        notification.setBody(titleBody.split('###')[1]);

        // Set the notification type and target
        notification.setNotificationTypeId(notificationType.Id);
        notification.setTargetPageRef(target);
        
        // Actually send the notification
        try {
            notification.send(recipientsIds);
        }
        catch (Exception e) {
            System.debug(LoggingLevel.debug, 'Problem sending notification: ' + e.getMessage());
        }
    }
}