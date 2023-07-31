/**
* Created/Modified By :(Arushi)
* Created On:          13/06/2022
* @description  :      As an Ops User , I should be able to complete end to end stand submission process on behalf of Exhibitor/contractor.
* Test Class:          IMCC_ContractorNominationsCTRL_Test(96%) 
**/
public class IMCC_ContractorNominationsCTRL {

    /**
     * @description get purchase datas
     * @param editionId
     * @return Map<String, object>
     */
    @AuraEnabled
    public static Map<String, object> getActivePHDatas(String editionId){
        Set<Id> contractorIdSet = new Set<Id>();
        List<Purchase_Data__c> pdList = new List<Purchase_Data__c>();
        List<Contact_Edition_Mapping__c> listCEM = new List<Contact_Edition_Mapping__c>();
        List<Contractor_Mapping__c> listBoothContractor = new List<Contractor_Mapping__c>();
        Map<Id, Contact_Edition_Mapping__c> cEMmap = new Map<Id, Contact_Edition_Mapping__c>();
        Map<Id, Purchase_Data__c> pHDataMap = new Map<Id, Purchase_Data__c>();
        Map<Id, Contractor_Mapping__c> contractorMap = new Map<Id, Contractor_Mapping__c>();
        List<wrapperlist> boothWrapperList = new List<wrapperlist>();
        List<Edition__c> listEdition = new List<Edition__c>();
        
        //User userObj = [SELECT Id, contactId FROM User WHERE Id = : UserInfo.getUserId() WITH SECURITY_ENFORCED LIMIT 1];
        
        if(Schema.sObjectType.Edition__c.isAccessible()){
            listEdition = [SELECT Id,Stand_Design_Completion_Due_Date__c, Contractor_Nomination_Due_Date__c
                           ,Customer_Center_Status__c, Edition_Status__c,Edition_Code__c FROM Edition__c WHERE Edition_Status__c = 'Confirmed' AND 
                           Customer_Center_Status__c ='Active' AND Id=:editionId];
        }
        
        if(Schema.sObjectType.Contact_Edition_Mapping__c.isAccessible()){
            listCEM = [SELECT Id,Edition__c,Relationship_Status__c,Access_Type__c,Account__c
                       ,Contact__c, Edition__r.Edition_Code__c, Edition__r.Event_Type__c
                       ,Edition__r.Contractor_Nomination_Due_Date__c, Edition__r.Stand_Setting__r.Allow_Contractor_Nomination__c
                       ,Edition__r.Stand_Design_Completion_Due_Date__c
                       FROM Contact_Edition_Mapping__c WHERE Relationship_Status__c = 'Active' 
                       AND Edition__r.Id=:editionId AND Edition__r.Stand_Setting__c != null];
        }
        
        if(!listCEM.isEmpty()){
            for(Contact_Edition_Mapping__c cemData : listCEM){
                cEMmap.put(cemData.Id,cemData);
            }   
        }
        if(Schema.sObjectType.Purchase_Data__c.isAccessible()){
            pdList  = [SELECT Id,Quantity_Area__c, Transaction_Status__c, Contact_Edition_Mapping__c,Account__r.Name,Contact__r.Name,Booth_Number__c, Purchase_Status__c, Booth_Product_Type__c,Contractor_Mapping__c FROM Purchase_Data__c WHERE Booth_Number__c!=null AND Booth_Number__c!='' AND Contact_Edition_Mapping__c IN: cEMmap.keySet() AND (Booth_Product_Type__c = 'Space' OR Booth_Product_Type__c = 'Space Only') AND Purchase_Status__c = 'Active' AND Transaction_Status__c ='Active' WITH SECURITY_ENFORCED];  
        }
        Set<Id> conMappingIds = new Set<Id>();
        if(!pdList.isEmpty()){
            for(Purchase_Data__c pHData : pdList){
                pHDataMap.put(pHData.Id,pHData);
                conMappingIds.add(pHData.Contractor_Mapping__c);
            }   
        }
        
        listBoothContractor = [SELECT Id,Approved__c,Account__c,Account__r.Name,Contractor_CEM__c,Contact__c,Contact__r.Name,Contractor_Status__c,Edition__c,Rejection_Reason__c,TempContact__c,TempContact__r.Name,TempContact__r.Rejection_Reason__c,TempContact__r.TempAccount__c,TempContact__r.TempAccount__r.Name,Edition__r.Edition_Code__c,CreatedDate FROM Contractor_Mapping__c WHERE Edition__r.Id=:editionId AND (Contact__c != null OR TempContact__c != null) AND Id IN:conMappingIds WITH SECURITY_ENFORCED ORDER BY CreatedDate];
        
        for(Contractor_Mapping__c cm : listBoothContractor){
            contractorIdSet.add(cm.id);
            contractorMap.put(cm.Id,cm);            
        }
        
        
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
                    wrapperlist wrap = new wrapperlist();
                    wrap.boothId = pHData.Id;
                    wrap.boothNumber = pHData.Booth_Number__c;
                    wrap.exhibitorCompany = pHData.Account__r.Name;
                    wrap.exhibitorContact = pHData.Contact__r.Name;
                    wrap.contractorLength = 1;
                    wrap.contractor = contractorMap.get(pHData.Contractor_Mapping__c);
                    if(cEMmap.ContainsKey(pHData.Contact_Edition_Mapping__c)){
                        wrap.toBeNominated = !(cEMmap.get(pHData.Contact_Edition_Mapping__c).Edition__r.Contractor_Nomination_Due_Date__c < System.Today() && cEMmap.get(pHData.Contact_Edition_Mapping__c).Edition__r.Stand_Setting__r.Allow_Contractor_Nomination__c == false );
                    }
                    else{
                        wrap.toBeNominated = false; 
                    }
                    wrap.standDetail = standDetailMap.ContainsKey(contractorMap.get(pHData.Contractor_Mapping__c).Id)?standDetailMap.get(contractorMap.get(pHData.Contractor_Mapping__c).Id):new Stand_Detail__c();
                    wrap.standDetailLength = standDetailMap.ContainsKey(contractorMap.get(pHData.Contractor_Mapping__c).Id)?1:0;
                    wrap.standSubmissionDueDate = cEMmap.get(pHData.Contact_Edition_Mapping__c).Edition__r.Stand_Design_Completion_Due_Date__c;
                    boothWrapperList.add(wrap);
                }
                else{
                    wrapperlist wrap = new wrapperlist();
                    wrap.boothId = pHData.Id;
                    wrap.boothNumber = pHData.Booth_Number__c;
                    wrap.exhibitorCompany = pHData.Account__r.Name;
                    wrap.exhibitorContact = pHData.Contact__r.Name;
                    wrap.contractorLength = 0;
                    if(cEMmap.ContainsKey(pHData.Contact_Edition_Mapping__c)){
                        wrap.toBeNominated = !(cEMmap.get(pHData.Contact_Edition_Mapping__c).Edition__r.Contractor_Nomination_Due_Date__c < System.Today() && cEMmap.get(pHData.Contact_Edition_Mapping__c).Edition__r.Stand_Setting__r.Allow_Contractor_Nomination__c == false );
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
            'data'=> boothWrapperList
        };
    }
    
