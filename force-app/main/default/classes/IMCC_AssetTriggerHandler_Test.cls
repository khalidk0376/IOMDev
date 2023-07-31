/**
* File         :   IMCC_AssetTriggerHandler_Test 
* Project      :   IMCC
* Created Date :   16th feb 2022
* Created By   :   Girikon(Deepak)
***********************************************************************************************
* @description : Class will test Class For IMCC_CreateApiSyncRecords(96%),IMCC_APISynchronizationBatch(95%),IMCC_APISynchronizationHelper(100%),IMCC_APISynchronizationTransactionHelper(95%),IMCC_AssetTriggerHandler(97%),IMCC_AssetTrigger(100%),IMCC_AssetTriggerHandler_Test(100%),IMCC_UtilityMethods(58%)
***********************************************************************************************
* Modification log :
*/
@isTest
private class IMCC_AssetTriggerHandler_Test {

    @testSetup 
    static void setupdData(){
        Account acc = new Account(Name='Test Acc');
        insert acc;
        Contact con = new Contact(LastName = 'test con',AccountId = acc.Id,Email='test@test.com');
        insert con;
        Contact con2 = new Contact(LastName = 'test con2',AccountId = acc.Id,Email='test2@test.com');
        insert con2;
        Contact con3 = new Contact(LastName = 'test con3',AccountId = acc.Id,Email='test3@test.com');
        insert con3;
        
        List<Brand__c> brandObj  = IMCC_TestUtilities.createBrand(1);
        Id brandObjId = brandObj[0].Id;
        List<Series__c> seriesObj  = IMCC_TestUtilities.createEventSeries(brandObjId, 1);
        Id seriesObjId = seriesObj[0].Id;
        List<Document> docObj  = IMCC_TestUtilities.createDocument(1);
        Id docObjId = docObj[0].Id;
        List<Edition__c> editionObj = IMCC_TestUtilities.createEventEdition(seriesObjId,docObjId,1);
        Id editionObjId = editionObj[0].Id;
        
        Triggers_Configuration__mdt triggerConfiguration = new Triggers_Configuration__mdt(Before_Insert__c=true,Before_Update__c=true,After_Insert__c=true,After_Update__c=true);
        IMCC_UtilityMethods.mapTriggerConfiguration.put('IMCC_AssetTrigger_Async', triggerConfiguration);
        
        List<Asset> listAsset = new List<Asset>();
        Asset ast = new Asset(Name= 'test Asset11',AccountId = acc.id, ContactId = con.id,Edition__c = editionObjId,Booth_Status__c = 'Rented',Booth_Number__c='11',Status = 'Purchased',Source_Org__c='EMEA',User_Type1__c='Exhibitor',Booth_Product_Type1__c='Space Only',Source_Id__c='testid');
        listAsset.add(ast);
        ast = new Asset(Name= 'test Asset12',AccountId = acc.id, ContactId = con.id,Edition__c = editionObjId,Booth_Status__c = 'Rented',Booth_Number__c='12',Status = 'Purchased',Source_Org__c='EMEA',User_Type1__c='Exhibitor',Booth_Product_Type1__c='Space Only',Source_Id__c='testid');
        listAsset.add(ast);
        ast = new Asset(Name= 'test Asset13',AccountId = acc.id, ContactId = con2.id,Edition__c = editionObjId,Booth_Status__c = 'Rented',Booth_Number__c='13',Status = 'Purchased',Source_Org__c='EMEA',User_Type1__c='Exhibitor',Booth_Product_Type1__c='Space Only',Source_Id__c='testid');
        listAsset.add(ast);
        insert listAsset;
    }

