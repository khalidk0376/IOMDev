/**
 * Created By       :   Girikon(Mukesh)
 * Created On       :   04/26/2022
 * @description     :   All methods of this class AuraEnabled and called from imccContractorSubmission lwc component 
 * Test Class       :   Imcc_ContractorSubmissions_Test
 * Modified by      :   Girikon(Garima)
 **/
public with sharing class Imcc_ContractorSubmissions {
 
    /**
     * @description get All Active Editions
     * @return List<SObject>
     */
    @AuraEnabled
    public static List<SObject> getAllActiveEditions(){
        return [SELECT Id,Edition_Code__c,Name FROM Edition__c WHERE Edition_Status__c='Confirmed' WITH SECURITY_ENFORCED ORDER BY Start_Date__c DESC];
    }

    /**
     * @description get All Contractor Mappings
     * @param editionId
     * @return Map<String,Object>
     */
    @AuraEnabled
    public static Map<String,Object> getContractorMap(String editionId){
        Map<Id,Contractor_Mapping__c> mapConMapping = new Map<Id,Contractor_Mapping__c>([SELECT Id, Contact__c,Account__r.Name,
        TempContact__r.TempAccount__c,TempContact__r.TempAccount__r.Address__c,
        TempContact__r.TempAccount__r.Zip__c,TempContact__r.Account__r.Name,
        TempContact__r.TempAccount__r.State__c,                
        TempContact__r.TempAccount__r.Name,TempContact__r.Phone__c,
        TempContact__r.MobilePhone__c, TempContact__r.Email__c,TempContact__r.CreatedDate,
        TempContact__r.Contractor_Status__c,Contractor_Status__c,
        TempContact__r.Account__c,TempContact__c,TempContact__r.FirstName__c,
        TempContact__r.LastName__c,Contact__r.Name,Contact__r.Email,Contact__r.MobilePhone FROM Contractor_Mapping__c  
        WHERE TempContact__c!=null AND Edition__c =:editionId AND 
        Approved__c=false AND Contractor_Status__c!='New Contractor Nomination Rejected' 
        WITH SECURITY_ENFORCED]);

        List<Purchase_Data__c> listPD = [SELECT Id,Booth_Number__c,Booth_Product_Type__c,Contractor_Mapping__c,Contact_Edition_Mapping__c,Contact_Edition_Mapping__r.Account__c,Contact_Edition_Mapping__r.Account__r.Name,Contact_Edition_Mapping__r.Contact__c,Contact_Edition_Mapping__r.Contact__r.Name,Contact_Edition_Mapping__r.Access_Type__c FROM Purchase_Data__c WHERE Contractor_Mapping__c IN:mapConMapping.keySet() WITH SECURITY_ENFORCED];

        return new Map<String,Object>{
            'listConMapping'=>mapConMapping.Values(),
            'listPD'=>listPD
        };    
    }

    /**
     * @description update sobject list
     * @param records
     */
    @AuraEnabled
    public static void updateRecords(List<SObject> records){
        Update records;
    }

    /**
     * @description get stand details
     * @param editionId
     * @return Map<String,Object>
     */
    @AuraEnabled
    public static Map<String,Object> getStandList(String editionId){
        List<String> status = new List<String>();
        status.add('In Review');
        status.add('Stand Design Resubmitted');
        
        List<Stand_Detail__c> listStandDetail = [SELECT Id,Stand_Detail_Status__c,
        Contractor_Mapping__c,
        Contractor_Mapping__r.Account__c,
        Contractor_Mapping__r.Account__r.Name FROM Stand_Detail__c 
        WHERE Edition__c=:editionId AND Stand_Detail_Status__c IN:status WITH SECURITY_ENFORCED];

        Set<Id> conMappingIds = new Set<Id>();
        for(Stand_Detail__c sd : listStandDetail){
            conMappingIds.add(sd.Contractor_Mapping__c);
        }

        List<Purchase_Data__c> listPD = [SELECT Id,Booth_Number__c,Booth_Product_Type__c,Contractor_Mapping__c,Contact_Edition_Mapping__c,Contact_Edition_Mapping__r.Account__c,Contact_Edition_Mapping__r.Account__r.Name,Contact_Edition_Mapping__r.Contact__c,Contact_Edition_Mapping__r.Contact__r.Name,Contact_Edition_Mapping__r.Access_Type__c FROM Purchase_Data__c WHERE Contractor_Mapping__c IN:conMappingIds WITH SECURITY_ENFORCED];

        return new Map<String,Object>{
            'listStandDetail'=>listStandDetail,
            'listPD'=>listPD
        };
    }
    
    /**
     * @description approve stand deesign
     * @param selectedStandIds
     * @param status
     * @param approvalDate
     */
    @AuraEnabled
    public static void approvalStandDesign(List<String> selectedStandIds, String status, string approvalDate){
        
        List<Stand_Detail__c> updateStandDetail = new List<Stand_Detail__c>();
        List<Stand_Detail__c> standDetailList = [SELECT Id,Stand_Detail_Status__c,Approval_Date__c 
                                                 FROM Stand_Detail__c WHERE Id IN:selectedStandIds];
        for(Stand_Detail__c sd : standDetailList){
            sd.Stand_Detail_Status__c = status;
            if(status == 'Tentative Approval'){
            sd.Approval_Date__c = date.valueOf(approvalDate);
            }
            updateStandDetail.add(sd);
        }
        try{
            update updateStandDetail;
        }
        catch(exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
     /**
     * @description to reject selected stand designs
     * @param selectedStandIds
     * @param status
     * @param step
     * @param rejectionReason
     */
    @AuraEnabled
    public static void rejectStandDesign(List<String> selectedStandIds, String status, string step, string rejectionReason){
        List<Stand_Detail__c> updateStandDetail = new List<Stand_Detail__c>();
        List<Stand_Detail__c> standDetailList = [SELECT Id,Stand_Detail_Status__c,Rejection_Reason__c,Rejected_Steps__c 
                                                 FROM Stand_Detail__c WHERE Id IN:selectedStandIds];
        for(Stand_Detail__c sd : standDetailList){
            sd.Stand_Detail_Status__c = status;
            sd.Rejected_Steps__c = step;
            sd.Rejection_Reason__c = rejectionReason;
            updateStandDetail.add(sd);
        }
        try{
            update updateStandDetail;
        }
        catch(exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
    }
}