     /**
     * @description delete stand design
     * @param standDetailId
     * @param contactormapId
     */
    @auraEnabled
    public static void getstandDetailDelete(string standDetailId,string contactormapId){
        
        Contractor_Mapping__c contractorMap = [SELECT Id,Contractor_Status__c FROM Contractor_Mapping__c WHERE Id=:contactormapId WITH SECURITY_ENFORCED];
        
        Stand_Detail__c standDetail = [SELECT Id,Contractor_Mapping__c FROM Stand_Detail__c  WHERE Id =:standDetailId WITH SECURITY_ENFORCED];
        try{
            Delete standDetail;
            contractorMap.Contractor_Status__c = 'Contractor Accepted Nomination';
            update contractorMap;
        }
        catch(exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    /** @description wrapper class */
    public class Wrapperlist{
        /** @description booth id */
        @AuraEnabled public String boothId{get;set;}
        /** @description booth number */
        @AuraEnabled public String boothNumber{get;set;}
        /** @description exhibitor company */
        @AuraEnabled public String exhibitorCompany{get;set;}
        /** @description exhibitor contact */
        @AuraEnabled public String exhibitorContact{get;set;}
        /** @description stand design submission due date */
        @AuraEnabled public date standSubmissionDueDate{get;set;}
        /** @description contractor mapping length */
        @AuraEnabled public integer contractorLength{get;set;}
        /** @description is nominate a contractor */
        @AuraEnabled public Boolean toBeNominated{get;set;}
        /** @description Contractor mapping */
        @AuraEnabled public Contractor_Mapping__c contractor{get;set;}
        /** @description stand detail lenght */
        @AuraEnabled public integer standDetailLength{get;set;}
        /** @description stand detail */
        @AuraEnabled public Stand_Detail__c standDetail{get;set;}
    }
    
}