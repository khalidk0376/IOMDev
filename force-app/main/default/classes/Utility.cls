/**
* File:        Utility.cls
* Project:     GreenField
* Date:        11th December 2019
* Created By:  Girikon(Prashant)
* Test Class:  Utility_Test(85%)
* *************************************************************************
* @description: This class contains common methods for all Expocad related
               Classes and triggers.
* *************************************************************************
*/

public with sharing class Utility{
  
  public static boolean isRebookInProcess = false;
  public static boolean isReviewProcess = false;
  public static boolean byPassClosedWon = false;
  public static Boolean quoteTriggerMargeisFirstTime = false;
  public static Boolean quoteTriggerMargeisFirstTimeBefore = false;
  public static Boolean isAttachAgreement = false;
  public static Boolean isAmendmentProcess = false;
  
  /*
  *Catching all expocad exception using passed exception parameter details.
  ***/
  Public static void logError(String sMessage, Exception sCause, Integer sLineNumber , string sStackTraceString ,string sMethodName){
    // ExpoCad_Error__c oExpocadError = new ExpoCad_Error__c();
    // oExpocadError.Errors__c = 'Message: '+ sMessage +   'Cause: ' +  sCause + '  Line number: ' + sLineNumber + ' Stack trace: ' +  sStackTraceString ;
    // oExpocadError.Description__c = 'Error Message : ' + sMessage + 'Function/Method Name : ' +  sMethodName;
    // if(Schema.sObjectType.ExpoCad_Error__c.isCreateable())
    // {
    //   insert oExpocadError ;
    // }
  }
  
  // Method to encode using base64
  public static String encode(String str) {
    if(str != null && str != ''){
      return EncodingUtil.base64Encode(blob.valueof(str+'-INF17-AXUS-KG17'));
    }
    return str;
  }
  
  // Method to decode using base64
  public static String decode(String str) {
    if(str != null && str != ''){
      return EncodingUtil.base64Decode(str).toString().substringBefore('-INF17-AXUS-KG17');
    }
    return str;
  }
  
  // String to Currency format
  public static String currencyFormat(String str) {
    if(str != null && str != ''){
      Decimal dNumberToFormat = Decimal.valueof(str);
      List<String> args = new String[]{'0','number','###,###,##0.00'};
      String sFormattedValue = String.format(dNumberToFormat.format(), args);
      return sFormattedValue;
    }
    return str;
  }
  
  // Return true if Lightning page is accessed from Lightning Env.
  public static Boolean isLightning (String sURL){
    Boolean isLightning = False;
    if (!String.isBlank(sURL) && sURL.tolowercase().contains('lightning')) {
      isLightning = True;
    }
    return isLightning;
  }
  
  // Return true if Record is updating using Asynchronous ways.
  public static Boolean isAsync() { 
     return System.isBatch() || System.isQueueable() || System.isScheduled() || System.isFuture();
  }

  //Get all conga queries into map.
  public static Map<String, Id> mapCongaQuery(){
    Map<String, Id> mapCongaQry = new Map<String, Id>();
    List<APXTConga4__Conga_Merge_Query__c> lstCongaQry = new List<APXTConga4__Conga_Merge_Query__c>();
    if(Schema.sObjectType.APXTConga4__Conga_Merge_Query__c.isAccessible()){
      lstCongaQry = [SELECT Id, APXTConga4__Name__c FROM APXTConga4__Conga_Merge_Query__c Limit 49000];
    }
    if(lstCongaQry.size() > 0){
      for(APXTConga4__Conga_Merge_Query__c congqry : lstCongaQry){
        mapCongaQry.put(congqry.APXTConga4__Name__c,congqry.Id);
      }
    }
    return mapCongaQry;
  }
}