    @isTest
    private static void insertAssetAsync(){
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Edition__c edit = [SELECT Id FROM Edition__c LIMIT 1];
        Test.startTest();
        
        Triggers_Configuration__mdt triggerConfiguration = new Triggers_Configuration__mdt(Before_Insert__c=true,Before_Update__c=true,After_Insert__c=true,After_Update__c=true);
        IMCC_UtilityMethods.mapTriggerConfiguration.put('IMCC_AssetTrigger_Async', triggerConfiguration);
        
        List<Asset> listAsset = new List<Asset>();
        Asset ast = new Asset(Name= 'test Asset1',AccountId = acc.id, ContactId = con.id,Edition__c = edit.id,Booth_Status__c = 'Rented',Booth_Number__c='1',Status = 'Purchased',Source_Org__c='EMEA',User_Type1__c='Exhibitor',Booth_Product_Type1__c='Space Only',Source_Id__c='testid');
        listAsset.add(ast);
        ast = new Asset(Name= 'test Asset2',AccountId = acc.id, ContactId = con.id,Edition__c = edit.id,Booth_Status__c = 'Rented',Booth_Number__c='2',Status = 'Purchased',Source_Org__c='EMEA',User_Type1__c='Exhibitor',Booth_Product_Type1__c='Space Only',Source_Id__c='testid');
        listAsset.add(ast);
        ast = new Asset(Name= 'test Asset3',AccountId = acc.id, ContactId = con.id,Edition__c = edit.id,Booth_Status__c = 'Rented',Booth_Number__c='3',Status = 'Purchased',Source_Org__c='EMEA',User_Type1__c='Exhibitor',Booth_Product_Type1__c='Space Only',Source_Id__c='testid');
        listAsset.add(ast);
        insert listAsset;
        
        Test.stopTest();
        
        List<Contact_Edition_Mapping__c> contEdiMapingList = [SELECT Id FROM Contact_Edition_Mapping__c];
        System.assertEquals(2, contEdiMapingList.size(),'All CEM Created');
        List<Purchase_Data__c> purchDataList = [SELECT Id FROM Purchase_Data__c];
        System.assertEquals(6, purchDataList.size(),'All PD Created'); 
    }

    @isTest
    private static void insertAsset(){
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Edition__c edit = [SELECT Id FROM Edition__c LIMIT 1];
        Test.startTest();
        
        Triggers_Configuration__mdt triggerConfiguration = new Triggers_Configuration__mdt(Before_Insert__c=true,Before_Update__c=true,After_Insert__c=true,After_Update__c=true);
        IMCC_UtilityMethods.mapTriggerConfiguration.put('IMCC_AssetTrigger', triggerConfiguration);
        
        List<Asset> listAsset = new List<Asset>();
        Asset ast = new Asset(Name= 'test Asset1',AccountId = acc.id, ContactId = con.id,Edition__c = edit.id,Booth_Status__c = 'Rented',Booth_Number__c='1',Status = 'Purchased',Source_Org__c='EMEA',User_Type1__c='Exhibitor',Booth_Product_Type1__c='Space Only',Source_Id__c='testid');
        listAsset.add(ast);
        ast = new Asset(Name= 'test Asset2',AccountId = acc.id, ContactId = con.id,Edition__c = edit.id,Booth_Status__c = 'Rented',Booth_Number__c='2',Status = 'Purchased',Source_Org__c='EMEA',User_Type1__c='Exhibitor',Booth_Product_Type1__c='Space Only',Source_Id__c='testid');
        listAsset.add(ast);
        ast = new Asset(Name= 'test Asset3',AccountId = acc.id, ContactId = con.id,Edition__c = edit.id,Booth_Status__c = 'Rented',Booth_Number__c='3',Status = 'Purchased',Source_Org__c='EMEA',User_Type1__c='Exhibitor',Booth_Product_Type1__c='Space Only',Source_Id__c='testid');
        listAsset.add(ast);
        insert listAsset;
        
        Test.stopTest();
        
        List<Contact_Edition_Mapping__c> contEdiMapingList = [SELECT Id FROM Contact_Edition_Mapping__c];
        System.assertEquals(2, contEdiMapingList.size(),'All CEM Created');
        List<Purchase_Data__c> purchDataList = [SELECT Id FROM Purchase_Data__c];
        System.assertEquals(6, purchDataList.size(),'All PD Created'); 
    }
    
