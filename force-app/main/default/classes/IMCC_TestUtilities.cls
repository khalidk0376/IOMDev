/*
* Created       :  Girikon(Aishwarya)
* Created On    :  13/9/2021
* @description  :  This class works as utility test class and contains reusable test methods
* Modified By   :  Girikon(Garima)
* Modified On   :  08/10/2021
* Modified By   :  Girikon(Arushi)
* Modified On   :  22/12/2021,04/02/2022
**/

@isTest
public class IMCC_TestUtilities {
    public static List<Account> createAccount(Integer numAccts)
    {   
        List<Account> accts=new List<Account>();
        for(Integer i=0;i<numAccts;i++){
            Account a=new Account(Name='Test Account'+i);
            accts.add(a);
        }
        insert accts;
        return accts;
    }
    
    public static List<Contact> createContact(Id accId,Integer numContacts)
    {
        List<Contact> con = new List<Contact>();
        for(Integer i=0;i<numContacts;i++){
            con.add(new Contact(firstname='Test'+i,lastname='Test'+i,AccountId=accId,Email='FirstName@test.com'+i)); 
        }
        insert con;
        return con;
    }
    
    public static List<Contact> createContact2(Integer numContacts)
    {
        List<Contact> con = new List<Contact>();
        for(Integer i=0;i<numContacts;i++){
            con.add(new Contact(firstname='Test'+i,lastname='Test'+i,Email='Testtest@test.com'+i)); 
        }
        insert con;
        return con;
    }
    
    public static List<Brand__c> createBrand(Integer numBrand)
    {
        List<Brand__c> oBrand = new List<Brand__c>();
        for(Integer i=0; i<numBrand; i++){
            Brand__c br=new Brand__c(Name='World of Concrete'+i);
            oBrand.add(br);
        }
        insert oBrand;
        return oBrand;
    }
    
    public static List<Series__c> createEventSeries(Id brandObjId, Integer numSeries)
    {
        List<Series__c> oEventseries = new List<Series__c>();
        for(Integer i=0;i<numSeries;i++){
            Series__c se=new Series__c(Name = 'World Of Concrete'+i, Status__c = 'Active', CurrencyISOCode = 'USD', Brand__c = brandObjId);
            oEventseries.add(se);
        }
        insert oEventseries;
        return oEventseries;
    }
    
    public static List<Edition__c> createEventEdition(Id eventSeriesId,Id editionImageURL, Integer numEditions)
    {
        List<Edition__c> eveEdition = new List<Edition__c>();
        for(Integer i=0;i<numEditions;i++){
            Edition__c edition=new Edition__c(
                Name = 'Test Event 2021'+i,
                Part_of_Series__c = eventSeriesId, 
                Edition_Code__c ='TEV21'+i, 
                End_Date__c = System.Today(), 
                Start_Date__c = System.Today(), 
                Edition_Status__c = 'Confirmed', 
                Edition_Website__c = 'http://www.testevent.com', 
                Edition_Image_URL__c = editionImageURL, 
                Send_Welcome_email__c=true,
                Customer_Center_Status__c='Active'
            );
            eveEdition.add(edition);
        }
        insert eveEdition;
        return eveEdition;
    }
    
    public static List<Edition__c> createEventEditionInActive(Id eventSeriesId,Id editionImageURL, Integer numEditions)
    {
        List<Edition__c> eveEdition = new List<Edition__c>();
        for(Integer i=0;i<numEditions;i++){
            Edition__c edition=new Edition__c(Name = 'Test Event 2021'+i,Part_of_Series__c = eventSeriesId, Edition_Code__c ='TEV21'+i, End_Date__c = System.Today(), Start_Date__c = System.Today(), Edition_Status__c = 'Confirmed', Edition_Website__c = 'http://www.testevent.com', Edition_Image_URL__c = editionImageURL, Send_Welcome_email__c=true,Customer_Center_Status__c='Inactive');
            eveEdition.add(edition);
        }
        insert eveEdition;
        return eveEdition;
    }
    
    public static List<Edition__c> createEventEditionWithEveSetting(Id eventSeriesId,Id editionImageURL, Id eveSetting, Integer numEditions)
    {
        List<Edition__c> eveEdition = new List<Edition__c>();
        for(Integer i=0;i<numEditions;i++){
            Edition__c edition=new Edition__c(Name = 'Test Event 2021'+i, Part_of_Series__c = eventSeriesId, Edition_Code__c ='TEV21'+i, End_Date__c = System.Today(), Start_Date__c = System.Today(), Edition_Status__c = 'Confirmed', Edition_Website__c = 'http://www.testevent.com', Edition_Image_URL__c = editionImageURL,Customer_Center_Status__c='Active',Event_Setting__c = eveSetting); 
            eveEdition.add(edition);
        }
        insert eveEdition;
        return eveEdition;
    }
    
    public static List<Edition__c> createEventEditionWithEveSetting2(Id eventSeriesId,Id editionImageURL, Id eveSetting, Integer numEditions)
    {
        List<Edition__c> eveEdition = new List<Edition__c>();
        for(Integer i=0;i<numEditions;i++){
            Edition__c edition=new Edition__c(Name = 'Test Event 2021'+i, Part_of_Series__c = eventSeriesId, Edition_Code__c ='TEV21'+i,
                                              End_Date__c = System.Today(), Start_Date__c = System.Today(), Edition_Status__c = 'Confirmed',
                                              Edition_Website__c = 'http://www.testevent.com', Edition_Image_URL__c = editionImageURL,
                                              Customer_Center_Status__c='Active',Event_Setting__c = eveSetting,Contractor_Nomination_Due_Date__c= System.Today(),
                                              Stand_Design_Completion_Due_Date__c= System.Today()); 
            eveEdition.add(edition);
        }
        insert eveEdition;
        return eveEdition;
    }
    
    public static List<Edition__c> createEventEditionWithEveAndFormSetting(Id eventSeriesId,Id editionImageURL, Id eveSetting, Id formSetting, Integer numEditions)
    {
        List<Edition__c> eveEdition = new List<Edition__c>();
        for(Integer i=0;i<numEditions;i++){
            Edition__c edition=new Edition__c(Name = 'Test Event 2021'+i, Part_of_Series__c = eventSeriesId, Edition_Code__c ='TEV21'+i, End_Date__c = System.Today(), Start_Date__c = System.Today(), Edition_Status__c = 'Confirmed', Edition_Website__c = 'http://www.testevent.com', Edition_Image_URL__c = editionImageURL,Event_Setting__c = eveSetting,Customer_Center_Status__c='Active',Form_Setting__c = formSetting); 
            eveEdition.add(edition);
        }
        insert eveEdition;
        return eveEdition;
    }
    
