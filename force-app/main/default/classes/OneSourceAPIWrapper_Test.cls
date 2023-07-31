/**
* File			: 	OneSourceAPIWrapper_Test
* Project      	:   Order & Billing Plateform
* Created By	: 	Deepak(Girikon)
* Created Date	: 	21 Sept 2021
* ******************************************************************************************************
* @description : Test Class to provide code covrage to classes - OneSourceAPIWrapper(73%)
* Last Modified By :
*/
@isTest
private class OneSourceAPIWrapper_Test {
	@isTest 
    static void testOneSourceAPIWrapper()
    {
        Test.startTest();
        OneSourceAPIWrapper.Cls_Request req = new OneSourceAPIWrapper.Cls_Request();
        req.get('orderOrigin');
        req.get('orderAcceptance');
        req.get('isExempt');
        req.get('userAttributes');
        req.get('lines');
        req.put('companyId','test data');
        req.put('documentNumber','test data');
        req.put('documentDate','test data');
        req.put('fiscalDate','test data');
        req.put('calculationDirection','test data');
        req.put('companyRole','test data');
        req.put('currencyReq','test data');
        req.put('documentType','test data');
        req.put('isAudited','false');
        req.put('isCredit','false');
        req.put('pointOfTitleTransfer','test data');
        req.put('transactionType','test data');
        req.put('accountName','test data');
        req.put('accountTaxNumber','test data');
        req.put('vendorName','test data');
        req.put('vendorNumber','test data');
        req.put('vendorTax','test data');
        req.orderOrigin.put('street','test data');
        req.orderOrigin.put('city','test data');
        req.orderOrigin.put('state','test data');
        req.orderOrigin.put('country','test data');
        req.orderOrigin.put('province','test data');
        req.orderOrigin.put('postalCode','test data');
        req.orderOrigin.put('geoCode','test data');
        req.orderOrigin.get('geoCode');
        req.isExempt.get('orderOrigin2');
        req.isExempt.put('all','test data');
        req.isExempt.put('country','test data');
        req.isExempt.put('province','test data');
        req.isExempt.put('state','test data');
        req.isExempt.put('county','test data');
        req.isExempt.put('city','test data');
        req.isExempt.put('district','test data');
        req.isExempt.put('postalCode','test data');
        req.isExempt.put('geoCode','test data');
        req.userAttributes.get('geoCode');
        req.userAttributes.put('name','test data');
        req.userAttributes.put('value','test data');
        OneSourceAPIWrapper.Cls_lines_req linereq = new OneSourceAPIWrapper.Cls_lines_req();
        linereq.get('userAttributes');
        linereq.get('shipFrom');
        linereq.get('shipTo');
        linereq.get('billTo');
        linereq.put('itemNumber','1');
        linereq.put('grossAmount','1.0');
        linereq.put('commodityCode','1');
        linereq.put('productCode','1');
        linereq.put('partNumber','1');
        linereq.put('relatedLineItemNumber','1');
        linereq.put('description','1');
        
        OneSourceAPIWrapper.Reponse resp = new OneSourceAPIWrapper.Reponse();
        resp.get('data');
        resp.get('meta');
        resp.data.get('lines');
        resp.data.get('vendorTax');
        OneSourceAPIWrapper.Cls_lines respLine = new OneSourceAPIWrapper.Cls_lines();
        respLine.get('taxSummary');
        respLine.get('taxes');
        respLine.get('transactionType');
        respLine.taxSummary.get('taxableBasis');
        OneSourceAPIWrapper.Cls_taxes respTaxes = new OneSourceAPIWrapper.Cls_taxes();
        respTaxes.get('currencyConversion');
        respTaxes.get('exemptAmount');
        respTaxes.get('grossAmount');
        respTaxes.get('nonTaxableBasis');
        respTaxes.get('taxableBasis');
        respTaxes.get('taxAmount');
        respTaxes.get('taxRate');
        respTaxes.taxAmount.get('exchangeRateSource');
        respTaxes.taxableBasis.get('exchangeRateSource');
        OneSourceAPIWrapper.Cls_currencyConversion respCurr = new OneSourceAPIWrapper.Cls_currencyConversion();
        respCurr.get('exchangeRateSource');
        resp.meta.get('partnerMessages');
        resp.meta.get('code');
        OneSourceAPIWrapper.Cls_partnerMessages respPMsg = new OneSourceAPIWrapper.Cls_partnerMessages();
        respPMsg.get('location');
        System.assertEquals('test data', req.vendorTax, 'Data not set');
        Test.stopTest();
    }
}