    @isTest
    private static void insertAsset3Async(){
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<Contact> con = [SELECT Id FROM Contact LIMIT 3];
        Edition__c edit = [SELECT Id FROM Edition__c LIMIT 1];
        Test.startTest();
        
        Triggers_Configuration__mdt triggerConfiguration = new Triggers_Configuration__mdt(Before_Insert__c=true,Before_Update__c=true,After_Insert__c=true,After_Update__c=true);
        IMCC_UtilityMethods.mapTriggerConfiguration.put('IMCC_AssetTrigger_Async', triggerConfiguration);
        
        List<Asset> listAsset = new List<Asset>();
        Asset ast = new Asset(Name= 'test Asset1',AccountId = acc.id, ContactId = con[2].id,Edition__c = edit.id,Booth_Status__c = 'Rented',Booth_Number__c='1',Status = 'Purchased',Source_Org__c='EMEA',User_Type1__c='Exhibitor',Booth_Product_Type1__c='Space Only',Source_Id__c='testid');
        listAsset.add(ast);
        insert listAsset;
        
        Test.stopTest();
        
        List<Contact_Edition_Mapping__c> contEdiMapingList = [SELECT Id FROM Contact_Edition_Mapping__c];
        System.assertEquals(3, contEdiMapingList.size(),'All CEM Created');
        List<Purchase_Data__c> purchDataList = [SELECT Id FROM Purchase_Data__c];
        System.assertEquals(4, purchDataList.size(),'All PD Created'); 
    }

    @isTest
    private static void insertAsset3(){
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<Contact> con = [SELECT Id FROM Contact LIMIT 3];
        Edition__c edit = [SELECT Id FROM Edition__c LIMIT 1];
        Test.startTest();
        
        Triggers_Configuration__mdt triggerConfiguration = new Triggers_Configuration__mdt(Before_Insert__c=true,Before_Update__c=true,After_Insert__c=true,After_Update__c=true);
        IMCC_UtilityMethods.mapTriggerConfiguration.put('IMCC_AssetTrigger', triggerConfiguration);
        
        List<Asset> listAsset = new List<Asset>();
        Asset ast = new Asset(Name= 'test Asset1',AccountId = acc.id, ContactId = con[2].id,Edition__c = edit.id,Booth_Status__c = 'Rented',Booth_Number__c='1',Status = 'Purchased',Source_Org__c='EMEA',User_Type1__c='Exhibitor',Booth_Product_Type1__c='Space Only',Source_Id__c='testid');
        listAsset.add(ast);
        insert listAsset;
        
        Test.stopTest();
        
        List<Contact_Edition_Mapping__c> contEdiMapingList = [SELECT Id FROM Contact_Edition_Mapping__c];
        System.assertEquals(3, contEdiMapingList.size(),'All CEM Created');
        List<Purchase_Data__c> purchDataList = [SELECT Id FROM Purchase_Data__c];
        System.assertEquals(4, purchDataList.size(),'All PD Created'); 
    }
    
