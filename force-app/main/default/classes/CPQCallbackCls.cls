/**
* Created By   :   Girikon(Ashish) : JIRA ref: [IML2R-299]
* Created On   :   27 Nov 2019
* *********************************************************************************
* @description  : Call Back Class to save QLI items After Calculations
* Test Class    : AddCPQQuoteLines_Test(100%)
* *********************************************************************************
* Modification log -- 
* 
*/ 
/**
* P2 Volation : Cannot remove Global from this class as it is Uses CPQ API 
*/
Global with sharing class CPQCallbackCls implements SBQQ.CalculateCallback 
{
    /*
    * @description  :   CPQ Call Back Methord 
    */
    Global void callback(String quoteJSON)
    {
        String quoteJSONres =  SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', quoteJSON);
    }
}