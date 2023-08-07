import { LightningElement,api,track, wire } from 'lwc';
import {handleErrors, showToast} from 'c/lWCUtility';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';
import { getPicklistValues,getObjectInfo } from 'lightning/uiObjectInfoApi';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import BillingStateCode from '@salesforce/schema/Account.BillingStateCode';
import SALUTATION from '@salesforce/schema/Contact.Salutation';
import BillingCountryCode from '@salesforce/schema/Account.BillingCountryCode';
import getRecordDetail from '@salesforce/apex/CommonTableController.getRecordDetail2';
import isSSCBrazilRole from '@salesforce/apex/SSCDashboardLtngCtrl.isSSCBrazilUser';
import getaccTransRecordDetail from '@salesforce/apex/OrderDashboardController.getaccTransRecordDetail';
import getconTransRecordDetail from '@salesforce/apex/OrderDashboardController.getconTransRecordDetail';
import updateSobjDetails from '@salesforce/apex/OrderDashboardController.updateSobjDetails';
import getglobalConsVal from '@salesforce/apex/GlobalConstants.getValue';
import ID_FIELD from '@salesforce/schema/Order.Id';
import ORDTRANS_FIELD from '@salesforce/schema/Order.Order_Translation_Status__c';
export default class PendingOrderModal extends LightningElement {

    @api isOpenActionModal;
    @api isReadOnly;
    @api isOpenSecondModal = false;
    @api recordId;    
    @api objectName;
    @api showhide = false;
    @api sObjectname;
    @track error;
    @track showLoading = false;

    @track ordName;
    @track isDisabled;
    @track isSSCBrazilUser;
    @track spinner;

    @track dataId;
    @track fieldsInfo = {};
    @track countryOptions = [];
    @track stateOptions = [];
    recordFields;
    @track defaultRecordTypeId;
    controllerValues = {};
    controlledValues = {}; 
    @track salutationOptions = [];

    @track ordObj;
    @track conObj;
    @track accObj;
    @track ordstatus;

    accnameval;
    address1val;
    addressval;
    addresslineval;
    cityval;
    countryval;
    stateval;
    zipcodeval;
    salutation;
    firstname;
    lastname;
    titleval;
    emailval;

    orgaccnameval;
    orgaddress1val;
    orgaddressval;
    orgaddresslineval;
    orgcityval;
    orgzipcodeval;
    orgsalutation;
    orgfirstname;
    orglastname;
    orgtitleval;
    orgemailval;
    orgstatecode;
    orgcountrycode;
    orgcountry;

    // get list of countries where Zip is not required or State is required
    nonZipCodeCountries ='';
    countriesWithReqState ='';

    connectedCallback(){
       this.getConstantCSV('CountriesWithoutPostalCode');
       this.getConstantCSV('CountriesWithRequiredState');
    }

    getData(){
        isSSCBrazilRole()
        .then(result=>{
            this.isSSCBrazilUser = result;            
        })
        .catch(error=>{
            handleErrors(this,error)
        })
    }

    @api
    getOrdDetail(recordId){
        this.showLoading = true;        
        this.recordId = recordId;
        let fields ='Id,Order_Translation_Status__c,OrderNumber,blng__BillingAccount__c,blng__BillingAccount__r.BillingCountryCode,blng__BillingAccount__r.Billing_Address_Line_3__c,blng__BillingAccount__r.BillingStateCode,blng__BillingAccount__r.BillingStreet,blng__BillingAccount__r.Billing_Address_Line_2__c,blng__BillingAccount__r.Name,blng__BillingAccount__r.BillingCity,blng__BillingAccount__r.BillingCountry,blng__BillingAccount__r.BillingState,blng__BillingAccount__r.BillingPostalCode';

        fields  = fields +',BillToContactId,BillToContact.FirstName,BillToContact.LastName,BillToContact.Salutation,BillToContact.Title,BillToContact.Email';

        getRecordDetail({objectName:'Order',allFields:fields,recordId:recordId})
        .then(data=>{
            if(data.length>0){
                this.ordObj = data[0];
                this.ordstatus = data[0].Order_Translation_Status__c;
                this.ordName = data[0].OrderNumber;
                if(this.ordObj.blng__BillingAccount__r){
                    this.orgaccnameval = this.ordObj.blng__BillingAccount__r.Name;
                    this.orgaddress1val = this.ordObj.blng__BillingAccount__r.BillingStreet;
                    this.orgaddressval = this.ordObj.blng__BillingAccount__r.Billing_Address_Line_2__c;
                    this.orgaddresslineval = this.ordObj.blng__BillingAccount__r.Billing_Address_Line_3__c;
                    this.orgcityval = this.ordObj.blng__BillingAccount__r.BillingCity;
                    this.orgzipcodeval = this.ordObj.blng__BillingAccount__r.BillingPostalCode;
                    this.orgcountrycode = this.ordObj.blng__BillingAccount__r.BillingCountryCode;
                    this.orgcountry = this.ordObj.blng__BillingAccount__r.BillingCountry;
                    this.orgstatecode = this.ordObj.blng__BillingAccount__r.BillingStateCode;
                }
                if(this.ordObj.BillToContact){
                    this.orgsalutation = this.ordObj.BillToContact.Salutation;
                    this.orgfirstname = this.ordObj.BillToContact.FirstName;
                    this.orglastname = this.ordObj.BillToContact.LastName;
                    this.orgtitleval = this.ordObj.BillToContact.Title;
                    this.orgemailval = this.ordObj.BillToContact.Email; 
                }          
            }
            // console.log('this.orgstatecode',this.orgstatecode);
            // this.getData();
            this.checkrequiredfields();            
            this.getaccTransData();
            this.getconTransData();
        })
        .catch(error=>{
            handleErrors(this,error);
        });
    }

