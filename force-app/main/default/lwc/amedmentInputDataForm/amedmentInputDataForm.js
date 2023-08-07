import { api,wire,track,LightningElement } from 'lwc';
import LWCExternal from '@salesforce/resourceUrl/LWCExternal';
import {loadStyle} from 'lightning/platformResourceLoader';
import { getPicklistValues,getObjectInfo } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, updateRecord} from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';

import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import BillingCountryCode from '@salesforce/schema/Account.BillingCountryCode';
import BillingStateCode from '@salesforce/schema/Account.BillingStateCode';

import getglobalConsVal from '@salesforce/apex/GlobalConstants.getValue';
import getAmdDetails from '@salesforce/apex/AmendmentUtils.fetchIOMAmdCatDetails';
import getAmendmentDetails from '@salesforce/apex/AmendmentUtils.getChangeRequest';
import getInvDetails from '@salesforce/apex/AmendmentUtils.getAllInvoices';
import saveObjData from '@salesforce/apex/AmendmentUtils2.updateChangeRequest';
import getPaymentSch from '@salesforce/apex/PaymentSchedule_Cls.getPaymentPicklistValues';
import fullCancel from '@salesforce/apex/AmendmentUtils.executeFullCancelRebill';
import reBillOrder from '@salesforce/apex/AmendmentUtils2.executeReBillOrder';
import getAsyncJobDetails from '@salesforce/apex/SynchronousAPICallController.getJobs';
import getGoogleAddressAutoComplete from '@salesforce/apex/AmendmentUtils2.getAddressAutoComplete';
import getAddressDetails from '@salesforce/apex/AmendmentUtils2.getAddressDetails';
import getGoogleApiMetaData from '@salesforce/apex/IOM_AddressValidation.getGoogleApiMetaData';
import fetchInvAndCrNotes from '@salesforce/apex/AmendmentUtils.getAllInvoicesAndCreditNotes';
import completeAmendment from '@salesforce/apex/AmendmentUtils2.completeAmendmentProcess';
import cancleSingleInvoies from '@salesforce/apex/AmendmentUtils2.cancleInvoies';
import getAmendedOpportunity from '@salesforce/apex/AmendmentUtils.amendOpportunity';
import executePCAI from '@salesforce/apex/AmendmentUtils.executePartialCreditORAddtionalInvoiceQuote';
import fetchAllordersAndProducts from '@salesforce/apex/AmendmentUtils2.getAllOrders';
import getaccTransRecordDetail from '@salesforce/apex/OrderDashboardController.getaccTransRecordDetail';
import getconTransRecordDetail from '@salesforce/apex/OrderDashboardController.getconTransRecordDetail';
import getQuoteCalculationInProgressFlag from '@salesforce/apex/AmendmentUtils2.isQuoteCalculationInProgress';

//new change
import fetchOpportunityRecord from '@salesforce/apex/AmendmentUtils2.getOpportunityRecord';

const TableClass = 'amedment-table slds-table slds-table_cell-buffer slds-table_bordered';
const AddOpenClass = 'slds-dropdown-trigger_click slds-is-open';
const AddCloseClass = ' slds-dropdown-trigger_click slds-combobox-lookup';

/**** ... Types Of Amendment ...****/
//----------------------------------
// G1 - Full Deal Cancel or Single Invoice Cancel
const Cancellation = 'Cancellation';
//G2 - New Amendment Opportunity Change
const BillingOptionsUpdate = 'Billing Options Update';
//G3 - Full Cancle & Rebill Order 
const BillingScheduleChange = 'Billing Schedule Change';
const TaxExemptRebill = 'Tax Exempt Rebill';
const CampaignRunDatesChange= 'Campaign Run Dates Change';
//G4  -  RICD - Reprint invoice with updated Changes Or Rebill Option
const BillToAccountChange = 'Bill To Account Change';
const ShipToAccountChange = 'Ship To Account Change';
const UpdateBillToContact = 'Update Bill To Contact';
//G5 -  RICD 
const PONumberChange = 'PO number change';
const AccountNameChange     = 'Account Name Change';
const ShippingAddressChange = 'Shipping Address Change';
const BillingAddressChange  = 'Billing Address Change';
const BillToContactDetailsChange    = 'Bill to Contact Details Change';
//G6 - RICD + FCR
const VATRegistrationNumberChange   = 'VAT Registration Number Change';

export default class AmedmentInputDataForm extends NavigationMixin(LightningElement)
{
    @api recordId;
    @track parentOppId;
 //#region  -- Atributes/variables ..
    countryOptions = []; /* Country state picklist variables */
    billToStateOptions = [];
    shipToStateOptions = [];
    paymentvalues = []; //payment schedule options 
    invoiceToCancel = []; //Invoice record data
    selectedInvs = [];//Invoices to cancel
    defaultRecordTypeId;
    controlledValues = {}; //
    controllerValues = {};
    stageProcessingOrder = [];  //Order for Froms to display
    currentStageName;           // Type of change for which form will be displayed
    activeSections = []; // Accordian Sections which are Active & in Focus
    nonZipCodeCountries =''; // get list of countries where Zip is not required or State is required
    countriesWithReqState =''; // get list of countries where State Is Required
    invCrTableData = []; // After RICD Invoice & Credit Notes List avalible for Update
    currentAmendmentGroupNo; // Amendment Groups as[1. Cancelation| 2. New Amendment Opp| 3.RICD] 

    requiredPostalcodeCountryCSV={};  // GECI-1142
    legalentitycode='';    

    amendmentObj; // Amendment Record Data    

    showModalLoading = false; // Spinner inside Modal
    showAmendmentDataForm = false; // Show Amendment Data form when Approved
    isOpenConfirmationModal = false; // Show Confirmation Modal
    isOpenInvCancleModal = false; //Show invoice modal
    showSpinner = false; // Show Loading Spinner    
    isAmedDataConfirmAmendModal = false; // to show Final Warning before Data sync to CRM & ERP
    showInvoiceSelectionModal = false;
    hasPostSaveProcess = false;    //Is Cancel
    hasPreSaveProcess = false;      // Is Rebill
    isFullCancleSelected = false;
    hasNewAmedmentOppTypeRequest = false // If a change type needs a new Amendment Opp.
    disableUpdate = false; // Disable Update button
    hasInvoicePlanProducts = false; // true if Opportunity has Invoice Plan Products [GECI-1713]

    // Google Address Atributes
    googleApiFieldMap =[];
    showBillToAddressOptions = false;
    isBillToAddressLoading = false;
    showShipToAddressOptions = false;
    isShipToAddressLoading = false;
    isReadOnlyMode = false; //[GECI-941]

    // Confirmation Modal Message.
    confirmationMSG ='Do you want to proceed with the Amendments?';

    /** Look Up Input Fields Filter Conditions */
    shipToAccountFilterCondition = ' (Legacy_CRM_Instance__c in (\'GE\',\'Penton\',\'Payment Portal\') OR Legacy_CRM_Instance__c = null) '; //GECI-492
    billToAccountFilterCondition = ' (Legacy_CRM_Instance__c in (\'GE\',\'Penton\',\'Payment Portal\') OR Legacy_CRM_Instance__c = null) ';
    // billToContactFilterCondition = ' (Legacy_CRM_Instance__c in (\'GE\',\'Penton\',\'Payment Portal\') OR Legacy_CRM_Instance__c = null) ';

    /** To Update sObject Instances */
    billToAccountObj={};    // Billing Account
    shipToAccountObj={};    // Shipping Account
    billToContactObj={};    // Bill To Contact 
    opportunityObj={};      // Opportunity
    accTaxObj={};           // Account Tax Number
    amendmentObjToSave={};  // Amendment Request
    orderItemList=[];       // Order Product List
    billToAccTransObj ={};  // Bill To Account Translation Obj
    shipToAccTransObj ={};  // Ship To Account Translation Obj
    billToConTransObj ={};  // Bill To Contact Translation Obj

    // new change
    opp; // Opportunity Record.
    invoiceToBeIssuedBeforeInDays = 30;
    eventEditionStartDate;
    dueDate;
    showCustomBillingScreen = false;
    errorMsg = '';
    showSpinner = false;
    oppQueryFields = 'Id,Name,Bill_To_Account__c,Amount,Total_No_of_payment__c,Milestone_1_Delivery_Date__c,Milestone_2_Delivery_Date__c,Milestone_3_Delivery_Date__c,Milestone_4_Delivery_Date__c ,Milestone_5_Delivery_Date__c ,Milestone_6_Delivery_Date__c, Milestone_7_Delivery_Date__c ,  Milestone_8_Delivery_Date__c, Milestone_9_Delivery_Date__c,Milestone_10_Delivery_Date__c ,Milestone_11_Delivery_Date__c ,Milestone_12_Delivery_Date__c, Milestone_1_Amount__c,Milestone_2_Amount__c,Milestone_3_Amount__c,Milestone_4_Amount__c, Milestone_5_Amount__c,Milestone_6_Amount__c,Milestone_7_Amount__c,Milestone_8_Amount__c,Milestone_9_Amount__c,Milestone_10_Amount__c,Milestone_11_Amount__c,Milestone_12_Amount__c,Milestone_1_Percent__c,Milestone_2_Percent__c,Milestone_3_Percent__c,Milestone_4_Percent__c,Milestone_5_Percent__c,Milestone_6_Percent__c,Milestone_7_Percent__c,Milestone_8_Percent__c,Milestone_9_Percent__c,Milestone_10_Percent__c,Milestone_11_Percent__c,Milestone_12_Percent__c ';
    billingAddressFields = 'BillingStreet,Billing_Address_Line_2__c,Billing_Address_Line_3__c,BillingCity,BillingCountry,BillingState,BillingPostalCode';
    customBillingList = [];
    oppTotal = 0;
    totalNoOfPayment = 0;    
    invCrcolumns = [
        { label: 'Name', fieldName: 'name' },
        { label: 'Status', fieldName: 'status' },
        { label: 'ERP Ref No', fieldName: 'ERPRefNo'},        
        { label: 'Amount', fieldName: 'amount', type: 'currency' },
        { label: 'Invoice Date', fieldName: 'invoiceDate', type: 'date' },
        { label: 'Due Date', fieldName: 'dueDate', type: 'date' },
    ];
    //#endregion
    
    /*************** ON Load *******************/
    connectedCallback()
    {
        this.showSpinner = true;
        loadStyle(this, LWCExternal);        
        this.getConstantCSV('RequiredPostalCode_Oracle');
        this.getConstantCSV('RequiredPostalCode_SAP');
        this.getConstantCSV('CountriesWithoutPostalCode');
        this.getConstantCSV('CountriesWithRequiredState');
        this.getConstantCSV('LegalEntitiesCodeCSV');
        this.getAmendTypes4InvScreen();
        // this.oppQueryFields = this.oppQueryFields; 
        //this.eventEditionStartDate = new Date(new Date().setMonth(new Date().getMonth()+5));
        this.dueDate = new Date();
    }

    //#region *********** Component Button/Event Functions *******/
    // handleSave(){
    //     this.showSpinner = true;
    //     this.setJSONAndSave();
    // }    

    onDataChange(event){
        let fieldName =event.target.name;
        let fieldtype =event.target.type;
        let value = fieldtype === 'checkbox'?event.target.checked:event.target.value;
        let requestType = event.target.dataset.requestType;
        let bindingobject = event.target.dataset.object;
        if(bindingobject === 'BillingAccount')
        {
            this.billToAccountObj[fieldName] = value;
        }
        if(bindingobject === 'ShippingAccount')
        {
            this.shipToAccountObj[fieldName] = value;
        }
        if(bindingobject === 'BillingContact')
        {
            this.billToContactObj[fieldName] = value;
        }

        if(bindingobject === 'BillingAccountName')
        {
            this.billToAccountObj[fieldName] = value;
        }

        if(bindingobject === 'Opportunity')
        {
            this.opportunityObj[fieldName] = value;
        }
        if(bindingobject === 'VATRegistration'){
            this.accTaxObj[fieldName] = value;
        }
        if(bindingobject === 'BillingTranslationAccount'){            
            this.billToAccTransObj[fieldName] = value;
        }
        if(bindingobject === 'ShippingTranslationAccount'){
            this.shipToAccTransObj[fieldName] = value;
        }
        // console.log('fieldName - '+fieldName+' | value '+value+' | requestType - '+requestType+' | bindingobject -'+bindingobject);
    }

