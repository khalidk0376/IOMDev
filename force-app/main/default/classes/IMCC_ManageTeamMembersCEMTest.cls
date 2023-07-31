/**
* Created/Modified By :(Arushi)
* Created On:          3/03/2023 
* Last Modified By:    [Aishwarya IMCC-5102 3 Apr 2023, Arushi IMCC-5147 20 Apr 2023]
* @description  :      As a Customer, I should be able to invite my colleague(s) for an event set up in 
                       Customer Center portal so that they get full access to event related information
                       in the customer center portal.
* Methods:             getContact,matchedContact,contactToBeCreated,teamMemberList,cancelInvitation,reSendInvitation
* Apex Class:          IMCC_ManageTeamMembersCEM
**/
@IsTest
public class IMCC_ManageTeamMembersCEMTest {
    @TestSetUp
    static void testUserData(){
        UserRole userrole = [Select Id, DeveloperName From UserRole Where DeveloperName = 'Administrator' Limit 1];
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' and IsActive = true Limit 1];
        adminUser.UserRoleId = userrole.Id;
        update adminUser;
    }

    public static testMethod void testMethod1(){
        // Setup Test Data 
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' and IsActive = true and UserRole.Name = 'Administrator' Limit 1];
        Contact con = new Contact();
        User userObj;
        Id contactId;
        Id accId;
        
        System.runAs(adminUser){
            List<Account> accObj  = IMCC_TestUtilities.createAccount(1);
            accId = accObj[0].Id;
            List<Contact> contObj = IMCC_TestUtilities.createContact(accId, 1);
            contactId = contObj[0].Id;
            con = contObj[0];
            userObj = IMCC_TestUtilities.createCommunityUser(contactId);
            System.assertEquals(userObj.ContactID,contactId, 'Same contact');
        }
        List<Document> docObj  = IMCC_TestUtilities.createDocument(1);
        Id docObjId = docObj[0].Id;
        List<Brand__c> brandObj  = IMCC_TestUtilities.createBrand(1);
        Id brandObjId = brandObj[0].Id;
        List<Series__c> serviceObj  = IMCC_TestUtilities.createEventSeries(brandObjId, 1);
        Id serviceObjId = serviceObj[0].Id;
        List<Event_Setting__c> eveSettingObj = IMCC_TestUtilities.createEventSetting(1);
        Id eveSettingObjId = eveSettingObj[0].Id;
        List<Edition__c> editionObj = IMCC_TestUtilities.createEventEditionWithEveSetting2(serviceObjId,docObjId,eveSettingObjId,1);
        Id editionObjId = editionObj[0].Id;
        
        Contact_Edition_Mapping__c cemObj = IMCC_TestUtilities.createContactEditionMapping(contactId,accId,editionObjId);
        List<Edition_Websites__c> edwebObj = IMCC_TestUtilities.createEditionWebsites(editionObjId, 250);
       
        Purchase_Data__c booth = IMCC_TestUtilities.createPurchaseData3(contactId,editionObjId,accId);
        booth.Contact_Edition_Mapping__c = cemObj.Id;
        Update booth;

        Test.startTest();        
        System.runAs(userObj) {
               IMCC_ManageTeamMembersCEM.getContact('abc@test.com');
               IMCC_ManageTeamMembersCEM.matchedContact(contactId,editionObj[0].Edition_Code__c,accId,'Secondary Admin');
               IMCC_ManageTeamMembersCEM.contactToBeCreated(editionObj[0].Edition_Code__c,accId,'abc2@test.com','Team Member','firstName','lastName');
               IMCC_ManageTeamMembersCEM.teamMemberList(editionObj[0].Edition_Code__c,accId);
               //IMCC_ManageTeamMembersCEM.cancelInvitation(cemObj.Id);
               IMCC_ManageTeamMembersCEM.reSendInvitation(cemObj.Id,editionObj[0].Edition_Code__c,accId);
               IMCC_ManageTeamMembersCEM.checkCurrentUser(editionObj[0].Edition_Code__c,accId);
        }
        Test.stopTest();
    }
    
