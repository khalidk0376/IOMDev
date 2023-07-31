/**
* Created By       :   Girikon(Sachin)
* Created On       :   18-12-2019
* @description     :   Test class to provide code coverage.          
* Apex Class       :   OppActionButtonController

* Modification log --
* Modified by      :  
**/

@IsTest
public class OppActionButtonController_Test {

    @IsTest
    private static void saveTest() {
        Test.startTest();
        OppActionButtonController.Wrap_CL reqParam = new OppActionButtonController.Wrap_CL();
        OppActionButtonController cont = new OppActionButtonController(); 
        Contact con = new Contact(LastName='test',Email='abc@test.in');
        reqParam.cont_obj = con;
        
        //Test 1
        Object response = OppActionButtonController.invokeInsertOrUpdate('set_contact',JSON.serialize(reqParam));
        System.assert(response != NULL, 'Response should not be NULL');
        
        //Test 2
        Account acc = new Account();
        acc.Name='test acc';
        acc.BillingCity ='Delhi' ;
        acc.BillingCountry='india';
        acc.BillingPostalCode='600075';
        acc.BillingState='Delhi';
        acc.BillingStreet='water well street';
        insert acc;
        
        DateTime dT = System.now().addDays(3);
        Date myDate = date.newinstance(dT.year(), dT.month(), dT.day());
        Edition__c Edi = new Edition__c(Name='TestName',Event_Code__c='XYZ');
        insert Edi;
        
        Opportunity opp = new Opportunity();
        opp.Name = 'Tets';
        opp.CloseDate = myDate;
        opp.StageName = 'Discover';
        opp.AccountId = acc.Id;
        opp.Default_Edition__c = Edi.Id;
        insert opp;
        reqParam.opp_obj = opp;
        
        response = OppActionButtonController.invokeInsertOrUpdate('set_opp',JSON.serialize(reqParam));
        System.assert(response != NULL, 'Response should not be NULL');
        
        //Test 3 clone opportunity
        reqParam.depfieldApiName='Task';
        reqParam.recordId = opp.Id;
        reqParam.oppId = opp.Id;
        //response = OppActionButtonController.invokeInsertOrUpdate('opp_clone_related',JSON.serialize(reqParam));
        //System.assert(response != NULL, 'Response should not be NULL');
        
        //Test 4 add partner
        Account acc2 = new Account();
        acc2.Name = 'acc test 2';
        acc2.BillingCity ='Delhi6';
        acc2.BillingCountry='india';
        acc2.BillingPostalCode='60005';
        acc2.BillingState='Delhi';
        acc2.BillingStreet='water wefs treet';
        insert acc2;
        
        reqParam.partner_obj = new Partner(AccountFromId=acc.Id,Role='Broker',AccountToId=acc2.Id);
        response = OppActionButtonController.invokeInsertOrUpdate('add_partner',JSON.serialize(reqParam));
        System.assert(response != NULL, 'Response should not be NULL');
        
        Contact conObj2 = new Contact(LastName='asas',Email='asdasd@gmail.com',AccountId=acc.Id);
        insert conObj2;
        AccountContactRelation acr = new AccountContactRelation();
        acr.AccountId = acc2.Id;
        acr.ContactId = conObj2.Id;
        acr.Roles='Other';
        reqParam.acc_con_rel_obj = acr;
        OppActionButtonController.getAccountCountryPicklistOptions();
        response = OppActionButtonController.invokeInsertOrUpdate('add_acc_con_rel_obj',JSON.serialize(reqParam));
        System.assert(response != NULL, 'Response should not be NULL');
        Test.stopTest();
    }
    
