/**
* Created By    :  Girikon(Keertiraj)
* Created on    : 05/10/2021
* @description  : The purpose of this class is to keep common reusable functionalities at single place.
* Modified By     :  Girikon(Arushi[IMCC-763])
* Modified On     :  28/03/2022
* @description   :  On a new customer username creation in Salesforce, currently there are extra characters created along with the email in the username. This will need to be removed for the ease of use from customer's side. 
* Test Class    : (92%), IMCC_UtilityMethods_Test (83%),IMCC_AssetTriggerHandler_Test(58%)
* Modified By : Shiv Raghav (Ticket No - IMCC-2815 ), Garima Gupta(IMCC-4529, 31st Aug 2022),[Aishwarya Kumar IMCC-4936 16 Dec 2022]
* @description : Added null check as part of IMCC-2815 ticket
*/

public without sharing class IMCC_UtilityMethods {
    public static Map<String,Triggers_Configuration__mdt> mapTriggerConfiguration = new Map<String,Triggers_Configuration__mdt>();

    /**
    * @description : Prepare customer community user list
    * @param profileId
    * @param contacts
    * @return : List<User>
    **/
    public static List<User> prepareCommunityUser(Id profileId, List<Contact> contacts){
        //Initialization of community user list
        List<User> commUserLst = new List<User>();
        for(Contact con : contacts){
            String aliasName = (String.isNotBlank(con.FirstName)?String.valueOf(con.FirstName.substring(0,1)):'') + String.valueOf(con.LastName.substring(0,1));

            User commUsr = new User(ContactId = con.Id,
                                    Username = con.Email,
                                    FirstName = con.FirstName,
                                    LastName = con.LastName,
                                    Email = con.Email,
                                    Alias = aliasName,
                                    ProfileId = profileId,
                                    FederationIdentifier = con.Email,
                                    EmailEncodingKey = 'UTF-8',
                                    LanguageLocaleKey = 'en_US',
                                    LocaleSidKey = 'en_US',
                                    TimeZoneSidKey = 'America/Los_Angeles');
            commUserLst.add(commUsr);                     
        }
        return commUserLst;        
    }
    
    /**
    * @description : Get Community URL
    * @return : String
    **/
    public static String getCommunityURL(){
        Network myNetwork = new Network();
        if(Schema.sObjectType.Network.isAccessible()){
            myNetwork = [SELECT Id FROM Network WHERE Name ='IMCustomerCenter'];
        }
        return Network.getLoginUrl(myNetwork.Id);
    }
    
    /**
    * @description : get Comm Profile
    * @return : Id
    **/
    public static Id getCommProfile(){
        String commProfileId; 
        String commUsrProfile = (String.isNotBlank(Label.IMCC_Community_User_Profile)?Label.IMCC_Community_User_Profile:'IM Customer Community Login User');
        //Fetch community user profile        
        List<Profile> communityProfile = [SELECT Id FROM Profile WHERE Name=:commUsrProfile]; 
        if(!communityProfile.isEmpty()){
            commProfileId = communityProfile.get(0).Id;
        } 
        return commProfileId;
    }

    /**
    * @description : get Contact Edition Mappings
    * @param eventCode
    * @param accountId
    * @return : Map<String,Object>
    **/
    public static Map<String,Object> getContactEditionMappings(String eventCode, String accountId){
        User u = [SELECT id,Name,ContactId FROM User WHERE Id =: UserInfo.getUserId() WITH SECURITY_ENFORCED]; 
        List<Contact_Edition_Mapping__c> conEdMapLst = [SELECT Id,
        Name,
        Access_Type__c,
        Account__c,
        Account__r.Name,
        CC_Status__c,
        Contact__c,
        First_Login_Date_Time__c,        //IMCC-4936 adding parameter in query
        Relationship_Status__c,        
        Completed_Purchase_Summaries__c,      
        Primary_Contact_Edition_Mapping__c,
        Primary_Contact_Edition_Mapping__r.Feathr_Unique_Link__c,
        Feathr_Unique_Link__c,   
        Role__c,
        isSecondary__c,
        Edition__c, 
        Edition__r.Name,        
        Edition__r.Edition_Code__c,  
        Edition__r.Form_Setting__c,
        Edition__r.Event_Setting__c,
        Edition__r.Due_Date__c,
        Edition__r.SizedLogo__c,
        Popup_Marked_as_Read__c,
        Edition__r.Company_Profile_Submission_Due_Date__c,
        Edition__r.Contractor_Nomination_Due_Date__c,        
        Edition__r.Event_Type__c,
        Edition__r.Stand_Setting__r.Allow_Contractor_Nomination__c,
        Edition__r.Stand_Design_Completion_Due_Date__c,
        Edition__r.Expocad_Event_Code__c,
        Edition__r.Start_Date__c
        FROM Contact_Edition_Mapping__c 
        WHERE Contact__c =: u.ContactId 
        AND Account__c =: accountId 
        AND Relationship_Status__c = 'Active' 
        AND Edition__r.Edition_Code__c =: eventCode WITH SECURITY_ENFORCED];

        Set<Id> setIds = new Set<Id>();
        Contact_Edition_Mapping__c conRecrod = new Contact_Edition_Mapping__c();
        if(!conEdMapLst.isEmpty()){
            setIds.add(conEdMapLst.get(0).Id);
            if(String.isNotBlank(conEdMapLst.get(0).Primary_Contact_Edition_Mapping__c)){
                setIds.add(conEdMapLst.get(0).Primary_Contact_Edition_Mapping__c);
            }
            conRecrod =  conEdMapLst.get(0);
        }       
        return new Map<String,Object>{
            'cemList' =>conEdMapLst,
            'cem' => conRecrod,
            'cemIds' => setIds
        };       
    }

    /**
    * @description get Custom meta data info
    * @param name
    * @return Triggers_Configuration__mdt
    */
    public static Triggers_Configuration__mdt getTriggerConfiguration(String name){
        Triggers_Configuration__mdt tconfig;
        if(!Test.isRunningTest()){tconfig = [SELECT Before_Insert__c, Before_Update__c, Before_Delete__c, After_Insert__c, After_Update__c, After_Delete__c, After_Undelete__c FROM Triggers_Configuration__mdt WHERE Trigger_Name__c=:name LIMIT 1];}
        else{
            tconfig = mapTriggerConfiguration.get(name);
        }
        return tconfig;
    }
}