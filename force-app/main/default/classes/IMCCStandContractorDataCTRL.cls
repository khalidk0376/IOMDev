/**
* Created/Modified By :(Arushi)
* Created On:          25/01/2022
* @description  :      As a Contractor, I Should be able to view approve/decline the list of exhibitors who have
nominated me in the portal so that I can confirm the list of exhibitors for whom I will 
complete the stand design process.
Created/Modified By: Girikon(Arushi)
* Created On:          08/02/2022
* @description : (IMCC-69)As an Ops User , I Should be able to  choose the due submission date 
for stand design forms so the contractor and customer are aware of the deadline to complete this process.
Modified On:          01/03/2022
* @description : (IMCC-84)As a Customer & Contractor , I should be able to see the due date for the stand 
design forms to be submitted along with the form name so that I’m aware not to miss the deadline to
submit the stand design forms.
* Methods:             getActiveDatas,setUpdatedValue
* Apex TestClass:      IMCCStandContractorDataCTRL_Test(86%) 
**/
public without sharing class IMCCStandContractorDataCTRL {
    
    @AuraEnabled
    public static Map<String,Object> getActiveDatas(String accountId, String editionCode){
        
        Id editionId;
        Set<Id> contractorIdSet = new Set<Id>();
        List<Contractor_Mapping__c> contractorMappingList = new List<Contractor_Mapping__c>();
        List<Contact_Edition_Mapping__c> listCEM = new List<Contact_Edition_Mapping__c>();
        Map<Id, Contact_Edition_Mapping__c> cEMmap = new Map<Id, Contact_Edition_Mapping__c>();
        Map<Id,Purchase_Data__c> mapPD = new Map<Id,Purchase_Data__c>();
        
        try{
            Map<String,Object> mapCEMDetails = IMCC_UtilityMethods.getContactEditionMappings(editionCode, accountId);
            listCEM = (List<Contact_Edition_Mapping__c>)mapCEMDetails.get('cemList');
            Set<Id> cemIds = (Set<Id>)mapCEMDetails.get('cemIds');
                        
            if(!listCEM.isEmpty()){
                for(Contact_Edition_Mapping__c cemData : listCEM){
                    editionId = cemData.Edition__c;
                    cEMmap.put(cemData.Id,cemData);
                }   
            }
            
            contractorMappingList = [SELECT Id, Approval_Date__c, Approved__c,Is_Self_Managed__c, Account__c, Contact__c, Contractor_CEM__c,Contractor_Status__c, Edition__c,CreatedDate,TempContact__c, Account__r.Name,Edition__r.Stand_Design_Completion_Due_Date__c,Edition__r.Stand_Setting__r.Allow_Stand_Design_Submission__c,Edition__r.Start_Date__c FROM Contractor_Mapping__c WHERE Contractor_CEM__c IN: cemIds AND Contractor_Status__c != 'Contractor Declined Nomination' AND Account__c !='' AND Account__c!= null AND Edition__r.Stand_Setting__c != null WITH SECURITY_ENFORCED ORDER BY CreatedDate];
                                        
            for(Contractor_Mapping__c cm : contractorMappingList){
                contractorIdSet.add(cm.id);
            }

            List<Purchase_Data__c> listPD = [SELECT Id,Booth_Number__c,Purchase_Status__c,Transaction_Status__c,Booth_Product_Type__c,Contractor_Mapping__c,Contact_Edition_Mapping__c,Contact_Edition_Mapping__r.Account__r.Name,Contact_Edition_Mapping__r.Account__c FROM Purchase_Data__c WHERE Contractor_Mapping__c IN:contractorIdSet WITH SECURITY_ENFORCED];
            for(Purchase_Data__c pd : listPD){
                mapPD.put(pd.Contractor_Mapping__c, pd);
            }

            List<Stand_Detail__c> listStandDetail = new List<Stand_Detail__c>();
            Map<Id,Stand_Detail__c> standDetailMap = new Map<Id,Stand_Detail__c>();
            List<wrapperlist> boothWrapperList = new List<wrapperlist>();

            if(!contractorIdSet.isEmpty() && Schema.sObjectType.Stand_Detail__c.isAccessible()){
                listStandDetail = [SELECT Id,Name,Stand_Detail_Status__c,Current_Step__c,Stand_Detail_Submitted_On__c,Contractor_Mapping__c,Rejection_Reason__c FROM Stand_Detail__c WHERE Contractor_Mapping__c =:contractorIdSet WITH SECURITY_ENFORCED ORDER BY CreatedDate];
            }
            if(!listStandDetail.isEmpty()){
                for(Stand_Detail__c sd : listStandDetail){
                    standDetailMap.put(sd.Contractor_Mapping__c,sd);
                }
            } 

            for(Contractor_Mapping__c cm : contractorMappingList){
                wrapperlist wrap = new wrapperlist();
                wrap.contractor = cm;
                wrap.pd = mapPD.get(cm.Id);
                wrap.standDetail = standDetailMap.ContainsKey(cm.Id)?standDetailMap.get(cm.Id):new Stand_Detail__c();
                wrap.standDetailLength = standDetailMap.ContainsKey(cm.Id)?1:0;
                boothWrapperList.add(wrap);
            }

            String d = !listCEM.isEmpty() ? System.Today()+'_'+ listCEM[0].Edition__r.Stand_Design_Completion_Due_Date__c:''+System.Today()+'_';
            return new map<String, object>{
                'dates'=>d,
                'data'=>boothWrapperList
            };
        }
        catch(exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
   
    @AuraEnabled
    public static void setUpdatedValue(string statusValue,string rejectReason,string cmId){
        List<Contractor_Mapping__c> contractorMappingList = new List<Contractor_Mapping__c>();
        List<Contractor_Mapping__c> cmToUpdate = new List<Contractor_Mapping__c>();
        try{
            if(Schema.sObjectType.Contractor_Mapping__c.isAccessible()){
                contractorMappingList = [SELECT Id, Approval_Date__c, Approved__c, Account__c, Contact__c, Contractor_CEM__c,Contractor_Status__c, Edition__c,TempContact__c,Account__r.Name,Rejection_Reason__c FROM Contractor_Mapping__c WHERE Id =: String.escapeSingleQuotes(cmId) WITH SECURITY_ENFORCED];
                
                for(Contractor_Mapping__c cm : contractorMappingList){
                    cm.Contractor_Status__c = statusValue;
                    if(rejectReason != null && rejectReason!=''){
                        cm.Rejection_Reason__c = rejectReason;
                    }
                    cmToUpdate.add(cm);
                }
            }
            if(!cmToUpdate.isEmpty()) update cmToUpdate;
        }
        catch(exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
    }

    public class wrapperlist{
        @AuraEnabled public Contractor_Mapping__c contractor{get;set;}
        @AuraEnabled public integer standDetailLength{get;set;}
        @AuraEnabled public Stand_Detail__c standDetail{get;set;}
        @AuraEnabled public Purchase_Data__c pd{get;set;}
    }
}