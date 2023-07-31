/**
* File			: 	IOM_MulesoftSalesforce_Mock
* Project       :   Order & Billing Plateform
* Created By	: 	Suresh(Girikon)
* Created Date	: 	9th Dec 2021
* ***************************************************************************
* @description : HttpCalloutMock Class for IOM_MulesoftSalesforceCalloutBatch
*****************************************************************************
* Last Modified By :
*/
@isTest
public class IOM_MulesoftSalesforce_Mock implements HttpCalloutMock{
    
     public Map<String,String> mapURIBody;
    public Integer responseCode;
	public String responseBody;
    
    /**
    * @description  This Constructor Default
    */
    Public IOM_MulesoftSalesforce_Mock()
    {
        this.responseCode = 200;        
    }
    /**
    * @description  This Constructor is genrate Dynamic Response
    * @param  code
    * @param  body
    */
    Public IOM_MulesoftSalesforce_Mock(Integer code, String body)
    {
        this.responseCode = code;
        this.responseBody = body;        
    }
    /**
    * @description  This Constructor for Dynamic Multiple  Response
    * @param  mapstr
    */
    Public IOM_MulesoftSalesforce_Mock(Map<String,String> mapstr)
    {
        this.mapURIBody = mapstr;
    }

    /**
    * @description  This method is used to genrate fake response for Api Callouts
    * @param  req     
    * @return  HTTPResponse
    */
    public HTTPResponse respond(HTTPRequest req) 
    {
        HTTPResponse res = new HTTPResponse();
        res.setHeader('Content-Type', 'application/json');     
        if(mapURIBody != null){
            for(String key : mapURIBody.keySet()){
                if(req.getEndpoint().contains(key)){
                    String str = mapURIBody.get(key);
                    System.debug(LoggingLevel.DEBUG, 'str==='+str);
                    res.setStatusCode(Integer.valueOf(str.split('###')[0]));
                    res.setBody(str.split('###')[1]);
                    res.setStatus('Success');
                }
            }
        }else{
            res.setStatusCode(responseCode);
            res.setStatus(responseCode==200?'Success':'Error'); 
            if(string.isNotBlank(responseBody))
            {
                res.setBody(responseBody);
            }
        }
        return res;
    }

}