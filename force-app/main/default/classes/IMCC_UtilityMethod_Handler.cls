/**
* Created By    :  Girikon(Keertiraj)
* Created on    : 05/10/2021
* @description  : The purpose of this class is to keep common reusable functionalities at single place.
* Test Class    : IMCC_EditionWelcomeEmailTest (93%)
*/
public without sharing class IMCC_UtilityMethod_Handler {
    
    /**
    * @description  send Welcome Email To Existing User
    * @param  sConEEMIds
    */
    public static void sendEmailToExistingUser(Set<Id> sConEEMIds){
        set<Id> sConId = new set<Id>();
        set<Id> sEventId = new set<Id>();
        Set<String> roleSet = new Set<String>();
        Map<Id,User> mapConUser = new Map<Id,User>();
        List<User> lstUsr = new List<User>();
        String commURL = System.Label.CommunityURL;
        String documentURL = System.Label.Document_URL;
        boolean bypass = true;
        List<Contact_Edition_Mapping__c> listCEMUpdate = new List<Contact_Edition_Mapping__c>();
        try
        {
            List<Contact_Edition_Mapping__c> lstContactMappingToUpdate = new List<Contact_Edition_Mapping__c>();
            List<Contact_Edition_Mapping__c> lstContactMappingEmailProcessed = new List<Contact_Edition_Mapping__c>();     
            List<Contact_Edition_Mapping__c> lstContactMapping = [SELECT Id, Role__c, Account__c, Account__r.Name, Contact__c
                                                                  ,Edition__c,Edition__r.Name, CC_Status__c,Edition__r.Edition_Code__c
                                                                  ,Edition__r.Edition_Image_URL__c,Relationship_Status__c
                                                                  ,Access_Type__c,Edition__r.Business_Hours__c,Edition__r.Support_Email__c
                                                                  ,Edition__r.Edition_Website__c,Edition__r.Start_Date__c,Edition__r.Venue__c
                                                                  ,Edition__r.Customer_Support_Team__r.Business_Hours__c
                                                                  ,Edition__r.Customer_Support_Team__r.Hotline_Number__c
                                                                  ,Contact__r.Email,Contact__r.Phone
                                                                  FROM Contact_Edition_Mapping__c where Id IN :sConEEMIds WITH SECURITY_ENFORCED];
            
            for(Contact_Edition_Mapping__c cem : lstContactMapping){
                sConId.add(cem.Contact__c);
                sEventId.add(cem.Edition__c);
                roleSet.add(cem.Role__c);                
            }
            
            List<Messaging.SingleEmailMessage> mails =  new List<Messaging.SingleEmailMessage>();
            //Get existing user of contact with community profile
            if(Schema.sObjectType.User.isAccessible() || bypass){
                lstUsr = [SELECT Id,Email,username,firstname,ContactId,Contact.account.name,Contact.name,Contact.email,IsActive,IsPortalEnabled FROM User where ContactId IN : sConId AND IsPortalEnabled=true AND Profile.Name='IM Customer Community Login User' AND IsActive=true];  
                for(User oUser : lstUsr){
                    mapConUser.put(oUser.ContactId,oUser);
                }
            }

            List<Event_Edition_Email_Template__c> listEEET = [SELECT Role__c,Template_Code__c, Edition__c, Subject__c, From_Email_Address__c, Content__c FROM Event_Edition_Email_Template__c WHERE Template_Code__c Like:'WELNew%' AND Role__c IN:roleSet AND Edition__c IN:sEventId WITH SECURITY_ENFORCED];

            Map<String,Event_Edition_Email_Template__c> mapEEET = new Map<String,Event_Edition_Email_Template__c>();
            Map<String,String> mapOrgEMailAddr = new Map<String,String>();
            Map<String,Event_Edition_Email_Template__c> roleTempMap = new Map<String,Event_Edition_Email_Template__c>();
            for(Event_Edition_Email_Template__c eeet : listEEET){                                
                mapEEET.put(eeet.Edition__c,eeet);
                roleTempMap.put(eeet.Role__c,eeet);
                if(String.isNotBlank(eeet.From_Email_Address__c)){mapOrgEMailAddr.put(eeet.From_Email_Address__c,null);}
            }
            if(Schema.sObjectType.OrgWideEmailAddress.isAccessible() || bypass){
                List<OrgWideEmailAddress> listOrgAddresses = [SELECT Id,Address FROM OrgWideEmailAddress WHERE Address IN:mapOrgEMailAddr.keySet()];
                for(OrgWideEmailAddress orgAdd : listOrgAddresses){
                    mapOrgEMailAddr.put(orgAdd.Address, orgAdd.Id);
                }
            }
            
            for(Contact_Edition_Mapping__c cem : lstContactMapping){
                System.debug(cem.Role__c+' :: '+cem.Edition__c);
                if(mapEEET.containsKey(cem.Edition__c)){                    
                    System.debug(mapEEET.get(cem.Edition__c).Role__c+'=='+cem.Role__c);
                }

                if(mapEEET.containsKey(cem.Edition__c) && mapConUser.containsKey(cem.Contact__c) && roleTempMap.containsKey(cem.Role__c)){
                    Event_Edition_Email_Template__c template = roleTempMap.get(cem.Role__c); //mapEEET.get(cem.Edition__c);
                    String htmlValue = template.Content__c;
                    
                    String companyName = cem.Account__r.Name!=null?cem.Account__r.Name:'';                
                    String firstName = mapConUser.get(cem.Contact__c).firstname;
                    firstName = firstName!=null?firstName:'';
                    String userName = mapConUser.get(cem.Contact__c).userName;
                    userName = userName!=null?userName:'';
                    String eventName = cem.Edition__r.Name!=null?cem.Edition__r.Name:'';
                    String businessHours = cem.Edition__r.Business_Hours__c!=null?cem.Edition__r.Business_Hours__c:''; 
                    String cSTeamBusinessHours = cem.Edition__r.Customer_Support_Team__r.Business_Hours__c!=null?cem.Edition__r.Customer_Support_Team__r.Business_Hours__c:''; 
                    String hotlineNumber = cem.Edition__r.Customer_Support_Team__r.Hotline_Number__c!=null?cem.Edition__r.Customer_Support_Team__r.Hotline_Number__c:''; 
                    String eventVenue = cem.Edition__r.Venue__c!=null?cem.Edition__r.Venue__c:''; 
                    String eventWebsite = cem.Edition__r.Edition_Website__c!=null?cem.Edition__r.Edition_Website__c:''; 
                    Datetime eventStartDate = cem.Edition__r.Start_Date__c!=null?cem.Edition__r.Start_Date__c:null;             
                    String supportEmail = cem.Edition__r.Support_Email__c!=null?cem.Edition__r.Support_Email__c:'';
                    String Email = cem.Contact__r.Email!=null?cem.Contact__r.Email:'';
                    String Phone = cem.Contact__r.Phone!=null?cem.Contact__r.Phone:'';
                    
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    
                    htmlValue = htmlValue!=null?htmlValue:'';
                    htmlValue = htmlValue.replace('{Event Name}',eventName);                    
                    htmlValue = htmlValue.replace('{COMPANY NAME}',companyName);     
                    htmlValue = htmlValue.replace('{Firstname}',firstName);               
                    htmlValue = htmlValue.replace('{UserName}',userName);
                    
                    htmlValue = htmlValue.replace('{Venue}',eventVenue);
                    htmlValue = htmlValue.replace('{Website}',eventWebsite);
                    htmlValue = htmlValue.replace('{SupportEmail}',supportEmail);
                    htmlValue = htmlValue.replace('{HotlineNumber}',hotlineNumber);
                    if(cem.Edition__r.Business_Hours__c !=null){
                        htmlValue = htmlValue.replace('{BusinessHours}',businessHours);
                    }
                    else{
                        htmlValue = htmlValue.replace('{BusinessHours}',cSTeamBusinessHours);
                    }
                    if(eventStartDate !=null){
                        htmlValue = htmlValue.replace('{StartDate}',getFormattedDateWithSuperScript(eventStartDate));
                    }                    
                    //htmlValue = htmlValue.replace('{#comm_url#}',commUrl+'?edcode='+cem.Edition__r.Edition_Code__c);   
                    htmlValue = htmlValue.replaceAll(documentURL, commURL+'/IMCC');                 
                    htmlValue = htmlValue.replace('{EMAIL}',Email);
                    htmlValue = htmlValue.replace('{NUMBER}',Phone);
                    
                    String emailSubject = template.Subject__c;
                    emailSubject = emailSubject.replace('{Event Name}', eventName);
                    emailSubject = emailSubject.replace('{COMPANY NAME}', companyName);

                    mail.setSubject(emailSubject);
                    mail.setHtmlBody(htmlValue);
                    mail.setSaveAsActivity(false);
                    mail.setTargetObjectId(mapConUser.get(cem.Contact__c).Id);
                    if(String.isNotBlank(template.From_Email_Address__c)){
                        Id oweaId = mapOrgEMailAddr.get(template.From_Email_Address__c);
                        if(oweaId !=null){
                            mail.setOrgWideEmailAddressId(oweaId);
                        }
                    }
                    mails.add(mail);
                    lstContactMappingEmailProcessed.add(cem);
                }
                else{
                    String errorMsg = (!mapConUser.containsKey(cem.Contact__c)?System.Label.IMCC_Welcome_Email_Error_Msg3:System.Label.IMCC_Welcome_Email_Error_Msg4); // Using labels for displaying/populating(error message field on CEM) the error message on screen duirng sending welcome email
                    listCEMUpdate.add(new Contact_Edition_Mapping__c(Id=cem.Id,Error_Message__c=errorMsg)); // Populating Error MEssage field on CEM if there is nay error during sending of welcome email
                }
            }
            
            if(!mails.isEmpty()){
                Messaging.sendEmail(mails,true);
                
                for(Contact_Edition_Mapping__c conEvntMap : lstContactMappingEmailProcessed){
                    conEvntMap.IsEmailSent__c = true;
                    conEvntMap.Email_Sent__c = System.now();
                    conEvntMap.Error_Message__c = null;
                    lstContactMappingToUpdate.add(conEvntMap);
                }
                
                if(!lstContactMappingToUpdate.isEmpty() && (Schema.sObjectType.Contact_Edition_Mapping__c.isUpdateable() || bypass)){
                    Update lstContactMappingToUpdate;  
                }
            }

            if(!listCEMUpdate.isEmpty() && (Schema.sObjectType.Contact_Edition_Mapping__c.isUpdateable() || bypass)){
                Update listCEMUpdate;  
            }
        }
        catch(Exception ex) {
            HandleAllCustomException.logException(ex,'Contact_Edition_Mapping__c', 'Exception in sendEmailToUser');
        }     
    }

    /**
    * @description  to format datetime with superscript in day
    * @param  dateTimeVal
    * @return  String
    */
    public static String getFormattedDateWithSuperScript(DateTime dateTimeVal) {
        Integer day = dateTimeVal.Day();
        String superScript = 'th';
        Integer modResult = Math.mod(day, 10);        
        if(modResult == 1 && day != 11) { 
            superScript = 'st'; 
        }else if (modResult == 2 && day != 12) { 
            superScript = 'nd'; 
        } else if (modResult == 3 && day != 13) { 
            superScript = 'rd'; 
        }
        String formattedDateTime = String.ValueOf(dateTimeVal.formatGMT('d MMMMM yyyy'));
        formattedDateTime = formattedDateTime.replaceFirst(' ','<sup>'+superScript+'</sup> ');
        return formattedDateTime;
    }
}