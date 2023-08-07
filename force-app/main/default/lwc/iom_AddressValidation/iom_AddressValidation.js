import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, updateRecord} from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import getAddressAutoComplete from '@salesforce/apex/IOM_AddressValidation.getAddressAutoComplete';
import getAddressDetails from '@salesforce/apex/IOM_AddressValidation.getAddressDetails';
import getProfileName from '@salesforce/apex/IOM_AddressValidation.getProfileName';
import getAllowAccountAddressEdit from '@salesforce/apex/IOM_AddressValidation.getAllowAccountAddressEdit';
import getGoogleApiMetaData from '@salesforce/apex/IOM_AddressValidation.getGoogleApiMetaData';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getPicklistValues,getObjectInfo } from 'lightning/uiObjectInfoApi';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import BillingStateCode from '@salesforce/schema/Account.BillingStateCode';
import BillingCountryCode from '@salesforce/schema/Account.BillingCountryCode';
import LWCExternal from '@salesforce/resourceUrl/IOM_LWCExternal';
import { loadStyle } from 'lightning/platformResourceLoader';
import { NavigationMixin } from 'lightning/navigation';

const OpenClass = 'slds-size_2-of-3 slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open';
const CloseClass = 'slds-size_2-of-3 slds-dropdown-trigger slds-dropdown-trigger_click slds-combobox-lookup';

const editModeClass = 'slds-is-relative containerDiv';
const viewModeClass = 'slds-is-relative';

export default class AccAddForm extends NavigationMixin (LightningElement) {
    @api recordId;
    @api isEditMode = false;
    @api streetField;
    @api cityField;
    @api stateField;
    @api stateCodeField;
    @api zipCodeField;
    @api countryField;
    @api countryCodeField;
    @api sObjectname;

    @track addressData = {};
    @track error;
    @track dataId;
    @track accountRecord;
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
    activeSections = ['A','B','C'];
    recordFields;

    

    @wire(getRecord, { recordId: '$dataId', fields: '$recordFields'})
    accountData(value) {
        this.accountRecord = value;
        const { data, error } = value;
        if (data) {
            let addData = JSON.parse(JSON.stringify(data));
            //console.log('getRecord==',JSON.stringify(data));
            this.addressData.street = addData.fields[this.streetField].value;
            this.addressData.state = addData.fields[this.stateField].value;
            this.addressData.city = addData.fields[this.cityField].value;
            this.addressData.zipcode = addData.fields[this.zipCodeField].value;
            this.addressData.country = addData.fields[this.countryField].value;
            this.addressData.statecode = addData.fields[this.stateCodeField].value;
            this.addressData.countrycode = addData.fields[this.countryCodeField].value;
            this.error = undefined;
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
                        this.activeSections = ['A','B','C','D'];
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
            this.loadStateOfCountryChangeByCode(this.addressData.countrycode);
        } else if (error) {
            this.error = error;
        }
    };