    public static List<Edition__c> createEventEditionWithBadgeSetting(Id eventSeriesId,Id editionImageURL, Id badgeSetting, Integer numEditions)
    {
        List<Edition__c> eveEdition = new List<Edition__c>();
        for(Integer i=0;i<numEditions;i++){
            Edition__c edition=new Edition__c(Name = 'Test Event 2021'+i, Part_of_Series__c = eventSeriesId, Edition_Code__c ='TEV21'+i
                                              , End_Date__c = System.Today(), Start_Date__c = System.Today(), Edition_Status__c = 'Confirmed'
                                              , Edition_Website__c = 'http://www.testevent.com', Edition_Image_URL__c = editionImageURL
                                              ,Customer_Center_Status__c='Active',Badge_Setting__c = badgeSetting,Additional_Badge_Allocated__c =2); 
            eveEdition.add(edition);
        }
        insert eveEdition;
        return eveEdition;
    }
    
    public static List<Edition__c> createEventEditionWithStandSetting(Id eventSeriesId,Id editionImageURL, Id standSetting, Integer numEditions, Date conNominatedDueDate,Date standDesignDueDate)
    {
        List<Edition__c> eveEdition = new List<Edition__c>();
        for(Integer i=0;i<numEditions;i++){
            Edition__c edition=new Edition__c(Name = 'Test Event 2021'+i, Part_of_Series__c = eventSeriesId, Edition_Code__c ='TEV21'+i
                                              , End_Date__c = System.Today(), Start_Date__c = System.Today(), Edition_Status__c = 'Confirmed'
                                              , Edition_Website__c = 'http://www.testevent.com', Edition_Image_URL__c = editionImageURL
                                              ,Customer_Center_Status__c='Active',Stand_Setting__c = standSetting
                                              ,Contractor_Nomination_Due_Date__c = conNominatedDueDate,Stand_Design_Completion_Due_Date__c = standDesignDueDate); 
            eveEdition.add(edition);
        }
        insert eveEdition;
        return eveEdition;
    }
    
    public static List<Event_Setting__c> createEventSetting(Integer numEvtSet)
    {
        List<Event_Setting__c> eventSet = new List<Event_Setting__c>();
        for(Integer i=0;i<numEvtSet;i++){
            Event_Setting__c es=new Event_Setting__c(Description__c = 'Test Event'+i);
            eventSet.add(es);
        }
        insert eventSet;
        return eventSet;
    }
    
    public static List<Event_Tabs__c> createEventTabs(Id eveSettingObjId, Integer numTabs,Integer addNumToSeq, String layoutType, String tabType,String standrdTabType, String floorplanType)
    {   
        List<Event_Tabs__c> eveTab = new List<Event_Tabs__c>();
        if(tabType == 'Custom'){
            for(Integer i=0;i<numTabs;i++){
                Event_Tabs__c et=new Event_Tabs__c(Sequence__c=i+addNumToSeq,ExtTabId__c='Test'+i+'_'+standrdTabType,Tab_Title__c='Test Tab'+i, Event_Setting__c=eveSettingObjId,Is_Tab_Active__c = true,Is_Tab_Visible__c=true,Layout_Type__c = layoutType,Tab_Type__c = tabType);
                eveTab.add(et);
            }  
        }
        else if(standrdTabType == 'Floorplan'){
            for(Integer i=0;i<numTabs;i++){
                Event_Tabs__c et=new Event_Tabs__c(Sequence__c=i+addNumToSeq,ExtTabId__c= standrdTabType+'_'+floorplanType+i, Tab_Title__c='Test Tab'+i, Event_Setting__c=eveSettingObjId,Is_Tab_Active__c = true,Is_Tab_Visible__c=true,Layout_Type__c = layoutType,Tab_Type__c = tabType,Standard_Tab_Type__c = standrdTabType,Floorplan_Type__c = floorplanType);
                eveTab.add(et);
            }
            
        }
        else{
            for(Integer i=0;i<numTabs;i++){
                Event_Tabs__c et=new Event_Tabs__c(Sequence__c=i+addNumToSeq,ExtTabId__c='Test'+i+'_'+standrdTabType, Tab_Title__c='Test Tab'+i, Event_Setting__c=eveSettingObjId,Is_Tab_Active__c = true,Is_Tab_Visible__c=true,Layout_Type__c = layoutType,Tab_Type__c = tabType,Standard_Tab_Type__c = standrdTabType);
                eveTab.add(et);
            }  
            system.debug('Event Tab ' +eveTab);
        }
        insert eveTab;
        
        return eveTab;
    }
    
    public static List<Event_Tabs__c> createEventTabs2(Id eveSettingObjId, Integer numTabs,Integer addNumToSeq, String layoutType, String tabType,String standrdTabType, String floorplanType)
    {   
        List<Event_Tabs__c> eveTab = new List<Event_Tabs__c>();
        if(tabType == 'Custom'){
            for(Integer i=0;i<numTabs;i++){
                Event_Tabs__c et=new Event_Tabs__c(Sequence__c=i+addNumToSeq,ExtTabId__c='Test'+i+'_'+standrdTabType,Tab_Title__c='Test Tab'+i, Event_Setting__c=eveSettingObjId,Is_Tab_Active__c = true,Is_Tab_Visible__c=true,Layout_Type__c = layoutType,Tab_Type__c = tabType);
                eveTab.add(et);
            }  
        }
        else if(standrdTabType == 'Floorplan'){
            for(Integer i=0;i<numTabs;i++){
                Event_Tabs__c et=new Event_Tabs__c(Sequence__c=i+addNumToSeq,ExtTabId__c= standrdTabType+'_'+floorplanType+i, Tab_Title__c='Test Tab'+i, Event_Setting__c=eveSettingObjId,Is_Tab_Active__c = true,Is_Tab_Visible__c=true,Layout_Type__c = layoutType,Tab_Type__c = tabType,Standard_Tab_Type__c = standrdTabType,Floorplan_Type__c = floorplanType);
                eveTab.add(et);
            }
            
        }
        else{
            for(Integer i=0;i<numTabs;i++){
                Event_Tabs__c et=new Event_Tabs__c(Sequence__c=i+addNumToSeq,ExtTabId__c='Test'+i+'_'+standrdTabType, Tab_Title__c='Test Tab'+i, Event_Setting__c=eveSettingObjId,Is_Tab_Active__c = true,Is_Tab_Visible__c=true,Layout_Type__c = layoutType,Tab_Type__c = tabType,Standard_Tab_Type__c = standrdTabType);
                eveTab.add(et);
            }  
            system.debug('Event Tab ' +eveTab);
        }
        insert eveTab;
        
        return eveTab;
    }
    
