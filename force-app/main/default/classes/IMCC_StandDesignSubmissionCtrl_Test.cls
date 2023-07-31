@IsTest
public with sharing class IMCC_StandDesignSubmissionCtrl_Test {
    
    @TestSetUp
    static void testUserData(){
        UserRole userrole = [Select Id, DeveloperName From UserRole Where DeveloperName = 'Administrator' Limit 1];
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' and IsActive = true Limit 1];
        adminUser.UserRoleId = userrole.Id;
        update adminUser;
    }
    
    public static testMethod void testStandContractor(){
        // Setup Test Data 
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' and IsActive = true and UserRole.Name = 'Administrator' Limit 1];
        Contact con = new Contact();
        User userObj;
        Id contactId;
        Id accId;
        
        System.runAs(adminUser){
            List<Account> accObj  = IMCC_TestUtilities.createAccount(250);
            accId = accObj[0].Id;
            List<Contact> contObj = IMCC_TestUtilities.createContact(accId, 250);
            contactId = contObj[0].Id;
            con = contObj[0];
            userObj = IMCC_TestUtilities.createCommunityUser(contactId);
            System.assertEquals(userObj.ContactID,contactId, 'Same contact');
        }
        List<Document> docObj  = IMCC_TestUtilities.createDocument(250);
        Id docObjId = docObj[0].Id;
        List<Brand__c> brandObj  = IMCC_TestUtilities.createBrand(250);
        Id brandObjId = brandObj[0].Id;
        List<Series__c> serviceObj  = IMCC_TestUtilities.createEventSeries(brandObjId, 250);
        Id serviceObjId = serviceObj[0].Id;
        List<Event_Setting__c> eveSettingObj = IMCC_TestUtilities.createEventSetting(250);
        Id eveSettingObjId = eveSettingObj[0].Id;
        List<Edition__c> editionObj = IMCC_TestUtilities.createEventEditionWithEveSetting2(serviceObjId,docObjId,eveSettingObjId,2);
        Id editionObjId = editionObj[0].Id;        
        
        //System.assertEquals(editionObj[0].Edition_Code__c,'TEV21', 'Event Code');
        
        Contact_Edition_Mapping__c cemObj = IMCC_TestUtilities.createContactEditionMapping(contactId,accId,editionObjId);
        List<Edition_Websites__c> edwebObj = IMCC_TestUtilities.createEditionWebsites(editionObjId, 250);
        
        Purchase_Data__c booth = IMCC_TestUtilities.createPurchaseData3(contactId,editionObjId,accId);
        booth.Contact_Edition_Mapping__c = cemObj.Id;
        Update booth;
        IMCC_TestUtilities.createPurchaseData(cemObj.id,accId,1);
        
        List<Form_Setting__c> formSettLst = IMCC_TestUtilities.createFormSettings(1);
        System.assertEquals(formSettLst.Size(),1, 'Form Setting List size should be 1');
        editionObj[0].Form_Setting__c = formSettLst[0].id;
        update editionObj;
        Form_Allocation__c formAllocLst5 = IMCC_TestUtilities.createFormAllocation1('Manual','PDF',null,formSettLst[0].id,'One Per Account');
        List<Tab_User_Type__c> tabUserFormAllocLst5 = IMCC_TestUtilities.createTabUserTypeFormAlloc(formAllocLst5.id,1,'Exhibitor');
        System.assertEquals(tabUserFormAllocLst5.Size(),1, 'Tab User List size should be 1');
        Contact_Edition_Mapping__c cem = [SELECT Id FROM Contact_Edition_Mapping__c LIMIT 1];
        Form_Allocation__c fa = [SELECT Id FROM Form_Allocation__c WHERE Form_Entry__c='One Per Account' AND Feature_Category__c='Manual' LIMIT 1];
        System.debug('Form Alloc ' +fa);
        Form_Data__c fd = [SELECT Id FROM Form_Data__c WHERE Contact_Edition_Mapping__c=:cem.id AND Forms_Permission__r.Form_Allocation__c=:fa.Id LIMIT 1];
        System.debug('Form Data ' +fd);
        Map<string,string> param1 = new Map<String,String>();
        param1.put('status','Viewed');
        param1.put('qid','');
        param1.put('conEdMapId',cem.id);
        param1.put('formDataId',fd.id);   
        param1.put('entryId','');
        param1.put('pageNo','0');
        param1.put('totalPages','0');
        param1.put('boothId','');
        FBUtils.saveFormStatus(param1);
        
        
        Id pHId = booth.Id;
        List<Contractor_Mapping__c> cmObj = IMCC_TestUtilities.createContractorMappingData(accId,contactId,cemObj.Id,pHId,'Contractor Nominated',editionObjId,null,1);
        Id cmObjId = cmObj[0].id;
        
        List<Stand_Setting__c> ssl = IMCC_TestUtilities.createStandSetting(1);
        
        editionObj[0].Stand_Setting__c = ssl[0].Id;
        Update editionObj;
        
        //Test content document
        IMCC_TestUtilities.createContentVer(1);
        List<ContentDocument> documents = [SELECT Id FROM ContentDocument LIMIT 1];
        List<ContentDocumentLink> cdl = IMCC_TestUtilities.createContentDocLink(documents[0].Id,ssl[0].Id,1);
        IMCC_StandDesignSubmissionCtrl.updateDocumentName(documents[0].Id,'Informa',ssl[0].Id);
        
        documents = [SELECT Id,Title FROM ContentDocument LIMIT 1];
        System.assertEquals('Informa - 1', documents[0].Title, 'Previous title was "Test PDf1", now it changed to "Informa"');
        
        IMCC_StandDesignSubmissionCtrl.updateDocumentName(documents[0].Id,'Informa',ssl[0].Id);
        System.assertEquals('Informa - 1', documents[0].Title, 'Previous title was "Informa - 1", now it changed to "Informa - 2"');
        
        IMCC_StandDesignSubmissionCtrl.deleteFile(documents[0].Id,ssl[0].Id);
            
        System.runAs(userObj) {
            Test.startTest();
            
            
            IMCC_StandDesignSubmissionCtrl.getExhibitorDetail(cmObjId,false);
            IMCC_StandDesignSubmissionCtrl.getOptions('Account','Type');
            
            Stand_Detail__c standDetail = new Stand_Detail__c();
            standDetail.Contractor_Mapping__c = cmObjId;
            standDetail.Stand_Detail_Status__c='In Progress';
            standDetail.Current_Step__c='1';
            IMCC_StandDesignSubmissionCtrl.saveStandDetail(standDetail);
            standDetail = [SELECT Id,Stand_Detail_Status__c,Current_Step__c,Contractor_Mapping__c FROM Stand_Detail__c WHERE Contractor_Mapping__c=:cmObjId LIMIT 1];
            standDetail.Current_Step__c='3';
            IMCC_StandDesignSubmissionCtrl.saveStandDetail(standDetail);
            IMCC_StandDesignSubmissionCtrl.getManualStatus('Id!=\'\'');
            IMCC_StandDesignSubmissionCtrl.getFiles(standDetail.Id);
            IMCC_StandDesignSubmissionCtrl.getManualPermission(editionObj[0].Edition_Code__c,accId,contactId);
            
            
            IMCC_StandDesignSubmissionCtrl.updateFormAgreed(fd.Id);            
            
            //test attachment
                        
            String fileContent = 'Unit Test Attachment Body';
            IMCC_StandDesignSubmissionCtrl.saveSignature(fileContent,standDetail.Id);
            
            IMCC_StandDesignSubmissionCtrl.getStandFileTypes(null,'Complex');
            
            IMCC_StandDesignSubmissionCtrl.publishStandSettings(ssl[0]);
            Stand_File_Type__c sf = new Stand_File_Type__c(Type__c='Complex',Name='Test');
            insert sf;
            IMCC_StandDesignSubmissionCtrl.deleteStandFileTypes(sf.Id);
            Test.stopTest();
        }
    }   
}