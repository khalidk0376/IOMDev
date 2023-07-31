/**
* File			: 	GoogleAddressValidationCtrl
* Project		: 	IOM ECOM
* Created By	: 	Ansh(Girikon)
* Test Class	:  	GoogleAddressValidationCtrl_Test
* Coverage		:  	92%  
* Created Date	: 	26th Sept 2022
* *******************************************************************************************************
* @description : class to fetch address detail from google api
* *******************************************************************************************************
* Last Modified By :
*/

public with sharing class GoogleAddressValidationCtrl {


    /**
    * @description : Auto suggestion Web Service 
    * @param searchKey Search text
    * @return String autocomplete json
    */
    @AuraEnabled
    public static string getAddressAutoComplete(String searchKey) {

        String url = GlobalConstants.getValue('Google_Autocomplete_API').replaceAll('<key>',GlobalConstants.getValue('Google_Api_Key')).replaceAll('<searchkey>',EncodingUtil.urlEncode(searchKey, 'UTF-8'));

        return getHttp(url);
    }
    
    /**
    * @description Place Details Web Service 
    * @param placeId Unique Place Id
    * @return String address json
    */ 
    @AuraEnabled
    public static string getAddressDetails(String placeId) {

        String url = GlobalConstants.getValue('Google_Place_API').replaceAll('<key>',GlobalConstants.getValue('Google_Api_Key')).replaceAll('<placeid>',placeId);

        return getHttp(url);
    }
    
    /**
    * @description Common Utility method for making call out
    * @param url API End Point
    * @return String response
    */    
    private static string getHttp(String url){
        try{            
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(url);
            request.setMethod('GET');
            HttpResponse response = http.send(request);

            return response.getBody();
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());}
    } 


    /**
    * @description Get if by pass account address edit
    * @return boolean is by passed or not
    */ 
    @AuraEnabled
    public static boolean getAllowAccountAddressEdit() {
        Application_Bypass__c abpProfile = Application_Bypass__c.getInstance(UserInfo.getProfileId());
        boolean isAllow = false;
        if(abpProfile != null){
            isAllow = abpProfile.Allow_Account_Address_Edit__c;
        }
        if(!isAllow){
            Application_Bypass__c abpUser = Application_Bypass__c.getInstance(UserInfo.getUserId());
            if(abpUser != null){
                isAllow = abpUser.Allow_Account_Address_Edit__c;
            }
        }
        return isAllow;
    }

    /**
    * @description Get Current user profile Name
    * @return String Current user profile Name
    */ 
    @AuraEnabled
    public static String getProfileName() {
        String profileName = '';
        if(Schema.sObjectType.profile.isaccessible())
        {
            profile pro = [Select id ,name from profile where id =: UserInfo.getProfileId()];
            profileName = pro.Name;
        }
        return profileName;
    }

    /**
    * @description : get custom metadata record based on Country code (MasterLabel) from Custom MetaData type.    
    * @return : Map<String, Google_Place_Api_Field_Mapping__mdt>
    **/
    @AuraEnabled(cacheable = true)
    public static Map<String , Google_Place_Api_Field_Mapping__mdt> getGoogleApiMetaData(){
        Map<String , Google_Place_Api_Field_Mapping__mdt> mapGoogleApi = new Map<String , Google_Place_Api_Field_Mapping__mdt>();
        List<Google_Place_Api_Field_Mapping__mdt> lstGoogleApiData = [SELECT Id,MasterLabel,Address_Line_2__c,Address_Line_3__c, QualifiedApiName, Country__c, State__c, City__c, District__c, Postal_Code__c FROM Google_Place_Api_Field_Mapping__mdt];
        for(Google_Place_Api_Field_Mapping__mdt fieldMap : lstGoogleApiData){
            mapGoogleApi.put(fieldMap.MasterLabel , fieldMap);
        }
        return  mapGoogleApi;
    }

}