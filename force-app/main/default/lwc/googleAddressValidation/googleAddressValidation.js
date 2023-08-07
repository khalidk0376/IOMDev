import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, updateRecord} from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import getProfileName from '@salesforce/apex/GoogleAddressValidationCtrl.getProfileName';
import getGoogleApiMetaData from '@salesforce/apex/GoogleAddressValidationCtrl.getGoogleApiMetaData';
import getAddressAutoComplete from '@salesforce/apex/GoogleAddressValidationCtrl.getAddressAutoComplete';
import getAddressDetails from '@salesforce/apex/GoogleAddressValidationCtrl.getAddressDetails';
import getAllowAccountAddressEdit from '@salesforce/apex/GoogleAddressValidationCtrl.getAllowAccountAddressEdit';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getPicklistValues,getObjectInfo } from 'lightning/uiObjectInfoApi';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import BillingStreet from '@salesforce/schema/Account.BillingStreet';
import BillingStreet2 from '@salesforce/schema/Account.Billing_Address_Line_2__c';
import BillingStreet3 from '@salesforce/schema/Account.Billing_Address_Line_3__c';
import BillingCity from '@salesforce/schema/Account.BillingCity';
import BillingState from '@salesforce/schema/Account.BillingState';
import BillingPostalCode from '@salesforce/schema/Account.BillingPostalCode';
import BillingCountry from '@salesforce/schema/Account.BillingCountry';
import BillingStateCode from '@salesforce/schema/Account.BillingStateCode';
import BillingCountryCode from '@salesforce/schema/Account.BillingCountryCode';
import CreatedById from '@salesforce/schema/Account.CreatedById';
import CreatedByName from '@salesforce/schema/Account.CreatedBy.Name';
import LastModifiedById from '@salesforce/schema/Account.LastModifiedById';
import LastModifiedByName from '@salesforce/schema/Account.LastModifiedBy.Name';
import CreatedDate from '@salesforce/schema/Account.CreatedDate';
import LastModifiedDate from '@salesforce/schema/Account.LastModifiedDate';
import ID_FIELD from '@salesforce/schema/Account.Id';
import LWCExternal from '@salesforce/resourceUrl/LWCExternal';
import { loadStyle } from 'lightning/platformResourceLoader';
import { NavigationMixin } from 'lightning/navigation';

const OpenClass = 'slds-size_2-of-3 slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open';
const CloseClass = 'slds-size_2-of-3 slds-dropdown-trigger slds-dropdown-trigger_click slds-combobox-lookup';

const editModeClass = 'slds-is-relative containerDiv';
const viewModeClass = 'slds-is-relative';

export default class AccAddForm extends NavigationMixin (LightningElement) {
    @api recordId;
    @api isEditMode = false;
    @track error;
    @track accountRecord;
    @track account;
    @track listClass = CloseClass;
    @track containerClass = viewModeClass;
    @track filteredOptions;
    @track isShow = false;
    @track isShowForm = false;
    @track isShowData = false;
    @track isShowDrp = false;
    @track defaultRecordTypeId;
    @track countryOptions = [];
    @track stateOptions = [];
    @track sObjectname = 'Account';
    @track isAllowEdit = false;
    @track fieldsInfo = {};
    @track rowsInfo = {};
    @track profileName = '';
    @track isShowAdminInfo = false;
    @track isSaving = false;
    @track googleApiFieldMap = [];
    controllerValues = {};
    controlledValues = {}; 
    isOptionClick = false;  
    delayTimeout;
    delaySave;
    delayBlur;
    activeSections = ['A','B'];
    @track tempRecordId;
    @track tempDefaultRecordTypeId;

