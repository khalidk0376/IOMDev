@isTest
public class ESSOConnectedAppHandler_Test {
    static string name = 'TestHandler';
    static User u = new User();
    static Account a = new Account();
    static Contact c = new Contact();
    static Edition__c e = new Edition__c();
    
    
    @TestSetUp
    static void testUserData(){
        UserRole userrole = [Select Id, DeveloperName From UserRole Where DeveloperName = 'Administrator' Limit 1];
        Profile p = [SELECT Id FROM Profile WHERE Name= 'IM System Administrator'];
        
        User user = new User(Alias = 'standt', Email='davidjones@test.com', 
        EmailEncodingKey='UTF-8', LastName='Kumar', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id,IsActive = true,
        TimeZoneSidKey='America/Los_Angeles', UserName='IMAdmin1@testorg.com');
        insert user;
        
        user.UserRoleId = userrole.Id;
        update user;
    }
    static testMethod void UnitTest() 
    {
        Profile p = [SELECT Id FROM Profile Where Name='IM Customer Community Login User' LIMIT 1];
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='IM System Administrator' and IsActive = true and UserRole.Name = 'Administrator' Limit 1];
        System.runAs(adminUser) {
            a = new Account(Name=name);
            insert a;
            
            c= new Contact(AccountId=a.Id,LastName=name,FirstName=name,email='test@test.com');
            insert c;
            
            u = new User(ContactId = c.Id,FirstName=name,LastName=name,Username= name +'@TestHandler.com',email=name +'@TestHandler.com',ProfileId=p.Id,Alias=name.left(8),LocaleSidKey='en_US',LanguageLocaleKey='en_US',TimeZoneSidKey='America/Los_Angeles',EmailEncodingKey='UTF-8');
            insert u;
            
            e =new Edition__c(Name = 'Test Event 2021', Edition_Code__c ='TEV21', End_Date__c = System.Today(), 
                                         Start_Date__c = System.Today(), Edition_Status__c = 'Confirmed', Edition_Website__c = 'http://www.testevent.com', 
                                         Customer_Center_Status__c='Active'); 
            insert e;
            System.debug('####!DEBUG! Edition__c: '+ e);
        }
        Contact_Edition_Mapping__c cem = new Contact_Edition_Mapping__c();
        cem.Contact__c = c.Id;
        cem.Edition__c = e.Id;
        cem.Relationship_Status__c = 'Active';
        cem.Account__c = a.Id;
        cem.Access_Type__c ='Exhibitor';
        insert cem;
        Test.StartTest();
            update cem; 
            
            System.debug('####!DEBUG! Opportunity: '+ ([SELECT Id FROM Contact_Edition_Mapping__c WHERE Account__c =: a.Id]));
          
            ESSOConnectedAppHandler cacc = new ESSOConnectedAppHandler();
            Map<String,String> formulaDefinedAttributes = new Map<String,String>();
            System.debug('####!DEBUG! u.Id: '+ u.Id);
            Map<String,String> j = cacc.customAttributes(u.Id,null,formulaDefinedAttributes,null);
            System.debug('####!DEBUG! j: '+ j.get('exhibitor'));
            System.assertEquals(cem.Id, ([SELECT Id FROM Contact_Edition_Mapping__c WHERE Account__c =: a.Id]).Id, 'Opp ids match');
            System.assertEquals(true, String.isNotBlank(j.get('exhibitor')), 'Is Json');
        Test.StopTest();
    }
}