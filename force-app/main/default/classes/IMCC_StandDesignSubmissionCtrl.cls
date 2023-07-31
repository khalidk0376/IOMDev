/**
* Created By       :   Girikon(Mukesh)
* Created On:          14 Feb, 2022
* Modified By      :   Girikon(Mukesh)
* Modified On      :   25 Feb, 2022
* @description     :   This class use to inser/update stand detail record. Also use to insert/update attachment and content document record.
                       IMCC_StandDesignSubmissionCtrl class use by imccStandDesignSteps, imccStandDesignStep1-7 and imccPublishStandSettings lightning component.
* Modified By      :   Girikon(Arushi - [IMCC-91])
* Modified On      :   25 Feb, 2022
* @description     :   As a Customer, I should be able to submit the stand design for my booths
                       , if I am decide to complete my stand submission process myself.
* Apex Class       :   IMCC_StandDesignSubmissionCtrl
* Apex Test Class  :   IMCC_StandDesignSubmissionCtrl_Test (90%)
**/
public without sharing class IMCC_StandDesignSubmissionCtrl {
    
    /**
     * @description get exhibitor detail
     * @param cmId
     * @param isCon
     * @return Map<String,Object>
     */
    @AuraEnabled
    public static Map<String,Object> getExhibitorDetail(String cmId,Boolean isCon){
        Map<String,Object> res = new Map<String,Object>();
        List<Contractor_Mapping__c> cmList = [SELECT Id,Is_Self_Managed__c,Contractor_Status__c, Approval_Date__c, Approved__c, Account__c, Contact__c,Contact__r.Name,Contact__r.Email,Contact__r.MobilePhone,Contact__r.Phone,Contact__r.Account.BillingCountryCode,Contact__r.Account.Name, Contractor_CEM__c,Edition__c,CreatedDate,TempContact__c, Account__r.Name,Edition__r.Name,Edition__r.Stand_Design_Completion_Due_Date__c,Edition__r.Stand_Setting__r.Manual_Instructions__c,
        Edition__r.Stand_Setting__r.Non_Complex_Stand_Instructions__c,Edition__r.Stand_Setting__r.Complex_Stand_Instructions__c,
        Edition__r.Stand_Setting__r.Hide_Stand_Design_Questions__c,Edition__r.Stand_Setting__r.Maximum_Hours__c,
        Edition__r.Stand_Setting__r.Allow_Stand_Design_Submission__c,Edition__r.Stand_Setting__r.Maximum_Size_of_Crew__c,
        Edition__r.Stand_Setting__r.Maximum_Stand_Height__c,
        Edition__r.Stand_Setting__r.Unit_of_measurement__c,
        Edition__r.Start_Date__c FROM Contractor_Mapping__c WHERE Id=:cmId WITH SECURITY_ENFORCED];
        res.put('cmList',cmList);

        List<Purchase_Data__c> listPD = [SELECT Id,Stand_Width__c,Stand_Length__c,Quantity_Area__c,Hall_Name__c,Booth_Number__c,Purchase_Status__c,Transaction_Status__c,Booth_Product_Type__c,Contact_Edition_Mapping__r.Account__r.Name FROM Purchase_Data__c WHERE Contractor_Mapping__c=:cmId WITH SECURITY_ENFORCED];
        res.put('listPD',listPD);
        
        List<Stand_Detail__c> sdList = [SELECT Id,Rejected_Steps__c,Stand_Detail_Status__c,Amount__c,Riggering_Options__c,Open_Side__c,Onsite_Health_and_Safety_Contact_Email__c,Onsite_Health_and_Safety_Contact_Name__c,Onsite_Health_and_Safety_Contact_Number__c,Current_Step__c,Stand_Height__c,Stand_Type__c,Are_you_aware_of_the_onsite_welfare__c,Does_the_contractor_hold_adequate_public__c,Is_the_appointed_contractor_travelling__c,Free_Text_for_the_team_to_customize_base__c,Are_any_other_hanging_structure__c,Type_of_rigging__c,Double_Decker__c,Is_Required_Document_Uploaded__c,Subcontractor_Company__c,Subcontractor_Name__c,Subcontractor_Email__c,Subcontractor_Number__c,Subcontractor_Country__c,Task_Activity__c,Sustainable_frame_and_fabric__c,Is_Complex_Structure__c,Including_rigging_in_the_design__c,MDF_Panels_or_similar__c,Raw_Materials__c,Reusable_Materials__c,Prefabricated_Offsite__c,LED_Lighting__c,Flame_retarded_material__c,Heavy_machinery_equipment_lift_require__c,Large_machinery_on_the_stand_area__c,Display_vehicles_requirement_on_stand__c,Incorporate_any_water_feature__c,Build_a_food_preparation_area__c,Dose_design_include_glass_walls__c,Over_600mm_within_the_design__c,Build_Construction_Time__c,Is_BuildUp_Equipment_Required__c,Is_Breakdown_Equipment_Required__c,Breakdown_Construction_Time__c,Build_Crew_Onsite_Arrival_Time__c,Breakdown_Crew_Onsite_Arrival_Time__c,Build_list_Stands_Numbers__c,Breakdown_Please_list_the_Stands_Numbers__c,Build_Size_of_Crew__c,Breakdown_Size_of_Crew__c,Build_crew_working_on_other_stands__c,Breakdown_crew_working_on_other_stands__c,Staircases_built_into_the_design__c,Require_high_value_product_storage__c,Equipment_Required_for_Build_up__c,Equipment_Required_for_Breakdown__c,Uploaded_Document_Description__c,Print_Name__c,Job_Title__c,Date__c,Signature_ContentId__c,CreatedById,Contractor_Mapping__c FROM Stand_Detail__c WHERE Contractor_Mapping__c=:cmId WITH SECURITY_ENFORCED];
        
        Boolean isBuildMyOwn = !cmList.isEmpty()?cmList[0].Is_Self_Managed__c:false;

        if(sdList.isEmpty() && (!isCon || isBuildMyOwn) ){
            Stand_Detail__c sd = new Stand_Detail__c(Contractor_Mapping__c=cmId); 
            sd.Stand_Detail_Status__c = 'Viewed';
            sd.Current_Step__c='1';
            sd.Edition__c = cmList[0].Edition__c;
            if(Schema.SObjectType.Stand_Detail__c.isCreateable()){
                Insert sd;
            }
            sdList.add(sd);

            Contractor_Mapping__c cm = new Contractor_Mapping__c(Id=cmId);
            cm.Contractor_Status__c = 'Viewed';
            cm.Latest_Stand_Detail__c = sd.Id;
            if(Schema.SObjectType.Contractor_Mapping__c.isUpdateable() && cmId!=null){
                Update cm;
            }
        }
        res.put('sdList',sdList);
        return res;
    }

    /**
     * @description get picklist options
     * @param objectName
     * @param fieldName
     * @return List<Option>
     */
    @AuraEnabled(cacheable = true)
    public static List<Option> getOptions(String objectName,String fieldName){
        Schema.SObjectType objSobjectType = Schema.getGlobalDescribe().get(objectName);
        Schema.DescribeSObjectResult objDescribeSobject = objSobjectType.getDescribe();
        Map<String, Schema.SObjectField> mapFields = objDescribeSobject.fields.getMap();
        List<Schema.PicklistEntry> lstPickListValues = mapFields.get(fieldName).getDescribe().getPickListValues();
        List<Option> options = new List<Option>();
        for (Schema.PicklistEntry objPickList : lstPickListValues) {
            if(objPickList.isActive()){
                options.add(new Option(objPickList.getLabel(),objPickList.getValue()));
            }
        }
        return options;
    }   

    /**
     * @description save Stand detail
     * @param standDetail
     */
    @AuraEnabled
    public static void saveStandDetail(Stand_Detail__c standDetail){
        String cmId = standDetail.Contractor_Mapping__c;
        if(standDetail.Stand_Detail_Status__c=='In Review' || standDetail.Stand_Detail_Status__c=='Permission to Build' || standDetail.Stand_Detail_Status__c=='Stand Design Resubmitted'){
            standDetail.Stand_Detail_Submitted_On__c = System.today();
        }
        
        if(standDetail.Id!=null)
        {
            List<Stand_Detail__c> fdl = [SELECT Current_Step__c,Stand_Detail_Status__c FROM Stand_Detail__c WHERE Id=:standDetail.Id WITH SECURITY_ENFORCED];
            //set previous "Current_Step__c" field value, if less than old value  
            if(!fdl.isEmpty()){
                Integer oldStep = Integer.valueOf(fdl[0].Current_Step__c);
                Integer newStep = Integer.valueOf(standDetail.Current_Step__c);
                if(oldStep > newStep){
                    standDetail.Current_Step__c = oldStep+'';
                }
            }
        }

        if(Schema.SObjectType.Stand_Detail__c.isCreateable() && Schema.SObjectType.Stand_Detail__c.isUpdateable()){            
            Upsert standDetail;
        }
        
        Contractor_Mapping__c cm = new Contractor_Mapping__c(Id=cmId);
        cm.Contractor_Status__c = standDetail.Stand_Detail_Status__c;
        if(Schema.SObjectType.Contractor_Mapping__c.isUpdateable()){
            Update cm;
        }
    }    

    /**
     * @description update manual as agreed
     * @param formDataId
     */
    @AuraEnabled
    public static void updateFormAgreed(String formDataId){                
        Form_Data__c fd = new Form_Data__c(Id=formDataId);
        fd.Is_Agreed__c = true;
        fd.Status1__c = 'Agreed';
        if(Schema.SObjectType.Form_Data__c.isUpdateable()){
            Update fd;
        }
        List<Form_Response_Entry__c> lst = [SELECT Id FROM Form_Response_Entry__c WHERE Form_Data__c=:formDataId WITH SECURITY_ENFORCED LIMIT 1];
         for (Form_Response_Entry__c fre : lst) {
            fre.Status__c = 'Submitted';
         }
         if(Schema.SObjectType.Form_Response_Entry__c.isUpdateable() && !lst.isEmpty()){
            Update lst;
        }
    }

    /**
     * @description get status of manual
     * @param condition
     * @return List<SObject>
     */
    @AuraEnabled
    public static List<SObject> getManualStatus(String condition){        
        return Database.query('SELECT Id,Is_Viewed__c,Is_Agreed__c FROM Form_Data__c WHERE '+condition+' WITH SECURITY_ENFORCED');
    }

    /**
     * @description get permissions of manual
     * @param eventCode
     * @param accountId
     * @param contId
     * @return Map<String,Object>
     */
    @AuraEnabled
    public static Map<String,Object> getManualPermission(String eventCode, String accountId,String contId){
        list<Forms_Permission__c> formPermManLst = new list<Forms_Permission__c>();
        //User userObj  = [SELECT Name,ContactId from User where Id =: userId WITH SECURITY_ENFORCED];
        List<Contact_Edition_Mapping__c> conEdMapLst = [SELECT Id,Primary_Contact_Edition_Mapping__c,Contact__c,Access_Type__c FROM Contact_Edition_Mapping__c WHERE 
            Contact__c =: contId AND Account__c =: accountId 
            AND Relationship_Status__c = 'Active' AND Edition__r.Edition_Code__c =: eventCode 
            WITH SECURITY_ENFORCED];

        List<String> accessType = new List<String>();
        
        Map<String,Object> res = new Map<String,Object>();

        if(!conEdMapLst.isEmpty()){
            accessType.add(conEdMapLst[0].Access_Type__c);
            List<String> cemIds = new List<String>();
            cemIds.add(conEdMapLst[0].Id);
            
            if(String.isNotBlank(conEdMapLst[0].Primary_Contact_Edition_Mapping__c)){
                cemIds.add(conEdMapLst[0].Primary_Contact_Edition_Mapping__c);
                List<Contact_Edition_Mapping__c> conEdMapLst2 = [SELECT Id,Access_Type__c FROM Contact_Edition_Mapping__c WHERE 
                Id =: conEdMapLst[0].Primary_Contact_Edition_Mapping__c WITH SECURITY_ENFORCED];
                if(!conEdMapLst2.isEmpty()){
                    accessType.add(conEdMapLst2[0].Access_Type__c);
                }
            }

            res.put('cemIds',cemIds);
            res.put('conEdMapId', conEdMapLst[0].Id);
            res.put('contactId', conEdMapLst[0].Contact__c);
            formPermManLst = [SELECT Id,Form_Allocation__r.Form_Heading__c,
                Tab_User_Type__r.User_Type__c FROM Forms_Permission__c 
                WHERE Form_Allocation__r.Form_Heading__c='Mandatory' 
                AND Form_Allocation__r.Feature_Category__c='Manual' 
                AND Form_Allocation__r.Form_Status__c='Visible' 
                AND Is_Active__c=true
                AND Tab_User_Type__r.User_Type__c IN:accessType WITH SECURITY_ENFORCED];
            res.put('manualPermission', formPermManLst);
        }
        return res;
    }

    /**
     * @description update document name
     * @param docId
     * @param fileName
     * @param parentId
     * @return List<ContentDocumentLink>
     */
    @AuraEnabled
    public static List<ContentDocumentLink> updateDocumentName(String docId,String fileName,String parentId){
        
        String likeStr = String.escapeSingleQuotes(fileName)+'%';
        List<ContentDocumentLink> cdl = [SELECT ContentDocument.Title FROM ContentDocumentLink WHERE ContentDocument.Title Like:likeStr AND LinkedEntityId=:parentId WITH SECURITY_ENFORCED ORDER BY SystemModstamp DESC LIMIT 1];
        
        if(cdl.isEmpty()){
            fileName = fileName + ' - 1';
        }
        else{
            List<String> names = cdl[0].ContentDocument.Title.split('-');
            if(names.size()>1){
                Integer counter = Integer.valueOf(names[names.size()-1].trim());
                counter = counter + 1;
                fileName = fileName + ' - '+counter;
            }
        }

        ContentDocument cd = new ContentDocument(Id=docId);
        cd.Title = fileName;
        if(Schema.SObjectType.ContentDocument.isUpdateable()){
            Update cd;
        }
        return getFiles(parentId);
    }

    /**
     * @description get files
     * @param parentId
     * @return List<ContentDocumentLink>
     */
    @AuraEnabled
    public static List<ContentDocumentLink> getFiles(String parentId){
        return Database.query('SELECT ContentDocumentId,ContentDocument.LatestPublishedVersionId,format(SystemModstamp),ContentDocument.Title,ContentDocument.FileType FROM ContentDocumentLink WHERE LinkedEntityId=:parentId WITH SECURITY_ENFORCED ORDER BY SystemModstamp DESC');
    }

    /**
     * @description delete file
     * @param documentId
     * @param parentId
     * @return List<ContentDocumentLink>
     */
    @AuraEnabled
    public static List<ContentDocumentLink> deleteFile(String documentId,String parentId){
        delete([SELECT Id FROM ContentDocument WHERE Id=:documentId WITH SECURITY_ENFORCED]);        
        return getFiles(parentId);
    }

    /**
     * @description save Signature
     * @param contentVersionData
     * @param recordId
     * @return String
     */
    @AuraEnabled
    public static String saveSignature(String contentVersionData, Id recordId){
        Attachment att = new Attachment();
        try{
            /*
                Create Content Version Object and then after content document link
            */
            List<Attachment> attList = [SELECT Body FROM Attachment WHERE Name='Signature.png' AND ParentId=:recordId WITH SECURITY_ENFORCED LIMIT 1];            
            if(attList.isEmpty()){
                att = new Attachment();
                att.Body = EncodingUtil.base64Decode(ContentVersionData);
                att.Name = 'Signature.png';
                att.ParentId = recordId;
            }
            else{
                att = attList[0];
                att.Body = EncodingUtil.base64Decode(ContentVersionData);
            }        

            if(Schema.SObjectType.Stand_Detail__c.isCreateable() && Schema.SObjectType.Stand_Detail__c.isUpdateable()){
                Upsert att;
            }

            Stand_Detail__c sd = new Stand_Detail__c(Id=recordId);
            sd.Signature_ContentId__c = att.Id;
            if(Schema.SObjectType.Stand_Detail__c.isUpdateable()){
                update sd;
            }
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage()+','+e.getLineNumber());
        }
        return att.Id;
    }
    
    /**
     * @description to publish stand settings
     * @param setting
     */
    @AuraEnabled
    public static void publishStandSettings(Stand_Setting__c setting){
        if(Schema.SObjectType.Stand_Setting__c.isUpdateable()){
            Update setting;
        }
    }

    /**
     * @description get Stand File Type
     * @param standSettingId
     * @param type
     * @return List<Stand_File_Type__c>
     */
    @AuraEnabled
    public static List<Stand_File_Type__c> getStandFileTypes(String standSettingId,String type){
        List<Stand_File_Type__c> sfl; 
        if(type!=''){
            sfl = Database.query('SELECT Name,Stand_Setting__r.Status__c,Type__c,Stand_Setting__r.Name FROM Stand_File_Type__c WHERE Type__c includes(\''+String.escapeSingleQuotes(type)+'\') AND Stand_Setting__c=:standSettingId WITH SECURITY_ENFORCED');
        }
        else{
            sfl = Database.query('SELECT Name,Stand_Setting__r.Status__c,Type__c,Stand_Setting__r.Allow_Stand_Design_Submission__c, Stand_Setting__r.Name FROM Stand_File_Type__c WHERE Stand_Setting__c=:standSettingId WITH SECURITY_ENFORCED');
        }
        return sfl;
    }

    /**
     * @description delete Stand File Type
     * @param id
     */
    @AuraEnabled
    public static void deleteStandFileTypes(String id){
        if(Schema.SObjectType.Stand_File_Type__c.isDeletable()){
            delete([SELECT Id FROM Stand_File_Type__c WHERE Id=:id WITH SECURITY_ENFORCED]);
        }
    }


    /**@description picklist option*/
    public class Option{
        @AuraEnabled public String label;
        @AuraEnabled public String value;

        /**
         * @description picklist option Constructor
         * @param label
         * @param value
         */
        public Option(String label,String value){
            this.label = label;
            this.value = value;
        }
    }    
}