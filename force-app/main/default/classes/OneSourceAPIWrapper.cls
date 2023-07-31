/**
* File         :   OneSourceAPIWrapper 
* Project      :   Order & Billing Plateform
* Created Date :   17th Sept 2021
* Created By   :   Girikon(Deepak)
* Test Class   :   OneSourceAPIWrapper_Test(73%),TaxServiceUtils_Test(56%)-(98%)
* ***************************************************************************************************
* @description : contain the Wrapper Nodes for ONE_SOURCE Callouts & Payload creation Methord(OBP-84)
* ***************************************************************************************************
* Modification log :   
*/
public with sharing class OneSourceAPIWrapper
{
    /** @description : OneSource Tax Request Interface Class*/
    public interface OneSourceTaxRequestInterface{
        /** @description : put method for class
        * @param key
        * @param value
        */
        void put(String key, String value);

        /** @description : get method for class
        * @param key
        * @return Object
        */
        Object get(String key);
    }

    /** @description : request class for tax calculation*/
    public class Cls_Request implements OneSourceTaxRequestInterface
    {
        // Put the Nodes Here
        public String companyId;
        public String documentNumber;
        public String documentDate;
        public String fiscalDate;
        public String calculationDirection;
        public String companyRole;
        public String currencyReq;
        public String documentType;
        public Boolean isAudited;
        public Boolean isCredit;
        public String pointOfTitleTransfer;
        public String transactionType;
        public String accountName;
        public String accountTaxNumber;
        public String vendorName;
        public String vendorNumber;
        public String vendorTax;
        public String sourceSystem;
        public Cls_Address orderOrigin;
        public Cls_Address orderAcceptance;
        public Cls_isExempt isExempt;
        public Cls_userAttributes userAttributes;
        public Cls_lines_req[] lines;

        /** @description : put method for class
        * @param key
        * @param value
        */
        public void put(String key, String value){
            switch on key{
                when 'companyId'{
                    this.companyId = value;
                }
                when 'documentNumber'{
                    this.documentNumber = value;
                }
                when 'documentDate'{
                    this.documentDate = value;
                }
                when 'fiscalDate'{
                    this.fiscalDate = value;
                }
                when 'calculationDirection'{
                    this.calculationDirection = value;
                }
                when 'companyRole'{
                    this.companyRole = value;
                }
                when 'currencyReq'{
                    this.currencyReq = value;
                }
                when 'documentType'{
                    this.documentType = value;
                }
                when 'isAudited'{
                    this.isAudited = (value=='false'?false:true);
                }
                when 'isCredit'{
                    this.isCredit = (value=='false'?false:true);
                }
                when 'pointOfTitleTransfer'{
                    this.pointOfTitleTransfer = value;
                }
                when 'transactionType'{
                    this.transactionType = value;
                }
                when 'accountName'{
                    this.accountName = value;
                }
                when 'accountTaxNumber'{
                    this.accountTaxNumber = value;
                }
                when 'vendorName'{
                    this.vendorName = value;
                }
                when 'vendorNumber'{
                    this.vendorNumber = value;
                }
                when 'vendorTax'{
                    this.vendorTax = value;
                }
                when 'sourceSystem'{
                    this.sourceSystem = value;
                }
            }
        }

        /** @description : get method for object type nodes
        * @param key
        * @return Object
        */
        public Object get(String key){
            Object obj;
            switch on key{
                when 'orderOrigin'{
                    this.orderOrigin = this.orderOrigin==null?new Cls_Address():this.orderOrigin;
                    obj = this.orderOrigin;
                }
                when 'orderAcceptance'{
                    this.orderAcceptance = this.orderAcceptance==null?new Cls_Address():this.orderAcceptance;
                    obj = this.orderAcceptance;
                }
                when 'isExempt'{
                    this.isExempt = this.isExempt==null?new Cls_isExempt():this.isExempt;
                    obj = this.isExempt;
                }
                when 'userAttributes'{
                    this.userAttributes = this.userAttributes==null?new Cls_userAttributes():this.userAttributes;
                    obj = this.userAttributes;
                }
                when 'lines'{
                    this.lines = this.lines==null?new List<Cls_lines_req>():this.lines;
                    obj = this.lines;
                }
            }
            return obj;
        }
    }

    /** @description : wrapper class for address*/
    public class Cls_Address implements OneSourceTaxRequestInterface{
        public String street;
        public String city;
        public String state;
        public String country;
        public String county;
       // public String province;
        public String postalCode;
        public String geoCode;

        /** @description : put method for class
        * @param key
        * @param value
        */
        public void put(String key, String value){
            switch on key{
                when 'street'{
                    this.street = value;
                }
                when 'city'{
                    this.city = value;
                }
                when 'state'{
                    this.state = value;
                }
                when 'country'{
                    this.country = value;
                }
               /* when 'province'{
                    this.province = value;
                }*/
                when 'postalCode'{
                    this.postalCode = value;
                }
                when 'geoCode'{
                    this.geoCode = value;
                }
            }
        }

        /** @description : get method for object type nodes
        * @param key
        * @return Object
        */
        public Object get(String key){
            Object obj;
            return obj;
        }
    }

    /** @description : wrapper class for tax exempt info*/
    public class Cls_isExempt implements OneSourceTaxRequestInterface{
        public Boolean all = false;
        /*public Boolean country = false;
        public Boolean province = false;
        public Boolean state = false;
        public Boolean county = false;
        public Boolean city = false;
        public Boolean district = false;
        public Boolean postalCode = false;
        public Boolean geoCode = false;
        public Cls_Address orderOrigin2 ;*/

        /** @description : put method for class
        * @param key
        * @param value
        */
        public void put(String key, String value){
            switch on key{
                when 'all'{
                    this.all = Boolean.valueOf(value);
                }/*
                when 'country'{
                    this.country = Boolean.valueOf(value);
                }
                when 'province'{
                    this.province = Boolean.valueOf(value);
                }
                when 'state'{
                    this.state = Boolean.valueOf(value);
                }
                when 'county'{
                    this.county = Boolean.valueOf(value);
                }
                when 'city'{
                    this.city = Boolean.valueOf(value);
                }
                when 'district'{
                    this.district = Boolean.valueOf(value);
                }
                when 'postalCode'{
                    this.postalCode = Boolean.valueOf(value);
                }
                when 'geoCode'{
                    this.geoCode = Boolean.valueOf(value);
                }*/
            }
        }

        /** @description : get method for object type nodes
        * @param key
        * @return Object
        */
        public Object get(String key){
            Object obj;
            /*switch on key{
                when 'orderOrigin2'{
                    this.orderOrigin2 = this.orderOrigin2==null?new Cls_Address():this.orderOrigin2;
                    obj = this.orderOrigin2;
                }
            }*/
            return obj;
        }
    }

    /** @description : wrapper class for user info*/
    public class Cls_userAttributes implements OneSourceTaxRequestInterface{
        public String name;
        public String value;

        /** @description : put method for class
        * @param key
        * @param value
        */
        public void put(String key, String value){
            switch on key{
                when 'name'{
                    this.name = value;
                }
                when 'value'{
                    this.value = value;
                }
            }
        }

        /** @description : get method for object type nodes
        * @param key
        * @return Object
        */
        public Object get(String key){
            Object obj;
            return obj;
        }
    }

    /** @description : wrapper class line items for tax calculation*/
    public class Cls_lines_req implements OneSourceTaxRequestInterface{
        public Integer itemNumber;
        public Decimal grossAmount;
        public String commodityCode;
        public String productCode;
        public String partNumber;
        public Integer relatedLineItemNumber;
        public String description;
        public Cls_userAttributes userAttributes;
        public Cls_Address shipFrom;
        public Cls_Address shipTo;
        public Cls_Address billTo;


        /** @description : put method for class
        * @param key
        * @param value
        */
        public void put(String key, String value){
            switch on key{
                when 'itemNumber'{
                    this.itemNumber = Integer.valueOf(value);
                }
                when 'grossAmount'{
                    this.grossAmount = Decimal.valueOf(value);
                }
             /*   when 'commodityCode'{
                    this.commodityCode = value;
                }*/
                when 'productCode'{
                    this.productCode = value;
                }
                when 'partNumber'{
                    this.partNumber = value;
                }
                when 'relatedLineItemNumber'{
                    this.relatedLineItemNumber = Integer.valueOf(value);
                }
                when 'description'{
                    this.description = value;
                }
               
            }
        }

        /** @description : get method for object type nodes
        * @param key
        * @return Object
        */
        public Object get(String key){
            Object obj;
            switch on key{
                when 'userAttributes'{
                    this.userAttributes = this.userAttributes==null?new Cls_userAttributes():this.userAttributes;
                    obj = this.userAttributes;
                }
                when 'shipFrom'{
                    this.shipFrom = this.shipFrom==null?new Cls_Address():this.shipFrom;
                    obj = this.shipFrom;
                }
                when 'shipTo'{
                    this.shipTo = this.shipTo==null?new Cls_Address():this.shipTo;
                    obj = this.shipTo;
                }
                when 'billTo'{
                    this.billTo = this.billTo==null?new Cls_Address():this.billTo;
                    obj = this.billTo;
                }
            }
            return obj;
        }
    }

    /** @description : OneSource Tax Request Interface Class*/
    public interface OneSourceTaxResponseInterface{
        /** @description : get method for class
        * @param key
        * @return Object
        */
        Object get(String key);
    }

    /** @description : wrapper class for tax calculation response*/
    public class Reponse implements OneSourceTaxResponseInterface
    {
        public Cls_data data;
        public Cls_meta meta;

        /** @description : get method for object type nodes
        * @param key
        * @return Object
        */
        public Object get(String key){
            Object obj;
            switch on key{
                when 'data'{
                    this.data = this.data==null?new Cls_data():this.data;
                    obj = this.data;
                }
                when 'meta'{
                    this.meta = this.meta==null?new Cls_meta():this.meta;
                    obj = this.meta;
                }
            }
            return obj;
        }
    }
    
    /** @description : wrapper class for tax calculation response data*/
    public class Cls_data implements OneSourceTaxResponseInterface{
        public String calculationDirection; //f
        public String companyId;        //1307
        public String companyName;      //iNFORMA bUSINESS mEDIA iNC
        public String companyRole;      //S
        public String strCurrency;          //USD  --> Replace strCurrency to Currency
        public String minAccountableUnit;   //0.01
        public String roundingPrecision;   //2
        public String roundingRule;     //1
        public String documentDate;     //2019-12-09
        public String documentNumber;   //qte30180
        public String totalTaxAmount;  //0
        public String vendorTax;       //0
        public Cls_lines[] lines;

        /** @description : get method for object type nodes
        * @param key
        * @return Object
        */
        public Object get(String key){
            Object obj;
            switch on key{
                when 'lines'{
                    this.lines = this.lines==null?new List<Cls_lines>():this.lines;
                    obj = this.lines;
                }
                when else{

                    obj = ((Map<String,Object>)JSON.deserializeUntyped(JSON.serialize(this))).get(key);
                }
            }
            return obj;
        }
    }

    /** @description : wrapper class for tax calculation response lines*/
    public class Cls_lines implements OneSourceTaxResponseInterface{
        public String itemNumber;          //16384
        public String relatedLineItemNumber;   //1
        public String productCode;          //gc66
        public String commodityCode;        //
        public String description;          //r.e.p. pROVIDER eNROLLMENT lEVEL fEE
        public String grossAmount;         //1500
        public String modeOfTransport;      //delivery
        public String partNumber;           //reppro
        public String pointOfTitleTransfer; //i
        public String shipFromCountry;      //united states
        public String shipToCountry;        //france
        public String supplementaryUnit;    //Each
        public String totalTaxAmount;      //0
        public String uom;                  //Each
        public String transactionType;      //GS
        public Cls_taxSummary taxSummary;
        public Cls_taxes[] taxes;

        /** @description : get method for object type nodes
        * @param key
        * @return Object
        */
        public Object get(String key){
            Object obj;
            switch on key{
                when 'taxSummary'{
                    this.taxSummary = this.taxSummary==null?new Cls_taxSummary():this.taxSummary;
                    obj = this.taxSummary;
                }
                when 'taxes'{
                    this.taxes = this.taxes==null?new List<Cls_taxes>():this.taxes;
                    obj = this.taxes;
                }
                when else{
                    obj = ((Map<String,Object>)JSON.deserializeUntyped(JSON.serialize(this))).get(key);
                }
            }
            return obj;
        }
    }

    /** @description : wrapper class for tax calculation response tax summary*/
    public class Cls_taxSummary implements OneSourceTaxResponseInterface{
        public String taxableBasis;        //1500
        public String nonTaxableBasis;     //0
        public String exemptAmount;        //0
        public String taxRate;             //0
        public String effectiveTaxRate;    //0
        
        /** @description : get method for object type nodes
        * @param key
        * @return Object
        */
        public Object get(String key){
            Object obj = ((Map<String,Object>)JSON.deserializeUntyped(JSON.serialize(this))).get(key);
            return obj;
        }
    }

    /** @description : wrapper class for tax calculation response tax lines*/
    public class Cls_taxes implements OneSourceTaxResponseInterface{
        public String addressType;          //sf
        public String adminZoneLevel;       //State
        public String authorityName;        //us - united states export
        public String authorityType;        //sTATE sALES/uSE
        public String calculationMethod;    //1
        public String comment;              //oracle[usex]
        public String erpTaxCode;           //usex
        public String effectiveZoneLevel;   //State
        public String documentDescription;  //nO lIABILITY
        public String jurisdictionText;     //ussg157: nO us SALES OR USE TAX APPLIES TO EXPORTS.
        public String ruleOrder;           //5000
        public String taxableCountry;       //us
        public String taxableCountryName;   //united states
        public String taxableState;         //pennsylvania
        public String taxableCounty;        //delaware
        public String taxableCity;          //unincorporated
        public String taxableGeoCode;       //3200
        public String taxablePostalCode;    //19073
        public String taxRateCode;          //nl
        public String taxType;              //nl
        public String zoneName;             //united states
        public String zoneLevel;            //State
        public String taxRate;             //0
        public String natureOfTax;          //p
        public String euTransaction;
        public String authorityUuid;            //1B40AAA8-C77F-4D49-BB4E-3AED83013016
        public String authorityCurrencyCode;    //USD
        public Cls_currencyConversion[] currencyConversion;
        public Cls_Amount exemptAmount;
        public Cls_Amount grossAmount;
        public Cls_Amount nonTaxableBasis;
        public Cls_taxableBasis taxableBasis;
        public Cls_Amount taxAmount;
        public String taxDeterminationDate; //2019-12-09
        public String taxPointDate;         //2019-12-09

        /** @description : get method for object type nodes
        * @param key
        * @return Object
        */
        public Object get(String key){
            Object obj;
            switch on key{
                when 'currencyConversion'{
                    this.currencyConversion = this.currencyConversion==null?new List<Cls_currencyConversion>():this.currencyConversion;
                    obj = this.currencyConversion;
                }
                when 'exemptAmount'{
                    this.exemptAmount = this.exemptAmount==null?new Cls_Amount():this.exemptAmount;
                    obj = this.exemptAmount;
                }
                when 'grossAmount'{
                    this.grossAmount = this.grossAmount==null?new Cls_Amount():this.grossAmount;
                    obj = this.grossAmount;
                }
                when 'nonTaxableBasis'{
                    this.nonTaxableBasis = this.nonTaxableBasis==null?new Cls_Amount():this.nonTaxableBasis;
                    obj = this.nonTaxableBasis;
                }
                when 'taxableBasis'{
                    this.taxableBasis = this.taxableBasis==null?new Cls_taxableBasis():this.taxableBasis;
                    obj = this.taxableBasis;
                }
                when 'taxAmount'{
                    this.taxAmount = this.taxAmount==null?new Cls_Amount():this.taxAmount;
                    obj = this.taxAmount;
                }
                when else{
                    obj = ((Map<String,Object>)JSON.deserializeUntyped(JSON.serialize(this))).get(key);
                }
            }
            return obj;
        }
    }

    /** @description : wrapper class for tax calculation response currency conversion info*/
    public class Cls_currencyConversion implements OneSourceTaxResponseInterface{
        public String taxExchangeRateDate;  //2019-12-09
        public String exchangeRateSource;   //

        /** @description : get method for object type nodes
        * @param key
        * @return Object
        */
        public Object get(String key){
            Object obj = ((Map<String,Object>)JSON.deserializeUntyped(JSON.serialize(this))).get(key);
            return obj;
        }
    }

    /** @description : wrapper class for tax calculation response tax Amount info*/
    public class Cls_Amount implements OneSourceTaxResponseInterface{
        public String documentAmount;          //0
        public String unroundedDocumentAmount; //0
        public String authorityAmount;         //0
        public String unroundedAuthorityAmount;    //0

        /** @description : get method for object type nodes
        * @param key
        * @return Object
        */
        public Object get(String key){
            Object obj = ((Map<String,Object>)JSON.deserializeUntyped(JSON.serialize(this))).get(key);
            return obj;
        }
    }
    
    /** @description : wrapper class for tax calculation response taxable basis*/
    public class Cls_taxableBasis implements OneSourceTaxResponseInterface{
        public String documentAmount;              //1500
        public String unroundedDocumentAmount;     //1500
        public String authority_amount;            //1500
        public String unrounded_authority_amount;  //1500

        /** @description : get method for object type nodes
        * @param key
        * @return Object
        */
        public Object get(String key){
            Object obj = ((Map<String,Object>)JSON.deserializeUntyped(JSON.serialize(this))).get(key);
            return obj;
        }
    }

    /** @description : wrapper class for tax calculation response meta*/
    public class Cls_meta implements OneSourceTaxResponseInterface{
        public String status;           //success
        public String message;          //document Calcualted Successfully
        public String code;             //200
        public Cls_partnerMessages[] partnerMessages;

        /** @description : get method for object type nodes
        * @param key
        * @return Object
        */
        public Object get(String key){
            Object obj;
            switch on key{
                when 'partnerMessages'{
                    this.partnerMessages = this.partnerMessages==null?new List<Cls_partnerMessages>():this.partnerMessages;
                    obj = this.partnerMessages;
                }
                when else{
                    obj = ((Map<String,Object>)JSON.deserializeUntyped(JSON.serialize(this))).get(key);
                }
            }
            return obj;
        }
    }

    /** @description : wrapper class for tax calculation response gross amount*/
    public class Cls_partnerMessages implements OneSourceTaxResponseInterface{
        public String status;           //warning
        public String code;             //INVALID_CURRENCY_CODE
        public String message;          //The Currency Code passed was invalid.
        public String location;         //Header
        public String locationId;       //QTE30180

        /** @description : get method for object type nodes
        * @param key
        * @return Object
        */
        public Object get(String key){
            Object obj = ((Map<String,Object>)JSON.deserializeUntyped(JSON.serialize(this))).get(key);
            return obj;
        }
    }

    /**
    * @description   This method is used to Create Payload for One Source Tax
    * @param  orderId Order id
    * @return  String Request JSON String
    */
    public static string getOneSourceOrderTaxPayload(Id orderId)
    {
        WrapperParametrs params = new WrapperParametrs();
        params.objectName = 'Order';
        params.lineObjectName = 'OrderItem';
        params.lineObjectRelationName = 'OrderItems';
        params.taxCallTypename = 'Order Tax';
        return getOneSourceTaxPayload(orderId, params);
    }


    /**
    * @description   This method is used to Create Payload for One Source Tax
    * @param  invoiceId Order id
    * @return  String Request JSON String
    */
    public static string getOneSourceInvoiceTaxPayload(Id invoiceId)
    {
        WrapperParametrs params = new WrapperParametrs();
        params.objectName = 'blng__Invoice__c';
        params.lineObjectName = 'blng__InvoiceLine__c';
        params.lineObjectRelationName = 'blng__InvoiceInvoiceLines__r';
        params.taxCallTypename = 'Invoice Tax';
        return getOneSourceTaxPayload(invoiceId, params);
    }

    /**
    * @description   This method is used to Create Payload for One Source Tax
    * @param  recordId sobject id
    * @param  params
    * @return  String Request JSON String
    */
    private static string getOneSourceTaxPayload(Id recordId, WrapperParametrs params)
    {
        List<API_Field_Mapping__mdt> listAFM = [SELECT API_3rd_Party_Name__c,API_Call_Name__c,API_Node_Name__c,API_Node_Value__c,Do_Not_Use_in_API_Mapping__c,Field_Name__c,isLineMapping__c,Object_Field_Value__c,Object_Name__c,SObject_Field_Name__c,Object_Name__r.QualifiedApiName,Custom_Node__c FROM API_Field_Mapping__mdt WHERE JSON_Type__c=:params.jsonTypeName AND API_Call_Name__c=:params.taxCallTypename AND API_3rd_Party_Name__c=:params.thirdPartyName AND Do_Not_Use_in_API_Mapping__c=false WITH SECURITY_ENFORCED];
        String objectFields = 'Id';
        String objectFieldsLines = 'Id';
        List<API_Field_Mapping__mdt> listAFMOrder = new List<API_Field_Mapping__mdt>();
        List<API_Field_Mapping__mdt> listAFMOI = new List<API_Field_Mapping__mdt>();
        for(API_Field_Mapping__mdt afm : listAFM){
            if(afm.Object_Name__r.QualifiedApiName == params.objectName){
                if(!(','+objectFields+',').contains(','+afm.SObject_Field_Name__c+',')){objectFields += ',' + afm.SObject_Field_Name__c;}
            }
            if(afm.Object_Name__r.QualifiedApiName == params.lineObjectName){
                if(!(','+objectFieldsLines+',').contains(','+afm.SObject_Field_Name__c+',')){objectFieldsLines += ',' + afm.SObject_Field_Name__c;}
            }
            if(afm.isLineMapping__c){
                listAFMOI.add(afm);
            }
            else{
                listAFMOrder.add(afm);
            }
        }
        String query = 'SELECT ' + String.escapeSingleQuotes(objectFields) + ',(Select ' + String.escapeSingleQuotes(objectFieldsLines) + ' FROM '+String.escapeSingleQuotes(params.lineObjectRelationName)+') FROM '+String.escapeSingleQuotes(params.objectName)+' WHERE Id=:recordId';
        System.debug(LoggingLevel.Debug, query);
        SObject sobj = Database.query(query);
        Cls_Request reqObj = new Cls_Request();
        for(API_Field_Mapping__mdt afm : listAFMOrder){
            if(filterMetadata(sobj,afm))
            {
                String value = (String.isNotBlank(afm.API_Node_Value__c)?afm.API_Node_Value__c:'');
                if(String.isNotBlank(afm.SObject_Field_Name__c)){
                    String value2 = getSObjectValue(sobj, afm.SObject_Field_Name__c);
                    value += (value2==null?'':value2);
                }
                if(!afm.API_Node_Name__c.contains('.')){
                    if(value!=''){reqObj.put(afm.API_Node_Name__c,value);}
                }
                else{
                    List<String> nodeSplit = afm.API_Node_Name__c.split('\\.');
                    if(value!=''){setJSONNodeValue(value, afm.API_Node_Name__c.replaceAll(nodeSplit[0]+'.', ''),(OneSourceTaxRequestInterface)reqObj.get(nodeSplit[0]));}
                }
            }
        }
        reqObj.lines = new List<Cls_lines_req>();
        for(SObject line : sobj.getSObjects(params.lineObjectRelationName)){
            Cls_lines_req reqLineObj = new Cls_lines_req();
            for(API_Field_Mapping__mdt afm : listAFMOI){
                if(filterMetadata(line,afm))
                {
                    String value = (String.isNotBlank(afm.API_Node_Value__c)?afm.API_Node_Value__c:'');
                    if(String.isNotBlank(afm.SObject_Field_Name__c)){
                        System.debug(LoggingLevel.Debug, afm.SObject_Field_Name__c);
                        String value2 = getSObjectValue(line, afm.SObject_Field_Name__c);
                        value += (value2==null?'':value2);
                    }
                    if(!afm.API_Node_Name__c.contains('.')){
                        if(value!=''){reqLineObj.put(afm.API_Node_Name__c,value);}
                    }
                    else{
                        List<String> nodeSplit = afm.API_Node_Name__c.split('\\.');
                        String firstNodeName = nodeSplit.remove(0);
                        String nodeName = String.join(nodeSplit,'.');
                        if(value!=''){setJSONNodeValue(value, nodeName,(OneSourceTaxRequestInterface)reqLineObj.get(firstNodeName));}
                    }
                }
            }
            reqObj.lines.add(reqLineObj);
        }
        String strJSON = JSON.serialize(reqObj).replaceAll(',"currencyReq":"', ',"currency":"');
        strJSON = strJSON.replaceAll('"orderOrigin":null,', '');
        strJSON = strJSON.replaceAll('"orderAcceptance":null,', '');
        System.debug(LoggingLevel.Debug, strJSON);
        return strJSON;
    }

    /**
    * @description   This method is used to get sboject field value
    * @param  obj SObject
    * @param  fieldName field name
    * @return  SObject field value
    */
    public static string getSObjectValue(SObject obj, String fieldName)
    {
        String value;
        List<String> fieldSplit = fieldName.split('\\.');
        if(1 == fieldSplit.size()){
            if(obj != null && obj.get(fieldSplit[0]) != null){value = String.valueOf(obj.get(fieldSplit[0]));}
        }
        else{
            String firstNodeName = fieldSplit.remove(0);
            String nodeName = String.join(fieldSplit,'.');
            value = getSObjectValue(obj.getSObject(firstNodeName),nodeName);
        }
        return value;
    }

    /**
    * @description   This method is used to set JSON Node value
    * @param  value value
    * @param  nodeName node name
    * @param  otriObj
    */
    public static void setJSONNodeValue(String value, String nodeName, OneSourceTaxRequestInterface otriObj)
    {
        List<String> nodeSplit = nodeName.split('\\.');
        if(1 == nodeSplit.size()){
            if(value != ''){otriObj.put(nodeSplit[0],value);}
        }
        else{
            String firstNodeName = nodeSplit.remove(0);
            String nodeName2 = String.join(nodeSplit,'.');
            setJSONNodeValue(value, nodeName2,(OneSourceTaxRequestInterface)otriObj.get(firstNodeName));
        }
    }

    /**
    * @description   This method is used to get JSON Node value
    * @param  nodeName node name
    * @param  otriObj
    * @return object
    */
    public static object getJSONNodeValue(String nodeName, OneSourceTaxResponseInterface otriObj) 
    {
        Object obj;
        List<String> nodeSplit = nodeName.split('\\.'); 
        if(1 == nodeSplit.size()){
            obj = otriObj.get(nodeSplit[0]);
        }
        else{
            obj = getJSONNodeValue(nodeName.replaceAll(nodeSplit[0]+'.', ''),(OneSourceTaxResponseInterface)otriObj.get(nodeSplit[0]));
        }
        return obj;
    }

    /** @description : wrapper class to create parametrs*/
    public class WrapperParametrs
    {
        public String objectName;
        public String lineObjectName;
        public String lineObjectRelationName;
        public String taxCallTypename;
        public String thirdPartyName = 'Onesource';
        public String jsonTypeName = 'Request';
        public Map<String,Map<String,List<API_Field_Mapping__mdt>>> mapObjectApiNameAndListAFM = new Map<String,Map<String,List<API_Field_Mapping__mdt>>>();
    }

    private static Boolean filterMetadata(SObject obj,API_Field_Mapping__mdt afm)
    {
        Boolean isValid = true;
        // Filter Metadata for Query Only Nodes [OBP-430]
        if(String.isBlank(afm.API_Node_Name__c))
        {
            isValid = false;
        }

        // Filter metadata with Product Family [OBP-430]
        // Custom Node Format - <Product Cat[Event/Subscription]>#<ProductFamily Field Api> 
        if(String.isNotBlank(afm.Custom_Node__c) && 
           (afm.Custom_Node__c.contains('#Product2.Family') || afm.Custom_Node__c.contains('#blng__Product__r.Family') ))
        {  
            String productFamilyValue = getSObjectValue(obj,afm.Custom_Node__c.split('#')[1]);
            productFamilyValue = (String.isNotBlank(productFamilyValue) ? productFamilyValue :'');
            productFamilyValue = ',' + productFamilyValue + ',';
            String productCat = ',' + afm.Custom_Node__c.split('#')[0] + ',';            
            if(!productCat.contains(productFamilyValue))
            {
                isValid = false;
            }
        }

        // Filter metadata with TaxExempt  [IOM-1421]
        // Custom Node Format - TaxExempt
        if(String.isNotBlank(afm.Custom_Node__c) && afm.Custom_Node__c.equalsIgnoreCase('TaxExempt'))
        {
            if(getSObjectValue(obj,afm.SObject_Field_Name__c) == 'false')
            {
                isValid = false;
            }
        }
        return isValid;
    }
}