/**
* File      :   ImportCampaignMembersCtrl
* Project    :   Service Console Informa
* Created By  :   Garima Gupta(Girikon)
* Test Class  :    Test_ImportCampaignMembersCtrl
* Coverage    :    82%
* Created Date  :   2nd August 2021
 ******************************************************************************************************
* @description :  Apex class to fetch records from Campaign Upload object and then import them as campaign members to Campaign from which the Import campaign button is clicked
 ******************************************************************************************************
* Last Modified By :
*/
public class ImportCampaignMembersCtrl {
    @AuraEnabled
    public static CampaignMembersCountWrapper importMembers(String campaignId){
        CampaignMembersCountWrapper campWrap = new CampaignMembersCountWrapper();
        campWrap.duplicateMem = 0;
        campWrap.memNotFound = 0;
        //system.debug('CampaignId' +campaignId);
        Set<String> emailIds = new Set<String>();
        List<Campaign_Upload_and_Member_mapping__mdt> campMetadataLst = [Select DeveloperName,MasterLabel,Campaign_Member_fields__c,Campaign_Upload_fields__c from Campaign_Upload_and_Member_mapping__mdt];
        String fields = '';
        for(Campaign_Upload_and_Member_mapping__mdt cmpMetadata : campMetadataLst){
            fields += ','+cmpMetadata.Campaign_Upload_fields__c;
        }
        //system.debug('fields ' +fields);
        String query = 'Select Campaign__c,Contact_Email__c,Contact__c,Member_Added__c,Member_Not_Found__c,Duplicate_Member__c '+fields+' from Campaign_Upload__c where Member_Added__c != true and Campaign__c =\''+campaignId+'\'';
        //system.debug('query ' +query);
        List<Campaign_Upload__c> campUploadLst = database.query(query);
        //system.debug('campUploadLst ' +campUploadLst);
        for(Campaign_Upload__c campUpload : campUploadLst){
            if(campUpload.Member_Added__c != true && campUpload.Contact__c == null){
                emailIds.add(campUpload.Contact_Email__c);
            }
        }
        //system.debug('emailIds' +emailIds);
        List<Contact> conLst = [Select id,FirstName,LastName,Email from Contact  where email IN : emailIds Order By CreatedDate asc];
        system.debug('conLst' +conLst);
        Map<String,Contact> mapEmailCon = new Map<String,Contact>();
        for(Contact con : conLst){
            mapEmailCon.put(con.Email,con);
        }
        //system.debug('mapEmailCon 1' +mapEmailCon);
        set<string> duplicateCon = new set<string>();
        List<CampaignMember> cmpgMemberLst = [Select ContactId,Contact.Email,CampaignId from CampaignMember where CampaignId =:campaignId];
        //system.debug('cmpgMemberLst' +cmpgMemberLst);
        for(CampaignMember cmpgMem : cmpgMemberLst){
            if(mapEmailCon.containsKey(cmpgMem.Contact.Email)){
                mapEmailCon.remove(cmpgMem.Contact.Email);
                duplicateCon.add(cmpgMem.Contact.Email);
            }
        }
        //system.debug('duplicateCon' +duplicateCon);
        set<string> contactId = new set<string>();
        for(CampaignMember cmpgMem : cmpgMemberLst){
            contactId.add(cmpgMem.ContactId);
        }
        
        //system.debug('campMetadataLst ' +campMetadataLst);
        Map<string,string> mapCampMetadata = new Map<string,string>();
        for(Campaign_Upload_and_Member_mapping__mdt campMetadata : campMetadataLst){
            if(!mapCampMetadata.containsKey(campMetadata.Campaign_Member_fields__c)){
                mapCampMetadata.put(campMetadata.Campaign_Member_fields__c,campMetadata.Campaign_Upload_fields__c);
            }
        }
        //system.debug('mapCampMetadata ' +mapCampMetadata);
        //system.debug('mapEmailCon ' +mapEmailCon);
        List<CampaignMember> cmpgMemLst = new List<CampaignMember>();
        List<Campaign_Upload__c> cmpgUploadLst = new List<Campaign_Upload__c>();
        for(Campaign_Upload__c cmpUpload : campUploadLst){
            if(cmpUpload.Contact__c == null && cmpUpload.Member_Added__c != true){
                if(mapEmailCon.containsKey(cmpUpload.Contact_Email__c)){
                    //system.debug('Welcome');
                    CampaignMember cmpgMem = new CampaignMember();
                    cmpgMem.CampaignId = cmpUpload.Campaign__c;
                    cmpgMem.ContactId = mapEmailCon.get(cmpUpload.Contact_Email__c).Id;
                    for(Campaign_Upload_and_Member_mapping__mdt campMetadata : campMetadataLst){
                       cmpgMem.put(campMetadata.Campaign_Member_fields__c,cmpUpload.get(mapCampMetadata.get(campMetadata.Campaign_Member_fields__c)));
                        
                    }
                    cmpgMemLst.add(cmpgMem); 
                    cmpUpload.Member_Added__c = true;
                    if(cmpUpload.Member_Not_Found__c == true){
                    cmpUpload.Member_Not_Found__c = false;  
                    }  
                    cmpgUploadLst.add(cmpUpload);
                    //system.debug('cmpgMemLst ' +cmpgMemLst);
                }
                else if(!mapEmailCon.containsKey(cmpUpload.Contact_Email__c) && !duplicateCon.contains(cmpUpload.Contact_Email__c)){
                    cmpUpload.Member_Not_Found__c = true;
                    cmpgUploadLst.add(cmpUpload);
                    campWrap.memNotFound = campWrap.memNotFound + 1;
                    //system.debug('cmpgUploadLst ' +cmpgUploadLst);
                }
            }
            if(duplicateCon.contains(cmpUpload.Contact_Email__c)){
                cmpUpload.Duplicate_Member__c = true;
                cmpUpload.Member_Added__c = true;
                cmpgUploadLst.add(cmpUpload);
                campWrap.duplicateMem = campWrap.duplicateMem + 1;
                //system.debug('campWrap.duplicateMem 1 ' +campWrap.duplicateMem);
            }
            if(cmpUpload.Contact__c != null && cmpUpload.Member_Added__c != true){
                if(!contactId.contains(cmpUpload.Contact__c)){
                CampaignMember cmpgMem = new CampaignMember();
                cmpgMem.CampaignId = cmpUpload.Campaign__c;
                cmpgMem.ContactId = cmpUpload.Contact__c;
                for(Campaign_Upload_and_Member_mapping__mdt campMetadata : campMetadataLst){
                     cmpgMem.put(campMetadata.Campaign_Member_fields__c,cmpUpload.get(mapCampMetadata.get(campMetadata.Campaign_Member_fields__c)));
                       
                    }
                    cmpgMemLst.add(cmpgMem);
                
                cmpUpload.Member_Added__c = true;
                    if(cmpUpload.Member_Not_Found__c == true){
                        cmpUpload.Member_Not_Found__c = false;  
                    }  
                cmpgUploadLst.add(cmpUpload);  
                }
             }
        }
        if(cmpgMemLst.isEmpty()){
            campWrap.campMembers = 0;
            //.debug('Count ' +campWrap.campMembers);
        }
        else{
            campWrap.campMembers = cmpgMemLst.size();
            //system.debug('Count 1' +campWrap.campMembers);
        }
        //system.debug('campWrap.duplicateMem ' +campWrap.duplicateMem);
        upsert cmpgMemLst;
        update cmpgUploadLst;
        
        return campWrap;
    }
    public class CampaignMembersCountWrapper{
        @AuraEnabled
        public Integer campMembers{get;set;}
        @AuraEnabled
        public Integer duplicateMem{get;set;}
        @AuraEnabled
        public Integer memNotFound{get;set;}
    }
}