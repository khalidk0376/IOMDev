/**
 * @description IMCC_ManageFormDataRecords 
Created By    : Aishwarya[IMCC-616]
Test Class    : IMCC_FormDataHandler_Test()
Created/Modified By   :  21/11/2021
Code Coverage - 92%
*/

public without sharing class IMCC_ManageFormDataRecords{
    /**
    * @description  to handle form permission after update.
    * @param  lstFP 
    */
    public static void handleAfterInsert(List<Forms_Permission__c> lstFP){
        Set<String> setformAllocationIds = new Set<String>();
        Set<Id> setFormSettingIds = new Set<Id>();
        Set<Id> setEditionIds = new Set<Id>();
        Map<Id,Set<Id>> mapFormSettingIdSetEditionId = new Map<Id,Set<Id>>();
        Set<String> setCEMIds = new Set<String>();
        Set<String> setUserType = new Set<String>();
        Map<Id,Form_Allocation__c> mapFormAllocationData = new Map<Id,Form_Allocation__c>();
        List<Purchase_Data__c> listPurchaseData = new List<Purchase_Data__c>();
        List<Form_Data__c> listFormDataInsert = new List<Form_Data__c>();
        List<Form_Data__c> listFormDataUpdate = new List<Form_Data__c>();
        Map<Id,Set<String>> mapFormAllocUserTypes = new Map<Id,Set<String>>();
        
        for(Forms_Permission__c fp : lstFP){
            setformAllocationIds.add(fp.Form_Allocation__c);
            setUserType.add(fp.User_Type1__c);
        }
        
        mapFormAllocationData = new Map<Id,Form_Allocation__c>([SELECT Id, Booth_Product_Types__c, Form_Setting__c, Form_Entry__c, (select Id, User_Type__c, Form_Allocation__c FROM Tab_User_Types__r) FROM Form_Allocation__c WHERE Id IN:setformAllocationIds WITH SECURITY_ENFORCED]);
        
        if(!mapFormAllocationData.isEmpty()){
            for(Form_Allocation__c form : mapFormAllocationData.Values()){
                setFormSettingIds.add(form.Form_Setting__c);
                Set<String> setStr = new Set<String>();
                if(form.Tab_User_Types__r != null){
                    for(Tab_User_Type__c tut : form.Tab_User_Types__r){
                        setStr.add(tut.User_Type__c);
                    }
                }
                mapFormAllocUserTypes.put(form.Id,setStr);
            }
        }

        if(!setFormSettingIds.isEmpty() && Schema.sObjectType.Edition__c.isAccessible()){
            List<Edition__c> listEdition = [SELECT Id, Name, Form_Setting__c, Edition_Status__c FROM Edition__c WHERE Form_Setting__c IN:setFormSettingIds];
            for(Edition__c edition : listEdition){
                setEditionIds.add(edition.Id);
                Set<Id> setStr = (mapFormSettingIdSetEditionId.containsKey(edition.Form_Setting__c)?mapFormSettingIdSetEditionId.get(edition.Form_Setting__c):(new Set<Id>()));
                setStr.add(edition.Id);
                mapFormSettingIdSetEditionId.put(edition.Form_Setting__c,setStr);
            }
        }

        Map<Id,List<Contact_Edition_Mapping__c>> mapEditionIdListCEM = new Map<Id,List<Contact_Edition_Mapping__c>>();
        if(!setEditionIds.isEmpty() && Schema.sObjectType.Contact_Edition_Mapping__c.isAccessible()){
            List<Contact_Edition_Mapping__c> listCEM2 = [SELECT Id, Account__c, Contact__c, Edition__c, CC_Status__c, Access_Type__c FROM Contact_Edition_Mapping__c WHERE Relationship_Status__c = 'Active' AND CC_Status__c IN ('Active', 'In Progress') AND Edition__c IN:setEditionIds AND Access_Type__c IN:setUserType AND isSecondary__c=false];
            for(Contact_Edition_Mapping__c cem : listCEM2){
                setCEMIds.add(cem.Id);
                List<Contact_Edition_Mapping__c> lst = (mapEditionIdListCEM.containsKey(cem.Edition__c)?mapEditionIdListCEM.get(cem.Edition__c):(new List<Contact_Edition_Mapping__c>()));
                lst.add(cem);
                mapEditionIdListCEM.put(cem.Edition__c,lst);
            }
        }
        
        Map<Id,Set<String>> mapCEMIdBoothTypes = new Map<Id,Set<String>>();
        Map<Id,List<Purchase_Data__c>> mapCEMIdListPD = new Map<Id,List<Purchase_Data__c>>();
        if(!setCEMIds.isEmpty() && Schema.sObjectType.Purchase_Data__c.isAccessible()){
            listPurchaseData = [SELECT Id, Booth_Product_Type__c, Contact_Edition_Mapping__c FROM Purchase_Data__c WHERE Contact_Edition_Mapping__c IN:setCEMIds AND Booth_Number__c!=null AND Purchase_Status__c='Active' AND Transaction_Status__c ='Active'];
            for(Purchase_Data__c pd : listPurchaseData){
                Set<String> setStr = (mapCEMIdBoothTypes.containsKey(pd.Contact_Edition_Mapping__c)?mapCEMIdBoothTypes.get(pd.Contact_Edition_Mapping__c):(new Set<String>()));
                setStr.add(pd.Booth_Product_Type__c);
                mapCEMIdBoothTypes.put(pd.Contact_Edition_Mapping__c,setStr);
                
                List<Purchase_Data__c> listPD = (mapCEMIdListPD.containsKey(pd.Contact_Edition_Mapping__c)?mapCEMIdListPD.get(pd.Contact_Edition_Mapping__c):(new List<Purchase_Data__c>()));
                listPD.add(pd);
                mapCEMIdListPD.put(pd.Contact_Edition_Mapping__c,listPD);
            }
        }

        Map<Id,Map<Id,List<Form_Data__c>>> mapCEMIdMapFormPermListFD = new Map<Id,Map<Id,List<Form_Data__c>>>();
        if(!setCEMIds.isEmpty() && Schema.sObjectType.Form_Data__c.isAccessible()){
            List<Form_Data__c> listFD = [SELECT Id, Forms_Permission__c, Forms_Permission__r.Form_Allocation__c, Contact_Edition_Mapping__c,Is_Active__c,Purchase_Data__c FROM Form_Data__c WHERE Contact_Edition_Mapping__c IN:setCEMIds AND Forms_Permission__r.Form_Allocation__c IN:setformAllocationIds];
            for(Form_Data__c fd : listFD){
                Map<Id,List<Form_Data__c>> mapFormPermListFD = (mapCEMIdMapFormPermListFD.containsKey(fd.Contact_Edition_Mapping__c)?mapCEMIdMapFormPermListFD.get(fd.Contact_Edition_Mapping__c):(new Map<Id,List<Form_Data__c>>()));
                List<Form_Data__c> lst = (mapFormPermListFD.containsKey(fd.Forms_Permission__c)?mapFormPermListFD.get(fd.Forms_Permission__c):(new List<Form_Data__c>()));
                lst.add(fd);
                mapFormPermListFD.put(fd.Forms_Permission__c,lst);
                mapCEMIdMapFormPermListFD.put(fd.Contact_Edition_Mapping__c,mapFormPermListFD);
            }
        }
        
        for(Forms_Permission__c fp : lstFP){
            Form_Allocation__c formAlloc = mapFormAllocationData.get(fp.Form_Allocation__c);
            Id formSettingId = formAlloc.Form_Setting__c;
            if(mapFormSettingIdSetEditionId.containsKey(formSettingId)){
                Set<Id> editionIds = mapFormSettingIdSetEditionId.get(formSettingId);
                List<Contact_Edition_Mapping__c> listCEM = new List<Contact_Edition_Mapping__c>();
                for(Id editionId : editionIds){
                    if(mapEditionIdListCEM.containsKey(editionId)){
                        listCEM.addAll(mapEditionIdListCEM.get(editionId));
                    }
                }
                for(Contact_Edition_Mapping__c cem : listCEM){
                    List<Form_Data__c> existingFormData = new List<Form_Data__c>();
                    Map<Id,Form_Data__c> mapExistingFormData = new Map<Id,Form_Data__c>();
                    Set<String> existingBoothProductTypes = new Set<String>();
                    if(mapCEMIdMapFormPermListFD.containsKey(cem.Id)){
                        if(mapCEMIdMapFormPermListFD.get(cem.Id).containsKey(fp.Id)){
                            existingFormData = mapCEMIdMapFormPermListFD.get(cem.Id).get(fp.Id);
                        }
                    }
                    for(Form_Data__c fd : existingFormData){
                        if(String.isNotBlank(fd.Purchase_Data__c)){
                            mapExistingFormData.put(fd.Purchase_Data__c,fd);
                        }
                    }
                    if(mapCEMIdBoothTypes.containsKey(cem.Id)){
                        existingBoothProductTypes = mapCEMIdBoothTypes.get(cem.Id);
                    }
                    if(fp.User_Type1__c == cem.Access_Type__c){
                        String formEntry = formAlloc.Form_Entry__c;
                        List<String> listBoothProductTypes = (String.isBlank(formAlloc.Booth_Product_Types__c)?new List<String>():formAlloc.Booth_Product_Types__c.split(';'));
                        if(formEntry == 'One Per Booth' || formEntry == 'Multiple Per Booth'){
                            
                            List<Purchase_Data__c> listPD = mapCEMIdListPD.containskey(cem.Id)?mapCEMIdListPD.get(cem.Id):new List<Purchase_Data__c>();
                            Set<Id> processedIds = new Set<Id>();
                            for(Purchase_Data__c pd : listPD){
                                processedIds.add(pd.Id);
                                if(listBoothProductTypes.isEmpty() || listBoothProductTypes.contains(pd.Booth_Product_Type__c)){
                                    if(mapExistingFormData.containsKey(pd.Id)){
                                        listFormDataUpdate.add(getFormDataObj(mapExistingFormData.get(pd.Id), cem, fp.Is_Active__c,pd.Id));
                                    }
                                    else{
                                        Form_Data__c newFD = getFormDataObj(new Form_Data__c(), cem, fp.Is_Active__c,pd.Id);
                                        newFD.Forms_Permission__c = fp.Id;
                                        listFormDataInsert.add(newFD);
                                    }
                                }
                                else if(mapExistingFormData.containsKey(pd.Id)){
                                    listFormDataUpdate.add(getFormDataObj(mapExistingFormData.get(pd.Id), cem, false,pd.Id));
                                }
                            }
                            
                            for(Form_Data__c oldFD: mapExistingFormData.Values()){
                                if(!processedIds.contains(oldFD.Purchase_Data__c)){
                                    listFormDataUpdate.add(new Form_Data__c(Id=oldFD.Id,Is_Active__c = false));
                                }
                            }
                        }
                        else{
                            boolean isInsert = existingFormData.isEmpty();
                            boolean isProcess = listBoothProductTypes.isEmpty();
                            for(String str : listBoothProductTypes){
                                if(String.isNotBlank(str) && existingBoothProductTypes.contains(str)){
                                    isProcess = true;
                                }
                            }
                            if(isProcess){
                                if(isInsert){
                                    Form_Data__c newFD = getFormDataObj(new Form_Data__c(), cem, fp.Is_Active__c,null);
                                    newFD.Forms_Permission__c = fp.Id;
                                    listFormDataInsert.add(newFD);
                                    system.debug(LoggingLevel.Debug, 'listFormDataInsert2 ' +listFormDataInsert);
                                }
                                else{
                                    listFormDataUpdate.add(getFormDataObj(existingFormData.get(0), cem, fp.Is_Active__c,null));
                                }
                            }
                            else if(!existingFormData.isEmpty()){
                                listFormDataUpdate.add(getFormDataObj(existingFormData.get(0), cem, false,null));
                            }
                        }
                    }
                }
            }
        }

        if(!listFormDataInsert.isEmpty() && Schema.sObjectType.Form_Data__c.IsCreateable()){
            Database.insert(listFormDataInsert,false);
            //insert listFormDataInsert;
        }
        if(!listFormDataUpdate.isEmpty() && Schema.sObjectType.Form_Data__c.isUpdateable()){
            Database.update(listFormDataUpdate,false);
            //update listFormDataUpdate;
        }
    }

    /**
    * @description  to Insert/Update form data after purchase data After Insert/Update.
    * @param  listPDNew 
    * @param  mapOldPD 
    * @param  isInsert 
    */
    public static void handleAfterInsertAfterUpdatePurchaseData(List<Purchase_Data__c> listPDNew, Map<Id,Purchase_Data__c> mapOldPD, Boolean isInsert){
        Set<Id> setCEMIds = new Set<Id>();
        Set<Id> setEditionIds = new Set<Id>();
        Map<Id,Set<Id>> mapFormSettingIdSetEditionId = new Map<Id,Set<Id>>();
        Map<Id,Form_Allocation__c> mapFormAllocationData = new Map<Id,Form_Allocation__c>();

        for(Purchase_Data__c pd : listPDNew){
            if(isInsert || (pd.Booth_Product_Type__c != mapOldPD.get(pd.Id).Booth_Product_Type__c || pd.Purchase_Status__c != mapOldPD.get(pd.Id).Purchase_Status__c || pd.Transaction_Status__c != mapOldPD.get(pd.Id).Transaction_Status__c)){
                setCEMIds.add(pd.Contact_Edition_Mapping__c);
                setEditionIds.add(pd.Edition__c);
            }
        }

        if(!setEditionIds.isEmpty()){
            List<Edition__c> listEdition = [SELECT Id, Name, Form_Setting__c, Edition_Status__c FROM Edition__c WHERE Id IN:setEditionIds WITH SECURITY_ENFORCED];
            for(Edition__c edition : listEdition){
                if(String.isNotBlank(edition.Form_Setting__c)){
                    Set<Id> setStr = (mapFormSettingIdSetEditionId.containsKey(edition.Form_Setting__c)?mapFormSettingIdSetEditionId.get(edition.Form_Setting__c):(new Set<Id>()));
                    setStr.add(edition.Id);
                    mapFormSettingIdSetEditionId.put(edition.Form_Setting__c,setStr);
                }
            }
        }
        
        Map<Id,List<Form_Allocation__c>> mapFprmSettingIdListFormAlloc = new Map<Id,List<Form_Allocation__c>>();
        if(!mapFormSettingIdSetEditionId.isEmpty()){
            mapFormAllocationData = new Map<Id,Form_Allocation__c>([SELECT Id, Booth_Product_Types__c, Form_Setting__c, Form_Entry__c, (select Id, User_Type__c, Form_Allocation__c FROM Tab_User_Types__r) FROM Form_Allocation__c WHERE Form_Setting__c IN:mapFormSettingIdSetEditionId.keySet() WITH SECURITY_ENFORCED]);
            for(Form_Allocation__c fAlloc : mapFormAllocationData.Values()){
                List<Form_Allocation__c> lst = (mapFprmSettingIdListFormAlloc.containsKey(fAlloc.Form_Setting__c)?mapFprmSettingIdListFormAlloc.get(fAlloc.Form_Setting__c):(new List<Form_Allocation__c>()));
                lst.add(fAlloc);
                mapFprmSettingIdListFormAlloc.put(fAlloc.Form_Setting__c,lst);
            }
        }

        Map<Id,List<Contact_Edition_Mapping__c>> mapEditionIdListCEM = new Map<Id,List<Contact_Edition_Mapping__c>>();
        Set<String> setUserType = new Set<String>();
        if(!setCEMIds.isEmpty()){
            List<Contact_Edition_Mapping__c> listCEM2 = [SELECT Id, Account__c, Contact__c, Edition__c, CC_Status__c, Access_Type__c FROM Contact_Edition_Mapping__c WHERE Relationship_Status__c = 'Active' AND CC_Status__c IN ('Active', 'In Progress') AND Id IN:setCEMIds AND isSecondary__c=false WITH SECURITY_ENFORCED];
            for(Contact_Edition_Mapping__c cem : listCEM2){
                List<Contact_Edition_Mapping__c> lst = (mapEditionIdListCEM.containsKey(cem.Edition__c)?mapEditionIdListCEM.get(cem.Edition__c):(new List<Contact_Edition_Mapping__c>()));
                lst.add(cem);
                mapEditionIdListCEM.put(cem.Edition__c,lst);
                setUserType.add(cem.Access_Type__c);
            }
        }

        Map<Id,Set<String>> mapCEMIdBoothTypes = new Map<Id,Set<String>>();
        Map<Id,List<Purchase_Data__c>> mapCEMIdListPD = new Map<Id,List<Purchase_Data__c>>();
        if(!setCEMIds.isEmpty()){
            List<Purchase_Data__c> listPurchaseData = [SELECT Id, Booth_Product_Type__c, Contact_Edition_Mapping__c FROM Purchase_Data__c WHERE Contact_Edition_Mapping__c IN:setCEMIds AND Booth_Number__c!=null AND Purchase_Status__c='Active' AND Transaction_Status__c ='Active' WITH SECURITY_ENFORCED];
            for(Purchase_Data__c pd : listPurchaseData){
                Set<String> setStr = (mapCEMIdBoothTypes.containsKey(pd.Contact_Edition_Mapping__c)?mapCEMIdBoothTypes.get(pd.Contact_Edition_Mapping__c):(new Set<String>()));
                setStr.add(pd.Booth_Product_Type__c);
                mapCEMIdBoothTypes.put(pd.Contact_Edition_Mapping__c,setStr);
                
                List<Purchase_Data__c> listPD = (mapCEMIdListPD.containsKey(pd.Contact_Edition_Mapping__c)?mapCEMIdListPD.get(pd.Contact_Edition_Mapping__c):(new List<Purchase_Data__c>()));
                listPD.add(pd);
                mapCEMIdListPD.put(pd.Contact_Edition_Mapping__c,listPD);
            }
        }

        Map<Id,Map<Id,List<Form_Data__c>>> mapCEMIdMapFormPermListFD = new Map<Id,Map<Id,List<Form_Data__c>>>();
        if(!setCEMIds.isEmpty()){
            List<Form_Data__c> listFD = [SELECT Id, Forms_Permission__c, Contact_Edition_Mapping__c,Is_Active__c,Purchase_Data__c FROM Form_Data__c WHERE Contact_Edition_Mapping__c IN:setCEMIds WITH SECURITY_ENFORCED];
            for(Form_Data__c fd : listFD){
                Map<Id,List<Form_Data__c>> mapFormPermListFD = (mapCEMIdMapFormPermListFD.containsKey(fd.Contact_Edition_Mapping__c)?mapCEMIdMapFormPermListFD.get(fd.Contact_Edition_Mapping__c):(new Map<Id,List<Form_Data__c>>()));
                List<Form_Data__c> lst = (mapFormPermListFD.containsKey(fd.Forms_Permission__c)?mapFormPermListFD.get(fd.Forms_Permission__c):(new List<Form_Data__c>()));
                lst.add(fd);
                mapFormPermListFD.put(fd.Forms_Permission__c,lst);
                mapCEMIdMapFormPermListFD.put(fd.Contact_Edition_Mapping__c,mapFormPermListFD);
            }
        }


        List<Form_Data__c> listFormDataInsert = new List<Form_Data__c>();
        List<Form_Data__c> listFormDataUpdate = new List<Form_Data__c>();

        List<Forms_Permission__c> lstFP = [SELECT Id,Form_Allocation__c,Is_Active__c,User_Type1__c FROM Forms_Permission__c WHERE Form_Allocation__c IN:mapFormAllocationData.keySet() AND User_Type1__c IN:setUserType WITH SECURITY_ENFORCED];
        
        for(Forms_Permission__c fp : lstFP){
            Form_Allocation__c formAlloc = mapFormAllocationData.get(fp.Form_Allocation__c);
            Id formSettingId = formAlloc.Form_Setting__c;
            if(mapFormSettingIdSetEditionId.containsKey(formSettingId)){
                Set<Id> editionIds = mapFormSettingIdSetEditionId.get(formSettingId);
                List<Contact_Edition_Mapping__c> listCEM = new List<Contact_Edition_Mapping__c>();
                for(Id editionId : editionIds){
                    if(mapEditionIdListCEM.containsKey(editionId)){
                        listCEM.addAll(mapEditionIdListCEM.get(editionId));
                    }
                }
                for(Contact_Edition_Mapping__c cem : listCEM){
                    List<Form_Data__c> existingFormData = new List<Form_Data__c>();
                    Map<Id,Form_Data__c> mapExistingFormData = new Map<Id,Form_Data__c>();
                    Set<String> existingBoothProductTypes = new Set<String>();
                    if(mapCEMIdMapFormPermListFD.containsKey(cem.Id)){
                        if(mapCEMIdMapFormPermListFD.get(cem.Id).containsKey(fp.Id)){
                            existingFormData = mapCEMIdMapFormPermListFD.get(cem.Id).get(fp.Id);
                        }
                    }
                    for(Form_Data__c fd : existingFormData){
                        if(String.isNotBlank(fd.Purchase_Data__c)){
                            mapExistingFormData.put(fd.Purchase_Data__c,fd);
                        }
                    }
                    if(mapCEMIdBoothTypes.containsKey(cem.Id)){
                        existingBoothProductTypes = mapCEMIdBoothTypes.get(cem.Id);
                    }
                    if(fp.User_Type1__c == cem.Access_Type__c){
                        String formEntry = formAlloc.Form_Entry__c;
                        List<String> listBoothProductTypes = (String.isBlank(formAlloc.Booth_Product_Types__c)?new List<String>():formAlloc.Booth_Product_Types__c.split(';'));

                        if(formEntry == 'One Per Booth' || formEntry == 'Multiple Per Booth'){
                            
                            List<Purchase_Data__c> listPD = mapCEMIdListPD.containskey(cem.Id)?mapCEMIdListPD.get(cem.Id):new List<Purchase_Data__c>();
                            Set<Id> processedIds = new Set<Id>();
                            for(Purchase_Data__c pd : listPD){
                                processedIds.add(pd.Id);
                                if(listBoothProductTypes.isEmpty() || listBoothProductTypes.contains(pd.Booth_Product_Type__c)){
                                    if(mapExistingFormData.containsKey(pd.Id)){
                                        listFormDataUpdate.add(getFormDataObj(mapExistingFormData.get(pd.Id), cem, fp.Is_Active__c,pd.Id));
                                    }
                                    else{
                                        Form_Data__c newFD = getFormDataObj(new Form_Data__c(), cem, fp.Is_Active__c,pd.Id);
                                        newFD.Forms_Permission__c = fp.Id;
                                        listFormDataInsert.add(newFD);
                                    }
                                }
                                else if(mapExistingFormData.containsKey(pd.Id)){
                                    listFormDataUpdate.add(getFormDataObj(mapExistingFormData.get(pd.Id), cem, false,pd.Id));
                                }
                            }
                            
                            for(Form_Data__c oldFD: mapExistingFormData.Values()){
                                if(!processedIds.contains(oldFD.Purchase_Data__c)){
                                    listFormDataUpdate.add(new Form_Data__c(Id=oldFD.Id,Is_Active__c = false));
                                }
                            }
                        }
                        else{
                            boolean isInsert2 = existingFormData.isEmpty();
                            boolean isProcess = listBoothProductTypes.isEmpty();
                            for(String str : listBoothProductTypes){
                                if(String.isNotBlank(str) && existingBoothProductTypes.contains(str)){
                                    isProcess = true;
                                }
                            }
                            if(isProcess){
                                if(isInsert2){
                                    Form_Data__c newFD = getFormDataObj(new Form_Data__c(), cem, fp.Is_Active__c,null);
                                    newFD.Forms_Permission__c = fp.Id;
                                    listFormDataInsert.add(newFD);
                                }
                                else{
                                    listFormDataUpdate.add(getFormDataObj(existingFormData.get(0), cem, fp.Is_Active__c,null));
                                }
                            }
                            else if(!existingFormData.isEmpty()){
                                listFormDataUpdate.add(getFormDataObj(existingFormData.get(0), cem, false,null));
                            }
                        }
                    }
                }
            }
        }

        if(!listFormDataInsert.isEmpty() && Schema.sObjectType.Form_Data__c.IsCreateable()){
            Database.insert(listFormDataInsert,false);
        }
        if(!listFormDataUpdate.isEmpty() && Schema.sObjectType.Form_Data__c.isUpdateable()){
            Database.update(listFormDataUpdate,false);
        }
    }

    private static Form_Data__c getFormDataObj(Form_Data__c fData, Contact_Edition_Mapping__c cem, Boolean isActive,String pdId){
        fData.Contact_Edition_Mapping__c = cem.Id;
        fData.Account__c = cem.Account__c;
        fData.Edition__c = cem.Edition__c;
        fData.User_Type1__c = cem.Access_Type__c;
        fData.Is_Active__c = isActive;
        fData.Purchase_Data__c = pdId;
        return fData;
    }
}