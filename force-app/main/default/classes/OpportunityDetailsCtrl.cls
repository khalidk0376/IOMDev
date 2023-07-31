/**
 * Created By       :   Girikon(Sachin)
 * Created On       :   18 Dec 2019
 * @description     :   This class is used in opportunity lightning lauout.
 * Test Class       :   OpportunityCtrl_Test
 **/
public with sharing class OpportunityDetailsCtrl {
  /**
   * @description [Fetch sObject records for custom lookup]
   * @param  objectName   [Object name]
   * @param  nameFieldApi [Object fields name]
   * @param  searchKey    [Searchy Key]
   * @param  accId        [Account Id]
   * @param  partnerAccId [Partnet Account Id]
   * @param  isBilling    [Fetch only billing types records]
   * @return              [List Of sObject]
   */
    
  @AuraEnabled
  public static RecordDataTableWrapper getLookupDatas(String objectName, String nameFieldApi, String searchKey, String accId, String partnerAccId, Boolean isBilling, Decimal pageNumber, Decimal pageSize) {
    set<id> accIds = new set<id>();
    set<id> conIds = new set<id>();
        
    if (String.isNotBlank(accId)) {
      accIds.add(accId);
    }
        
    if (String.isNotBlank(partnerAccId)) {
      accIds.add(partnerAccId);
    }
        
    for (AccountPartner objAccountPartner : [select AccountToId from AccountPartner where AccountFromId = :accId]) {
      accIds.add(objAccountPartner.AccountToId);
    }
        
    for (AccountContactRelation objAccountContactRelation : [select ContactId from AccountContactRelation where AccountId = :accId and IsDirect = false and Contact.Inactive__c = false]) {
      conIds.add(objAccountContactRelation.ContactId);
    }
    string strCountQuery = 'Select COUNT() FROM ' + String.escapeSingleQuotes(objectName) + '  ';
    string strQuery = 'Select Contact_Type__c,Account.Name,Account.BillingCity,Account.BillingCountry,' + String.escapeSingleQuotes(nameFieldApi) + ' FROM ' + String.escapeSingleQuotes(objectName) + '  ';
        string whereClause = ' WHERE ( AccountId IN :accIds AND Inactive__c = false  AND Contact_Type__c != NULL ';
    string slikeQuery ;
        
    if (isBilling) {
      whereClause = whereClause + ' AND Contact_Type__c INCLUDES (\'Billing\',\'Invoice Contact\') ';
    }
        System.debug('searchKey' +searchKey);
    if (String.isNotBlank(searchKey)) {
      searchKey = String.escapeSingleQuotes('%' + searchKey + '%');            
      whereClause = whereClause + ' AND ' + String.escapeSingleQuotes(nameFieldApi) + ' LIKE:searchKey ';
            //BK-1758 
            slikeQuery = String.escapeSingleQuotes(nameFieldApi) + ' LIKE:searchKey ';
            system.debug('slikeQuery===' + slikeQuery);            
    }
        //BK-1758
        if (String.isNotBlank(slikeQuery)){
            whereClause = whereClause + ' ) OR ( Id IN :conIds  AND ' + slikeQuery + ') ';
        }
        else {
              whereClause = whereClause + ' ) OR Id IN :conIds '; 
        }
        //BK-1758
        /*
         BK-1909 
        */
        String SearchQuery = strQuery + ' ' + whereClause ;
    strQuery = strQuery + ' ' + whereClause + ' ORDER BY ' + String.escapeSingleQuotes(nameFieldApi) + ' ASC LIMIT :pSize OFFSET :offset';
                
    strCountQuery = strCountQuery + ' ' + whereClause;
    System.debug(JSON.serialize(accIds));
    System.debug(JSON.serialize(conIds));
    Set<sobject> lstContacts = new Set<sobject>();
    Integer pSize = (Integer)pageSize;
    Integer pNumber = (Integer)pageNumber;
        
    //Offset for SOQL
    Integer offset = (pNumber - 1) * pSize;
        
    system.debug('offset===' + offset);
    //Total Records
    Integer totalRecords = database.countQuery(strCountQuery);
    Integer recordEnd = pSize * pNumber;

    //Instance of Contact DataTable Wrapper Class
    RecordDataTableWrapper objDT =  new RecordDataTableWrapper();
    objDT.pageSize = pSize;
    objDT.pageNumber = pNumber;
    objDT.recordStart = offset + 1;
    objDT.recordEnd = totalRecords >= recordEnd ? recordEnd : totalRecords;
    objDT.totalRecords = totalRecords;
    system.debug('strQuery===' + strQuery);    
        /*
         BK-1909
        */
        if(String.isNotBlank(searchKey))
        {                    
          lstContacts.addAll(Database.query(SearchQuery));
          objDT.recordList = lstContacts;
        }
        else
        {
          lstContacts.addAll(Database.query(strQuery));
          objDT.recordList = lstContacts;                 
        }
       
    return objDT; 
  }

  //Wrapper Class For Contact DataTable
  public class RecordDataTableWrapper {
    @AuraEnabled
    public Integer pageSize {get; set;}
    @AuraEnabled
    public Integer pageNumber {get; set;}
    @AuraEnabled
    public Integer totalRecords {get; set;}
    @AuraEnabled
    public Integer recordStart {get; set;}
    @AuraEnabled
    public Integer recordEnd {get; set;}
    @AuraEnabled
    public set<sObject> recordList {get; set;}
  }
  //Wrapper Class For picklist values for Sales for 
  //Added by Avinash for JIRA Ticket : GGCW-3355
  public class exhibPaidByValue {
    @AuraEnabled
    public String label {get; set;}
    @AuraEnabled
    public String value {get; set;}
  }

  /**
   * @description [Fetch ureent user details]
   * @return [user record]
   */
  @AuraEnabled
  public static user getCurrentUserDtls() {
    return  LtngUtilityCtrl.getCurrentUserDtls();
  }

  /**
   * @description [Fetch account contact relationships]
   * @param  recordId [Record id to fetch the object record]
   * @return          [List of sObject]
   */
  @AuraEnabled
  public static List<sObject> getRecord(String recordId, String objectName, String fields) {
    return LtngUtilityCtrl.getRecord(recordId, objectName, fields);
  }
  /**
   * @description [get quotes,quoteLines,allowed profiles data]
   * @param  recordId   [recordId to match]
   * @param  objectName [objectName from which records need to fetch]
   * @param  fields     [field names for object]
   * @return            [map of string ad object]
   */
  @AuraEnabled
  public static Map<String, Object> getAllDatas(String recordId, String objectName, String fields) {
    User u = LtngUtilityCtrl.getCurrentUserDtls();
    List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();
    List<SBQQ__Quote__c> quotes = [Select Id, Name from SBQQ__Quote__c WHERE SBQQ__Primary__c = true AND SBQQ__Opportunity2__c = :recordId];
    String quoteId = null;
    if (quotes.size() > 0) {
      quoteId = quotes[0].Id;
      quoteLines = [Select Id, Name From SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :quoteId];
    }

    return new Map<String, Object> {
      'userDetail' =>  u,
      'oppDetail' =>  LtngUtilityCtrl.getRecord(recordId, objectName, fields),
      'allowProfile' => [Select id, Name from AllowedProfiles__c WHERE Name = :u.Profile.Name],
      'primaryQuote' => quotes,
      'primaryQuoteProducts' => quoteLines
    };
  }

  /**
  * @description [Fetch event alternate currencies]
  * @param  eventId [Event id]
  * @return         [List of event currecies]
  */
  @AuraEnabled
  public static List<EventCurrecies__c> getEventCurrency(String eventId) {
    List<EventCurrecies__c> getevtCurrency = new List<EventCurrecies__c>();
    if (Schema.sObjectType.EventCurrecies__c.isAccessible()) {
      getevtCurrency = [select Id, Name from EventCurrecies__c where Event_Edition__c = :eventId];
    }
    return getevtCurrency;
  }
  /**
   * @description  [Update Opportunity with alternate currency]
   * @param  oppDtls [opportunity object to update]
   * @return         [Boolean]
   */
  @AuraEnabled
  public static boolean updateOpportunity(Opportunity oppDtls) {
        try{
            System.debug(oppDtls);
            update oppDtls;
        }
        catch(Exception e){
            system.debug(e.getMessage());
        }
        system.debug(oppDtls);
    return true;
  }

  /**
   * @description [Check user access]
   * @param  recordId [Record Id to check access permission]
   * @return          [List of UserRecordAccess]
   */
  @AuraEnabled
  public static list<UserRecordAccess> getUserRecordAccess(string recordId) {
    List<UserRecordAccess> getUsrRecord = new List<UserRecordAccess>();
    if (Schema.sObjectType.UserRecordAccess.isAccessible()) {
      getUsrRecord = [SELECT RecordId, HasReadAccess, HasDeleteAccess, HasEditAccess, HasTransferAccess, MaxAccessLevel
                      FROM UserRecordAccess WHERE UserId = : userInfo.getUserId() AND RecordId = : recordId ];
    }
    return getUsrRecord;
  }
  
  //Added by Avinash for JIRA Ticket : GGCW-3355
 // @AuraEnabled
  /**
   * @description method return object of picklist values that should be visible after opp is closed won for sales user
   * @return wrapper list
   */
  /*public static list<exhibPaidByValue> getAllExhibPaidByValues() {
    List<exhibPaidByValue> exhibPaidByValueLst = new List<exhibPaidByValue>();
    exhibPaidByValue obje = new exhibPaidByValue();
    obje.label = '--None--';
    obje.value = '';
    exhibPaidByValueLst.add(obje);
    for(exhibitor_paid_by_for_sales_after_cw__c instobje : exhibitor_paid_by_for_sales_after_cw__c.getAll().values()){
      exhibPaidByValue objeNew = new exhibPaidByValue();
      objeNew.label = instobje.Name;
      objeNew.value = instobje.Name;
      exhibPaidByValueLst.add(objeNew);
    }
    system.debug(exhibPaidByValueLst);
    return exhibPaidByValueLst;
  }*/


}