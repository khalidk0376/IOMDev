/**
* Created By    :  Girikon(Keertiraj)
* Created on    : 18/10/2021
* @description  : The purpose of this class is to show data on new user welcome email visualforce component.
* Test Class    : IMCC_WelcomeEmailCtrl_Test(100%)
*/

public without sharing class IMCC_WelcomeEmailCtrl {

    /**@description Contact Id */
    public string sContactId {get;set;}
    
    /**@description IMCC_WelcomeEmailCtrl Constructor */
    public IMCC_WelcomeEmailCtrl(){
        system.debug(LoggingLevel.Debug, '@@@@@@@@@@@@');
    }
    
    /**@description to get Welcome Email Content and Subject 
    * @return EmailContent
    */
    public EmailContent getWelcomeEmailContent(){
        return welcomeEmailContentData(sContactId, null);
    }

    /**@description to get Welcome Email Content and Subject 
    * @param contactId
    * @param editionId
    * @return EmailContent
    */
    public EmailContent welcomeEmailContentData(String contactId ,String editionId){
        String body = '';
        /*String commURL = System.Label.CommunityURL;
        String documentURL = System.Label.Document_URL;
        if(String.isNotBlank(contactId) && Schema.sObjectType.Contact.isAccessible()){
            List<Contact> conList = [SELECT Id,FirstName,Account.Name,Contact_Edition_Mapping__c,Contact_Edition_Mapping__r.Edition__c FROM Contact where Id=:contactId LIMIT 1]; 
            List<User> user = [SELECT Id,UserName,FirstName FROM User where ContactId=:contactId LIMIT 1];
            
            if(String.isBlank(editionId) && !conList.isEmpty() && String.isNotBlank(conList.get(0).Contact_Edition_Mapping__c)){
                editionId = conList.get(0).Contact_Edition_Mapping__r.Edition__c;

                List<Event_Edition_Email_Template__c> listEEET = [SELECT Content__c, Subject__c, From_Email_Address__c, Edition__c FROM Event_Edition_Email_Template__c WHERE Edition__c=:editionId AND Template_Code__c='WELNew' WITH SECURITY_ENFORCED];
                if(!listEEET.isEmpty()){
                    Event_Edition_Email_Template__c template = listEEET.get(0);
                    body = template.Content__c;
                    
                    List<Contact_Edition_Mapping__c> listCEM = [SELECT Id, Account__c,Account__r.Name, Contact__c,Edition__c,Edition__r.Name, CC_Status__c,Edition__r.Edition_Code__c,Edition__r.Edition_Image_URL__c,Relationship_Status__c, Access_Type__c,Edition__r.Business_Hours__c,Edition__r.Support_Email__c,Edition__r.Edition_Website__c,Edition__r.Start_Date__c,Edition__r.Venue__c,Edition__r.Customer_Support_Team__r.Business_Hours__c,Edition__r.Customer_Support_Team__r.Hotline_Number__c FROM Contact_Edition_Mapping__c WHERE Id=:conList.get(0).Contact_Edition_Mapping__c WITH SECURITY_ENFORCED];
                    if(!listCEM.isEmpty()){
                        Contact_Edition_Mapping__c conEvntMap = listCEM.get(0);
                        String companyName = conEvntMap.Account__r.Name!=null?conEvntMap.Account__r.Name:'';                
                        String firstName = (!user.isEmpty()?user.get(0).FirstName:'');
                        String userName = (!user.isEmpty()?user.get(0).UserName:'');
                        String eventName = conEvntMap.Edition__r.Name!=null?conEvntMap.Edition__r.Name:'';
                        String businessHours = conEvntMap.Edition__r.Business_Hours__c!=null?conEvntMap.Edition__r.Business_Hours__c:''; 
                        String cSTeamBusinessHours = conEvntMap.Edition__r.Customer_Support_Team__r.Business_Hours__c!=null?conEvntMap.Edition__r.Customer_Support_Team__r.Business_Hours__c:''; 
                        String hotlineNumber = conEvntMap.Edition__r.Customer_Support_Team__r.Hotline_Number__c!=null?conEvntMap.Edition__r.Customer_Support_Team__r.Hotline_Number__c:''; 
                        String eventVenue = conEvntMap.Edition__r.Venue__c!=null?conEvntMap.Edition__r.Venue__c:''; 
                        String eventWebsite = conEvntMap.Edition__r.Edition_Website__c!=null?conEvntMap.Edition__r.Edition_Website__c:'';
                        Datetime eventStartDate = conEvntMap.Edition__r.Start_Date__c!=null?conEvntMap.Edition__r.Start_Date__c:null;           
                        String supportEmail = conEvntMap.Edition__r.Support_Email__c!=null?conEvntMap.Edition__r.Support_Email__c:'';
                        
                        body = body.replace('{Event Name}',eventName);  
                        body = body.replace('{COMPANY NAME}',companyName);
                        body = body.replace('{Firstname}',firstName);
                        body = body.replace('{UserName}',userName);

                        body = body.replace('{Venue}',eventVenue);
                        body = body.replace('{Website}',eventWebsite);
                        body = body.replace('{SupportEmail}',supportEmail);
                        body = body.replace('{HotlineNumber}',hotlineNumber);
                        if(conEvntMap.Edition__r.Business_Hours__c !=null){
                            body = body.replace('{BusinessHours}',businessHours);
                        }
                        else{
                            body = body.replace('{BusinessHours}',cSTeamBusinessHours);
                        }     
                        if(eventStartDate !=null){
                            body = body.replace('{StartDate}',IMCC_UtilityMethod_Handler.getFormattedDateWithSuperScript(eventStartDate));
                        }                    
                        //body = body.replace('{#comm_url#}',commUrl+'?edcode='+conEvntMap.Edition__r.Edition_Code__c);
                        body = body.replaceAll(documentURL, commURL+'/IMCC');
                    }
                }
            }      
        }*/
        EmailContent obj = new EmailContent();
        obj.body = body;
        return obj;
    }
    
    /**@description EmailContent*/
    public class EmailContent{
        /**@description body*/
        public String body{get;set;}
    }
}