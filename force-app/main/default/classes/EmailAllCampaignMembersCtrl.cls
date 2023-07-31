/**
* File      :   EmailAllCampaignMembersCtrl
* Project    :   Service Console Informa
* Created By  :   Garima Gupta(Girikon)
* Test Class  :    Test_EmailAllCampaignMembersCtrl
* Coverage    :    81%
* Created Date  :   26th July 2021
 ******************************************************************************************************
* @description : Invocable class to Send Email to Campaign Members
 ******************************************************************************************************
* Last Modified By :
*/
public with sharing class EmailAllCampaignMembersCtrl {
    
    @InvocableMethod
    public static void massEmailCampaignMembers(List<FlowInputs> requests){
        
        Set<id> cmpgIds = new Set<id>();
        //system.debug('requests' +requests);
        for(Id cmpgId : requests[0].campaignIds){
            cmpgIds.add(cmpgId);
        }
        Map<Id,List<CampaignMember>> mapEmailTemCamMem = new Map<Id,List<CampaignMember>>();
        List<Email_Temp_Content_mapping__mdt> mailTempMetadataLst = [Select DeveloperName,MasterLabel,Campaign_Member_fields__c from Email_Temp_Content_mapping__mdt];
        String fields = '';
        for(Email_Temp_Content_mapping__mdt mailTempMetadata : mailTempMetadataLst){
            fields += ','+mailTempMetadata.Campaign_Member_fields__c;
        }
        String query = 'Select Id,Name,CampaignId,ContactId,Campaign.Email_Template_Id__c '+fields+' from CampaignMember where CampaignId in:cmpgIds';
        //system.debug('query ' +query);
        List<CampaignMember> cmpgMemLst = database.query(query);
        //system.debug('campaignIds' +requests[0].campaignIds);
        //system.debug('cmpgMemLst' +cmpgMemLst);
        for(CampaignMember cmpgMem : cmpgMemLst) {
            if(String.isNotBlank(cmpgMem.Campaign.Email_Template_Id__c)){
                if(!mapEmailTemCamMem.containsKey(cmpgMem.Campaign.Email_Template_Id__c)) {
                    mapEmailTemCamMem.put(cmpgMem.Campaign.Email_Template_Id__c, new List<CampaignMember>());
                }
                mapEmailTemCamMem.get(cmpgMem.Campaign.Email_Template_Id__c).add(cmpgMem);
            }
        }
        //system.debug('mapEmailTemCamMem' +mapEmailTemCamMem);
        List<Email_Temp_Content_mapping__mdt> emailContentMetaDataLst = [Select MasterLabel,DeveloperName,Campaign_Member_fields__c from Email_Temp_Content_mapping__mdt];
        Map<String,Email_Temp_Content_mapping__mdt> mapLabelField = new Map<String,Email_Temp_Content_mapping__mdt>();
        for(Email_Temp_Content_mapping__mdt emailContentMetaData : emailContentMetaDataLst){
            if(!mapLabelField.containsKey(emailContentMetaData.MasterLabel)){
                mapLabelField.put(emailContentMetaData.MasterLabel,emailContentMetaData);
            }
        }
        //system.debug('mapLabelField ' +mapLabelField);
        List<EmailTemplate> emailTempLst = [Select id,HtmlValue,Subject,Description from EmailTemplate where Description like '%Campaign%'];
        map<Id,EmailTemplate> emailTempMap = new map<Id,EmailTemplate>();
        for(EmailTemplate emailTemp : emailTempLst){
            emailTempMap.put(emailTemp.Id,emailTemp);
        }
        //system.debug('emailTempMap ' +emailTempMap);
        List<Messaging.SingleEmailMessage> lstEmail = new List<Messaging.SingleEmailMessage>();
        for(Id tempId : mapEmailTemCamMem.keyset()){
            for(CampaignMember campMem : mapEmailTemCamMem.get(tempId)){
                String htmlValue = emailTempMap.get(tempId).HtmlValue;
                for(String metadataLabel : mapLabelField.keyset()){
                    if(!String.isBlank(htmlValue)) {
                        If(htmlValue.Contains(metadataLabel) ){
                            if(!String.isBlank(String.valueof(campMem.get(mapLabelField.get(metadataLabel).Campaign_Member_fields__c)))){
                                //system.debug('String.valueof 1 ' +String.valueof(campMem.get(mapLabelField.get(metadataLabel).Campaign_Member_fields__c)));
                                htmlValue = htmlValue.replace(metadataLabel,String.valueof(campMem.get(mapLabelField.get(metadataLabel).Campaign_Member_fields__c)));
                                system.debug('htmlValue ' +htmlValue);
                            }
                            else{
                                htmlValue = htmlValue.replace(metadataLabel,'');
                            }
                        }
                    }
                }
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setSubject(emailTempMap.get(tempId).Subject);
                mail.setHtmlBody(htmlValue);
                mail.setTargetObjectId(campMem.contactId);
                mail.setTemplateId(tempId);
                lstEmail.add(mail);
                //system.debug('lstEmail ' +lstEmail);
            }
        }
        Messaging.sendEmail(lstEmail);
        
        List<Campaign> cmpgLst = [Select Id,EndDate,Next_Email_Date__c,Email_Start_Date__c,Frequency__c from Campaign where Id In: requests[0].campaignIds];
        List<Campaign> updateCmpgLst = new List<Campaign>();
            for(Campaign cmpg : cmpgLst){
            Integer freqDays = Integer.valueOf(cmpg.Frequency__c);
            system.debug('freqDays' +freqDays);
            If(cmpg.Email_Start_Date__c != null && cmpg.Frequency__c != null && cmpg.Email_Start_Date__c == System.today()){
                if(cmpg.Email_Start_Date__c.addDays(freqDays) < cmpg.EndDate){
                    //system.debug('Next Date' +cmpg.Email_Start_Date__c.addDays(freqDays));
                    cmpg.Next_Email_Date__c = cmpg.Email_Start_Date__c.addDays(freqDays);
                    updateCmpgLst.add(cmpg);
                }
            }
            else If(cmpg.Email_Start_Date__c != null && cmpg.Frequency__c != null && cmpg.Next_Email_Date__c == System.today()){
                if(cmpg.Next_Email_Date__c.addDays(freqDays) < cmpg.EndDate){
                    cmpg.Next_Email_Date__c = cmpg.Next_Email_Date__c.addDays(freqDays);
                    updateCmpgLst.add(cmpg);
                }
            }
        }
        update updateCmpgLst;
        }

    public class FlowInputs {
        @InvocableVariable public List<String> campaignIds;
        }
}