    @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
    objectInfo({ error, data }) {
        if (data) {
            this.defaultRecordTypeId = data.defaultRecordTypeId;
        } else if (error) {
            this.error = error;
        }
    };

    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: SALUTATION })
    salutationData({ error, data }) {
        if (data) {
            var salutationOptions = [];
            for (var i = 0; i< data.values.length; i++) {
                var salutationValue = data.values[i];
                var opt = { label: salutationValue.label, value: salutationValue.value};
                salutationOptions.push(opt);
            }
            // console.log('salutationOptions',salutationOptions);
            this.salutationOptions = salutationOptions;
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
            this.loadStateOfCountryChangeByCode(this.orgcountrycode);
        } else if (error) {
            this.error = error;
        }
    };

    loadStateOfCountryChangeByCode(countryCode){
        if(countryCode != null && countryCode != ''){
            var key = this.controllerValues[countryCode];
            var stateOptions = this.controlledValues[key];
            this.stateOptions = stateOptions;
        }
    }

    handleSalutationCountry(event){
        this.orgsalutation = event.target.value;
    }

    handleChangeCountry(event){
        this.orgcountrycode = event.target.value;
        this.loadStateOfCountryChangeByCode(event.target.value);
    }

    handleChangeState(event){
        this.orgstatecode = event.target.value;
    }

    handleLocalChangeState(event){
        this.stateval = event.target.value;
    }


    showhideval(){
        this.loadStateOfCountryChangeByCode(this.orgcountrycode);
        this.showhide = true;
    }
    
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
        })
        .catch(error=>{            
            console.log('error in getConstantCSV '+error);
        })        
    }

    /*
    * @description [This method is used to close the model]
    */
    closeModal() {
        this.isOpenActionModal = false;
        this.isOpenSecondModal = false;
        this.showhide = false;
    }

    getaccTransData(){
        let fields ='Id,Account__c,Translated_Account_Name__c,Translated_Billing_Address_Line_1__c,Translated_Billing_Address_Line_2__c,Translated_Billing_City__c,Translated_Billing_Country__c';

        fields  = fields +',Translated_Billing_State__c,Translation_Postal_Code__c,Translated_Billing_Address_Line_3__c';

        let accId = this.ordObj.blng__BillingAccount__c;
        
        getaccTransRecordDetail({objectName:'Translated_Record__c',allFields:fields,accId:accId})
        .then(data=>{
            if(data.length>0){
                this.accObj = data[0];
                this.accnameval = this.accObj.Translated_Account_Name__c;
                this.address1val = this.accObj.Translated_Billing_Address_Line_1__c,
                this.addressval = this.accObj.Translated_Billing_Address_Line_2__c;
                this.addresslineval = this.accObj.Translated_Billing_Address_Line_3__c;
                this.cityval = this.accObj.Translated_Billing_City__c;
                this.countryval = this.accObj.Translated_Billing_Country__c;
                this.stateval = this.accObj.Translated_Billing_State__c;
                this.zipcodeval = this.accObj.Translation_Postal_Code__c;
                // console.log('this.accObj',this.accObj);
            }
        })
        .catch(error=>{
            handleErrors(this,error);
        });
    }

    getconTransData(){
        let fields ='Id,Contact__c,Translated_Contact_Salutation__c,Translated_Contact_FirstName__c,Translated_Contact_LastName__c,Translated_ContactTitle__c,Translated_EmailAddress__c';

        let conId = this.ordObj.BillToContactId;

        getconTransRecordDetail({objectName:'Translated_Record__c',allFields:fields,conId:conId})
        .then(data=>{
            if(data.length>0){
                this.conObj = data[0];
                this.salutation = this.conObj.Translated_Contact_Salutation__c;
                this.firstname = this.conObj.Translated_Contact_FirstName__c;
                this.lastname = this.conObj.Translated_Contact_LastName__c;
                this.titleval = this.conObj.Translated_ContactTitle__c;
                this.emailval = this.conObj.Translated_EmailAddress__c;
            }            
            this.showLoading = false;
        })
        .catch(error=>{
            handleErrors(this,error);
        });

    }

    switchModal(){
        if(this.isInputValid() && this.isLocalInputValid()){
            this.isOpenActionModal = false;
            this.isOpenSecondModal = true;
            this.showhide = false;
        }
        
    }

    handlechange(event){
        if(event.target.name == "id1"){
            this.accnameval = event.target.value;
        }else if(event.target.name == "id2"){
            this.addressval = event.target.value;
        }
        else if(event.target.name == "id45"){
            this.addresslineval = event.target.value;
        }
        else if(event.target.name == "id3"){
            this.cityval = event.target.value;
        }else if(event.target.name == "id4"){
            this.countryval = event.target.value;
        }else if(event.target.name == "id6"){
            this.zipcodeval = event.target.value;
        }else if(event.target.name == "id7"){
            this.firstname = event.target.value;
        }else if(event.target.name == "id8"){
            this.lastname = event.target.value;
        }else if(event.target.name == "id9"){
            this.titleval = event.target.value;
        }else if(event.target.name == "id0"){
            this.emailval = event.target.value;
        }else if(event.target.name == "ida"){
            this.orgaccnameval = event.target.value;
        }else if(event.target.name == "idb"){
            this.orgaddressval = event.target.value;
        }
        else if(event.target.name == "idbz"){
            this.orgaddresslineval = event.target.value;
        }
        else if(event.target.name == "idb1"){
            this.orgaddress1val = event.target.value;
        }
        
        else if(event.target.name == "idc"){
            this.orgcityval = event.target.value;
        }else if(event.target.name == "idf"){
            this.orgzipcodeval = event.target.value;
        }else if(event.target.name == "idg"){
            this.orgfirstname = event.target.value;
        }else if(event.target.name == "idh"){
            this.orglastname = event.target.value;
        }else if(event.target.name == "idi"){
            this.orgtitleval = event.target.value;
        }else if(event.target.name == "idj"){
            this.orgemailval = event.target.value;
        }else if(event.target.name == "idb1"){
            this.orgaddress1val = event.target.value;
        }else if(event.target.name == "id21"){
            this.address1val = event.target.value;
        }
    }

    isLocalInputValid(){
        let isValid = true;
        let inputFields = this.template.querySelectorAll('.validatelocal');
        inputFields.forEach(inputField => {
            if(!inputField.checkValidity()){                    
                isValid = false;
            }
            inputField.reportValidity();
        });
        return isValid;
    }

    isInputValid() {
        let isValid = true;
        let inputFields = this.template.querySelectorAll('.validate');
        inputFields.forEach(inputField => {
            //let isValid = this.validateEng(inputField.value);
            //console.log(isValid+' Inp Deatils '+inputField.name+' - '+inputField.value);
            if(this.validateEng(inputField.value)){
                inputField.setCustomValidity('');
                if(!inputField.checkValidity()){                    
                    isValid = false;
                }
                inputField.reportValidity();
            }else{
                inputField.setCustomValidity('Please review the value of this field so that only includes characters from the ISO-8859-1 set.');
                inputField.reportValidity();
                isValid = false;              
            }
        });
        return isValid;
    }

    validateEng(str)
    {
        return !/[^\u0000-\u00ff]/g.test(str);
    }

    get isStateRequired(){ 
        // if(this.orgcountrycode == "US" || this.orgcountrycode == "GB")
        let flag = false;
        const conList = this.countriesWithReqState.split(',');
        // console.log(this.orgcountrycode+' Cons '+ JSON.stringify(conList));
        if(this.orgcountrycode && conList.includes(this.orgcountrycode))
        {
            flag = true;
        }
        return flag;
    }

    get isPostalCodeRequired()
    {
        let flag = true;
        const nonZipCodeCountriesList = this.nonZipCodeCountries.split(',');
        if(!this.orgcountrycode || this.orgcountrycode == "" || (this.orgcountrycode && nonZipCodeCountriesList.includes(this.orgcountrycode)))
        {
            flag = false;
        }
        return flag;
    }

    checkrequiredfields(){
        if(this.isNull(this.orgaccnameval) || this.isNull(this.orgaddress1val) ||
             this.isNull(this.orgcityval)  || this.isNull(this.orgcountrycode ) || 
             this.isNull(this.orgstatecode) || this.isNull(this.orgzipcodeval)|| 
             this.isNull(this.orgfirstname) || this.isNull(this.orglastname) || 
             this.isNull(this.orgemailval))
            {
                this.loadStateOfCountryChangeByCode(this.orgcountrycode);
                this.showhide = true;
            }
            else{
                this.chekEngValfields();
            }
    }

    chekEngValfields(){
        if(!this.validateEng(this.orgaccnameval) || !this.validateEng(this.orgaddress1val) ||
             !this.validateEng(this.orgcityval)  || !this.validateEng(this.orgcountrycode ) || 
             !this.validateEng(this.orgstatecode) || !this.validateEng(this.orgzipcodeval)|| 
             !this.validateEng(this.orgfirstname) || !this.validateEng(this.orglastname) || 
             !this.validateEng(this.orgemailval))
            {        
                this.loadStateOfCountryChangeByCode(this.orgcountrycode);     
                this.showhide = true; // Open In Edit Mode
            }
    }

    isNull(value)
    {
        return value == undefined || value == '' ?true:false;
    }

    updateRecords(){
        this.showLoading = true;
        // this.isOpenSecondModal = false;
        var trnaslatedobj = [];
        let obj1={
            Id : this.accObj?this.accObj.Id:null,
            Translated_Account_Name__c : this.accnameval,
            Translated_Billing_Address_Line_1__c : this.address1val,
            Translated_Billing_Address_Line_2__c : this.addressval,
            Translated_Billing_Address_Line_3__c : this.addresslineval,
            Translated_Billing_City__c : this.cityval,
            Translated_Billing_Country__c : this.orgcountry,
            Translated_Billing_State__c : this.stateval,
            Translation_Postal_Code__c : this.zipcodeval
        }
        if(obj1.Id){trnaslatedobj.push(obj1)}
        let obj2 ={
            Id : this.conObj?this.conObj.Id:null,
            Translated_Contact_Salutation__c : this.salutation,
            Translated_Contact_FirstName__c : this.firstname,
            Translated_Contact_LastName__c : this.lastname,
            Translated_ContactTitle__c : this.titleval,
            Translated_EmailAddress__c : this.emailval
        };
        if(obj2.Id){trnaslatedobj.push(obj2)}

        var conupdate = {
            Id : this.ordObj.BillToContactId?this.ordObj.BillToContactId:undefined,
            Salutation : this.orgsalutation,
            FirstName : this.orgfirstname,
            LastName : this.orglastname,
            Title : this.orgtitleval,
            Email : this.orgemailval
        };        
        var accupdate = {
            Id : this.ordObj.blng__BillingAccount__c?this.ordObj.blng__BillingAccount__c:undefined,
            Name : this.orgaccnameval,
            BillingStreet : this.orgaddress1val,
            Billing_Address_Line_2__c : this.orgaddressval,
            Billing_Address_Line_3__c : this.orgaddresslineval,
            BillingCity : this.orgcityval,
            BillingCountryCode : this.orgcountrycode,
            BillingStateCode : this.orgstatecode,
            BillingPostalCode : this.orgzipcodeval
        };
        // console.log('Calling Apex03');
        updateSobjDetails({
            transdata : trnaslatedobj.length>0?JSON.stringify(trnaslatedobj):'',
            condata : conupdate.Id?JSON.stringify(conupdate):'',
            accdata : accupdate.Id?JSON.stringify(accupdate):''
        })
        .then(result => {            
            if(result) {
                this.accnameval = "";
                this.address1val = "";
                this.addressval = "";
                this.addresslineval = "";
                this.cityval = "";
                this.countryval = "";
                this.stateval = "";
                this.zipcodeval = "";
                this.salutation = "";
                this.firstname = "";
                this.lastname = "";
                this.titleval = "";
                this.emailval = "";
            
                this.orgaccnameval = "";
                this.orgaddress1val = "";
                this.orgaddressval = "";
                this.orgaddresslineval = "";
                this.orgcityval = "";
                this.orgzipcodeval = "";
                this.orgsalutation = "";
                this.orgfirstname = "";
                this.orglastname = "";
                this.orgtitleval = "";
                this.orgemailval = "";
                this.orgstatecode = "";
                this.orgcountrycode = "";                
            }
            // this.showLoading = false;
        })
        .catch(error => {
            // this.showLoading = false;
            console.log('error',error);            
        });

            const fields = {};
            fields[ID_FIELD.fieldApiName] = this.ordObj.Id;
            fields[ORDTRANS_FIELD.fieldApiName] = "Completed";

            const recordInput = {
                fields : fields
            };

            updateRecord(recordInput).then((record) => {                
                let ev = new CustomEvent('refreshtable');
                this.dispatchEvent(ev); 
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success!',
                        message: 'Order updated successfully',
                        variant: 'success'
                    })
                )
                this.showLoading = false;
                this.isOpenSecondModal = false;
            })
            .catch(error =>{
                this.showLoading = false;
                this.isOpenSecondModal = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error!',
                        message: 'Something went wrong. Please Contact your Admin',
                        variant: 'error'
                    })
                )
            });
    }
}