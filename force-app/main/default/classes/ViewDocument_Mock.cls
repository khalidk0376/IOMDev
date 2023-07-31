/**
* File			: 	ViewDocument_Mock
* Project      	:   GECI
* Created By	: 	IBM(Bharath)
* Created Date	: 	4-july-2023
* ******************************************************************************************************
* @description : Mock class for ViewDocumentController_Test
*/
@isTest
public class  ViewDocument_Mock implements HttpCalloutMock {
    /**
    * @description  This method is used to genrate fake response for Api Callouts
    * @param  request     
    * @return  HTTPResponse
    */
    public HTTPResponse respond(HTTPRequest request) {
        string resbody = '{"errors":[{"id":"b0a0b361-a286-46ee-b18c-0471ff62697f","timestamp":"2023-07-03T17:09:32.326Z","status":400,"title":"Bad Request","detail":"Document number cannot be null or empty.","path":"/document/ERP-0056987/download?legalEntity=IN23"}]}';
        
        HTTPResponse response = new HTTPResponse();
        response.setBody(resbody);
        response.setStatus('Success');
        response.setHeader('Content-Type', 'application/json');
        response.setStatusCode(200);
        return response;
    }
}