    public static testMethod void testMethod2(){
        // Setup Test Data 
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' and IsActive = true and UserRole.Name = 'Administrator' Limit 1];
        Contact con = new Contact();
        User userObj;
        Id contactId;
        Id accId;
        
        System.runAs(adminUser){
            List<Account> accObj  = IMCC_TestUtilities.createAccount(1);
            accId = accObj[0].Id;
            List<Contact> contObj = IMCC_TestUtilities.createContact(accId, 1);
            contactId = contObj[0].Id;
            con = contObj[0];
            userObj = IMCC_TestUtilities.createCommunityUser(contactId);
            System.assertEquals(userObj.ContactID,contactId, 'Same contact');
        }
        List<Document> docObj  = IMCC_TestUtilities.createDocument(1);
        Id docObjId = docObj[0].Id;
        List<Brand__c> brandObj  = IMCC_TestUtilities.createBrand(1);
        Id brandObjId = brandObj[0].Id;
        List<Series__c> serviceObj  = IMCC_TestUtilities.createEventSeries(brandObjId, 1);
        Id serviceObjId = serviceObj[0].Id;
        List<Event_Setting__c> eveSettingObj = IMCC_TestUtilities.createEventSetting(1);
        Id eveSettingObjId = eveSettingObj[0].Id;
        List<Edition__c> editionObj = IMCC_TestUtilities.createEventEditionWithEveSetting2(serviceObjId,docObjId,eveSettingObjId,1);
        Id editionObjId = editionObj[0].Id;
        
        //System.assertEquals(editionObj[0].Edition_Code__c,'TEV21', 'Event Code');
        
        Contact_Edition_Mapping__c cemObj = IMCC_TestUtilities.createContactEditionMapping(contactId,accId,editionObjId);
        List<Edition_Websites__c> edwebObj = IMCC_TestUtilities.createEditionWebsites(editionObjId, 250);
       
        Purchase_Data__c booth = IMCC_TestUtilities.createPurchaseData3(contactId,editionObjId,accId);
        booth.Contact_Edition_Mapping__c = cemObj.Id;
        Update booth;

        Test.startTest();  
            Contact con1 = new Contact(FirstName='test first',LastName='Test',Email='testmukesh@girikon.com');
            insert con1;      
        System.runAs(userObj) {
            IMCC_ManageTeamMembersCEM.getContact('abc@test.com');
            IMCC_ManageTeamMembersCEM.matchedContact(con1.Id,editionObj[0].Edition_Code__c,accId,'Team Member');
            IMCC_ManageTeamMembersCEM.contactToBeCreated(editionObj[0].Edition_Code__c,accId,'abc2@test.com','Team Member','firstName','lastName');
            IMCC_ManageTeamMembersCEM.teamMemberList(editionObj[0].Edition_Code__c,accId);
            IMCC_ManageTeamMembersCEM.cancelInvitation(cemObj.Id,editionObj[0].Edition_Code__c,accId);
            //IMCC_ManageTeamMembersCEM.reSendInvitation(cemObj.Id);
        }
        Test.stopTest();
    }
    
