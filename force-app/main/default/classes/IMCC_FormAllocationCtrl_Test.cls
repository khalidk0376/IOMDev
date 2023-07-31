/**
* Created/Modified By: Girikon(Keertiraj)
* Created On:          08th Nov 2021
* @description : This test class covers the apex class : IMCC_FormAllocationCtrl
* Apex Class:    IMCC_FormAllocationCtrl(85%)      
**/

@isTest
public class IMCC_FormAllocationCtrl_Test {
    
    @TestSetUp
    static void testUserData(){
        UserRole userrole = [Select Id, DeveloperName From UserRole Where DeveloperName = 'Administrator' Limit 1];
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' and IsActive = true Limit 1];
        adminUser.UserRoleId = userrole.Id;
        update adminUser;
    }
    
    public static testMethod void IMCC_FormAllocationCtrlTest(){        
        List<Questionnaire__c> girikonForms = IMCC_TestUtilities.createGirikonForm(250);
        Id girikonFormId = girikonForms[0].Id;
        List<Form_Setting__c> formSettings = IMCC_TestUtilities.createFormSettings(250);
        Id formSettingId = formSettings[0].Id;
        Form_Allocation__c formAlloc = IMCC_TestUtilities.createFormAllocation(girikonFormId,formSettingId);
        Test.startTest();
        try{
        IMCC_FormAllocationCtrl.getFormSubmissions(formAlloc.Id);
        }catch(exception e){}
        Profile p = [Select Id From Profile Where Name='Chatter Free User'];
        User u = new User(Username = 'test@test.com.imcctestclassuserflloc',
                                        FirstName = 'test',
                                        LastName = 'test',
                                        Email = 'test@test.com',
                                        ProfileId = p.Id,
                                        Alias='test',
                                        EmailEncodingKey = 'UTF-8',
                                        LanguageLocaleKey = 'en_US',
                                        LocaleSidKey = 'en_US',
                                        TimeZoneSidKey = 'America/Los_Angeles');
        insert u;
        system.runAs(u){
            try{
            IMCC_FormAllocationCtrl.getFormSubmissions(formAlloc.Id);
            }catch(exception e){}
        }
        Test.stopTest();
        
    }

}