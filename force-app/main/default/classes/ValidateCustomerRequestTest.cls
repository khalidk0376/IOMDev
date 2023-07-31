/**
* Date:        13 jan 2020
* Created By : Girikon(Ashish)
* Apex Class : ValidateCustomerRequest
* *************************************************************************
* @description: This test class test the ValidateCustomerRequest
* *************************************************************************
* History: 
*/
@IsTest
public class ValidateCustomerRequestTest {

    static testMethod void testParse() {
        String json = '{'+
                '\"Header\": { \"Systems\": {'+
                '\"CallingApplication\": \"SFDC-GE\", \"MessageDate\": \"2017-05-04\", \"MessageStatus\": \"10\", \"MessageStatusText\": \"Tax Calculation\"'+
                '} },'+
                '\"Content\": { \"AddressWrapper\": {'+
                '\"Customer\": {'+
                '\"CustomerNumber\": \"BP010101010101\", \"CustomerNumberType\": \"BP\", \"CustomerGroup\": \"Group\", \"CustomerEmail\": \"mulesoft@informa.com\"'+
                '}, \"Person\": {'+
                '\"Prefix\": \"Mr.\",'+
                '\"FirstNames\": \"Peter Charley\", \"LastName\": \"Mc Afee\"'+
                '}, \"Address\": {'+
                '\"Organisation\": \"Informa\", \"Department\": \"Global Support\", \"AddressLine1\": \"Schimmelt 32\", \"AddressLine2\": \"\",'+
                '\"City\": \"Eindhoven\",'+
                '\"State\": \"\",'+
                '\"PostalCode\": \"5611 ZX\", \"Country\": \"NL\",'+
                '\"PhoneNumber\": \"3161234567890\", \"PhoneExtension\": \"x1234\", \"FaxNumber\": \"3161234567899\"'+
                '} }'+
                '} }';
        ValidateCustomerRequest obj = ValidateCustomerRequest.parse(json);
        Account oAccount = TestDataFactoryUtils.createAccount();
        System.assertEquals('Test Account' , oAccount.Name, 'Error ::: Account not created');
     }

    static testMethod void testValidateCustomerRequest() 
    {        
        // Create an account
        // Account acc = new Account(name='TESTACC',Payment_Term__c='Net 10');
        Account acc = new Account ();
        acc.Name = 'TESTACC';
        acc.currencyisocode='USD';
        acc.BillingStreet ='street2';
        acc.BillingCity='test';
        acc.BillingCity='Alaska';
        acc.BillingState='tamil nadu';
        acc.BillingCountryCode='IN';
        acc.BillingPostalCode='12342';
        acc.Accounting_Credit_Hold__c = 'Hold';
        acc.Payment_Term__c='Net 10';
        insert acc;
        System.assertEquals('TESTACC', acc.Name,'true');
        Contact con = new Contact(Firstname= 'test',Lastname = '123',email = 'abc@df.com',AccountId = acc.Id);
        Insert con;

        ValidateCustomerRequest ccr = new ValidateCustomerRequest(acc,con);
    }
}