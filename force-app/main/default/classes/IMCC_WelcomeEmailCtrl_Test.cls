/**
* Created/Modified By: Girikon(Keertiraj),[Aishwarya IMCC-3222 1 June 2022]
* Created On:          18 Oct 2021
* @description : This test class covers the apex class : IMCC_WelcomeEmailCtrl
* Apex Class:    IMCC_WelcomeEmailCtrl(100%)      
**/
@isTest
public class IMCC_WelcomeEmailCtrl_Test {
    
    @TestSetUp
    static void testUserData(){
        UserRole userrole = [Select Id, DeveloperName From UserRole Where DeveloperName = 'Administrator' Limit 1];
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' and IsActive = true Limit 1];
        adminUser.UserRoleId = userrole.Id;
        update adminUser;
    }
    
    public static testMethod void IMCC_WelcomeEmailCtrlTest(){
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' and IsActive = true and UserRole.Name = 'Administrator' Limit 1];
        User userObj;
        Id contactId;
        Id contactId1;
        Id accId;
        System.runAs(adminUser){
            List<Account> accObj = IMCC_TestUtilities.createAccount(250);
            accId = accObj[0].Id;
            System.assertEquals('Test Account0', accObj[0].Name, 'Account name does not match');
            List<Contact> contObj = IMCC_TestUtilities.createContact(accId, 250);
            contactId = contObj[0].Id;
            contactId1 = contObj[1].Id;
            System.assertEquals('Test0', contObj[0].LastName, 'Contact name does not match');
            userObj = IMCC_TestUtilities.createCommunityUser(contObj[1].Id);
        }
        List<Document> docObj  = IMCC_TestUtilities.createDocument(250);
        Id docObjId = docObj[0].Id;
        List<Brand__c> brandObj  = IMCC_TestUtilities.createBrand(250);
        Id brandObjId = brandObj[0].Id;
        List<Series__c> serviceObj  = IMCC_TestUtilities.createEventSeries(brandObjId, 250);
        Id serviceObjId = serviceObj[0].Id;
        List<Edition__c> editionObj = IMCC_TestUtilities.createEventEdition(serviceObjId,docObjId,250);
        Id editionObjId = editionObj[0].Id;
        Contact_Edition_Mapping__c cemObj = IMCC_TestUtilities.createContactEditionMapping(contactId,accId,editionObjId);
        
        System.runAs(adminUser){
            IMCC_WelcomeEmailCtrl im=new IMCC_WelcomeEmailCtrl();
            im.sContactId = contactId;
            //im.getEmailHeader();
            List<Email_Templates__c> listEmailTemp = IMCC_TestUtilities.createEmailTemplateWelcome();
            IMCC_TestUtilities.createEditionEmailTemplate(editionObjId,listEmailTemp.get(0).Id, new List<String>{'WELNew'});   
            im.welcomeEmailContentData(contactId,null); 
        }    
    }     


}