    handleSectionToggle(event)
    {
        let openSection  = event.detail.openSections;
    }

    handleChangeCountry(event){
        let fieldName =event.target.name
        let value = event.target.value;
        let requestType = event.target.dataset.requestType;
        let bindingobject = event.target.dataset.object;
        if(bindingobject === 'BillingAccount')
        {
            this.billToAccountObj[fieldName] = value;
            this.billToAccountObj.BillingStateCode = undefined;
            this.loadStateOfCountryChangeByCode(event.target.value,'BillToAddress');
        }
        if(bindingobject === 'ShippingAccount')
        {
            this.shipToAccountObj[fieldName] = value;
            this.shipToAccountObj.BillingStateCode = undefined;
            this.loadStateOfCountryChangeByCode(event.target.value,'ShipToAddress');
        }
        
    }   

    handleInv2CancleSelection(event)
    {
        let selectedRows = event.detail.selectedRows;
        let invIds=[];
        let largestIndexNo = 0;
        if(selectedRows && Array.isArray(selectedRows) && selectedRows.length>0)
        {
            selectedRows.forEach((item)=>{
                if(largestIndexNo < item.index){largestIndexNo = item.index;}
                //invIds.push(item.Id);
            });
            for(let i=0;i<=largestIndexNo;i++)
            {
                invIds.push(this.invoiceToCancel[i].Id);
            }
        }else{
            invIds =[];
        }        
        this.selectedInvs = invIds;        
        // console.log('selectedInv2Cancle ===>',JSON.stringify(this.selectedInvs));
    }

    billToAccountNewAddress={}; //Formated Address Obj    
    billToAccountChange(event)
    {
        let billtoAccount = event.detail.selectedRecord;
        // console.log('billtoAccount - '+JSON.stringify(billtoAccount));
        this.opportunityObj.Bill_To_Account__c = billtoAccount ? billtoAccount.Id:undefined;
        //this.billToContactFilterCondition = '  Legacy_CRM_Instance__c in (\'GE\',\'Penton\',\'Payment Portal\') AND AccountId = \''+(this.opportunityObj.Bill_To_Account__c?this.opportunityObj.Bill_To_Account__c:'')+'\' ';         
        this.billToAccountNewAddress = this.getAddressStrings(billtoAccount);
        // Refreh Bill to Contact if loaded
        let lookupInputs = this.template.querySelectorAll('c-s-object-look-up-input');        
        lookupInputs.forEach(inputField => {            
            if(inputField.sObjectApiName ==='Contact')
            {      
                inputField.filterCondition = this.billToContactFilterCondition;  
                inputField.refreshData();
            }
        });
    }
    shipToAccountNewAddress={}; //Formated Address Obj    
    shipToAccountChange(event)
    {
        let shiptoAccount = event.detail.selectedRecord;
        this.opportunityObj.Ship_To_Account__c = shiptoAccount? shiptoAccount.Id :null;
        this.shipToAccountNewAddress = this.getAddressStrings(shiptoAccount);
    }
    billingContactAddedInformation ;
    billToContactChange(event)
    {
        let billtoContact = event.detail.selectedRecord;
        this.opportunityObj.Billing_Contact__c = billtoContact? billtoContact.Id: null;
        this.billingContactAddedInformation = billtoContact? billtoContact.Account.Name: undefined;
    }

    closeModal(){
        this.isOpenConfirmationModal = false;
        this.isOpenInvCancleModal = false;
        this.isAmedDataConfirmAmendModal = false;
        this.showInvoiceSelectionModal = false;
    }

    openSaveModal(){
        if(!this.isFullCancellation)
        {
            if(this.isInputValid()){
                this.isOpenConfirmationModal = true;    
                // this.showSpinner = true;
                // this.setJSONAndSave();
            }else{
                this.closeModal();
                this.openAllaccordions();
            }
        }else{
            this.isOpenConfirmationModal = true;
        }        
    }

    cancleInvoice() //
    {
        this.closeModal();
        this.showSpinner = true;

        if(this.selectedInvs.length > 0)
        {
            this.cancelSelectedInvs(); // Cancel Selected Inv only without holding Order product's billing 
        }else{
            if(this.isRICDwithFinancialChange == true && this.amendmentObj.Current_Processing_Step__c != 'Step 2') 
            {
                // If No Invoice is Selected - Normal Data update without Cancel & ReBill
                // this.hasPostSaveProcess = false;
                this.showSpinner = true;
                this.updateAllObjData();
            }else{ // Default Case - For Full Cancel
                // If No Invoice is Selected - Full Cancel Order
                this.cancleOrder();
                this.isFullCancleSelected = true;
                this.confirmationMSG = 'As no invoice found.Please confirm,if you wish to Cancel the full Deal ?'
                this.isOpenConfirmationModal = true;
                this.showSpinner = false;
            }
        }
    }

    handleCancellation()
    {
        this.selectedInvs = [];
        if(this.isFullCancleSelected == false)
        {
            this.fetchAllInvs();
        }else{
            this.confirmationMSG = 'Please confirm,if you wish to Cancel the full Deal ?'
            this.isOpenConfirmationModal = true;
        }
    }
    fullCancle()
    {
        this.selectedInvs = [];
        this.showSpinner = true;
        this.closeModal();
        this.cancleOrder();
    }

    saveData()
    {
        this.closeModal();
        this.amendmentObjToSave.Id = this.amendmentObj.Id;
        this.amendmentObjToSave.Amendment_Type__c = this.amendmentObj.Amendment_Type__c;
        this.amendmentObjToSave.Opportunity__c = this.amendmentObj.Opportunity__c;
        this.mapFieldsValueAndSave();
        // if(!this.isFullCancellation)
        // {            
           
        // }else{
        //     alert ('IN progress')
        // }        
    }

    completeAmend(){
        // Call Apex to complete Amendment
        this.closeModal();
        // alert('Development in progress....');
        this.showSpinner = true;
        if(this.isCampaignRunDatesChange)
        {   // Check if the CPQ async Calcutaions are complete. [GECI-776]
            setTimeout(() => {
                this.checkQuoteCalculationStatus();
            },10000);
        }else{
            this.afterAmendDataSync();
        }        
    }

    invoiceSelectionModalNext()
    {
        this.showInvoiceSelectionModal = false;
        //this.isAmedDataConfirmAmendModal = true;
        this.completeAmend(); // Added for [GECI-552]
    }
    handleInv2RePrintSelection(event)
    {
        this.amendmentObjToSave['ERP_Ref_Numbers__c'] = undefined;
        let selectedRows = event.detail.selectedRows;
        // this.showRequiredInvMessage =false;
        // console.log('selectedRows 4 RePrint - '+ JSON.stringify(selectedRows));
        let erpRefList=[];
        
        if(selectedRows && Array.isArray(selectedRows))
        {
            selectedRows.forEach((item)=>{
                
                if((item.type=="Invoice") && item.ERPRefNo){                    
                    erpRefList.push(item.ERPRefNo);
                }
                
            });
            // if(selectedRows.length != (invIds.length+crNoteIds.length))
            // {
            //     this.reqErrorMessage = 'Please,Select Invoice/Credit Note with a valid ERP Ref No,else data will not be synced with ERP.'
            //     this.showRequiredInvMessage = true;
            // }
        }
        if(erpRefList.length>0){
            this.amendmentObjToSave['ERP_Ref_Numbers__c'] = erpRefList.join(',');  // INV/CN CSV
        }
    }

    createNewAmendmentOpp(){
        this.showSpinner = true;
        // this.navigatetoQLE('a0x050000003QOWAA2');
        this.redirectToNewAmedmentOpp();
    }

    handlePCAI()
    {
        this.showSpinner = true;
        this.processPCAI();
    }

    handleFullCancleCheckChange(event) {
        this.isFullCancleSelected = event.target.checked;
    }
    /* Address Change functions */
    handleAddressBlur(event) {
        setTimeout(() => {
            this.billToAddressClass = AddCloseClass;
            this.showBillToAddressOptions = false;

            this.shipToAddressClass = AddCloseClass;
            this.showShipToAddressOptions = false;
        },500);
    }
    delayTimeout;
    handleBillToSteetChange(event)// On key up
    {
        this.billToAccountObj.BillingStreet = event.target.value;         
        //Debouncing this method: Do not actually fire the event as long as this function is
        //being called within a delay of DELAY. This is to avoid a very large number of Apex
        //method calls in components listening to this event.
        window.clearTimeout(this.delayTimeout);
        this.delayTimeout = setTimeout(() => {            
            if(this.billToAccountObj.BillingStreet && this.billToAccountObj.BillingStreet.length>1){                
                this.openAddressListbox('BillToAddress');
                this.displayGoogleAddressOptions( this.billToAccountObj.BillingStreet,'BillToAddress');
            }
            else if(this.billToAccountObj.BillingStreet && this.billToAccountObj.BillingStreet.length==0){
                this.billToAccountObj.Billingcity = '';
                this.billToAccountObj.BillingStreetcode = '';
                this.billToAccountObj.BillingPostalCode = '';
                this.billToAccountObj.Billingcountrycode = '';
            }
        }, 300);
    }

    handleBillToAddressSelect(event) // On Option Selection
    {
        this.billToAccountObj.BillingStreet = event.currentTarget.dataset.record;    
        this.billToAddressClass = AddCloseClass;
        this.setGooggleAddressDetails(event.currentTarget.dataset.placeid,'BillToAddress',event.currentTarget.dataset.record);
        this.showBillToAddressOptions = false;  
    }

    handleShipToSteetChange(event)// On key up
    {
        this.shipToAccountObj.BillingStreet = event.target.value;         
        //Debouncing this method: Do not actually fire the event as long as this function is
        //being called within a delay of DELAY. This is to avoid a very large number of Apex
        //method calls in components listening to this event.
        window.clearTimeout(this.delayTimeout);
        this.delayTimeout = setTimeout(() => {            
            if(this.shipToAccountObj.BillingStreet && this.shipToAccountObj.BillingStreet.length>1){                
                this.openAddressListbox('ShipToAddress');
                this.displayGoogleAddressOptions( this.shipToAccountObj.BillingStreet,'ShipToAddress');
            }
            else if(this.shipToAccountObj.BillingStreet && this.shipToAccountObj.BillingStreet.length==0){
                this.shipToAccountObj.Billingcity = '';
                this.shipToAccountObj.BillingStreetcode = '';
                this.shipToAccountObj.BillingPostalCode = '';
                this.shipToAccountObj.Billingcountrycode = '';
            }
        }, 300);
    }

    handleShipToAddressSelect(event) // On Option Selection
    {
        this.shipToAccountObj.BillingStreet = event.currentTarget.dataset.record;    
        this.shipToAddressClass = AddCloseClass;
        this.setGooggleAddressDetails(event.currentTarget.dataset.placeid,'ShipToAddress',event.currentTarget.dataset.record);
        this.showShipToAddressOptions = false;  
    }

    handleCampaignRunInputChange(event)
    {
        let fieldName =event.target.name;
        let value = event.target.value;
        let orderItemId = event.target.dataset.orderItemId;
        let orderId = event.target.dataset.orderId;        

        let recordIndex =  this.orderItemList.findIndex(x => x.Id ===orderItemId);
        // console.log('fieldName - '+fieldName+' | value '+value+' | recordIndex '+recordIndex+' | orderItemId - '+orderItemId +' | orderId '+orderId);
        if(recordIndex>=0)
        {
            this.orderItemList[recordIndex][fieldName]=value;
        }else{
            let orderItem = {Id:orderItemId};
            orderItem[fieldName]=value;
            this.orderItemList.push(orderItem);
        }
        // console.log(' Order Item List -'+JSON.stringify(this.orderItemList));
    }

