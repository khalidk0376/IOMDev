@isTest
private class LookupCtrl_Test {
	
	static testMethod void createQniareRecordTestMethod(){
		// Implement test code
		// creating Account record
		Account acc = new Account(Name='Test Account');
		insert acc;
		List<Account> lstAcc = [Select id from Account where id=:acc.id];
		System.assertNotEquals(lstAcc, null);
		System.assertEquals(lstAcc.size(),1);
		Test.startTest();
			String result = LookupCtrl.searchDB('Account','Name', 'Id',acc.Name ) ;
			System.assertNotEquals(result, null);
			System.assert(result.length()>0,'exit account name');
		Test.stopTest();
	}
	
	
	
}