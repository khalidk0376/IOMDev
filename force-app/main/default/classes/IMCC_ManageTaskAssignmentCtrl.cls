/**
* Created/Modified By         : Girikon(Mukesh)
* Created On/Last Modified By : 06/19/2023
* @description                : This class is used to fetch forms permission and Contact Edition Mapping and also to update some fields on Form Data Object
* Methods                     : getTasksForAssignment
* Apex Class                  : IMCC_ManageTaskAssignmentCtrl 
* Apex Test Class             : IMCC_ManageTaskAssignmentCtrl_Test

**/
public with sharing class IMCC_ManageTaskAssignmentCtrl {
    /**
* @description fetch forms permissions and Contact Edition Mapping
* @param  eventCode
* @param  accountId
* @param  tabId
* @return Map<String,Object>
*/
    @AuraEnabled
    public static Map<String,Object> getTasksForAssignment(String eventCode, String accountId, String tabId){
        Map<Id,Form_Data__c> mapFormData = new Map<Id,Form_Data__c>();
        Map<Id,List<Form_Response_Entry__c>> mapEntries = new Map<Id,List<Form_Response_Entry__c>>();
        List<Purchase_Data__c> listPD = new List<Purchase_Data__c>();
        String stanTabType = '';
        Map<String,Object> mapCEMDetails = IMCC_UtilityMethods.getContactEditionMappings(eventCode, accountId);
        String conEdMApId;
        String myRole = '';
        List<Contact_Edition_Mapping__c> conEdMapLst = (List<Contact_Edition_Mapping__c>)mapCEMDetails.get('cemList');
        try{
            if(!conEdMapLst.isEmpty()){
                if(String.isNotBlank(conEdMapLst.get(0).Primary_Contact_Edition_Mapping__c)){
                    conEdMApId = conEdMapLst.get(0).Primary_Contact_Edition_Mapping__c;
                }
                else{
                    conEdMApId = conEdMapLst.get(0).Id;
                }
                myRole = conEdMapLst.get(0).Role__c;
            }
            
            //conEdMapLst = [SELECT Id,Name,Access_Type__c,Account__c,Account__r.Name,CC_Status__c,Contact__c,Edition__c,Relationship_Status__c,isSecondary__c,Edition__r.Form_Setting__c from Contact_Edition_Mapping__c where Contact__c =: u.ContactId And Account__c =: accountId And Relationship_Status__c = 'Active' And Edition__r.Edition_Code__c =: eventCode WITH SECURITY_ENFORCED];
            
            if(!conEdMapLst.isEmpty()){
                listPD = FormPreviewController.getRelatedBooths(conEdMApId);
                
                List<Event_Tabs__c> evntTabLst = [SELECT id,Name,Standard_Tab_Type__c,Tab_Code__c,Tab_Type__c FROM Event_Tabs__c WHERE Tab_Code__c =: tabId WITH SECURITY_ENFORCED];
                
                if(!evntTabLst.isEmpty()){
                    stanTabType = evntTabLst[0].Standard_Tab_Type__c;
                }
                
                if(!evntTabLst.isEmpty()){                    
                    //get both form and manual permission // Form_Allocation__r.Feature_Category__c=:featureCategory and 
                    Map<Id,Forms_Permission__c> formPermIds = new Map<Id,Forms_Permission__c>([SELECT Id FROM Forms_Permission__c WHERE Tab_User_Type__r.User_Type__c=:conEdMapLst[0].Access_Type__c and Is_Active__c = true and Form_Allocation__r.Form_Status__c = 'Visible' AND Form_Allocation__r.Form_Setting__c=:conEdMapLst[0].Edition__r.Form_Setting__c WITH SECURITY_ENFORCED]);
                    
                    mapFormData = new Map<Id,Form_Data__c>([SELECT Id,Feature_Category__c,Assign_To__c,Assign_To__r.Contact__c,Assign_To__r.Contact__r.Name,Forms_Permission__r.Form_Allocation__r.Name,Forms_Permission__r.Form_Allocation__r.Form__r.Category__c,Forms_Permission__r.Form_Allocation__r.Form_Type__c,Forms_Permission__r.Form_Allocation__r.Form_Category__c,Forms_Permission__r.Form_Allocation__r.Form_Provider__c,Forms_Permission__r.Form_Allocation__r.Submission_Deadline__c,Forms_Permission__r.Form_Allocation__r.Allow_Submissions_after_Due_date__c,Forms_Permission__r.Form_Allocation__r.Form__c,Is_Viewed__c,Forms_Permission__r.Form_Allocation__r.Approval_Required__c,Status1__c,Not_Applicable__c,Forms_Permission__r.Form_Allocation__r.Form_Url__c,Forms_Permission__r.Form_Allocation__r.Form_Heading__c,Forms_Permission__r.Form_Allocation__r.Form_Entry__c,Forms_Permission__r.Form_Allocation__r.CountMultiSubmission__c,Is_Agreed__c,Approved_Responses__c,Rejected_Responses__c,Total_Responses__c,Submitted_Responses__c,Forms_Permission__r.Form_Allocation__r.Entry_Limit__c,Forms_Permission__r.Form_Allocation__r.Feature_Category__c,Forms_Permission__r.Form_Allocation__r.Booth_Product_Types__c,Purchase_Data__c,Overall_Status__c FROM Form_Data__c WHERE Contact_Edition_Mapping__c =:conEdMApId AND Forms_Permission__c IN:formPermIds.keySet() AND Is_Active__c=true WITH SECURITY_ENFORCED ORDER BY Forms_Permission__r.Form_Allocation__r.Name]);
                    
                    List<Form_Response_Entry__c> listEntries = [SELECT Id,Name,Content_Version__c,File_Name__c,Approval_Status__c,Contact_Edition_Mapping__c,Current_Page__c,Current_Page_No__c,Entry_Number__c,Form_Data__c,Form_Unlock__c,Girikon_Form__c,Purchase_Data__c,Rejection_Reason__c,Status__c,Total_Pages__c,User__c,User_Type1__c,Purchase_Data__r.Booth_Number__c,Version__c FROM Form_Response_Entry__c WHERE Form_Data__c IN:mapFormData.keySet() WITH SECURITY_ENFORCED];
                    for(Form_Response_Entry__c entry : listEntries){
                        List<Form_Response_Entry__c> listEntries2 = (mapEntries.containsKey(entry.Form_Data__c)?mapEntries.get(entry.Form_Data__c):(new List<Form_Response_Entry__c>()));
                        listEntries2.add(entry);
                        mapEntries.put(entry.Form_Data__c,listEntries2);
                    }
                }
            }
        }
        catch (Exception e) {
            //System.debug(LoggingLevel.DEBUG, 'Exception hit ' +e.getMessage());
            //HandleAllCustomException.logException(e,'Forms_Permission__c', 'After Insert');
            String mesg = String.isNotBlank(e.getMessage()) ? e.getMessage():'';  
            String stackTrace = e.getStackTraceString().substringBefore('\n');             
            throw new AuraHandledException('Message='+mesg+'Stacktrace='+stackTrace);
        } 
        return new Map<String,Object>{
            'listFormData'=>mapFormData.values(),
                'mapEntries'=>mapEntries,
                'listPD'=>listPD,
                'conEdMapId'=>conEdMApId,
                'contactId'=>(conEdMapLst.size()>0?conEdMapLst[0].Contact__c:null),
                'isCEMSecondary'=>(conEdMapLst.size()>0?conEdMapLst[0].isSecondary__c:false),
                'stanTabType'=>stanTabType,
                'teamMembers' => teamMemberList(eventCode,accountId),
                'myRole'=>myRole
                };
                    }
    
    @AuraEnabled
    public static Contact_Edition_Mapping__c getLoggedInUserInfo(String eventCode, String accountId){
        Map<String,Object> mapCEMDetails = IMCC_UtilityMethods.getContactEditionMappings(eventCode, accountId);
        return (Contact_Edition_Mapping__c)mapCEMDetails.get('cem');
    }
    
    private static List<Contact_Edition_Mapping__c> teamMemberList(String eventCode, String accountId){   
        List<Contact_Edition_Mapping__c> teamMemberList = [SELECT Id,Contact__r.Name,Role__c FROM Contact_Edition_Mapping__c
                                                           WHERE Account__c =:accountId AND Relationship_Status__c = 'Active'
                                                           AND Edition__r.Edition_Code__c=:eventCode AND (Role__c != null AND Role__c !='' )
                                                           WITH SECURITY_ENFORCED];
        return teamMemberList;        
    }
    
    @AuraEnabled
    public static Form_Data__c assignFormToTeam(String eventCode, String accountId, List<Form_Data__c> formDataToUpdate, String tabId, String tabName){
        
        Set<Id> fDUpdatedIds = new Set<Id>();
        Set<Id> teamMemberIds = new Set<Id>();
        try {
            update formDataToUpdate;
            formDataToUpdate = [SELECT Id, Assign_To__c,Assign_To__r.Contact__r.Name FROM Form_Data__c WHERE Id=:formDataToUpdate[0].Id LIMIT 1];
            
            Map<String,Object> mapCEMDetails = IMCC_UtilityMethods.getContactEditionMappings(eventCode, accountId);
            Contact_Edition_Mapping__c adminCEM =  (Contact_Edition_Mapping__c)mapCEMDetails.get('cem');
            
            for(Form_Data__c fd : formDataToUpdate){
                if(fd.Assign_To__c != null && adminCEM.Id != fd.Assign_To__c){
                    teamMemberIds.add(fd.Assign_To__c);
                }
            }
              if(!teamMemberIds.isEmpty()){
                    IMCC_WelcomeEmailNotification.teamMemberNotification(teamMemberIds,'TaskASSIGNEMAIL',tabId,tabName);
                }
       } 
        catch (Exception ex){
            system.debug('error'+ex.getLineNumber());
            system.debug('error1'+ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage());
        }
        return formDataToUpdate[0];
    }
}