    /******** Custom Billing *********/
    handleCustomBillingInputChange(event){
        let fieldName =event.target.name;
        let value = event.target.value;
        let index = event.target.dataset.index;
        // console.log('fieldName - '+fieldName+' | value '+value+' | index - '+index);
        if(fieldName === 'totalNoOfPayment')
        {
            this.totalNoOfPayment = value;
            this.setCustomBillingList();
        }else if(fieldName === 'paymentPercent')
        {            
            this.validateAndResetPercent(parseInt(index),value);
        }else if(fieldName === 'paymentDate')
        {
            this.validateAndResetDate(parseInt(index),value);
        }
        // console.log('customBillingList - '+JSON.stringify(this.customBillingList));
    }
    //#endregion
    
    //#region ********** Helper Functions *************/

    isInputValid(){
        let isValid = true;
        let inputFields = this.template.querySelectorAll('.validate');
        inputFields.forEach(inputField => {
            if(!inputField.checkValidity()){                    
                isValid = false;
            }
            inputField.reportValidity();
        });

        let lookupInputs = this.template.querySelectorAll('c-s-object-look-up-input');
        // console.log('lookupInputs',JSON.stringify(lookupInputs));
        lookupInputs.forEach(inputField => {
            if(inputField.sObjectApiName ==='Account')
            {
                if(this.isBillToAccountChange && !this.opportunityObj.Bill_To_Account__c){                    
                    isValid = false;
                    inputField.addErrorMeesage('Complete this field');
                }
                if(this.isShipToAccountChange && !this.opportunityObj.Ship_To_Account__c){                    
                    isValid = false;
                    inputField.addErrorMeesage('Complete this field');
                }
            }
            if(inputField.sObjectApiName ==='Contact' && this.isUpdateBillToContact && !this.opportunityObj.Billing_Contact__c)
            {
                isValid = false;
                inputField.addErrorMeesage('Complete this field');
            }
        });
        /* Removed in [GECI-1895]
        if(this.isBilltoContactDetailsChange)
        {
            isValid = this.validateBilltoContactDetailsChange();
        }*/

        if(this.isBillingScheduleChange ){
            isValid = this.validateAndSetCustomPayments();
        }
        if(this.isCampaignRunDatesChange){
            isValid = this.validateCampaignRunDatesChange();
        }
        return isValid;
    }

    openAllaccordions(){        
        this.activeSections = ['RICD_01','RICD_02','RICD_03','RICD_04','RICD_05','RICD_06','RICD_07','RICD_08','RICD_09','FC_01','FC_02','FC_03'];
    }
    mapFieldsValueAndSave(){        
        if(this.isBillingAddressChange){
            this.billToAccountObj.Id = this.amendmentObj.Opportunity__r.Bill_To_Account__c;
            this.amendmentObjToSave.New_Billing_Street__c = this.billToAccountObj.BillingStreet;
            this.amendmentObjToSave.New_Billing_Address_Line_2__c = this.billToAccountObj.Billing_Address_Line_2__c;
            this.amendmentObjToSave.New_Billing_City__c = this.billToAccountObj.BillingCity;
            this.amendmentObjToSave.New_Billing_Country__c = this.billToAccountObj.BillingCountry;
            this.amendmentObjToSave.New_Billing_State__c = this.billToAccountObj.BillingState;
            this.amendmentObjToSave.New_Billing_Postal_Code__c = this.billToAccountObj.BillingPostalCode;
            this.amendmentObjToSave.Old_Billing_Address_Line_2__c = this.amendmentObj.Opportunity__r.Bill_To_Account__r.Billing_Address_Line_2__c;
            this.amendmentObjToSave.Old_Billing_Street__c = this.amendmentObj.Opportunity__r.Bill_To_Account__r.BillingStreet;
            this.amendmentObjToSave.Old_Billing_State__c = this.amendmentObj.Opportunity__r.Bill_To_Account__r.BillingState;
            this.amendmentObjToSave.Old_Billing_Postal_Code__c = this.amendmentObj.Opportunity__r.Bill_To_Account__r.BillingPostalCode;
            this.amendmentObjToSave.Old_Billing_Country__c = this.amendmentObj.Opportunity__r.Bill_To_Account__r.BillingCountry;
            this.amendmentObjToSave.Old_Billing_City__c = this.amendmentObj.Opportunity__r.Bill_To_Account__r.BillingCity;
        }
        if(this.isShippingAddressChange){
            this.shipToAccountObj.Id = this.amendmentObj.Opportunity__r.Ship_To_Account__c;
            this.amendmentObjToSave.New_Shipping_Street__c = this.shipToAccountObj.BillingStreet;
            this.amendmentObjToSave.New_Shipping_City__c = this.shipToAccountObj.BillingCity;
            this.amendmentObjToSave.New_Shipping_Country__c = this.shipToAccountObj.BillingCountry;
            this.amendmentObjToSave.New_Shipping_State__c = this.shipToAccountObj.BillingState;
            this.amendmentObjToSave.New_Shipping_Postal_Code__c = this.shipToAccountObj.BillingPostalCode;
            this.amendmentObjToSave.Old_Shipping_Street__c = this.amendmentObj.Opportunity__r.Ship_To_Account__r.BillingStreet;
            this.amendmentObjToSave.Old_Shipping_State__c = this.amendmentObj.Opportunity__r.Ship_To_Account__r.BillingState;
            this.amendmentObjToSave.Old_Shipping_Postal_Code__c = this.amendmentObj.Opportunity__r.Ship_To_Account__r.BillingPostalCode;
            this.amendmentObjToSave.Old_Shipping_Country__c = this.amendmentObj.Opportunity__r.Ship_To_Account__r.BillingCountry;
            this.amendmentObjToSave.Old_Shipping_City__c = this.amendmentObj.Opportunity__r.Ship_To_Account__r.BillingCity;
        }
        if(this.isPONumberChange){
            this.opportunityObj.Id = this.amendmentObj.Opportunity__c;
            this.amendmentObjToSave.New_PO_Number__c = this.opportunityObj.PO_Number__c;
            this.amendmentObjToSave.Old_PO_Number__c = this.amendmentObj.Opportunity__r.PO_Number__c;
        }
        if(this.isBillToAccountChange){
            this.opportunityObj.Id = this.amendmentObj.Opportunity__c;
            this.amendmentObjToSave.New_Billing_Account__c = this.opportunityObj.Bill_To_Account__c;
            this.amendmentObjToSave.Old_Billing_Account__c = this.amendmentObj.Opportunity__r.Bill_To_Account__c;
        }
        if(this.isShipToAccountChange){
            this.opportunityObj.Id = this.amendmentObj.Opportunity__c;
            this.amendmentObjToSave.New_Shipping_Account__c = this.opportunityObj.Ship_To_Account__c;
            this.amendmentObjToSave.Old_Shipping_Account__c = this.amendmentObj.Opportunity__r.Ship_To_Account__c;
        }
        if(this.isUpdateBillToContact){
            this.opportunityObj.Id = this.amendmentObj.Opportunity__c;
            this.amendmentObjToSave.New_Billing_Contact__c = this.opportunityObj.Billing_Contact__c;
            this.amendmentObjToSave.Old_Bill_To_Contact__c = this.amendmentObj.Opportunity__r.Billing_Contact__c;
        }
        if(this.isAccountNameUpdate){
            this.billToAccountObj.Id = this.amendmentObj.Opportunity__r.Bill_To_Account__c;
            this.amendmentObjToSave.New_Account_NameD__c = this.billToAccountObj.Name;
            this.amendmentObjToSave.Old_Account_Name__c = this.amendmentObj.Opportunity__r.Bill_To_Account__r.Name;
        }
        if(this.isBilltoContactDetailsChange){
            this.billToContactObj.Id = this.amendmentObj.Opportunity__r.Billing_Contact__c;
            this.amendmentObjToSave.New_Contact_FirstName__c = this.billToContactObj.FirstName;
            this.amendmentObjToSave.New_Contact_LastName__c = this.billToContactObj.LastName;
            this.amendmentObjToSave.New_Contact_Phone__c = this.billToContactObj.MobilePhone;
            this.amendmentObjToSave.New_Contact_Email__c = this.billToContactObj.Email;
            this.amendmentObjToSave.Old_Contact_FirstName__c = this.amendmentObj.Opportunity__r.Billing_Contact__r.FirstName;
            this.amendmentObjToSave.Old_Contact_LastName__c = this.amendmentObj.Opportunity__r.Billing_Contact__r.LastName;
            this.amendmentObjToSave.Old_Contact_Phone__c = this.amendmentObj.Opportunity__r.Billing_Contact__r.MobilePhone;
            this.amendmentObjToSave.Old_Contact_Email__c = this.amendmentObj.Opportunity__r.Billing_Contact__r.Email;
        }
        if(this.isBillingScheduleChange){        
            this.opportunityObj.Id = this.amendmentObj.Opportunity__c;
            this.amendmentObjToSave.New_Payment_Schedule__c = 'custom';
            this.amendmentObjToSave.Old_Payment_Schedule__c = this.isPaymentSchedulefromOpp ?this.amendmentObj.Opportunity__r.Payment_Schedule__c:this.amendmentObj.Opportunity__r.Event_Payment_ScheduleFor__c;          
            //this.opportunityObj.Custom_Payment__c=True;
            //this.opportunityObj.Total_No_of_payment__c=totalNoOfPayment;
        
        }
        if(this.isTaxExemptRebill){
            this.opportunityObj.Id = this.amendmentObj.Opportunity__c;
        }
        if(this.isVATRegistrationNumberChange){            
            if(this.amendmentObj.Old_Account_Tax_Number__r.Id != '' && this.amendmentObj.Old_Account_Tax_Number__r.Id != null && this.amendmentObj.Old_Account_Tax_Number__r.Id != undefined){                
                this.accTaxObj.Id = this.amendmentObj.Old_Account_Tax_Number__r.Id;
            }else{                
                this.accTaxObj.Account__c = this.amendmentObj.Opportunity__r.Bill_To_Account__c;
                this.accTaxObj.Tax_Country__c = this.amendmentObj.Opportunity__r.Bill_To_Account__r.BillingCountryCode;
                this.accTaxObj.Status__c = 'Valid';
            }
            
            //this.accTaxObj.Account__c = this.amendmentObj.Opportunity__r.Bill_To_Account__c;
            this.amendmentObjToSave.New_Tax_ID__c = this.accTaxObj.Tax_ID__c;
            this.amendmentObjToSave.Old_Tax_ID__c = this.amendmentObj.Old_Account_Tax_Number__r.Tax_ID__c;
        }
        if(this.isCampaignRunDatesChange){
            let activatedOrderIds = [];
            this.orderItemList.forEach((newOrderProduct)=>{            
                let oldOrderProduct = this.allActiveOrderProducts[this.allActiveOrderProducts.findIndex(x => x.Id ===newOrderProduct.Id)];
                //if(oldOrderProduct.IsActive)
                //{
                    activatedOrderIds.push(oldOrderProduct.OrderId);                 
               // }
           });
            this.amendmentObjToSave.Order_IDs__c = activatedOrderIds.length >0 ?activatedOrderIds.join(','):undefined;
            //console.log('activatedOrderIds -  '+JSON.stringify(activatedOrderIds));
        }
                
        // Set Next Step        
        this.showSpinner = true;
        if(this.hasPreSaveProcess){            
            this.cancleOrder();
        }else{
            if(this.isRICDwithFinancialChange)
            { // Show Inv Selection Screen
                // this.hasPostSaveProcess = false;
                this.fetchAllInvs();
            }else{ // Normal RICD                 
                this.updateAllObjData();   
            }            
        }
    }

    loadStateOfCountryChangeByCode(countryCode,addressType){
        let stateOptions =[];        
        if(countryCode != null && countryCode != '' && this.controllerValues && this.controlledValues){
            var key = this.controllerValues[countryCode];
            stateOptions = this.controlledValues[key];
        }
        
        if(addressType == 'BillToAddress')
        {
            this.billToStateOptions = JSON.parse(JSON.stringify(stateOptions));
        }else if(addressType == 'ShipToAddress')
        {
            this.shipToStateOptions = JSON.parse(JSON.stringify(stateOptions));
        }
    }

