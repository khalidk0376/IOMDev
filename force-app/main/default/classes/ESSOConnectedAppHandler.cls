global class ESSOConnectedAppHandler extends Auth.ConnectedAppPlugin
{
    global override Map<String,String> customAttributes(Id userId, Id connectedAppId, Map<String,String> formulaDefinedAttributes, Auth.InvocationContext context)
    { 
        User u = [SELECT AccountId, Account.Name, ContactId FROM User WHERE Id = :userId];
        
        if (u != null && u.AccountId != null)
        {
            string strJson = '{';
            strJson += '"contactId": "'+ u.ContactId +'","accountId": "' +u.AccountId +'","accountName": "' +u.Account.Name +'","eventEditions": ['; 
            
            list<Contact_Edition_Mapping__c> listCem = [SELECT Access_Type__c,Edition__r.Edition_Code__c,Edition__r.Name,Edition__r.Start_Date__c,Edition__r.End_Date__c FROM Contact_Edition_Mapping__c WHERE 
                                             Account__c =: u.AccountId AND Contact__c =:u.ContactId AND Relationship_Status__c ='Active' ];

            for(Contact_Edition_Mapping__c cem: listCem)
            {
                strJson += '{"accessType": "' +cem.Access_Type__c +'","eventName": "' +cem.Edition__r.Name +'","eventCode": "' +cem.Edition__r.Edition_Code__c+ '","startDate": "' +cem.Edition__r.Start_Date__c +'","endDate": "' +cem.Edition__r.End_Date__c+ '"},';
            }
            if (strJson.endsWith(',')){strJson.left(strJson.length()-1);}
            
            strJson += ']}';
            
            formulaDefinedAttributes.put('exhibitor',  strJson);
        }
            
        return formulaDefinedAttributes;   
    }
}