/**
* Created By       :   Girikon(Mukesh)
* Created On:          21/01/2022
* Modified By      :   Girikon(Mukesh)
* Modified On      :   21/01/2022
* @description     :   This class use from imccStandContractor. This class use to add "TempContact and TempAccount" records and select "Contact and Account" based on type
* Modified By      :   Arushi(Mukesh)
* Modified On      :   01/02/2022
* @description     :   As an exhibitor, I should be able to nominate a contractor per booth from a list of existing approved contractors so my stand design submission process
                       is approved and completed by the contractor company.
* Apex Class       :   IMCC_StandContractorCtrl 
* Apex Test Class  :   IMCC_StandContractorCtrl_Test (91%)
**/
public without sharing class IMCC_StandContractorCtrl {
    
    @AuraEnabled(cacheable=true)
    public static String getCountries(){        
        return JSON.serialize([SELECT Country_Name__c,Controlling_Field_Code__c FROM Dependent_Picklist_Setting__mdt WITH SECURITY_ENFORCED ORDER BY Country_Name__c ASC]);
    }
    
    @AuraEnabled
    public static list<account> getAccountContacts(String searchText)
    {
        List<Account> accList = new List<Account>();
        //String strQuery = 'SELECT Id,Name,BillingCountry,(Select Id,Name,Contact_Type__c,FirstName,LastName,Email,MobilePhone,Phone,MailingCountryCode FROM Contacts) FROM Account WHERE type=\'Stand Contractor\' ';
        String strQuery = 'SELECT Id,Name,BillingCountry,(Select ContactId, Contact.Name,Contact.Contact_Type__c,Contact.FirstName,Contact.LastName,Contact.Email,Contact.MobilePhone,Contact.Phone,Contact.MailingCountryCode FROM AccountContactRelations) FROM Account WHERE type=\'Stand Contractor\' ';
        if(String.isNotEmpty(searchText)) 
        {
            string whereClause = '%' + String.escapeSingleQuotes(searchText) + '%';
            strQuery+=' AND Name like :whereClause ';
        }
        strQuery+=' WITH SECURITY_ENFORCED limit 100';
        
        return Database.query(strQuery);        
    }
    
    //Create temporary contractor company
    @AuraEnabled
    public static Map<String,Object> setAccountContacts(String jsonString)
    {
        Map<String,Object> result = new Map<String,Object>();
        TempAccount__c newTempAcc = (TempAccount__c)JSON.deserialize(jsonString,TempAccount__c.class);
        //Check duplicate reord        
        List<Account> accList = [SELECT Id FROM Account WHERE Name=:String.escapeSingleQuotes(newTempAcc.Name) WITH SECURITY_ENFORCED];
        if(accList.size()==0){
            //Create new record
            SObjectAccessDecision securityDecision1 = Security.stripInaccessible(AccessType.CREATABLE, new TempAccount__c []{newTempAcc});
            Insert securityDecision1.getRecords();
            result.put('success',securityDecision1.getRecords());
        }
        else{
            result.put('error','Duplicate account found in the system, please click on the existing account or click Cancel.');                
        }        
        return result;
    }
    
    
    //Create/update temp contact record
    @AuraEnabled
    public static Map<String,Object> setContact(String jsonString,List<String> boothIds,String eventCode,String AccountId)
    {
        Map<String,Object> result = new Map<String,Object>();
        TempContact__c newTempCon = (TempContact__c)JSON.deserialize(jsonString,TempContact__c.class);
        
        //Check duplicate reord
        List<Contact> conList = [SELECT Id FROM Contact WHERE Email=:String.escapeSingleQuotes(newTempCon.Email__c) WITH SECURITY_ENFORCED];
        
        List<TempContact__c> tempConList = [SELECT Id FROM TempContact__c WHERE Email__c=:String.escapeSingleQuotes(newTempCon.Email__c)
                                           AND Contractor_Status__c = 'Approved' WITH SECURITY_ENFORCED];
        if(conList.size() == 0 && tempConList.size() == 0){
            //Create or update record
            SObjectAccessDecision securityDecision1 = Security.stripInaccessible(AccessType.UPSERTABLE, new TempContact__c []{newTempCon});
            Insert securityDecision1.getRecords();
            Id conId = securityDecision1.getRecords()[0].Id;
            TempContact__c tempObj = [SELECT Id,Name__c,Account__c,Contractor_Status__c
                                      FROM TempContact__c WHERE ID=:conId WITH SECURITY_ENFORCED LIMIT 1];
            createContactMap(false,boothIds,tempObj,eventCode,'',AccountId);
            result.put('success',tempObj);
        }
        else{
            result.put('error','Mapping already exists, choose a different contact from Contractor or edit the existing one.');                
        }
        return result;
    }
    
    @auraEnabled//Create contractor company contact and servives mapping
    public static void createContactMap(boolean alreadyExistCon, List<String> boothIds,TempContact__c objTempCon,string eventCode,String jsonString,String AccountId)
    {   
        system.debug('boothIds'+ boothIds);
        system.debug('jsonString'+ jsonString);
        Set<String> boothSEt = new Set<String>();
        Map<Id,Id> mapCEM = new Map<Id,Id>();
        List<Contractor_Mapping__c> boothMappingList = new List<Contractor_Mapping__c>();
        List<Contact_Edition_Mapping__c> listCEM = new List<Contact_Edition_Mapping__c>();
        
        //User userExh = [Select ContactId FROM User WHERE id=:userInfo.getUserId() WITH SECURITY_ENFORCED LIMIT 1];
        Edition__c ed =[SELECT Id FROM Edition__c WHERE Edition_Code__c=:eventCode WITH SECURITY_ENFORCED LIMIT 1];
        String editionId = ed.Id;
        //List<Contact_Edition_Mapping__c> exhibitorCEM = [SELECT Id,Primary_Contact_Edition_Mapping__c,isSecondary__c FROM Contact_Edition_Mapping__c WHERE Contact__c=:userExh.ContactId AND Account__c =:AccountId AND Edition__r.Edition_Code__c=:eventCode WITH SECURITY_ENFORCED LIMIT 1];
        
        if(!boothIds.isEmpty()){
            boothSEt.addAll(boothIds);
            for(Purchase_Data__c pd  : [SELECT Id, Contact_Edition_Mapping__c FROM Purchase_Data__c WHERE Id IN:boothSEt]){
                mapCEM.put(pd.Id,pd.Contact_Edition_Mapping__c);
            }
        }
        if(alreadyExistCon == false){
            Map<Integer,Id> mapIndexBoothId = new Map<Integer,Id>();
            Integer index = -1;
            if(!boothIds.isEmpty()){
                for(String bthId : boothIds){
                    Contractor_Mapping__c newboothMapping = new Contractor_Mapping__c();
                    newboothMapping.Name = objTempCon.Name__c;
                    newboothMapping.Account__c = objTempCon.Account__c;
                    newboothMapping.TempContact__c=objTempCon.Id;
                    newboothMapping.Edition__c=editionId;
                    newboothMapping.Is_Managed_by_Agent__c=true;
                    newboothMapping.Contractor_Status__c='New Contractor Nomination In Review'; 
                    boothMappingList.add(newboothMapping);

                    index++;
                    mapIndexBoothId.put(index, bthId);
                }
            }
            
            //Insert exhibitor and contartor map for expocad booth
            if(!boothMappingList.isEmpty() && Schema.sObjectType.Contractor_Mapping__c.isCreateable()){
                Insert boothMappingList;
                List<Purchase_Data__c> listPDUpdate = new List<Purchase_Data__c>();
                for(Integer indexVar : mapIndexBoothId.keySet()){
                    if(boothMappingList[indexVar].Id != null){
                        listPDUpdate.add(new Purchase_Data__c(Id=mapIndexBoothId.get(indexVar),Contractor_Mapping__c=boothMappingList[indexVar].Id));
                    }
                }
                if(!listPDUpdate.isEmpty() && Schema.sObjectType.Purchase_Data__c.isUpdateable()){
                    update listPDUpdate;
                }
            }
            Set<Id> cmIds = new Set<Id>();
            List<Contractor_Mapping__c> contractorMap = new List<Contractor_Mapping__c>();
            for(sObject cm : boothMappingList){
                cmIds.add(cm.Id);
            }
            
            if(Schema.sObjectType.Contractor_Mapping__c.isAccessible()){
                contractorMap = [SELECT Id,Approved__c,Account__c,Account__r.Name,Contractor_CEM__c,Contact__c,Contact__r.Name,Contractor_Status__c,Edition__c,Rejection_Reason__c,TempContact__c,TempContact__r.Name,TempContact__r.TempAccount__c,TempContact__r.TempAccount__r.Name,Edition__r.Edition_Code__c,CreatedDate FROM Contractor_Mapping__c WHERE ID =: cmIds WITH SECURITY_ENFORCED];}
                                      
         }
        else if(alreadyExistCon == true){
            Id cEMId;
            Contact con = (Contact)JSON.deserialize(jsonString,Contact.class);
            if(Schema.sObjectType.Contact_Edition_Mapping__c.isAccessible()){
                listCEM = [SELECT Id,Edition__c,Relationship_Status__c,Access_Type__c,Account__c
                           ,Contact__c, Edition__r.Edition_Code__c FROM Contact_Edition_Mapping__c
                           WHERE Relationship_Status__c = 'Active' AND Account__c=:con.AccountId
                           AND Edition__c=:editionId AND Contact__c=:con.Id WITH SECURITY_ENFORCED];
            }
            
            if(listCEM.isEmpty()){
                Contact_Edition_Mapping__c cEM = new Contact_Edition_Mapping__c();
                cEM.Account__c = con.AccountId;
                cEM.Contact__c = con.Id;
                cEM.Access_Type__c = 'Contractor';
                cEM.Edition__c = editionId;
                cEM.Relationship_Status__c = 'Active';
                
                SObjectAccessDecision securityDecision1 = Security.stripInaccessible(AccessType.CREATABLE, new Contact_Edition_Mapping__c []{cEM});
                Insert securityDecision1.getRecords();
                cEMId = securityDecision1.getRecords()[0].Id;
            }
            
            Map<Integer,Id> mapIndexBoothId = new Map<Integer,Id>();
            Integer index = -1;
            if(!boothIds.isEmpty()){
                for(String bthId : boothIds){
                    Contractor_Mapping__c newboothMapping = new Contractor_Mapping__c();
                    newboothMapping.Name = con.FirstName +''+ con.LastName;
                    newboothMapping.Contractor_CEM__c = (!listCEM.isEmpty())?listCEM[0].Id:cEMId;
                    newboothMapping.Account__c = con.AccountId;
                    newboothMapping.Contact__c = con.Id;
                    newboothMapping.Edition__c = editionId;
                    newboothMapping.Is_Managed_by_Agent__c=true;
                    newboothMapping.Approval_Date__c = system.now();
                    newboothMapping.Approved__c=true;
                    newboothMapping.Contractor_Status__c='Contractor Nominated'; 
                    boothMappingList.add(newboothMapping);

                    index++;
                    mapIndexBoothId.put(index, bthId);
                }
            }
            
            //Insert exhibitor and contartor map for expocad booth
            if(!boothMappingList.isEmpty() && Schema.sObjectType.Contractor_Mapping__c.isCreateable()){
                Insert boothMappingList;
                List<Purchase_Data__c> listPDUpdate = new List<Purchase_Data__c>();
                for(Integer indexVar : mapIndexBoothId.keySet()){
                    if(boothMappingList[indexVar].Id != null){
                        listPDUpdate.add(new Purchase_Data__c(Id=mapIndexBoothId.get(indexVar),Contractor_Mapping__c=boothMappingList[indexVar].Id));
                    }
                }
                if(!listPDUpdate.isEmpty() && Schema.sObjectType.Purchase_Data__c.isUpdateable()){
                    update listPDUpdate;
                }
            }

            Set<Id> cmIds = new Set<Id>();
            List<Contractor_Mapping__c> contractorMap = new List<Contractor_Mapping__c>();
            for(sObject cm : boothMappingList){
                cmIds.add(cm.Id);
            }
            
            if(Schema.sObjectType.Contractor_Mapping__c.isAccessible()){
                contractorMap = [SELECT Id,Approved__c,Account__c,Account__r.Name,Contractor_CEM__c,Contact__c,Contact__r.Name,Contractor_Status__c,Edition__c,Rejection_Reason__c,TempContact__c,TempContact__r.Name,TempContact__r.TempAccount__c,TempContact__r.TempAccount__r.Name,Edition__r.Edition_Code__c,CreatedDate FROM Contractor_Mapping__c WHERE ID =: cmIds WITH SECURITY_ENFORCED];
            }
            
            IMCC_ApproveContractorCtrl.sendEmail(contractorMap,boothIds,editionId);
        }
    }
    
    // fetch dependent picklist for country and state code
    @AuraEnabled // Fetch custom picklist values from custom Setting mdt related code towards country
    public static String getDepndentCustomVal(String countryCode)
    { 
        String cMobileCode ='';
        List<Dependent_Picklist_Setting__mdt> threatMappings = [SELECT MasterLabel,Controlling_Field_Code__c ,Dependent_Field_Code__c  
                                                                FROM Dependent_Picklist_Setting__mdt 
                                                                WHERE Controlling_Field_Code__c=:countryCode WITH SECURITY_ENFORCED
                                                                Limit 1];
        if(threatMappings.size()>0)
        {
            cMobileCode = threatMappings[0].Dependent_Field_Code__c; 
        }
        return cMobileCode;
    }
    
    // Fetch custom picklist values from custom Setting mdt related code towards country
    @AuraEnabled 
    public static String getCountryCodeByName(String countryName)
    { 
        String cCountryNameReltdCode ='';
        List<Dependent_Picklist_Setting__mdt> cCodeMappings = [SELECT MasterLabel,Controlling_Field_Code__c ,Dependent_Field_Code__c ,Country_Name__c  
                                                               FROM Dependent_Picklist_Setting__mdt 
                                                               WHERE Country_Name__c=:countryName WITH SECURITY_ENFORCED
                                                               limit 1];
        if(cCodeMappings.size()>0)
        {
            cCountryNameReltdCode = cCodeMappings[0].Dependent_Field_Code__c; 
        }
        return cCountryNameReltdCode;
    }
    
    
    
}