    /*
    validateBilltoContactDetailsChange() // GECI-924 - Removed in [GECI-1895]
    {
        let isValid = true;
        let oldContactData = this.amendmentObj.Opportunity__r.Billing_Contact__r;                
        let inputFields = this.template.querySelectorAll('[data-request-type="Bill to Contact Details Change"]');        
        inputFields.forEach(inputField => {
            inputField.setCustomValidity("");
            if(!this.billToContactObj.FirstName && !this.billToContactObj.LastName && !this.billToContactObj.MobilePhone && !this.billToContactObj.Email)
            {
                inputField.setCustomValidity("At least one value needs to be updated"); 
                isValid = false;       
            }                
            if(oldContactData && oldContactData[inputField.name] && (oldContactData[inputField.name] === this.billToContactObj[inputField.name]))
            {
                inputField.setCustomValidity("The new value entered is the same as the old value");
                isValid = false;
            }            
            inputField.reportValidity();
        });
        return isValid;
    }*/

    setOrderforAmedmentExecution()
    {
        // Amendment types which can co-exist with Cancellation
        let amedmentTypesWithCancellation =  [AccountNameChange,BillToContactDetailsChange,VATRegistrationNumberChange];

        let newAmedmentOppTypes =  [BillingOptionsUpdate];

        // this.billToContactFilterCondition += ' AND AccountId = \''+this.amendmentObj.Opportunity__r.Bill_To_Account__c+'\' ';
        this.currentStageName = '';
        this.currentAmendmentGroupNo = 3;
        this.stageProcessingOrder = this.amendmentObj.Amendment_Type__c.split(';');

        /** Remove Opp/Order level Amendment grouped with Cancellation */
        if(this.isFullCancellation)
        {            
            let tempStageProcessingOrder = [];
            this.stageProcessingOrder.forEach((row,i) => {
                if(amedmentTypesWithCancellation.includes(row))
                {
                    tempStageProcessingOrder.push(row);
                }
            });
            this.currentAmendmentGroupNo = tempStageProcessingOrder.length >0?3:1;
            tempStageProcessingOrder.push(Cancellation);
            this.stageProcessingOrder = tempStageProcessingOrder;
            if(this.amendmentObj.Current_Processing_Step__c != 'Step 0')
            {
                this.currentAmendmentGroupNo = 1;               
            }
            if(this.currentAmendmentGroupNo === 1){
                this.isFullCancleSelected = true;// GECI - 1079
            }
        }else{ //Check for 2nd Priorty types
            let hasNonP2RequestTypes = false;
            this.stageProcessingOrder.forEach((row,i) => {                
                if(newAmedmentOppTypes.includes(row))
                {
                    this.hasNewAmedmentOppTypeRequest = true;
                }else{
                    hasNonP2RequestTypes = true;
                }
            });
            this.currentAmendmentGroupNo = hasNonP2RequestTypes?3:2;
            if( this.hasNewAmedmentOppTypeRequest && this.amendmentObj.Current_Processing_Step__c != 'Step 0')
            {
                this.currentAmendmentGroupNo = 2;
            }
        }
        if(
            this.stageProcessingOrder.includes(BillingScheduleChange) || 
            this.stageProcessingOrder.includes(TaxExemptRebill) || 
            this.stageProcessingOrder.includes(CampaignRunDatesChange) || 
            (this.stageProcessingOrder.includes(VATRegistrationNumberChange) && this.isVATFCRChange())||
            (this.stageProcessingOrder.includes(BillToAccountChange) && this.hasInvoicePlanProducts == true) ||     // [GECI-1713]
            (this.stageProcessingOrder.includes(ShipToAccountChange) && this.hasInvoicePlanProducts == true) ||     // [GECI-1713]
            (this.stageProcessingOrder.includes(UpdateBillToContact) && this.hasInvoicePlanProducts == true)        // [GECI-1713]
        )      
        {
            this.hasPostSaveProcess = true;
            this.hasPreSaveProcess = true;
        }

        // alert('Check');
        // this.navigatetoQLE(this.amendmentObj.Amended_Quote_Id__c);
        // this.stageProcessingOrder = ['Billing Address Change','PO number change','Bill To Account Change','Update Bill To Contact','Account Name Change','Bill to Contact Details Change','VAT Registration Number Change'];
    }

    isVATFCRChange(){
        let isVATFCR = false;
        const legalentitycodearray = this.legalentitycode.split(',');
        if(this.amendmentObj.Opportunity__r.Bill_To_Account__r.Region__c == 'EU' && legalentitycodearray.includes(this.amendmentObj.Opportunity__r.Legal_Entity__r.Legal_Entity_Code__c)){
            isVATFCR = true;
        }
        return isVATFCR;
    }

    onAmendDataComplete()
    {
        let showInvmodal = false;
        let changeRequestWithInvSelection = [];
        let typeOfChanges = this.amendmentObj.Amendment_Type__c.split(';');
        let typeOfChangesWithInvScreen =  this.amendmentTypesforInvoiceSelectionScreen.split(',');
        typeOfChanges.forEach((typeOfChange)=>{
            if(typeOfChangesWithInvScreen.includes(typeOfChange) && 
                (typeOfChange != VATRegistrationNumberChange || (typeOfChange == VATRegistrationNumberChange && !this.isVATFCRChange()))
                ){
                showInvmodal = true;
                changeRequestWithInvSelection.push(typeOfChange);
            }
        });

        if(showInvmodal == true && !this.isFullCancellation){
            setTimeout(()=>{                
                this.getInvoicesAndCreditNotes();
            },500);
        }else{
            this.isAmedDataConfirmAmendModal = true;
        }
    } 
    
    getInvoiceAndCreditNoteTableData(invList)
    {
        let InvCrTableData = [];
        invList.forEach((row,i) => {
            InvCrTableData.push({Id:row.Id,name:row.Name, ERPRefNo:row.ERP_Reference__c, dueDate:row.blng__DueDate__c, amount:row.blng__TotalAmount__c,type:"Invoice",status:row.blng__InvoiceStatus__c,invoiceDate:row.blng__InvoiceDate__c});
        });

        return InvCrTableData;
    }

    hasPriorGroupProcess()
    {
        // add Code for Group 2
        if(this.isFullCancellation){
            this.currentAmendmentGroupNo = 1;
            this.isFullCancleSelected = true;// GECI - 1079
            return true;
        }else if(this.hasNewAmedmentOppTypeRequest){
            this.currentAmendmentGroupNo = 2;
            return true;
        }
        return false;
    }

    openAddressListbox(type) {
        if(type == 'BillToAddress')
        {
            if (typeof this.billToAccountObj.BillingStreet === 'undefined' || this.billToAccountObj.BillingStreet < 3) {
                this.billToAddressClass = AddCloseClass;
                return;
            }
            this.billToAddressClass = AddOpenClass;
        }else if(type == 'ShipToAddress')
        {
            if (typeof this.shipToAccountObj.BillingStreet === 'undefined' || this.shipToAccountObj.BillingStreet < 3) {
                this.shipToAddressClass = AddCloseClass;
                return;
            }
            this.shipToAddressClass = AddOpenClass;
        }        
    }

    getAddressStrings(accObj)
    {
        let addressObj ={"Line1":"","Line2":""};
        if(accObj)
        {
            addressObj.Line1 = accObj.BillingStreet ?accObj.BillingStreet+' ':'';
            addressObj.Line1 += accObj.Billing_Address_Line_2__c ?accObj.Billing_Address_Line_2__c+' ':'';
            addressObj.Line1 += accObj.Billing_Address_Line_3__c ?accObj.Billing_Address_Line_3__c+' ':'';
            addressObj.Line1 += accObj.BillingCity ?accObj.BillingCity+' ':'';

            addressObj.Line2 = accObj.BillingState ?accObj.BillingState+', ':'';
            addressObj.Line2 += accObj.BillingCountry ?accObj.BillingCountry+' ':'';
            addressObj.Line2 += accObj.BillingPostalCode ?'- '+accObj.BillingPostalCode:'';
        }
        return addressObj;
    }
    activeOrderAccordions = [];
    allActiveOrderProducts = [];
    setOrderProductValues(){
        this.opportunityOrderList.forEach((order)=>{
            this.activeOrderAccordions.push(order.OrderNumber);
            order.IsActive = order.Status ==='Activated'?true:false;
            order.OrderItems.forEach((orderItems)=>{
                orderItems.ProductName = orderItems.Product2.Name;
                orderItems.recordUrl =  '/lightning/r/Opportunity/'+orderItems.Id+'/view';
                orderItems.IsActive = order.IsActive;

                this.allActiveOrderProducts.push(orderItems);
            });
       });
    }
    
    validateCampaignRunDatesChange(){   
        let isValid = true;     
        this.orderItemList.forEach((newOrderProduct)=>{            
            // let recordIndex =  this.allActiveOrderProducts.findIndex(x => x.Id ===newOrderProduct.Id);
            let oldOrderProduct = this.allActiveOrderProducts[this.allActiveOrderProducts.findIndex(x => x.Id ===newOrderProduct.Id)];
            if(oldOrderProduct.IsActive)
            {
                let showError = false;
                // console.log('IsActive');
                if(newOrderProduct.ServiceDate == oldOrderProduct.ServiceDate)
                {
                    delete newOrderProduct.ServiceDate;
                }

                if(newOrderProduct.EndDate == oldOrderProduct.EndDate)
                {
                    delete newOrderProduct.EndDate;
                }
                // console.log('newOrderProduct '+ JSON.stringify(newOrderProduct));
                if(newOrderProduct.hasOwnProperty('ServiceDate') && newOrderProduct.hasOwnProperty('EndDate'))
                {
                    isValid = false; 
                    showError = true;   
                }
               
                let inputFields = this.template.querySelectorAll('[data-order-item-id="'+newOrderProduct.Id+'"]');
                inputFields.forEach(inputField => {
                    inputField.setCustomValidity("");
                    if((inputField.name == 'ServiceDate' || inputField.name == 'EndDate') && showError == true)
                    {
                        inputField.setCustomValidity("Can't update order item's start and end dates at the same time.");
                    }
                    inputField.reportValidity();
                });
                
            }
       });
       return isValid;
    }

