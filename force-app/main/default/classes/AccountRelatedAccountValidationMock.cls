/**
 * Created By : Girikon(Ashish)
 * Date :        13 jan 2020
 * Apex Class : AccountRelatedAccountValidation
 * *************************************************************************
 * @description : This test class used in AccountRelatedAccountValidation_Test for Mock 
 * ************************************************************************* 
 * History: 
 */

@IsTest
public class AccountRelatedAccountValidationMock implements HttpCalloutMock {
  
    public HttpResponse respond( HttpRequest req ) {
        HttpResponse res = new HttpResponse( );
        res.setHeader('Content-Type', 'application/json');
        res.setBody( '{"Header":{"Systems":{"SystemReference":"0011F000009bKCwQAM","MessageStatusText":"","MessageStatus":"","MessageDate":"2018-07-17","CallingApplication":"SFDC-GE"},"DataPacket":[]},"Content":{"AddressWrapper":{"Person":{"LastName":"testLN","FirstNames":"TestFN"},"Customer":{"CustomerNumberType":"web","CustomerNumber":"","CustomerGroup":"","CustomerEmail":"test.test@gmail.com"},"Address":{"State":"Delhi","PostalCode":"110025","PhoneNumber":"1234567890","PhoneExtension":"","Organisation":"","FaxNumber":"1234567890","Department":"","Country":"IN","City":"Las Vegas","AddressLine2":"","AddressLine1":"456 Zepplin Avenue"}}}}' );
        res.setStatusCode( 200 );
        return res;
    }
    
}