    //IMCC-5102
    public static testMethod void testMethod3()
    {
        UserRole userrole = [Select Id, DeveloperName From UserRole Where DeveloperName = 'Administrator' Limit 1];
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' and IsActive = true Limit 1];
        adminUser.UserRoleId = userrole.Id;
        update adminUser;
        // Setup Test Data 
        User userObj;
        Id contactId;
        Id accId;
        String acntId ='';
        System.runAs(adminUser){
            List<Account> accObj  = IMCC_TestUtilities.createAccount(250);
            accId = accObj[2].Id;
            acntId = accObj[2].Id;
            system.debug('###############ACC'+accObj);
            List<Contact> contObj = IMCC_TestUtilities.createContact(accId, 250);
            contactId = contObj[0].Id;
            userObj = IMCC_TestUtilities.createCommunityUser2(contactId);
            System.assertEquals(userObj.ContactID,contactId, 'Same contact');
            
            List<Document> docObj  = IMCC_TestUtilities.createDocument(250);
            Id docObjId = docObj[0].Id;
            
            List<Brand__c> brandObj  = IMCC_TestUtilities.createBrand(250);
            Id brandObjId = brandObj[0].Id;
            
            List<Series__c> serviceObj  = IMCC_TestUtilities.createEventSeries(brandObjId, 250);
            Id serviceObjId = serviceObj[0].Id;
            
            List<Event_Setting__c> eveSettingObj = IMCC_TestUtilities.createEventSetting(250);
            Id eveSettingObjId = eveSettingObj[0].Id;
            
            List<Edition__c> editionObj = IMCC_TestUtilities.createEventEditionWithEveSetting(serviceObjId,docObjId,eveSettingObjId,250);
            Id editionObjId = editionObj[0].Id;
            
            List<Edition_Popup__c> listEditionPopup = IMCC_TestUtilities.createEditionPopupData(editionObj[0].Id,200);
            
            List<Event_Tabs__c> evntTabsLst = IMCC_TestUtilities.createEventTabListData(eveSettingObj[0].Id,200);
            
            System.assertEquals(evntTabsLst.Size(),200, 'evntTabsLst size should be 200');
            
            List<Tab_User_Type__c> evntTabUserTypeList = IMCC_TestUtilities.createEventntTabUserTypeData(evntTabsLst[0].Id,listEditionPopup[0].Id,200);
            
            Contact_Edition_Mapping__c cemObj = IMCC_TestUtilities.createContactEditionMapping(contactId,accId,editionObjId);
            Contact_Edition_Mapping__c cemObj2 = IMCC_TestUtilities.createContactEditionMapping(contactId,accId,editionObjId);
            
            cemObj.Edition__c = listEditionPopup[0].Edition__c;
            cemObj.Access_Type__c = evntTabUserTypeList[0].User_Type__c;
            cemObj.isSecondary__c = false;
            update cemObj;
            
            Test.startTest();
            Purchase_Data__c purData=new Purchase_Data__c(Contact__c=contactId,Edition__c = listEditionPopup[1].Edition__c,Account__c =accId,
            Booth_Product_Type__c = 'Space Only', Booth_Number__c = 'H2.11', Purchase_Status__c = 'Active', Transaction_Status__c ='Active',Contact_Edition_Mapping__c =cemObj.Id);
            insert purData;
            
            List<Questionnaire__c> girikonFormLst = IMCC_TestUtilities.createGirikonForm(5);
            System.assertEquals(girikonFormLst.Size(),5, 'Girikon Form List size should be 5');
        
            List<Form_Setting__c> formSettLst = IMCC_TestUtilities.createFormSettings(5);
            System.assertEquals(formSettLst.Size(),5, 'Form Setting List size should be 5');
            
            Form_Allocation__c formAllocLst1 = IMCC_TestUtilities.createFormAllocationWithEmail(girikonFormLst[0].id,formSettLst[0].id);
            
            List<Tab_User_Type__c> tabUserFormAllocLst = IMCC_TestUtilities.createTabUserTypeFormAlloc(formAllocLst1.id,5,'Exhibitor');
            System.assertEquals(tabUserFormAllocLst.Size(),5, 'Tab User List size should be 5');
            
            List<Forms_Permission__c> formsPermLst = IMCC_TestUtilities.createFormsPermission(tabUserFormAllocLst[0].id,formAllocLst1.id,5);
            System.assertEquals(formsPermLst.Size(),5, 'Form Permission List size should be 5');
        
            List<Form_Data__c> fdList = IMCC_TestUtilities.createFormData(cemObj.id,formsPermLst[0].Id,1);
                 
            Form_Response_Entry__c fsEntry = new Form_Response_Entry__c();
            fsEntry.Entry_Number__c = 1;
            fsEntry.Form_Data__c = fdList[0].id;
            fsEntry.Contact_Edition_Mapping__c =cemObj.Id;
            fsEntry.Ops_Contact_Name__c =contObj[5].Id;
            fsEntry.User__c=userObj.Id;
            insert fsEntry;
            
            List<Contractor_Mapping__c> cmObj = IMCC_TestUtilities.createContractorMappingData(accId,contactId,cemObj.Id,purData.Id,'Contractor Nominated',listEditionPopup[1].Edition__c,'',1);
            FAQ_Contact_Mapping__c faqs = new FAQ_Contact_Mapping__c(Contact_Edition_Mapping__c=cemObj.Id,Upvote_Downvote__c='Upvote');
            insert faqs;
            
            IMCC_ManageTeamMembersCEM.checkPrimaryCEM(String.ValueOf(cemObj.Id));
            IMCC_ManageTeamMembersCEM.cancelInvitationIfPrimary(String.valueOf(cemObj.Id),editionObj[0].Edition_Code__c,acntId);    
            
            Test.stopTest();
        }  
    }   
}