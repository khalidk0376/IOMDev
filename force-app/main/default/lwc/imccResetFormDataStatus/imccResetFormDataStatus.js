import { LightningElement, track, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import QuickActionPanel from "@salesforce/resourceUrl/QuickActionPanel";
import { handleErrors, showToast, redirect } from 'c/imcc_lwcUtility';
import getFormData from '@salesforce/apex/IMCC_FormsCtrl.getFormData';
import resetFormStatus from '@salesforce/apex/IMCC_FormsCtrl.resetFormDataStatus';
import { loadStyle } from "lightning/platformResourceLoader";
import formResetAlertMsg from '@salesforce/label/c.Form_Status_Reset';

export default class ImccResetFormDataStatus extends LightningElement {
    @track sortedDirection = 'asc';
    @track sortedBy = 'formAllocName';
    @track searchKey = '';
    @track allSelectedRows = [];
    @track selectedRows = [];
    @track page = 1;
    @track items = [];
    @track startingRecord = 1;
    @track endingRecord = 0;
    @track pageSize = 50;
    @track totalRecountCount = 0;
    @track totalPage = 0;
    @track isPrev = true;
    @track isNext = true;
    @track isDisable = true;
    @track showSpinner = false;
    @track columns = [
        { label: 'Form Name', fieldName: 'formAllocName', type: 'text', sortable: true },
        { label: 'Form Heading', fieldName: 'formHeading', type: 'text', sortable: true },
        { label: 'Feature Category', fieldName: 'formFeatureCategory', type: 'text', sortable: true },
        { label: 'Type', fieldName: 'formType', type: 'text', sortable: true },
        { label: 'Form Entry', fieldName: 'formEntry', type: 'text', sortable: true },
        { label: 'Booth Number', fieldName: 'BoothNumber', type: 'text', sortable: true },
        { label: 'Status', fieldName: 'Status', type: 'text', sortable: true },

    ];
    isPageChanged = false;
    alltableData;
    tableData;
    rows = [];
    recordsIds = [];
    showModal = false;
    delayTimeout;
    label = {
        formResetAlertMsg,
    };

    _recordId;
    //Public property
    @api
    get recordId(){
       return this._recordId;
    }

    set recordId(value){
        this._recordId = value;
        this.allSelectedRows = [];
        this.getNonStartedFormData();
    }

    connectedCallback() {
        loadStyle(this, QuickActionPanel);
    }
    
    handleDialogClose() {
        this.showModal = false;
    }

    handleShowModal() {
        this.showModal = true;
    }

    handleResetStatus() {
        this.allSelectedRows.forEach(formId =>{
            this.items.forEach(form =>{
                if(form.Id == formId) {                     
                    this.rows.push(form);                      
                } 
            });
        });
        this.resetStatus(this.rows);
        this.showSpinner = true;
    }

    resetStatus(selectedrecords) {
        resetFormStatus({ formDataList: selectedrecords })
            .then(result => {
                let message = result;
                if (message == 'Success'){
                    showToast(this, 'Form Status has been successfully Reset', 'success', 'Success!');
                    this.showSpinner = false;
                    this.allSelectedRows = [];
                    this.closeAction();
                }
                else {
                    window.console.log(message);
                    showToast(this, message, 'error', 'Error!');
                }
                this.showSpinner = false;
            })
            .catch(error => {
                window.console.log('error...' + JSON.stringify(error));
                this.error = error;
                handleErrors(this, error);

            });
    }

    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    getNonStartedFormData() {
        getFormData({ cemId: this.recordId, searchKey: this.searchKey, sortBy: this.sortedBy, sortDirection: this.sortedDirection})
            .then(data => {
                this.isPageChanged = false;
                console.log('Form Data 1111111' + data);
                let formDataLists = [];
                this.tableData = [];
                this.items = [];
                data.forEach((row) => {
                    let formData = {};
                    formData.Id = row.Id;
                    formData.formAllocName = row.Forms_Permission__r.Form_Allocation__r.Name;
                    formData.formHeading = row.Forms_Permission__r.Form_Allocation__r.Form_Heading__c;
                    formData.formFeatureCategory = row.Forms_Permission__r.Form_Allocation__r.Feature_Category__c;
                    formData.formType = row.Forms_Permission__r.Form_Allocation__r.Form_Type__c;
                    formData.formEntry = row.Forms_Permission__r.Form_Allocation__r.Form_Entry__c;
                    if(row.Purchase_Data__c){
                        formData.BoothNumber = row.Purchase_Data__r.Booth_Number__c;
                    }
                    formData.Status = row.Status1__c;
                    formDataLists.push(formData);
                });

                /*let visibleFormDataIds = [];
                formDataLists.forEach(form =>{
                    visibleFormDataIds.push(form.Id);
                });

                let tempSelectedIds = JSON.parse(JSON.stringify(this.allSelectedRows))
                tempSelectedIds.forEach(formId =>{
                    if(visibleFormDataIds.indexOf(formId) == -1){
                        let index = this.allSelectedRows.indexOf(formId);
                        this.allSelectedRows.splice(index, 1);
                    }
                });*/

                this.items = formDataLists;
                this.totalRecountCount = formDataLists.length;
                this.totalPage = Math.ceil(this.totalRecountCount / this.pageSize);
                if(this.totalPage == 1){
                    this.page = 1;
                }
                this.displayRecordPerPage(this.page);
            })
            .catch(error => {
                console.error(error);
            });
    }

    //clicking on previous button this method will be called
    previousHandler() {
        this.isPageChanged = true;
        if(this.page > 1) {
            this.page = this.page - 1; //decrease page by 1
            this.displayRecordPerPage(this.page);
        }
    }

    //clicking on next button this method will be called
    nextHandler() {
        this.isPageChanged = true;
        if((this.page < this.totalPage) && this.page !== this.totalPage){
            this.page = this.page + 1; //increase page by 1
            this.displayRecordPerPage(this.page);
        }
    }

    //this method displays records page by page
    displayRecordPerPage(page) {
        this.isNext = (this.page == this.totalPage || this.totalPage == 0);
        this.isPrev = (this.page == 1 || this.totalRecountCount < this.pageSize);
        this.startingRecord = ((page - 1) * this.pageSize);
        this.endingRecord = (this.pageSize * page);
        this.endingRecord = ((this.endingRecord > this.totalRecountCount)?this.totalRecountCount:this.endingRecord);
        let data = this.items.slice(this.startingRecord, this.endingRecord);
        this.startingRecord = this.startingRecord + 1;
        this.selectedRows = [];
        data.forEach(form =>{
            if(this.allSelectedRows.indexOf(form.Id) != -1){
                this.selectedRows.push(form.Id);
            }
        });
        this.isDisable = (this.allSelectedRows.length == 0);
        this.tableData = data;
        let self = this;
        setTimeout(function(){
            self.isPageChanged = false;
        },500);
    }

    sortColumns(event) {
        this.sortedDirection = event.detail.sortDirection;
        this.sortedBy = event.detail.fieldName;
        this.getNonStartedFormData();
    }

    handleKeyChange(event){
        let searchValue = event.detail.value;
        window.clearTimeout(this.delayTimeout);
        this.delayTimeout = setTimeout(() => {
            this.searchKey = searchValue;
            console.log('Search Key ' + this.searchKey);
            this.getNonStartedFormData();
        }, 750);
    }
    
    onRowSelection(event) {
        if(!this.isPageChanged){
            this.processSelectedRows(event.detail.selectedRows);
        }
        this.isPageChanged = false;
    }

    processSelectedRows(selectedForm) {
        let selectedFormDataIds = [];
        selectedForm.forEach(form =>{
            selectedFormDataIds.push(form.Id);
            if(this.allSelectedRows.indexOf(form.Id) == -1){
                this.allSelectedRows.push(form.Id);
            }
        });

        let visibleFormDataIds = [];
        this.tableData.forEach(form =>{
            visibleFormDataIds.push(form.Id);
        });

        let tempSelectedIds = JSON.parse(JSON.stringify(this.allSelectedRows))
        tempSelectedIds.forEach(formId =>{
            if(visibleFormDataIds.indexOf(formId) != -1 && selectedFormDataIds.indexOf(formId) == -1){
                let index = this.allSelectedRows.indexOf(formId);
                this.allSelectedRows.splice(index, 1);
            }
        });
        console.log("this.allSelectedRows",JSON.stringify(this.allSelectedRows));
        this.isDisable = (this.allSelectedRows.length == 0);
    }
}