    @isTest
    private static void insertAssetWithParentAsync(){
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Edition__c edit = [SELECT Id FROM Edition__c LIMIT 1];
        Test.startTest();
        Triggers_Configuration__mdt triggerConfiguration = new Triggers_Configuration__mdt(Before_Insert__c=true,Before_Update__c=false,After_Insert__c=false,After_Update__c=false);
        IMCC_UtilityMethods.mapTriggerConfiguration.put('IMCC_AssetTrigger_Async', triggerConfiguration);
        
        List<Asset> listAsset2 = [SELECT Id,Name,Purchase_Data__c FROM Asset Where ContactId=:con.id];
        listAsset2[1].ParentId = listAsset2[0].Id;
        update listAsset2[1];
        
        triggerConfiguration = new Triggers_Configuration__mdt(Before_Insert__c=true,Before_Update__c=true,After_Insert__c=true,After_Update__c=true);
        IMCC_UtilityMethods.mapTriggerConfiguration.put('IMCC_AssetTrigger_Async', triggerConfiguration);
        
        List<Asset> listAsset = new List<Asset>();
        Asset ast = new Asset(Name= 'test Asset1',AccountId = acc.id,ParentId=listAsset2[0].Id, ContactId = con.id,Edition__c = edit.id,Booth_Status__c = 'Rented',Booth_Number__c='1',Status = 'Purchased',Source_Org__c='EMEA',User_Type1__c='Exhibitor',Booth_Product_Type1__c='Space Only',Source_Id__c='testid');
        listAsset.add(ast);
        ast = new Asset(Name= 'test Asset2',AccountId = acc.id,ParentId=listAsset2[1].Id, ContactId = con.id,Edition__c = edit.id,Booth_Status__c = 'Rented',Booth_Number__c='2',Status = 'Purchased',Source_Org__c='EMEA',User_Type1__c='Exhibitor',Booth_Product_Type1__c='Space Only',Source_Id__c='testid');
        listAsset.add(ast);
        insert listAsset;
        
        Test.stopTest();
        
        List<Contact_Edition_Mapping__c> contEdiMapingList = [SELECT Id FROM Contact_Edition_Mapping__c];
        System.assertEquals(2, contEdiMapingList.size(),'All CEM Created');
        List<Purchase_Data__c> purchDataList = [SELECT Id FROM Purchase_Data__c];
        System.assertEquals(5, purchDataList.size(),'All PD Created'); 
        System.debug(LoggingLevel.Debug, new IMCC_APISynchronizationBatch(new Set<Id>()));
    }

    @isTest
    private static void insertAssetWithParent(){
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Edition__c edit = [SELECT Id FROM Edition__c LIMIT 1];
        Test.startTest();
        Triggers_Configuration__mdt triggerConfiguration = new Triggers_Configuration__mdt(Before_Insert__c=true,Before_Update__c=false,After_Insert__c=false,After_Update__c=false);
        IMCC_UtilityMethods.mapTriggerConfiguration.put('IMCC_AssetTrigger', triggerConfiguration);
        
        List<Asset> listAsset2 = [SELECT Id,Name,Purchase_Data__c FROM Asset Where ContactId=:con.id];
        listAsset2[1].ParentId = listAsset2[0].Id;
        update listAsset2[1];
        
        triggerConfiguration = new Triggers_Configuration__mdt(Before_Insert__c=true,Before_Update__c=true,After_Insert__c=true,After_Update__c=true);
        IMCC_UtilityMethods.mapTriggerConfiguration.put('IMCC_AssetTrigger', triggerConfiguration);
        
        List<Asset> listAsset = new List<Asset>();
        Asset ast = new Asset(Name= 'test Asset1',AccountId = acc.id,ParentId=listAsset2[0].Id, ContactId = con.id,Edition__c = edit.id,Booth_Status__c = 'Rented',Booth_Number__c='1',Status = 'Purchased',Source_Org__c='EMEA',User_Type1__c='Exhibitor',Booth_Product_Type1__c='Space Only',Source_Id__c='testid');
        listAsset.add(ast);
        ast = new Asset(Name= 'test Asset2',AccountId = acc.id,ParentId=listAsset2[1].Id, ContactId = con.id,Edition__c = edit.id,Booth_Status__c = 'Rented',Booth_Number__c='2',Status = 'Purchased',Source_Org__c='EMEA',User_Type1__c='Exhibitor',Booth_Product_Type1__c='Space Only',Source_Id__c='testid');
        listAsset.add(ast);
        insert listAsset;
        
        Test.stopTest();
        
        List<Contact_Edition_Mapping__c> contEdiMapingList = [SELECT Id FROM Contact_Edition_Mapping__c];
        System.assertEquals(2, contEdiMapingList.size(),'All CEM Created');
        List<Purchase_Data__c> purchDataList = [SELECT Id FROM Purchase_Data__c];
        System.assertEquals(5, purchDataList.size(),'All PD Created'); 
        System.debug(LoggingLevel.Debug, new IMCC_APISynchronizationBatch(new Set<Id>()));
    }
    