    @IsTest
    private static void fieldsTest() {
        OppActionButtonController.Wrap_CL reqParam = new OppActionButtonController.Wrap_CL();        
        //Test 1
        Account acc = new Account();
        acc.Name='test acc';
        acc.BillingCity ='Delhi' ;
        acc.BillingCountry='india';
        acc.BillingPostalCode='600075';
        acc.BillingState='Delhi';
        acc.BillingStreet='water well street';
        insert acc;
        reqParam.accountId = acc.Id;
        Object response = OppActionButtonController.invoke('get_account',JSON.serialize(reqParam));
        System.assert(response != NULL, 'Response should not be NULL');
        
        //Test 2
        DateTime dT = System.now().addDays(3);
        Date myDate = date.newinstance(dT.year(), dT.month(), dT.day());
        
        Edition__c Edi = new Edition__c(Name='TestName',Event_Code__c='XYZ');
        insert Edi;
        Opportunity opp = new Opportunity();
        opp.Name = 'Tets';
        opp.CloseDate = myDate;
        opp.StageName = 'Discover';
        opp.AccountId = acc.Id;
        opp.Default_Edition__c = Edi.Id;
        insert opp;
        reqParam.oppId = opp.Id;
        response = OppActionButtonController.invoke('get_opportunity',JSON.serialize(reqParam));
        System.assert(response != NULL, 'Response should not be NULL');
        
        response = OppActionButtonController.invoke('get_quote',JSON.serialize(reqParam));
        System.assert(response != NULL, 'Response should not be NULL');
        
        response = OppActionButtonController.invoke('get_account_detail',JSON.serialize(reqParam));
        //System.assert(response != NULL, 'Response should not be NULL');
        
        Contact con = new Contact(LastName='test',email='test@abc.com');
        insert con;
        reqParam.recordId=con.Id;
        response = OppActionButtonController.invoke('get_con_detail',JSON.serialize(reqParam));
        //System.assert(response != NULL, 'Response should not be NULL');
        
        response = OppActionButtonController.invoke('get_amend_team_member',JSON.serialize(reqParam));
        //System.assert(response != NULL, 'Response should not be NULL');
        
        reqParam.searchKey='test';
        response = OppActionButtonController.invoke('get_booth',JSON.serialize(reqParam));
        //System.assert(response != NULL, 'Response should not be NULL');
        
        reqParam.searchKey='';
        response = OppActionButtonController.invoke('get_booth',JSON.serialize(reqParam));
        //System.assert(response != NULL, 'Response should not be NULL');
        
        response = OppActionButtonController.invoke('get_partner_field',JSON.serialize(reqParam));
        //System.assert(response != NULL, 'Response should not be NULL');
        
        reqParam.objectName='Opportunity';
        reqParam.fieldName='Name';
        reqParam.fieldValue='Name';
        reqParam.searchKey='';
        response = OppActionButtonController.invoke('lookup',JSON.serialize(reqParam));
        //System.assertEquals('Account2Class' , oAccount.Name, 'true');
        //System.assert(response != NULL, 'Response should not be NULL')
        
        reqParam.searchKey='tets';
        response = OppActionButtonController.invoke('lookup',JSON.serialize(reqParam));
        //System.assert(response != NULL, 'Response should not be NULL');
        
        OppActionButtonController.getRecord(con.Id,'Contact','LastName');
        //'Account','billingCountryCode','billingStateCode'
        reqParam.objApi='Account';
        reqParam.contrfieldApiName='billingCountryCode';
        reqParam.depfieldApiName='billingStateCode';
        OppActionButtonController.getDependentMap(JSON.serialize(reqParam));
        
        Test.startTest();       
        Test.setMock(HttpCalloutMock.class, new AddressAutoComplete());
        reqParam.searchKey='girikon';
        response = OppActionButtonController.invoke('get_addresses',JSON.serialize(reqParam));
        System.assert(response != NULL, 'Response should not be NULL');
        reqParam.placeId = 'asdasdda';
        response = OppActionButtonController.invoke('get_address_detail',JSON.serialize(reqParam));
        System.assert(response != NULL, 'Response should not be NULL');
        reqParam.recordId = con.Id;
        response = OppActionButtonController.invoke('get_parent',JSON.serialize(reqParam));
        OppActionButtonController.fetchUser();
        OppActionButtonController.getUserRecordAccess(con.Id);
        reqParam.cont_obj = con;
        OppActionButtonController.invoke('delete_contact',JSON.serialize(reqParam));
        Test.stopTest();
    }
    
