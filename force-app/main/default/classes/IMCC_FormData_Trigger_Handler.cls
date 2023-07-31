/**
* Created/Modified By    : Girikon(Deepak)
* Created On             : 06-06-2022
* @description           : This trigger helper class is for updating form data overall status
* Test Class             : FBUtilTest
* Code Coverage          : 85%
* Modified by 
**/
public with sharing class IMCC_FormData_Trigger_Handler {
    /**
    * @description  to update form data overall status
    * @param  listNewFD
    * @param  oldMapFD
    * @param isAfter
    */
    public static void updateFormDataOverallStatus(List<Form_Data__c> listNewFD , Map<Id,Form_Data__c> oldMapFD, Boolean isAfter){
        if(isAfter){
            Set<Id> formPermIds = new Set<Id>();
            Set<Id> cemIds = new Set<Id>();
            for(Form_Data__c fd: listNewFD){
                if(fd.Status1__c != oldMapFD.get(fd.Id).Status1__c && String.isNotBlank(fd.Purchase_Data__c)){
                    formPermIds.add(fd.Forms_Permission__c);
                    cemIds.add(fd.Contact_Edition_Mapping__c);
                }
            }
            List<Form_Data__c> listFD = [SELECT Id,Is_Active__c,Forms_Permission__r.Form_Allocation__c,Forms_Permission__r.Form_Allocation__r.Approval_Required__c,Status1__c,Contact_Edition_Mapping__c FROM Form_Data__c WHERE Forms_Permission__c IN:formPermIds AND Contact_Edition_Mapping__c IN:cemIds AND Forms_Permission__r.Form_Allocation__r.Form_Entry__c IN ('One Per Booth','Multiple Per Booth') WITH SECURITY_ENFORCED];
            Map<String,List<Form_Data__c>> mapKeyListFD = new Map<String,List<Form_Data__c>>();
            Map<String,Boolean> mapFAllocApprovalReq = new Map<String,Boolean>();
            for(Form_Data__c fd : listFD){
                String key = fd.Forms_Permission__r.Form_Allocation__c + '_' + fd.Contact_Edition_Mapping__c;
                List<Form_Data__c> listFD2 = (mapKeyListFD.containsKey(key)?mapKeyListFD.get(key):(new List<Form_Data__c>()));
                if(fd.Is_Active__c){
                    listFD2.add(fd);
                }
                mapKeyListFD.put(key, listFD2);
                mapFAllocApprovalReq.put(fd.Forms_Permission__r.Form_Allocation__c, fd.Forms_Permission__r.Form_Allocation__r.Approval_Required__c);
            }

            List<Form_Data__c> listUpdate = new List<Form_Data__c>();
            for(String key : mapKeyListFD.keySet()){
                String formAllocId = key.split('_').get(0);
                Boolean approvalRequired = mapFAllocApprovalReq.get(formAllocId);
                List<Form_Data__c> listFD2 = mapKeyListFD.get(key);
                String tempStatus = 'Not Started';
                Integer notStarted = 0;
                Integer viewed = 0;
                Integer inProgress = 0;
                Integer inReview = 0;
                Integer approved = 0;
                Integer rejected = 0;
                Integer submitted = 0;
                //system.debug('listFD2 ' +listFD2);
                for(Form_Data__c fd : listFD2){
                    //system.debug('Form Data Status ' +fd.Status1__c);
                    if(fd.Status1__c == 'Not Started'){
                        notStarted++;
                    }
                    if(fd.Status1__c == 'Viewed'){
                        viewed++;
                    }
                    if(fd.Status1__c == 'In Progress'){
                        inProgress++;
                    }
                    if(fd.Status1__c == 'In Review'){
                        inReview++;
                    }
                    if(fd.Status1__c == 'Approved'){
                        approved++;
                    }
                    if(fd.Status1__c == 'Rejected'){
                        rejected++;
                    }
                    if(fd.Status1__c == 'Submitted' || fd.Status1__c == 'Resubmitted'){
                        submitted++;
                    }
                    if(approvalRequired){
                        if(listFD2.size() == notStarted){
                            tempStatus = 'Not Started';
                        }
                        else if(viewed > 0 && inProgress == 0 && inReview == 0 && approved == 0 && rejected == 0 && submitted == 0){
                            tempStatus = 'Viewed';
                        }
                        else if((notStarted > 0 || viewed > 0 )){
                            tempStatus = 'In Progress';
                            system.debug('tempStatus1 ' +tempStatus);
                        }
                        else{
                            tempStatus = 'In Progress';
                            if(inProgress == 0 && inReview > 0 && rejected == 0){
                                tempStatus = 'In Review';
                                //system.debug('tempStatus2 ' +tempStatus);
                            }
                            if(inProgress == 0 && inReview == 0 && rejected == 0 && approved > 0){
                                tempStatus = 'Approved';
                            }
                            if(listFD2.size() == rejected){
                                tempStatus = 'Rejected';
                            }
                        }
                    }
                    else{
                        if(listFD2.size() == notStarted){
                            tempStatus = 'Not Started';
                        }
                        else if(viewed > 0 && inProgress == 0 && inReview == 0 && approved == 0 && rejected == 0 && submitted == 0){
                            tempStatus = 'Viewed';
                        }
                        else{
                            tempStatus = 'In Progress';
                            if(listFD2.size() == submitted){
                                tempStatus = 'Submitted';
                            }
                        }
                    }
                }
                for(Form_Data__c fd : listFD2){
                    listUpdate.add(new Form_Data__c(Id=fd.Id,Overall_Status__c=tempStatus));
                }
            }
            if(!listUpdate.isEmpty()){
                update listUpdate;
            }
        }
        else{
            updateFormDataOverallStatus(listNewFD, oldMapFD);
        }
    }

    /**
    * @description  to update form data overall status Before Insert/Update
    * @param  listNewFD
    * @param  oldMapFD
    */
    public static void updateFormDataOverallStatus(List<Form_Data__c> listNewFD, Map<Id,Form_Data__c> oldMapFD){
        for(Form_Data__c fd: listNewFD){
            if(oldMapFD == null || (fd.Status1__c != oldMapFD.get(fd.Id).Status1__c && String.isBlank(fd.Purchase_Data__c))){
                fd.Overall_Status__c = fd.Status1__c;
            }
        }
    }
}