    @isTest
    private static void releaseAssetAsync(){
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Test.startTest();
        
        Triggers_Configuration__mdt triggerConfiguration = new Triggers_Configuration__mdt(Before_Insert__c=true,Before_Update__c=true,After_Insert__c=true,After_Update__c=true);
        IMCC_UtilityMethods.mapTriggerConfiguration.put('IMCC_AssetTrigger_Async', triggerConfiguration);
        
        List<Asset> listAsset = [SELECT Id,Name,Purchase_Data__c FROM Asset Where ContactId=:con.id];
        
        listAsset[0].Booth_Status__c = 'Released';
        update listAsset;
        Test.stopTest();
        List<Purchase_Data__c> purchDataList = [SELECT Id FROM Purchase_Data__c Where Purchase_Status__c='Inactive'];
        System.assertEquals(1, purchDataList.size(),'All PD Created'); 
    }

    @isTest
    private static void releaseAsset(){
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Test.startTest();
        
        Triggers_Configuration__mdt triggerConfiguration = new Triggers_Configuration__mdt(Before_Insert__c=true,Before_Update__c=true,After_Insert__c=true,After_Update__c=true);
        IMCC_UtilityMethods.mapTriggerConfiguration.put('IMCC_AssetTrigger', triggerConfiguration);
        
        List<Asset> listAsset = [SELECT Id,Name,Purchase_Data__c FROM Asset Where ContactId=:con.id];
        
        listAsset[0].Booth_Status__c = 'Released';
        update listAsset;
        Test.stopTest();
        List<Purchase_Data__c> purchDataList = [SELECT Id FROM Purchase_Data__c Where Purchase_Status__c='Inactive'];
        System.assertEquals(1, purchDataList.size(),'All PD Created'); 
    }
    
    @isTest
    private static void changeContactAsync(){
        List<Contact> con = [SELECT Id FROM Contact];
        Test.startTest();
        
        Triggers_Configuration__mdt triggerConfiguration = new Triggers_Configuration__mdt(Before_Insert__c=true,Before_Update__c=true,After_Insert__c=true,After_Update__c=true);
        IMCC_UtilityMethods.mapTriggerConfiguration.put('IMCC_AssetTrigger_Async', triggerConfiguration);
        
        List<Asset> listAsset = [SELECT Id,Name,Purchase_Data__c FROM Asset];
        
        listAsset[0].ContactId = con[2].Id;
        update listAsset;
        Test.stopTest();
        List<Contact_Edition_Mapping__c> contEdiMapingList = [SELECT Id FROM Contact_Edition_Mapping__c];
        System.assertEquals(3, contEdiMapingList.size(),'All CEM Created');
        List<Purchase_Data__c> purchDataList = [SELECT Id FROM Purchase_Data__c];
        System.assertEquals(3, purchDataList.size(),'All PD Created'); 
    }

    @isTest
    private static void changeContact(){
        List<Contact> con = [SELECT Id FROM Contact];
        Test.startTest();
        
        Triggers_Configuration__mdt triggerConfiguration = new Triggers_Configuration__mdt(Before_Insert__c=true,Before_Update__c=true,After_Insert__c=true,After_Update__c=true);
        IMCC_UtilityMethods.mapTriggerConfiguration.put('IMCC_AssetTrigger_Async', triggerConfiguration);
        
        List<Asset> listAsset = [SELECT Id,Name,Purchase_Data__c FROM Asset];
        
        listAsset[0].ContactId = con[2].Id;
        update listAsset;
        Test.stopTest();
        List<Contact_Edition_Mapping__c> contEdiMapingList = [SELECT Id FROM Contact_Edition_Mapping__c];
        System.assertEquals(3, contEdiMapingList.size(),'All CEM Created');
        List<Purchase_Data__c> purchDataList = [SELECT Id FROM Purchase_Data__c];
        System.assertEquals(3, purchDataList.size(),'All PD Created'); 
    }
    
