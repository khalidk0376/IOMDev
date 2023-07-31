/**
* Date:        13 jan 2020
* Created By : Girikon(Ashish)
* Apex Class : ValidateCustomerResponse
* *************************************************************************
* @description: This test class test the ValidateCustomerResponse
* *************************************************************************
* History: 
*/
@IsTest
public class ValidateCustomerResponseTest {

    static testMethod void testParse() {
        String json = '{'+
                '  \"Header\": {'+
                '    \"Systems\": {'+
                '      \"CallingApplication\": \"SFDC-GE\",'+
                '      \"MessageDate\": \"2017-05-04\",'+
                '      \"MessageStatus\": \"0\",'+
                '      \"MessageStatusText\": \"\"'+
                '    }'+
                '  },'+
                '  \"Content\": {'+
                '    \"AddressWrapper\": {'+
                '      \"Customer\": {'+
                '        \"CustomerNumber\": \"BP010101010101\",'+
                '        \"CustomerNumberType\": \"BP\",'+
                '        \"CustomerGroup\": \"Group\",'+
                '        \"CustomerEmail\": \"mulesoft@informa.com\"'+
                '      },'+
                '      \"Person\": {'+
                '        \"Prefix\": \"Mr.\",'+
                '        \"FirstNames\": \"Peter Charley\",'+
                '        \"LastName\": \"Mc Afee\"'+
                '      },'+
                '      \"Address\": {'+
                '        \"Organisation\": \"Informa\",'+
                '        \"Department\": \"Global Support\",'+
                '        \"AddressLine1\": \"Schimmelt 32\",'+
                '        \"AddressLine2\": \"\",'+
                '        \"City\": \"Eindhoven\",'+
                '        \"State\": \"\",'+
                '        \"PostalCode\": \"5611 ZX\",'+
                '        \"Country\": \"NL\",'+
                '        \"PhoneNumber\": \"3161234567890\",'+
                '        \"PhoneExtension\": \"x1234\",'+
                '        \"FaxNumber\": \"3161234567899\"'+
                '      }'+
                '    }'+
                '  }'+
                '}';
        ValidateCustomerResponse obj = ValidateCustomerResponse.parse(json);
        Account oAccount = TestDataFactoryUtils.createAccount();
        System.assertEquals('Test Account' , oAccount.Name, 'Error ::: Account not created');
    }
}