    public static List<Tab_User_Type__c> createTabUserType(Id evntTabId, Integer numTabUsr, String userType)
    {
        List<Tab_User_Type__c> tabUsrTypeLst = new List<Tab_User_Type__c>();
        for(Integer i=0;i<numTabUsr;i++){
            Tab_User_Type__c tabUsrType=new Tab_User_Type__c(Event_Tab__c = evntTabId,User_Type__c = userType);
            tabUsrTypeLst.add(tabUsrType);
        }
        insert tabUsrTypeLst;
        return tabUsrTypeLst;
    }
    
    public static List<Tab_User_Type__c> createTabUserTypeForAnnouncement(Id announcementId, String userType)
    {
        List<Tab_User_Type__c> tabUsrTypeLst = new List<Tab_User_Type__c>();
        for(Integer i=0;i<2;i++){
            Tab_User_Type__c tabUsrType=new Tab_User_Type__c(Announcement__c = announcementId,User_Type__c = userType);
            tabUsrTypeLst.add(tabUsrType);
        }
        insert tabUsrTypeLst;
        return tabUsrTypeLst;
    }
    
    public static List<Tab_Context__c> createTabContext(Id evntTabId, Integer numTabCntxt)
    {
        List<Tab_Context__c> tabCntxtLst = new List<Tab_Context__c>();
        for(Integer i=0;i<numTabCntxt;i++){
            Tab_Context__c tabCntxt=new Tab_Context__c(Event_Tab__c = evntTabId,Header__c = 'Test Header'+i, Section_1__c='Test Section 1'+i, Section_2__c ='test section 2'+i, Section_3__c='Test Section 3'+i);
            tabCntxtLst.add(tabCntxt);
        }
        insert tabCntxtLst;
        return tabCntxtLst;
    }
    
    public static List<Purchase_Data__c> createPurchaseData(Id conEdMap, Id accId, Integer numPurData)
    {
        List<Purchase_Data__c> purDataLst = new List<Purchase_Data__c>();
        for(Integer i=0;i<numPurData;i++){
            Purchase_Data__c purData=new Purchase_Data__c(Contact_Edition_Mapping__c = conEdMap, Account__c =accId,Booth_Product_Type__c = 'Space Only', Booth_Number__c = 'H2.11'+i,Purchase_Status__c = 'Active', Transaction_Status__c ='Active');
            purDataLst.add(purData);
        }
        insert purDataLst;
        return purDataLst;
    }
    
    public static Purchase_Data__c createPurchaseData3(Id contactId, Id eid, Id accId)
    {
        Purchase_Data__c purData=new Purchase_Data__c(
            Contact__c=contactId,
            Edition__c = eid, 
            Account__c =accId,
            Booth_Product_Type__c = 'Space Only', 
            Booth_Number__c = 'H2.11',
            Purchase_Status__c = 'Active', 
            Transaction_Status__c ='Active'
        );        
        insert purData;
        return purData;
    }
    
    public static List<Purchase_Data__c> createPurchaseData2(Id conEdMap, Id editionId, Integer numPurData)
    {
        List<Purchase_Data__c> purDataLst = new List<Purchase_Data__c>();
        for(Integer i=0;i<numPurData;i++){
            Purchase_Data__c purData=new Purchase_Data__c(Contact_Edition_Mapping__c = conEdMap, Edition__c =editionId, Booth_Number__c = 'H2.11'+i,Booth_Product_Type__c = 'Shell Scheme'
                                                          ,Purchase_Status__c = 'Active', Transaction_Status__c ='Active', Quantity_Area__c = 20.00, Addition_Badge_Count__c = 2);
            purDataLst.add(purData);
        }
        insert purDataLst;
        return purDataLst;
    }
    
    public static List<Purchase_Data__c> createPurchaseData4(Id conEdMap, Id editionId, Integer numPurData)
    {
        List<Purchase_Data__c> purDataLst = new List<Purchase_Data__c>();
        for(Integer i=0;i<numPurData;i++){
            Purchase_Data__c purData=new Purchase_Data__c(Contact_Edition_Mapping__c = conEdMap, Edition__c =editionId, Booth_Number__c = 'H2.11'+i,Booth_Product_Type__c = 'Space Only'
                                                          ,Purchase_Status__c = 'Active', Transaction_Status__c ='Active', Quantity_Area__c = 20.00, Addition_Badge_Count__c = 2);
            purDataLst.add(purData);
        }
        insert purDataLst;
        return purDataLst;
    }
    
    public static List<Edition_Popup__c> createEditionPopupData(Id EditionId, Integer numPurData)
    {
        List<Edition_Popup__c> edPopupDataLst = new List<Edition_Popup__c>();
        for(Integer i=0;i<numPurData;i++){
            Edition_Popup__c popupData = new Edition_Popup__c(Edition__c = EditionId, Is_Visible__c =True, Booth_Product_Type__c = 'Space Only', Pop_Up_Text__c ='Welcome User'+i,Reset_Pop_up_Preferences__c =False);
            edPopupDataLst.add(popupData);
        }
        insert edPopupDataLst;
        return edPopupDataLst;
    }
    
    public static List<PDF_Floorplan__c> createPdfFloorplan(Id eventTab, Integer numPdfFloorplan, String pdfType)
    {
        List<PDF_Floorplan__c> pdfFloorplanLst = new List<PDF_Floorplan__c>();
        for(Integer i=0;i<numPdfFloorplan;i++){
            PDF_Floorplan__c pdfFloorplan=new PDF_Floorplan__c(PDF_Name__c = 'Test PDF'+i, Event_Tab__c = eventTab, PDF_Type__c = pdfType);
            pdfFloorplanLst.add(pdfFloorplan);
        }
        insert pdfFloorplanLst;
        return pdfFloorplanLst;
    }
    
    public static List<Edition_Websites__c> createEditionWebsites(Id EditionId, Integer numWebsites)
    {
        List<Edition_Websites__c> edWeb = new List<Edition_Websites__c>();
        for(Integer i=0;i<numWebsites;i++){
            Edition_Websites__c ed=new Edition_Websites__c(Name = 'Test Web'+i, Website_Label__c = 'Test Website 1', Website_Link__c = 'https://www.google.com/', Sequence__c = 1, Edition__c = EditionId);
            edWeb.add(ed);
        }
        insert edWeb;
        return edWeb;
    }
    
