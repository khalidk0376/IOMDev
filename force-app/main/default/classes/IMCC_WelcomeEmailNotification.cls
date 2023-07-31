/**
* Created/Modified By :(Arushi [IMCC-5307])
* Created On:          03/07/2023 
* @description  :      As a primary and/or secondary admin, I want to be able to trigger an email to the relevant 
                       invited team members. So that they are aware they have been invited to the platform.
* Methods:             adminNotification,teamMemberNotification
* Test Class:          IMCC_WelcomeEmailNotificationTest
**/
public class IMCC_WelcomeEmailNotification {
    
    public static void adminNotification(Set<Id> teamMemberIds, Contact_Edition_Mapping__c admin, String templateCode){
        Id sConId;
        set<Id> sEventId = new set<Id>();
        List<User> adminUser = new List<User>();
        boolean bypass = true;
        try
        {
            List<Contact_Edition_Mapping__c> lstContactMapping = [SELECT Id, Role__c, Account__c, Account__r.Name, Contact__c
                                                                  ,Edition__c,Edition__r.Name, CC_Status__c,Edition__r.Edition_Code__c
                                                                  ,Edition__r.Edition_Image_URL__c,Relationship_Status__c
                                                                  ,Access_Type__c,Edition__r.Business_Hours__c,Edition__r.Support_Email__c
                                                                  ,Edition__r.Edition_Website__c,Edition__r.Start_Date__c,Edition__r.Venue__c
                                                                  ,Edition__r.Customer_Support_Team__r.Business_Hours__c
                                                                  ,Edition__r.Customer_Support_Team__r.Hotline_Number__c
                                                                  ,Contact__r.Email,Contact__r.Phone,Contact__r.Name
                                                                  FROM Contact_Edition_Mapping__c where Id IN :teamMemberIds WITH SECURITY_ENFORCED];
            
            for(Contact_Edition_Mapping__c cem : lstContactMapping){
                sEventId.add(cem.Edition__c);
            }
            
            if(admin.Contact__c != null){ sConId = admin.Contact__c; }
            
            List<Messaging.SingleEmailMessage> mails =  new List<Messaging.SingleEmailMessage>();
            //Get existing user of contact with community profile
            if(Schema.sObjectType.User.isAccessible() || bypass){
                adminUser = [SELECT Id,Email,username,firstname,ContactId,Contact.account.name,Contact.name,Contact.email,IsActive,IsPortalEnabled FROM User where ContactId =: sConId AND IsPortalEnabled=true AND Profile.Name='IM Customer Community Login User' AND IsActive=true];  
            }
            
            List<Event_Edition_Email_Template__c> listEEET = [SELECT Role__c,Template_Code__c, Edition__c, Subject__c
                                                              , From_Email_Address__c, Content__c FROM Event_Edition_Email_Template__c
                                                              WHERE Template_Code__c =: templateCode AND Edition__c IN:sEventId WITH SECURITY_ENFORCED];
            
            Map<String,Event_Edition_Email_Template__c> mapEEET = new Map<String,Event_Edition_Email_Template__c>();
            Map<String,String> mapOrgEMailAddr = new Map<String,String>();
            
            for(Event_Edition_Email_Template__c eeet : listEEET){                                
                mapEEET.put(eeet.Edition__c,eeet);
                if(String.isNotBlank(eeet.From_Email_Address__c)){mapOrgEMailAddr.put(eeet.From_Email_Address__c,null);}
            }
            if(Schema.sObjectType.OrgWideEmailAddress.isAccessible() || bypass){
                List<OrgWideEmailAddress> listOrgAddresses = [SELECT Id,Address FROM OrgWideEmailAddress WHERE Address IN:mapOrgEMailAddr.keySet()];
                for(OrgWideEmailAddress orgAdd : listOrgAddresses){
                    mapOrgEMailAddr.put(orgAdd.Address, orgAdd.Id);
                }
            }
            
            for(Contact_Edition_Mapping__c cem : lstContactMapping){
                
                if(mapEEET.containsKey(cem.Edition__c)){
                    Event_Edition_Email_Template__c template = mapEEET.get(cem.Edition__c);
                    String htmlValue = template.Content__c;
                    
                    String teamMember = cem.Contact__r.Name;
                    teamMember = teamMember!=null?teamMember:'';
                    String firstName = admin.Contact__r.Name;
                    firstName = firstName!=null?firstName:'';
                    //String userName = mapConUser.get(cem.Contact__c).userName;
                    //userName = userName!=null?userName:'';
                    String eventName = cem.Edition__r.Name!=null?cem.Edition__r.Name:'';
                    String hotlineNumber = cem.Edition__r.Customer_Support_Team__r.Hotline_Number__c!=null?cem.Edition__r.Customer_Support_Team__r.Hotline_Number__c:''; 
                    String supportEmail = cem.Edition__r.Support_Email__c!=null?cem.Edition__r.Support_Email__c:'';
                    
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    
                    htmlValue = htmlValue!=null?htmlValue:'';
                    htmlValue = htmlValue.replace('{EVENT}',eventName);                    
                    htmlValue = htmlValue.replace('{NAME}',firstName);               
                    //htmlValue = htmlValue.replace('{UserName}',userName);
                    htmlValue = htmlValue.replace('{TEAM MEMBER}',teamMember);
                    htmlValue = htmlValue.replace('{SupportEmail}',supportEmail);
                    htmlValue = htmlValue.replace('{HotlineNumber}',hotlineNumber);
                    
                    String emailSubject = template.Subject__c;
                    emailSubject = emailSubject.replace('{EVENT}', eventName);
                    
                    mail.setSubject(emailSubject);
                    mail.setHtmlBody(htmlValue);
                    mail.setSaveAsActivity(false);
                    mail.setTargetObjectId(adminUser[0].Id);
                    if(String.isNotBlank(template.From_Email_Address__c)){
                        Id oweaId = mapOrgEMailAddr.get(template.From_Email_Address__c);
                        if(oweaId !=null){
                            mail.setOrgWideEmailAddressId(oweaId);
                        }
                    }
                    mails.add(mail);
                }
            }
            
            if(!mails.isEmpty()){
                Messaging.sendEmail(mails,true);
            }
        }
        catch(Exception ex) {
            HandleAllCustomException.logException(ex,'Contact_Edition_Mapping__c', 'Exception in adminNotification');
        }     
    }
    
