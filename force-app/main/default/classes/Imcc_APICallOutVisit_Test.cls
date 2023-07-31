/**
* Created/Modified By    : Girikon(Arushi [IMCC-4862])
* Created On             : 22-Nov-2022
* @description           : Helper class method can be called on demand to make API Callout 
* Apex Class             : IMCC_APICallOutVisit
* Code Coverage          : 100%
**/
@isTest
private class Imcc_APICallOutVisit_Test {
    @isTest 
    static  void testGetCallout() {
        Test.startTest();
        Map<String,String> mapURIBody = new Map<String,String>();
        String resJSON1 = '{"animals": ["majestic badger", "fluffy bunny"]}';
        mapURIBody.put('visitGetCall','200###'+resJSON1);
        Test.setMock(HttpCalloutMock.class, new IMCC_VisitAPIHttpCalloutMock(mapURIBody)); 
        IMCC_SchedulableGetCall sh1 = new IMCC_SchedulableGetCall();
        String sch = '0 0 23 * * ?';
        system.schedule('Test Check', sch, sh1);
        Test.stopTest();
        System.assertEquals(0, [SELECT Id FROM Custom_Error_Log__c].size(),'No Errors');
    } 
    
    @isTest 
    static  void testGetCallout2() {
        Test.startTest();
        Map<String,String> mapURIBody = new Map<String,String>();
        String resJSON1 = '{"animals": ["majestic badger", "fluffy bunny"]}';
        mapURIBody.put('visitGetCall','200###'+resJSON1);
        Test.setMock(HttpCalloutMock.class, new IMCC_VisitAPIHttpCalloutMock(mapURIBody)); 
        IMCC_APICallOutVisit.makeGetCallout();
        Test.stopTest();
        System.assertEquals(0, [SELECT Id FROM Custom_Error_Log__c].size(),'No Errors');
    } 

    @isTest 
    static  void testGetCallout3() {
        Test.startTest();
        Map<String,String> mapURIBody = new Map<String,String>();
        String resJSON1 = '{"animals": ["majestic badger", "fluffy bunny"]}';
        mapURIBody.put('visitGetCall','400###'+resJSON1);
        Test.setMock(HttpCalloutMock.class, new IMCC_VisitAPIHttpCalloutMock(mapURIBody)); 
        IMCC_APICallOutVisit.makeGetCallout();
        Test.stopTest();
        System.assertEquals(1, [SELECT Id FROM Custom_Error_Log__c].size(),'No Errors');
    }
}