/**
* File      	:   CalculateDateDiff_Test
* Project       : 	Informa Order Management 
* Created By  	:   Girikon(Deepak)
* Created Date  :   17th March 2022
* ******************************************************************************************************
* @description : Test Class to provide code covrage to classes - CalculateDateDiff
* Last Modified By :
*/
@isTest
private class CalculateDateDiff_Test {
    
    @isTest
    private static void testRest(){
        string body = '{"Line1":{ "startdate": "2022-03-01", "endDate" : "2022-05-01" },"Line2":{ "startdate": "2022-03-01", "endDate" : "2022-05-01" }}';
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/calculatedatediff'; 
        req.requestBody = Blob.valueOf(body);
        req.httpMethod = 'Post';
        req.addHeader('Content-Type', 'application/json'); 
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        Map<String,String> mapRes = CalculateDateDiff.DateDiff();
        System.assertEquals(2, mapRes.size(), 'Date Validation Success');
        Test.stopTest();
    }

}