    billToAccountOldAddress ={};
    shipToAccountOldAddress ={};
    /*** SET Default Data/Values On Load */
    setDefaultValues()
    {
       if(this.isBillingScheduleChange)
        {
            this.getOppDetails();
            this.getPaymentSchOptions();
        }
        if(this.isCampaignRunDatesChange){
            this.getOppAllOrders(this.amendmentObj.Opportunity__c);
        }
        if(this.isAccountNameUpdate || this.isBillingAddressChange)
        {
            this.getAccTransData(this.amendmentObj.Opportunity__r.Bill_To_Account__c,'Bill To');                    
        }
        if(this.isShippingAddressChange)
        {   
            this.getAccTransData(this.amendmentObj.Opportunity__r.Ship_To_Account__c,'Ship To');
        }
        if(this.isBillToAccountChange ){
            this.billToAccountFilterCondition = ' (Legacy_CRM_Instance__c in (\''+this.amendmentObj.Opportunity__r.Legacy_CRM_Instance__c+'\') AND Legacy_CRM_Instance__c != null) ';
        }
        if(this.isShipToAccountChange ){
            this.shipToAccountFilterCondition = ' (Legacy_CRM_Instance__c in (\''+this.amendmentObj.Opportunity__r.Legacy_CRM_Instance__c+'\') AND Legacy_CRM_Instance__c != null) ';
        }

        this.billToAccountOldAddress = this.getAddressStrings(this.amendmentObj.Opportunity__r.Bill_To_Account__r);
        this.shipToAccountOldAddress = this.getAddressStrings(this.amendmentObj.Opportunity__r.Ship_To_Account__r);
        if(this.isBillingAddressChange){             
            this.loadStateOfCountryChangeByCode(this.amendmentObj.Opportunity__r.Bill_To_Account__r.BillingCountryCode,'BillToAddress');
            this.billToAccountObj.Id            = this.amendmentObj.Opportunity__r.Bill_To_Account__c;
            this.billToAccountObj.BillingStreet = this.amendmentObj.Opportunity__r.Bill_To_Account__r.BillingStreet;
            this.billToAccountObj.BillingCity   = this.amendmentObj.Opportunity__r.Bill_To_Account__r.BillingCity;
            //this.billToAccountObj.BillingState  = this.amendmentObj.Opportunity__r.Bill_To_Account__r.BillingState;
            this.billToAccountObj.BillingStateCode = this.amendmentObj.Opportunity__r.Bill_To_Account__r.BillingStateCode;
            this.billToAccountObj.Billing_Address_Line_2__c = this.amendmentObj.Opportunity__r.Bill_To_Account__r.Billing_Address_Line_2__c;
            //this.billToAccountObj.BillingCountry = this.amendmentObj.Opportunity__r.Bill_To_Account__r.BillingCountry;
            this.billToAccountObj.BillingCountryCode = this.amendmentObj.Opportunity__r.Bill_To_Account__r.BillingCountryCode;
            this.billToAccountObj.BillingPostalCode = this.amendmentObj.Opportunity__r.Bill_To_Account__r.BillingPostalCode;
        }
        if(this.isShippingAddressChange){
            this.loadStateOfCountryChangeByCode(this.amendmentObj.Opportunity__r.Ship_To_Account__r.BillingCountryCode,'ShipToAddress');
            this.shipToAccountObj.Id            = this.amendmentObj.Opportunity__r.Ship_To_Account__c;
            this.shipToAccountObj.BillingStreet = this.amendmentObj.Opportunity__r.Ship_To_Account__r.BillingStreet;
            this.shipToAccountObj.BillingCity   = this.amendmentObj.Opportunity__r.Ship_To_Account__r.BillingCity;
            //this.shipToAccountObj.BillingState  = this.amendmentObj.Opportunity__r.Ship_To_Account__r.BillingState;
            this.shipToAccountObj.BillingStateCode = this.amendmentObj.Opportunity__r.Ship_To_Account__r.BillingStateCode;
            this.shipToAccountObj.Billing_Address_Line_2__c = this.amendmentObj.Opportunity__r.Ship_To_Account__r.Billing_Address_Line_2__c;
            //this.billToAccountObj.BillingCountry = this.amendmentObj.Opportunity__r.Ship_To_Account__r.BillingCountry;
            this.shipToAccountObj.BillingCountryCode = this.amendmentObj.Opportunity__r.Ship_To_Account__r.BillingCountryCode;
            this.shipToAccountObj.BillingPostalCode = this.amendmentObj.Opportunity__r.Ship_To_Account__r.BillingPostalCode;         
        }
        if(this.isAccountNameUpdate){
            this.billToAccountObj.Id            = this.amendmentObj.Opportunity__r.Bill_To_Account__c;
            this.billToAccountObj.Name = this.amendmentObj.Opportunity__r.Bill_To_Account__r.Name;
        }
        if(this.isPONumberChange)
        {
            this.opportunityObj.Id = this.amendmentObj.Opportunity__c;
            this.opportunityObj.PO_Number__c = this.amendmentObj.Opportunity__r.PO_Number__c;
        }
        if(this.isBilltoContactDetailsChange){
            this.billToContactObj.Id = this.amendmentObj.Opportunity__r.Billing_Contact__c;
            this.billToContactObj.FirstName = this.amendmentObj.Opportunity__r.Billing_Contact__r.FirstName;
            this.billToContactObj.LastName = this.amendmentObj.Opportunity__r.Billing_Contact__r.LastName;
            this.billToContactObj.MobilePhone = this.amendmentObj.Opportunity__r.Billing_Contact__r.MobilePhone;
            this.billToContactObj.Email = this.amendmentObj.Opportunity__r.Billing_Contact__r.Email;
        }
        if(this.isVATRegistrationNumberChange){            
            if(this.amendmentObj.Old_Account_Tax_Number__r.Id != '' && this.amendmentObj.Old_Account_Tax_Number__r.Id != null && this.amendmentObj.Old_Account_Tax_Number__r.Id != undefined){                
                this.accTaxObj.Id = this.amendmentObj.Old_Account_Tax_Number__r.Id;
                this.accTaxObj.Tax_ID__c = this.amendmentObj.Old_Account_Tax_Number__r.Tax_ID__c;
            }
        }
    }

    /**  CUSTOM BILLING HELPER */
    setCustomBillingList()
    {
        let tempCustomBillingList = [];
        if(this.validateNoOfpaymentChange() == true)
        {            
            let equalPercent = this.totalNoOfPayment && this.totalNoOfPayment>0? parseFloat(100/this.totalNoOfPayment).toFixed(2):100;        
            for(let i=0;i<this.totalNoOfPayment;i++)
            {
                let paymentObj = { 
                    index :i,isLast:false,datelabel:"Date "+(i+1),percentageLabel:"Percentage "+(i+1),
                    amountlabel:"Amount "+(i+1),date:new Date()
                }            
                paymentObj.date.setDate(this.dueDate.getDate() + (i*this.invoiceToBeIssuedBeforeInDays));
                paymentObj.date = paymentObj.date.toISOString().split('T')[0];
                paymentObj.percent = equalPercent;//.toFixed(2);
                // console.log('C Index'+(i+1)+' & '+this.totalNoOfPayment);
                if((i+1) == this.totalNoOfPayment) // Last Index
                {
                    // console.log('Last % '+equalPercent);
                    // console.log('Last '+(equalPercent*i));
                    paymentObj.isLast = true;
                    paymentObj.percent = (100 - (equalPercent*i));
                }
                paymentObj.formatedPercent = paymentObj.percent/100;
                tempCustomBillingList.push(paymentObj);
            }           
        }
        // console.log('tempCustomBillingList - '+JSON.stringify(tempCustomBillingList));
        this.customBillingList = tempCustomBillingList;
    }

    validateNoOfpaymentChange(){
        let allValid = true;
        if(this.totalNoOfPayment && this.totalNoOfPayment >12)
        {   
            allValid = false;
            this.showNotification('Error','Number of payments cannot be greater than 12','Error');
            // Add Error -
        }else if(this.totalNoOfPayment && this.totalNoOfPayment < 1)
        {   
            allValid = false;
            this.showNotification('Error','Number of payments cannot be less than 1','Error');
            // Add Error -
        }
        /*else
        {
            let totalAvilableDays =  this.invoiceToBeIssuedBeforeInDays*(this.totalNoOfPayment-1);
            let lastPaymentDate = new Date().setDate(this.dueDate.getDate() +totalAvilableDays);
            if(lastPaymentDate >= this.eventEditionStartDate ){
                allValid = false; 
                this.showNotification('Error','Please, select less number of payments, as the final payment date becomes greater than the edition start date','Error');
                // Add Error -
            }
        }*/
        return allValid;
    }

    validateAndResetPercent(index,value){
        if((value )>100)
        {   
            // Show Error ---
            // alert('Error....');
            this.showNotification('Error','Total percent cannot exceed 100%','Error');
        }
        else{   
            // this.customBillingList[index].percent = value*100;
            // this.customBillingList[index].formatedPercent = value;
            this.customBillingList[index].percent = value;

            let tempCustomBillingList = JSON.parse(JSON.stringify(this.customBillingList));
            let PrevoiusPercents = 0;
            let remainingPercent = 100;
            let remainingIndexs = this.totalNoOfPayment - parseInt(index+1);
            // console.log(this.totalNoOfPayment+' n : '+index+' remainingIndexs '+remainingIndexs);
            for(let i=0;i<this.totalNoOfPayment;i++)
            {
                if(i<=index)
                {
                    PrevoiusPercents = parseFloat(PrevoiusPercents) + parseFloat(tempCustomBillingList[i].percent);
                    // console.log(i+' PrevoiusPercents '+PrevoiusPercents);
                }else{ // Future payments                    
                    tempCustomBillingList[i].percent = ((100 - PrevoiusPercents)/remainingIndexs).toFixed(2);
                    // console.log(i+' New Percents '+tempCustomBillingList[i].percent);
                    if((i+1) == this.totalNoOfPayment) // Last Index
                    {
                        tempCustomBillingList[i].percent = remainingPercent;
                    }
                }
                tempCustomBillingList[i].formatedPercent = tempCustomBillingList[i].percent/100;
                remainingPercent = remainingPercent - (tempCustomBillingList[i].percent);
            }
            // console.log('tempCustomBillingList 2 - '+JSON.stringify(tempCustomBillingList));
            this.customBillingList = tempCustomBillingList;
        }
        
    }

    validateAndResetDate(index,value){
        this.customBillingList[index].date = value;
        /*
        if(value<this.eventEditionStartDate)
        {
            this.customBillingList[index].date = value;
        }else
        {
            this.showNotification('Error','Selected date cannot be greater than Edition start date','Error');
            // Add Error - date to be less than Edition Start date
        }*/
    }
    // On Load
    setCustomPaymentList(OppData){
        // console.log('setCustomPaymentList');
        let tempCustomBillingList = [];
        // let customBillingObj = JSON.parse(billingInfo);
        this.totalNoOfPayment = OppData.Total_No_of_payment__c;
        for(let i=0;i<this.totalNoOfPayment;i++)
        {
            let oppPercentFieldAPI = 'Milestone_'+(i+1)+'_Percent__c';
            let oppDateFieldAPI = 'Milestone_'+(i+1)+'_Delivery_Date__c';
            let paymentObj = { 
                index :i,isLast:false,datelabel:"Date "+(i+1),percentageLabel:"Percentage "+(i+1),
                amountlabel:"Amount "+(i+1),date:OppData[oppDateFieldAPI],percent:parseFloat(OppData[oppPercentFieldAPI]).toFixed(2),formatedPercent:parseFloat(OppData[oppPercentFieldAPI])/100
            }
            if((i+1) == this.totalNoOfPayment) // Last Index
            {
                // console.log('Last % '+equalPercent);
                // console.log('Last '+(equalPercent*i));
                paymentObj.isLast = true;                
            }
            tempCustomBillingList.push(paymentObj);
        }
        // console.log('Load tempCustomBillingList - '+JSON.stringify(tempCustomBillingList));
        this.customBillingList = tempCustomBillingList;
    }
    
    validateAndSetCustomPayments(){
        let isInvalidDate = false;
        let totalPercent =0;
        let payments = [];
        let oppTotal = this.opp.Amount?this.opp.Amount:0;
        this.customBillingList.forEach((payment)=>{
             //console.log('Check '+payment.index + ' - '+JSON.stringify(payment));
            payments.push({
                "Date":payment.date,
                "Percent":parseFloat(payment.percent).toFixed(2),
                "Amount":parseFloat(oppTotal*payment.formatedPercent).toFixed(2),
                "PaymentNumber":payment.index+1
            });
            totalPercent = (parseFloat(totalPercent) + parseFloat(payment.percent)).toFixed(2);
            // if(payment.date >= this.eventEditionStartDate){isInvalidDate = true;}
        });
        let paymentInfo = JSON.stringify(payments);
        let paymentInfoval = JSON.parse(paymentInfo);
        

        if(totalPercent == 100 && isInvalidDate == false){            
            this.opportunityObj['Custom_Payment__c'] = true;    
            this.opportunityObj['Total_No_of_payment__c'] = this.totalNoOfPayment;  
            this.opportunityObj['Payment_Schedule__c'] = 'custom';   
            
            for(let i=0;i<12;i++)
            {
                let index = i+1
                this.opportunityObj['Milestone_'+index+'_Delivery_Date__c'] = null;
                this.opportunityObj['Milestone_'+index+'_Percent__c'] = null;
                this.opportunityObj['Milestone_'+index+'_Amount__c'] = null;

                if(i < paymentInfoval.length)
                {
                    this.opportunityObj['Milestone_'+index+'_Delivery_Date__c'] = paymentInfoval[i].Date;
                    this.opportunityObj['Milestone_'+index+'_Percent__c'] = paymentInfoval[i].Percent;
                }
            }

            // console.log('Custom Billing opportunityObj  - '+JSON.stringify(this.opportunityObj));    
            // this.updateOpportunity(updateOBJ);
            return true;
        }
        /*
        else if(isInvalidDate == true){            
            this.showNotification('Error','Date can not be greater than edition start date','Error');
        }*/
        else
        {
            this.showNotification('Error','Please update all percent fields to get 100% as aggregate','Error');
            return false;
        }        
    }

