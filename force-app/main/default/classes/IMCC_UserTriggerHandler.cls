/**
* Created By     :  Girikon(Arushi[IMCC-763])
* Created On     :  28/03/2022
* @description   :  On a new customer username creation in Salesforce, currently there are extra characters created along with the email in the username. This will need to be removed for the ease of use from customer's side. 
* Apex Test Class: IMCC_UserTriggerHandler_Test(100%)
**/
public class IMCC_UserTriggerHandler{
    /**
* @description : insert Update Community User Trigger
* @param newUserList
* @param isUpdate
**/
    public static void insertUpdateCommunityUserDetails(List<User> newUserList, Boolean isUpdate){
        Set<Id> contactIds = new Set<Id>();
        Set<Id> userIds = new Set<Id>();
        Set<String> firstNames = new Set<String>();
        Set<String> lastNames = new Set<String>();
        for(User u : newUserList){
            if(u.contactId != null && (!isUpdate || u.IsPortalEnabled)){
                u.Username = u.Email;
                if(String.isBlank(u.FederationIdentifier)){
                    u.FederationIdentifier = u.Email;
                }
                contactIds.add(u.contactId);
                if(isUpdate){
                    userIds.add(u.Id);
                }
            }
        }
        Map<Id,Contact> mapContact = new Map<Id,Contact>([SELECT Id,FirstName,LastName,AccountId,Account.Name FROM Contact WHERE Id IN:contactIds]);
        Map<Id,String> mapInitials = new Map<Id,String>();
        Map<Id,String> mapFirstNameInitials = new Map<Id,String>();
        for(Contact con : mapContact.values()){
            if(!mapInitials.containsKey(con.AccountId)){
                mapInitials.put(con.AccountId, getInitials(con.Account.Name));
            }
            if(!mapFirstNameInitials.containsKey(con.Id) && String.isNotBlank(con.FirstName)){
                mapFirstNameInitials.put(con.Id, getNameInitials(con.FirstName));
            }
        }
        Map<Id,User> mapUser = new Map<Id,User>([SELECT Id,CommunityNickname FROM User WHERE Id IN:userIds WITH SECURITY_ENFORCED]);
        for(User u : newUserList){
            if(u.contactId != null && !isUpdate){
                Contact con = mapContact.get(u.contactId);
                if(String.isNotBlank(con.FirstName)){
                    firstNames.add(con.FirstName);
                }
                lastNames.add(con.LastName);
            }
            if(u.contactId != null && isUpdate){
                User oldUser = mapUser.get(u.Id);
                u.CommunityNickname = oldUser.CommunityNickname;
            }
        }
        Set<String> existingNickNames = new Set<String>();
        Map<String,Integer> existingNickNamesCount = new Map<String,Integer>();
        List<User> listUser = [SELECT Id,CommunityNickname FROM User WHERE (FirstName IN:firstNames OR LastName IN:lastNames) WITH SECURITY_ENFORCED];
        for(User u : listUser){
            existingNickNames.add(u.CommunityNickname);
            String nickName = u.CommunityNickname;
            String lastPart = nickName.substring(nickName.lastIndexOf(' ')+1,nickName.length());
            Integer cnt = 1;
            if(lastPart.isNumeric()){
                cnt = Integer.valueOf(lastPart);
                nickName = nickName.replace(' '+lastPart,'');
            }
            Integer currentCount = (existingNickNamesCount.containsKey(nickName)?existingNickNamesCount.get(nickName):(1));
            if(cnt > currentCount){
                currentCount = cnt;
            }
            existingNickNamesCount.put(nickName, currentCount);
        }       
        
        for(User u : newUserList){
            if(u.contactId != null && !isUpdate){
                Contact con = mapContact.get(u.contactId);
                String nickName = (String.isBlank(con.FirstName)?'':(con.FirstName + ' ')) + (con.LastName + ' ') + con.Account.Name.replace('&', '').normalizeSpace();
                
                if(nickName.length() > 40){
                    nickName = (String.isBlank(con.FirstName)?'':(con.FirstName + ' ')) + (con.LastName + ' ') + mapInitials.get(con.AccountId);
                }
                
                if(nickName.length() > 40){nickName = (String.isBlank(con.FirstName)?'':(mapFirstNameInitials.get(con.Id) + ' ')) + (con.LastName + ' ') + mapInitials.get(con.AccountId);}
                
                nickName = nickName.left(40);
                Integer currentCount = (existingNickNamesCount.containsKey(nickName)?existingNickNamesCount.get(nickName):(1));
                String tempNickName = nickName;
                
                while(existingNickNames.contains(nickName)){
                    currentCount++;
                    nickName = tempNickName + ' ' + currentCount;
                    while(nickName.length() > 40) {
                        tempNickName = tempNickName.substring(0, tempNickName.length()-1);
                        currentCount = (existingNickNamesCount.containsKey(tempNickName)?existingNickNamesCount.get(tempNickName):(1));
                        currentCount++;
                        nickName = tempNickName + ' ' + currentCount;
                    }
                }
                u.CommunityNickname = nickName;
                existingNickNames.add(nickName);
                existingNickNamesCount.put(tempNickName, currentCount);
            }
        }
    }
    
