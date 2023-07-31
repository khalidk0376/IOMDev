/**
* Created      : Girikon(Garima)
* Created On   : 31/03/2023
* @description : This class fetch the login user details and its account details to intialize the pendo.
* Methods      : getMetadata
* Test Class   : IMCC_PendoAgentController_Test (91%)
**/
public without sharing class IMCC_PendoAgentController {
    
    /**
    * @description : to fetch the login user details and CEM Details.
    * @param editionCode edition code
    * @param accountId selected account id
    * @return : Map<String, Object>
    **/
    @AuraEnabled
    public static Map<String, Object> getMetadata(String editionCode, String accountId){
        try {
            User u = [SELECT Id, Username, Email, Name, Contact.Account.Name,Contact.AccountId FROM User  WHERE Id = :UserInfo.getUserId()];
            List<Contact_Edition_Mapping__c> listCEM = new List<Contact_Edition_Mapping__c>();
            Integer editionYear = 0;
            if(String.isNotBlank(editionCode) && String.isNotBlank(accountId)){
                Map<String,Object> mapCEMDetails = IMCC_UtilityMethods.getContactEditionMappings(editionCode, accountId);
                listCEM = (List<Contact_Edition_Mapping__c>)mapCEMDetails.get('cemList');
                if(!listCEM.isEmpty()){
                    if(listCEM[0].Edition__r.Start_Date__c !=null){
                        editionYear = listCEM[0].Edition__r.Start_Date__c.year();
                    }
                }
            }
            return new Map<String, Object> {
                'listCEM' => listCEM,
                'editionYear' => editionYear,
                'visitor' => new Map<String, String> {
                    'username' => u.Username,
                	'email' => u.Email,
                    'name' => u.Name,
                    'id' => u.Id
                 },
                 'account' => new Map<String, String> {
                 	'name' => u.Contact.Account.Name,
                    'id' => u.Contact.AccountId
                 }
            };
        } 
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}