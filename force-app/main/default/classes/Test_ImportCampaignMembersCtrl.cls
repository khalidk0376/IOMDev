@isTest
public class Test_ImportCampaignMembersCtrl {
 @isTest
    static void testData(){
        
        Campaign cmpg = new Campaign();
        cmpg.Name = 'Test Campaign';
        cmpg.EndDate = System.today().addDays(6);
        
        insert cmpg;
        
        Contact con1 = new Contact();
        con1.FirstName = 'Test Con';
        con1.LastName = 'Lname';
        con1.Email = 'test@gmail.com';
        
        insert con1;
        
        Contact con2 = new Contact();
        con2.FirstName = 'Test Con 1';
        con2.LastName = 'Lname 1';
        con2.Email = 'test1@gmail.com';
        
        insert con2;
        
        Contact con3 = new Contact();
        con3.FirstName = 'Test Con 3';
        con3.LastName = 'Lname 3';
        con3.Email = 'test3@gmail.com';
        
        insert con3;
        
        CampaignMember cmpgMem = new CampaignMember();
        cmpgMem.CampaignId = cmpg.Id;
        cmpgMem.ContactId = con1.Id;
        insert cmpgMem;
        
        Campaign_Upload__c cmpgUpload1 = new Campaign_Upload__c();
        
        cmpgUpload1.Campaign__c = cmpg.id;
        cmpgUpload1.Contact_Email__c = 'test1@gmail.com';
        
        insert cmpgUpload1;
        
        Campaign_Upload__c cmpgUpload2 = new Campaign_Upload__c();
        
        cmpgUpload2.Campaign__c = cmpg.id;
        cmpgUpload2.Contact_Email__c = 'test@gmail.com';
        
        insert cmpgUpload2;
        
        Campaign_Upload__c cmpgUpload3 = new Campaign_Upload__c();
        
        cmpgUpload3.Campaign__c = cmpg.id;
        cmpgUpload3.Contact_Email__c = 'test3@gmail.com';
        
        insert cmpgUpload3;
        
        Campaign_Upload__c cmpgUpload4 = new Campaign_Upload__c();
        
        cmpgUpload4.Campaign__c = cmpg.id;
        cmpgUpload4.Contact_Email__c = 'test4@gmail.com';
        
        insert cmpgUpload4;
        
        test.startTest();
        ImportCampaignMembersCtrl.importMembers(cmpg.id);
        test.stopTest();
     }
}