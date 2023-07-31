@isTest
public class Test_EmailAllCampaignMembersCtrl {    
     @TestSetUp
     static void testData(){
         
        EmailTemplate temp = new EmailTemplate();
         temp.Description = 'Campaign-Test';
         temp.Body = 'Test Body';
         temp.Subject = 'Test Subject';
         temp.IsActive = true ;
         temp.DeveloperName = 'Test_Campaign_Temp';
         temp.Name = 'Test Campaign Temp';
         temp.TemplateType = 'custom';
         temp.FolderId = UserInfo.getUserId();
         insert temp;
         
     }
    @isTest
    static void testMethodCampaignInsert(){
        
        List<EmailTemplate> emailTemp = [Select Id,Name from EmailTemplate where Name = 'Test Campaign Temp'];
        List<Campaign> cmpgLst = new List<Campaign>();
         for(integer i=0;i<3;i++){
             Campaign cmpg = new Campaign();
             cmpg.Name = 'Test Campaign'+i;
             cmpg.EndDate = System.today().addDays(6);
             cmpg.Email_Template_Id__c = emailTemp[0].Id;
             cmpg.Email_Start_Date__c = System.today().addDays(1);
             cmpg.Frequency__c = decimal.valueOf('2');
             cmpgLst.add(cmpg);
         }
         insert cmpgLst;
         
         Account acc = new Account();
         acc.Name = 'Test Account';
         insert acc;
         
         Contact con = new Contact();
         con.FirstName = 'Test Contact';
         con.LastName = 'Test';
         con.Email = 'test@gmail.com';
         con.AccountId = acc.Id;
         insert con;
         
         CampaignMember cmpgMem = new CampaignMember();
         cmpgMem.CampaignId = cmpgLst[0].Id;
         cmpgMem.ContactId = con.Id;
         insert cmpgMem;
         
         
         test.startTest();
         EmailAllCampaignMembersCtrl.FlowInputs cmpgIds = new EmailAllCampaignMembersCtrl.FlowInputs();
         List<Campaign> lstCmpg = [Select Id,Name from Campaign where id in: cmpgLst];
         List<String> cmpgId = new List<String>();
         for(Campaign cmpg : lstCmpg){
             cmpgId.add(cmpg.Id);
         }
         cmpgIds.campaignIds = cmpgId;
         EmailAllCampaignMembersCtrl.massEmailCampaignMembers(
            new List<EmailAllCampaignMembersCtrl.FlowInputs>{cmpgIds}
        );
         test.stopTest();
    }

}