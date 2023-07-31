/**
 * @description to approve stand contarctor
* Created By    : Aishwarya[IMCC-90]
* Test Class    : IMCC_StandContractorCtrl_Test()
* Created/Modified By   :  01/02/2022
*/
public without sharing class IMCC_ApproveContractorCtrl{
    /**
    * @description  to approve Stand Contractor
    * @param  sboothConMapId
    * @return  String
    */
    public static string approveStandContractor(Set<Id> sboothConMapId){        
        Savepoint sp = Database.setSavepoint();
        List<Contact> createCon = new List<Contact>();
        List<Account> createAcc = new List<Account>();
        string sEventId = null;
        List<String> boothIDs = new List<String>();
        Map<Id,Id> cemMap = new Map<Id,Id>();
        Map<String,String> accMap = new Map<String,String>();
        Map<String,String> conMap = new Map<String,String>();
        List<Contractor_Mapping__c> updateBoothmap = new List<Contractor_Mapping__c>();
        List<Contact_Edition_Mapping__c> insertCEM = new List<Contact_Edition_Mapping__c>();
        Set<String> setDuplicateAccount = new Set<String>();
        Set<String> setDuplicateContact = new Set<String>();
        List<Contractor_Mapping__c> lstBoothConMap = new List<Contractor_Mapping__c>();
        
        if(Contractor_Mapping__c.SObjectType.getDescribe().isAccessible()){
            lstBoothConMap = [SELECT id, Contact__c,Account__r.Name,TempContact__r.TempAccount__c,TempContact__r.TempAccount__r.Address__c,TempContact__r.TempAccount__r.Zip__c,Edition__c,Edition__r.Name,TempContact__r.TempAccount__r.State__c,TempContact__r.TempAccount__r.Country__c,TempContact__r.TempAccount__r.City__c,TempContact__r.TempAccount__r.Name,TempContact__r.Phone__c,TempContact__r.MobilePhone__c, TempContact__r.Email__c, TempContact__r.Account__c,TempContact__c,TempContact__r.FirstName__c,TempContact__r.LastName__c FROM Contractor_Mapping__c WHERE TempContact__c IN:sboothConMapId AND Approved__c=false];
        }
        
        Set<Id> conMappingIds = new Set<Id>();
        for(Contractor_Mapping__c oBooth: lstBoothConMap){
            if(oBooth.Edition__c != null){
                sEventId = oBooth.Edition__c;
            } 

            if(oBooth.TempContact__r.TempAccount__c != null && oBooth.TempContact__r.Account__c == null){                   
                Account oAcc = new Account();
                oAcc.Name = oBooth.TempContact__r.TempAccount__r.Name;
                oAcc.BillingStreet = oBooth.TempContact__r.TempAccount__r.Address__c; 
                oAcc.BillingCity = oBooth.TempContact__r.TempAccount__r.City__c;
                oAcc.BillingCountry = oBooth.TempContact__r.TempAccount__r.Country__c;
                oAcc.BillingState = oBooth.TempContact__r.TempAccount__r.State__c;
                oAcc.BillingPostalCode = oBooth.TempContact__r.TempAccount__r.Zip__c;
                oAcc.TempAccountId__c = oBooth.TempContact__r.TempAccount__c;
                oAcc.Type='Stand Contractor';
                if(!setDuplicateAccount.contains(oBooth.TempContact__r.TempAccount__r.Name)){
                    setDuplicateAccount.add(oBooth.TempContact__r.TempAccount__r.Name);
                    createAcc.add(oAcc);
                }
            }
            conMappingIds.add(oBooth.Id);
        }

        List<Purchase_Data__c> listPD = [SELECT Id FROM Purchase_Data__c WHERE Contractor_Mapping__c IN:conMappingIds  WITH SECURITY_ENFORCED];
        for(Purchase_Data__c pd : listPD){
            boothIDs.add(pd.Id);
        }

        if(createAcc != null && createAcc.size()>0){
            try{
                insert createAcc;
                for(Account acc : createAcc){
                    accMap.put(acc.TempAccountId__c,acc.Id);
                }
            } 
            catch(DmlException e){
                //return('This Account already exist in the system so can not be approved.');
                Database.rollback(sp);
                System.debug(LoggingLevel.debug, 'DmlException----'+e.getMessage()+', This Contact already exist in the system so can not be approved.');
            }     
        }      
        for(Contractor_Mapping__c oBooth: lstBoothConMap){  
            if(oBooth.TempContact__c != null ){   
                Contact oObjCon=new Contact();
                oObjCon.FirstName = oBooth.TempContact__r.FirstName__c;
                oObjCon.LastName = oBooth.TempContact__r.LastName__c; 
                oObjCon.Email = oBooth.TempContact__r.Email__c;
                oObjCon.MobilePhone = oBooth.TempContact__r.MobilePhone__c;
                oObjCon.TempContactId__c = oBooth.TempContact__c;
                if(oBooth.TempContact__r.Phone__c!=null){
                    oObjCon.Phone = oBooth.TempContact__r.Phone__c;  
                }
                if(accMap.ContainsKey(oBooth.TempContact__r.TempAccount__c)){
                    oObjCon.AccountId = accMap.get(oBooth.TempContact__r.TempAccount__c);
                }
                else{
                    oObjCon.AccountId = oBooth.TempContact__r.Account__c;
                }
                if(!setDuplicateContact.contains(oObjCon.AccountId)){
                    setDuplicateContact.add(oObjCon.AccountId);
                    createCon.add(oObjCon);
                }
            }      
        }            
        if(createCon != null && createCon.size()>0){
            try{
                insert createCon;  
                for(Contact con : createCon){
                    conMap.put(con.TempContactId__c,con.Id);
                }
                //create a ContactEditionMapping record for newly approved Contact with User type 'Stand Contractor'
                for(Contact c : createCon){
                    Contact_Edition_Mapping__c oObjConEvntEdtionMap= new Contact_Edition_Mapping__c();
                    oObjConEvntEdtionMap.Access_Type__c = 'Contractor';
                    oObjConEvntEdtionMap.Contact__c = c.Id;
                    oObjConEvntEdtionMap.Edition__c = sEventId;
                    oObjConEvntEdtionMap.Account__c = c.AccountId;
                    oObjConEvntEdtionMap.Relationship_Status__c ='Active';
                    insertCEM.add(oObjConEvntEdtionMap);
                }
                if(!insertCEM.isEmpty())insert insertCEM;
                for(Contact_Edition_Mapping__c cEM : insertCEM){
                    cemMap.put(cEM.Contact__c,cEM.Id);
                }
            } 
            catch(DmlException e){
                //return('This Contact already exist in the system so can not be approved.');
                System.debug(LoggingLevel.debug, 'DmlException----'+e.getMessage()+', This Contact already exist in the system so can not be approved.');
                Database.rollback(sp);
                return(e.getMessage());
            }
        }
        
        for(Contractor_Mapping__c updateBooth: lstBoothConMap){
            if(updateBooth.TempContact__c != null){
                updateBooth.Contact__c = conMap.get(updateBooth.TempContact__c);
                updateBooth.Account__c = updateBooth.TempContact__r.TempAccount__c != null?accMap.get(updateBooth.TempContact__r.TempAccount__c):updateBooth.TempContact__r.Account__c;
            }
            updateBooth.Approved__c = true;
            updateBooth.Contractor_Status__c = 'Contractor Nominated';
            updateBooth.Approval_Date__c = System.now();
            if(!insertCEM.isEmpty()){
                updateBooth.Contractor_CEM__c = cemMap.get(conMap.get(updateBooth.TempContact__c));
            }
            updateBoothmap.add(updateBooth);     
        }
        if(!updateBoothmap.isEmpty()){
            update updateBoothmap;
            sendEmail(updateBoothmap,boothIDs,sEventId);
        }
        return ('Successfully  Approved!');
    }
    
    /**
    * @description  to sendEmail
    * @param  contractorMap
    * @param  boothIDs
    * @param  eventId
    */
    public static void sendEmail(List<Contractor_Mapping__c> contractorMap,List<string> boothIDs,String eventId){
        List<Contractor_Mapping__c> cmpList = [SELECT Id,Contact__c, Account__r.Name,Edition__r.Customer_Support_Team__r.Hotline_Number__c,Edition__r.Name FROM Contractor_Mapping__c WHERE Id IN: contractorMap WITH SECURITY_ENFORCED];
        String boothNumbers ='';
        List<Purchase_Data__c> listPurchaseData = new List<Purchase_Data__c>([SELECT Id,Contractor_Mapping__c, Booth_Number__c,Contact_Edition_Mapping__r.Account__c,Contact_Edition_Mapping__r.Account__r.Name FROM Purchase_Data__c WHERE Id IN:boothIDs WITH SECURITY_ENFORCED]);
        Map<Id,Purchase_Data__c> mapPD = new Map<Id,Purchase_Data__c>();
        if(!listPurchaseData.isEmpty() && listPurchaseData.size()>0){
            for(Purchase_Data__c pd :listPurchaseData){
                //BoothNumbers += pd.Booth_Number__c +','+' ';
                boothNumbers+=(boothNumbers==''?pd.Booth_Number__c:', '+pd.Booth_Number__c);
                mapPD.put(pd.Contractor_Mapping__c, pd);
            }
        }
        Map<ID,String> mapGetUserName = new Map<ID,String>();
        List<User> listuser = new List<User>();
        if(User.SObjectType.getDescribe().isAccessible()){
            listuser = [Select userName, ContactId FROM User WHERE ContactId != null AND IsPortalEnabled=true AND Profile.Name='IM Customer Community Login User' AND IsActive=true ];
        }
        if(!listuser.isEmpty() && listuser.size()>0){
            for(User u : listuser){
                mapGetUserName.put(u.ContactId,u.userName);
            }
        }
        List<EmailTemplate> emailTemplate = [Select Id,Subject,Description,HtmlValue,DeveloperName,Body from EmailTemplate where DeveloperName = 'IMCC_Onboarding_Stand_Contractor'];
        String body = emailTemplate[0].HtmlValue;
        String subject = emailTemplate[0].Subject;
        List<FromEmailAddressESMapping__c> listFromAddress = new List<FromEmailAddressESMapping__c>();
        OrgWideEmailAddress[] owea;
        listFromAddress =[Select Org_Wide_From_Email_Addresses__c FROM FromEmailAddressESMapping__c WHERE Modules__c ='Stand Design' AND Edition__c =:eventId WITH SECURITY_ENFORCED LIMIT 1];
        if(!listFromAddress.isEmpty() && listFromAddress.size()>0 && listFromAddress[0].Org_Wide_From_Email_Addresses__c !=null){
            owea = [select Id from OrgWideEmailAddress where Address =:listFromAddress[0].Org_Wide_From_Email_Addresses__c LIMIT 1];
        }
        
        for(Contractor_Mapping__c cmp :cmpList)
        { 
            if(!String.isBlank(body))
            {
                if(cmp.Account__r.Name != null){
                    if(body.contains('{Account.Name}')){
                        body = body.replace('{Account.Name}',cmp.Account__r.Name);
                    }
                }
                if(mapPD.ContainsKey(cmp.Id)){
                    if(body.contains('{Designating-Exhibitor.Account.Name}')){
                        body = body.replace('{Designating-Exhibitor.Account.Name}',mapPD.get(cmp.Id).Contact_Edition_Mapping__r.Account__r.Name);
                    }
                }
                if(body.contains('{Purchase_Data__c.Booth_Number__c}')){
                    body = body.replace('{Purchase_Data__c.Booth_Number__c}',BoothNumbers);
                }
                if(cmp.Edition__r.Name != null){
                    if(body.contains('{Event_Edition__c.Name}')){
                        body = body.replace('{Event_Edition__c.Name}',cmp.Edition__r.Name);
                    }
                }
                if(IMCC_UtilityMethods.getCommunityURL()!=null){
                    if(body.contains('{Community_URL}')){
                        body = body.replace('{Community_URL}',IMCC_UtilityMethods.getCommunityURL());
                    }
                }
                if(!mapGetUserName.isEmpty() && mapGetUserName.size()>0 && mapGetUserName.containsKey(cmp.Contact__c)){
                    if(body.contains('{UserName}')){
                        body = body.replace('{UserName}',mapGetUserName.get(cmp.Contact__c));
                    }
                }
                if(cmp.Edition__r.Customer_Support_Team__r.Hotline_Number__c != null){
                    if(body.contains('{OfficePhone}')){
                        body = body.replace('{OfficePhone}',cmp.Edition__r.Customer_Support_Team__r.Hotline_Number__c);
                    }
                }
            }
            if(!String.isBlank(subject)){
                if(cmp.Edition__r.Name != null){
                    if(subject.contains('{Event_Edition__c.Name}')){
                        subject = subject.replace('{Event_Edition__c.Name}',cmp.Edition__r.Name);
                    }
                }
                if(mapPD.containsKey(cmp.Id)){
                    if(subject.contains('{Designating-Exhibitor.Account.Name}')){
                        subject = subject.replace('{Designating-Exhibitor.Account.Name}',mapPD.get(cmp.Id).Contact_Edition_Mapping__r.Account__r.Name);
                    }
                }
                if(subject.contains('{Purchase_Data__c.Booth_Number__c}')){
                    subject = subject.replace('{Purchase_Data__c.Booth_Number__c}',BoothNumbers);
                }
            }
            
            // Define the email
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            if(owea !=null && !owea.isEmpty() && owea.size()>0){
                email.setOrgWideEmailAddressId(owea.get(0).Id);
            }
            email.setHtmlBody(body); 
            email.setSubject(subject); 
            email.setSaveAsActivity(false);
            email.setTargetObjectId(cmp.Contact__c);
            // Sends the email
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email}, false );
            break;
        } 
    }
    
    /**
    * @description  to rejectContarctor
    * @param  sIds
    * @return  String
    */
    public static String rejectContarctor(Set<Id> sIds){
        String msg = 'Contractor Rejected successfully!';
        if(sIds != null ){
            List<Contractor_Mapping__c> lstTempCon = [select id, Rejection_Reason__c,TempContact__r.Rejection_Reason__c, Contractor_Status__c FROM Contractor_Mapping__c where TempContact__c IN:sIds WITH SECURITY_ENFORCED];           
            if(lstTempCon != null && lstTempCon.size()>0){
                for(Contractor_Mapping__c oBooth: lstTempCon){
                    oBooth.Contractor_Status__c = 'New Contractor Nomination Rejected';
                    oBooth.Rejection_Reason__c = oBooth.TempContact__r.Rejection_Reason__c;  
                }
                Update lstTempCon;
            }   
        }
        return msg;
    }
}