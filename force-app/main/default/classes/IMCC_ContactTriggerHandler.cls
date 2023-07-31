/**
* Created By     :  Girikon(Arushi[IMCC-5341])
* Created On     :  06/06/2023
* @description   :  Contact Email Update in Source Org should be reflected in IMCC
* Apex Test Class: IMCC_ContactTriggerHandler_Test
**/
public without sharing class IMCC_ContactTriggerHandler implements TriggerInterface_Contact.Runnable{
    
    public void run(TriggerInterface_Contact.Trig trig){
        if(trig.isAfter && trig.isUpdate){
        	List<Id> contactIds = new List<Id>();
            for(Contact con : trig.newList){
                if(con.Email != null && con.Email != trig.oldMap.get(con.Id).Email){
                    contactIds.add(con.Id);
                }
        	}
            if(!contactIds.isEmpty()){
            	emailUpdatedContacts(contactIds);
            }
        }
        system.debug('Debug');
    }
    
    @future
    Private static void emailUpdatedContacts(List<Id> contactIds){
        List<User> updatedUserList = new List<User>();
        Map<Id,Contact> mapContact = new Map<Id,Contact>([SELECT Id,Email FROM Contact WHERE Id IN:contactIds WITH SECURITY_ENFORCED]);
        
        List<User> listUser = new List<User>([SELECT Id,CommunityNickname,ContactId,IsActive,ProfileId,Profile.Name
                                              ,Email,FederationIdentifier FROM User WHERE ContactId IN:mapContact.keySet()
                                              AND IsActive = True AND Profile.Name = 'IM Customer Community Login User'
                                              WITH SECURITY_ENFORCED]);
        for(User u : listUser){
            u.Email = mapContact.get(u.ContactId).Email;
            u.FederationIdentifier = mapContact.get(u.ContactId).Email;
            u.Username = mapContact.get(u.ContactId).Email;
            updatedUserList.add(u);
        }
        if(!updatedUserList.isEmpty()) update updatedUserList;
    }
    
}