    @wire(getRecord, { recordId: '$tempRecordId', fields: [CreatedById,CreatedDate,LastModifiedDate,CreatedByName,LastModifiedById,LastModifiedByName,BillingStreet,BillingStreet2,BillingStreet3,BillingCity,BillingState,BillingPostalCode,BillingCountry,BillingStateCode,BillingCountryCode] })
    accountData(value) {
        this.accountRecord = value;
        const { data, error } = value;
        if (data) {
            this.account = JSON.parse(JSON.stringify(data));
            this.error = undefined;
            this.defaultRecordTypeId = this.tempDefaultRecordTypeId;
            getAllowAccountAddressEdit()
            .then(data2 => {
                this.isAllowEdit = data2;                
            })
            .catch(error2 => {
                this.isAllowEdit = false;
            });
            getProfileName()
            .then(data3 => {
                this.profileName = data3;
                if(this.profileName == 'IM System Administrator' || this.profileName == 'System Administrator'){
                    this.isShowAdminInfo = true;
                    setTimeout(() => {
                        this.activeSections = ['A','B'];
                    }, 250);
                }
            })
            .catch(error3 => {
            });
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
            this.loadStateOfCountryChangeByCode(this.account.fields.BillingCountryCode.value);
        } else if (error) {
            this.error = error;
        }
    };

    @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
    objectInfo({ error, data }) {
        if (data) {
            this.fieldsInfo = JSON.parse(JSON.stringify(data.fields));
            if(data.updateable == false){
                for (var key in this.fieldsInfo) {
                    this.fieldsInfo[key].updateable = false;
                }
            }
            this.fieldsInfo.IM_Account_Number__c = false; // Changed Location [SFV-1152]
            this.tempRecordId = this.recordId;
            this.tempDefaultRecordTypeId = data.defaultRecordTypeId;
            this.isShowForm = true;
        } else if (error) {
            this.error = error;
        }
    };

    @wire(getGoogleApiMetaData)
    GoogleApiMetaData({ error, data }) {
        if(data){
            this.googleApiFieldMap = data;
        }else if(error){
            console.log('---',error);
        }
    }

    handleKeyUp(event) {
        this.account.fields.BillingStreet.value = event.target.value;
        //Debouncing this method: Do not actually fire the event as long as this function is
        //being called within a delay of DELAY. This is to avoid a very large number of Apex
        //method calls in components listening to this event.
        window.clearTimeout(this.delayTimeout);
        this.delayTimeout = setTimeout(() => {
            if(this.account.fields.BillingStreet.value && this.account.fields.BillingStreet.value.length>1){
                this.openListbox();
                this.displayOptionsLocation();
            }
            else if(this.account.fields.BillingStreet.value && this.account.fields.BillingStreet.value.length==0){
                this.account.fields.BillingCity.value = '';
                this.account.fields.BillingStateCode.value = '';
                this.account.fields.BillingPostalCode.value = '';
                this.account.fields.Billing_Address_Line_2__c.value = '';
                this.account.fields.Billing_Address_Line_3__c.value = '';
                this.account.fields.BillingCountryCode.value = '';
            }
        }, 750);
    }

    handleFocus(event) {
        this.listClass = CloseClass;
        this.isShowDrp = false;
    }

    handleBlur(event) {
        this.delayBlur = setTimeout(() => {
            if(this.isOptionClick){
                this.listClass = CloseClass;
                this.isShowDrp = false;
            }
            else{
                this.listClass = CloseClass;
                this.isShowDrp = false;
            }
        }, 500);
    }

    handleBlurCity(event){
        this.account.fields.BillingCity.value = event.target.value;
    }

    handleBlurPostal(event){
        this.account.fields.BillingPostalCode.value = event.target.value;
    }

    handleBlurLine1(event){
        this.account.fields.Billing_Address_Line_2__c.value = event.target.value;
    }

    handleBlurLine2(event){
        this.account.fields.Billing_Address_Line_3__c.value = event.target.value;
    }

    handleSelect(event){
        this.isOptionClick = true;
        this.account.fields.BillingStreet.value = event.currentTarget.dataset.record;    
        this.listClass = CloseClass;
        this.displayOptionDetails(event.currentTarget.dataset.placeid);
        this.isShowDrp = false;   
    }