    public static List<Q_s_A_s_How_To__c> createQuesAnsHowTo(Id eventTabId,string type,Integer numQuesAns)
    {
        List<Q_s_A_s_How_To__c> quesAnsLst = new List<Q_s_A_s_How_To__c>();
        if(type == 'FAQ'){
            for(Integer i=0;i<numQuesAns;i++){
                Q_s_A_s_How_To__c quesAnsData=new Q_s_A_s_How_To__c(Active__c = true, Event_Tab__c = eventTabId,Type__c=type,Sequence__c =i, Question__c ='Test Ques' +i,Answer__c='Test Ans' +i); 
                quesAnsLst.add(quesAnsData);
            }
        }
        else if(type == 'How to'){
            for(Integer i=0;i<numQuesAns;i++){
                Q_s_A_s_How_To__c quesAnsData=new Q_s_A_s_How_To__c(Active__c = true, Event_Tab__c = eventTabId,Type__c=type,Sequence__c =i,HyperLink__c='www.google.com',Label__c='Test PDF' +i); 
                quesAnsLst.add(quesAnsData);
            }  
        }
        insert quesAnsLst;
        return quesAnsLst;
    }
    
    public static Contact_Edition_Mapping__c createContactEditionMapping(Id contactId,Id accountId,Id EditionId)
    {
        Contact_Edition_Mapping__c cem = new Contact_Edition_Mapping__c();
        cem.Contact__c = contactId;
        cem.Edition__c = EditionId;
        cem.Relationship_Status__c = 'Active';
        cem.Account__c = accountId;
        cem.Role__c = 'Team Member';
        cem.Access_Type__c ='Exhibitor';
        cem.Popup_Marked_as_Read__c = true;
        insert cem; 
        return cem;
    }
    
    public static Contact_Edition_Mapping__c createContactEditionMapping2(Id contactId,Id accountId,Id EditionId)
    {
        Contact_Edition_Mapping__c cem = new Contact_Edition_Mapping__c();
        cem.Contact__c = contactId;
        cem.Edition__c = EditionId;
        cem.Relationship_Status__c = 'Inactive';
        cem.Account__c = accountId;
        cem.Role__c = 'Team Member';
        cem.Access_Type__c ='Agent';
        cem.Popup_Marked_as_Read__c = true;
        cem.isTestUser__c = True;
        insert cem; 
        return cem;
    }
    
    public static List<Event_Tabs__c> createEventTabListData(Id eveSetting, Integer numDocs)
    {
        List<Event_Tabs__c> evntTabsLst = new List<Event_Tabs__c>();
        for(integer i=0; i<numDocs; i++){
            Event_Tabs__c evntTabs = new Event_Tabs__c();
            evntTabs.Event_Setting__c = eveSetting;
            evntTabs.Is_Tab_Active__c = true;
            evntTabs.Is_Tab_Visible__c = true;
            evntTabs.Layout_Type__c = '3 Column';
            evntTabs.Sequence__c = i;
            evntTabs.Tab_Title__c = 'Test Tab '+i;
            evntTabs.Tab_Type__c = 'Custom';
            evntTabsLst.add(evntTabs);
        }
        insert evntTabsLst;
        return evntTabsLst;
    }
    
    public static List<Tab_User_Type__c> createEventntTabUserTypeData(Id eveTab, Id editionPopup,Integer numDocs)
    {
        List<Tab_User_Type__c > tabUserLst = new List<Tab_User_Type__c >();
        for(integer i = 0; i<numDocs; i++){
            Tab_User_Type__c tabUser = new Tab_User_Type__c();
            tabUser.Event_Tab__c = eveTab;
            tabUser.User_Type__c = 'Exhibitor';
            tabUser.Edition_Popup__c = editionPopup;
            tabUserLst.add(tabUser);
        }
        insert tabUserLst;
        return tabUserLst;
    }
    
    public static List<Tab_User_Type__c> createEventntTabUserTypeData2(Id eveTab, Id editionPopup,String accessType,Integer numDocs)
    {
        List<Tab_User_Type__c > tabUserLst = new List<Tab_User_Type__c >();
        for(integer i = 0; i<numDocs; i++){
            Tab_User_Type__c tabUser = new Tab_User_Type__c();
            tabUser.Event_Tab__c = eveTab;
            tabUser.User_Type__c = accessType;
            tabUser.Edition_Popup__c = editionPopup;
            tabUserLst.add(tabUser);
        }
        insert tabUserLst;
        return tabUserLst;
    }
    
    public static List<Document> createDocument(Integer numDocs)
    {
        List<Document> docs = new List<Document>(); 
        for(Integer i=0; i<numDocs; i++){
            Document d=new Document(Name='TEV17-Event-Image'+i, FolderId=UserInfo.getUserId(), IsPublic=true, Body=Blob.valueOf('Some Text'), ContentType = 'image/jpeg');
            docs.add(d);
        }
        insert docs;
        return docs;
    }
    
    public static List<Tab_Context__c> createTabContext2(Id eveTab, Integer numDocs)
    {
        List<Tab_Context__c> listTabContext = new List<Tab_Context__c>();
        for(integer i = 0; i<numDocs; i++){
            Tab_Context__c tab = new Tab_Context__c();
            tab.Event_Tab__c = eveTab;
            tab.Publish_Changes__c = false;
            tab.Last_Published_Number__c = 1;
            listTabContext.add(tab);
        }
        insert listTabContext;
        listTabContext[0].Publish_Changes__c = true;
        update listTabContext;
        return listTabContext;
    }
    
    public static List<Tab_Context__c> createTabContext3(Id eveTab, Integer numDocs)
    {
        List<Tab_Context__c> listTabContext = new List<Tab_Context__c>();
        for(integer i = 0; i<numDocs; i++){
            Tab_Context__c tab = new Tab_Context__c();
            tab.Event_Tab__c = eveTab;
            tab.Publish_Changes__c = false;
            listTabContext.add(tab);
        }
        insert listTabContext;
        listTabContext[0].Publish_Changes__c = true;
        update listTabContext;
        return listTabContext;
    }
    
    public static List<ContentVersion> createContentVer(Integer numCntnVer)
    {
        List<ContentVersion> cntntVerLst = new List<ContentVersion>(); 
        for(Integer i=0; i<numCntnVer; i++){
            ContentVersion cntntVer=new ContentVersion(title = 'Test PDf'+i,PathOnClient= 'test',VersionData=Blob.valueOf('Some Text'));
            cntntVerLst.add(cntntVer);
        }
        insert cntntVerLst;
        return cntntVerLst;
    }
    
    public static List<ContentDocumentLink> createContentDocLink(Id cntntDocId, Id linkEntId, Integer numCntnt)
    {
        List<ContentDocumentLink> cntntDocLinkLst = new List<ContentDocumentLink>(); 
        for(Integer i=0; i<numCntnt; i++){
            ContentDocumentLink cntntDocLink=new ContentDocumentLink(contentdocumentid = cntntDocId, LinkedEntityId = linkEntId, ShareType = 'V');
            cntntDocLinkLst.add(cntntDocLink);
        }
        insert cntntDocLinkLst;
        return cntntDocLinkLst;
    }
    
