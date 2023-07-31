/**
* Created/Modified By: Girikon(Garima)
* Created On:          1/10/2021
* @description  :      This class is used to fetch all the Booth Details related to contact edition mapping of the customer who is login
* Methods:             fetchBoothDetails
* Apex Class:          IMCC_FloorplanCtrl 
* Apex Test Class:     IMCC_FloorplanCtrl_Test (93%) 
* Modified By      :  IBM(Srikanth)
* Modified On      :   16 Sept, 2022
* @description  :      For all Auraenabled methods added try-catch block and threw Aura exception.
**/

/**
* @description : to fetch Booth Detail from Purchase Data object for particular contact who is login to Customer Center
* @param : eventcode, accountId,tabId
* @return : WrapperBoothDetails
**/
public class IMCC_FloorplanCtrl {
    @AuraEnabled
    public static WrapperBoothDetails fetchBoothDetails(String eventCode, String accountId, String tabId){
        WrapperBoothDetails wrapBoothData = new WrapperBoothDetails();
        Map<String,Object> mapCEMDetails = IMCC_UtilityMethods.getContactEditionMappings(eventCode, accountId);
    
        try{
            List<Contact_Edition_Mapping__c> conEdMapLst = (List<Contact_Edition_Mapping__c>)mapCEMDetails.get('cemList');//[Select Id,Name,Access_Type__c,Account__c,Account__r.Name,CC_Status__c,Contact__c,Edition__c,Edition__r.Expocad_Event_Code__c,Relationship_Status__c from Contact_Edition_Mapping__c where Contact__c =: u.ContactId And Account__c =: accountId And Relationship_Status__c = 'Active' And Edition__r.Edition_Code__c =: eventCode];
            Set<Id> cemIds = (Set<Id>)mapCEMDetails.get('cemIds');

            if(!conEdMapLst.isEmpty()){
                wrapBoothData.expocadEventCode = conEdMapLst[0].Edition__r.Expocad_Event_Code__c;
                List<Tab_Context__c> evntTabContextLst;
                List<Event_Tabs__c> eventTabLst = new List<Event_Tabs__c>();
                if(String.isNotBlank(tabId)){
                    if(Tab_Context__c.SObjectType.getDescribe().isAccessible()){
                        evntTabContextLst = [Select id,Name,Event_Tab__r.Name,Event_Tab__r.Tab_Code__c,Event_Tab__r.Tab_Type__c,Event_Tab__r.Floorplan_Type__c,Header__c,Section_1__c,Section_2__c,Section_3__c from Tab_Context__c where Event_Tab__r.Tab_Code__c =: tabId];
                    }
                    if(!evntTabContextLst.isEmpty()){
                        wrapBoothData.tabContext = evntTabContextLst[0]; 
                        system.debug('Tab Contet ' +wrapBoothData.tabContext);
                    }
                    
                    if(Event_Tabs__c.SObjectType.getDescribe().isAccessible()){
                        eventTabLst = [Select id,Name,Standard_Tab_Type__c,Tab_Code__c,Tab_Type__c,Floorplan_Type__c,Floorplan_Blank_Msg__c from Event_Tabs__c where Tab_Code__c =: tabId];
                    }
                    
                }
                /* Check whether Floorplan type of Standard Tab is Interactive*/
                if(!eventTabLst.isEmpty() && eventTabLst[0].Floorplan_Type__c == 'Interactive'){
                    wrapBoothData.evntTab = eventTabLst[0];
                    List<Purchase_Data__c> prchseDtlLst;
                    if(Purchase_Data__c.SObjectType.getDescribe().isAccessible()){
                        prchseDtlLst = [Select id,Name,Contact_Edition_Mapping__c,Booth_Number__c,Booth_Product_Type__c,Purchase_Status__c,Transaction_Status__c,Quantity_Area__c,Unit_of_Measurement__c from Purchase_Data__c where Contact_Edition_Mapping__c IN:cemIds and Booth_Number__c != '' and Purchase_Status__c='Active' and Transaction_Status__c = 'Active'];
                    }
                    if(!prchseDtlLst.isEmpty() && prchseDtlLst.size()>0){
                        wrapBoothData.purchaseDtls = prchseDtlLst;
                        system.debug('purchase Data ' +wrapBoothData.purchaseDtls);
                    }
                }
                /* Check whether Floorplan type of Standard Tab is Manual*/
                if(!eventTabLst.isEmpty() && eventTabLst[0].Floorplan_Type__c == 'Manual'){
                    Map<String,List<PDF_Floorplan__c>> mapPdfGroup = new Map<String,List<PDF_Floorplan__c>>();
                    List<PDF_Floorplan__c> pdfFloorplanLst = [Select id,Name,Event_Tab__c,PDF_Name__c,PDF_Type__c from PDF_Floorplan__c where Event_Tab__r.Tab_Code__c =: tabId Order By PDF_Type__c,PDF_Name__c asc];
                    for(PDF_Floorplan__c pdfFlrplan : pdfFloorplanLst){
                        if(String.isNotBlank(pdfFlrplan.PDF_Type__c)){
                            if(!mapPdfGroup.containsKey(pdfFlrplan.PDF_Type__c)){
                                mapPdfGroup.put(pdfFlrplan.PDF_Type__c, new List<PDF_Floorplan__c>());
                            }
                          mapPdfGroup.get(pdfFlrplan.PDF_Type__c).add(pdfFlrplan);  
                        }
                    }
                    system.debug('Map PDF Floorplan  ' +mapPdfGroup);
                    List<WrapperPdfFloorplan> wrapPdfLst = new List<WrapperPdfFloorplan>();
                    for(String pdfType : mapPdfGroup.keySet()){
                       WrapperPdfFloorplan wrapPdf = new WrapperPdfFloorplan();
                        wrapPdf.pdfType = pdfType;
                        wrapPdf.pdfFloorplan = mapPdfGroup.get(pdfType);
                        wrapPdfLst.add(wrapPdf);
                    }
                    wrapBoothData.lstPdf = wrapPdfLst;
                    system.debug('Wrapper PDF Floorplan  ' +wrapBoothData.lstPdf);
                }
                
            }       
        }
        catch (Exception e) {
            System.debug('Exception hit ' +e.getMessage());
           // HandleAllCustomException.logException(e,'Purchase_Data__c', 'After Insert');
           String stackTrace = e.getStackTraceString().substringBefore('\n');
           String mesg = String.isNotBlank(e.getMessage()) ? e.getMessage():''; 
           throw new AuraHandledException('Message='+mesg+'Stacktrace='+stackTrace);

        } 
        return wrapBoothData;
    }
    public class WrapperBoothDetails
    {
        @AuraEnabled public Tab_Context__c tabContext{get;set;}
        @AuraEnabled public List<Purchase_Data__c> purchaseDtls{get;set;}
        @AuraEnabled public Event_Tabs__c evntTab{get;set;}
        @AuraEnabled public List<WrapperPdfFloorplan> lstPdf{get;set;}
        @AuraEnabled public String expocadEventCode{get;set;}
    }
    public Class WrapperPdfFloorplan
    {
        @AuraEnabled public String pdfType {get;set;}
        @AuraEnabled public List<PDF_Floorplan__c> pdfFloorplan{get;set;}
    }
    