    displayOptionDetails(PlaceId) {
        getAddressDetails({placeId:PlaceId})
        .then(data => {
            var options = JSON.parse(data);
            var Addressdet = options.result;
            var key = "address_components";
            var googleApiMap = this.googleApiFieldMap;
            var o = Addressdet[key];
            var GoogleApiMetadata;
            //reset address fields
            this.account.fields.BillingCity.value = '';
            this.account.fields.BillingStateCode.value = '';
            this.account.fields.BillingPostalCode.value = '';
            this.account.fields.BillingCountryCode.value = '';
            this.account.fields.Billing_Address_Line_3__c.value = '';
            this.account.fields.Billing_Address_Line_2__c.value = '';

            for (var prop in o) {
                for (var prop2 in o[prop].types) {
                    if (o[prop].types[prop2] == 'country') { 
                        this.account.fields.BillingStateCode.value = o[prop].short_name;
                        if(googleApiMap.hasOwnProperty(this.account.fields.BillingStateCode.value)){
                            GoogleApiMetadata = googleApiMap[o[prop].short_name];
                        }
                        else{
                            GoogleApiMetadata = googleApiMap['Default'];
                        }
                    }
                }
            }
            var googleApiCity = GoogleApiMetadata.City__c;
                var cityNodes = [];
                if( googleApiCity.includes(',') ){
                    cityNodes = googleApiCity.split(',');
                }
                else{
                    cityNodes.push(googleApiCity);
                }
            for (var prop in o) {
                for (var prop2 in o[prop].types) {
                    if (o[prop].types[prop2] == GoogleApiMetadata.State__c) {
                        this.account.fields.BillingStreet.value = this.account.fields.BillingStreet.value.replace(new RegExp(o[prop].long_name + ','), ",").trim();
                        this.account.fields.BillingStreet.value = this.account.fields.BillingStreet.value.replace(new RegExp(o[prop].short_name + ','), ",").trim();
                        this.account.fields.BillingStateCode.value = o[prop].short_name;
                        if(o[prop].short_name.length>3){
                            this.account.fields.BillingStateCode.value = '';
                        }
                    }
                    if (cityNodes.indexOf(o[prop].types[prop2]) != -1) { 
                        this.account.fields.BillingStreet.value = this.account.fields.BillingStreet.value.replace(new RegExp(', '+o[prop].long_name+','), ",").trim();
                        this.account.fields.BillingStreet.value = this.account.fields.BillingStreet.value.replace(new RegExp(', '+o[prop].short_name+','), ",").trim();
                        this.account.fields.BillingStreet.value = this.account.fields.BillingStreet.value.replace(new RegExp(', '+o[prop].short_name+'$'), ",").trim();                            
                        this.account.fields.BillingCity.value = o[prop].long_name;
                    }
                    
                    if (o[prop].types[prop2] == GoogleApiMetadata.Country__c) {            
                        this.account.fields.BillingStreet.value = this.account.fields.BillingStreet.value.replace(new RegExp(', '+o[prop].long_name + '$'), ",").trim();
                        this.account.fields.BillingStreet.value = this.account.fields.BillingStreet.value.replace(new RegExp(', '+o[prop].short_name + '$'), ",").trim();
                        
                        //only for USA
                        if(o[prop].short_name=='US'){
                            this.account.fields.BillingStreet.value = this.account.fields.BillingStreet.value.replace(new RegExp(', USA$'), "").trim();
                        }
                        else if(o[prop].short_name=='GB'){
                            this.account.fields.BillingStreet.value = this.account.fields.BillingStreet.value.replace(new RegExp(', UK$'), "").trim();
                        }
                        this.account.fields.BillingCountryCode.value = o[prop].short_name;
                        this.loadStateOfCountryChangeByCode(o[prop].short_name);
                    }
                    if (o[prop].types[prop2] == GoogleApiMetadata.Postal_Code__c) {
                        this.account.fields.BillingStreet.value = this.account.fields.BillingStreet.value.replace(new RegExp(o[prop].long_name + ','), ",").trim();
                        this.account.fields.BillingStreet.value = this.account.fields.BillingStreet.value.replace(new RegExp(o[prop].short_name + ','), ",").trim();
                        this.account.fields.BillingPostalCode.value = o[prop].short_name;
                    }
                }
            }

            this.account.fields.BillingStreet.value = this.account.fields.BillingStreet.value.trim().replace(new RegExp("([, ]+)" + '$'), "").trim();
            
            //replace city
            this.account.fields.BillingStreet.value = this.account.fields.BillingStreet.value.trim().replace(new RegExp("([, ]?)"+this.account.fields.BillingCity.value+ '$'), "").trim();
            
            //replace all commas from last
            this.account.fields.BillingStreet.value = this.account.fields.BillingStreet.value.trim().replace(new RegExp("([, ]+)" + '$'), "").trim();
            
            this.isOptionClick = false;
        })
        .catch(error => {
            this.error = error;
        });
    }