    //Create Httpcallout mock response
    private class AddressAutoComplete implements HTTPCalloutMock{
        public HTTPResponse respond(HTTPRequest req){
            HttpResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/JSON');
            res.setBody('{predictions : [{description : Girikon - Salesforce Consulting, North Tatum Boulevard, Phoenix, AZ, USA,id : 36f85aab59c54f4d93f3dd5ee5c76ec30837fb55,matched_substrings : [{length : 7,offset : 0}],place_id : ChIJe2Fsc5YNK4cRsyMLNVZi0Po,reference : ChIJe2Fsc5YNK4cRsyMLNVZi0Po,structured_formatting : {main_text : Girikon - Salesforce Consulting,main_text_matched_substrings : [{length : 7,offset : 0}],secondary_text : North Tatum Boulevard, Phoenix, AZ, USA},terms : [{offset : 0,value : Girikon - Salesforce Consulting},{offset : 33,value : North Tatum Boulevard},{offset : 56,value : Phoenix},{offset : 65,value : AZ},{offset : 69,value : USA}],types : [ establishment ]},{description : Girikon USA, South 48th Street, Tempe, AZ, USA,id : 35c9ef1cb6700c0754f5e9c46d79e83ae906841f,matched_substrings : [{length : 7,offset : 0}],place_id : ChIJwXcapeAOK4cR1jC6B-hR7nk,reference : ChIJwXcapeAOK4cR1jC6B-hR7nk,structured_formatting : {main_text : Girikon USA,main_text_matched_substrings : [{length : 7,offset : 0}],secondary_text : South 48th Street, Tempe, AZ, USA},terms : [{offset : 0,value : Girikon USA},{offset : 13,value : South 48th Street},{offset : 32,value : Tempe},{offset : 39,value : AZ},{offset : 43,value : USA}],types : [ establishment ]},{description : Kirkenes, Norway,id : c5273ef6d456f35e6cc08dd7bc856f0f96fdac9b,matched_substrings : [{length : 8,offset : 0}],place_id : ChIJD0qdGM5Iy0URrY07tVlYRyE,reference : ChIJD0qdGM5Iy0URrY07tVlYRyE,structured_formatting : {main_text : Kirkenes,main_text_matched_substrings : [{length : 8,offset : 0}],secondary_text : Norway},terms : [{offset : 0,value : Kirkenes},{offset : 10,value : Norway}],types : [ locality, political, geocode ]},{description : Girkonjárgohppi, Russenes, Norway,id : 270ddcbe7b7058d4c1f5adb4f92973e926b77d2d,matched_substrings : [{length : 6,offset : 0}],place_id : ChIJPSiTnk8kyUURXQOhSFZjmyg,reference : ChIJPSiTnk8kyUURXQOhSFZjmyg,structured_formatting : {main_text : Girkonjárgohppi,main_text_matched_substrings : [{length : 6,offset : 0}],secondary_text : Russenes, Norway},terms : [{offset : 0,value : Girkonjárgohppi},{offset : 17,value : Russenes},{offset : 27,value : Norway}],types : [ natural_feature, establishment, geocode ]},{description : Girkonuorri, Tana, Norway,id : 9a66fe5ad1ca6c2a1cf8a0e1ea9c6daebc1738b5,matched_substrings : [{length : 6,offset : 0}],place_id : ChIJ0_VBaMeWy0UReKPpORLIbag,reference : ChIJ0_VBaMeWy0UReKPpORLIbag,structured_formatting : {main_text : Girkonuorri,main_text_matched_substrings : [{length : 6,offset : 0}],secondary_text : Tana, Norway},terms : [{offset : 0,value : Girkonuorri},{offset : 13,value : Tana},{offset : 19,value : Norway}],types : [ natural_feature, establishment, geocode ]}],status : OK}');
            res.setStatusCode(200);
            return res;
        }
    }
    
}