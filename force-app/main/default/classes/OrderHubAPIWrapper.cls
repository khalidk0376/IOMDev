/**
* File         :   OrderHubAPIWrapper 
* Project      :   Order & Billing Plateform
* Created Date :   29th Sept 2021
* Created By   :   Girikon(Ashish)
* Test Class   :   OracleOrderHubAPIUtils_Test (88%)
* ***************************************************************************************************
* @description : contain the Wrapper Nodes for ORDER_HUB Callouts & Payload creation Methord(OBP-341)
* ***************************************************************************************************
* Modification log :  
* 1. Girikon(Suresh) [IOM-666]  1 Feb 2022, Updated payload to include Payment Schedule fields 
* 2. Girikon(Ashish) [IOM-839]  14 Feb 2022, Updated payload to include new tax line fields 
* 3. Girikon(Ashish) [IOM-572]  14 Feb 2022, Updated payload to Amended Data payload
* 4. Girikon(Ashish) [IOM-1054] 23 Mar 2022, Added date nodes in Document Lines
* 5. Girikon(Ashish) [IOM-1778] 04 July 2022, Only Billing Address will be used for Bill/Shipp To
* 6. Girikon(Ashish) [IE-10]    17 Aug 2022, Payment from IOM to Order Hub
* 7. Girikon(Ashish) [IE-17]    23 Aug 2022, Customer details from IOM to Order Hub
* 8. Girikon(Ansh)   [IE-42]    26 Aug 2022, Tax Lines from IOM to Order Hub
* 9. Girikon(Ashish) [GECI-283] 02 Dec 2022, Added OH Changes for GE
* 10.Girikon(Ashish) [GECI-537] 12 Jan 2023, For Translated records SAP requires post code to be in English even for translated value
* 11.Girikon(Ashish) [GECI-1379] 10 Apr 2023, Validation to check translated values before sending to OrderHub
* 12.Girikon(Ashish) [GECI-916] 15 May 2023, Amendment process Changes to Allow Multiple Amendments for Order Hub
* 13.IBM(Bharath) [GECI-1894] 19 June 2023, JSON to OH For Account & Address Amendments to include the translated fields
*/
@SuppressWarnings('PMD')
public with sharing class OrderHubAPIWrapper {

    private static final String ERP_SYNC_STATUS = 'Sync Required';
    private Static final String FILTER_FIELD_API_METANAME = 'Invoice_External_No_Field';
    
    /******************************** RESPONSE DATA MODEL****************************************/
    
    /** @description : wrapper class Response Data*/
    public class Response
    {
        public Cls_Meta meta;
    }
    /** @description : wrapper class Meta Header*/
	public class Cls_Meta {
		public String status;	    //incomplete
		public String message;	    //Some message
		public Cls_DetailedMessage detailedMessage;
	}
    /** @description : wrapper class detailedMessage*/
	public class Cls_DetailedMessage {
		public Cls_Errors[] errors;
	}
    /** @description : wrapper class Response Error Details*/
	public class Cls_Errors {
		public String documentId;	//MSG_232425
		public String message;	    //[object has missing required properties (["sourceSystem"])]
	}

    /******************************* REQUEST DATA MODEL******************************************/

	/** @description : Order Hub Request Interface*/
    public interface OrderHubRequestInterface{
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
    /** @description : wrapper class for Req Meta INFO*/
    public class Cls_ReqMeta {
        public String primaryLanguage ='en';
        public String[] translationLanguages;
    }

    /** @description : wrapper class for Document[Invoice/Credit Note]*/
    public class Cls_Document implements OrderHubRequestInterface{
        public Cls_ReqMeta meta ;
		public String documentId='';	    //NPD-SINV-01JL-02
		public String sourceSystem='';	    //CHARGEBEE_SS365
		public String documentType='';	    //Invoice
		public String referenceDocumentId='';	//
		public String contractId='';	    //AzZlzlSay8PYx4vi
		public String legalEntityCode='';	//U077
		public String clientAccount='';	//Informa
		public String brandName='';	    //SupplySide
		public String financialPeriod='';	//
		public String documentDate='';	    //2021-06-21T00:00:00
		public Decimal amount=0;	        //425.33
		public Decimal discountAmount=0;	//0
		public Decimal balance=0;	        //0
		public String documentOrigin='';	//MM
		public String dueDate='';	        //2021-06-21T00:00:00
		public String currencyReq='';	    //USD
		public String paymentTerms='';	    //0
		public String salesOrder='';	    //
		public String purchaseOrder='';	//
		public String barter='';	        //
		public String taxCode='';	        //
		public String taxName='';	        //
		public String taxCountryCode='';	//
        public String salesPersonEmail='';	//"test.test@test.com"
        public String salesPersonName='';	//"Test User"
        public String salesPersonLastName;	//"User"
        public String salesPersonFirstName;	//"Test"
        public String toPrint='';	        // * To accept only Y / N values *
        public String opportunityId='';	//
        public String documentHeaderText='';	//
        public String documentFooterText='';	//
		public Cls_Account[] account;
		public Cls_Contact contact;
		public Cls_DocumentLines[] documentLines;
        public Cls_Schedule[] instalments;
        public Cls_Email email = new Cls_Email();
        public List<Object> translations;

		/** @description : put method for class
        * @param key
        * @param value
        */
        public void put(String key, String value){
            switch on key{
                when 'documentId'{
                    this.documentId = value;
                }
                when 'sourceSystem'{
                    this.sourceSystem = value;
                }
                when 'documentType'{
                    this.documentType = value;
                }
                when 'referenceDocumentId'{
                    this.referenceDocumentId = value;
                }
                when 'contractId'{
                    this.contractId = value;
                }
                when 'legalEntityCode'{
                    this.legalEntityCode = value;
                }
                when 'clientAccount'{
                    this.clientAccount = value;
                }
				when 'brandName'{
                    this.brandName = value;
                }
				when 'financialPeriod'{
                    this.financialPeriod = value;
                }
				when 'documentDate'{
                    this.documentDate = formatJSONDate(value);
                }
				when 'amount'{
                    this.amount = Decimal.valueOf(value);
                }
				when 'discountAmount'{
                    this.discountAmount = Decimal.valueOf(value);
                }
				when 'balance'{
                    this.balance = Decimal.valueOf(value);
                }
				when 'documentOrigin'{
                    this.documentOrigin = value;
                }
				when 'dueDate'{
                    this.dueDate = formatJSONDate(value);
                }
				when 'currencyReq'{
                    this.currencyReq = value;
                }
				when 'paymentTerms'{
                    this.paymentTerms = value;
                }
                when 'salesOrder'{
                    this.salesOrder = value;
                }
				when 'purchaseOrder'{
                    this.purchaseOrder = value;
                }
                when 'barter'{
                    this.barter = value;
                }
				when 'taxCode'{
                    this.taxCode = value;
                }
                when 'taxName'{
                    this.taxName = value;
                }
				when 'taxCountryCode'{
                    this.taxCountryCode = value;
                }
                when 'salesPersonEmail'{
                    this.salesPersonEmail = value;
                }
                when 'salesPersonName'{
                    this.salesPersonName = value;
                }
                when 'toPrint'{
                    this.toPrint = value;
                }
				when 'opportunityId'{
                    this.opportunityId = value;
                }
                when 'documentHeaderText'{
                    this.documentHeaderText = value;
                }
				when 'documentFooterText'{
                    this.documentFooterText = value;
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
                when 'contact'{
                    this.contact = this.contact==null?new Cls_Contact():this.contact;
                    obj = this.contact;
                }
                when 'documentLines'{
                    this.documentLines = this.documentLines==null?new List<Cls_DocumentLines>():this.documentLines;
                    obj = this.documentLines;
                }
                when 'email'{
                    this.email = this.email==null?new Cls_Email():this.email;
                    obj = this.email;
                }             
            }
            return obj;
		}
	}
	/** @description : wrapper class for Account*/
	public class Cls_Account implements OrderHubRequestInterface{
		public String accountId='';	    //NP-SACC-01JL-01
		public String name='';	            //Sangeethanew Parsannew
		public String emailAddress='';	    //sp401@peteam.testinator.com
		public String phone='';	        //
		public String accountType='';	    //CUSTOMER
		public String accountStatus='';	//ACTIVE
		public String taxCategory='';	//
		public String taxNumberPrefix='';	//
		public String taxNumber='';	//
		public Cls_Addresses[] addresses;
        public List<Object> translations;

		/** @description : put method for class
        * @param key
        * @param value
        */
        public void put(String key, String value){
            switch on key{
                when 'accountId'{
                    this.accountId = value;
                }
                when 'name'{
                    this.name = value;
                }
                when 'emailAddress'{
                    this.emailAddress = value;
                }
                when 'phone'{
                    this.phone = value;
                }
                when 'accountType'{
                    this.accountType = value;
                }
                when 'accountStatus'{
                    this.accountStatus = value;
                }  
                when 'taxCategory'{
                    this.taxCategory = value;
                }
                when 'taxNumberPrefix'{
                    this.taxNumberPrefix = value;
                }    
                when 'taxNumber'{
                    this.taxNumber = value;
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
                when 'addresses'{
                    this.addresses = this.addresses==null?new List<Cls_Addresses>():this.addresses;
                    obj = this.addresses;
                }                
            }
            return obj;
		}
	}
	/** @description : wrapper class for Addresses*/
	public class Cls_Addresses implements OrderHubRequestInterface{
		public String addressType='';	    //Shipping
		public String addressLine1='';	    //17411 Hollyberry Lane
		public String addressLine2='';	    //
		public String addressLine3='';	    //
		public String city='';	            //Sugar Land
        public String state='';
		public String stateCode='';	    //TX
		public String postalCode='';	    //77479
		public String countryCode='';	    //US
        public List<Object> translations;

		/** @description : put method for class
        * @param key
        * @param value
        */
        public void put(String key, String value){
            switch on key{
                when 'addressType'{
                    this.addressType = value;
                }
                when 'addressLine1'{
                    this.addressLine1 = value;
                }
				when 'addressLine2'{
                    this.addressLine2 = value;
                }
                when 'addressLine3'{
                    this.addressLine3 = value;
                }
				when 'city'{
                    this.city = value;
                }
                when 'state'{
                    this.state = value;
                }
                when 'stateCode'{
                    this.stateCode = value;
                }
				when 'postalCode'{
                    this.postalCode = value;
                }
                when 'countryCode'{
                    this.countryCode = value;
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
	
	/** @description : wrapper class for Contact*/
	public class Cls_Contact implements OrderHubRequestInterface{
		public String contactId='';	    //NP-SCON-01JL-01
		public String salutation='';	    //
		public String title='';	        //
		public String firstName='';	    //Sangeethanew
		public String lastName='';	        //Parsannew
		public String emailAddress='';	    //sp401@peteam.testinator.com
		public String phone='';	        //
		public String contactType='';	    //CUSTOMER
		public String contactStatus='';	//ACTIVE
        public List<Object> translations;

		/** @description : put method for class
        * @param key
        * @param value
        */
        public void put(String key, String value){
            switch on key{
                when 'contactId'{
                    this.contactId = value;
                }
                when 'salutation'{
                    this.salutation = value;
                }
				when 'title'{
                    this.title = value;
                }
                when 'firstName'{
                    this.firstName = value;
                }
				when 'lastName'{
                    this.lastName = value;
                }
                when 'emailAddress'{
                    this.emailAddress = value;
                }
				when 'phone'{
                    this.phone = value;
                }
                when 'contactType'{
                    this.contactType = value;
                }
				when 'contactStatus'{
                    this.contactStatus = value;
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
	/** @description : wrapper class for DocumentLines*/
	public class Cls_DocumentLines implements OrderHubRequestInterface{
		public String lineNumber='';	    //1
        public decimal parentSumNetValue=0;	//123.10
        public String parentProduct='';
        public String suppressFlag='';	    //Y
		public String description='';	    //SS365 Yearly Plan
        public String lineItemDescription='';	    //SS365 Yearly Plan
		public String referenceLineNumber='';	//
		public String orderId='';	        //
		public String orderDetailId='';	//
		public String billingStage='';	    //paid
		public String productCode='';	    //ss365-standard-plan
		public Decimal quantity=0;	    //1
		public String uom='';	            //
		public String productStartDate='';	//2021-06-21T00:00:00
		public String productEndDate='';	//2022-06-21T00:00:00
        public String serviceStartDate='';	//2021-06-21T00:00:00  [IOM-1054]
		public String serviceEndDate='';	//2022-06-21T00:00:00   [IOM-1054]
        public String campaignName='';
		public Decimal netAmount=0;	    //399
		public Decimal taxAmount=0;	    //26.33
		public Decimal discountAmount=0;	//0
		public String authorityName='';	//
		public String authorityType='';	//
        public String billingScheduleStage='';	//
        public String billingSchedulePercentage='';	//
		public Cls_Taxes[] taxes;
        public List<Object> translations;

		/** @description : put method for class
        * @param key
        * @param value
        */
        public void put(String key, String value){
            switch on key{
                when 'lineNumber'{
                    this.lineNumber = value;
                }
                when 'description'{
                    this.description = value;
                }
                when 'referenceLineNumber'{
                    this.referenceLineNumber = value;
                }
                when 'campaignName'{
                    this.campaignName = value;
                }
                when 'orderId'{
                    this.orderId = value;
                }
                when 'orderDetailId'{
                    this.orderDetailId = value;
                }
                when 'billingStage'{
                    this.billingStage = value;
                }  
				when 'productCode'{
                    this.productCode = value;
                }
                when 'quantity'{
                    this.quantity = Decimal.valueOf(value);
                }
                when 'uom'{
                    this.uom = value;
                }
				when 'productStartDate'{
                    this.productStartDate = formatJSONDate(value);
                }
                when 'productEndDate'{
                    this.productEndDate = formatJSONDate(value);
                }
                when 'serviceStartDate'{
                    this.serviceStartDate = formatJSONDate(value);
                }
                when 'serviceEndDate'{
                    this.serviceEndDate = formatJSONDate(value);
                }
                when 'netAmount'{
                    this.netAmount = Decimal.valueOf(value);
                }
				when 'taxAmount'{
                    this.taxAmount = Decimal.valueOf(value);
                }
				when 'discountAmount'{
                    this.discountAmount = Decimal.valueOf(value);
                }
                when 'parentSumNetValue'{
                    this.parentSumNetValue = Decimal.valueOf(value);
                }
                when 'parentProduct'{
					this.parentProduct = String.valueOf(value)=='True'?'Y':'N'; //GECI-27
                }
                when 'suppressFlag'{
					this.suppressFlag = String.valueOf(value)=='True'?'Y':'N'; //GECI-27
                }
                when 'billingScheduleStage'{
                    this.billingScheduleStage = value;
                }
                when 'billingSchedulePercentage'{
                    this.billingSchedulePercentage = String.isNotBlank(value)?value+' %':value;
                }
				/*when 'authorityName'{
                    this.authorityName = value;
                }
				when 'authorityType'{
                    this.authorityType = value;
                }*/			
            }            
        }
		/** @description : get method for object type nodes
        * @param key
        * @return Object
        */
        public Object get(String key){
			Object obj;
            switch on key{               
                when 'taxes'{
                    this.taxes = this.taxes==null?new List<Cls_Taxes>():this.taxes;
                    obj = this.taxes;
                }                
            }
            return obj;
		}
	}
	/** @description : wrapper class for Taxes*/
	public class Cls_Taxes implements OrderHubRequestInterface{
		public Decimal taxRate=0;	    //6.25
		public String taxCode='';	    //TX STATE TAX
		public String taxCountry='';	//
		public Decimal taxAmount=0;	    //19.95
        public String taxState='';	    //
        public String taxCity='';	    //
        public String taxCounty='';	    //
        public String taxZone='';	    //
        public String natureOfTax='';	//


		/** @description : put method for class
        * @param key
        * @param value
        */
        public void put(String key, String value){
            switch on key{
                when 'taxRate'{
                    this.taxRate = Decimal.valueOf(value);
                }
                when 'taxCode'{
                    this.taxCode = value;
                }
				when 'taxCountry'{
                    this.taxCountry = value;
                }
                when 'taxState'{
                    this.taxState = value;
                }
				when 'taxCity'{
                    this.taxCity = value;
                }
                when 'taxCounty'{
                    this.taxCounty = value;
                }
				when 'taxZone'{
                    this.taxZone = value;
                }
                when 'natureOfTax'{
                    this.natureOfTax = value;
                }
                when 'taxAmount'{
                    this.taxAmount = Decimal.valueOf(value);
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
        /** @description : wrapper class for PaymentSchedule*/
	public class Cls_Schedule implements OrderHubRequestInterface{
		public Decimal amount=0;
		public Date dueDate;
		public Decimal ledgerAmount=0;

		/** @description : put method for class
        * @param key
        * @param value
        */
        public void put(String key, String value){
            switch on key{
                when 'amount'{
                    this.amount = Decimal.valueOf(value);
                }
                when 'dueDate'{
                    this.duedate = Date.valueOf(value);
                }
                when 'ledgerAmount'{
                    this.ledgerAmount = Decimal.valueOf(value);
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

     /** @description : wrapper class for Email [GECI-283]*/  
	public class Cls_Email implements OrderHubRequestInterface{
		public string  cc='';
        public string  bcc='';

		/** @description : put method for class
        * @param key
        * @param value
        */
        public void put(String key, String value){
            switch on key{
                when 'cc'{
                    this.cc = value;
                }
                when 'bcc'{
                    this.bcc = value;
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
    /*******************************After Amendment Data Wrapper**********************************/

     /** @description : wrapper class for Account Update*/
	public class Cls_AccountDoc {
        public Cls_ReqMeta meta;
        public string[] erpDocumentNumber;
        public String legalEntity;	    //6038
        public String reprintFlag;	    //Y
        public Cls_AccountRefNo[] erpAccountIds;	
        public String accountId;	    //icaa1645506240360
        public String name;	            //API Automation
        public String emailAddress;	    //iomautomationtest@informa.com
        public String phone;	        //177564332
        public String accountType;	    //COMPANY
        public String accountStatus;	//Active
        public String taxCategory;	    //US01
        public String taxNumberPrefix;	//US
        public String taxNumber;	    //987654321
        public Cls_Addresses[] addresses;
		public List<Object> translations;

    }

    /** @description : wrapper class for Account Ref Deatils*/
	public class Cls_AccountRefNo {
        public String  account_type;    //BILL_TO
        public String  account_number;  //12345
    }


    /** @description : wrapper class for Contact Update*/
	public class Cls_ContactDoc {
        // public Cls_ReqMeta meta;
        public string[] erpDocumentNumber;
        public String erpAccountNumber; //12345 Account Oracle_Number
        public String IOMAccountNumber; //IM-45678
        public String legalEntity;	//6038
        public String reprintFlag;	 //Y
        public String contactId;	//icac1645506240360
        public String salutation;	//Mr.
        public String title;	//APIAutomation
        public String firstName;	//IOMAutomation
        public String lastName;	//Test
        public String emailAddress;	//iomautomationtest@informa.com
        public String phone;	//7712445
        public String contactType;	//Cont
        public String contactStatus;	//Active
        public List<Object> translations ;
    }

    /** @description : wrapper class for Po number Update*/
	public class Cls_PoNumberDoc {
        public string[] erpDocumentNumber;
        public String sourceSystem;	//IOM
        public String poNumber;	//PO12434
        public String reprintFlag;	//Y
        public String legalEntity;	//6038
    }

    /******************************* Payment Transactions Wrapper**********************************/
    class PaymentTransaction {
		public String paymentId;	    //txn_AzZl8HSSwHz4E25D
		public String sourceSystem;	    //SS_CHARGEBEE
		public String documentId;	    //56
		public String paymentType;	    //payment
		public String paymentMethod;	//card
		public String paymentStatus;	//success
		public String cardType;	        //visa		
		public String strCurrency;	    //EUR
		public Double amount;	            //309.72
		public String gateway_id;	        //cybersource
		public String gatewayAccountId;	    //gw_6opfGSMbo6fL1ta
		public String gatewayReference;	    //cb_Azz5z4SQIv5mV4h70
        public String authorisationNumber;	//AzZl8HSSwHz4J25E
		public String authorizationReason;	//verification
		public String authorisationDatetime;	//2020-11-26T01:20:00Z
	}

    /********************************* Amendment Single JSON Wrapper ********************** [GECI-916] */
    
    class Cls_Amendment {
		public Cls_ReqMeta meta;
		public String sourceSystem;	        //IOM
		public string[] erpDocumentNumber;
		public String legalEntity;	        //SA02
		public String reprintFlag;	        //Y
		public Cls_AmendDocument document;       
		public Cls_AmendContact contact;
		public Cls_AmendAccount account;
	}

    class Cls_AmendDocument {
		public String poNumber;	//TEST-PO-3
		public String documentHeaderText;	//Header1
		public String documentFooterText;	//Footer1
		public List<Object> translations;
	}

    class Cls_AmendContact {
		public String contactId;	    //UC2-CON-001
		public String erpAccountNumber;	//0001042405
		public String IOMAccountNumber;	//UC2-ACC-001
		public String salutation;	    //Mr
		public String title;	        //RupakTest
		public String firstName;	    //Rupak
		public String lastName;	        //Singh
		public String emailAddress;	    //puran@informa.com
		public String phone;	        //(+91)7838955564
		public String contactType;	    //CUSTOMER
		public String contactStatus;	//Active
		public List<Object> translations;
	}
	class Cls_AmendAccount {
		public Cls_AccountRefNo[] erpAccountIds;
		public String accountId;	//UC2-ACC-001
		public String name;	        //Amended Testing
		public String emailAddress;	//amendtest1676593007893@informa.com
		public String phone;	    //711676593007800
		public String accountType;	//COMPANY
		public String accountStatus;    //Active
		public String taxCategory;	//SA1
		public String taxNumberPrefix;	//SA
		public String taxNumber;	//123456789
		public List<Object> translations;
		public cls_addresses[] addresses;
	}

    /******************************** JSON Creator ************************************************/
    /**
    * @description   This method is used to Create Payload for OrderHub
    * @param  invoiceId Invoice id
    * @return  String Request JSON String
    */
    public static string getOrderHubInvoicePayload(Id invoiceId)
    {
        WrapperParametrs params = new WrapperParametrs();
        params.objectName = 'blng__Invoice__c';
        params.lineObjectName = 'blng__InvoiceLine__c';
        params.lineObjectRelationName = 'blng__InvoiceInvoiceLines__r';
        params.taxCallTypename = 'Post Invoice';
        return getOneSourceTaxPayload(invoiceId, params);
    }
    
    /**
    * @description   This method is used to Create Payload for OrderHub
    * @param  creditNoteId Credit Note id
    * @return  String Request JSON String
    */
    public static string getOrderHubCreditNotePayload(Id creditNoteId)
    {
        WrapperParametrs params = new WrapperParametrs();
        params.objectName = 'blng__CreditNote__c';
        params.lineObjectName = 'blng__CreditNoteLine__c';
        params.lineObjectRelationName = 'blng__CreditNoteCreditLines__r';
        params.taxCallTypename = 'Post Credit Note';
        return getOneSourceTaxPayload(creditNoteId, params);
    }

    /********************************** Utility Methods ******************************************/
    /**
    * @description   This method is used to Create Payload for One Source Tax
    * @param  recordId sobject id
    * @param  params
    * @return  String Request JSON String
    */
    private static string getOneSourceTaxPayload(Id recordId, WrapperParametrs params)
    {
                  
        // ********** -Query only fields for INV/CN- [GECI-283] **************
        set<string> extraInvQueryFields = new set<string>();
        set<string> extraCNQueryFields = new set<string>();
        extraInvQueryFields.addAll(new set<string>{'blng__Order__r.Edition__r.Edition_Code__c','blng__Order__r.Edition__r.X3rd_Party_ERP_System__c','blng__Order__r.Legacy_CRM_Instance__c,blng__BillToContact__c,blng__Account__c'});
        extraCNQueryFields.addAll(new set<string>{'blng__RelatedInvoice__r.blng__Order__r.Edition__r.Edition_Code__c','blng__RelatedInvoice__r.blng__Order__r.Edition__r.X3rd_Party_ERP_System__c','blng__RelatedInvoice__r.blng__Order__r.Legacy_CRM_Instance__c,blng__BillToContact__c,blng__Account__c'});

        /****** get Fields to Query from meta data settings ******/
        List<API_Field_Mapping__mdt> listAFM = [SELECT API_3rd_Party_Name__c,API_Call_Name__c,API_Node_Name__c,API_Node_Value__c,Do_Not_Use_in_API_Mapping__c,Field_Name__c,isLineMapping__c,Object_Field_Value__c,Object_Name__c,SObject_Field_Name__c,Object_Name__r.QualifiedApiName,Custom_Node__c,Do_Not_Use_in_SOQL__c FROM API_Field_Mapping__mdt WHERE JSON_Type__c=:params.jsonTypeName AND API_Call_Name__c=:params.taxCallTypename AND API_3rd_Party_Name__c=:params.thirdPartyName AND Do_Not_Use_in_API_Mapping__c=false WITH SECURITY_ENFORCED];

        String objectFields = 'Id';
        String objectFieldsLines = 'Id';
        String objectFieldsTaxLines = 'Id';
        String objectFieldsPaymentSchedules = 'Id';
        String objectFieldsTranslations = 'Id';
        List<API_Field_Mapping__mdt> listAFMOrder = new List<API_Field_Mapping__mdt>();
        List<API_Field_Mapping__mdt> listAFMOI = new List<API_Field_Mapping__mdt>();
        List<API_Field_Mapping__mdt> listAFMTax = new List<API_Field_Mapping__mdt>();
        List<API_Field_Mapping__mdt> listAFMBillAdd = new List<API_Field_Mapping__mdt>();
        List<API_Field_Mapping__mdt> listAFMShipAdd = new List<API_Field_Mapping__mdt>();
        List<API_Field_Mapping__mdt> listAFMSchAdd = new List<API_Field_Mapping__mdt>();
        List<API_Field_Mapping__mdt> listAFMAccount = new List<API_Field_Mapping__mdt>();
        List<API_Field_Mapping__mdt> listAFMTranslatons = new List<API_Field_Mapping__mdt>();
        
        /****** Filter API_Field_Mapping ****/
        for(API_Field_Mapping__mdt afm : listAFM){
            if(afm.Object_Name__r.QualifiedApiName == params.objectName && !afm.Do_Not_Use_in_SOQL__c){
                if(!(','+objectFields+',').contains(','+afm.SObject_Field_Name__c+',')){objectFields += ',' + afm.SObject_Field_Name__c;}
            }
            if(afm.Object_Name__r.QualifiedApiName == params.lineObjectName && !afm.Do_Not_Use_in_SOQL__c){
                if(!(','+objectFieldsLines+',').contains(','+afm.SObject_Field_Name__c+',')){objectFieldsLines += ',' + afm.SObject_Field_Name__c;}
            }
            if(String.isNotBlank(afm.Custom_Node__c))
            {
                string filterName = afm.Custom_Node__c.substringBefore('.');
                switch on filterName{
                    when 'taxes'{
                        if(!(','+objectFieldsTaxLines+',').contains(','+afm.SObject_Field_Name__c+',') && !afm.Do_Not_Use_in_SOQL__c){objectFieldsTaxLines += ',' + afm.SObject_Field_Name__c;}listAFMTax.add(afm);
                    }
                    when 'BillingAddress'{
                        if(afm.Object_Name__r.QualifiedApiName == params.objectName && !afm.Do_Not_Use_in_SOQL__c && !(','+objectFields+',').contains(','+afm.SObject_Field_Name__c+',')){objectFields += ',' + afm.SObject_Field_Name__c;}listAFMBillAdd.add(afm);
                    }
                    when 'ShippingAddress'{
                        if(afm.Object_Name__r.QualifiedApiName == params.objectName && !afm.Do_Not_Use_in_SOQL__c &&  !(','+objectFields+',').contains(','+afm.SObject_Field_Name__c+',')){objectFields += ',' + afm.SObject_Field_Name__c;}listAFMShipAdd.add(afm);
                    }
                    when 'account'{
                        listAFMAccount.add(afm);
                    }
                    when 'PaymentSchedule'{
                        if(afm.Object_Name__r.QualifiedApiName == 'Payment_Schedule__c' && !afm.Do_Not_Use_in_SOQL__c && !(','+objectFieldsPaymentSchedules+',').contains(','+afm.SObject_Field_Name__c+',')){objectFieldsPaymentSchedules += ',' + afm.SObject_Field_Name__c;}listAFMSchAdd.add(afm);
                    }
                    when 'Translations'{
                        listAFMTranslatons.add(afm);
                        if(afm.Object_Name__r.QualifiedApiName == 'Translated_Record__c' && !afm.Do_Not_Use_in_SOQL__c && !(','+objectFieldsTranslations+',').contains(','+afm.SObject_Field_Name__c+',')){objectFieldsTranslations += ',' + afm.SObject_Field_Name__c;}listAFMTranslatons.add(afm);
                    }                   
                }
            }else{
                if(afm.isLineMapping__c){
                    listAFMOI.add(afm);
                }
                else{
                    if(afm.API_Node_Name__c != 'billingAccount' && afm.API_Node_Name__c != 'shippingAccount'){
                        listAFMOrder.add(afm);
                    }
                }
            }
        }

        String x3rdPartyERPSystem ='';
        /****  Query Data ****/
        String paymentRcheduleRelationshipName = 'Payment_Schedules__r';
        String traslatedStatusFieldAPI ='';
        String query = '';
        string ProductDescriptionFieldAPI  = '';
        /**  Object & Line Item**/
        if(String.escapeSingleQuotes(params.objectName) == 'blng__Invoice__c'){
            traslatedStatusFieldAPI = 'blng__Order__r.Order_Translation_Status__c';
            for(string flds:extraInvQueryFields){if(!(','+objectFields+',').contains(','+flds+',')){objectFields += ',' + flds;}}
            query = 'SELECT ' + String.escapeSingleQuotes(objectFields) + ',(Select ' + String.escapeSingleQuotes(objectFieldsLines) + ',Translated_Product_Description__c FROM '+String.escapeSingleQuotes(params.lineObjectRelationName)+')'+',(Select ' + String.escapeSingleQuotes(objectFieldsPaymentSchedules) + ' FROM '+paymentRcheduleRelationshipName+'),'+traslatedStatusFieldAPI+' FROM '+String.escapeSingleQuotes(params.objectName)+' WHERE Id=:recordId';
            ProductDescriptionFieldAPI = 'Translated_Product_Description__c';
        }else{ //Credit Note
            traslatedStatusFieldAPI = 'blng__RelatedInvoice__r.blng__Order__r.Order_Translation_Status__c';
            for(string flds:extraCNQueryFields){if(!(','+objectFields+',').contains(','+flds+',')){objectFields += ',' + flds;}}
            query = 'SELECT ' + String.escapeSingleQuotes(objectFields) + ',(Select ' + String.escapeSingleQuotes(objectFieldsLines) + ',blng__InvoiceLine__r.Translated_Product_Description__c FROM '+String.escapeSingleQuotes(params.lineObjectRelationName)+'),'+traslatedStatusFieldAPI+' FROM '+String.escapeSingleQuotes(params.objectName)+' WHERE Id=:recordId';
            ProductDescriptionFieldAPI = 'blng__InvoiceLine__r.Translated_Product_Description__c';
        }

        System.debug(LoggingLevel.Debug, query);
        SObject sobj = Database.query(query);

        /*** Line Item & tax Lines***/
        String queryLine = 'SELECT Id,(Select ' + String.escapeSingleQuotes(objectFieldsTaxLines) + ' FROM Tax_Lines__r) FROM '+String.escapeSingleQuotes(params.lineObjectName)+' WHERE '+String.escapeSingleQuotes(params.objectName) +' =:recordId';

        System.debug(LoggingLevel.Debug, queryLine);
        list<SObject> sobjRecs = Database.query(queryLine);
        map<Id,SObject> taxMap = new map<Id,SObject>(sobjRecs);    

        // get Edition Setting Metadata [GECI-283]
        Edition_Setting__mdt editionSetting = getEditionSetting(sobj,params.objectName);

        Cls_Document reqObj = new Cls_Document();
        for(API_Field_Mapping__mdt afm : listAFMOrder){
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
                String firstNodeName = nodeSplit.remove(0);
                String nodeName = String.join(nodeSplit,'.');
                if(value!=''){setJSONNodeValue(value, nodeName,(OrderHubRequestInterface)reqObj.get(firstNodeName));}
            }
        }
        
        //For PaymentSchedule
        reqObj.instalments = params.objectName == 'blng__Invoice__c' ? getSchNode(sobj.getSObjects(paymentRcheduleRelationshipName),listAFMSchAdd) : new List<Cls_Schedule>();

        Cls_Account billingAccount = new Cls_Account();
        SObject sobjBillToAcc = sobj.getSObject('blng__Account__r');      
        for(API_Field_Mapping__mdt afm : listAFMAccount){
            String value = (String.isNotBlank(afm.API_Node_Value__c)?afm.API_Node_Value__c:'');
            if(String.isNotBlank(afm.SObject_Field_Name__c)){
                String value2 = getSObjectValue(sobjBillToAcc, afm.SObject_Field_Name__c);
                value += (value2==null?'':value2);
            }
            if(!afm.API_Node_Name__c.contains('.')){
                if(value!=''){billingAccount.put(afm.API_Node_Name__c,value);}
            }
            else{
                List<String> nodeSplit = afm.API_Node_Name__c.split('\\.');
                String firstNodeName = nodeSplit.remove(0);
                String nodeName = String.join(nodeSplit,'.');
                if(value!=''){setJSONNodeValue(value, nodeName,(OrderHubRequestInterface)billingAccount.get(firstNodeName));}
            }
        } 

        // Add Address
        List<Cls_Addresses> addrssesBillingAcc = new List<Cls_Addresses>();
        // For Billing
        Cls_Addresses billingAddressBillingAcc = getAddressNode(sobjBillToAcc,listAFMBillAdd);
        billingAddressBillingAcc.translations = new List<Object>();
        
        // For Shipping
        Cls_Addresses shippingAddressBillingAcc = new Cls_Addresses();//getAddressNode(sobjBillToAcc,listAFMShipAdd);
        shippingAddressBillingAcc.translations = new List<Object>();
        /* // IOM-1778 [Only Billing Address to be used]
        if(String.isBlank(shippingAddressBillingAcc.addressLine1) 
            && String.isBlank(shippingAddressBillingAcc.city )
            && String.isBlank(shippingAddressBillingAcc.countryCode)
            && String.isBlank(shippingAddressBillingAcc.postalCode)
            && String.isBlank(shippingAddressBillingAcc.stateCode))
        {*/
            shippingAddressBillingAcc.addressType     =  'Shipping';
            shippingAddressBillingAcc.addressLine1    =  billingAddressBillingAcc.addressLine1;
            shippingAddressBillingAcc.addressLine2    =  billingAddressBillingAcc.addressLine2;
            shippingAddressBillingAcc.addressLine3    =  billingAddressBillingAcc.addressLine3;
            shippingAddressBillingAcc.city            =  billingAddressBillingAcc.city;
            shippingAddressBillingAcc.stateCode       =  billingAddressBillingAcc.stateCode;
            shippingAddressBillingAcc.countryCode     =  billingAddressBillingAcc.countryCode;
            shippingAddressBillingAcc.postalCode      =  billingAddressBillingAcc.postalCode;
            shippingAddressBillingAcc.state      =  billingAddressBillingAcc.state;
        //}

        reqObj.account = new List<Cls_Account>();
        billingAccount.put('taxNumberPrefix', '');        
        string accountTaxNumVal = params.objectName == 'blng__Invoice__c' ?((blng__Invoice__c)sobj).blng__Order__r.Account_Tax_Number__r.Tax_ID__c:((blng__CreditNote__c)sobj).blng__RelatedInvoice__r.blng__Order__r.Account_Tax_Number__r.Tax_ID__c;
        billingAccount.put('taxNumber', String.isNotBlank(accountTaxNumVal)?accountTaxNumVal:'');        

        Cls_Account shippingAccount = new Cls_Account();
        SObject sobjShipToAcc;
        if(params.taxCallTypename == 'Post Credit Note'){
            sobjShipToAcc = sobj.getSObject('blng__RelatedInvoice__r').getSObject('Ship_To_Account__r');
            x3rdPartyERPSystem = getSObjectValue(sobj,'blng__RelatedInvoice__r.blng__Order__r.Edition__r.X3rd_Party_ERP_System__c');
        }
        else{
            sobjShipToAcc = sobj.getSObject('Ship_To_Account__r');
            x3rdPartyERPSystem = getSObjectValue(sobj,'blng__Order__r.Edition__r.X3rd_Party_ERP_System__c');
        }
        for(API_Field_Mapping__mdt afm : listAFMAccount){
            String value = (String.isNotBlank(afm.API_Node_Value__c)?afm.API_Node_Value__c:'');
            if(String.isNotBlank(afm.SObject_Field_Name__c)){
                String value2 = getSObjectValue(sobjShipToAcc, afm.SObject_Field_Name__c);
                value += (value2==null?'':value2);
            }
            if(!afm.API_Node_Name__c.contains('.')){
                if(value!=''){shippingAccount.put(afm.API_Node_Name__c,value);}
            }
            else{
                List<String> nodeSplit = afm.API_Node_Name__c.split('\\.');
                String firstNodeName = nodeSplit.remove(0);
                String nodeName = String.join(nodeSplit,'.');
                if(value!=''){setJSONNodeValue(value, nodeName,(OrderHubRequestInterface)shippingAccount.get(firstNodeName));}
            }
        } 

        // Add Address
        List<Cls_Addresses> addrssesShiptoAcc = new List<Cls_Addresses>();
        
        // For Billing
        Cls_Addresses billingAddressShiptoAcc = getAddressNode(sobjShipToAcc,listAFMBillAdd);       
        billingAddressShiptoAcc.translations = new List<Object>();
        // For Shipping
        Cls_Addresses shippingAddressshiptoAcc = new Cls_Addresses();//getAddressNode(sobjShipToAcc,listAFMShipAdd);
        shippingAddressshiptoAcc.translations = new List<Object>();
        /* // IOM-1778 [Only Billing Address to be used]
        if(String.isBlank(shippingAddressshiptoAcc.addressLine1) 
            && String.isBlank(shippingAddressshiptoAcc.city )
            && String.isBlank(shippingAddressshiptoAcc.countryCode)
            && String.isBlank(shippingAddressshiptoAcc.postalCode)
            && String.isBlank(shippingAddressshiptoAcc.stateCode))
        {*/
            shippingAddressshiptoAcc.addressType     =  'Shipping';
            shippingAddressshiptoAcc.addressLine1    =  billingAddressShiptoAcc.addressLine1;
            shippingAddressshiptoAcc.addressLine2    =  billingAddressShiptoAcc.addressLine2;
            shippingAddressshiptoAcc.addressLine3    =  billingAddressShiptoAcc.addressLine3;
            shippingAddressshiptoAcc.city            =  billingAddressShiptoAcc.city;
            shippingAddressshiptoAcc.stateCode       =  billingAddressShiptoAcc.stateCode;
            shippingAddressshiptoAcc.countryCode     =  billingAddressShiptoAcc.countryCode;
            shippingAddressshiptoAcc.postalCode      =  billingAddressShiptoAcc.postalCode;
            shippingAddressshiptoAcc.state      =  billingAddressShiptoAcc.state;
        //}
        
        shippingAccount.put('taxNumberPrefix', '');

        /** Add Translation Records [IE-17] **/
        Boolean hasTranslation = getSObjectValue(sobj,traslatedStatusFieldAPI) == 'Completed'?true:false;

        set<string> accountIMIds = new set<string> {billingAccount.accountId,shippingAccount.accountId};
        String contactId = reqObj.contact.contactId;
        // Create Query
        String queryTransRec = 'SELECT '+ String.escapeSingleQuotes(objectFieldsTranslations) +',Account__r.IM_Account_No__c,Translated_Language__c,Contact__r.IM_Contact_No__c FROM Translated_Record__c WHERE Account__r.IM_Account_No__c IN:accountIMIds OR Contact__r.IM_Contact_No__c =:contactId';
        
        Map<String,List<Translated_Record__c>> translatedRecordsMap = getTrasationRecodsMap(Database.query(queryTransRec));
        
        // if Record translation is avalible for Order [Translation == Complete]
        if(hasTranslation)
        {
            // Add taxCategory for payment Portal            
            string accountTaxCategoryVal = params.objectName == 'blng__Invoice__c' ?((blng__Invoice__c)sobj).blng__Order__r.Account_Tax_Number__r.Tax_Category__c:((blng__CreditNote__c)sobj).blng__RelatedInvoice__r.blng__Order__r.Account_Tax_Number__r.Tax_Category__c;
            billingAccount.put('taxCategory', String.isNotBlank(accountTaxCategoryVal)?accountTaxCategoryVal:'');

            // billingAccount.accountId  - Add Billing Account Traslations
            List<Translated_Record__c> billAccTraslations = translatedRecordsMap.containskey(billingAccount.accountId) ? translatedRecordsMap.get(billingAccount.accountId):new List<Translated_Record__c>();
            billingAccount.translations = getTranslations('Account',billAccTraslations,listAFMTranslatons);
            billingAddressBillingAcc.translations = getTranslations('Address',billAccTraslations,listAFMTranslatons);            
            
			// billingAccount.accountId  - Add Shipping Account Traslations
            shippingAccount.put('taxCategory', String.isNotBlank(accountTaxCategoryVal)?accountTaxCategoryVal:'');
            List<Translated_Record__c> shipAccTraslations = translatedRecordsMap.containskey(billingAccount.accountId) ? translatedRecordsMap.get(billingAccount.accountId):new List<Translated_Record__c>();            
            shippingAccount.translations = getTranslations('Account',shipAccTraslations,listAFMTranslatons);
            billingAddressBillingAcc.translations = getTranslations('Address',shipAccTraslations,listAFMTranslatons);
            
			// reqObj.contact.contactId - Add Contact Traslations
            List<Translated_Record__c> consTraslations = translatedRecordsMap.containskey(reqObj.contact.contactId) ? translatedRecordsMap.get(reqObj.contact.contactId):new List<Translated_Record__c>();
            reqObj.contact.translations = getTranslations('Contact',consTraslations,listAFMTranslatons);
            
            List<String> lsttranslatedLanguages = new List<String>();
            Set<String> translatedLanguages = new Set<String>();

            for (List<Translated_Record__c> records : translatedRecordsMap.values()) {
                for (Translated_Record__c record : records) {
                    translatedLanguages.add(record.Translated_Language__c);
                }
            }
            lsttranslatedLanguages.addAll(translatedLanguages);
            // Add Meta to Header
            if(!lsttranslatedLanguages.isEmpty()){
                reqObj.meta = new Cls_ReqMeta();
            	reqObj.meta.translationLanguages = lsttranslatedLanguages;
            }

            // [GECI-537] - For Translated records SAP requires post code to be in English even for translated value
            if(x3rdPartyERPSystem == 'SAP')
            {
                validateTranslatedAddress(billingAddressBillingAcc.translations,'Blling');//[GECI-1379]
                overRidePostalCode(billingAddressBillingAcc);
            }

            // if(true){throw new APISynchronizationHelper.CustomException('Test exception'); }

            // Add Translated Header/Footers [GECI-283]
            list<SObject> listOjects = new list<SObject>();
            listOjects.add(sobj);
            reqObj.translations = new List<Object>();
            //if( String.isNotBlank(getSObjectValue(sobj,''))){
            reqObj.translations = getTranslations('Document',listOjects,listAFMTranslatons);
            //}
        }
        
        /***** Add Addresses to Accounts*/
        // ------- BILLING -------
        addrssesBillingAcc.add(billingAddressBillingAcc); // Billing Acc Billing Add
        addrssesBillingAcc.add(shippingAddressBillingAcc); // Billing Acc Shipping Add       
        //  Add Address
        billingAccount.addresses = addrssesBillingAcc;

        // ------ SHIPPING -------
        addrssesShiptoAcc.add(billingAddressShiptoAcc);   // Shipping Acc Billing Add  
        addrssesShiptoAcc.add(shippingAddressshiptoAcc);  // Shipping Acc Shipping Add
        // Add Address
        shippingAccount.addresses = addrssesShiptoAcc;

        /**** Add Accounts to Document Nodes ***/
        reqObj.account.add(billingAccount);

        if(billingAccount.accountId != shippingAccount.accountId){
            reqObj.account.add(shippingAccount);
        }

        //*********/ Add Lines to to Document Nodes **********/
        reqObj.documentLines = new List<Cls_DocumentLines>();
        for(SObject line : sobj.getSObjects(params.lineObjectRelationName)){
            Cls_DocumentLines reqLineObj = new Cls_DocumentLines();
            for(API_Field_Mapping__mdt afm : listAFMOI){
                String value = (String.isNotBlank(afm.API_Node_Value__c)?afm.API_Node_Value__c:'');
                if(String.isNotBlank(afm.SObject_Field_Name__c)){
                    //System.debug(LoggingLevel.Debug, afm.SObject_Field_Name__c);
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
                    if(value!=''){setJSONNodeValue(value, nodeName,(OrderHubRequestInterface)reqLineObj.get(firstNodeName));}
                }
            }

            list<Cls_Taxes> listTaxes = new list<Cls_Taxes>();
            Id lineId = (Id)line.get('Id');
            if(taxMap.containsKey(lineId))
            {                
                for(SObject taxLine :taxMap.get(lineId).getSObjects('Tax_Lines__r'))
                {
                    Cls_Taxes taxLineObj = new Cls_Taxes();
                    for(API_Field_Mapping__mdt afm : listAFMTax){
                        String value = (String.isNotBlank(afm.API_Node_Value__c)?afm.API_Node_Value__c:'');
                        if(String.isNotBlank(afm.SObject_Field_Name__c)){
                            //System.debug(LoggingLevel.Debug, afm.SObject_Field_Name__c);
                            String value2 = getSObjectValue(taxLine, afm.SObject_Field_Name__c);
                            value += (value2==null?'':value2);
                        }
                        if(!afm.API_Node_Name__c.contains('.')){
                            if(value!=''){taxLineObj.put(afm.API_Node_Name__c,value);}
                        }
                    }
                    listTaxes.add(taxLineObj);
                }
            }
            reqLineObj.taxes = listTaxes;
            // For Invoice Product Traslation
            if(hasTranslation){
                list<SObject> listOjects = new list<SObject>();
                listOjects.add(line);
                reqLineObj.translations = new List<Object>();
                if( String.isNotBlank(getSObjectValue(line, ProductDescriptionFieldAPI))){
                    reqLineObj.translations = getTranslations('Product',listOjects,listAFMTranslatons);
                }
            }
            // Add/Remove nodes based on Edition Setting [GECI-283]
            if(!editionSetting.OH_ContainsParentProduct__c){
                reqLineObj.parentSumNetValue = null;
                reqLineObj.parentProduct = null;
                reqLineObj.suppressFlag = null;
            }
            if(!editionSetting.OH_LineItemdescription__c){
                reqLineObj.lineItemDescription = null;
                reqLineObj.translations = removeNodeFromTranslation(reqLineObj.translations,'lineItemDescription');
                /*if(reqLineObj.translations !=null && reqLineObj.translations.containsKey('lineItemDescription')){
                    reqLineObj.translations.remove('lineItemDescription');                        
                }*/
            }
            if(!editionSetting.OH_DisplayBillingScheduleNodes__c ){
                reqLineObj.billingScheduleStage = null;
                reqLineObj.billingSchedulePercentage = null;         
            }
            reqObj.documentLines.add(reqLineObj);
        }

        //Set New Nodes based on Edition Settings - [GECI-283]
        if(editionSetting.OH_SalesPersonNameSplit__c && String.isNotBlank(reqObj.salesPersonName))
        {
            reqObj.salesPersonFirstName = reqObj.salesPersonName.contains(' ')?reqObj.salesPersonName.substringBeforeLast(' '):'';
            reqObj.salesPersonLastName = reqObj.salesPersonName.contains(' ')?reqObj.salesPersonName.substringAfterLast(' '):reqObj.salesPersonName;
        }
        if(!editionSetting.OH_Include_Emails__c){
            reqObj.email = null;
        }
        if(!editionSetting.OH_DisplayHeader_Footer__c){
            reqObj.documentHeaderText = null;
            reqObj.documentFooterText = null;
            reqObj.translations = null;
        } 

        //Add bill to contact Id from AccountContactRelation  //[GECI-763]
        String sourceCRM = params.objectName == 'blng__Invoice__c' ? getSObjectValue(sobj,'blng__Order__r.Legacy_CRM_Instance__c') : getSObjectValue(sobj,'blng__RelatedInvoice__r.blng__Order__r.Legacy_CRM_Instance__c');
        reqObj.contact.contactId = MuleSoftCRMCalloutUtils.getAccountContactRelation(getSObjectValue(sobj,'blng__Account__c'),getSObjectValue(sobj,'blng__BillToContact__c'),sourceCRM).IM_Contact_No__c; //[GECI-763]

        //String strJSON = JSON.serialize(reqObj,true).replaceAll(',"currencyReq":"', ',"currency":"');  
        
        list<Cls_Document> listDocuments = new list<Cls_Document>();
        listDocuments.add(reqObj);
        String strJSON = JSON.serialize(listDocuments,true).replaceAll(',"currencyReq":"', ',"currency":"');      
        
        System.debug(LoggingLevel.Debug,'RESPONSE JSON : '+strJSON);
        return strJSON;
    }
    /********** UTILITY METHODS *********/
    /**
    * @description   This method is used to get PaymentSchedule objcet Node
    * @param  listPaymentSchedules list of payment Schedules
    * @param  listAFMAdd list of API_Field_Mapping__mdt
    * @return  List<Cls_Schedule> list of Cls_Schedule Obj
    */
    private static List<Cls_Schedule> getSchNode(list<Payment_Schedule__c> listPaymentSchedules,List<API_Field_Mapping__mdt> listAFMAdd)
    {
        List<Cls_Schedule> paymentSchs = new List<Cls_Schedule>();
        for(Payment_Schedule__c paySc :listPaymentSchedules)
        {
            Cls_Schedule payScObj = new Cls_Schedule();
            for(API_Field_Mapping__mdt afm : listAFMAdd){
                String value = (String.isNotBlank(afm.API_Node_Value__c)?afm.API_Node_Value__c:'');
                if(String.isNotBlank(afm.SObject_Field_Name__c)){                    
                    String value2 = getSObjectValue(paySc, afm.SObject_Field_Name__c);
                    value += (value2==null?'':value2);
                }
                if(!afm.API_Node_Name__c.contains('.')){
                    if(value!=''){payScObj.put(afm.API_Node_Name__c,value);}
                }
            }
            paymentSchs.add(payScObj);
        }
        return paymentSchs;
    }

    /**
    * @description   This method is used to get Address objcet Node
    * @param  sobj SObject
    * @param  listAFMAdd list of API_Field_Mapping__mdt
    * @return  Cls_Addresses Node
    */
    private static Cls_Addresses getAddressNode(SObject sobj,List<API_Field_Mapping__mdt> listAFMAdd)
    {
        Cls_Addresses objAdd = new Cls_Addresses();
        for(API_Field_Mapping__mdt afm : listAFMAdd) // Billing
        {
            String value = (String.isNotBlank(afm.API_Node_Value__c)?afm.API_Node_Value__c:'');
            if(String.isNotBlank(afm.SObject_Field_Name__c)){
                String value2 = getSObjectValue(sobj, afm.SObject_Field_Name__c);
                value += (value2==null?'':value2);
            }
            if(!afm.API_Node_Name__c.contains('.')){
                if(value!=''){objAdd.put(afm.API_Node_Name__c,value);}
            }
        }
        return objAdd;
    }
    /**
    * @description   This method is used to get sboject field value
    * @param  obj SObject
    * @param  fieldName field name
    * @return  SObject field value
    */
    private static string getSObjectValue(SObject obj, String fieldName)
    {
        String value;
        List<String> fieldSplit = fieldName.split('\\.');
        if(1 == fieldSplit.size()){
            if(obj != null && obj.get(fieldSplit[0]) != null){value = String.valueOf(obj.get(fieldSplit[0]));}
        }
        else{
            String firstNodeName = fieldSplit.remove(0);
            String nodeName = String.join(fieldSplit,'.');
            if(obj.getSObject(firstNodeName) != null){value = getSObjectValue(obj.getSObject(firstNodeName),nodeName);}            
        }
        return String.isNotBlank(value)?value:'';
    }

    /**
    * @description   This method is used to set JSON Node value
    * @param  value value
    * @param  nodeName node name
    * @param  otriObj
    */
    private static void setJSONNodeValue(String value, String nodeName, OrderHubRequestInterface otriObj)
    {
        List<String> nodeSplit = nodeName.split('\\.');
        if(1 == nodeSplit.size()){
            if(value != ''){otriObj.put(nodeSplit[0],value);}
        }
        else{
            String firstNodeName = nodeSplit.remove(0);
            String nodeName2 = String.join(nodeSplit,'.');
            setJSONNodeValue(value, nodeName2,(OrderHubRequestInterface)otriObj.get(firstNodeName));
        }
    }

    private static void overRidePostalCode(Cls_Addresses address)
    {
        for(Object tans :address.translations)
        {
            Map<string,object> tanslatonsMap = (Map<string,object>)tans;
            if(tanslatonsMap.containsKey('postalCode'))
            {
                tanslatonsMap.put('postalCode',address.postalCode);
            }
            tans = tanslatonsMap;
        }
    }

    private static string formatJSONDate(string strDate)
    {
        return strDate.replaceAll(' ','T');
    }
    // [GECI-283]
    private static Edition_Setting__mdt getEditionSetting(SObject obj,string objName)
    {
        string key ='';
        if(objName == 'blng__Invoice__c'){
            key = getSObjectValue(obj,'blng__Order__r.Edition__r.Edition_Code__c')+'_'+getSObjectValue(obj,'blng__Order__r.Legacy_CRM_Instance__c');
        }
        else if(objName == 'blng__CreditNote__c'){
            key = getSObjectValue(obj,'blng__RelatedInvoice__r.blng__Order__r.Edition__r.Edition_Code__c')+'_'+getSObjectValue(obj,'blng__RelatedInvoice__r.blng__Order__r.Legacy_CRM_Instance__c');
        }
        // MAP of Edtion Code & Legacy CRM With Edition Settings
        Map<String,Edition_Setting__mdt> mapEditionSt = InvoiceTaxApiSynchronization_Trig.getEditionSettingsMapOnEditionCodeLegacyCRM();
        
        return mapEditionSt.containsKey(key)?mapEditionSt.get(key): new Edition_Setting__mdt();
    }
    /******************************* After Amendment Data JSON ****************************/
    /**
    * @description   This method is used to get After Amendment Oracle Payload
    * @param  apiSyncObj API_Synchronization_Item
    * @return json string
    
    public static String getAfterAmendmentOraclePayload(API_Synchronization_Item__c apiSyncObj)
    {        
        String payloadString='';

        String ordFields = 'Id,';

        String oppFields = 'Opportunity.PO_Number__c,Opportunity.Legacy_CRM_Instance__c,';

        String otherFields = 'Legal_Entity__r.Legal_Entity_Code__c,Edition__r.X3rd_Party_ERP_System__c,Account_Tax_Number__r.Tax_ID__c,Account_Tax_Number__r.Tax_Category__c,';
        String contactFields = 'BillToContact.IM_Contact_No__c,BillToContact.Email,BillToContact.FirstName,BillToContact.LastName,BillToContact.MobilePhone,BillToContact.Salutation,BillToContact.Title,';

        String accountFields = 'Ship_To_Account__r.Billing_Address_Line_3__c,Ship_To_Account__r.Billing_Address_Line_2__c,blng__BillingAccount__r.Billing_Address_Line_2__c,blng__BillingAccount__r.Billing_Address_Line_3__c,blng__BillingAccount__r.IM_Account_No__c,Ship_To_Account__r.Oracle_Number__c,Ship_To_Account__r.SAP_Number__c,blng__BillingAccount__r.Oracle_Number__c,blng__BillingAccount__r.SAP_Number__c,blng__BillingAccount__r.Name,blng__BillingAccount__r.BillingStreet,blng__BillingAccount__r.BillingCity,blng__BillingAccount__r.BillingStateCode,blng__BillingAccount__r.BillingCountryCode,blng__BillingAccount__r.BillingPostalCode,blng__BillingAccount__r.BillingState,blng__BillingAccount__r.ShippingStreet,blng__BillingAccount__r.ShippingCity,blng__BillingAccount__r.ShippingStateCode,blng__BillingAccount__r.ShippingCountryCode,blng__BillingAccount__r.ShippingPostalCode,blng__BillingAccount__r.ShippingState,blng__BillingAccount__r.Customer_Type__c,Ship_To_Account__r.IM_Account_No__c,Ship_To_Account__r.Name,Ship_To_Account__r.BillingStreet,Ship_To_Account__r.BillingCity,Ship_To_Account__r.BillingStateCode,Ship_To_Account__r.BillingCountryCode,Ship_To_Account__r.BillingPostalCode,Ship_To_Account__r.BillingState,Ship_To_Account__r.ShippingStreet,Ship_To_Account__r.ShippingCity,Ship_To_Account__r.ShippingStateCode,Ship_To_Account__r.ShippingCountryCode,Ship_To_Account__r.ShippingPostalCode,Ship_To_Account__r.ShippingState,Ship_To_Account__r.Customer_Type__c';

        String queryStr = 'Select '+ordFields+oppFields+otherFields+contactFields+accountFields+' From Order  WHERE OpportunityId = \''+apiSyncObj.Amendment_Request__r.Opportunity__c+'\' AND Status= \'Activated\' ORDER BY CreatedDate desc LIMIT 1';
        Order odr = Database.query(queryStr);
        
        String[] erpRefNos = String.isNotBlank(apiSyncObj.Amendment_Request__r.ERP_Ref_Numbers__c)?apiSyncObj.Amendment_Request__r.ERP_Ref_Numbers__c.Split(','):new List<String>();
		//GECI-1894
		Map<Id,Translated_Record__c> maplatestTranslatedRecord =  MuleSoftCRMCalloutUtils.getTranslatedRecordMap(new Set<Id>{odr.blng__BillingAccount__c,odr.Ship_To_Account__c,odr.BillToContactId});

        switch on apiSyncObj.Type__c {
            when 'Re-Print for PO number change' {
                Cls_PoNumberDoc poNumObj    = new Cls_PoNumberDoc();
                poNumObj.poNumber           = odr.Opportunity.PO_Number__c;
                poNumObj.erpDocumentNumber  = erpRefNos;
                poNumObj.sourceSystem       = 'IOM';
                poNumObj.legalEntity        = odr.Legal_Entity__r.Legal_Entity_Code__c;
                poNumObj.reprintFlag        = 'Y';

                payloadString =    JSON.serialize(poNumObj,false);
            }
            when 'Re-Print for Contact Details Change' {
                Cls_ContactDoc conObj = new Cls_ContactDoc();
                conObj.erpAccountNumber = odr.Edition__r.X3rd_Party_ERP_System__c == 'SAP' ? odr.blng__BillingAccount__r.SAP_Number__c : odr.blng__BillingAccount__r.Oracle_Number__c;
                conObj.IOMAccountNumber = odr.blng__BillingAccount__r.IM_Account_No__c;
                conObj.legalEntity  = odr.Legal_Entity__r.Legal_Entity_Code__c;   
                conObj.reprintFlag  = 'Y';
                conObj.contactId    = odr.BillToContact.IM_Contact_No__c;
                conObj.contactStatus  = 'Active';                
                conObj.emailAddress = odr.BillToContact.Email;
                conObj.firstName    = odr.BillToContact.FirstName;
                conObj.lastName     = odr.BillToContact.LastName;
                conObj.phone        = odr.BillToContact.MobilePhone;
                conObj.salutation   = odr.BillToContact.Salutation;
                conObj.title        = odr.BillToContact.Title;
                conObj.erpDocumentNumber  = erpRefNos; 
                conObj.translations = new List<Object>();

                payloadString =    JSON.serialize(conObj,false);
            }
            when 'Re-Print for Bill To Account Details Change','Re-Print for Account Details Change' {
                Cls_AccountRefNo accRef = new Cls_AccountRefNo();
                accRef.account_type     =   'BILL_TO';
                accRef.account_number   =  odr.Edition__r.X3rd_Party_ERP_System__c == 'SAP' ? odr.blng__BillingAccount__r.SAP_Number__c : odr.blng__BillingAccount__r.Oracle_Number__c;

                Cls_AccountDoc accObj   = new Cls_AccountDoc();
                accObj.legalEntity      = odr.Legal_Entity__r.Legal_Entity_Code__c;    
                accObj.reprintFlag      = 'Y';
                accObj.erpDocumentNumber = erpRefNos;
                accObj.erpAccountIds     = new List<Cls_AccountRefNo>();
                accObj.accountId        = odr.blng__BillingAccount__r.IM_Account_No__c;
                accObj.name             = odr.blng__BillingAccount__r.Name;
                accObj.accountType      = odr.blng__BillingAccount__r.Customer_Type__c;
                accObj.accountStatus    = 'ACTIVE';
                accObj.taxCategory      = odr.Account_Tax_Number__r.Tax_Category__c; 
                accObj.taxNumber        = odr.Account_Tax_Number__r.Tax_ID__c; // [GECI-110]
                accObj.addresses        = new List<Cls_Addresses>();
				accObj.translations = new List<Object>();
                accObj.erpAccountIds.add(accRef);
                // For Address
				Map<String,String> accChangeJSONMap = new Map<String,String>();
                if(maplatestTranslatedRecord.containsKey(odr.blng__BillingAccount__c)){                    
                    Translated_Record__c billToTras = maplatestTranslatedRecord.get(odr.blng__BillingAccount__c);
                    accChangeJSONMap.put('name',billToTras.Translated_Account_Name__c);
                    accChangeJSONMap.put('languageTag',billToTras.Translated_Language__c);
                    accObj.translations.add(accChangeJSONMap);

                    accObj.meta = new Cls_ReqMeta(); 
                    accObj.meta.translationLanguages = new list<String>{billToTras.Translated_Language__c};
                }
                
                // For Billing
                Cls_Addresses billingAddress = new Cls_Addresses();
                billingAddress.addressLine1 =  odr.blng__BillingAccount__r.BillingStreet;
                billingAddress.addressLine2 = odr.blng__BillingAccount__r.Billing_Address_Line_2__c;
                billingAddress.addressLine3 = odr.blng__BillingAccount__r.Billing_Address_Line_3__c;
                billingAddress.city         =  odr.blng__BillingAccount__r.BillingCity;
                billingAddress.stateCode    =  odr.blng__BillingAccount__r.BillingStateCode;
                billingAddress.countryCode  =  odr.blng__BillingAccount__r.BillingCountryCode;
                billingAddress.postalCode   =  odr.blng__BillingAccount__r.BillingPostalCode;
                billingAddress.state        =  odr.blng__BillingAccount__r.BillingState;
                billingAddress.addressType  = 'Billing';
				billingAddress.translations = new List<Object>();
                accObj.addresses.add(billingAddress);

                // For Shipping
                Cls_Addresses shippingAddres = new Cls_Addresses();
                shippingAddres.addressType  = 'Shipping';                
                shippingAddres.addressLine1 =  billingAddress.addressLine1;
                shippingAddres.addressLine2 =  billingAddress.addressLine2;
                shippingAddres.addressLine3 =  billingAddress.addressLine3;
                shippingAddres.city         =  billingAddress.city;
                shippingAddres.stateCode    =  billingAddress.stateCode;
                shippingAddres.countryCode  =  billingAddress.countryCode;
                shippingAddres.postalCode   =  billingAddress.postalCode;
                shippingAddres.state        =  billingAddress.state;
				shippingAddres.translations = new List<Object>();
                accObj.addresses.add(shippingAddres);
				
                // For Translations
                 Map<String,String> transAddJSONMap = new Map<String,String>();
                if(maplatestTranslatedRecord.containsKey(odr.blng__BillingAccount__c)){
					
                    Translated_Record__c billToTras = maplatestTranslatedRecord.get(odr.blng__BillingAccount__c);
                    transAddJSONMap.put('addressLine1',billToTras.Translated_Billing_Address_Line_1__c);
                    transAddJSONMap.put('addressLine2',billToTras.Translated_Billing_Address_Line_2__c);
                    transAddJSONMap.put('addressLine3',billToTras.Translated_Billing_Address_Line_3__c);
                    transAddJSONMap.put('city',billToTras.Translated_Billing_City__c);
                    transAddJSONMap.put('stateCode',billingAddress.stateCode);
                    transAddJSONMap.put('countryCode',billingAddress.countryCode);
                    transAddJSONMap.put('postalCode',billingAddress.postalCode);
                     
                    billingAddress.translations.add(transAddJSONMap);
                    shippingAddres.translations.add(transAddJSONMap);
                }                                
                payloadString =    JSON.serialize(accObj,false);                
            }
            when 'Re-Print for Ship To Account Details Change' {
                Cls_AccountRefNo accRef = new Cls_AccountRefNo();
                accRef.account_type     =   'SHIP_TO';
                accRef.account_number   =   odr.Edition__r.X3rd_Party_ERP_System__c == 'SAP' ? odr.Ship_To_Account__r.SAP_Number__c : odr.Ship_To_Account__r.Oracle_Number__c;

                Cls_AccountDoc accObj   = new Cls_AccountDoc();
                accObj.legalEntity      = odr.Legal_Entity__r.Legal_Entity_Code__c; 
                accObj.reprintFlag      = 'Y';
                accObj.erpDocumentNumber = erpRefNos;
                accObj.erpAccountIds     = new List<Cls_AccountRefNo>();
                accObj.accountId        = odr.Ship_To_Account__r.IM_Account_No__c;
                accObj.name         = odr.Ship_To_Account__r.Name;
                accObj.accountType  = odr.Ship_To_Account__r.Customer_Type__c;
                accObj.accountStatus = 'ACTIVE';    
                accObj.addresses    = new List<Cls_Addresses>();
				accObj.translations = new List<Object>();
                accObj.erpAccountIds.add(accRef);
                // For Address
				Map<String,String> accChangeJSONMap = new Map<String,String>();
                if(maplatestTranslatedRecord.containsKey(odr.Ship_To_Account__c)){                
                    Translated_Record__c shipToTras = maplatestTranslatedRecord.get(odr.Ship_To_Account__c);
                    accChangeJSONMap.put('name',shipToTras.Translated_Account_Name__c);
                    accChangeJSONMap.put('languageTag',shipToTras.Translated_Language__c);
                    accObj.translations.add(accChangeJSONMap);

                    accObj.meta = new Cls_ReqMeta(); 
                    accObj.meta.translationLanguages = new list<String>{shipToTras.Translated_Language__c};
                }
                 
                // For Billing
                Cls_Addresses billingAddress = new Cls_Addresses();        
                billingAddress.addressLine1 =  odr.Ship_To_Account__r.BillingStreet;
                billingAddress.addressLine2 =  odr.Ship_To_Account__r.Billing_Address_Line_2__c;
                billingAddress.addressLine3 =  odr.Ship_To_Account__r.Billing_Address_Line_3__c;
                billingAddress.city         =  odr.Ship_To_Account__r.BillingCity;
                billingAddress.stateCode    =  odr.Ship_To_Account__r.BillingStateCode;
                billingAddress.countryCode  =  odr.Ship_To_Account__r.BillingCountryCode;
                billingAddress.postalCode   =  odr.Ship_To_Account__r.BillingPostalCode;
                billingAddress.state        =  odr.Ship_To_Account__r.BillingState;
                billingAddress.addressType  = 'Billing';
				billingAddress.translations = new List<Object>();
                accObj.addresses.add(billingAddress);

                // For Shipping
                Cls_Addresses shippingAddres = new Cls_Addresses();
                shippingAddres.addressType  = 'Shipping';
                shippingAddres.addressLine1 =  billingAddress.addressLine1;
                shippingAddres.addressLine2 =  billingAddress.addressLine2;
                shippingAddres.addressLine3 =  billingAddress.addressLine3;
                shippingAddres.city         =  billingAddress.city;
                shippingAddres.stateCode    =  billingAddress.stateCode;
                shippingAddres.countryCode  =  billingAddress.countryCode;
                shippingAddres.postalCode   =  billingAddress.postalCode;
                shippingAddres.state        =  billingAddress.state;
				shippingAddres.translations = new List<Object>();   
                Map<String,String> transAddJSONMap = new Map<String,String>();
                if(maplatestTranslatedRecord.containsKey(odr.blng__BillingAccount__c)){
                    Translated_Record__c billToTras = maplatestTranslatedRecord.get(odr.blng__BillingAccount__c);
                    transAddJSONMap.put('addressLine1',billToTras.Translated_Billing_Address_Line_1__c);
                    transAddJSONMap.put('addressLine2',billToTras.Translated_Billing_Address_Line_2__c);
                    transAddJSONMap.put('addressLine3',billToTras.Translated_Billing_Address_Line_3__c);
                    transAddJSONMap.put('city',billToTras.Translated_Billing_City__c);
                    transAddJSONMap.put('stateCode',billingAddress.stateCode);
                    transAddJSONMap.put('countryCode',billingAddress.countryCode);
                    transAddJSONMap.put('postalCode',billingAddress.postalCode);
                    billingAddress.translations.add(transAddJSONMap);
                    shippingAddres.translations.add(transAddJSONMap);
                }
                accObj.addresses.add(shippingAddres);
                payloadString =    JSON.serialize(accObj,false);
            }
        }

        return payloadString.replaceAll(':null',':""').replaceAll('"translations":"",','').replaceAll(',"translations":""','').replaceAll('"meta":"",','');
    }*/
	

    /******************************* Translations JSON ****************************/
    /**
    * @description  : This method is used to get Translation Records JSON Payload
    * @param  type  Filter Type
    * @param  translationRecords Records Holding the translations
    * @param  listFieldMappins List of API Field Mapping
    * @return json string
    */
    public static List<Object> getTranslations(String type,List<sObject> translationRecords,List<API_Field_Mapping__mdt> listAFM)
    {
        List<Object> translationRecordsList = new List <Object>();
        for(sObject obj:translationRecords)
        {            
            Map<String,String> jsonMAP = new Map<String,String>();
            for(API_Field_Mapping__mdt afm : listAFM)
            {
                if(afm.Custom_Node__c.substringAfter('.') == type)
                {
                    String value = (String.isNotBlank(afm.API_Node_Value__c)?afm.API_Node_Value__c:'');
                    if(String.isNotBlank(afm.SObject_Field_Name__c)){                    
                        String value2 = getSObjectValue(obj, afm.SObject_Field_Name__c);
                        value += String.isBlank(value2)?'':value2;
                    }
                    if(!afm.API_Node_Name__c.contains('.')){
                        jsonMAP.put(afm.API_Node_Name__c,value);
                    }
                }
            }
            if(!jsonMAP.isEmpty()){translationRecordsList.add(jsonMAP);}            
        }
        return translationRecordsList;
    }
    /**
    * @description   This method is used to get Translation Key Map
    * @param traslationRecords Translated_Records    
    * @return json string
    */
    private static Map<String,List<Translated_Record__c>> getTrasationRecodsMap(List<Translated_Record__c> traslationRecords)
    {
        Map<String,List<Translated_Record__c>> translatedRecordsMap = new Map<String,List<Translated_Record__c>> ();
        for(Translated_Record__c tr:traslationRecords)
        {
            // For Account
            string accKey = tr.Account__r.IM_Account_No__c ; //for Mutil -Lang add LANG
            if(String.isNotBlank(accKey))
            {
                List<Translated_Record__c> accTRList = translatedRecordsMap.containskey(accKey)?translatedRecordsMap.get(accKey): new List<Translated_Record__c>();
                accTRList.add(tr);
                translatedRecordsMap.put(accKey,accTRList);
            }
            
            // For Contact
            string conKey = tr.Contact__r.IM_Contact_No__c ; //for Mutil -Lang add LANG
            if(String.isNotBlank(conKey))
            {
                List<Translated_Record__c> conTRList = translatedRecordsMap.containskey(conKey)?translatedRecordsMap.get(conKey): new List<Translated_Record__c>();
                conTRList.add(tr);
                translatedRecordsMap.put(conKey,conTRList);    
            }        
        }
        return translatedRecordsMap;
    }

    private Static List<Object> removeNodeFromTranslation(List<Object> tnasObj,string nodeName)
    {
        List<Object> translationRecordsList = new List <Object>();
        if(tnasObj !=null && !tnasObj.isEmpty()){
            for(object obj:tnasObj)
            {
                Map<String,object> jsonMAP = (Map<String,object>)obj;
                if(jsonMAP.containsKey(nodeName)){jsonMAP.remove(nodeName);}
                translationRecordsList.add(jsonMAP);
            }
        }else{translationRecordsList = tnasObj;}
        return translationRecordsList;
    }

    private Static void validateTranslatedAddress(List<Object> tnasObj,string type)
    {
        List<Object> translationRecordsList = new List <Object>();
        if(tnasObj !=null && !tnasObj.isEmpty()){
            for(object obj:tnasObj)
            {
                Map<String,object> jsonMAP = (Map<String,object>)obj;
                if(!jsonMAP.containsKey('addressLine1') || 
                    !jsonMAP.containsKey('city') ||
                    (jsonMAP.containsKey('addressLine1') && String.isBlank((String)jsonMAP.get('addressLine1'))) ||
                    (jsonMAP.containsKey('city') && String.isBlank((String)jsonMAP.get('city'))) ) 
                {throw new APISynchronizationHelper.CustomException('The Translated record for the account is missing mandatory values for Address Line 1 & City');}               
            }
        }
    }
    /******************************* Payment Transactions JSON ****************************/
    /**
    * @description   This method is used to get Payment Transactions JSON Payload
    * @param  apiSyncObj API_Synchronization_Item
    * @return json string
    */
    public static String getPaymentTransactionsPayload(Id invId,string paymentType)
    { 
        List<PaymentTransaction> listPaymentTrans = new List<PaymentTransaction>();
        String nameFieldAPI = 'Invoice__r.'+(!Test.isRunningTest()?GlobalConstants.getValue(FILTER_FIELD_API_METANAME):'Name');

        string queryString = 'SELECT Id,Amount__c,Invoice__c,'+String.escapeSingleQuotes(nameFieldAPI)+',Authorization_Date__c,Card_Type__c,CurrencyIsoCode,Gateway_Account_ID__c,Gateway_ID__c,Gateway_Reference_ID__c,Payment_Method__c,Payment_Status__c,Payment_Type__c,Source_Payment_ID__c FROM Payment_Transaction__c WHERE Invoice__c = \''+invId +'\' AND Payment_Type__c = \''+String.escapeSingleQuotes(paymentType)+'\' AND ERP_Sync_Status__c = \''+String.escapeSingleQuotes(ERP_SYNC_STATUS)+'\'' ;
        system.debug('QUERY: '+queryString);
        for(Payment_Transaction__c payTrs : Database.query(queryString))
        {
            PaymentTransaction payTrsObj = new PaymentTransaction();
            payTrsObj.documentId    = getSObjectValue(payTrs,nameFieldAPI);
            payTrsObj.sourceSystem  = 'IOM';
            payTrsObj.amount        = payTrs.Amount__c;
            payTrsObj.cardType      = payTrs.Card_Type__c;
            payTrsObj.strCurrency   = payTrs.CurrencyIsoCode;
            payTrsObj.gateway_id    = payTrs.Gateway_ID__c;
            payTrsObj.paymentMethod = payTrs.Payment_Method__c;
            payTrsObj.paymentStatus = payTrs.Payment_Status__c;
            payTrsObj.paymentType   = payTrs.Payment_Type__c;
            payTrsObj.paymentId     = payTrs.Source_Payment_ID__c;
            payTrsObj.gatewayAccountId  = payTrs.Gateway_Account_ID__c;
            payTrsObj.gatewayReference  = payTrs.Gateway_Reference_ID__c;
            payTrsObj.authorisationDatetime   = payTrs.Authorization_Date__c != null ? formatJSONDate(String.valueOf(payTrs.Authorization_Date__c)):'' ;
                        
            listPaymentTrans.add(payTrsObj);
        }
        return JSON.serialize(listPaymentTrans).replaceAll('"strCurrency":"', '"currency":"').replaceAll(':null',':""');
    }

    /************************************ Parametrs Wrapper Class *************************/

    /** @description : wrapper class to create parametrs*/
    public class WrapperParametrs
    {
        public String objectName;
        public String lineObjectName;
        public String lineObjectRelationName;
        public String taxCallTypename;
        public String thirdPartyName = 'Oracle';
        public String jsonTypeName = 'Request';
        public Map<String,Map<String,List<API_Field_Mapping__mdt>>> mapObjectApiNameAndListAFM = new Map<String,Map<String,List<API_Field_Mapping__mdt>>>();
    }


    /******************************* New After Amendment Data JSON ************************ [GECI-916]****/
    /**
    * @description   This method is used to get After Amendment Oracle Payload
    * @param  apiSyncObj API_Synchronization_Item
    * @return json string
    */
    
    public static String getAfterAmendmentOraclePayload(API_Synchronization_Item__c apiSyncObj)
    {        
        List<String> amedmentTypes = apiSyncObj.Amendment_Request__r.Amendment_Type__c.split(';');

        String payloadString='';

        String ordFields = 'Id,';

        String oppFields = 'Opportunity.PO_Number__c,Opportunity.Legacy_CRM_Instance__c,';

        String otherFields = 'Legal_Entity__r.Legal_Entity_Code__c,Edition__r.X3rd_Party_ERP_System__c,Account_Tax_Number__r.Tax_ID__c,Account_Tax_Number__r.Tax_Category__c,';
        String contactFields = 'BillToContactId,BillToContact.IM_Contact_No__c,BillToContact.Email,BillToContact.FirstName,BillToContact.LastName,BillToContact.MobilePhone,BillToContact.Salutation,BillToContact.Title,';

        String accountFields = 'blng__BillingAccount__c,blng__BillingAccount__r.Billing_Address_Line_2__c,blng__BillingAccount__r.Billing_Address_Line_3__c,blng__BillingAccount__r.IM_Account_No__c,blng__BillingAccount__r.Oracle_Number__c,blng__BillingAccount__r.SAP_Number__c,blng__BillingAccount__r.Name,blng__BillingAccount__r.BillingStreet,blng__BillingAccount__r.BillingCity,blng__BillingAccount__r.BillingStateCode,blng__BillingAccount__r.BillingCountryCode,blng__BillingAccount__r.BillingPostalCode,blng__BillingAccount__r.BillingState,blng__BillingAccount__r.ShippingStreet,blng__BillingAccount__r.ShippingCity,blng__BillingAccount__r.ShippingStateCode,blng__BillingAccount__r.ShippingCountryCode,blng__BillingAccount__r.ShippingPostalCode,blng__BillingAccount__r.ShippingState,blng__BillingAccount__r.Customer_Type__c,Ship_To_Account__c,Ship_To_Account__r.IM_Account_No__c,Ship_To_Account__r.Name,Ship_To_Account__r.BillingStreet,Ship_To_Account__r.BillingCity,Ship_To_Account__r.BillingStateCode,Ship_To_Account__r.BillingCountryCode,Ship_To_Account__r.BillingPostalCode,Ship_To_Account__r.BillingState,Ship_To_Account__r.ShippingStreet,Ship_To_Account__r.ShippingCity,Ship_To_Account__r.ShippingStateCode,Ship_To_Account__r.ShippingCountryCode,Ship_To_Account__r.ShippingPostalCode,Ship_To_Account__r.ShippingState,Ship_To_Account__r.Customer_Type__c,Ship_To_Account__r.Oracle_Number__c,Ship_To_Account__r.SAP_Number__c,Ship_To_Account__r.Billing_Address_Line_3__c,Ship_To_Account__r.Billing_Address_Line_2__c';

        String queryStr = 'Select '+ordFields+oppFields+otherFields+contactFields+accountFields+' From Order  WHERE OpportunityId = \''+apiSyncObj.Amendment_Request__r.Opportunity__c+'\' AND Status= \'Activated\' ORDER BY CreatedDate desc LIMIT 1';
        Order odr = Database.query(queryStr);
        
        String[] erpRefNos = String.isNotBlank(apiSyncObj.Amendment_Request__r.ERP_Ref_Numbers__c)?apiSyncObj.Amendment_Request__r.ERP_Ref_Numbers__c.Split(','):new List<String>();
        Map<Id,Translated_Record__c> maplatestTranslatedRecord =  MuleSoftCRMCalloutUtils.getTranslatedRecordMap(new Set<Id>{odr.blng__BillingAccount__c,odr.Ship_To_Account__c,odr.BillToContactId});

        Cls_Amendment amendmentObj = new Cls_Amendment(); 
        amendmentObj.sourceSystem = 'IOM';
        amendmentObj.legalEntity = odr.Legal_Entity__r.Legal_Entity_Code__c;
        amendmentObj.erpDocumentNumber  = erpRefNos;
        amendmentObj.reprintFlag  = 'Y';

        set<string> otherTraslatedlangs = new set<string>();
        if(amedmentTypes.contains('PO number change'))
        {
            amendmentObj.document = new Cls_AmendDocument ();
            amendmentObj.document.poNumber   = odr.Opportunity.PO_Number__c;
        }

        if(amedmentTypes.contains('Bill to Contact Details Change') || amedmentTypes.contains('Update Bill To Contact'))
       {
            amendmentObj.contact = new Cls_AmendContact ();
            // amendmentObj.contact.contactId    = odr.BillToContact.IM_Contact_No__c;
            amendmentObj.contact.contactId    = MuleSoftCRMCalloutUtils.getAccountContactRelation(odr.blng__BillingAccount__c,odr.BillToContactId,odr.Opportunity.Legacy_CRM_Instance__c).IM_Contact_No__c;
            amendmentObj.contact.erpAccountNumber = odr.Edition__r.X3rd_Party_ERP_System__c == 'SAP' ? odr.blng__BillingAccount__r.SAP_Number__c : odr.blng__BillingAccount__r.Oracle_Number__c;
            amendmentObj.contact.IOMAccountNumber = odr.blng__BillingAccount__r.IM_Account_No__c;
            amendmentObj.contact.contactStatus  = 'Active';                
            amendmentObj.contact.emailAddress = odr.BillToContact.Email;
            amendmentObj.contact.firstName    = odr.BillToContact.FirstName;
            amendmentObj.contact.lastName     = odr.BillToContact.LastName;
            amendmentObj.contact.phone        = odr.BillToContact.MobilePhone;
            amendmentObj.contact.salutation   = odr.BillToContact.Salutation;
            amendmentObj.contact.title        = odr.BillToContact.Title;

            // Traslations
            // if(maplatestTranslatedRecord.containsKey(odr.BillToContactId))
            // {
            //     Translated_Record__c conTras = maplatestTranslatedRecord.get(odr.BillToContactId);
            //     Map<String,String> transConJSONMap = new Map<String,String>();
            //     amendmentObj.contact.translations = new List<Object>();
            //     otherTraslatedlangs.add(conTras.Translated_Language__c);

            //     transConJSONMap.put('lastName',conTras.Translated_Contact_LastName__c);
            //     transConJSONMap.put('firstName',conTras.Translated_Contact_LastName__c);
            //     transConJSONMap.put('salutation',conTras.Translated_Contact_Salutation__c);

            //     amendmentObj.contact.translations.add(transConJSONMap);
            // }
        }

        if(amedmentTypes.contains('Account Name Change') || amedmentTypes.contains('Bill To Account Change') ||
           amedmentTypes.contains('Billing Address Change') || amedmentTypes.contains('VAT Registration Number Change') )
       {            
            Cls_AccountRefNo accRef = new Cls_AccountRefNo();
            accRef.account_type     =   'BILL_TO';
            accRef.account_number   =  odr.Edition__r.X3rd_Party_ERP_System__c == 'SAP' ? odr.blng__BillingAccount__r.SAP_Number__c : odr.blng__BillingAccount__r.Oracle_Number__c;

            Cls_AmendAccount billToAccObj = new Cls_AmendAccount();
            
            billToAccObj.accountId        = odr.blng__BillingAccount__r.IM_Account_No__c;
            billToAccObj.name             = odr.blng__BillingAccount__r.Name;
            billToAccObj.accountType      = odr.blng__BillingAccount__r.Customer_Type__c;
            billToAccObj.accountStatus    = 'ACTIVE';
            billToAccObj.taxCategory      = odr.Account_Tax_Number__r.Tax_Category__c; 
            billToAccObj.taxNumber        = odr.Account_Tax_Number__r.Tax_ID__c; // [GECI-110]
            billToAccObj.addresses        = new List<Cls_Addresses>();

            billToAccObj.erpAccountIds     = new List<Cls_AccountRefNo>();
            billToAccObj.erpAccountIds.add(accRef);
            
            // -----For Address----
            // For Billing
            Cls_Addresses billingAddress = new Cls_Addresses();
            billingAddress.addressLine1 =  odr.blng__BillingAccount__r.BillingStreet;
            billingAddress.addressLine2 = odr.blng__BillingAccount__r.Billing_Address_Line_2__c;
            billingAddress.addressLine3 = odr.blng__BillingAccount__r.Billing_Address_Line_3__c;
            billingAddress.city         =  odr.blng__BillingAccount__r.BillingCity;
            billingAddress.stateCode    =  odr.blng__BillingAccount__r.BillingStateCode;
            billingAddress.countryCode  =  odr.blng__BillingAccount__r.BillingCountryCode;
            billingAddress.postalCode   =  odr.blng__BillingAccount__r.BillingPostalCode;
            billingAddress.state        =  odr.blng__BillingAccount__r.BillingState;
            billingAddress.addressType  = 'Billing';            

            // For Shipping
            Cls_Addresses shippingAddres = new Cls_Addresses();
            shippingAddres.addressType  = 'Shipping';
            shippingAddres.addressLine1 =  billingAddress.addressLine1;
            shippingAddres.addressLine2 =  billingAddress.addressLine2;
            shippingAddres.addressLine3 =  billingAddress.addressLine3;
            shippingAddres.city         =  billingAddress.city;
            shippingAddres.stateCode    =  billingAddress.stateCode;
            shippingAddres.countryCode  =  billingAddress.countryCode;
            shippingAddres.postalCode   =  billingAddress.postalCode;
            shippingAddres.state        =  billingAddress.state;
            
            // Traslations
            if(maplatestTranslatedRecord.containsKey(odr.blng__BillingAccount__c))
            {
                Translated_Record__c billToTras = maplatestTranslatedRecord.get(odr.blng__BillingAccount__c);
                Map<String,String> transAccJSONMap = new Map<String,String>();
                billToAccObj.translations = new List<Object>();
                otherTraslatedlangs.add(billToTras.Translated_Language__c);

                transAccJSONMap.put('name',billToTras.Translated_Account_Name__c);

                billToAccObj.translations.add(transAccJSONMap);

                //for Address
                Map<String,String> transAddJSONMap = new Map<String,String>();
                billingAddress.translations = new List<Object>();
                shippingAddres.translations = new List<Object>();

                transAddJSONMap.put('addressLine1',billToTras.Translated_Billing_Address_Line_1__c);
                transAddJSONMap.put('addressLine2',billToTras.Translated_Billing_Address_Line_2__c);
                transAddJSONMap.put('addressLine3',billToTras.Translated_Billing_Address_Line_3__c);
                transAddJSONMap.put('city',billToTras.Translated_Billing_City__c);

                billingAddress.translations.add(transAddJSONMap);
                shippingAddres.translations.add(transAddJSONMap);
            }

            billToAccObj.addresses.add(billingAddress);
            billToAccObj.addresses.add(shippingAddres);
            amendmentObj.account =billToAccObj;
        }
        if(amedmentTypes.contains('Ship To Account Change') || amedmentTypes.contains('Shipping Address Change'))
        {
            Cls_AccountRefNo accRef = new Cls_AccountRefNo();
            accRef.account_type     =   'SHIP_TO';
            accRef.account_number   =   odr.Edition__r.X3rd_Party_ERP_System__c == 'SAP' ? odr.Ship_To_Account__r.SAP_Number__c : odr.Ship_To_Account__r.Oracle_Number__c;

            Cls_AmendAccount shipToAccObj = new Cls_AmendAccount();                
            shipToAccObj.accountId        = odr.Ship_To_Account__r.IM_Account_No__c;
            shipToAccObj.name         = odr.Ship_To_Account__r.Name;
            shipToAccObj.accountType  = odr.Ship_To_Account__r.Customer_Type__c;
            shipToAccObj.accountStatus = 'ACTIVE';    
            shipToAccObj.addresses    = new List<Cls_Addresses>();

            shipToAccObj.erpAccountIds     = new List<Cls_AccountRefNo>();
            shipToAccObj.erpAccountIds.add(accRef);

            // ----For Address-----
            // For Billing
            Cls_Addresses billingAddress = new Cls_Addresses();        
            billingAddress.addressLine1 =  odr.Ship_To_Account__r.BillingStreet;
            billingAddress.addressLine2 =  odr.Ship_To_Account__r.Billing_Address_Line_2__c;
            billingAddress.addressLine3 =  odr.Ship_To_Account__r.Billing_Address_Line_3__c;
            billingAddress.city         =  odr.Ship_To_Account__r.BillingCity;
            billingAddress.stateCode    =  odr.Ship_To_Account__r.BillingStateCode;
            billingAddress.countryCode  =  odr.Ship_To_Account__r.BillingCountryCode;
            billingAddress.postalCode   =  odr.Ship_To_Account__r.BillingPostalCode;
            billingAddress.state        =  odr.Ship_To_Account__r.BillingState;
            billingAddress.addressType  = 'Billing';
            
            // For Shipping
            Cls_Addresses shippingAddres = new Cls_Addresses();
            shippingAddres.addressType  = 'Shipping';
            shippingAddres.addressLine1 =  billingAddress.addressLine1;
            shippingAddres.addressLine2 =  billingAddress.addressLine2;
            shippingAddres.addressLine3 =  billingAddress.addressLine3;
            shippingAddres.city         =  billingAddress.city;
            shippingAddres.stateCode    =  billingAddress.stateCode;
            shippingAddres.countryCode  =  billingAddress.countryCode;
            shippingAddres.postalCode   =  billingAddress.postalCode;
            shippingAddres.state        =  billingAddress.state;
            
            // Traslations
            if(maplatestTranslatedRecord.containsKey(odr.Ship_To_Account__c))
            {
                Translated_Record__c shipToTras = maplatestTranslatedRecord.get(odr.Ship_To_Account__c);
                Map<String,String> transAccJSONMap = new Map<String,String>();
                shipToAccObj.translations = new List<Object>();
                otherTraslatedlangs.add(shipToTras.Translated_Language__c);

                transAccJSONMap.put('name',shipToTras.Translated_Account_Name__c);

                shipToAccObj.translations.add(transAccJSONMap);

                //for Address
                Map<String,String> transAddJSONMap = new Map<String,String>();
                billingAddress.translations = new List<Object>();
                shippingAddres.translations = new List<Object>();

                transAddJSONMap.put('addressLine1',shipToTras.Translated_Billing_Address_Line_1__c);
                transAddJSONMap.put('addressLine2',shipToTras.Translated_Billing_Address_Line_2__c);
                transAddJSONMap.put('addressLine3',shipToTras.Translated_Billing_Address_Line_3__c);
                transAddJSONMap.put('city',shipToTras.Translated_Billing_City__c);

                billingAddress.translations.add(transAddJSONMap);
                shippingAddres.translations.add(transAddJSONMap);
            }
 
            shipToAccObj.addresses.add(billingAddress);
            shipToAccObj.addresses.add(shippingAddres);

            amendmentObj.account =shipToAccObj;
        }
        if(!otherTraslatedlangs.isEmpty()){
            amendmentObj.meta = new Cls_ReqMeta();
            amendmentObj.meta.translationLanguages = new List<String>(otherTraslatedlangs);
        }
        list<Cls_Amendment> listAmedments = new list<Cls_Amendment>();
        listAmedments.add(amendmentObj);           
        payloadString= JSON.serialize(listAmedments, false);
        return payloadString.replaceAll(':null',':""').replaceAll('"translations":"",','').replaceAll(',"translations":""','');
    } 
    
}