/**
 * Created By : Hailey Niemand
 * Created On : 10/11/2020
 * Apex Class : TriggerInterfaceHelper
 */
@isTest
private class zTest_TriggerInterfaceHelper {
    static testMethod void UnitTest_TriggerHelper_Trig() 
    {
        // Create Trigger test record 
        Trigger__c trig = new Trigger__c(Trigger_Name_Unique__c='UpdateFieldsOnOpportunity_Trig',Enabled__c=true,Object__c='Opportunity',Run_for_Recordypes__c='All',  Description__c='my test',Execution_Order__c=1,
                                        Before_Update__c=true);
        Insert trig;
        system.assertEquals(trig.Trigger_Name_Unique__c, 'UpdateFieldsOnOpportunity_Trig', 'Both values should be the same.');
        Trigger_Recordtype__c rt = new Trigger_Recordtype__c(Enabled__c=true,Recordtype_Id__c=trig.Id,Trigger__c=trig.Id,Parameters__c='param=1;param=2');
        Insert rt;
        System.assertEquals(rt.Enabled__c, true, 'trigger status should be active.');
        TriggerInterfaceHelper.initTriggerMapAndList('Opportunity');
        TriggerInterfaceHelper.runTrigger('UpdateFieldsOnOpportunity_Trig', 'Opportunity', 1, 'bu', trig.Id, 'param=1;param=2','All');
        
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        Trigger__c trig2 = new Trigger__c(Trigger_Name_Unique__c='ExcludeProfile',Enabled__c=true,Object__c='Opportunity',Run_for_Recordypes__c='',  Description__c='test',Execution_Order__c=2,
                                        Before_Update__c=true,Excluded_Profiles__c=p.Id);
        insert trig2;
        System.assertEquals(trig2.Excluded_Profiles__c, p.Id, 'profile must be System Administrator');
        TriggerInterfaceHelper.initTriggerMapAndList('Opportunity');
        TriggerInterfaceHelper.runTrigger('ExcludeProfilesOnOpportunity_Trig', 'Opportunity', 2, 'bu', trig2.Id, 'param=1;param=2','All');
    }
    
    static testMethod void UnitTest_TriggerHelper_Trig2() 
    {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        Trigger__c trig2 = new Trigger__c(Trigger_Name_Unique__c='ExcludeProfile',Enabled__c=true,Object__c='Opportunity', Description__c='test',Execution_Order__c=2,
                                        Before_Update__c=true,Excluded_Profiles__c=p.Id);
        insert trig2;
        System.assertEquals(trig2.Excluded_Profiles__c, p.Id, 'profile must be System Administrator');
        TriggerInterfaceHelper.initTriggerMapAndList('Opportunity');
        TriggerInterfaceHelper.runTrigger('ExcludeProfilesOnOpportunity_Trig', 'Opportunity', 2, 'bu', trig2.Id, 'param=1;param=2','All');
    }
}