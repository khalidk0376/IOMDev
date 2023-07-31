@isTest
private class trig_CaptureEvent_test {
    @isTest static void TestCaseInsertion() {
        
        Edition__c objEdt1 = new Edition__c(Name = 'Test Event Edition 1', Edition_Code__c = 'TE2021', Edition_Status__c = 'Confirmed');
        insert objEdt1;
        
        Edition__c objEdt2 = new Edition__c(Name = 'Test Event Edition 2', Edition_Code__c = 'TE-2021', Edition_Status__c = 'Confirmed');
        insert objEdt2;
        
        Case objCase1 = new Case(Status ='New', Priority = 'Medium', Origin = 'Web',Edition_Code__c = objEdt1.id,Case_Description__c = 'Test Description');
        
        test.startTest();
        Database.SaveResult str1 = database.insert(objCase1 , False);
        System.assertEquals(True, str1.isSuccess());
        objCase1.Edition_Code__c = objEdt2.Id; 
        Database.SaveResult str2 = database.update(objCase1 , False);
        System.assertEquals(True, str2.isSuccess());
        test.stopTest();
    }
}