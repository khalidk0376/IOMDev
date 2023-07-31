/**
* Created/Modified By :(Arushi)
* Created On:          27/01/2022
* @description  :      As a Contractor, I Should be able to view approve/decline the list of exhibitors who have
nominated me in the portal so that I can confirm the list of exhibitors for whom I will 
complete the stand design process.
* Methods:             getActiveDatas,setUpdatedValue
* Apex Class:          IMCCStandContractorDataCTRL(96%) 
**/
@IsTest
public class IMCCStandContractorDataCTRL_Test {
    @TestSetUp
    static void testUserData(){
        UserRole userrole = [Select Id, DeveloperName From UserRole Where DeveloperName = 'Administrator' Limit 1];
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' and IsActive = true Limit 1];
        adminUser.UserRoleId = userrole.Id;
        update adminUser;
       
    }
    public static void setupData(){
         Account acc = new Account(Name='Test Acc');
        insert acc;
        Contact con = new Contact(LastName = 'test con',AccountId = acc.Id,Email='test@agshsa.com');
        insert con;
        Edition__c edit = new Edition__c(name ='test edition');
        insert edit;
        Asset ast = new Asset(Name= 'test Asset',AccountId = acc.id, ContactId = con.id,Edition__c = edit.id,
                              Booth_Status__c = 'Rented',Status = 'Purchased');
        insert ast;
    }
    public static testMethod void testData(){
        // Setup Test Data 
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' and IsActive = true and UserRole.Name = 'Administrator' Limit 1];
        User userObj;
        Id contactId;
        Id accId;
        
        System.runAs(adminUser){
            List<Account> accObj  = IMCC_TestUtilities.createAccount(2);
            accId = accObj[0].Id;
            List<Contact> contObj = IMCC_TestUtilities.createContact(accId, 2);
            contactId = contObj[0].Id;
            userObj = IMCC_TestUtilities.createCommunityUser(contactId);
            System.assertEquals(userObj.ContactID,contactId, 'Same contact');
        }
        List<Document> docObj  = IMCC_TestUtilities.createDocument(2);
        Id docObjId = docObj[0].Id;
        List<Brand__c> brandObj  = IMCC_TestUtilities.createBrand(2);
        Id brandObjId = brandObj[0].Id;
        List<Series__c> serviceObj  = IMCC_TestUtilities.createEventSeries(brandObjId, 2);
        Id serviceObjId = serviceObj[0].Id;
        List<Stand_Setting__c> standSettingObj = IMCC_TestUtilities.createStandSetting(250);
        Id standSettingObjId = standSettingObj[0].Id;
        List<Edition__c> editionObj = IMCC_TestUtilities.createEventEditionWithStandSetting(serviceObjId,docObjId,standSettingObjId,250,system.today(),system.today());
        Id editionObjId = editionObj[0].Id;
        
        //System.assertEquals(editionObj[0].Edition_Code__c,'TEV21', 'Event Code');
        
        Contact_Edition_Mapping__c cemObj = IMCC_TestUtilities.createContactEditionMapping(contactId,accId,editionObjId);
        Id cemObjId = cemObj.Id;
        Purchase_Data__c pH = IMCC_TestUtilities.createPurchaseData3(contactId,editionObjId,accId);
        pH.Contact_Edition_Mapping__c = cemObjId;
        update pH;
        Id pHId = pH.Id;
        
        System.runAs(userObj) {
            List<Contractor_Mapping__c> cmObj = IMCC_TestUtilities.createContractorMappingData(accId,contactId,cemObjId,pHId,'Contractor Nominated',editionObjId,null,1);
            Id cmObjId = cmObj[0].id;
            
            Stand_Detail__c listStandDetail = new Stand_Detail__c(Stand_Detail_Status__c = 'In Progress',Stand_Detail_Submitted_On__c = system.today(),Contractor_Mapping__c=cmObjId); 
            Test.startTest();
            IMCCStandContractorDataCTRL.getActiveDatas(accId,editionObj[0].Edition_Code__c);
            IMCCStandContractorDataCTRL.setUpdatedValue('Contractor Accepted Nomination',null,cmObjId);
            Test.stopTest();
        }
    }    
    
    @isTest
    private static void insertAsset(){
        setupData();
        List<Contact_Edition_Mapping__c> contEdiMapingList = [SELECT Id FROM Contact_Edition_Mapping__c];
        //system.assertEquals(1, contEdiMapingList.size());
        List<Purchase_Data__c> purchDataList = [SELECT Id FROM Purchase_Data__c];
        //system.assertEquals(1, purchDataList.size());        
    }
    
    @isTest
    private static void updateAsset(){
        setupData();
        Asset astRec = [SELECT Id,AccountId,ContactId,Edition__c,Booth_Status__c,Status FROM Asset];
        Contact_Edition_Mapping__c contEdiMapingRec = new Contact_Edition_Mapping__c(Account__c = astRec.AccountId,
                                                                                     Contact__c =astRec.ContactId,Edition__c =astRec.Edition__c);
        insert contEdiMapingRec;
        Purchase_Data__c purchDataRec = new Purchase_Data__c(Account__c =  astRec.AccountId,Contact__c =astRec.ContactId,Edition__c =astRec.Edition__c,
                                                             Purchase_Status__c ='Active');
        insert purchDataRec;
        astRec.Booth_Status__c = 'Released';
        astRec.status = 'Obsolete';
        Test.startTest();
        update astRec;        
        Test.stopTest();
    }
}