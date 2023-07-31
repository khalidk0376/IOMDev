/*Created By: {Girikon(Pramod)}
Created On: 09/14/2018
Description/Purpose: This class provides coverage to apex class "ccRewriter"
Methods: ccRewriterTest
Apex Class: ccRewriter(90%)

Modification log --
Modified By: Ashish on Feb 27 2019[CCEN-695]
*/

@isTest
Public class ccRewriter_Test
{
    @isTest
    public static void ccRewriterTest() 
    { 
        ccRewriter ccr=new ccRewriter();
        
        PageReference pr=new PageReference('/_ui/testpage');
        ccr.mapRequestUrl(pr);
        PageReference[] prArr=new List<PageReference>();
        prArr.Add(pr);
        System.assertNotEquals(null, pr.getURL(), 'URL must not be null');
        ccr.generateUrlFor(prArr);
    }
    
    //[CCEN-695]
    @isTest
    public static void ccRewriterAttViewTest() 
    { 
        ccRewriter ccr=new ccRewriter();        
        PageReference pr=new PageReference('/file/view/CHpnFCFS7rVwfkI2PcLqno06ut_qL5OSUqkEIHrZ4onDhCP8Ezuqee_Jx41J_UHO');
        ccr.mapRequestUrl(pr);
        PageReference[] prArr=new List<PageReference>();
        prArr.Add(pr);
        System.assertNotEquals(null, pr.getURL(), 'URL must not be null');
        ccr.generateUrlFor(prArr);
    }
}