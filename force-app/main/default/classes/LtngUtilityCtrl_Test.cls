/**
* Created By       :   Girikon(Sachin)
* Created On       :   
* @description     :   Test class to provide code coverage.          
* Apex Class       :   LtngUtilityCtrl

* Modification log --
* Modified by      :  
**/

@isTest
public class LtngUtilityCtrl_Test {
    
    @isTest
    public static void callTest() {
        Test.startTest();
        Account acc=new Account();
        acc.Name='test account';
        acc.BillingCity ='Delhi' ;
        acc.BillingCountry='india';
        acc.BillingPostalCode='600075';
        acc.BillingState='Delhi';
        acc.BillingStreet='water well street'; 
        insert acc;
        System.assertNotEquals(null, acc.Id,'test');
        
        // Creates test Edition object
        Edition__c ee = new Edition__c(Name='TestName',Event_Code__c='XYZ');
        insert ee;
        
        opportunity opp= new opportunity();
        opp.AccountId=acc.id;
        opp.Name='test';
        opp.StageName='Prospecting';
        opp.CloseDate=system.today();
        opp.Default_Edition__c = ee.Id;
        insert opp;
        
        
        
        Contact con = new Contact();
        con.LastName='test';
        con.Email = 'test@informa.com';
        con.Phone = '1212121212';
        insert con;
        
        Attachment attach = new Attachment();
        attach.Name = 'ABC';
        attach.ParentId = con.Id;
        attach.Body = EncodingUtil.base64Decode('xyz');
        insert attach;
        
        string recordId = con.Id;
        list<contact> conList =  LtngUtilityCtrl.getRecord(recordId,'Contact','LastName');
        LtngUtilityCtrl.getCurrentUserDtls();
        //LtngUtilityCtrl.getCommunityURL();
        
        LtngUtilityCtrl.RecordDataTableWrapper getObjRecords = LtngUtilityCtrl.getRecords('Contact','LastName','Id' , recordId, 3, 2);
        
        LtngUtilityCtrl.RecordDataTableWrapper getsObjRecords = LtngUtilityCtrl.getSobjectRecords('Contact','LastName','LastName','test','Where Id != null','LastName','DESC',3,2);
        
        //LtngUtilityCtrl.agentEventDetails(ee.Event_Code__c);
        
       
        Id saveFile = LtngUtilityCtrl.saveFile(recordId, 'Abc', 'xyz');
        Test.stopTest();
    }

}