    public static user createCommunityUser(Id ContactId)
    {
        Profile p = [SELECT Id FROM Profile WHERE Name= 'IM Customer Community Login User'];
        User user = new User(Alias = 'standt', Email='davidjones@test.com',
                             EmailEncodingKey='UTF-8', LastName='Kumar', LanguageLocaleKey='en_US', 
                             LocaleSidKey='en_US', ProfileId = p.Id,ContactID=ContactId,IsActive=true,
                             TimeZoneSidKey='America/Los_Angeles', UserName='CommunityUser1@testorg.com');
        insert user; 
        return user;
    }
    
    public static user createCommunityUser2(Id ContactId)
    {
        Profile p = [SELECT Id FROM Profile WHERE Name= 'IM Customer Community Login User'];
        User user = new User(Alias = 'standt', Email='davidjones1122@test.com',
                             EmailEncodingKey='UTF-8', LastName='Kumar2', LanguageLocaleKey='en_US', 
                             LocaleSidKey='en_US', ProfileId = p.Id,ContactID=ContactId,
                             TimeZoneSidKey='America/Los_Angeles', UserName='CommunityUser22@testorg.com');
        insert user; 
        return user;
    }
    
    
    
    public static List<Questionnaire__c> createGirikonForm(Integer numForms){
        List<Questionnaire__c> girikonForms = new List<Questionnaire__c>();
        for(Integer i=0; i<numForms; i++){
            Questionnaire__c q=new Questionnaire__c(Name='Test Form'+i,Category__c='Form');
            girikonForms.add(q);
        }
        insert girikonForms;
        return girikonForms;
    }
    
    public static List<Form_Setting__c> createFormSettings(Integer numFormSettings){
        List<Form_Setting__c> formSettings = new List<Form_Setting__c>();
        for(Integer i=0; i<numFormSettings; i++){
            Form_Setting__c formSet = new Form_Setting__c(Description__c='Form Setting'+i);
            formSettings.add(formSet);
        }
        insert formSettings;
        return formSettings;
    }
    
    public static List<Form_Allocation__c> createFormAlloc(Id girikonFormId, Id formSettingId, Integer size){
        List<Form_Allocation__c> listFormAlloc = new List<Form_Allocation__c>();
        for(Integer i=0; i<size; i++){
            Form_Allocation__c formAlloc = new Form_Allocation__c(Form_Setting__c=formSettingId,Form__c=girikonFormId,Booth_Product_Types__c='Space Only',Form_Status__c='Visible');
            listFormAlloc.add(formAlloc);
        }
        insert listFormAlloc;
        return listFormAlloc;
    }
    
    public static Form_Allocation__c createFormAllocation(Id girikonFormId, Id formSettingId){
        Form_Allocation__c formAlloc = new Form_Allocation__c(Form_Setting__c=formSettingId,Form__c=girikonFormId,Booth_Product_Types__c='Space Only',Form_Status__c='Visible');
        insert formAlloc;
        return formAlloc;
    }
    
    public static Form_Allocation__c createFormAllocationWithEmail(Id girikonFormId, Id formSettingId){
        Form_Allocation__c formAlloc = new Form_Allocation__c(Form_Setting__c=formSettingId,Form__c=girikonFormId,Booth_Product_Types__c='Space Only',Send_individual_forms__c=true,Email_To__c='test@test.com,test1@test.com',Form_Status__c='Visible');
        insert formAlloc;
        return formAlloc;
    }
    
    public static Form_Allocation__c createFormAllocationWithHeading(Id girikonFormId, Id formSettingId,string heading){
        Form_Allocation__c formAlloc1 = new Form_Allocation__c(Feature_Category__c='Form',Form_Setting__c=formSettingId,Form__c=girikonFormId,Booth_Product_Types__c='Space Only',
                                                               Send_individual_forms__c=true,Form_Type__c='Online',Submission_Deadline__c=Date.Today(),Email_To__c='test@test.com,test1@test.com',Form_Heading__c=heading,Form_Status__c='Visible');
        system.debug('Form Alloc ' +formAlloc1);
        insert formAlloc1;
        return formAlloc1;
        
    }
    
    public static Form_Allocation__c createFormAllocation1(String featureCat, String formType,Id girikonFormId, Id formSettingId, string entryType){
        Form_Allocation__c formAlloc1 = new Form_Allocation__c(Feature_Category__c=featureCat,Form_Type__c=formType,Form_Setting__c=formSettingId,Form__c=girikonFormId,Booth_Product_Types__c='Space Only',Send_individual_forms__c=true,Email_To__c='test@test.com,test1@test.com',Form_Heading__c='Mandatory',Form_Status__c='Visible',Form_Entry__c = entryType);
        system.debug('Form Alloc ' +formAlloc1);
        insert formAlloc1;
        return formAlloc1;
        
    }
    public static Form_Allocation__c createFormAllocation2(String featureCat, String formType,Id girikonFormId, Id formSettingId, string entryType){
        Form_Allocation__c formAlloc2 = new Form_Allocation__c(Feature_Category__c=featureCat,Form_Type__c=formType,Form_Setting__c=formSettingId,Form__c=girikonFormId,Booth_Product_Types__c='Space Only',Send_individual_forms__c=true,Email_To__c='test@test.com,test1@test.com',Form_Heading__c='Mandatory',Form_Status__c='Visible',Form_Entry__c = entryType,Entry_Limit__c=3);
        system.debug('Form Alloc ' +formAlloc2);
        insert formAlloc2;
        return formAlloc2;
        
    }
    
    /*public static Form_Submission_Status__c createFormSubmissionStatus(Id userId,Id girikonFormId){
Form_Submission_Status__c formsub = new Form_Submission_Status__c(User__c=userId, Girikon_Form__c=girikonFormId, Status__c='Viewed');
insert formsub;
return formsub;
}
public static Form_Submission_Status__c createFormSubmissionStatus2(Id girikonFormId,Id conMapId){
Form_Submission_Status__c formsub = new Form_Submission_Status__c(Girikon_Form__c=girikonFormId,Contact_Edition_Mapping__c = conMapId);
insert formsub;
return formsub;
}
public static Form_Submission_Status__c createFormSubmissionStatusSubmitted(Id girikonFormId,Id conMapId,Id userId){
Form_Submission_Status__c formsub = new Form_Submission_Status__c(Girikon_Form__c=girikonFormId,Contact_Edition_Mapping__c = conMapId,Status__c='Submitted',User__c=userId);
insert formsub;
return formsub;
}*/
    
