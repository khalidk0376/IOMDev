/**
* File         :   IMCC_AssetTriggerHandler 
* Project      :   IMCC
* Created Date :   16th Feb 2022
* Created By   :   Girikon(Deepak)
* Test Class   :   IMCC_AssetTriggerHandler_Test(97%)
* Coverage     :   97%
***********************************************************************************************
* @description : Class will be helper for Asset Trigger. It will create or Update Contact Edition Mapping and Purchase Data For Asset.
***********************************************************************************************
* Modification log :
* Modified By      :   Girikon(Deepak, Arushi[IMCC-4623]),[Aishwarya 14 March 2023 IMCC-5070]
* Modified On      :   13 Sept 2022
*/
public with sharing class IMCC_AssetTriggerHandler {
    
    public static boolean isTestNegative = false;

    /**
    * @description this method will Create or Update Contact Edition Mapping and Purchase Data For Asset
    * @param newAssetList
    * @param oldMapAsset
    * @param isUpdate
    */
    public static void createConEdiAndPurcData(List<Asset> newAssetList, Map<Id,Asset> oldMapAsset, Boolean isUpdate){
        Set<Id> setAccountIds = new Set<Id>();
        Set<Id> setContactIds = new Set<Id>();
        Set<Id> setEditionIds = new Set<Id>();
        Set<Id> setParentAssetIds = new Set<Id>();
        List<Asset> listAsset = new List<Asset>();
        Map<Id,Asset> mapAsset = new Map<Id,Asset>();
        Map<Id,Asset> mapParentAsset = new Map<Id,Asset>();
        Set<Id> pdIds = new Set<Id>();
        Map<Id,Purchase_Data__c> mapPDUpdate = new Map<Id,Purchase_Data__c>();
        List<Purchase_Data__c> listPDInsert = new List<Purchase_Data__c>();
        Map<Id,Asset> mapAssetUpdate = new Map<Id,Asset>();
        Map<String,Contact_Edition_Mapping__c> mapCEMUpsert = new Map<String,Contact_Edition_Mapping__c>();
        Map<String,Map<String,Purchase_Data__c>> mapAccConEdiKeyMapPDUpsert = new Map<String,Map<String,Purchase_Data__c>>();Map<String,Map<String,Purchase_Data__c>> mapAccConEdiKeyMapPD = new Map<String,Map<String,Purchase_Data__c>>();
        Map<String,Contact_Edition_Mapping__c> mapAccConEdiKeyCEM = new Map<String,Contact_Edition_Mapping__c>();

        for(Asset asset : newAssetList){
            if(asset.AccountId != null && asset.ContactId != null && asset.Edition__c != null && String.isNotBlank(asset.Source_Org__c) && (!isUpdate || (asset.Purchase_Data__c == oldMapAsset.get(asset.Id).Purchase_Data__c && asset.Progressing_Status__c == 'In Progress')))
            {
                setAccountIds.add(asset.AccountId);
                setContactIds.add(asset.ContactId);
                setEditionIds.add(asset.Edition__c);
                listAsset.add(asset);
                mapAsset.put(asset.Id,asset);
                if(String.isNotBlank(asset.ParentId)){setParentAssetIds.add(asset.ParentId);}
                if(String.isNotBlank(asset.Purchase_Data__c)){pdIds.add(asset.Purchase_Data__c);}
            }
        }

        try{
            //map of parent Asset
            if(!setParentAssetIds.isEmpty()){
                mapParentAsset = new Map<Id,Asset>([SELECT Id,AccountId,User_Type1__c,Purchase_Data__c,Purchase_Data__r.Contact_Edition_Mapping__c,Parent.Purchase_Data__c,Parent.Purchase_Data__r.Contact_Edition_Mapping__c FROM Asset WHERE Id IN:setParentAssetIds WITH SECURITY_ENFORCED]);
            }
            //map of Existing CEM
            Map<Id,Contact_Edition_Mapping__c> mapExistingCEM = new Map<Id,Contact_Edition_Mapping__c>([SELECT Id,Account__c,Contact__c,Edition__c,Primary_Contact_Edition_Mapping__c,isSecondary__c  FROM Contact_Edition_Mapping__c WHERE Contact__c IN:setContactIds AND Account__c IN:setAccountIds AND Edition__c IN:setEditionIds WITH SECURITY_ENFORCED]);

            for(Contact_Edition_Mapping__c cem : mapExistingCEM.values()){
                String key = cem.Account__c + '_' + cem.Contact__c + '_' + cem.Edition__c;
                mapAccConEdiKeyCEM.put(key, cem);
            }
            //map of Existing PD
            List<Purchase_Data__c> listExistingPD = [SELECT Id,Account__c,Booth_Number__c,Booth_Product_Type__c,Contact__c,Contact_Edition_Mapping__c,Edition__c,Hall_Name__c,Purchase_Status__c,Quantity_Area__c,Source_Org__c,Transaction_Status__c,User_Type__c,Asset__c FROM Purchase_Data__c WHERE Contact__c IN:setContactIds AND Account__c IN:setAccountIds AND Edition__c IN:setEditionIds WITH SECURITY_ENFORCED];
            //map of PD of Asset PD
            Map<Id,Purchase_Data__c> mapPD2 = new Map<Id,Purchase_Data__c>([SELECT Id,Contact_Edition_Mapping__c FROM Purchase_Data__c WHERE Id IN:pdIds WITH SECURITY_ENFORCED]);

            for(Purchase_Data__c pd : listExistingPD){
                String key = pd.Account__c + '_' + pd.Contact__c + '_' + pd.Edition__c;
                Map<String,Purchase_Data__c> mapPD = (mapAccConEdiKeyMapPD.containsKey(key)?mapAccConEdiKeyMapPD.get(key):(new Map<String,Purchase_Data__c>()));
                String keyBoothNumOrProdType = (String.isNotBlank(pd.Booth_Number__c)?pd.Booth_Number__c:('Online_'+pd.Booth_Product_Type__c));
                mapPD.put(keyBoothNumOrProdType,pd); //map of Booth NUmber and PD
                mapAccConEdiKeyMapPD.put(key, mapPD); //map of string(AccId_ContactId_EditionId) and map(map of Booth NUmber and PD)
            }
            
            for(Asset ast : listAsset){
                String key = ast.AccountId + '_' + ast.ContactId + '_' + ast.Edition__c;
                String status = 'Active';
                if((String.isNotBlank(ast.Booth_Number__c) && (ast.Booth_Status__c != 'Rented' || ast.Status != 'Purchased')) || (String.isBlank(ast.Booth_Number__c) && ast.Status != 'Purchased')){
                    status = 'Inactive'; 
                }
                Contact_Edition_Mapping__c cem = (mapAccConEdiKeyCEM.containsKey(key)?mapAccConEdiKeyCEM.get(key):(new Contact_Edition_Mapping__c()));
                if(!mapAccConEdiKeyCEM.containsKey(key)){
                    cem.Contact__c = ast.ContactId;
                    cem.Account__c = ast.AccountId;
                }

                if(String.isNotBlank(ast.Purchase_Data__c)){
                    Purchase_Data__c pdExisting = mapPD2.get(ast.Purchase_Data__c);
                    if(String.isBlank(cem.Id) || (String.isNotBlank(cem.Id) && cem.Id != pdExisting.Contact_Edition_Mapping__c)){
                        cem.Primary_Contact_Edition_Mapping__c = pdExisting.Contact_Edition_Mapping__c;
                        cem.isSecondary__c = true;
                    }
                }
                
                cem.Edition__c = ast.Edition__c;
                cem.Access_Type__c = ast.User_Type1__c;
                cem.Relationship_Status__c = 'Active';
                if(String.isNotBlank(ast.ParentId)){
                    Asset parentAsset = mapParentAsset.get(ast.ParentId);
                    cem.Parent_Account__c = parentAsset.AccountId;
                    cem.Parent_Type__c = parentAsset.User_Type1__c;
                    if(cem.Id != parentAsset.Purchase_Data__r.Contact_Edition_Mapping__c){cem.Parent_Contact_Edition_Mapping__c = parentAsset.Purchase_Data__r.Contact_Edition_Mapping__c;}
                    if(parentAsset.ParentId != null && parentAsset.Parent.Purchase_Data__c != null && parentAsset.Parent.Purchase_Data__r.Contact_Edition_Mapping__c != null){
                        if(cem.Id != parentAsset.Parent.Purchase_Data__r.Contact_Edition_Mapping__c){cem.Grand_Parent_Contact_Edition_Mapping__c = parentAsset.Parent.Purchase_Data__r.Contact_Edition_Mapping__c;}
                    }
                }

                if(status != 'Inactive'){mapCEMUpsert.put(key, cem);}


                Map<String,Purchase_Data__c> mapPD = (mapAccConEdiKeyMapPD.containsKey(key)?mapAccConEdiKeyMapPD.get(key):(new Map<String,Purchase_Data__c>())); 
                String keyBoothNumOrProdType = (String.isNotBlank(ast.Booth_Number__c)?ast.Booth_Number__c:('Online_'+ast.Booth_Product_Type1__c));

                Purchase_Data__c pd = (String.isBlank(ast.Purchase_Data__c)?(mapPD.containsKey(keyBoothNumOrProdType)?mapPD.get(keyBoothNumOrProdType):(new Purchase_Data__c())):(new Purchase_Data__c(Id=ast.Purchase_Data__c)));
                pd.Account__c = ast.AccountId;
                if(String.isBlank(pd.Id)){
                    pd.Contact__c = ast.ContactId;
                }
                pd.User_Type__c = ast.User_Type1__c;
                pd.Quantity_Area__c = ast.Quantity;
                pd.Booth_Number__c = ast.Booth_Number__c;
                pd.Source_Org__c = ast.Source_Org__c;
                pd.Booth_Product_Type__c = ast.Booth_Product_Type1__c;
                pd.Source_Transaction_ID__c = ast.Source_Id__c;
                pd.Edition__c = ast.Edition__c;
                pd.Hall_Name__c = ast.Booth_Hall__c;
                pd.Booth_Pavillion__c = ast.Booth_Pavillion__c;
                pd.Booth_Show_in_Show__c = ast.Booth_Show_in_Show__c;
                pd.Purchase_Status__c = status;
                pd.Transaction_Status__c = (status=='Inactive'?null:status);
                pd.Asset__c = ast.Id;
                pd.Unit_of_Measurement__c = ast.Unit_of_Measurement__c;
                pd.Booth_Dimension__c = ast.Booth_Dimension__c;
                pd.Exhibiting_Name__c = ast.Exhibiting_Name__c;
                if(String.isNotBlank(ast.Length__c)){pd.Stand_Length__c = Decimal.valueOf(ast.Length__c);}
                if(String.isNotBlank(ast.Width__c)){pd.Stand_Width__c = Decimal.valueOf(ast.Width__c);}
                if(String.isBlank(ast.Booth_Dimension__c) && String.isNotBlank(ast.Length__c) && String.isNotBlank(ast.Width__c)){pd.Booth_Dimension__c = ast.Length__c + 'x'+ast.Width__c;}
                
                if(String.isNotBlank(ast.ParentId)){
                    Asset parentAsset2 = mapParentAsset.get(ast.ParentId);
                    if(pd.Id != parentAsset2.Purchase_Data__c){pd.Parent_Purchase_Data__c = parentAsset2.Purchase_Data__c;}
                    if(parentAsset2.ParentId != null && parentAsset2.Parent.Purchase_Data__c!= null){
                        if(pd.Id != parentAsset2.Parent.Purchase_Data__c){pd.Grand_Parent_Purchase_Data__c = parentAsset2.Parent.Purchase_Data__c;}
                    }
                }
                
                if((status != 'Inactive' && String.isBlank(pd.Id)) || String.isNotBlank(pd.Id)){mapPD.put(keyBoothNumOrProdType, pd);}
                mapAccConEdiKeyMapPDUpsert.put(key, mapPD);
                mapAccConEdiKeyMapPD.put(key, mapPD);
            }

            //Upsert Contact_Edition_Mapping__c
            List<Contact_Edition_Mapping__c> listCEMUpsert = mapCEMUpsert.values();
            if(!listCEMUpsert.isEmpty() && Schema.sObjectType.Contact_Edition_Mapping__c.isCreateable() && Schema.sObjectType.Contact_Edition_Mapping__c.isUpdateable()){
                upsert listCEMUpsert;
                
                for(Contact_Edition_Mapping__c cem : listCEMUpsert){
                    Contact_Edition_Mapping__c tempCEM = (mapExistingCEM.containsKey(cem.Id)?mapExistingCEM.get(cem.Id):cem);
                    String key = tempCEM.Account__c + '_' + tempCEM.Contact__c + '_' + tempCEM.Edition__c;
                    mapAccConEdiKeyCEM.put(key, cem);
                }
            }
            
            //Upsert Purchase_Data__c
            for(String key : mapAccConEdiKeyMapPDUpsert.keySet()){
                if(mapAccConEdiKeyCEM.containsKey(key)){
                    Contact_Edition_Mapping__c cem = mapAccConEdiKeyCEM.get(key);
                    Map<String,Purchase_Data__c> mapPD = mapAccConEdiKeyMapPDUpsert.get(key);
                    for(String keyBoothNumOrProdType : mapPD.keySet()){
                        Purchase_Data__c pd = mapPD.get(keyBoothNumOrProdType);
                        if(cem.isSecondary__c == false){
                            pd.Contact_Edition_Mapping__c = cem.Id;
                        }
                        if(String.isNotBlank(pd.Id)){mapPDUpdate.put(pd.Id, pd);}
                        if(String.isBlank(pd.Id)){listPDInsert.add(pd);}
                    }
                }
            }
            
            List<Purchase_Data__c> listPDChanged = new List<Purchase_Data__c>();
            if(!mapPDUpdate.isEmpty() && Schema.sObjectType.Purchase_Data__c.isUpdateable()){
                update mapPDUpdate.values();
                listPDChanged.addAll(mapPDUpdate.values());
            }
            if(!listPDInsert.isEmpty() && Schema.sObjectType.Purchase_Data__c.isCreateable()){
                insert listPDInsert;
                listPDChanged.addAll(listPDInsert);
            }
            for(Purchase_Data__c pd : listPDChanged){
                if(mapAsset.containsKey(pd.Asset__c)){
                    Asset ast = mapAsset.get(pd.Asset__c);
                    if(ast.Purchase_Data__c != pd.Id){mapAssetUpdate.put(pd.Asset__c,new Asset(Id=pd.Asset__c,Purchase_Data__c=pd.Id,Progressing_Status__c = 'Success',Progressing_Error_Message__c = null));}
                    else{mapAssetUpdate.put(pd.Asset__c,new Asset(Id=pd.Asset__c,Progressing_Status__c = 'Success',Progressing_Error_Message__c = null));}
                }
            }
            if(!mapAssetUpdate.isEmpty() && Schema.sObjectType.Asset.isUpdateable()){
                update mapAssetUpdate.values();
            }
        }
        catch(Exception ex){
            for(Asset ast : listAsset){
                mapAssetUpdate.put(ast.Id,new Asset(Id=ast.Id,Progressing_Status__c = 'Error',Progressing_Error_Message__c = ex.getMessage()));
            }
            if(!mapAssetUpdate.isEmpty() && Schema.sObjectType.Asset.isUpdateable()){update mapAssetUpdate.values();}
            HandleAllCustomException.logException(ex,'','Asset Trigger');
        }
    }

    /**
    * @description this method will Create API Transaction Records For Processing
    * @param newAssetList
    * @param oldMapAsset
    * @param isUpdate
    */
    public static void createAPISynRecords(List<Asset> newAssetList, Map<Id,Asset> oldMapAsset, Boolean isUpdate){
        List<Asset> listAsset = new List<Asset>();
        Map<Id,Asset> mapAsset = new Map<Id,Asset>();
        for(Asset asset : newAssetList){
            if(!System.isBatch() && asset.AccountId != null && asset.ContactId != null && asset.Edition__c != null && String.isNotBlank(asset.Source_Org__c) && String.isNotBlank(asset.Source_Id__c) && (!isUpdate || asset.Purchase_Data__c == oldMapAsset.get(asset.Id).Purchase_Data__c))
            {
                listAsset.add(asset); //list of Asset when not processed with Batch and all red fields are present
                if(isUpdate){mapAsset.put(asset.Id,oldMapAsset.get(asset.Id));}//if Asset is update
            }
        }

        if(!listAsset.isEmpty()){
            //set wrapper data
            IMCC_CreateApiSyncRecords.IMCC_ApiSyncRecordsWrapper obj = new IMCC_CreateApiSyncRecords.IMCC_ApiSyncRecordsWrapper();
            obj.Type = (isUpdate?'Update':'Create');
            obj.startedFrom = 'Asset';
            obj.requestType = 'Asynchronous'; 
            obj.itemType = 'Purchase Data'; 
            obj.apiCallType = 'NA';
            obj.listSObject = listAsset;
            obj.mapSObjectOld = mapAsset;
            obj.transactionStatus = 'Queued';
            obj.itemStatus = 'Queued';
            IMCC_CreateApiSyncRecords.insertAllAPISyncItem(obj); // IMCC_CreateApiSyncRecords class method
        }
    }

    /**
    * @description   This method is used for Processing Asset
    * @param  apiItem IMCC API Synchronization Item
    * @return  String Status
    */
    public static String createConEdiAndPurcData(IMCC_API_Synchronization_Item__c apiItem) 
    {
        Savepoint sp;
        String calloutStatus = 'Processing';
        
        Id assetId = apiItem.Asset__c;
        System.debug(LoggingLevel.DEBUG, assetId);
        
        List<Contact_Edition_Mapping__c> listCEMUpsert = new List<Contact_Edition_Mapping__c>();
        List<Contact_Edition_Mapping__c> listCEMUpsert2 = new List<Contact_Edition_Mapping__c>();
        Map<String,Purchase_Data__c> mapPDUpsert = new Map<String,Purchase_Data__c>();

        //Asset query 
        String assetQuery = 'Select '+String.escapeSingleQuotes(dynamicGetAllFieldsQuery('Asset'))+ ' From Asset Where Id=:assetId';

        List<Asset> newAssetList = Database.query(assetQuery);
        Asset asset = (!newAssetList.isEmpty()?newAssetList.get(0):new Asset());

        try{
            List<Asset> listParetAsset = new List<Asset>();
            //list of Parent Asset
            if(String.isNotBlank(asset.ParentId)){
                listParetAsset = [SELECT Id,AccountId,User_Type1__c,Purchase_Data__c,Purchase_Data__r.Contact_Edition_Mapping__c,Parent.Purchase_Data__c,Parent.Purchase_Data__r.Contact_Edition_Mapping__c FROM Asset WHERE Id=:asset.ParentId WITH SECURITY_ENFORCED];
            }
            List<Contact_Edition_Mapping__c> listExistingCEM;
            List<Contact_Edition_Mapping__c> listExistingOpeartionCEM;
            //list of existing CEM based on where clause
            if(asset.ContactId !=null || (asset.Operations_Contact__c != null && asset.ContactId == asset.Operations_Contact__c)){
                listExistingCEM = [SELECT Id,Account__c,Contact__c,Edition__c,Primary_Contact_Edition_Mapping__c,isSecondary__c,Role__c FROM Contact_Edition_Mapping__c WHERE Contact__c =:asset.ContactId AND Account__c =:asset.AccountId AND Edition__c =:asset.Edition__c AND Relationship_Status__c='Active' WITH SECURITY_ENFORCED];
                if(listExistingCEM.isEmpty()){
                    listExistingCEM = [SELECT Id,Account__c,Contact__c,Edition__c,Primary_Contact_Edition_Mapping__c,isSecondary__c,Role__c FROM Contact_Edition_Mapping__c WHERE Contact__c =:asset.ContactId AND Account__c =:asset.AccountId AND Edition__c =:asset.Edition__c AND Relationship_Status__c='Inactive' WITH SECURITY_ENFORCED];
                }
            }
            // IMCC-5070 Querying CEM on basis of Asset's Operation Contact
            if(asset.Operations_Contact__c != null && asset.ContactId != asset.Operations_Contact__c){
                listExistingOpeartionCEM = [SELECT Id,Account__c,Contact__c,Edition__c,Primary_Contact_Edition_Mapping__c,isSecondary__c,Role__c FROM Contact_Edition_Mapping__c WHERE Contact__c =:asset.Operations_Contact__c AND Account__c =:asset.AccountId AND Edition__c =:asset.Edition__c AND Relationship_Status__c='Active' WITH SECURITY_ENFORCED];
                if(listExistingOpeartionCEM.isEmpty()){
                    listExistingOpeartionCEM = [SELECT Id,Account__c,Contact__c,Edition__c,Primary_Contact_Edition_Mapping__c,isSecondary__c,Role__c FROM Contact_Edition_Mapping__c WHERE Contact__c =:asset.Operations_Contact__c AND Account__c =:asset.AccountId AND Edition__c =:asset.Edition__c AND Relationship_Status__c='Inactive' WITH SECURITY_ENFORCED];
                }
            }
            //list of existing PD based on where clause
            List<Purchase_Data__c> listExistingPD = [SELECT Id,Account__c,Booth_Number__c,Booth_Product_Type__c,Contact__c,Contact_Edition_Mapping__c,Edition__c,Hall_Name__c,Purchase_Status__c,Quantity_Area__c,Source_Org__c,Transaction_Status__c,User_Type__c,Asset__c FROM Purchase_Data__c WHERE Contact__c =:asset.ContactId AND Account__c =:asset.AccountId AND Edition__c =:asset.Edition__c WITH SECURITY_ENFORCED];
            //list of PD of asset purchase data
            List<Purchase_Data__c> listPD2 = [SELECT Id,Contact_Edition_Mapping__c FROM Purchase_Data__c WHERE Id =:asset.Purchase_Data__c WITH SECURITY_ENFORCED];

            Map<String,Purchase_Data__c> mapPDExisting = new Map<String,Purchase_Data__c>();
            for(Purchase_Data__c pd : listExistingPD){
                String keyBoothNumOrProdType = (String.isNotBlank(pd.Booth_Number__c)?pd.Booth_Number__c:('Online_'+pd.Booth_Product_Type__c));
                mapPDExisting.put(keyBoothNumOrProdType,pd); //map of existing PD with Booth Number as key
            }

            String status = 'Active';
            if((String.isNotBlank(asset.Booth_Number__c) && (asset.Booth_Status__c != 'Rented' || asset.Status != 'Purchased')) || (String.isBlank(asset.Booth_Number__c) && asset.Status != 'Purchased')){
                status = 'Inactive';
            }
            //update the ExistingCEM
            Contact_Edition_Mapping__c cem = (!listExistingCEM.isEmpty()?listExistingCEM.get(0):(new Contact_Edition_Mapping__c()));
            if(String.isBlank(cem.Id) && !isTestNegative){
                cem.Contact__c = asset.ContactId;
                cem.Account__c = asset.AccountId;
                cem.Role__c = 'Team Member';
            }

            if(String.isNotBlank(asset.Purchase_Data__c)){
                Purchase_Data__c pdExisting = listPD2.get(0);
                if(String.isBlank(cem.Id) || (String.isNotBlank(cem.Id) && cem.Id != pdExisting.Contact_Edition_Mapping__c)){
                    cem.Primary_Contact_Edition_Mapping__c = pdExisting.Contact_Edition_Mapping__c;
                    cem.isSecondary__c = true;
                }
            }
            
            cem.Edition__c = asset.Edition__c;
            if(asset.User_Type1__c == 'Co-Exhibitor'){
                cem.Role__c = 'Platform Admin';
            }    
            cem.Access_Type__c = asset.User_Type1__c;
            cem.Relationship_Status__c = 'Active';
            if(String.isNotBlank(asset.ParentId)){
                Asset parentAsset = listParetAsset.get(0);
                cem.Parent_Account__c = parentAsset.AccountId;
                cem.Parent_Type__c = parentAsset.User_Type1__c;
                if(cem.Id != parentAsset.Purchase_Data__r.Contact_Edition_Mapping__c){
                    cem.Parent_Contact_Edition_Mapping__c = parentAsset.Purchase_Data__r.Contact_Edition_Mapping__c;
                }
                if(parentAsset.ParentId != null && parentAsset.Parent.Purchase_Data__c != null && parentAsset.Parent.Purchase_Data__r.Contact_Edition_Mapping__c != null){
                    if(cem.Id != parentAsset.Parent.Purchase_Data__r.Contact_Edition_Mapping__c){cem.Grand_Parent_Contact_Edition_Mapping__c = parentAsset.Parent.Purchase_Data__r.Contact_Edition_Mapping__c;}
                }
            }
            if(status != 'Inactive'){listCEMUpsert.add(cem);}
            
            String keyBoothNumOrProdType = (String.isNotBlank(asset.Booth_Number__c)?asset.Booth_Number__c:('Online_'+asset.Booth_Product_Type1__c));
            //set asset data to insert new PD 
            Purchase_Data__c pd = (String.isBlank(asset.Purchase_Data__c)?(mapPDExisting.containsKey(keyBoothNumOrProdType)?mapPDExisting.get(keyBoothNumOrProdType):(new Purchase_Data__c())):(new Purchase_Data__c(Id=asset.Purchase_Data__c)));
            pd.Account__c = asset.AccountId;
            if(String.isBlank(pd.Id)){
                pd.Contact__c = asset.ContactId;
            }
            pd.User_Type__c = asset.User_Type1__c;
            pd.Quantity_Area__c = asset.Quantity;
            pd.Booth_Number__c = asset.Booth_Number__c;
            pd.Source_Org__c = asset.Source_Org__c;
            pd.Booth_Product_Type__c = asset.Booth_Product_Type1__c;
            pd.Source_Transaction_ID__c = asset.Source_Id__c;
            pd.Edition__c = asset.Edition__c;
            pd.Hall_Name__c = asset.Booth_Hall__c;
            pd.Booth_Pavillion__c = asset.Booth_Pavillion__c;
            pd.Booth_Show_in_Show__c = asset.Booth_Show_in_Show__c;
            pd.Purchase_Status__c = status;
            pd.Transaction_Status__c = (status=='Inactive'?null:status);
            pd.Asset__c = asset.Id;
            pd.Unit_of_Measurement__c = asset.Unit_of_Measurement__c;
            pd.Booth_Dimension__c = asset.Booth_Dimension__c;
            pd.Exhibiting_Name__c = asset.Exhibiting_Name__c;
            if(String.isNotBlank(asset.Length__c)){pd.Stand_Length__c = Decimal.valueOf(asset.Length__c);}
            if(String.isNotBlank(asset.Width__c)){pd.Stand_Width__c = Decimal.valueOf(asset.Width__c);}
            if(String.isBlank(asset.Booth_Dimension__c) && String.isNotBlank(asset.Length__c) && String.isNotBlank(asset.Width__c)){pd.Booth_Dimension__c = asset.Length__c + 'x'+asset.Width__c;}
            
            if(String.isNotBlank(asset.ParentId)){
                Asset parentAsset2 = listParetAsset.get(0);
                if(pd.Id != parentAsset2.Purchase_Data__c){pd.Parent_Purchase_Data__c = parentAsset2.Purchase_Data__c;}
                if(parentAsset2.ParentId != null && parentAsset2.Parent.Purchase_Data__c!= null){
                    if(pd.Id != parentAsset2.Parent.Purchase_Data__c){pd.Grand_Parent_Purchase_Data__c = parentAsset2.Parent.Purchase_Data__c;}
                }
            }
            
            if((status != 'Inactive' && String.isBlank(pd.Id)) || String.isNotBlank(pd.Id)){mapPDUpsert.put(keyBoothNumOrProdType, pd);}
            mapPDExisting.put(keyBoothNumOrProdType, pd);

            sp = Database.setSavepoint();
            Boolean isErrorInCEM = false;
            //Upsert Contact_Edition_Mapping__c
            if(!listCEMUpsert.isEmpty() && Schema.sObjectType.Contact_Edition_Mapping__c.isCreateable() && Schema.sObjectType.Contact_Edition_Mapping__c.isUpdateable()){
                upsert listCEMUpsert;
            }
            // IMCC-5070
            if(asset.Operations_Contact__c !=null && asset.ContactId != asset.Operations_Contact__c){
                Contact_Edition_Mapping__c cemOP = (!listExistingOpeartionCEM.isEmpty()?listExistingOpeartionCEM.get(0):(new Contact_Edition_Mapping__c()));
                if(String.isBlank(cemOP.Id)){
                    cemOP.Contact__c = asset.Operations_Contact__c;
                    cemOP.Account__c = asset.AccountId;
                }
                cemOP.Edition__c = asset.Edition__c;
                cemOP.Access_Type__c = asset.User_Type1__c;
                cemOP.Relationship_Status__c = 'Active';
                cemOP.Role__c = 'Platform Admin'; // assigning Ops Contact as a Platform Admin Role
                cemOP.Primary_Contact_Edition_Mapping__c = listCEMUpsert[0].Id;
                cemOP.isSecondary__c = true;
                if(status != 'Inactive'){listCEMUpsert2.add(cemOP);}
                
                List<Contact_Edition_Mapping__c> listExistingCEMTeamMembers = [SELECT Id, Role__c FROM Contact_Edition_Mapping__c WHERE Account__c =:asset.AccountId AND Edition__c =:asset.Edition__c AND Contact__c !=:asset.Operations_Contact__c AND Relationship_Status__c='Active' WITH SECURITY_ENFORCED];
                if(!listExistingCEMTeamMembers.isEmpty()){
                    for(Contact_Edition_Mapping__c cemp :listExistingCEMTeamMembers){
                        cemp.Role__c = 'Team Member';
                    }
                    update listExistingCEMTeamMembers;
                }
            }
            if(!listCEMUpsert2.isEmpty() && Schema.sObjectType.Contact_Edition_Mapping__c.isCreateable() && Schema.sObjectType.Contact_Edition_Mapping__c.isUpdateable()){
                upsert listCEMUpsert2;
            }
            
            //Upsert Purchase_Data__c
            Map<Id,Purchase_Data__c> mapPDUpdate = new Map<Id,Purchase_Data__c>();
            List<Purchase_Data__c> listPDInsert = new List<Purchase_Data__c>();
            Map<Id,Asset> mapAssetUpdate = new Map<Id,Asset>();
            Contact_Edition_Mapping__c cem2 = (!listCEMUpsert.isEmpty()?listCEMUpsert.get(0):(!listExistingCEM.isEmpty()?listExistingCEM.get(0):(new Contact_Edition_Mapping__c())));
            for(String key : mapPDUpsert.keySet()){
                Purchase_Data__c pd2 = mapPDUpsert.get(key);
                if(String.isNotBlank(cem2.Id)){
                    if(cem2.isSecondary__c == false){
                        pd2.Contact_Edition_Mapping__c = cem2.Id;
                    }
                    if(String.isBlank(pd2.Id)){listPDInsert.add(pd2);}
                }
                if(String.isBlank(pd2.Id) && String.isBlank(pd2.Contact_Edition_Mapping__c)){
                    isErrorInCEM = true;
                }
                if(String.isNotBlank(pd2.Id)){
                    mapPDUpdate.put(pd2.Id, pd2);
                }
            }
            
            List<Purchase_Data__c> listPDChanged = new List<Purchase_Data__c>();
            if(!mapPDUpdate.isEmpty() && Schema.sObjectType.Purchase_Data__c.isUpdateable()){
                update mapPDUpdate.values();
                listPDChanged.addAll(mapPDUpdate.values());
            }
            if(!listPDInsert.isEmpty() && Schema.sObjectType.Purchase_Data__c.isCreateable() && !isErrorInCEM){
                insert listPDInsert;
                listPDChanged.addAll(listPDInsert);
            }
            for(Purchase_Data__c pd2 : listPDChanged){
                if(asset.Purchase_Data__c != pd2.Id){mapAssetUpdate.put(pd2.Asset__c,new Asset(Id=pd2.Asset__c,Purchase_Data__c=pd2.Id));}
            }
            if(!mapAssetUpdate.isEmpty() && Schema.sObjectType.Asset.isUpdateable()){
                update mapAssetUpdate.values();
            }
            calloutStatus = 'success';
            if(isErrorInCEM){
                if(sp != null){
                    Database.rollback(sp);
                }
                String errorMessage = 'Error occured while Insert/Update or Finding Existing Contact Edition Mapping.';
                calloutStatus = 'Error';
                //update asset
                if(Schema.sObjectType.Asset.isUpdateable()){
                    asset.Progressing_Status__c = 'Error';
                    asset.Progressing_Error_Message__c = errorMessage;
                    update asset;
                }
                if(String.isNotBlank(apiItem.id)){IMCC_APISynchronizationHelper.updateSyncItemStatus(new IMCC_API_Synchronization_Item__c(Id=apiItem.id,Status__c='Error',Error_Message__c=errorMessage));}
            }
            else{
                //update asset
                if(Schema.sObjectType.Asset.isUpdateable()){
                    asset.Progressing_Status__c = 'Success';
                    asset.Progressing_Error_Message__c = null;
                    update asset;
                }
                if(String.isNotBlank(apiItem.id)){IMCC_APISynchronizationHelper.updateSyncItemStatus(new IMCC_API_Synchronization_Item__c(Id=apiItem.id,Status__c='Completed',Error_Message__c=''));}
            }
        }
        catch(Exception ex){
            if(sp != null){
                Database.rollback(sp);
            }
            calloutStatus = 'Error';
            // Error 
            String error = 'Error_Message__c --> '+ ex.getMessage() +' At Line' + ex.getLineNumber() + ' Trace --> '+ ex.getStackTraceString();
            //update asset
            if(Schema.sObjectType.Asset.isUpdateable()){
                asset.Progressing_Status__c = 'Error';
                asset.Progressing_Error_Message__c = error;
                update asset;
            }
            if(String.isNotBlank(apiItem.id)){IMCC_APISynchronizationHelper.updateSyncItemStatus(new IMCC_API_Synchronization_Item__c(Id=apiItem.id,Status__c='Error',Error_Message__c=error));
            System.debug(LoggingLevel.Debug, 'error=='+error);}
        }
        
        return calloutStatus;
    }

    /**
    * @description Before trigger handler for Asset
    * @param newAssetList
    * @param oldMap
    * @param isInsert
    */
    public static void handleBefore(List<Asset> newAssetList, Map<Id,Asset> oldMap, Boolean isInsert){
        for(Asset ast : newAssetList){
            //set the Booth_Dimension__c before insert
            if(String.isBlank(ast.Booth_Dimension__c) && String.isNotBlank(ast.Length__c) && String.isNotBlank(ast.Width__c)){ast.Booth_Dimension__c = ast.Length__c + 'x'+ast.Width__c;}
            //set the Progressing status if record is not processed through batch
            if(!System.isBatch() && !isInsert){
                Asset oldAsset = oldMap.get(ast.Id);
                if(!(ast.Purchase_Data__c != oldAsset.Purchase_Data__c || ast.Progressing_Status__c != oldAsset.Progressing_Status__c || ast.Progressing_Error_Message__c != oldAsset.Progressing_Error_Message__c)){
                    ast.Progressing_Status__c = 'In Progress';
                }
            }
            if(!System.isBatch() && isInsert){ast.Progressing_Status__c = 'In Progress';}
        }
    }

    /**
    * @description get fields of sobject
    * @param       sObjectApiName object name
    * @return      string fields
    */
    public static String dynamicGetAllFieldsQuery(string sObjectApiName)
    {
        String commaSepratedFields = '';
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Map<String, Schema.SObjectField> fieldMap = schemaMap.get(SobjectApiName).getDescribe().fields.getMap();

        //commaSepratedFields of queried object
        for(String fieldName : fieldMap.keyset()){
            if(commaSepratedFields == null || commaSepratedFields == ''){
                commaSepratedFields = fieldName;
            }else{
                commaSepratedFields = commaSepratedFields + ', ' + fieldName;
            }
        }
        return commaSepratedFields;
    }
}