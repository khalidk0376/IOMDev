/**
* Created/Modified By :(Arushi)
* Created On:          21/01/2022
* @description  :      As a Customer , I Should be able to see the Stand design tab only if I'm an onsite exhibitor(Exhibitor with a booth) so that I can complete my stand submission process on time.
Created/Modified By: Girikon(Arushi,Saurabh)
* Created On:          08/02/2022
* @description : (IMCC-68)As an  Ops User , I Should be able to  set a due date for an exhibitor to associate a 
contractor so that the customer is aware of the deadline to nominate contractors to complete the stand design process.
* Modified By      :   Girikon(Arushi - [IMCC-91]),[Aishwarya Girikon 29 March 2023 IMCC-5042]
* Modified On      :   25 Feb, 2022
* @description     :   As a Customer, I should be able to submit the stand design for my booths
                       , if I am decide to complete my stand submission process myself.
* Methods:             getTabContext,getActivePHDatas,buildOwnStandContactorMap
* Apex TestClass:      IMCCStandDesignCTRL_Test(88%) 
**/
public without sharing class IMCCStandDesignCTRL {
    
    /**
    * @description  to get Active Purchase Datas
    * @param  accountId
    * @param  editionCode
    * @return Map<String, object>
    */
    @AuraEnabled
    public static Map<String, object> getActivePHDatas(String accountId, String editionCode){
        List<Purchase_Data__c> pdList = new List<Purchase_Data__c>();
        List<Contact_Edition_Mapping__c> listCEM = new List<Contact_Edition_Mapping__c>();
        Map<Id, Contact_Edition_Mapping__c> cEMmap = new Map<Id, Contact_Edition_Mapping__c>();
        Map<Id, Purchase_Data__c> pHDataMap = new Map<Id, Purchase_Data__c>();
        Map<Id, Contractor_Mapping__c> contractorMap = new Map<Id, Contractor_Mapping__c>();
        List<Wrapperlist> boothWrapperList = new List<Wrapperlist>();
        List<Edition__c> listEdition = new List<Edition__c>();
        Set<Id> contractorIdSet = new Set<Id>();

        //User userObj = [SELECT Id, contactId FROM User WHERE Id = : UserInfo.getUserId() WITH SECURITY_ENFORCED LIMIT 1];
        //IMCC-5042 Including Status of 'In Progress'
        if(Schema.sObjectType.Edition__c.isAccessible()){
            listEdition = [SELECT Id,Stand_Design_Completion_Due_Date__c, Contractor_Nomination_Due_Date__c
                           ,Customer_Center_Status__c, Edition_Status__c,Edition_Code__c FROM Edition__c WHERE Edition_Status__c = 'Confirmed' AND 
                            Customer_Center_Status__c IN ('Active', 'In Progress') AND Edition_Code__c=:String.escapeSingleQuotes(editionCode) ];
        }

        Map<String,Object> mapCEMDetails = IMCC_UtilityMethods.getContactEditionMappings(editionCode, accountId);
        listCEM = (List<Contact_Edition_Mapping__c>)mapCEMDetails.get('cemList');
        Set<Id> cemIds = (Set<Id>)mapCEMDetails.get('cemIds');
        
        if(!listCEM.isEmpty()){
            for(Contact_Edition_Mapping__c cemData : listCEM){
                cEMmap.put(cemData.Id,cemData);
                if(String.isNotBlank(cemData.Primary_Contact_Edition_Mapping__c)){
                    cEMmap.put(cemData.Primary_Contact_Edition_Mapping__c,cemData);
                }
            }   
        }
        
        pdList  = [SELECT Id,Quantity_Area__c, Transaction_Status__c, Contact_Edition_Mapping__c,Booth_Number__c, Purchase_Status__c, Booth_Product_Type__c,Contractor_Mapping__c FROM Purchase_Data__c WHERE Booth_Number__c!=null AND Booth_Number__c!='' AND Contact_Edition_Mapping__c IN: cemIds AND (Booth_Product_Type__c = 'Space' OR Booth_Product_Type__c = 'Space Only') AND Purchase_Status__c = 'Active' AND Transaction_Status__c ='Active' WITH SECURITY_ENFORCED];        
    
        for(Purchase_Data__c pHData : pdList){
            pHDataMap.put(pHData.Id,pHData);  
            if(String.isNotBlank(pHData.Contractor_Mapping__c)){contractorIdSet.add(pHData.Contractor_Mapping__c);}      
        }  

        contractorMap = new Map<Id, Contractor_Mapping__c>([SELECT Id,Approved__c,Account__c,Account__r.Name,Contractor_CEM__c,Contact__c,Contact__r.Name,Contractor_Status__c,Edition__c,Rejection_Reason__c,TempContact__c,TempContact__r.Name,TempContact__r.Rejection_Reason__c,TempContact__r.TempAccount__c,TempContact__r.TempAccount__r.Name,Edition__r.Edition_Code__c,CreatedDate FROM Contractor_Mapping__c WHERE Edition__r.Edition_Code__c=:String.escapeSingleQuotes(editionCode) AND (Contact__c != null OR TempContact__c != null) AND Id IN:contractorIdSet WITH SECURITY_ENFORCED ORDER BY CreatedDate]);

        List<Stand_Detail__c> listStandDetail = new List<Stand_Detail__c>();
        Map<Id,Stand_Detail__c> standDetailMap = new Map<Id,Stand_Detail__c>();
        if(!contractorIdSet.isEmpty() && Schema.sObjectType.Stand_Detail__c.isAccessible()){
            listStandDetail = [SELECT Id,Name,Stand_Detail_Status__c,Current_Step__c,Stand_Detail_Submitted_On__c,Contractor_Mapping__c FROM Stand_Detail__c WHERE Contractor_Mapping__c =:contractorIdSet WITH SECURITY_ENFORCED ORDER BY CreatedDate];
        }
        if(!listStandDetail.isEmpty()){
            for(Stand_Detail__c sd : listStandDetail){
                standDetailMap.put(sd.Contractor_Mapping__c,sd);
            }
        } 
               
        if(!pdList.isEmpty()){
            for(Purchase_Data__c pHData : pdList){
                if(contractorMap.ContainsKey(pHData.Contractor_Mapping__c)){
                    Wrapperlist wrap = new Wrapperlist();
                    wrap.boothId = pHData.Id;
                    wrap.boothNumber = pHData.Booth_Number__c;
                    wrap.contractorLength = 1;
                    wrap.contractor = contractorMap.get(pHData.Contractor_Mapping__c);
                    if(cEMmap.ContainsKey(pHData.Contact_Edition_Mapping__c)){
                        wrap.toBeNominated = !(cEMmap.get(pHData.Contact_Edition_Mapping__c).Edition__r.Contractor_Nomination_Due_Date__c < System.Today() && cEMmap.get(pHData.Contact_Edition_Mapping__c).Edition__r.Stand_Setting__r.Allow_Contractor_Nomination__c == false );
                    }
                    else{
                        wrap.toBeNominated = false; 
                    }
                    wrap.standDetail = standDetailMap.ContainsKey(pHData.Contractor_Mapping__c)?standDetailMap.get(pHData.Contractor_Mapping__c):new Stand_Detail__c();
                    wrap.standDetailLength = standDetailMap.ContainsKey(pHData.Contractor_Mapping__c)?1:0;
                    wrap.standSubmissionDueDate = cEMmap.get(pHData.Contact_Edition_Mapping__c).Edition__r.Stand_Design_Completion_Due_Date__c;
                    boothWrapperList.add(wrap);
                }
                else{
                    Wrapperlist wrap = new Wrapperlist();
                    wrap.boothId = pHData.Id;
                    wrap.boothNumber = pHData.Booth_Number__c;
                    wrap.contractorLength = 0;
                    if(cEMmap.ContainsKey(pHData.Contact_Edition_Mapping__c)){
                        wrap.toBeNominated = !(cEMmap.get(pHData.Contact_Edition_Mapping__c).Edition__r.Contractor_Nomination_Due_Date__c < System.Today() && cEMmap.get(pHData.Contact_Edition_Mapping__c).Edition__r.Stand_Setting__r.Allow_Contractor_Nomination__c == false);
                    }
                    else{
                        wrap.toBeNominated = false; 
                    }
                    wrap.contractor = new Contractor_Mapping__c();
                    wrap.standDetail = new Stand_Detail__c();
                    wrap.standDetailLength = 0;
                    wrap.standSubmissionDueDate = cEMmap.get(pHData.Contact_Edition_Mapping__c).Edition__r.Stand_Design_Completion_Due_Date__c;
                    boothWrapperList.add(wrap);
                }
            }   
        }
    
        return new map<String, object>{
            'DueDate'=> listEdition,
            'data'=> boothWrapperList
        };
        //return boothWrapperList;
    }
    
    /**
    * @description  to set exhibitor as contractor on booth/stand
    * @param  boothId
    * @param  editionCode
    * @param  accountId
    */
    @AuraEnabled
    public static void buildOwnStandContactorMap(String boothId,string editionCode,String accountId)
    {   
        //User userExh = [Select ContactId FROM User WHERE id=:userInfo.getUserId() WITH SECURITY_ENFORCED LIMIT 1];
        
        Edition__c ed =[SELECT Id FROM Edition__c WHERE Edition_Code__c=:editionCode WITH SECURITY_ENFORCED LIMIT 1];
        String editionId = ed.Id;
        Map<Id,Id> mapCEM = new Map<Id,Id>();

        //List<Contact_Edition_Mapping__c> ExhibitorCEM = [SELECT Id,Edition__c FROM Contact_Edition_Mapping__c WHERE Account__c=:String.escapeSingleQuotes(accountId) AND Edition__r.Edition_Code__c=:String.escapeSingleQuotes(editionCode) AND Contact__c=:userExh.ContactId WITH SECURITY_ENFORCED LIMIT 1];

        String contactId; 
        for(Purchase_Data__c pd  : [SELECT Id, Contact_Edition_Mapping__c,Contact_Edition_Mapping__r.Contact__c FROM Purchase_Data__c WHERE Id =:boothId]){
            mapCEM.put(pd.Id,pd.Contact_Edition_Mapping__c);
            contactId = pd.Contact_Edition_Mapping__r.Contact__c;
        }
        Contact con = [SELECT Id, FirstName, LastName, AccountId FROM Contact WHERE Id=:contactId WITH SECURITY_ENFORCED];
        
        Contractor_Mapping__c newboothMapping = new Contractor_Mapping__c();
        newboothMapping.Name = con.FirstName +' '+ con.LastName;
        newboothMapping.Contractor_CEM__c = mapCEM.get(boothId);
        newboothMapping.Account__c = con.AccountId;
        newboothMapping.Contact__c = con.Id;
        newboothMapping.Edition__c = editionId;
        newboothMapping.Is_Self_Managed__c=true;
        newboothMapping.Approval_Date__c = system.now();
        newboothMapping.Approved__c=true;
        newboothMapping.Contractor_Status__c='Contractor Nominated'; 
        if(Schema.sObjectType.Contractor_Mapping__c.isCreateable()){
            insert newboothMapping;
            if(Schema.sObjectType.Purchase_Data__c.isUpdateable()){
                update new Purchase_Data__c(Id=boothId, Contractor_Mapping__c=newboothMapping.Id);
            }
        }
    }

    /**@description  Wrapperlist*/
    public class Wrapperlist{
        /**@description  boothId*/
        @AuraEnabled public String boothId{get;set;}
        /**@description  boothNumber*/
        @AuraEnabled public String boothNumber{get;set;}
        /**@description  standSubmissionDueDate*/
        @AuraEnabled public date standSubmissionDueDate{get;set;}
        /**@description  contractorLength*/
        @AuraEnabled public integer contractorLength{get;set;}
        /**@description  toBeNominated*/
        @AuraEnabled public Boolean toBeNominated{get;set;}
        /**@description  contractor*/
        @AuraEnabled public Contractor_Mapping__c contractor{get;set;}
        /**@description  standDetailLength*/
        @AuraEnabled public integer standDetailLength{get;set;}
        /**@description  standDetail*/
        @AuraEnabled public Stand_Detail__c standDetail{get;set;}
    }

    }