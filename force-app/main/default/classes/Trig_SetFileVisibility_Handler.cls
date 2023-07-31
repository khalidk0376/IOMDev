/**
* Created/Modified By: Girikon(Garima)
* Created On:          07/10/2021
* @description  :      This is a handler class for Trigger - Trig_SetFileVisibilityForPdfFloorplan. This is used to give content document access
                       to community users
* Methods:             setFileVisibility
* Apex Class:          Trig_SetFileVisibility_Handler 
* Apex Test Class:     Trig_SetFileVisibility_Handler_Test(100%)
**/


/**
* @description : To give permission of content document to community users
* @param : List<ContentDocumentLink>
* @return : void
**/
public class Trig_SetFileVisibility_Handler {
    public void setFileVisibility(List<ContentDocumentLink> cntntDocLst){
        for (ContentDocumentLink cdl : cntntDocLst) {
            if (cdl.LinkedEntityId.getSObjectType().getDescribe().getName() == 'PDF_Floorplan__c' || 
                cdl.LinkedEntityId.getSObjectType().getDescribe().getName() == 'Q_s_A_s_How_To__c' || 
                cdl.LinkedEntityId.getSObjectType().getDescribe().getName() == 'Form_Allocation__c' ||
                cdl.LinkedEntityId.getSObjectType().getDescribe().getName() == 'Purchase_Summary__c'||
                cdl.LinkedEntityId.getSObjectType().getDescribe().getName() == 'Event_Tabs__c' ||
                cdl.LinkedEntityId.getSObjectType().getDescribe().getName() == 'Event_Edition_Email_Template__c' ||
                cdl.LinkedEntityId.getSObjectType().getDescribe().getName() == 'Stand_Design__c'){
                cdl.visibility = 'AllUsers';
            }
        }
    }
}