    public static List<Tab_User_Type__c> createTabUserTypeFormAlloc(Id formAlloc, Integer numTabUsr, String userType)
    {
        List<Tab_User_Type__c> tabUsrTypeLst = new List<Tab_User_Type__c>();
        for(Integer i=0;i<numTabUsr;i++){
            Tab_User_Type__c tabUsrType=new Tab_User_Type__c(Form_Allocation__c = formAlloc,User_Type__c = userType);
            tabUsrTypeLst.add(tabUsrType);
        }
        insert tabUsrTypeLst;
        return tabUsrTypeLst;
    }
    public static List<Forms_Permission__c> createFormsPermission(Id tabUser, Id formAlloc, Integer numFormPerm)
    {
        List<Forms_Permission__c> formPermLst = new List<Forms_Permission__c>();
        for(integer i=0; i<numFormPerm; i++){
            Forms_Permission__c formPerm = new Forms_Permission__c(Form_Allocation__c = formAlloc,Tab_User_Type__c = tabUser,Is_Active__c=true);
            formPermLst.add(formPerm);
        }
        insert formPermLst;
        return formPermLst;
    }
    
    public static List<Form_Data__c> createFormData(Id conMapId, Id formPermId, Integer numFormData)
    {
        List<Form_Data__c> formDataLst = new List<Form_Data__c>();
        for(integer i=0; i<numFormData; i++){
            Form_Data__c formData = new Form_Data__c(Contact_Edition_Mapping__c = conMapId,Forms_Permission__c = formPermId);
            formDataLst.add(formData);
        }
        insert formDataLst;
        return formDataLst;
    }
    
    public static List<Form_Data__c> createFormData2(Id conMapId, Id formPermId, Integer numFormData,Id editionId, Id AccountId) 
    {
        List<Form_Data__c> formDataLst = new List<Form_Data__c>();
        for(integer i=0; i<numFormData; i++){
            Form_Data__c formData = new Form_Data__c(Contact_Edition_Mapping__c = conMapId,Forms_Permission__c = formPermId,Account__c = AccountId, Edition__c =editionId);
            formDataLst.add(formData);
        }
        insert formDataLst;
        return formDataLst;
    }
    
    public static List<Form_Data__c> createFormDataWithFormSubmission(Id conMapId, Id formPermId, Id formsubm, Id userId, Integer numFormData)
    {
        List<Form_Data__c> formDataLst = new List<Form_Data__c>();
        for(integer i=0; i<numFormData; i++){
            Form_Data__c formData = new Form_Data__c(Contact_Edition_Mapping__c = conMapId,Forms_Permission__c = formPermId);
            formDataLst.add(formData);
        }
        insert formDataLst;
        return formDataLst;
    }
    
    public static List<Form_Response_Entry__c> createFormRespEntry(Id formDataId,Id cemId, Integer numRespEnt, Id purchaseDataId){
        List<Form_Response_Entry__c> formRespEntryLst = new List<Form_Response_Entry__c>();
        for(Integer i=0;i<numRespEnt;i++){
            Form_Response_Entry__c formRespEnt = new Form_Response_Entry__c(Contact_Edition_Mapping__c =cemId,Form_Data__c=formDataId,Purchase_Data__c=purchaseDataId,Current_Page_No__c=0,Total_Pages__c=0,Entry_Number__c=i,Approval_Status__c =' Not Required');
            formRespEntryLst.add(formRespEnt);
        }
        insert formRespEntryLst;
        return formRespEntryLst;
    }
    
    public static List<Question__c> createQuestions(){
        List<Question__c> questList = new List<Question__c>();
        Question__c quest = new Question__c(Label__c='Test Question1',Type__c='TextPlain');
        Question__c quest1 = new Question__c(Label__c='Test Question2',Type__c='Picklist');
        questList.add(quest);
        questList.add(quest1);
        insert questList;
        return questList;
    }
    
    public static List<Question_Option__c> createQuestionOptions(Id questionId){
        List<Question_Option__c> questOptionList = new List<Question_Option__c>();
        Question_Option__c qo1 = new Question_Option__c(Name__c='Picklist1',Name_Long__c='Picklist1',Question__c =questionId);
        Question_Option__c qo2 = new Question_Option__c(Name__c='Picklist2',Name_Long__c='Picklist2',Question__c =questionId);
        questOptionList.add(qo1);
        questOptionList.add(qo2);
        insert questOptionList;
        return questOptionList;
    }
    
    public static Question_Response__c createQuestionResponse(Id formId,Id questionId,Id userId,String answer){
        Question_Response__c qr = new Question_Response__c(Questionnaire__c=formId,Question__c=questionId,User__c=userId,Answer__c=answer);
        insert qr;
        return qr;
    }
    
    public static Question_Response__c createQuestionResponse2(Id formId,Id questionId,Id userId,String answer,Id formRespId){
        Question_Response__c qr = new Question_Response__c(Questionnaire__c=formId,Question__c=questionId,User__c=userId,Answer__c=answer,Form_Response_Entry__c=formRespId);
        insert qr;
        return qr;
    }
    
    
    public static List<Badge_Setting__c> createBadgeSetting(Integer numEvtSet){
        List<Badge_Setting__c> badgeSet = new List<Badge_Setting__c>();
        for(Integer i=0;i<numEvtSet;i++){
            Badge_Setting__c bs=new Badge_Setting__c(Description__c = 'Test Event'+i);
            badgeSet.add(bs);
        }
        insert badgeSet;
        return badgeSet;
    }
    
    public static List<Stand_Setting__c> createStandSetting(Integer numEvtSet){
        List<Stand_Setting__c> standSet = new List<Stand_Setting__c>();
        for(Integer i=0;i<numEvtSet;i++){
            Stand_Setting__c ss = new Stand_Setting__c(Name = 'Test-'+i);
            standSet.add(ss);
        }
        insert standSet;
        return standSet;
    }
    
    public static List<Badge_Allocation__c> createBadgeAllocationSetting(Id badgeSetting, String boothProdType, Integer numEvtSet){
        List<Badge_Allocation__c> badgeAllocateSet = new List<Badge_Allocation__c>();
        for(Integer i=0;i<numEvtSet;i++){
            Badge_Allocation__c bAs=new Badge_Allocation__c(Badge_Numbers__c = 10 + i,Booth_Product_Type__c = boothProdType
                                                            ,Badge_Setting__c = badgeSetting,Lower__c = (10 * i)
                                                            ,Upper__c = (10 * i)+10);
            badgeAllocateSet.add(bAs);
        }
        insert badgeAllocateSet;
        return badgeAllocateSet;
    }
    /*
public static Purchase_Summary__c createPurchaseSummary(String eventSetting,String eventTab){
Purchase_Summary__c ps = new  Purchase_Summary__c();
ps.Event_Setting__c = eventSetting;
ps.Event_Tab__c = eventTab;
ps.Name='Test';
ps.External_Link__c='https://test.com';
ps.External_Link_Label__c='test link';
ps.Information_Label__c='test';
Insert ps;
return ps;
}*/
    
