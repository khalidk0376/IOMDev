/**
* File         :   AddCPQQuoteLines 
* Project      :   Order & Billing Plateform
* Created Date :   01 Feb 2022
* Created By   :   Girikon(Deepak)
* Test Class   :   AddCPQQuoteLines_Test(95%)
*******************************************************************************************************
* @description : For Adding Quote Lines On Quote
*******************************************************************************************************
* Modification log :
* 1. Girikon (Ashish) [02 Nov 2021 (GECI-28) ] - Added new node "alternateLanguageDescription" for QLI data 
* 2. Girikon (Ansh) [23rd Dec 2022 ] - Added new node "translatedAltProductName" for QLI data
* 3. Girikon (Ashish) [09 Feb 2022 (GECI-761)] - Create Separate orders if Available_for_Order_Split__c is true on Product 2
* 4. Girikon (Ashish) [09 Feb 2022 (GECI-781)] - Add Quantity to Booth Size

*/
@RestResource(urlMapping='/insertquotelineitems/*')
global with sharing class AddCPQQuoteLines {
    /**
    * @description  This method is used to update Invoice fields
    * @return String 
    */
    @HttpPost
    global static ResponseData addQLI() 
    {
        ResponseData resWrap = new ResponseData();
        resWrap.status = 'Unknown';
        resWrap.message = 'Invalid Request Data';
        RestRequest req = RestContext.request;
        String requestJSONString = req.requestBody.toString();
        try {
            QuoteModelWrapper quoteWrapper = (QuoteModelWrapper)JSON.deserialize(requestJSONString,QuoteModelWrapper.class);
            
            resWrap = addQuoteLinesToQuoteCPQ(quoteWrapper.quoteId,quoteWrapper.lines, quoteWrapper.currencyISOcode);
        }catch (Exception e) 
        {
            resWrap.status = 'Error';resWrap.message = e.getMessage();
            system.debug(logginglevel.DEBUG,'Error_Message__c --> '+ resWrap.message +' At Line' + e.getLineNumber()); system.debug(logginglevel.DEBUG,' Trace --> '+ e.getStackTraceString());
        }
        return resWrap;
    }


    /**
   * @description [This method is for Adding Quote Lines On Quote.]
   * @param quoteId SF Quote Id
   * @param quoteLines QuoteLines
   * @param currencyISOcode Quote Currency
   * @return ResponseData 
   */
    private static ResponseData addQuoteLinesToQuoteCPQ(String quoteId, List<QuoteLineModelWrapper> quoteLines, String currencyISOcode) {
        // System.debug(LoggingLevel.DEBUG, 'quoteId==='+quoteId);
        // System.debug(LoggingLevel.DEBUG, 'quoteLines==='+quoteLines);
        
        //Added by Ansh(Girikon) GECI-773
        List<SBQQ__Quote__c> qtList = [SELECT Id,Name,SBQQ__Opportunity2__r.Default_Edition__r.Start_Date__c FROM SBQQ__Quote__c WHERE ID =: quoteId WITH SECURITY_ENFORCED];
        Date edStartdate = qtList[0].SBQQ__Opportunity2__r.Default_Edition__r.Start_Date__c != null ? qtList[0].SBQQ__Opportunity2__r.Default_Edition__r.Start_Date__c : Date.today();
        
        ResponseData resWrap = new ResponseData();        
        CPQAPIUtils oCPQreader  = new CPQAPIUtils(); // CPQ Util Class 
        Boolean isByPass = true;
        if(isByPass ||  Schema.sObjectType.SBQQ__Quote__c.isUpdateable()){
            update new SBQQ__Quote__c(Id=quoteId,SBQQ__Primary__c=true);
        }

        //load Quote from Api
        CPQAPIUtils.QuoteModel  quoteModelObj  =   oCPQreader.readQuote(quoteId);

        List<Pricebook2> pbs = [SELECT Id FROM Pricebook2 WHERE IsStandard=true WITH SECURITY_ENFORCED];
        Id pbId = (Test.isRunningTest()?Test.getStandardPricebookId():pbs.get(0).Id);
        quoteModelObj.record.SBQQ__PriceBook__c = pbId;
		
        Boolean iscontainsLineNum = false;
        Set<String> setIMProductCode = new Set<String>();
        List<QuoteLineModelWrapper> qtlinewrapList = new List<QuoteLineModelWrapper>();
        List<String> productcrmOLINumber = new List<String>();
        for(QuoteLineModelWrapper qliWrap : quoteLines){
            if(String.isNotBlank(qliWrap.imProductCode)){
                if(qliWrap.itemNumber != null && qliWrap.itemNumber != 0){
                    iscontainsLineNum = true;
                }
                setIMProductCode.add(qliWrap.imProductCode);
                qtlinewrapList.add(qliwrap);
            }
            else{
                productcrmOLINumber.add(qliWrap.crmOLINumber);
                resWrap.status = 'Error';
                System.debug(LoggingLevel.DEBUG, qliWrap.crmOLINumber + ' : Product Configuration Missing in Order Hub/IOM.');
        }
        }
        if(resWrap.status == 'Error' && !productcrmOLINumber.isEmpty()){
            resWrap.message = String.join(productcrmOLINumber, ',') + ' : Product Configuration Missing in Order Hub/IOM.';
        }

        if(iscontainsLineNum == false){
            quoteLines.sort();
        }
        List<PricebookEntry> listPBE = [SELECT Id,Product2Id,Product2.IM_ProductCode__c,Product2.QuantityUnitOfMeasure,Product2.Available_for_Order_Split__c FROM PricebookEntry WHERE Pricebook2Id=:pbId AND Product2.IM_ProductCode__c IN:setIMProductCode AND CurrencyIsoCode=:currencyISOcode AND IsActive=true WITH SECURITY_ENFORCED];

        Map<String,CPQAPIUtils.ProductModel> mapProductModel = new Map<String,CPQAPIUtils.ProductModel>();
        Map<String,Product2> mapProdIdProduct = new Map<String,Product2>();
        Boolean splitOrder = false;
        for(PricebookEntry pbe : listPBE){
            CPQAPIUtils.ProductModel productModelobj = oCPQreader.readProduct(pbe.Product2Id,pbId,currencyISOcode);
            
            mapProductModel.put(pbe.Product2.IM_ProductCode__c,productModelobj);
            // if(pbe.Product2.QuantityUnitOfMeasure=='M2'){
                mapProdIdProduct.put(pbe.Product2Id,pbe.Product2);
            // }
            if(pbe.Product2.Available_for_Order_Split__c){//[GECI-761] & [GECI-247]
                splitOrder=true;
            }
        }

        productcrmOLINumber = new List<String>();
        List<CPQAPIUtils.ProductModel> listProductModel = new List<CPQAPIUtils.ProductModel>();
        for(QuoteLineModelWrapper qliWrap : qtlinewrapList){
            if(mapProductModel.containsKey(qliWrap.imProductCode)){
                listProductModel.add(mapProductModel.get(qliWrap.imProductCode));
            }
            else{
                productcrmOLINumber.add(qliWrap.crmOLINumber);
                resWrap.status = 'Error';
                System.debug(LoggingLevel.DEBUG, qliWrap.crmOLINumber + ' : Product Configuration Missing or PriceBookentry Not Found in PriceBook in IOM.');
            }
        }
        if(resWrap.status == 'Error' && !productcrmOLINumber.isEmpty()){
            resWrap.message = (String.isBlank(resWrap.message)?'':(resWrap.message + '  ')) + (String.join(productcrmOLINumber, ',') + ' : Product(s) Configuration Missing or PriceBookentry Not Found in PriceBook in IOM.');
        }

        if(resWrap.status != 'Error'){
        CPQAPIUtils.QuoteModel finalQuoteModel = oCPQreader.addProductsToQuote(quoteModelObj,listProductModel,0);

        Integer index = 0;
            //Date quoteStartDate = null;
        Date quoteEndDate = null;
        List<Date> qldtList = new List<Date>();
        for(CPQAPIUtils.QuoteLineModel quoteLine : finalQuoteModel.lineItems)
        {
            QuoteLineModelWrapper qliWrap = qtlinewrapList.get(index);

            quoteLine.record.SBQQ__Quantity__c = (mapProdIdProduct.get(quoteLine.record.SBQQ__Product__c).QuantityUnitOfMeasure == 'M2')? 1 : qliWrap.quantity;
            quoteLine.record.Booth_Size__c      = (mapProdIdProduct.get(quoteLine.record.SBQQ__Product__c).QuantityUnitOfMeasure == 'M2' && qliWrap.quantity != null)?String.valueOf(qliWrap.quantity.setScale(4)):null; // GECI-781 & GECI-1063
            Date startDate = qliWrap.startDate;
            Date endDate = qliWrap.endDate;
            qldtList.add(startDate);
            //Decimal targetPrice = qliWrap.unitPrice;
            Decimal targetUnitPrice = qliWrap.unitPrice;
            quoteLine.record.Target_Price__c = targetUnitPrice*qliWrap.quantity;
            quoteEndDate = endDate;
            if(endDate > quoteEndDate){quoteEndDate = endDate;}
            if(startDate < edStartdate){
                edStartdate = startDate;
            }
            /*if(quoteLine.record.SBQQ__DefaultSubscriptionTerm__c != null){
                Integer monthsBetween = startDate.monthsBetween(endDate.addDays(1));
                Date tempEndDate = startDate.addMonths(monthsBetween);
                if(tempEndDate > endDate){
                    monthsBetween -= 1;
                    tempEndDate = startDate.addMonths(monthsBetween);
                }
                Integer daysBetween = tempEndDate.daysBetween(endDate.addDays(1));
                Decimal prorateMultiplier = ((monthsBetween + (daysBetween / (Decimal.valueof(365) / 12)))/(quoteLine.record.SBQQ__DefaultSubscriptionTerm__c)).setScale(2);
                Decimal listPrice = (targetUnitPrice/prorateMultiplier).setScale(2);
                Decimal totalPrice = (listPrice*prorateMultiplier*qliWrap.quantity).setScale(2);
                Decimal discount = targetPrice - totalPrice;

                quoteLine.record.SBQQ__OriginalPrice__c = listPrice;
                quoteLine.record.SBQQ__ListPrice__c = listPrice;
                quoteLine.record.SBQQ__AdditionalDiscountAmount__c = discount;
            }
            else{*/
                quoteLine.record.SBQQ__OriginalPrice__c = targetUnitPrice;
                quoteLine.record.SBQQ__ListPrice__c = targetUnitPrice;
                quoteLine.record.SBQQ__AdditionalDiscountAmount__c = 0;
            //}
            //GECI-27
            quoteLine.record.IsParent__c = String.isNotBlank(qliWrap.isParent)? Boolean.valueof(qliWrap.isParent):false;
            quoteLine.record.ParentSumNetValue__c = String.isNotBlank(qliWrap.parentSumNetValue) ? Decimal.valueOf(qliWrap.parentSumNetValue) :null;
            
            //GECI-379
			quoteLine.record.Tobe_Hidden_in_ERP__c = String.isNotBlank(qliWrap.isSuppressedtoDisplayinERP)? Boolean.valueof(qliWrap.isSuppressedtoDisplayinERP):false;
            quoteLine.record.Booth_Number__c = String.isNotBlank(qliWrap.boothNumber) ? qliWrap.boothNumber : null; //GECI-394
            quoteLine.record.Tobe_Hidden_in_ERP_when__c = qliWrap.isSuppressedtoDisplayinERPWhen; //GECI-1330
	
            quoteline.record.SBQQ__Number__c = qliWrap.itemNumber;
            quoteLine.record.CRM_OLI_Number__c = qliWrap.crmOLINumber;
            quoteLine.record.CRM_Parent_OLI_Number__c = qliWrap.crmParentOLINumber;
            quoteLine.record.SBQQ__StartDate__c = qliWrap.startDate;
            quoteLine.record.SBQQ__EndDate__c = qliWrap.endDate;
            quoteLine.record.Source_Product_Code__c = qliWrap.sourceProductCode;
            quoteLine.record.SBQQ__Description__c = qliWrap.description;
            quoteLine.record.Line_Description__c = (qliWrap.description!=null?qliWrap.description.left(255):qliWrap.description);
            quoteLine.record.Invoice_Line_Item_Description__c = (qliWrap.description!=null?qliWrap.description.left(150):qliWrap.description);
            quoteLine.record.Translated_Product_Description__c = String.isNotBlank(qliWrap.alternateLanguageDescription)?qliWrap.alternateLanguageDescription:null; //GECI-28
            quoteLine.record.Translated_Alt_ProductName__c = String.isNotBlank(qliWrap.translatedAltProductName)?qliWrap.translatedAltProductName:null; //GECI-19            
            index++;
        }
            
            //oCPQreader.saveQuoteModel(finalQuoteModel);
            //finalQuoteModel.record.SBQQ__Primary__c = true;
            if(splitOrder){
                finalQuoteModel.record.SBQQ__OrderBy__c='Name';
            }

            finalQuoteModel.record.SBQQ__Status__c = 'Approved';
            finalQuoteModel.record.SBQQ__StartDate__c = edStartdate < Date.today()?edStartdate:Date.today(); //Modified by Ansh(Girikon) GECI-773
            
            if(finalQuoteModel.record.SBQQ__ExpirationDate__c==null){finalQuoteModel.record.SBQQ__ExpirationDate__c = quoteEndDate;}
            oCPQreader.calculateQuotePrice(finalQuoteModel, 'CPQCallbackCls');
            resWrap.opportunityLineItems =  getCrmIomIdMap(quoteId);
            resWrap.status = 'Success'; resWrap.message = 'Quote Lines Inserted';
        }
        return resWrap;
    }

   /**
   * @description QuoteLineModelWrapper
   */
    public class QuoteModelWrapper {
        public String quoteId;
        public String currencyISOcode;
        public list<QuoteLineModelWrapper> lines;
    }


    /**
    * @description QuoteLineModelWrapper
    */
    public class QuoteLineModelWrapper implements Comparable{
        public String imProductCode;
        public Decimal quantity;
        
        public Integer itemNumber;
        public Decimal unitPrice;
        public Date startDate;
        public Date endDate;
        public String description;
        public String sourceProductCode;
        public String crmOLINumber;	//"OLI-00031"
        public String crmParentOLINumber; // CRM parent product OLI number [GECI-595]
        public String alternateLanguageDescription; // [GECI-28]
        public String translatedAltProductName; //[GECI-19]
        public String parentSumNetValue; //GECI-27
        public String isParent; //GECI-27
        public String isSuppressedtoDisplayinERP; //GECI-379
        public String isSuppressedtoDisplayinERPWhen; //GECI-1330
        public String boothNumber; //GECI-394

        /** @description Compare QuoteLineModelWrapper based on the Start Date.
         * @param compareTo
         * @return Integer Result
         * */
        public Integer compareTo(Object compareTo) {
            // Cast argument to OpportunityWrapper
            QuoteLineModelWrapper compareToWrapper = (QuoteLineModelWrapper)compareTo;

            // The return value of 0 indicates that both elements are equal.
            Integer returnValue = 0;
            if (startDate > compareToWrapper.startDate) {
                // Set return value to a positive value.
                returnValue = 1;
            } else if (startDate < compareToWrapper.startDate) {
                // Set return value to a negative value.
                returnValue = -1;
            }

            return returnValue;
        }
   }

   /**
    * @description  This Class is to return Reponse Data
    */
    global class ResponseData 
    {
        public String status;	        // Success / Error /Unknown
		public String message;	        // 006
        public List<OpportunityProduct> opportunityLineItems;
        /**
        * @description  constructor for Class to return Reponse Data
        */
        global ResponseData(){
            opportunityLineItems = new List<OpportunityProduct>();
        }
    }

    /**
    * @description  This Class is to return OpportunityProduct
    */
    global class OpportunityProduct
    {	
        public String crmOLINumber = '';	//"OLI-00031"
        public String iomQLINumber = '';	//"QL-00041"		
    }

    private static  List<OpportunityProduct> getCrmIomIdMap(Id quoteId)
    {        
        List<OpportunityProduct> qlis = new List<OpportunityProduct>();
        for(SBQQ__QuoteLine__c qli :[SELECT Id,Name,CRM_OLI_Number__c FROM SBQQ__QuoteLine__c Where SBQQ__Quote__c =:quoteId WITH SECURITY_ENFORCED] )
        {
            //System.debug(LoggingLevel.DEBUG, qli.Name +' - '+qli.CRM_OLI_Number__c);
            OpportunityProduct op = new OpportunityProduct();
            op.crmOLINumber = qli.CRM_OLI_Number__c;
            op.iomQLINumber = qli.Name;
            qlis.add(op);
        }
        return qlis;
    }
}

/************************** SAMPLE JSON ************************************ */
// {"quoteId": "a0x050000002vm7AAA","currencyISOcode":"USD","lines": [{"imProductCode": "IM-00357","quantity": 1,"unitPrice": 350.5,"startDate": "2022-01-30","endDate": "2022-06-30","description": "Line Desc","sourceProductCode": "P-0001","crmOLINumber":"TOLI-0023","crmParentOLINumber":"","alternateLanguageDescription":"","isParent":"false","parentSumNetValue":0,"isSuppressedtoDisplayinERP":"false","isSuppressedtoDisplayinERPWhen":"","boothNumber":"B6"},{"imProductCode": "IM-00357", "quantity": 1,"unitPrice": 75,"startDate": "2022-06-30","endDate": "2022-07-30","description": "Line Desc","sourceProductCode": "P-0001","crmOLINumber":"TOLI-0024","alternateLanguageDescription":"parentSumNetValue","isParent":"false","parentSumNetValue":0,"isSuppressedtoDisplayinERP":"false","isSuppressedtoDisplayinERPWhen":"","boothNumber":"B6"}]}