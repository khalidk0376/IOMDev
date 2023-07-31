/**
 * File			: 	MuleSoftCRMWrapper
 * Project       :   Informa Order Management [IOM-775]
 * Created By	: 	Girikon(Ashish)
 * Created Date	: 	22nd Feb 2022
 * Test Class    :   MuleSoftCRMCalloutUtils_Test(100%)
 * **************************************************************************************
 * @description : Wrapper Class for Sending Data to MuleSoft & further carry data to CRMS
 ****************************************************************************************
 * Last Modified By :
 */
@SuppressWarnings('PMD')
public with sharing class MuleSoftCRMWrapper {
	/** @description Constructor */
	public MuleSoftCRMWrapper() {
		OpportunityContactRole 	= new list < OpportunityContactRole > ();
		OpportunityLineItem 	= new List<OpportunityProduct>();
		Translations = new List<Object>();
		CustomBillingSchedule = new List<Object>();
	}
	public OpportunityContactRole[] OpportunityContactRole;
	public OpportunityProduct[] OpportunityLineItem;
	public List<Object> Translations;
	public List<Object> CustomBillingSchedule;
	public String AccountShippingState = '';
    public String CreditStatus = '';
    public String ERPAccountNo = '';
	public string PO_Number = '';
	public String Amendment_IOMOpportunityNumber = '';
	public string VATRegistrationNumber = '';
	public string ShippingAccount_VATRegistrationNumber = '';
	public string BillingAccount_VATRegistrationNumber = '';
	public String OpportunityProbability = '';
	public String OpportunityCloseDate = '';
	public String ShippingAccount_ShippingCountry = '';
	public String IOMOpportunityNumber = ''; //IM-007
	public String Opportunity_RejectionNotes = ''; //The opportunity has been rejected by the Sales Operations
	public String Opportunity_RejectionReason = ''; //Incorrect Product Or Event
	public String OpportunityCurrency = '';
	public String AccountShippingPostalCode = '';
	public String BillingAccount_Number = '';
	public String BillingAccount_ShippingState = '';
	public String BillingAccount_Name = '';
	public String ShippingAccount_BillingState = '';
	public String ShippingAccount_BillingCity = '';
	public String OpportunityStageName = '';
	public String OpportunityName = '';
	public String IOMAccountNumber = '';
	//public String PaymentSchedule = '';
	public String AccountBillingCity = '';
	public String BillingAccount_BillingPostalCode = '';
	public String AccountShippingCity = '';
	public String AccountName = '';
	public String ShippingAccount_ShippingPostalCode = '';
	public String AccountBillingCountry = '';
	public String ShippingAccount_BillingStreet = '';
	public String ShippingAccount_BillingAddressLine2 = '';
	public String ShippingAccount_BillingAddressLine3 = '';
	public String BillingAccount_ShippingPostalCode = '';
	public String AccountShippingStreet = '';
	public String ShippingAccount_BillingPostalCode = '';
	public String BillingAccount_BillingStreet = '';
	public String BillingAccount_BillingAddressLine2 = '';
	public String BillingAccount_BillingAddressLine3 = '';
	public String BillingAccount_ShippingCity = '';
	public String ShippingAccount_IOMNumber = '';
	public String CustomPaymentScheduleInfo = '';
	public String ShippingAccount_ShippingStreet = '';
	public String BillingAccount_BillingState = '';
	public String AccountBillingStreet = '';
	public String AccountBillingAddressLine2 = '';
	public String AccountBillingAddressLine3 = '';
	public String ShippingAccount_ShippingState = '';
	public String AccountRecordType = '';
	public String BillingAccount_BillingCountry = '';
	public String OpportunityEditionCode = '';
	public String OpportunityAmount = '';
	public String AccountShippingCountry = '';
	public String BillingAccount_ShippingStreet = '';
	public String ShippingAccount_Name = '';
	public String AccountBillingPostalCode = '';
	public String BillingAccount_ShippingCountry = '';
	public String BillingAccount_IOMNumber = '';
	public String ShippingAccount_ShippingCity = '';
	public String TargetName = '';
	public String ShippingAccount_BillingCountry = '';
	public String BillingAccount_BillingCity = '';	
	public String AccountBillingState = '';
	public String BillingContact_MailingStreet = '';
	public String BillingContact_AccountShippingCity = '';
	public String BillingContact_AccountBillingCountry = '';
	public String BillingContact_AccountShippingCountry = '';
	public String BillingContact_Salutation = '';
	public String BillingContact_MailingPostalCode = '';
	public String BillingContact_AccountShippingPostalCode = '';
	public String BillingContact_AccountName = '';
	public String BillingContact_MailingCity = '';
	public String BillingContact_IOMNumber = '';
	public String BillingContact_AccountBillingState = '';
	public String BillingContact_AccountBillingPostalCode = '';
	public String BillingContact_MailingState = '';
	public String BillingContact_IOMAccountNumber = '';
	public String BillingContact_MailingCountry = '';
	public String BillingContact_IsPrimary = '';
	public String BillingContact_MobilePhone = '';
	public String BillingContact_AccountId = '';
	public String BillingContact_AccountShippingStreet = '';
	public String BillingContact_Email = '';
	public String BillingContact_Title = '';
	public String BillingContact_FirstName = '';
	public String BillingContact_AccountShippingState = '';
	public String BillingContact_LastName = '';
	public String BillingContact_AccountNumber = '';
	public String BillingContact_AccountBillingStreet = '';
	public String BillingContact_AccountBillingAddressLine2 = '';
	public String BillingContact_AccountBillingAddressLine3 = '';
	public String BillingContact_AccountBillingCity = '';
	public String BillingContact_ACRId = '';
	public String IOMApprovalStatus = '';
	public String CRMOrg = ''; //Penton

	class OpportunityContactRole {
		public String ContactMailingStreet = '';
		/*public String AccountShippingCountry = '';
		public String Role = '';
		public String AccountBillingPostalCode = '';
		public String ContactMailingState = '';
		public String ContactMailingCountry = '';
		public String AccountShippingStreet = '';
		public String ContactTitle = '';
		public String ContactFirstName = '';
		public String AccountShippingState = '';
		public String ContactLastName = '';
		public String AccountBillingCity = '';
		public String AccountShippingCity = '';
		public String AccountBillingCountry = '';
		public String ContactSalutation = '';
		public String ContactMailingPostalCode = '';
		public String AccountShippingPostalCode = '';
		public String AccountName = '';
		public String ContactMailingCity = '';
		public String IOMContactNumber = '';
		public String AccountBillingState = '';
		public String IOMAccountNumber = '';
		public String IsPrimary = '';
		public String ContactMobilePhone = '';
		public String ContactEmail = '';
		public String ccountBillingStreet = '';	*/	
	}

	
	/**
	 * @description - Opportunity Products 
	 */
	public class OpportunityProduct{
		public String OpportunityProductName = '';	//IOM Test Opportunity 001 Raw Space
		public String ProductCode = '';	//IM01-00002
		public String ListPrice = '';	//
		public String TotalPrice = '';	//
		public String Quantity = '';//
		public String LineDescription = '';	//
		public String ProductName = '';	//
		public String StartDate = '';	//01-01-2020
		public String EndDate = '';	//01-31-2020	
		public String CRMOLINumber = '';	//"OLI-00031"	
		public String IOMQLINumber = '';	//"QL-00041"		
	}

	/**
	 * @description - AmendmentRequest Data Wrapper for CRM
	 */
	public class AmendmentRequest {
		public String ChangeRequestNo = '';
		public String AmendmentNumber = '';
		public String ChangeRequestStatus = '';
		public String SalesOperationsComments = '';
		public String IOMOpportunityId = '';
		public String CRMOrg = '';
        public String ActionedBy = '';
		public String ActionedDateTime = '';
	}
}