    loadStateOfCountryChangeByCode(countryCode){
        if(countryCode != null && countryCode != ''){
            var key = this.controllerValues[countryCode];
            var stateOptions = this.controlledValues[key];
            this.stateOptions = stateOptions;
        }
    }

    handleChangeCountry(event){
        this.account.fields.BillingCountryCode.value = event.target.value;
        this.loadStateOfCountryChangeByCode(event.target.value);
    }

    handleChangeState(event){
        this.account.fields.BillingStateCode.value = event.target.value;
    }

    openListbox() {
        if (typeof this.account.fields.BillingStreet.value === 'undefined' || this.account.fields.BillingStreet.value.length < 3) {
            this.listClass = CloseClass;
            return;
        }
        this.listClass = OpenClass;
    }

    displayOptionsLocation() {
        this.isShow = true;
        this.isShowDrp = true;
        getAddressAutoComplete({searchKey:this.account.fields.BillingStreet.value })
        .then(data => {
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
                this.filteredOptions = addresses;
                if(this.filteredOptions.length > 0){
                    this.isShowData = true;
                }
                this.isShow = false;
            }
        })
        .catch(error => {
            this.filteredOptions = [];
            this.isShow = false;
            this.isShowData = false;
            this.error = error;
        });
    }

    handleSubmit(event) {
        event.preventDefault();
        const fields = event.detail.fields;
        this.isSaving = true;
        this.updateAccount(fields);
    }

    handleCancel(event) {
        refreshApex(this.accountRecord);
        this.isEditMode = false;
        this.containerClass = viewModeClass;
    }

    updateAccount(fields) {
        //Debouncing this method: Do not actually fire the event as long as this function is
        //being called within a delay of DELAY. This is to avoid a very large number of Apex
        //method calls in components listening to this event.
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[BillingStreet.fieldApiName] = this.account.fields.BillingStreet.value;
        fields[BillingCity.fieldApiName] = this.account.fields.BillingCity.value;
        fields[BillingPostalCode.fieldApiName] = this.account.fields.BillingPostalCode.value;
        fields[BillingCountryCode.fieldApiName] = this.account.fields.BillingCountryCode.value;
        fields[BillingStateCode.fieldApiName] = this.account.fields.BillingStateCode.value;
        fields[BillingStreet2.fieldApiName] = this.account.fields.Billing_Address_Line_2__c.value;
        fields[BillingStreet3.fieldApiName] = this.account.fields.Billing_Address_Line_3__c.value;
        const recordInput = { fields };

        updateRecord(recordInput)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Account address updated',
                        variant: 'success'
                    })
                );
                this.isEditMode = false;
                this.containerClass = viewModeClass;
                this.isSaving = false;
                // Display fresh data in the form
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error updating record',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
                this.isSaving = false;
            });
    }

    connectedCallback(){
        loadStyle(this, LWCExternal);
    }

    editRecord(event){
        this.containerClass = editModeClass;
        refreshApex(this.accountRecord);
        this.isEditMode = true;
    }

    handleLinkClick(event){
        let id = event.currentTarget.dataset.id
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: id,
                actionName: 'view',
            },
        });
    }
}