    @isTest
    private static void requeueAllTarnsaction(){
        Test.startTest();
        
        List<IMCC_API_Synchronization_Transaction__c> listAST = [SELECT Id FROM IMCC_API_Synchronization_Transaction__c];
        
        listAST[0].Status__c = 'Requeue All';
        update listAST[0];
        Test.stopTest();
        List<Contact_Edition_Mapping__c> contEdiMapingList = [SELECT Id FROM Contact_Edition_Mapping__c];
        System.assertEquals(2, contEdiMapingList.size(),'All CEM Created');
        List<Purchase_Data__c> purchDataList = [SELECT Id FROM Purchase_Data__c];
        System.assertEquals(3, purchDataList.size(),'All PD Created'); 
    }
    
    @isTest
    private static void requeueSuccessFullTarnsaction(){
        Test.startTest();
        
        List<IMCC_API_Synchronization_Transaction__c> listAST = [SELECT Id FROM IMCC_API_Synchronization_Transaction__c];
        
        listAST[0].Status__c = 'Requeue for Successful records';
        update listAST[0];
        Test.stopTest();
        List<Contact_Edition_Mapping__c> contEdiMapingList = [SELECT Id FROM Contact_Edition_Mapping__c];
        System.assertEquals(2, contEdiMapingList.size(),'All CEM Created');
        List<Purchase_Data__c> purchDataList = [SELECT Id FROM Purchase_Data__c];
        System.assertEquals(3, purchDataList.size(),'All PD Created'); 
    }
    
    @isTest
    private static void requeueErrorTarnsaction(){
        Test.startTest();
        
        List<IMCC_API_Synchronization_Transaction__c> listAST = [SELECT Id FROM IMCC_API_Synchronization_Transaction__c];
        List<IMCC_API_Synchronization_Item__c> listASI = [SELECT Id FROM IMCC_API_Synchronization_Item__c Where IMCC_API_Synchronization_Transaction__c=:listAST[0].Id];
        for(IMCC_API_Synchronization_Item__c item : listASI){
            item.Status__c = 'Error';
        }
        update listASI;
        listAST[0].Status__c = 'Requeue for Erroneous records';
        update listAST[0];
        Test.stopTest();
        List<Contact_Edition_Mapping__c> contEdiMapingList = [SELECT Id FROM Contact_Edition_Mapping__c];
        System.assertEquals(2, contEdiMapingList.size(),'All CEM Created');
        List<Purchase_Data__c> purchDataList = [SELECT Id FROM Purchase_Data__c];
        System.assertEquals(3, purchDataList.size(),'All PD Created'); 
    }
    
    @isTest
    private static void requeueErrorTarnsaction2(){
        Test.startTest();
        
        List<IMCC_API_Synchronization_Transaction__c> listAST = [SELECT Id FROM IMCC_API_Synchronization_Transaction__c];
        List<IMCC_API_Synchronization_Item__c> listASI = [SELECT Id FROM IMCC_API_Synchronization_Item__c Where IMCC_API_Synchronization_Transaction__c=:listAST[0].Id];
        for(IMCC_API_Synchronization_Item__c item : listASI){
            item.Status__c = 'Error';
        }
        update listASI;
        listAST[0].Status__c = 'Requeue for Erroneous records';
        update listAST[0];
        IMCC_APISynchronizationHelper.scheduleBatchForNextItems();
        Test.stopTest();
        List<Contact_Edition_Mapping__c> contEdiMapingList = [SELECT Id FROM Contact_Edition_Mapping__c];
        System.assertEquals(2, contEdiMapingList.size(),'All CEM Created');
        List<Purchase_Data__c> purchDataList = [SELECT Id FROM Purchase_Data__c];
        System.assertEquals(3, purchDataList.size(),'All PD Created'); 
    }
    