    public static Announcement__c createAnnouncementData(Id eid){
        //ceid => contact edition mapping
        Announcement__c a = new Announcement__c();
        Date startDate = System.now().Date();
        Date endDate = System.now().Date();
        endDate = endDate.addDays(3);
        startDate = startDate.addDays(-3);
        a.Announcement_Date__c = startDate;
        a.Booth_Product_Types__c = 'Space Only';
        a.Description__c = 'test';
        a.Edition__c = eid;
        a.Expiration_Date__c = endDate;
        a.Is_Active__c = true;
        a.Title__c = 'tets';
        a.URL__c='https://www.test.com';
        a.URL_Label__c='Read more';
        Insert a;
        return a;
    }
    
    public static Announcement__c createAnnouncementData2(Id eid, Id eventTabId){
        //ceid => contact edition mapping
        Announcement__c a = new Announcement__c();
        Date startDate = System.now().Date();
        Date endDate = System.now().Date();
        endDate = endDate.addDays(3);
        startDate = startDate.addDays(-3);
        a.Announcement_Date__c = startDate;
        a.Booth_Product_Types__c = 'Space Only';
        a.Description__c = 'test';
        a.Edition__c = eid;
        a.Expiration_Date__c = endDate;
        a.Is_Active__c = true;
        a.Title__c = 'tets';
        a.URL__c='https://www.test.com';
        a.URL_Label__c ='Read more';
        a.Event_Tab__c = eventTabId;
        Insert a;
        return a;
    }
    
    public static TempContact__c createTempContactData(){
        TempAccount__c temAcc = new TempAccount__c();
        temAcc.Address__c ='B-24 Sec 65';
        temAcc.City__c ='Noida';
        temAcc.Country__c ='India';
        temAcc.State__c ='Delhi';
        temAcc.Zip__c ='201301';
        insert temAcc;
        TempContact__c tempContact = new TempContact__c();
        tempContact.Name ='Test Test';
        tempContact.FirstName__c='Tets';
        tempContact.LastName__c='Test';
        tempContact.MobilePhone__c='(000) 238-1122';
        tempContact.Phone__c='9328820238';
        tempContact.Country_Code__c='+91';
        tempContact.Email__c='test@tets.com';
        tempContact.TempAccount__c=temAcc.Id;
        Insert tempContact;
        return tempContact;
    }
    
    public static List<Badge_Data__c> createBadgeData(Id pdDataId,Integer numEvtSet){
        List<Badge_Data__c> badgeDataSet = new List<Badge_Data__c>();
        for(Integer i=0;i<numEvtSet;i++){
            Badge_Data__c bd = new Badge_Data__c(First_Name__c= 'abcd'+i, Last_Name__c= 'test'+i, Email__c = 'abc@test.com'
                                                 , Job_Title__c= 'analyst',Purchase_Data__c = pdDataId);
            badgeDataSet.add(bd); 
        }
        insert badgeDataSet;
        return badgeDataSet;
    }
    
    public static List<Contractor_Mapping__c> createContractorMappingData(Id accId,Id conId,Id cEMId,Id pdDataId,string contractorStatus,Id editionId,string rejectReason,Integer numEvtSet){
        List<Contractor_Mapping__c> contractorMappingDataSet = new List<Contractor_Mapping__c>();
        for(Integer i=0;i<numEvtSet;i++){
            Contractor_Mapping__c cm = new Contractor_Mapping__c(Account__c = accId, Contact__c =conId , Contractor_CEM__c = cEMId
                                                                 ,Contractor_Status__c = contractorStatus, Edition__c = editionId
                                                                 ,Rejection_Reason__c= rejectReason);
            contractorMappingDataSet.add(cm); 
        }
        insert contractorMappingDataSet;
        update (new Purchase_Data__c(Id=pdDataId,Contractor_Mapping__c=contractorMappingDataSet[0].Id));
        return contractorMappingDataSet;
    }
    
    public static List<Contractor_Mapping__c> createConMapping(Id tempCon, Id accId, Id contactId, Id editionObjId, Id cemObj, Id booth){
        List<Contractor_Mapping__c> contractorMappingDataSet = new List<Contractor_Mapping__c>();
        
        Contractor_Mapping__c cm = new Contractor_Mapping__c(Account__c = accId, Contact__c =contactId, Contractor_CEM__c = cemObj,
                                                             Edition__c = editionObjId,TempContact__c =tempCon,Approved__c = false);
        contractorMappingDataSet.add(cm); 
        insert contractorMappingDataSet;
        update (new Purchase_Data__c(Id=booth,Contractor_Mapping__c=contractorMappingDataSet[0].Id));
        return contractorMappingDataSet;
    }
    
    public static Customer_Services_Team__c createChatSupport(){
        Customer_Services_Team__c cs = new Customer_Services_Team__c();
        cs.AgentDevName__c = 'EmbeddedServiceLiveAgen';
        cs.Button_ID__c = 'Test Button';
        cs.Chat_Deployment__c = 'UAT_ME_Chat_Deployment';
        cs.Deployment_Id__c = 'Deployment Ids';
        cs.SupportTeam__c = 'ME Team';
        cs.baseLiveAgentContentURL__c = 'https://c.la1-c1cs-ia2.salesforceliveagent.com/content'; 
        cs.baseLiveAgentURL__c = 'https://d.la1-c1cs-ia2.salesforceliveagent.com/chat';
        insert cs;
        return cs;
    }
    
    public static Edition__c createEdition(Id eventSeriesId,Id editionImageURL, Id eveSetting, Id ChatSupport)
    {
        Edition__c edition=new Edition__c(Name = 'Test Event 2021', Part_of_Series__c = eventSeriesId, Edition_Code__c ='TEV21',
                                          End_Date__c = System.Today(), Start_Date__c = System.Today(), Edition_Status__c = 'Confirmed',
                                          Edition_Website__c = 'http://www.testevent.com', Edition_Image_URL__c = editionImageURL,
                                          Customer_Center_Status__c='Active',Event_Setting__c = eveSetting,Contractor_Nomination_Due_Date__c= System.Today(),
                                          Stand_Design_Completion_Due_Date__c= System.Today(),IM_EventEditionId__c='a3dwsdefghtrdbjh',Customer_Support_Team__c=ChatSupport,
                                          Live_Agent_Online__c=true); 
        insert edition;
        return edition;
    }
    
    
    public static List<Email_Templates__c> createEmailTemplate(){
        List<Email_Templates__c> listEmailTemp = new List<Email_Templates__c>();
        Email_Templates__c et = new Email_Templates__c();
        et.Name ='Form Approval';
        et.Subject__c ='Form Approval Email';
        et.Template_Code__c ='IMF';
        et.Content__c ='Hello Welcome';
        listEmailTemp.add(et);
        insert listEmailTemp;
        return listEmailTemp;
    }
    
