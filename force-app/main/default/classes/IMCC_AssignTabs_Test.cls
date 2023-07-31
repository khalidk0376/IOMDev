/*
Created By    : Aishwarya[IMCC-992]
Class         : IMCC_AssignTabs
Created/LastModified Date   : 
*/

@isTest
private class IMCC_AssignTabs_Test{
    
    @isTest
    private static void tabDataInsert()
    {
        List<Event_Setting__c> eveSettingObj = IMCC_TestUtilities.createEventSetting(250);
        Id eveSettingObjId = eveSettingObj[0].Id;
        
        System.assertEquals(eveSettingObjId,eveSettingObj[0].Id, 'both values must be equal');
        List<Event_Tabs__c> evntTabsLst = IMCC_TestUtilities.createEventTabs(eveSettingObjId,5,10,null,'Standard','Forms',null);
        System.assertEquals(evntTabsLst.Size(),5, 'evntTabsLst size should be 5');
        
        List<String> listUserTypes = new List<String>();
        String recordId = evntTabsLst[0].id;
        String fieldName = 'Event_Tab__c';
        List<Tab_User_Type__c> tabUserLst;
        
        tabUserLst = IMCC_TestUtilities.createTabUserType(evntTabsLst[0].id,1,'Exhibitor');
        tabUserLst = IMCC_TestUtilities.createTabUserType(evntTabsLst[0].id,1,'Agent');
        tabUserLst = IMCC_TestUtilities.createTabUserType(evntTabsLst[0].id,1,'Online');
        listUserTypes.add('Exhibitor');
        listUserTypes.add('Online');
        listUserTypes.add('Contractor');
        Test.startTest();
        IMCC_AssignTabs.assignTabToUsers(listUserTypes, recordId, fieldName);
        IMCC_AssignTabs.assignTabToUsers(listUserTypes, recordId, 'Test');
        Test.stopTest();
    }
    
    @isTest
    private static void tabProductTypeInsert()
    {
        List<Event_Setting__c> eveSettingObj = IMCC_TestUtilities.createEventSetting(250);
        Id eveSettingObjId = eveSettingObj[0].Id;
        //Test.startTest();
        System.assertEquals(eveSettingObjId,eveSettingObj[0].Id, 'both values must be equal');
        List<Event_Tabs__c> evntTabsLst = IMCC_TestUtilities.createEventTabs(eveSettingObjId,5,10,null,'Standard','Forms',null);
        System.assertEquals(evntTabsLst.Size(),5, 'evntTabsLst size should be 5');
        //Test.stopTest();
    }
}