    @AuraEnabled
    public static String fetchManualPdfDetails(String linkEntId){
        system.debug('linkEntId ' +linkEntId);
        String pdfUrl;
        try{
            List<ContentDocumentLink> cntnDocLinkLst;
            if(String.isNotBlank(linkEntId)){
            cntnDocLinkLst = [SELECT Id, LinkedEntityId, ContentDocumentId, SystemModstamp, Visibility, ShareType FROM ContentDocumentLink where LinkedEntityId =: linkEntId Order By SystemModstamp desc ];
            system.debug('cntnDocLinkLst ' +cntnDocLinkLst);
            }
            
            if(cntnDocLinkLst.size()>0){
                List<ContentVersion> docmList = new List<ContentVersion>();
                    docmList = [select id, title FROM ContentVersion where contentdocumentid =: cntnDocLinkLst[0].ContentDocumentId and IsLatest = true];
                    if(docmList != null && docmList.size()>0)
                    pdfUrl = docmList[0].Id;
            }
        } catch(Exception e) {

            String stackTrace = e.getStackTraceString().substringBefore('\n');
            String mesg = String.isNotBlank(e.getMessage()) ? e.getMessage():''; 
            throw new AuraHandledException('Message='+mesg+'Stacktrace='+stackTrace);

        }
        return pdfUrl;
    }
}