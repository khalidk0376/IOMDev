/**
* Modified By: Girikon(Aishwarya)
* Created On:          22/9/2021
* @description  :      This class covers the code coverage of the class Trig_EventTabHandler and Trigger trig_EventTab
* Methods:             Trig_EventTabHandler_Test
* Apex Class:          Trig_EventTabHandler(90%) 
**/

@isTest
public class Trig_EventTabHandler_Test{
    @isTest static void testdupSeqBeforeInsertHandler()
    {
        List<Event_Tabs__c> objEvtTabList = new List<Event_Tabs__c>();
        List<Event_Setting__c> eveSettingObj = IMCC_TestUtilities.createEventSetting(5);
        Test.StartTest();
            List<Event_Tabs__c> eventTabsObj = IMCC_TestUtilities.createEventTabs(eveSettingObj[0].Id, 10,10,null,null,null,null);
            System.assertEquals(eventTabsObj[0].Sequence__c, 10, 'Sequence should equal to 10');
        	Event_Tabs__c evt=new Event_Tabs__c(Sequence__c=30,ExtTabId__c='TEST19',Tab_Title__c='Test',Event_Setting__c=eveSettingObj[0].Id);
        	insert evt;
            
            /******  Testing addError method of Trigger  ******/
            
            try {
                eventTabsObj[0].Sequence__c = 20;
                eventTabsObj[0].ExtTabId__c='TEST20';
                update eventTabsObj; 
                System.assertNotEquals(eventTabsObj[0].Sequence__c, 10, 'Sequence should equal to 10');
                System.assertEquals(eventTabsObj[2].Sequence__c, 12, 'Sequence should be equal to 12');
            }
            catch(Exception e) {
                System.assert(e.getMessage().contains('You cannot put the same sequence number present in other event tab. Please choose a different sequence number.'), 'Validation Success');
           
            }
        Test.StopTest();
    }
}