    getValue(obj,nodeName)
    {
        // console.log('Get val '+nodeName+' in '+JSON.stringify(obj));
        let val;
        if(nodeName.includes('.')){
           val = this.getValue(obj[nodeName.split('.')[0]],nodeName.split('.').slice(1).join('.'));
        }else{
            val = obj[nodeName];
        }
        return val;
    }
    //#endregion
    
    //#region ***********  Component Get Functions *********/
    get showCustomBillingInput(){
        return this.customBillingList.length >0 ? true:false;
    }

    /*get formatedDueDate(){
        return new Date().toISOString();
    }*/
    get isBillingAddressChange(){
        return this.stageProcessingOrder.includes(BillingAddressChange)?true:false;
    }
    get isShippingAddressChange(){
        return this.stageProcessingOrder.includes(ShippingAddressChange)?true:false;
    }
    get isPONumberChange(){
        return this.stageProcessingOrder.includes(PONumberChange)?true:false;
    }
    get isBillToAccountChange(){
        return this.stageProcessingOrder.includes(BillToAccountChange)?true:false;
    }
    get isShipToAccountChange(){
        return this.stageProcessingOrder.includes(ShipToAccountChange)?true:false;
    }
    get isUpdateBillToContact(){
        return (this.stageProcessingOrder.includes(UpdateBillToContact))?true:false;
    }
    get isAccountNameUpdate(){
        return this.stageProcessingOrder.includes(AccountNameChange)?true:false;
    }
    get isBilltoContactDetailsChange(){
        return this.stageProcessingOrder.includes(BillToContactDetailsChange)?true:false;
    }
    get isVATRegistrationNumberChange(){
        return this.stageProcessingOrder.includes(VATRegistrationNumberChange)?true:false;
    }
    get isBillingScheduleChange(){
        return this.stageProcessingOrder.includes(BillingScheduleChange)?true:false;
    }
    get isTaxExemptRebill(){
        return this.stageProcessingOrder.includes(TaxExemptRebill)?true:false;
    }
    get isCampaignRunDatesChange(){
        return this.stageProcessingOrder.includes(CampaignRunDatesChange)?true:false;
    }    
    get isFullCancellation(){
        return this.stageProcessingOrder.includes(Cancellation)?true:false;
    }
    get isNextDisabled(){
        return false;//this.selectedInvs && Array.isArray(this.selectedInvs) && this.selectedInvs.length>0?false:true;
    }
    get amendmentTableCSSClass (){
        return this.isReadOnlyMode ? TableClass+' read-only-table' :TableClass;
    }
    get currentDataRowHeader(){
        return this.isReadOnlyMode ?'Field Value':'Old Value';
    }
    get isBillToPostalCodeRequired() // [GECI-1142] && [GECI-577]
    {
        let flag = false;
        let countryCode = this.billToAccountObj? this.billToAccountObj.BillingCountryCode:'';
        const requiredZipCodeCountriesList = this.requiredPostalcodeCountryCSV[this.amendmentObj.Edition__r.X3rd_Party_ERP_System__c]?this.requiredPostalcodeCountryCSV[this.amendmentObj.Edition__r.X3rd_Party_ERP_System__c].split(','):[];
        //console.log(JSON.stringify(this.billToAccountObj) +countryCode+' - '+requiredZipCodeCountriesList);
        if(countryCode && requiredZipCodeCountriesList.includes(countryCode))
        {
            flag = true;
        }
        return flag;
    }

    get isShipToPostalCodeRequired() // [GECI-1142] && [GECI-577]
    {
        let flag = false;
        let countryCode = this.shipToAccountObj? this.shipToAccountObj.BillingCountryCode:'';
        const requiredZipCodeCountriesList = this.requiredPostalcodeCountryCSV[this.amendmentObj.Edition__r.X3rd_Party_ERP_System__c]?this.requiredPostalcodeCountryCSV[this.amendmentObj.Edition__r.X3rd_Party_ERP_System__c].split(','):[];
        if(countryCode && requiredZipCodeCountriesList.includes(countryCode))
        {
            flag = true;
        }
        return flag;
    }
    
    get isPaymentSchedulefromOpp(){
        return this.amendmentObj.Opportunity__r.Payment_Schedule__c?true:false
    }

    get isRICDwithFinancialChange() // Show Invoices with cancel option
    {                   // GECI-1713
       return this.hasInvoicePlanProducts == false && (this.stageProcessingOrder.includes(BillToAccountChange) || this.stageProcessingOrder.includes(ShipToAccountChange) || this.stageProcessingOrder.includes(UpdateBillToContact)) ?true:false;
    }

    get isAmedmentOpportunityCreated(){
        return this.amendmentObj.Amended_Opportunity__c?true:false;
    }

    get isGroup1() // Cancellation
    {
       return this.currentAmendmentGroupNo === 1 ?true:false;
    }

    get isGroup2() // With New Amendment opportunity
    {
       return this.currentAmendmentGroupNo === 2 ?true:false;
    }

    get isGroup3() // All other [RICD + Cancel & Rebill] - Default
    {
       return this.currentAmendmentGroupNo === 3 ?true:false;
    }

    //#endregion

    //#region ************ Wire functions ****************/

