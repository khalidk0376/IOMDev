import { LightningElement, wire, track, api } from 'lwc';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
import { updateRecord } from 'lightning/uiRecordApi';
import { getRecord } from 'lightning/uiRecordApi';
import tabUserTypeObj from '@salesforce/schema/Tab_User_Type__c';
import eventTabObj from '@salesforce/schema/Event_Tabs__c';
import userType from '@salesforce/schema/Tab_User_Type__c.User_Type__c';
import productType from '@salesforce/schema/Event_Tabs__c.Booth_Product_Types__c';
import assignTabToUsers from '@salesforce/apex/IMCC_AssignTabs.assignTabToUsers';
import relatedData from '@salesforce/apex/IMCC_AssignTabs.relatedData';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import NoteOnProductTypeSelectionOnAssignVisibility from '@salesforce/label/c.NoteOnProductTypeSelectionOnAssignVisibility';
import NoteOnUserTypeOnlySelectionOnAssignVisibility from '@salesforce/label/c.NoteOnUserTypeOnlySelectionOnAssignVisibility';
import NoteOnUserTypeWithProdTypeSelectionOnAssignVisibility from '@salesforce/label/c.NoteOnUserTypeWithProdTypeSelectionOnAssignVisibility';

export default class Imcc_AssignTabVisibility extends LightningElement{

    label = {
        NoteOnProductTypeSelectionOnAssignVisibility,
        NoteOnUserTypeOnlySelectionOnAssignVisibility,
        NoteOnUserTypeWithProdTypeSelectionOnAssignVisibility
    };

    @track currentStep = null;
    @api recordId;
    @api fieldName;
    @api objectName;
    @api boothProductTypeFieldName;
    isBoothProductTypeAvailable = false;
    @track lstOptions = [];
    @track lstOptionsProd = [];
    lstSelectedUserType = [];
    lstSelectedProdType = [];
    values = [];
    valuesProd = [];
    lstOptionsTemp = [];
    isUserBtnDisable = false;
    isProductBtnDisable = false;
    @track recordFields;
    @track showPath=true;
            

    // Get Object Info.
    @wire(getObjectInfo, { objectApiName: tabUserTypeObj }) tabUserTypeObjInfo;
    @wire(getObjectInfo, { objectApiName: eventTabObj }) eventTabObjInfo;

    // Get Picklist values.
    @wire(getPicklistValues, { recordTypeId: '$tabUserTypeObjInfo.data.defaultRecordTypeId', fieldApiName: userType })
    userTypes(data, error) {
        if (data && data.data && data.data.values) {
            data.data.values.forEach(objPicklist => {
                this.lstOptionsTemp.push({
                    label: objPicklist.label,
                    value: objPicklist.value
                });
            });
            if(this.boothProductTypeFieldName){
                this.isBoothProductTypeAvailable = true;
            }
            this.recordFields = [(this.objectName+"."+this.boothProductTypeFieldName)];
            this.getAllRelatedData();
        } else if (error) {
            console.log(error);
        }
    };

    @wire(getPicklistValues, { recordTypeId: '$eventTabObjInfo.data.defaultRecordTypeId', fieldApiName: productType })
    productTypes(data, error) {
        if (data && data.data && data.data.values) {
            data.data.values.forEach(objPicklist => {
                this.lstOptionsProd.push({
                    label: objPicklist.label,
                    value: objPicklist.value
                });
            });
        } else if (error) {
            console.log(error);
        }
    };

    @wire(getRecord, { recordId: '$recordId', fields: '$recordFields' })
    wiredAccount({ error, data }) {
        if (data) {
            var boothProductType = data.fields[this.boothProductTypeFieldName].value;
            if (boothProductType != null) {
                boothProductType = boothProductType.split(';');
                this.valuesProd = [];
                this.lstSelectedProdType = [];
                boothProductType.forEach(boothtype => {
                    if (this.valuesProd.indexOf(boothtype) == -1) {
                        this.valuesProd.push(boothtype);
                        this.lstSelectedProdType.push(boothtype);
                    }
                });
            }
        }
    }