    public static List<Email_Templates__c> createEmailTemplateWelcome(){
        List<Email_Templates__c> listEmailTemp = new List<Email_Templates__c>();
        Email_Templates__c et = new Email_Templates__c();
        et.Name ='Welcome Email';
        et.Subject__c ='{Event Name} - Exhibitor Manual is Live';
        et.Template_Code__c ='WELNew';
        et.Content__c ='Hello {COMPANY NAME} {Firstname} {UserName}';
        listEmailTemp.add(et);
        insert listEmailTemp;
        return listEmailTemp;
    }
    
    public static Email_Templates__c updateEmailTemplate(){
        Email_Templates__c et = new Email_Templates__c();
        et.Name ='User Email Update';
        et.Subject__c ='Exhibitor Manual email change';
        et.Template_Code__c ='UEMAILUPD';
        et.Content__c ='Hello {FirstName} {UserEmail}';
        insert et;
        return et;
    }
    
    public static Email_Templates__c createEmailTemplateNotification(String Name,String Subject,string tempCode,String content){
        Email_Templates__c et = new Email_Templates__c();
        et.Name = Name;
        et.Subject__c = Subject;
        et.Template_Code__c = tempCode;
        et.Content__c = content;
        insert et;
        return et;
    }
    
    public static List<Email_Templates__c> createEmailTemplateWelcomeTestUser(){
        List<Email_Templates__c> listEmailTemp = new List<Email_Templates__c>();
        Email_Templates__c et = new Email_Templates__c();
        et.Name ='Welcome Email for Tester';
        et.Subject__c ='{Event Name} : for Test Data';
        et.Template_Code__c ='WELEMAILForTestData';
        et.Content__c ='Hello {Event Name} {Access Type} {Booth Type} {Username}';
        listEmailTemp.add(et);
        insert listEmailTemp;
        return listEmailTemp;
    }
    
    public static List<Event_Edition_Email_Template__c> createEditionEmailTemplate(string ed, String etemp,List<String> codes){
        List<Event_Edition_Email_Template__c> listEmailTemp = new List<Event_Edition_Email_Template__c>();
        for(String code : codes){
            Event_Edition_Email_Template__c et = new Event_Edition_Email_Template__c();
            et.Name ='Form Resubmission';
            et.Subject__c ='Form Approval Email {Company Name} {Customer Name} {Form Name} {Event Name} {Event Code} {Form Deadline} {Form Entry} {Form Type} {Form Submission Date} {Booth Dimension} {Booth Size} {Booth Number}';
            et.Template_Code__c = code;
            et.Content__c = 'Hello Welcome {Company Name} {Customer Name} {Form Name} {Event Name} {Event Code} {Form Deadline} {Form Entry} {Form Type} {Form Submission Date} {Booth Dimension} {Booth Size} {Booth Number}';
            et.Email_Template__c = etemp;
            et.Edition__c = ed;
            et.From_Email_Address__c = 'aishwarya.c.kumar@informa.com';
            listEmailTemp.add(et);
        }
        insert listEmailTemp;
        return listEmailTemp;
    }
    
    public static Event_Edition_Email_Template__c createEditionEmailTemplate2(Id ed, Id etemp,String Name,String Subject,string tempCode,String content){
        Event_Edition_Email_Template__c et = new Event_Edition_Email_Template__c();
        et.Name = Name;
        et.Subject__c = Subject;
        et.Template_Code__c = tempCode;
        et.Content__c = content;
        et.Email_Template__c = etemp;
        et.Edition__c = ed;
        et.From_Email_Address__c = 'aishwarya.c.kumar@informa.com';
        insert et;
        return et;
    }
    
    public static List<Form_Response_Entry__c> createFormRespEntry2(Id formDataId,Id cemId, Integer numRespEnt, Id purchaseDataId,Id edition, Id accId, Id userId){
        List<Form_Response_Entry__c> formRespEntryLst = new List<Form_Response_Entry__c>();
        Purchase_Data__c purData=new Purchase_Data__c(Contact_Edition_Mapping__c = cemId, Account__c =accId,Booth_Product_Type__c = 'Space Only',Quantity_Area__c=30, 
                                                      Booth_Number__c = 'H2.11',Booth_Dimension__c='5*12',Purchase_Status__c = 'Active', Transaction_Status__c ='Active');
        insert purData;
        for(Integer i=0;i<numRespEnt;i++){
            Form_Response_Entry__c formRespEnt = new Form_Response_Entry__c(Contact_Edition_Mapping__c =cemId,Rejection_Reason__c='Rejected',Form_Data__c=formDataId,
                                                                            Purchase_Data__c=purData.Id,Current_Page_No__c=0,Total_Pages__c=0,Entry_Number__c=i,Event_Name__c=edition,
                                                                            Approval_Status__c =' Not Required',Submission_Date__c=Date.Today()+7,Company_Name__c=accId,User__c=userId,Response_Status__c='Submitted'
                                                                           );
            formRespEntryLst.add(formRespEnt);
        }
        insert formRespEntryLst;
        return formRespEntryLst;
    }
    public static List<Email_Templates__c> createEditionEmailTemplate3(){
        List<Email_Templates__c> listEmailTemp = new List<Email_Templates__c>();
        Email_Templates__c et = new Email_Templates__c();
        et.Name ='Form Approval';
        et.Subject__c ='Form Approval Email';
        et.Template_Code__c ='IMF';
        et.Content__c ='Hello Welcome';
        listEmailTemp.add(et);
        insert listEmailTemp;
        return listEmailTemp;
    }
    public static List<Trigger__c> createTriggerRecodOfContact(){
        List<Trigger__c> listTrigger = new List<Trigger__c>();
        Trigger__c trig = new Trigger__c();
        trig.Trigger_Name_Unique__c ='IMCC_ContactTriggerHandler';
        trig.Name ='IMCC_ContactTriggerHandler';
        trig.Object__c = 'Contact';
        trig.Execution_Order__c =7;
        trig.Enabled__c =true;
        trig.After_Update__c = true;
        trig.Run_for_Recordypes__c = 'All';
        listTrigger.add(trig);
        insert listTrigger;
        return listTrigger;
    }
}