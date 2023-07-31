/**
* Created/Modified By    : Girikon(Arushi [IMCC-4862])
* Created On             : 23-Nov-2022
* @description           : HttpCalloutMock fake response for Imcc_APICallOutVisit_Test
* Test Class             : Imcc_APICallOutVisit_Test
* Apex Class             : IMCC_APICallOutVisit
**/
@isTest
public class IMCC_VisitAPIHttpCalloutMock implements HttpCalloutMock {
    public Map<String,String> mapURIBody;
    /**
    * @description  This Constructor for Dynamic Multiple  Response
    * @param  mapstr
    */
    Public IMCC_VisitAPIHttpCalloutMock(Map<String,String> mapstr)
    {
        this.mapURIBody = mapstr;
    }

    /**
    * @description this method will be return mock response for callout in test class
    * @param request
    * @return HTTPResponse
    */
    public HTTPResponse respond(HTTPRequest request) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        String str = mapURIBody.values()[0];
        res.setStatusCode(Integer.valueOf(str.split('###')[0]));
        res.setBody(str.split('###')[1]);
        return res; 
    }
}