    @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
    objectInfo({ error, data }) {
        if (data) {
            this.addressData.street = '';
            this.addressData.state = '';
            this.addressData.city = '';
            this.addressData.zipcode = '';
            this.addressData.country = '';
            this.addressData.statecode = '';
            this.addressData.countrycode = '';
            this.fieldsInfo = JSON.parse(JSON.stringify(data.fields));
            this.recordFields = [(this.sObjectname+"."+this.streetField),(this.sObjectname+"."+this.cityField),(this.sObjectname+"."+this.stateField),(this.sObjectname+"."+this.zipCodeField),(this.sObjectname+"."+this.countryField),(this.sObjectname+"."+this.stateCodeField),(this.sObjectname+"."+this.countryCodeField)];
            //console.log("this.recordFields===",this.recordFields);
            this.dataId = this.recordId;
            if(data.updateable == false){
                for (var key in this.fieldsInfo) {
                    this.fieldsInfo[key].updateable = false;
                }
            }
            this.defaultRecordTypeId = data.defaultRecordTypeId;
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
        this.addressData.street = event.target.value;
        //Debouncing this method: Do not actually fire the event as long as this function is
        //being called within a delay of DELAY. This is to avoid a very large number of Apex
        //method calls in components listening to this event.
        window.clearTimeout(this.delayTimeout);
        this.delayTimeout = setTimeout(() => {
            if(this.addressData.street && this.addressData.street.length>1){
                this.openListbox();
                this.displayOptionsLocation();
            }
            else if(this.addressData.street && this.addressData.street.length==0){
                this.addressData.city = '';
                this.addressData.statecode = '';
                this.addressData.zipcode = '';
                this.addressData.countrycode = '';
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
        this.addressData.city = event.target.value;
    }

    handleBlurPostal(event){
        this.addressData.zipcode = event.target.value;
    }

    handleSelect(event){
        this.isOptionClick = true;
        this.addressData.street = event.currentTarget.dataset.record;    
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
            this.addressData.city = '';
            this.addressData.statecode = '';
            this.addressData.zipcode = '';
            this.addressData.countrycode = '';

            for (var prop in o) {
                for (var prop2 in o[prop].types) {
                    if (o[prop].types[prop2] == 'country') { 
                        this.addressData.statecode = o[prop].short_name;
                        if(googleApiMap.hasOwnProperty(this.addressData.statecode)){
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
                    if (o[prop].types[prop2] == GoogleApiMetadata.IOM_State__c) {
                        this.addressData.street = this.addressData.street.replace(new RegExp(o[prop].long_name + ','), ",").trim();
                        this.addressData.street = this.addressData.street.replace(new RegExp(o[prop].short_name + ','), ",").trim();
                        this.addressData.statecode = o[prop].short_name;
                        if(o[prop].short_name.length>3){
                            this.addressData.statecode = '';
                        }
                    }
                    if (cityNodes.indexOf(o[prop].types[prop2]) != -1) { 
                        this.addressData.street = this.addressData.street.replace(new RegExp(', '+o[prop].long_name+','), ",").trim();
                        this.addressData.street = this.addressData.street.replace(new RegExp(', '+o[prop].short_name+','), ",").trim();
                        this.addressData.street = this.addressData.street.replace(new RegExp(', '+o[prop].short_name+'$'), ",").trim();                            
                        this.addressData.city = o[prop].long_name;
                    }
                    
                    if (o[prop].types[prop2] == GoogleApiMetadata.IOM_Country__c) {                        
                        this.addressData.street = this.addressData.street.replace(new RegExp(', '+o[prop].long_name + '$'), ",").trim();
                        this.addressData.street = this.addressData.street.replace(new RegExp(', '+o[prop].short_name + '$'), ",").trim();
                        
                        //only for USA
                        if(o[prop].short_name=='US'){
                            this.addressData.street = this.addressData.street.replace(new RegExp(', USA$'), "").trim();
                        }
                        else if(o[prop].short_name=='GB'){
                            this.addressData.street = this.addressData.street.replace(new RegExp(', UK$'), "").trim();
                        }
                        this.addressData.countrycode = o[prop].short_name;
                        this.loadStateOfCountryChangeByCode(o[prop].short_name);
                    }
                    if (o[prop].types[prop2] == GoogleApiMetadata.IOM_Postal_Code__c) {
                        this.addressData.street = this.addressData.street.replace(new RegExp(o[prop].long_name + ','), ",").trim();
                        this.addressData.street = this.addressData.street.replace(new RegExp(o[prop].short_name + ','), ",").trim();
                        this.addressData.zipcode = o[prop].short_name;
                    }
                }
            }

            this.addressData.street = this.addressData.street.trim().replace(new RegExp("([, ]+)" + '$'), "").trim();
            
            //replace city
            this.addressData.street = this.addressData.street.trim().replace(new RegExp("([, ]?)"+this.addressData.city+ '$'), "").trim();
            
            //replace all commas from last
            this.addressData.street = this.addressData.street.trim().replace(new RegExp("([, ]+)" + '$'), "").trim();
            
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
        this.addressData.countrycode = event.target.value;
        this.loadStateOfCountryChangeByCode(event.target.value);
    }

    handleChangeState(event){
        this.addressData.statecode = event.target.value;
    }

    openListbox() {
        if (typeof this.addressData.street === 'undefined' || this.addressData.street.length < 3) {
            this.listClass = CloseClass;
            return;
        }
        this.listClass = OpenClass;
    }

    displayOptionsLocation() {
        this.isShow = true;
        this.isShowDrp = true;
        getAddressAutoComplete({searchKey:this.addressData.street })
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
        fields["Id"] = this.recordId;
        fields[this.streetField] = this.addressData.street;
        fields[this.cityField] = this.addressData.city;
        fields[this.zipCodeField] = this.addressData.zipcode;
        fields[this.countryCodeField] = this.addressData.countrycode;
        fields[this.stateCodeField] = this.addressData.statecode;

        const recordInput = { fields };

        updateRecord(recordInput)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Account updated',
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