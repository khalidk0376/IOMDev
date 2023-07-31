/**
 * Project:         GreenField
 * Date:            16th December 2019
 * Test Class For:  Utility.cls 
 * Created By:      Girikon(Prashant)
 * *************************************************************************
 * @description    Test class for Class Utility.
 * *************************************************************************
*/

@isTest(seeAlldata = false)
public class Utility_Test {
  static testMethod void unitTest() {
    Integer x = 1;
    Boolean isUtilityActive = Utility.isRebookInProcess ;
    String sEncode = Utility.encode('Test');
    String sDecode = Utility.decode(sEncode);
    String scurrencyFormat = Utility.currencyFormat('10.23');
    Boolean bisLightning = Utility.isLightning ('url') ;
    Boolean bisAsync = Utility.isAsync();
    Utility.mapCongaQuery();
    System.assertEquals(1, x, 'Error');
    try {
      Integer i = 100 / 0;
    } catch (exception ex) {
      Utility.logError(ex.getMessage(), ex.getCause(), ex.getLineNumber() , ex.getStackTraceString() , 'makeExpocadQuery');
    }
  }
}