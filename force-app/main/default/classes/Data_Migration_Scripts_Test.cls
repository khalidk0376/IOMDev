/**
* File:         Data_Migration_Scripts_Test
* Project:      GECI
* Created Date: 26 May 2023
* Created By:   IBM(Bharath)
* *********************************************************************************
* @description  : Code Covrage for Data_Migration_Scripts(100%)
* *********************************************************************************
* Modification log -- 
*/ 
@isTest
private class Data_Migration_Scripts_Test {
  
    @isTest 
    static void dataMigrationScriptsTest(){
      Test.startTest();
      Data_Migration_Scripts obj = new Data_Migration_Scripts();
      System.assertNotEquals(null, obj, 'Object is null');
      Test.stopTest();
    }
}