    public static void teamMemberNotification(Set<Id> teamMemberIds, String templateCode,String tabId, string tabName){
        
        set<Id> sConId = new set<Id>(); 
        set<Id> sEventId = new set<Id>();
        Map<Id,User> mapConUser = new Map<Id,User>();
        List<User> lstUsr = new List<User>();
        boolean bypass = true;
        String commURL = System.Label.CommunityURL;
        String documentURL = System.Label.Document_URL;
        
        try
        {
            List<Contact_Edition_Mapping__c> lstContactMapping = [SELECT Id, Role__c, Account__c, Account__r.Name, Contact__c
                                                                  ,Edition__c,Edition__r.Name, CC_Status__c,Edition__r.Edition_Code__c
                                                                  ,Edition__r.Edition_Image_URL__c,Relationship_Status__c
                                                                  ,Access_Type__c,Edition__r.Business_Hours__c,Edition__r.Support_Email__c
                                                                  ,Edition__r.Edition_Website__c,Edition__r.Start_Date__c,Edition__r.Venue__c
                                                                  ,Edition__r.Customer_Support_Team__r.Business_Hours__c
                                                                  ,Edition__r.Customer_Support_Team__r.Hotline_Number__c
                                                                  ,Contact__r.Email,Contact__r.Phone,First_Login_Date_Time__c
                                                                  FROM Contact_Edition_Mapping__c where Id IN :teamMemberIds WITH SECURITY_ENFORCED];
            
            for(Contact_Edition_Mapping__c cem : lstContactMapping){
                sConId.add(cem.Contact__c);
                sEventId.add(cem.Edition__c);
            }
            
           
            List<Messaging.SingleEmailMessage> mails =  new List<Messaging.SingleEmailMessage>();
            //Get existing user of contact with community profile
            if(Schema.sObjectType.User.isAccessible() || bypass){
                lstUsr = [SELECT Id,Email,username,firstname,ContactId,Contact.account.name,Contact.name,Contact.email,IsActive,IsPortalEnabled FROM User where ContactId IN : sConId AND IsPortalEnabled=true AND Profile.Name='IM Customer Community Login User' AND IsActive=true];  
                for(User oUser : lstUsr){
                    mapConUser.put(oUser.ContactId,oUser);
                }
            }
            
            List<Event_Edition_Email_Template__c> listEEET = [SELECT Role__c,Template_Code__c, Edition__c, Subject__c
                                                              , From_Email_Address__c, Content__c FROM Event_Edition_Email_Template__c
                                                              WHERE Template_Code__c =: templateCode AND Edition__c IN:sEventId WITH SECURITY_ENFORCED];
            
            List<Event_Tabs__c> etl = new List<Event_Tabs__c>();
            if(string.isNotBlank(tabId)){
                 etl = [SELECT ExtTabId__c,Tab_Code__c,Tab_Type__c,Standard_Tab_Type__c 
                        FROM Event_Tabs__c WHERE Tab_Code__c =:tabId WITH SECURITY_ENFORCED];
            }
            Map<String,Event_Edition_Email_Template__c> mapEEET = new Map<String,Event_Edition_Email_Template__c>();
            Map<String,String> mapOrgEMailAddr = new Map<String,String>();
            
            for(Event_Edition_Email_Template__c eeet : listEEET){                                
                mapEEET.put(eeet.Edition__c,eeet);
                if(String.isNotBlank(eeet.From_Email_Address__c)){mapOrgEMailAddr.put(eeet.From_Email_Address__c,null);}
            }
            if(Schema.sObjectType.OrgWideEmailAddress.isAccessible() || bypass){
                List<OrgWideEmailAddress> listOrgAddresses = [SELECT Id,Address FROM OrgWideEmailAddress WHERE Address IN:mapOrgEMailAddr.keySet()];
                for(OrgWideEmailAddress orgAdd : listOrgAddresses){
                    mapOrgEMailAddr.put(orgAdd.Address, orgAdd.Id);
                }
            }
            
            for(Contact_Edition_Mapping__c cem : lstContactMapping){
                
                if(mapEEET.containsKey(cem.Edition__c)){
                    Event_Edition_Email_Template__c template = mapEEET.get(cem.Edition__c);
                    String htmlValue = template.Content__c;
                    
                    String firstName = mapConUser.get(cem.Contact__c).firstName;
                    firstName = firstName!=null?firstName:'';
                    //String userName = mapConUser.get(cem.Contact__c).userName;
                    //userName = userName!=null?userName:'';
                    String eventName = cem.Edition__r.Name!=null?cem.Edition__r.Name:'';
                    String hotlineNumber = cem.Edition__r.Customer_Support_Team__r.Hotline_Number__c!=null?cem.Edition__r.Customer_Support_Team__r.Hotline_Number__c:''; 
                    String supportEmail = cem.Edition__r.Support_Email__c!=null?cem.Edition__r.Support_Email__c:'';
                   
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    
                    htmlValue = htmlValue!=null?htmlValue:'';
                    htmlValue = htmlValue.replace('{EVENT}',eventName);                    
                    htmlValue = htmlValue.replace('{NAME}',firstName);               
                    htmlValue = htmlValue.replace('{SupportEmail}',supportEmail);
                    htmlValue = htmlValue.replace('{HotlineNumber}',hotlineNumber);
                    if(!etl.isEmpty()){
                        htmlValue = htmlValue.replace('{Task Link}','<a href="' + commURL+ tabName +'?accId='+cem.Account__c +'&edcode='+cem.Edition__r.Edition_Code__c+'&tabId='+etl[0].Tab_Code__c+'">here</a>');
                    }
                    system.debug('htmlValue==='+htmlValue);
                    String emailSubject = template.Subject__c;
                    emailSubject = emailSubject.replace('{EVENT}', eventName);
                    
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
                }
                else{
                     String errorMsg = (!mapConUser.containsKey(cem.Contact__c)?System.Label.IMCC_Welcome_Email_Error_Msg3:System.Label.IMCC_Welcome_Email_Error_Msg4); // Using labels for displaying/populating(error message field on CEM) the error message on screen duirng sending welcome email
                }
            }
            
            if(!mails.isEmpty()){
                Messaging.sendEmail(mails,true);
            }
        }
        catch(Exception ex) {
            HandleAllCustomException.logException(ex,'Contact_Edition_Mapping__c', 'Exception in teamMemberNotification');
        }     
    }
    
}