@isTest
private class Trig_EmailToCase_Handler_Test {
     @isTest static void TestDataInsertion() {
         
         Case objCase1 = new Case(Status ='New', Priority = 'Medium', Origin = 'Web', Subject = 'Test Subject');
         insert objCase1;
         
         EmailMessage emailMsg = new EmailMessage(ToAddress = 'email2case@gmail.com',CcAddress = 'abc1@test.com', FromAddress = 'test@abc.org',Incoming = True,Subject = 'Test email', ParentId = objCase1.Id);
         test.startTest();
         insert emailMsg;
         test.stopTest();
 }
}