    @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
    objectInfo({ error, data }) {
        if (data) {
            this.defaultRecordTypeId = data.defaultRecordTypeId;
        } else if (error) {
            this.error = error;
        }
    };

    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: BillingCountryCode })
    countryData({ error, data }) {
        if (data) {
            var countryOptions = [];
            for (var i = 0; i< data.values.length; i++) {
                var countryValue = data.values[i];
                var opt = { label: countryValue.label, value: countryValue.value};
                countryOptions.push(opt);
            }
            this.countryOptions = countryOptions;
        } else if (error) {
            this.error = error;
        }
    };

    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: BillingStateCode })
    stateData({ error, data }) {
        if (data) {
            for (var key in data.controllerValues) {
                var controllingKey = data.controllerValues[key]+"";
                this.controllerValues[key] = controllingKey;
                this.controlledValues[controllingKey] = [];
            }
            for (var i = 0; i< data.values.length; i++) {
                var stateValue = data.values[i];
                var opt = { label: stateValue.label, value: stateValue.value};
                for (var j = 0; j< stateValue.validFor.length; j++) {
                    var controllingKey = stateValue.validFor[j]+"";
                    this.controlledValues[controllingKey].push(opt);
                }
            }
            // let billingCountryCode = this.amendmentObj.Opportunity__r.Bill_To_Account__r? this.amendmentObj.Opportunity__r.Bill_To_Account__r.BillingCountryCode:'';
            // this.loadStateOfCountryChangeByCode(billingCountryCode);            
            this.getAllMetaData();        
        } else if (error) {
            this.error = error;
        }
    };

    @wire(getGoogleApiMetaData)
    GoogleApiMetaData({ error, data }) {
        if(data){
            this.googleApiFieldMap = data;
        }else if(error){
            console.log('GoogleApiMetaData Error',error);
        }
    }
    //#endregion

    //#region ******** Notification/Toast ********/
    showNotification(title,message,variant)
    {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant?variant:'success'
        });
        this.dispatchEvent(evt);        
    }
    //#endregion

    //#region *********** Apex Calls  ***************/
    /*
    updateOpportunity(updateOBJ) {
        updateRecord({fields:updateOBJ})
            .then(() => {                
                this.showNotification('Success','Custom Billing updated','Success');
                this.showSpinner = false;
            })
            .catch(error => {
                this.showNotification('Error','Error updating record '+error.body.message,'Error');
                this.showSpinner = false;              
            });
    }*/
     // Get Opportunity Record
     getOppDetails()
     {    
       //new change
         fetchOpportunityRecord({fields:this.oppQueryFields,oppId:this.amendmentObj.Opportunity__c})
         .then(data=>{
            //   console.log('Opportunity data - '+JSON.stringify(data));
             this.opp = data;
            // console.log('opprecordId - '+data.Id);
            if(this.isBillingScheduleChange){                
            this.setCustomPaymentList(data);
            }
         })
         .catch(error=>{            
             console.log('error in getOppDetails '+error);
         })        
     }
    listMetaData = [];
    // MetaData Query
    getAllMetaData(){
        getAmdDetails()
            .then(data => {
                this.listMetaData = data;
                // console.log("listMetaData data ==",JSON.stringify(data));
                this.getCRData(true);
            })
            .catch(error2 => {
                console.log('Some Error Occured in getAllMetaData');
            });
    }
    
    // get Amendment types where Invoice List Screen will be displayed
    amendmentTypesforInvoiceSelectionScreen ='';
    getAmendTypes4InvScreen()
    {
        let keyVal = 'AmendmentTypes4InvoiceScreen';        
        getglobalConsVal({key:keyVal})
        .then(result=>{
            //console.log('AmendmentTypes4InvoiceScreen - '+result);
            this.amendmentTypesforInvoiceSelectionScreen = result;
        })
        .catch(error=>{            
            console.log('error in amendmentTypesforInvoiceSelectionScreen'+error);
        })
    }

    // amendmentObj Query
    getCRData(onLaod){
        getAmendmentDetails({changeRequestId:this.recordId})
            .then(data => {
                this.amendmentObj = data;
                this.parentOppId = data.Opportunity__c;
                this.hasInvoicePlanProducts = data.Comments__c && parseInt(data.Comments__c) > 0 ?true:false;
                this.setOrderforAmedmentExecution();
                if(this.amendmentObj.Change_Request_Status__c === 'Approved'){
                    this.showAmendmentDataForm = true;
                }
                if(this.amendmentObj.Change_Request_Status__c === 'Amend Data Complete'){
                    this.onAmendDataComplete();
                }
                // [GECI-941]
                if(this.amendmentObj.Change_Request_Status__c === 'Completed'){
                    this.currentAmendmentGroupNo = 3;
                    this.showAmendmentDataForm = true;
                    this.isReadOnlyMode = true;
                    this.openAllaccordions();
                }

                // console.log("amendmentObj data ==",JSON.stringify(data));
                this.setDefaultValues();
                // setTimeout(() => {
                //     this.setDefaultValues();
                // },2500);
                
                setTimeout(() => {
                    this.showSpinner = false;
                },2500);
                
            })
            .catch(error2 => {
                this.showSpinner = false;
                console.log('Some Error Occured in getAmendmentDetails');
            });
    }

    opportunityOrderList = [];
    //  get All Orders [GECI-776]
    getOppAllOrders(oppId)
    {
        fetchAllordersAndProducts({oppId:oppId})
        .then(data=>{
            //  console.log('opportunityOrder data - '+JSON.stringify(data));
            this.opportunityOrderList = data;
            this.setOrderProductValues();       
        })
        .catch(error=>{            
            console.log('error in fetchAllordersAndProducts '+error);
        })        
    } 

    getPaymentSchOptions(){
    getPaymentSch({oppId : this.amendmentObj.Opportunity__c})
        .then(data => {
            var options = [];
            for (var i = 0; i< data.length; i++) {
                if(data[i] != 'Custom'){
                    var opt = { label: data[i], value: data[i]};
                    options.push(opt);
                }
            }
            this.paymentvalues = options;
        })
        .catch(error => {

        });
    }

    fetchAllInvs()
    {
        this.invoiceToCancel = [];
        this.showSpinner = true;
        let amdobj = {Id:this.amendmentObj.Id,Opportunity__c:this.amendmentObj.Opportunity__c}
        getInvDetails({changeReqobj :amdobj})
            .then(data => {
                let listsObj = JSON.parse(data);
                if(listsObj.Invoices.length>0){
                    this.showSpinner = false;
                    // console.log('data',data);                
                    listsObj.Invoices.forEach((row,i) => {
                        this.invoiceToCancel.push({Id:row.Id,name:row.Name,status:row.blng__InvoiceStatus__c, ERPRefNo:row.ERP_Reference__c, dueDate:row.blng__DueDate__c, amount:row.blng__TotalAmount__c,invoiceDate:row.blng__InvoiceDate__c,index:i});
                    });
                    this.isOpenInvCancleModal = true;
                    //console.log('invoiceToCancel - ' + JSON.stringify(this.invoiceToCancel));
                }else{
                    console.log('No Invoices found to Cancle');
                    this.cancleInvoice();
                }                
            })
            .catch(error => {
                this.showSpinner = false;
            });
    }
    // Get Global Constant values
    getConstantCSV(keyVal)
    {      
        getglobalConsVal({key:keyVal})
        .then(result=>{
            // console.log(keyVal+' - '+result);
            if(keyVal== 'CountriesWithoutPostalCode'){
                this.nonZipCodeCountries = result;                 
            }else if(keyVal== 'CountriesWithRequiredState'){
                this.countriesWithReqState = result;
            }
            if(keyVal == 'LegalEntitiesCodeCSV'){
                this.legalentitycode = result;
            }
            if(keyVal == 'RequiredPostalCode_Oracle'){
                this.requiredPostalcodeCountryCSV['Oracle'] = result;
            }
            if(keyVal == 'RequiredPostalCode_SAP'){
                this.requiredPostalcodeCountryCSV['SAP'] = result;
            }
        })
        .catch(error=>{            
            console.log('error in getConstantCSV '+error);
        })        
    }
    // Cancel Invoices
    cancelSelectedInvs() // Pre Save
    {      
        console.log('In cancelSelectedInvs..');
        cancleSingleInvoies({invIds:this.selectedInvs})
        .then(data => {
            if(this.isFullCancellation == false){
                // console.log('JOb ID'+data);
                if(data) // Async Process .. need Waiting
                {
                    this.checkAsyncJobStatus(data);
                }else{
                    console.log ('Error in executing CancelRebillInvoices Batch ');
                }
            }else{
                this.updateAmedmentReq(this.amendmentObj.Id,{Invoice_To_Cancel__c:this.selectedInvs.join(','),Change_Request_Status__c:"Amend Data Complete"});
                //this.amendmentObj.Change_Request_Status__c = 'Amend Data Complete';
                this.showSpinner = false;
            }
        })
        .catch(error =>{
            this.showSpinner = false;
            console.log('Error in cancleInvoice..');
            this.showNotification('Error','An error occurred, please contact your system administrator.','Error');
        });
    }

    // Pre Amend Data Compete Call for Hold Billing & Cancel Invoices
    cancleOrder() // Pre Save
    {        
        let amdobj = {Id:this.amendmentObj.Id,Opportunity__c:this.amendmentObj.Opportunity__c,Order_IDs__c:this.amendmentObjToSave.Order_IDs__c}
        console.log('CancleOrders..');
        fullCancel({changeReqobj:amdobj,listtoCancelInvId:this.selectedInvs})
        .then(data => {
           
            // console.log('JOb ID'+data);
            if(data) // Async Process .. need Waiting
            {
                this.checkAsyncJobStatus(data);
            }else{
                if(this.isFullCancellation == false){
                    this.updateAllObjData();
                }else{
                    this.updateAmedmentReq(this.amendmentObj.Id,{Change_Request_Status__c:"Amend Data Complete"});                    
                    this.showSpinner = false;
                }
            }            
        })
        .catch(error =>{
            this.showSpinner = false;
            console.log('Error in cancleInvoice..');
            this.showNotification('Error','An error occurred, please contact your system administrator.','Error');
        });
    }

    updateAllObjData()
    {        
        console.log('Updating Amendment Data ....');
        this.amendmentObjToSave.Current_Processing_Step__c = 'Step 2';   
        let objwrap = {
            'amendmentObj' : this.amendmentObjToSave,
            'opportunityObj' : this.opportunityObj,
            'billToAccountObj' : this.billToAccountObj,
            'shipToAccountObj' : this.shipToAccountObj,
            'billToContactObj' : this.billToContactObj,
            'accTaxObj' : this.accTaxObj,
            'orderItemsObj':this.orderItemList,
            'billToAccountTransObj':this.billToAccTransObj,
            'shipToAccountTransObj':this.shipToAccTransObj
        };
        console.log('data JSON ....'+JSON.stringify(objwrap));
        this.disableUpdate = true;
        saveObjData({dataObjJSON: JSON.stringify(objwrap)})
        .then(data => {
            if(data && data === 'Success')
            {
                if(this.hasPostSaveProcess){
                    this.reBill();
                }else{
                    // Add Tosat.
                    //this.amendmentObj.Change_Request_Status__c = 'Amend Data Complete';
                    this.showSpinner = false;
                    this.showNotification('Success','Amendment data processed successfully');
                    if(!this.hasPriorGroupProcess()){
                        // console.log('hasPriorGroupProcess ..');
                        this.updateAmedmentReq(this.amendmentObj.Id,{Change_Request_Status__c:"Amend Data Complete"});
                    }
                }
                
            }else{
                this.showSpinner = false;
                this.disableUpdate = false;
                this.showNotification('Error in Amendment data Update',data,'Error');
                console.log(data);
            }
        })
        .catch(error2 => {
            this.showSpinner = false;
            this.disableUpdate = false;
            this.showNotification('Error','Some Error Occured in amendment data Update','Error');
            console.log('Error in updateAllObjData..');
        });    
    }

    // Requque Order & Un Hold OLI [Post AmendData Complete]
    reBill() // Post Save
    {   
        console.log('ReBill....');
        let amdobj = {Id:this.amendmentObj.Id,Opportunity__c:this.amendmentObj.Opportunity__c,Order_IDs__c:this.amendmentObjToSave.Order_IDs__c}
        reBillOrder({amendmentOBJ:amdobj})
        .then(data => {            
            this.showSpinner = false;
            this.showNotification('Success','Amendment Data Processed Successfully');
            if(!this.hasPriorGroupProcess()){
                this.updateAmedmentReq(this.amendmentObj.Id,{Change_Request_Status__c:"Amend Data Complete"});
            }
        })
        .catch(error =>{
            this.showSpinner = false;
            console.log('Error in reBillOrder..');
            this.showNotification('Error','An error occurred, please contact your system administrator.','Error');
        });
    }

    updateAmedmentReq(recordId,amdObj) {
        let updateOBJ = {};
        if(amdObj){
            updateOBJ=amdObj;
        }
        updateOBJ['Id'] = recordId;
        updateRecord({fields:updateOBJ})
        .then(() => { 
            setTimeout(() => {
                this.amendmentObj.Invoice_To_Cancel__c = amdObj.Invoice_To_Cancel__c;
                this.amendmentObj.Change_Request_Status__c = amdObj.Change_Request_Status__c;
                this.showAmendmentDataForm = false;
                if(amdObj.Change_Request_Status__c == 'Amend Data Complete'){
                    this.onAmendDataComplete();
                }
                if(amdObj.Change_Request_Status__c == 'Completed'){
                    this.getCRData(false);
                }
            }, 250);
        })
        .catch(error =>{            
            console.log('Error in updateAmedmentReq..');
            this.showNotification('Error','An error occurred, please contact your system administrator.','Error');
        });
    }

    // Requque Order & Un Hold OLI [Post AmendData Complete]
    afterAmendDataSync() // Post Save
    {   
        console.log('Complete Amendment process ...');
        let X3rdErp = this.amendmentObj.Edition__r.X3rd_Party_ERP_System__c;
        let amdobj = {  Id:this.amendmentObj.Id,
                        Opportunity__c:this.amendmentObj.Opportunity__c,
                        Amendment_Type__c:this.amendmentObj.Amendment_Type__c,
                        ERP_Ref_Numbers__c:this.amendmentObjToSave.ERP_Ref_Numbers__c,
                        Invoice_To_Cancel__c:this.amendmentObj.Invoice_To_Cancel__c,                        
                    }
        completeAmendment({amendmentOBJ:amdobj,externalerp:X3rdErp})
        .then(data => {
            this.showSpinner = false;
            if(data === 'Success'){
                this.showNotification('Success','Amendment Data Sync is queued');
                this.updateAmedmentReq(this.amendmentObj.Id,{Change_Request_Status__c:"Completed"});
            }else{
                this.showNotification('Error','An error occurred, please contact your system administrator.','Error');
            }                        
        })
        .catch(error =>{
            this.showSpinner = false;
            console.log('Error in completeAmendment..');
            this.showNotification('Error','An error occurred, please contact your system administrator.','Error');
        });
    }
    
    // Check Async Process
    totalProgress =0;
    checkAsyncJobStatus(jobId)
    {
        console.log('CheckAsyncJobStatus..');
        this._interval = setInterval(() => {
            getAsyncJobDetails({ batchId : jobId})
                .then(data => {
                    //console.log('checkAsyncJobStatus - ' +JSON.stringify(data));
                    let currentStatus = data.Status;                    
                    let totalJobItems = data['TotalJobItems'];
                    let allErrors = data['NumberOfErrors'];
                    let jobsProcessed = data['JobItemsProcessed'];                    
                    console.log('AsyncJobStatus - ' +jobsProcessed+'/'+totalJobItems);
                    /*
                    for(let i=0;i<this.batchStatus.length;i++){
                        if(this.batchStatus[i].label == currentStatus){
                            this.currentStep = this.batchStatus[i].step;
                            this.hasError = this.batchStatus[i].hasError;
                        }
                    }*/
                    // this.progress = this.jobsProcessed;
                    //this.processStatus = currentStatus + '...';
                    // console.log('currentStatus - '+currentStatus+' TOTAL P'+this.totalProgress);
                    if(this.totalProgress === 100 && currentStatus === 'Completed') 
                    {                       
                        clearInterval(this._interval);
                        // Do Stuff 
                        if(this.isFullCancellation == false){
                            this.updateAllObjData();
                        }else{
                            this.updateAmedmentReq(this.amendmentObj.Id,{Change_Request_Status__c:"Amend Data Complete"});                            
                            this.showSpinner = false;
                        }
                    }
                    else if(this.totalProgress !== 100 && totalJobItems !== 0){
                        this.totalProgress = Math.round((jobsProcessed/totalJobItems)*100);
                    }
                })
                .catch(error => {
                    this.error = error;
                });
        }, 3000);
    }

    invCrTableData =[];
    getInvoicesAndCreditNotes(){
        let oppId = this.amendmentObj.Opportunity__c;
        this.showSpinner = true;
        fetchInvAndCrNotes({opportnityId:oppId})
        .then(data=>{
            if(data)
            {
                let listsObj = JSON.parse(data);
                //console.log('listsObj '+JSON.stringify(listsObj));
              
               if(listsObj.Invoices.length >0 )
                {
                    this.invCrTableData = this.getInvoiceAndCreditNoteTableData(listsObj.Invoices);
                    this.showInvoiceSelectionModal = true;
                }else{
                    console.log('No Invoices Found ..');
                    this.isAmedDataConfirmAmendModal = true; // Show Confirmation Box
                }
            }
            this.showSpinner = false;
        })
        .catch(error=>{
            this.invCrTableData=[];
            this.showSpinner = false;
            this.showNotification('Error','An error occurred, please contact your system administrator.','Error');
        });           
    }

    redirectToNewAmedmentOpp(){        
        console.log('Redirect To New Amedment Opp..');
        let amdobj = {  Id:this.amendmentObj.Id,
                        Opportunity__c:this.amendmentObj.Opportunity__c,
                        Amendment_Type__c:this.amendmentObj.Amendment_Type__c,
                        Contract__c:this.amendmentObj.Opportunity__r.Main_Contract__c
                    }

        if(amdobj.Contract__c )
        {
            getAmendedOpportunity({changeReqobj:amdobj})
            .then(data=>{
                if(data)
                {
                    let newQuoteId = data;
                    this.showNotification('Success','New Amendment opportunity created.');
                    setTimeout(() => {
                        // Redirect to new QLE
                        this.navigatetoQLE(newQuoteId);
                    }, 250); 
                }
                this.showSpinner = false;
            })
            .catch(error=>{
                console.log('Unknown problem,error: ' + JSON.stringify(error));
                this.showNotification('Error','Failed to create a new Amendment opportunity. please contact your system administrator.','error');
                this.showSpinner = false;
            }); 
        }else{
            this.showNotification('Error','No contract found on the opportunity to create a new amendment opportunity.');
        }
    }

    processPCAI(){
        console.log('Process PC_AI..');
        let amdobj = {  Id:this.amendmentObj.Id,
                        Opportunity__c:this.amendmentObj.Opportunity__c,
                        Amendment_Type__c:this.amendmentObj.Amendment_Type__c,
                        Amended_Quote_Id__c:this.amendmentObj.Amended_Quote_Id__c
                    }

        if(amdobj.Amended_Quote_Id__c )
        {
            executePCAI({changeReqobj:amdobj})
            .then(data=>{                
                this.showNotification('Success','New Amendment opportunity created.');
                this.showSpinner = false;
                this.updateAmedmentReq(this.amendmentObj.Id,{Change_Request_Status__c:"Amend Data Complete"});
            })
            .catch(error=>{
                this.showSpinner = false;
                this.showNotification('Error','An error occurred, please contact your system administrator.','Error');
            }); 
        }else{
            this.showNotification('Error','No new amendment opportunity found.');
        }
    }
    navigatetoQLE(quoteId)
    {
        let redURL = '/apex/SBQQ__sb?id=' + quoteId + '#quote/le?qId=' + quoteId;
        console.log('redirecting to ...'+redURL);
        // window.open(redURL,'_blank');
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__webPage',
            attributes: {
                url: redURL
            }
        }).then((url) => {
            // console.log('new URL to ...'+url);
            window.open(url,'_top');
        });

    }

    billToAccTransOldObj ={};
    shipToAccTransOldObj ={};
    getAccTransData(accId,type){        
        let fields ='Id,Account__c,Translated_Account_Name__c,Translated_Billing_Address_Line_1__c,Translated_Billing_Address_Line_2__c,Translated_Billing_City__c,Translated_Billing_Country__c';
        fields  = fields +',Translated_Billing_State__c,Translation_Postal_Code__c,Translated_Billing_Address_Line_3__c';
        
        getaccTransRecordDetail({objectName:'Translated_Record__c',allFields:fields,accId:accId})
        .then(data=>{
            if(data.length>0){
                // console.log('Translation for '+type+JSON.stringify(data));
                if(type == 'Ship To'){
                    this.shipToAccTransOldObj = data[0];
                    this.shipToAccTransObj['Id'] = data[0].Id;
                }else{
                    this.billToAccTransOldObj = data[0];                    
                    this.billToAccTransObj['Id'] = this.billToAccTransOldObj.Id;                    
                }
            }
        })
        .catch(error=>{
           console.log('error in fetching Account tranlations');
        });
    }

    billToConTransOldObj ={};
    getconTransData(conId){        
        let fields ='Id,Contact__c,Translated_Contact_Salutation__c,Translated_Contact_FirstName__c,Translated_Contact_LastName__c,Translated_ContactTitle__c,Translated_EmailAddress__c';

        getconTransRecordDetail({objectName:'Translated_Record__c',allFields:fields,conId:conId})
        .then(data=>{
            if(data.length>0){
                this.billToConTransOldObj = data[0];
            }
        })
        .catch(error=>{
           console.log('error in fetching Contact tranlations');
        });
    }

    checkQuoteCalculationStatus()
    {
        console.log('geting QuoteCalculationInProgressFlag..');
        this._interval = setInterval(() => {
            getQuoteCalculationInProgressFlag({ oppId : this.amendmentObj.Opportunity__c})
                .then(data => {
                    console.log('Quote Calculation InProgress Flag - ' +data);
                    if(data == false) 
                    {
                        clearInterval(this._interval);
                        // Do Stuff 
                        this.afterAmendDataSync();
                    }                    
                })
                .catch(error => {
                    this.error = error;
                });
        }, 3000);
    }

    // **** Google Address Validation ***.
    billToAddressOptions = [];
    billToAddressClass= AddCloseClass;
    
    shipToAddressOptions = [];
    shipToAddressClass= AddCloseClass;

    displayGoogleAddressOptions(streetVal,type) {
        if(type =='BillToAddress'){
            this.isBillToAddressLoading = true;
            this.showBillToAddressOptions = true;
        }else{
            this.isShipToAddressLoading = true;
            this.showShipToAddressOptions = true;
        }
        
        console.log('DisplayGoogleAddressOptions');
        getGoogleAddressAutoComplete({searchKey:streetVal})
        .then(data => {
            // console.log('Address Options - '+data);
            var options = JSON.parse(data);            
            var predictions = options.predictions;
            var addresses = [];
            if (predictions.length > 0) {                
                for (var i = 0; i < predictions.length; i++) {
                    var bc = [];
                    addresses.push({
                        value: predictions[i].types[0],
                        PlaceId: predictions[i].place_id,
                        locaval: bc,
                        label: predictions[i].description
                    });
                }                
                if(type =='BillToAddress'){
                    this.billToAddressOptions = addresses;
                    if(this.billToAddressOptions.length > 0){
                        this.showBillToAddressOptions = true;
                    }
                    this.isBillToAddressLoading = false;
                }
                else if(type =='ShipToAddress')
                {
                    this.shipToAddressOptions = addresses;
                    if(this.shipToAddressOptions.length > 0){
                        this.showShipToAddressOptions = true;
                    }
                    this.isShipToAddressLoading = false;
                }
            }
        })
        .catch(error => {
            this.billToAddressOptions = [];
            this.isBillToAddressLoading = false;
            this.showBillToAddressOptions = false;
            this.error = error;
        });
    }
  
    setGooggleAddressDetails(PlaceId,addressType,street) 
    {
        getAddressDetails({placeId:PlaceId})
        .then(data => {
            let addressObj ={};
            var options = JSON.parse(data);
            var Addressdet = options.result;
            var key = "address_components";
            var googleApiMap = this.googleApiFieldMap;
            var o = Addressdet[key];
            var GoogleApiMetadata;
            //reset address fields
            addressObj.street = street;
            addressObj.city = '';
            addressObj.statecode = '';
            addressObj.zipcode = '';
            addressObj.countrycode = '';
            
            for (var prop in o) {
                for (var prop2 in o[prop].types) {
                    if (o[prop].types[prop2] == 'country') { 
                        addressObj.statecode = o[prop].short_name;
                        if(googleApiMap.hasOwnProperty(addressObj.statecode)){
                            GoogleApiMetadata = googleApiMap[o[prop].short_name];
                        }
                        else{
                            GoogleApiMetadata = googleApiMap['Default'];
                        }
                    }
                }
            }            
            var googleApiCity = GoogleApiMetadata.IOM_City__c;
            var cityNodes = [];
            if( googleApiCity.includes(',') ){
                cityNodes = googleApiCity.split(',');
            }
            else{
                cityNodes.push(googleApiCity);
            }
            
            for (var prop in o) {
                for (var prop2 in o[prop].types) {                    
                    // CITY                    
                    if (cityNodes.indexOf(o[prop].types[prop2]) != -1) { 
                        addressObj.street = addressObj.street.replace(new RegExp(', '+o[prop].long_name+','), ",").trim();
                        addressObj.street = addressObj.street.replace(new RegExp(', '+o[prop].short_name+','), ",").trim();
                        addressObj.street = addressObj.street.replace(new RegExp(', '+o[prop].short_name+'$'), ",").trim();                         
                        addressObj.city = o[prop].long_name;
                    }
                    // COUNTRY
                    if (o[prop].types[prop2] == GoogleApiMetadata.IOM_Country__c) {                        
                        addressObj.street = addressObj.street.replace(new RegExp(', '+o[prop].long_name + '$'), ",").trim();
                        addressObj.street = addressObj.street.replace(new RegExp(', '+o[prop].short_name + '$'), ",").trim();
                        
                        //only for USA
                        if(o[prop].short_name=='US'){
                            addressObj.street = addressObj.street.replace(new RegExp(', USA$'), "").trim();
                        }
                        else if(o[prop].short_name=='GB'){
                            addressObj.street = addressObj.street.replace(new RegExp(', UK$'), "").trim();
                        }
                        addressObj.countrycode = o[prop].short_name;                        
                        this.loadStateOfCountryChangeByCode(o[prop].short_name,addressType);
                    }
                    // STATE
                    if (o[prop].types[prop2] == GoogleApiMetadata.IOM_State__c) {
                        addressObj.street = addressObj.street.replace(new RegExp(o[prop].long_name + ','), ",").trim();
                        addressObj.street = addressObj.street.replace(new RegExp(o[prop].short_name + ','), ",").trim();
                        addressObj.statecode = o[prop].short_name;
                        if(o[prop].short_name.length>3){
                            addressObj.statecode = '';
                        }
                    }
                    // ZIP CODE
                    if (o[prop].types[prop2] == GoogleApiMetadata.IOM_Postal_Code__c) {
                        addressObj.street = addressObj.street.replace(new RegExp(o[prop].long_name + ','), ",").trim();
                        addressObj.street = addressObj.street.replace(new RegExp(o[prop].short_name + ','), ",").trim();
                        addressObj.zipcode = o[prop].short_name;
                    }
                }
            }
            
            addressObj.street = addressObj.street.trim().replace(new RegExp("([, ]+)" + '$'), "").trim();
            
            //replace city
            addressObj.street = addressObj.street.trim().replace(new RegExp("([, ]?)"+addressObj.city+ '$'), "").trim();
            
            //replace all commas from last
            addressObj.street = addressObj.street.trim().replace(new RegExp("([, ]+)" + '$'), "").trim();
            
            // Set values based on Account Type;
            // console.log(addressType+' Final Address - '+JSON.stringify(addressObj));
            if(addressType == 'BillToAddress')
            {
                let billToAccountObj2 = JSON.parse(JSON.stringify(this.billToAccountObj));
                this.billToAccountObj = {};                
                billToAccountObj2.BillingStreet = addressObj.street;
                billToAccountObj2.BillingCity = addressObj.city;
                billToAccountObj2.BillingCountryCode = addressObj.countrycode;
                billToAccountObj2.BillingStateCode = addressObj.statecode;
                billToAccountObj2.BillingPostalCode = addressObj.zipcode;
                let self = this;
                setTimeout(()=>{
                    self.billToAccountObj = billToAccountObj2;
                },0);
            }else if(addressType == 'ShipToAddress')
            {                
                let shipToAccountObj2 = JSON.parse(JSON.stringify(this.shipToAccountObj));
                this.shipToAccountObj = {};
                shipToAccountObj2.BillingStreet = addressObj.street;
                shipToAccountObj2.BillingCity = addressObj.city;
                shipToAccountObj2.BillingCountryCode = addressObj.countrycode;
                shipToAccountObj2.BillingStateCode = addressObj.statecode;
                shipToAccountObj2.BillingPostalCode = addressObj.zipcode;
                let self = this;
                setTimeout(()=>{
                    self.shipToAccountObj = shipToAccountObj2;
                },0);
            }
            
        })
        .catch(error => {
            this.error = error;
        });
    }

    //#endregion

    /*************** Info*********/
    /**** Amendment Type with only Reprint invoice with updated Changes [Non FC]**/
    // -- "PO number change" "Account Name Change", "VAT Registration Number Change", "Bill to Contact Details Change","Shipping Address Change","Billing Address Change"

    /**** Amendment Type Reprint invoice with updated Changes Or Rebill Option**/
    // -- "Bill To Account Change","Ship To Account Change","Update Bill To Contact"

    /**** Amendment Type with new Amnedment Opportunity and Rebill */
    // -- "Product Upgrade", "Product Downgrade", "Billing Schedule Change", "Number of Impressions Amendment"

    /****  Amendment Type with Full Cancel without Subscription */
    // -- "Cancellation"
}