    @isTest
    private static void insertAssetNegativeAsync(){
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<Contact> con = [SELECT Id FROM Contact];
        Edition__c edit = [SELECT Id FROM Edition__c LIMIT 1];
        Test.startTest();
        IMCC_APISynchronizationHelper.createResponseAttchment(acc.Id, '');
        IMCC_APISynchronizationBatch cb = new IMCC_APISynchronizationBatch();
        IMCC_API_Synchronization_Item__c item = new IMCC_API_Synchronization_Item__c();
        cb.execute(null,new List<IMCC_API_Synchronization_Item__c>{item});
        Triggers_Configuration__mdt triggerConfiguration = new Triggers_Configuration__mdt(Before_Insert__c=true,Before_Update__c=true,After_Insert__c=true,After_Update__c=true);
        IMCC_UtilityMethods.mapTriggerConfiguration.put('IMCC_AssetTrigger_Async', triggerConfiguration);
        IMCC_AssetTriggerHandler.isTestNegative = true;
        
        List<Asset> listAsset = new List<Asset>();
        Asset ast = new Asset(Name= 'test Asset1',AccountId = acc.id, ContactId = con[2].id,Edition__c = edit.id,Booth_Status__c = 'Rented',Booth_Number__c='1',Status = 'Purchased',Source_Org__c='EMEA',User_Type1__c='Exhibitor',Booth_Product_Type1__c='Space Only',Source_Id__c='testid');
        listAsset.add(ast);
        insert listAsset;
        IMCC_APISynchronizationTransactionHelper.handleAfterUpdate(null,null);
        Test.stopTest();
        
        List<Contact_Edition_Mapping__c> contEdiMapingList = [SELECT Id FROM Contact_Edition_Mapping__c];
        System.assertEquals(2, contEdiMapingList.size(),'All CEM Created');
        List<Purchase_Data__c> purchDataList = [SELECT Id FROM Purchase_Data__c];
        System.assertEquals(3, purchDataList.size(),'All PD Created'); 
    }
    
    @isTest
    private static void insertAssetNegative2Async(){
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<Contact> con = [SELECT Id FROM Contact LIMIT 3];
        Edition__c edit = [SELECT Id FROM Edition__c LIMIT 1];
        insert new Contact_Edition_Mapping__c(Contact__c=con[2].id,Account__c = acc.id,Edition__c = edit.id,Access_Type__c = 'Exhibitor',Relationship_Status__c = 'Active',isSecondary__c = true);
        Test.startTest();
        
        Triggers_Configuration__mdt triggerConfiguration = new Triggers_Configuration__mdt(Before_Insert__c=true,Before_Update__c=true,After_Insert__c=true,After_Update__c=true);
        IMCC_UtilityMethods.mapTriggerConfiguration.put('IMCC_AssetTrigger_Async', triggerConfiguration);
        
        List<Asset> listAsset = new List<Asset>();
        Asset ast = new Asset(Name= 'test Asset1',AccountId = acc.id, ContactId = con[2].id,Edition__c = edit.id,Booth_Status__c = 'Rented',Booth_Number__c='12345',Status = 'Purchased',Source_Org__c='EMEA',User_Type1__c='Exhibitor',Booth_Product_Type1__c='Space Only',Source_Id__c='testid');
        listAsset.add(ast);
        insert listAsset;
        
        Test.stopTest();
        
        List<Contact_Edition_Mapping__c> contEdiMapingList = [SELECT Id FROM Contact_Edition_Mapping__c];
        System.assertEquals(3, contEdiMapingList.size(),'All CEM Created');
        List<Purchase_Data__c> purchDataList = [SELECT Id FROM Purchase_Data__c];
        System.assertNotEquals(4, purchDataList.size(),'All PD Created'); 
    }
}