    getAllRelatedData() {
        relatedData({ fieldName: this.fieldName, recordId: this.recordId })
            .then(resultRD => {
                this.values = [];
                this.lstSelectedUserType = [];
                resultRD.forEach(data => {
                    if (this.values.indexOf(data.User_Type__c) == -1) {
                        this.values.push(data.User_Type__c);
                        this.lstSelectedUserType.push(data.User_Type__c);
                    }
                });
                this.lstOptions = this.lstOptionsTemp;
            }).catch(errorRD => {
                console.log('ERR errorRD' + JSON.stringify(errorRD));
            });
    }

    handleChangeUserType(event) {
        this.lstSelectedUserType = event.detail.value;
        this.values = event.detail.value;
    }

    handleChangeProdType(event) {
        this.lstSelectedProdType = event.detail.value;
        this.valuesProd = event.detail.value;
    }

    SaveSelectedNext() {
        this.isUserBtnDisable = true;
        this.isPopupVisible = false;
        assignTabToUsers({
            listUserTypes: this.lstSelectedUserType,
            recordId: this.recordId,
            fieldName: this.fieldName
        })
            .then(result => {
                if (this.isBoothProductTypeAvailable == true) {
                    this.showPath = false;
                    this.currentStep = "2"
                    let self = this;
                    setTimeout(function(){
                        self.showPath = true;
                    },250);
                    this.showSuccess();
                }
                else {
                    this.showSuccess();
                    this.closeAction();
                }
            })
            .catch(error => {
                this.error = error;
                console.log('Error ', error);
            });
    }

    SelectAllandNext() {
        this.isUserBtnDisable = true;
        this.lstSelectedUserType = [];
        this.values = [];
        this.lstOptions.forEach(opt => {
            this.lstSelectedUserType.push(opt.value);
            this.values.push(opt.value);
        });
        this.isPopupVisible = false;
        assignTabToUsers({
            listUserTypes: this.lstSelectedUserType,
            recordId: this.recordId,
            fieldName: this.fieldName
        })
            .then(result => {
                if (this.isBoothProductTypeAvailable == true) {
                    this.showPath = false;
                    this.currentStep = "2"
                    let self = this;
                    setTimeout(function(){
                        self.showPath = true;
                    },250);
                    this.showSuccess();
                }
                else {
                    this.showSuccess();
                    this.closeAction();
                }
            })
            .catch(error => {
                this.error = error;
                console.log('Error ', error);
            });
    }

    SaveSelectedProductType() {
        this.isProductBtnDisable = true;
        var fields = {};
        fields["Id"] = this.recordId;
        fields[this.boothProductTypeFieldName] = this.lstSelectedProdType.join(';');
        const recordInput = {
            fields: fields
        };
        updateRecord(recordInput)
            .then(() => {
                this.showSuccess();
                this.closeAction();
            })
            .catch(error => {
                this.error = error;
                console.log('Error ', error);
            });
    }

    SelectAllandSaveProductType() {
        this.isProductBtnDisable = true;
        this.lstSelectedProdType = [];
        this.valuesProd = [];
        this.lstOptionsProd.forEach(opt => {
            this.lstSelectedProdType.push(opt.value);
            this.valuesProd.push(opt.value);
        });
        this.isPopupVisible = false;
        var fields = {};
        fields["Id"] = this.recordId;
        fields[this.boothProductTypeFieldName] = this.lstSelectedProdType.join(';');
        const recordInput = {
            fields: fields
        };
        updateRecord(recordInput)
            .then(() => {
                this.showSuccess();
                this.closeAction();
            })
            .catch(error => {
                this.error = error;
                console.log('Error ', error);
            });
    }

    handleOnStepClick(event) {
        this.isUserBtnDisable = false;
        this.isProductBtnDisable = false;
        this.currentStep = event.target.value;
    }

    get isStepOne() {
        return this.currentStep === "1";
    }

    get isStepTwo() {
        return (this.currentStep === "2" || !this.fieldName);
    }

    closeAction() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    showSuccess() {
        const evt = new ShowToastEvent({
            title: 'Changes have been done successfully!',
            variant: 'success'
        });
        this.dispatchEvent(evt);
    }
}