/**
 * @Author      : Himanshu RANA
 * @Date        : 31-08-2020
 * Apex Class : 
 * 
 */
@isTest
private class TriggerInterfaceHelper_Test {
    static testMethod void UnitTest_TriggerHelper_Trig() 
    {
        // Create Trigger test record 
        Trigger__c trig = new Trigger__c(Trigger_Name_Unique__c='UpdateFieldsOnOpportunity_Trig',Enabled__c=true,Object__c='copado__User_Story__c',Run_for_Recordypes__c='All',  Description__c='my test',Execution_Order__c=1,
                                        Before_Update__c=true);
        Insert trig;
        system.assertEquals(trig.Trigger_Name_Unique__c, 'UpdateFieldsOnOpportunity_Trig', 'Both values should be the same.');
        Trigger_Recordtype__c rt = new Trigger_Recordtype__c(Enabled__c=true,Recordtype_Id__c=trig.Id,Trigger__c=trig.Id,Parameters__c='param=1;param=2');
        Insert rt;
        System.assertEquals(rt.Enabled__c, true, 'trigger status should be active.');
        TriggerInterfaceHelper.initTriggerMapAndList('copado__User_Story__c');
        
        TriggerInterfaceHelper.runTrigger('UpdateFieldsOnOpportunity_Trig', 'copado__User_Story__c', 1, 'bu', trig.Id, 'param=1;param=2','All');
    }
}