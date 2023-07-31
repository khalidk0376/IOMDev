/**
* Created/Modified By: Girikon(Keertiraj)
* Created On:          24th Oct 2021
* @description : This test class covers the apex class : IMCC_EditionWelcomeEmail
* Apex Class:    IMCC_EditionWelcomeEmail(94%) and IMCC_UtilityMethod_Handler(93%) 
**/

@isTest
private class IMCC_EditionWelcomeEmailTest {
    
    @testSetUp
    static void testUserData(){
        UserRole userrole = [Select Id, DeveloperName From UserRole Where DeveloperName = 'Administrator' Limit 1];
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' and IsActive = true Limit 1];
        adminUser.UserRoleId = userrole.Id;
        update adminUser;

        List<Account> accts = new List<Account>();
        List<String> accountNames = (new List<String>{'Airtel Payments Bank Ltd','Arabi Company','ASEAN Super 8 Virtual Connect','chandras','Edge Communications','Facebook','Girikon Inc.','Global Partners','Google','IBM Corporation','IM Acc1','IM Acc2','IM Acc3','Infosys Public Services Inc','IPL','Maruti Suzuki India Ltd','Microsoft','Naveen& Sons','Pfizer Middle East','pixla12','pixla2','Polystat','Raidu Cement Private Limited','RenewX','salesforce.com','Test Acc CC 2','Test Account 2','Trebing & Himstedt Prozessautomation GmbH & Co.KG','Wipro Technologies Inc','Yahoo Farm'});
        for(String s: accountNames){
            Account a = new Account(Name=s);
            accts.add(a);
        }
        insert accts;

        List<String> firstNames = (new List<String>{'Jack','liam'});
        List<String> lastNames = (new List<String>{'Warner','walter'});           
        Integer emailCounter = 0;
        List<Contact> conList = new List<Contact>();
        for(Account a : accts){
            for(integer i=0;i<2;i++){
                conList.add(new Contact(firstname=firstNames[i]+emailCounter,lastname=lastNames[i]+emailCounter,
                                    AccountId=a.Id,Email='FirstName'+emailCounter+'@test.com')); 
                emailCounter++;
            }
        }
        insert conList;

        List<Brand__c> brand  = IMCC_TestUtilities.createBrand(1);
        List<Series__c> series  = IMCC_TestUtilities.createEventSeries(brand[0].Id, 1);
        List<Document> doc  = IMCC_TestUtilities.createDocument(1);
        List<Edition__c> edition = IMCC_TestUtilities.createEventEdition(series[0].Id,doc[0].Id,1);
        List<Contact_Edition_Mapping__c> listCEM = new List<Contact_Edition_Mapping__c>();
        for(Contact con : conList){
            listCEM.add(new Contact_Edition_Mapping__c(Contact__c=con.Id,Edition__c=edition[0].Id,Relationship_Status__c='Active',Account__c=con.AccountId,Access_Type__c ='Exhibitor'));
        }
        insert listCEM;
    }
    
    @isTest
    static void editionWelcomeEmailTest(){
        Test.startTest();
        Contact_Edition_Mapping__c cemObj2 = [SELECT Id,Access_Type__c FROM Contact_Edition_Mapping__c LIMIT 1];
        cemObj2.Access_Type__c ='Reseller';
        update cemObj2;
        
        Edition__c edition = [SELECT Id FROM Edition__c LIMIT 1];
        List<Email_Templates__c> listEmailTemp = IMCC_TestUtilities.createEmailTemplateWelcome(); 
        IMCC_TestUtilities.createEditionEmailTemplate(edition.Id,listEmailTemp.get(0).Id, new List<String>{'WELNew'});
        IMCC_EditionWelcomeEmail.getContactEditionMappings(edition.Id,'Test','ContactName','asc','All','All');
        IMCC_EditionWelcomeEmail.getContactEditionMappings(edition.Id,'Test','AccountName','desc','All','All');
        IMCC_EditionWelcomeEmail.getContactEditionMappings(edition.Id,'Test','ContactEmail','desc','All','All');
        IMCC_EditionWelcomeEmail.getContactEditionMappings(edition.Id,'Test','IsEmailSent','desc','All','All');
        IMCC_EditionWelcomeEmail.getContactEditionMappings(edition.Id,'Test','EmailSentDate','desc','All','All');
        IMCC_EditionWelcomeEmail.getContactEditionMappings(edition.Id,'Test','FirstLoginDateTime','desc','All','All');
        List<Contact_Edition_Mapping__c> listCEM = IMCC_EditionWelcomeEmail.getContactEditionMappings(edition.Id,'','UserType','desc','Who logged in','Received Email');
        System.assert(listCEM.size()>0, 'No CEM Found');
        List<Contact_Edition_Mapping__c> listCEM2 = [SELECT Id,Access_Type__c FROM Contact_Edition_Mapping__c LIMIT 20];
        IMCC_EditionWelcomeEmail.sendWelcomeEmail(listCEM2);
        List<Contact_Edition_Mapping__c> listCEM3 = [SELECT Id,Access_Type__c FROM Contact_Edition_Mapping__c LIMIT 40];
        IMCC_EditionWelcomeEmail.sendWelcomeEmail(listCEM3);
        IMCC_EditionWelcomeEmail.checkSendWelcomeEmailStatus(edition.Id);
        Test.stopTest();
    }
}