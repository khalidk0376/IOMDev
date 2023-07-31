/**
* Created/Modified By: Girikon(Aishwarya)
* Created On:          07/9/2021
* @description  :      This class covers the code coverage of the class IMCC_MarkAsPublishHandler and Trigger - IMCC_trgUpdateMarkAsPublish
* Apex Class:          IMCC_MarkAsPublishHandler(88%) 
**/

@isTest
private class IMCC_MarkAsPublishHandler_Test{

    public static testMethod void headerDataInsert()
    {
        List<Event_Setting__c> eveSettingObj = IMCC_TestUtilities.createEventSetting(250);
        Id eveSettingObjId = eveSettingObj[0].Id;
        
        Test.startTest();
            
            List<Event_Tabs__c> evntTabsLst = IMCC_TestUtilities.createEventTabs(eveSettingObjId,5,10,'3 Column','Custom',null,null);
            System.assertEquals(evntTabsLst.Size(),5, 'evntTabsLst size should be 5');
            
            List<Tab_Context__c> listTabContext = IMCC_TestUtilities.createTabContext2(evntTabsLst[0].Id, 200);
            
            List<Tab_Context__c> listTabContext2 = IMCC_TestUtilities.createTabContext3(evntTabsLst[0].Id, 200);
        Test.stopTest();
    }
}