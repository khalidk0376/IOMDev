/**
* File			: 	IOM_AddressValidation_Test
* Project		: 	Informa Order Management
* Created By	: 	Ansh(Girikon)
* Created Date	: 	10th Feb 2022
* **************************************************************************************************************************************
* @description : Test Class to provide code covrage to classes - IOM_AddressValidation
* **************************************************************************************************************************************
* Last Modified By :
*/
@IsTest
private with sharing class IOM_AddressValidation_Test {
    
    private class AddressAutoComplete implements HTTPCalloutMock{
        /**
        * @description AddressAutoComplete Mock for test class
        * @param req
        * @return HTTPResponse
        */
        public HTTPResponse respond(HTTPRequest req){
            HttpResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/JSON');
            res.setBody('{predictions : [{description : Girikon - Salesforce Consulting, North Tatum Boulevard, Phoenix, AZ, USA,id : 36f85aab59c54f4d93f3dd5ee5c76ec30837fb55,matched_substrings : [{length : 7,offset : 0}],place_id : ChIJe2Fsc5YNK4cRsyMLNVZi0Po,reference : ChIJe2Fsc5YNK4cRsyMLNVZi0Po,structured_formatting : {main_text : Girikon - Salesforce Consulting,main_text_matched_substrings : [{length : 7,offset : 0}],secondary_text : North Tatum Boulevard, Phoenix, AZ, USA},terms : [{offset : 0,value : Girikon - Salesforce Consulting},{offset : 33,value : North Tatum Boulevard},{offset : 56,value : Phoenix},{offset : 65,value : AZ},{offset : 69,value : USA}],types : [ establishment ]},{description : Girikon USA, South 48th Street, Tempe, AZ, USA,id : 35c9ef1cb6700c0754f5e9c46d79e83ae906841f,matched_substrings : [{length : 7,offset : 0}],place_id : ChIJwXcapeAOK4cR1jC6B-hR7nk,reference : ChIJwXcapeAOK4cR1jC6B-hR7nk,structured_formatting : {main_text : Girikon USA,main_text_matched_substrings : [{length : 7,offset : 0}],secondary_text : South 48th Street, Tempe, AZ, USA},terms : [{offset : 0,value : Girikon USA},{offset : 13,value : South 48th Street},{offset : 32,value : Tempe},{offset : 39,value : AZ},{offset : 43,value : USA}],types : [ establishment ]},{description : Kirkenes, Norway,id : c5273ef6d456f35e6cc08dd7bc856f0f96fdac9b,matched_substrings : [{length : 8,offset : 0}],place_id : ChIJD0qdGM5Iy0URrY07tVlYRyE,reference : ChIJD0qdGM5Iy0URrY07tVlYRyE,structured_formatting : {main_text : Kirkenes,main_text_matched_substrings : [{length : 8,offset : 0}],secondary_text : Norway},terms : [{offset : 0,value : Kirkenes},{offset : 10,value : Norway}],types : [ locality, political, geocode ]},{description : Girkonjárgohppi, Russenes, Norway,id : 270ddcbe7b7058d4c1f5adb4f92973e926b77d2d,matched_substrings : [{length : 6,offset : 0}],place_id : ChIJPSiTnk8kyUURXQOhSFZjmyg,reference : ChIJPSiTnk8kyUURXQOhSFZjmyg,structured_formatting : {main_text : Girkonjárgohppi,main_text_matched_substrings : [{length : 6,offset : 0}],secondary_text : Russenes, Norway},terms : [{offset : 0,value : Girkonjárgohppi},{offset : 17,value : Russenes},{offset : 27,value : Norway}],types : [ natural_feature, establishment, geocode ]},{description : Girkonuorri, Tana, Norway,id : 9a66fe5ad1ca6c2a1cf8a0e1ea9c6daebc1738b5,matched_substrings : [{length : 6,offset : 0}],place_id : ChIJ0_VBaMeWy0UReKPpORLIbag,reference : ChIJ0_VBaMeWy0UReKPpORLIbag,structured_formatting : {main_text : Girkonuorri,main_text_matched_substrings : [{length : 6,offset : 0}],secondary_text : Tana, Norway},terms : [{offset : 0,value : Girkonuorri},{offset : 13,value : Tana},{offset : 19,value : Norway}],types : [ natural_feature, establishment, geocode ]}],status : OK}');
            res.setStatusCode(200);
            return res;
        }
    }

    @IsTest
    private static void unitTest() {
        Test.startTest();  
        IOM_AddressValidation.getAllowAccountAddressEdit();     
        Test.setMock(HttpCalloutMock.class, new AddressAutoComplete());
        string responseAC = IOM_AddressValidation.getAddressAutoComplete('123 creek lane');
        System.assert(responseAC != NULL, 'Response should not be NULL');
        IOM_AddressValidation.getProfileName();
        string response = IOM_AddressValidation.getAddressDetails('testplaceid');
        System.assert(response != NULL, 'Response should not be NULL');
        Map<String,IOM_Google_Place_Api_Field_Mapping__mdt> data = IOM_AddressValidation.getGoogleApiMetaData();
        System.AssertNotEquals(null,data,'data not retrived.');
        Test.stopTest();
    }
}