    /**
* @description : get Initials
* @param str
* @return String
**/
    public static String getInitials(String str){
        String regex = '[^A-Za-z0-9_]';
        str = str.toLowerCase().replaceAll('\\s+','_').replaceAll(regex,'').trim().replaceAll('_',' ').normalizeSpace();
        List<String> splitStrs = str.split(' ');
        String initial = '';
        if(splitStrs.size() == 1) {
            initial = splitStrs.get(0).left(3);
        }
        if(splitStrs.size() == 2) {
            initial = splitStrs.get(0).left(1)+splitStrs.get(1).left(2);
        }
        if(splitStrs.size() > 2){
            for(String s : splitStrs){
                initial += s.left(1);
            }
        }
        return initial.toUpperCase();
    }
    
    /**
* @description : get Name Initials
* @param str
* @return String
**/
    public static String getNameInitials(String str){
        str = str.replace('&', '').normalizeSpace();
        List<String> splitStrs = str.split(' ');
        String initial = '';
        for(String s : splitStrs){
            initial += s.left(1);
        }
        return initial.toUpperCase();
    }
    
    public static void sendEmailToActiveUser(Map<Id,User> newUserMap, Map<Id,User> oldUserMap){
        
        Map<Id,User> mapConUser = new Map<Id,User>();
        List<User> lstUsr = new List<User>();
        
        try{
            for(User oUser : newUserMap.values()){
                if(oUser.Email != null && oUser.Email != oldUserMap.get(oUser.Id).Email){
                    lstUsr.add(oUser);
                    mapConUser.put(oUser.Id,oUser);
                }
            }
            
            List<Email_Templates__c> listET = [SELECT Content__c, Subject__c,Template_Code__c,Name FROM Email_Templates__c WHERE Template_Code__c =:'UEMAILUPD' WITH SECURITY_ENFORCED];
            List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
            
            if(!listET.isEmpty() && mapConUser.size() > 0){
                for(User oUser : newUserMap.values()){
                    String htmlValue = listET[0].Content__c;
                    
                    String firstName = oUser.firstName!=null?oUser.firstName:'';
                    String userEmail = oUser.Email!=null?oUser.Email:'';
                    
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    
                    htmlValue = htmlValue!=null?htmlValue:'';
                    htmlValue = htmlValue.replace('{FirstName}',firstName); 
                    htmlValue = htmlValue.replace('{UserEmail}',userEmail); 
                    
                    String emailSubject = listET[0].Subject__c;
                    
                    List<string> toAddress = new List<string>();
                    toAddress.add(oUser.Email);
                    
                    mail.setToAddresses(toAddress);
                    mail.setSubject(emailSubject);
                    mail.setHtmlBody(htmlValue);
                    mail.setSaveAsActivity(false);
                    
                    system.debug('mail'+ mail);
                    mails.add(mail);
                }
            }
            
            if(!mails.isEmpty()){
                Messaging.sendEmail(mails,true);
            }
            system.enqueueJob(new IMCC_UserRevokeAccess(lstUsr));
        }
        catch(Exception ex) {
            system.debug('ex=='+ex.getCause());
            system.debug('ex1=='+ex.getLineNumber());
            system.debug('ex2=='+ex.getMessage());
            //throw new AuraHandledException(ex.getMessage());
        }  
    } 
    
}