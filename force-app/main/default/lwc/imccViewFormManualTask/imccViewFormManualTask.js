import { LightningElement, wire, api, track } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import updateUserFormData from '@salesforce/apex/IMCC_FormsCtrl.updateFormDataNew';
import fileDownloadUrl from '@salesforce/label/c.File_Download_URL';
import fetchContVerId from '@salesforce/apex/IMCC_FloorplanCtrl.fetchManualPdfDetails';
import updateFormAgreed from '@salesforce/apex/IMCC_FormsCtrl.updateFormAgreed';
import getPurchaseData from '@salesforce/apex/FormPreviewController.getRelatedBooths';
import pdfInstruction from '@salesforce/apex/IMCC_FormsCtrl.fetchGlobalConstant';
import fetchfileUploadSize from '@salesforce/apex/IMCC_FormsCtrl.fetchfileUploadSize';
import { showToast, handleUIErrors, redirect } from 'c/imcc_lwcUtility';
import deleteUploadedPdf from '@salesforce/apex/IMCC_FormsCtrl.deleteUploadedPdf';
import manualLabel1 from '@salesforce/label/c.Contractors_Space_Only_Regulations_Manual';
import manualLabel2 from '@salesforce/label/c.Exhibitor_Code_of_Conduct_Manual';
import manualLabel3 from '@salesforce/label/c.Venue_Technical_Guidelines_Manual';

export default class ImccViewFormManualTask extends NavigationMixin(LightningElement) {

    @api task;
    @api contactId;
    @api cemId;
    @api mapFdPd;
    @api mapFaFe;
    @track eventcode;
    @track accountId;
    @track isModalOpenLink = false;
    @track downloadModal = false;
    @track showPdf = '';
    @track isPdfAgreed = false;
    @track isManaulAgree;
    @track isSaveBtnDisable;
    @track isVisibleSaveOnLoad = false;
    @track spinner = false;
    @track pdList;
    @track boothList;
    @track selectedBooth = '';
    @track isOpenBoothSelector = false;
    @track selectedFormId = '';
    @track isMultiEntry = 0;
    @track isUploadEnable = false;
    @track isManual = false;
    @track showAfterUploadBtn = false;
    @track disableViewBtn = true;
    @track disableSubmitBtn = true;
    @track isSubmit = false;
    @track isUpload = false;
    @track contentVerId = '';
    @track isViewPDFFormEntry = false;
    @track viewPdf = '';
    @track formCategory;
    @track viewModal = false;
    @track deadlineReached = false;
    @track entryLimitReached = false;
    @track isDeletePdfModal = false;
    @track disableDeleteBtn = true;
    @track manualTermCon;

    @track methodName;
    className = 'imccViewFormManualTask';
    comp_type = 'LWC';

    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        //this.taskCount = 0;
        //this.isShowTask = false;
        if (currentPageReference) {
            this.eventcode = currentPageReference.state.edcode;
            this.accountId = currentPageReference.state.accId;

        }
    };

    connectedCallback() {
        console.log('task1233 ' + JSON.stringify(this.task));
        this.methodName = 'getPurchaseData';
        getPurchaseData({
            cemId: this.cemId
        })
            .then(result => {
                console.log('PDLIST@@@@' + result);
                this.pdList = result;
                this.openAction(this.task);
            })
            .catch(error => {
                console.log("====IMCC_FORMS====setCurrentPageReference====");
                console.log(error);
                console.log("====IMCC_FORMS====setCurrentPageReference====");
                handleUIErrors(this, error);
            });

    }

    @track formType;
    @track formDataId;
    @track isPdfAgreed;
    @track formUrl;
    @track entryId;
    @track formAllocId;
    @track deadline;
    @track allowAfterDueDate;
    @track overAllStatus;

    openAction(task) {
        const data = task;
        this.formType = data.Forms_Permission__r.Form_Allocation__r.Form_Type__c;
        let targetId = data.Forms_Permission__r.Form_Allocation__r.Form__c;
        let fres = data.Form_Response_Entries__r;
        let allFres = this.mapFaFe[data.Forms_Permission__r.Form_Allocation__c];
        this.formDataId = data.Id;
        this.formUrl = data.Forms_Permission__r.Form_Allocation__r.Form_Url__c;
        let formAllocId = data.Forms_Permission__r.Form_Allocation__c;
        this.formAllocId = formAllocId;
        let formManName = data.Form_Name__c;
        let entryType = data.Forms_Permission__r.Form_Allocation__r.Form_Entry__c;
        let boothType = data.Forms_Permission__r.Form_Allocation__r.Booth_Product_Types__c;
        let entryLimit = data.Forms_Permission__r.Form_Allocation__r.Entry_Limit__c;
        let submittedResponse = data.Submitted_Responses__c;
        this.overAllStatus = data.Overall_Status__c;
        let ifAllowMultiForm = entryType && (entryType === 'Multiple Per Account' || entryType === 'Multiple Per Booth') ? 1 : 0;
        entryType = entryType ? entryType.toLowerCase() : '';
        this.formCategory = data.Forms_Permission__r.Form_Allocation__r.Feature_Category__c;
        this.deadline = data.Forms_Permission__r.Form_Allocation__r.Submission_Deadline__c;
        this.allowAfterDueDate = data.Forms_Permission__r.Form_Allocation__r.Allow_Submissions_after_Due_date__c;
        let date2;
        let today = new Date().setHours(0, 0, 0, 0);
        if (this.deadline) {
            date2 = new Date(this.deadline).setHours(0, 0, 0, 0);
        }

        if (this.deadline != null && this.deadline != '' && !this.allowAfterDueDate && date2 < today) {
            this.deadlineReached = true;
            showToast(this, 'Deadline has been reached for this ' + this.formCategory, 'error', 'Error');
            this.redirect(this.task.page, { "accId": this.accountId, "edcode": this.eventcode, "tabId": this.task.tabId });
        }
        else {
            this.deadlineReached = false;
        }

        if (entryLimit != null && entryLimit != '' && entryType === 'multiple per account' && (this.formType == 'PDF' || this.formType == 'Online')) {
            let entryLimitInt = parseInt(entryLimit, 10);
            if (entryLimitInt == submittedResponse) {
                showToast(this, 'Number of allowed submission has been submitted', 'error', 'Error');
                this.redirect(this.task.page, { "accId": this.accountId, "edcode": this.eventcode, "tabId": this.task.tabId });
                this.entryLimitReached = true;
            }
        }

        if (this.formCategory == 'Form' && this.formType == 'PDF' && entryType != 'multiple per account' && entryType != 'multiple per booth') {
            if (this.overAllStatus == 'In Review') {
                this.isUploadEnable = false;
            }
            else {
                this.isUploadEnable = true;
            }
        }
        else {
            this.isUploadEnable = true;
        }

        if (data.Form_Response_Entries__r != undefined) {
            data.Form_Response_Entries__r.forEach(entry => {
                if (this.formCategory == 'Manual') {
                    this.entryId = entry.Id;
                }
                else if (this.formType == 'Link' || (this.formType == 'Online' && entryType == 'one per account')) {
                    this.entryId = entry.Id;
                }
                else if (entryType == 'one per booth' || entryType == 'multiple per booth' || entryType == 'multiple per account') {
                    this.entryId = '';
                }
            });
        }

        const options = [{ label: 'Select booth', value: '' }];
        var pdList = [];
        var bType = (boothType == null || boothType == '' ? [] : boothType.split(';'));
        if (entryType === 'multiple per booth' || entryType === 'one per booth') {
            var submittedIds = [];
            var countOnPDId = {};
            this.boothList = [];
            if (allFres != null && allFres != undefined) {
                allFres.forEach(entry => {
                    if (entry.Status__c == 'Submitted' || entry.Status__c == 'Resubmitted') {
                        if (!entry.Form_Unlock__c) {
                            submittedIds.push(entry.Purchase_Data__c);
                        }
                        countOnPDId[entry.Purchase_Data__c] = (countOnPDId[entry.Purchase_Data__c] == null ? 0 : countOnPDId[entry.Purchase_Data__c]) + 1;
                    }
                });
            }
            console.log('PDLIST' + this.pdList);
            this.pdList.forEach(item => {
                if (bType.length == 0 || bType.includes(item.Booth_Product_Type__c)) {
                    pdList.push(item.Id);
                    if ((entryType === 'one per booth' && submittedIds.indexOf(item.Id) == -1) || (entryType === 'multiple per booth' && (entryLimit == null || entryLimit == ''))) {
                        options.push({ label: item.Booth_Number__c + ' - ' + item.Booth_Product_Type__c, value: item.Id });
                    }
                    if (entryType === 'multiple per booth' && entryLimit != null && entryLimit != '') {
                        var entryLimitInt = parseInt(entryLimit, 10);
                        let countOnPDId2 = (countOnPDId[item.Id] == null ? 0 : countOnPDId[item.Id]);
                        if (countOnPDId2 < entryLimitInt) {
                            options.push({ label: item.Booth_Number__c + ' - ' + item.Booth_Product_Type__c, value: item.Id });
                        }
                    }
                }
            });
        }

        if (this.formType == 'Link') {
            if (!this.deadlineReached) {
                this.isModalOpenLink = true;
            }
        }
        else if (this.formType == 'Online') {
            if (!this.deadlineReached) {
                if (entryType === 'multiple per account' || entryType === 'one per account') {
                    if (!this.entryLimitReached) {
                        this.redirect('FormPreview__c', {
                            id: targetId,
                            ceid: this.cemId,
                            check: ifAllowMultiForm,
                            ref: "new",
                            accId: this.accountId,
                            edcode: this.eventcode,
                            tabId: this.task.tabId,
                            formDataId: this.formDataId,
                            entryId: this.entryId
                        });
                    }
                }
                else if ((entryType === 'multiple per booth' || entryType === 'one per booth')) {
                    if (pdList.length == 0) {
                        let errMSG = (bType.length == 0 ? 'Booths not found' : ('Booths not found for booth types : ' + boothType));
                        showToast(this, errMSG, 'error', 'Error');
                    }
                    if (pdList.length > 0 && options.length == 1) {
                        let errMSG = (bType.length == 0 ? 'Submission has been made for all booths' : ('Submission has been made for all booths of booth types : ' + boothType));
                        showToast(this, errMSG, 'info', 'Info');
                        this.redirect(this.task.page, { "accId": this.accountId, "edcode": this.eventcode, "tabId": this.task.tabId });
                    }
                    if (options.length > 1) {
                        //open booth seletor modal
                        this.selectedBooth = options[0].value;
                        if (options.length == 2) {
                            this.selectedBooth = options[1].value;
                        }
                        this.boothList = options;
                        this.isOpenBoothSelector = true;
                        this.selectedFormId = targetId;
                        this.isMultiEntry = ifAllowMultiForm;
                    }
                }
            }

        }
        else if (this.formType == 'PDF') {
            if (!this.deadlineReached) {
                this.methodName = 'fetchContVerId';
                fetchContVerId({ linkEntId: formAllocId })
                    .then(result => {
                        let contVerId = result;
                        console.log('Content Ver ID ' + contVerId);
                        if (contVerId) {
                            if (this.formCategory == 'Form') {
                                this.isManual = false;
                                if ((entryType === 'multiple per booth' || entryType === 'one per booth')) {
                                    if (pdList.length == 0) {
                                        let errMSG = (bType.length == 0 ? 'Booths not found' : ('Booths not found for booth types : ' + boothType));
                                        showToast(this, errMSG, 'error', 'Error');
                                    }
                                    if (pdList.length > 0 && options.length == 1) {
                                        let errMSG = (bType.length == 0 ? 'Submission has been made for all booths' : ('Submission has been made for all booths of booth types : ' + boothType));
                                        showToast(this, errMSG, 'info', 'Info');
                                        this.redirect(this.task.page, { "accId": this.accountId, "edcode": this.eventcode, "tabId": this.task.tabId });
                                    }
                                    if (options.length > 1) {
                                        //open booth seletor modal
                                        this.showPdf = fileDownloadUrl + contVerId;
                                        this.selectedBooth = options[0].value;
                                        if (options.length == 2) {
                                            this.selectedBooth = options[1].value;
                                        }
                                        this.boothList = options;
                                        this.isOpenBoothSelector = true;
                                        this.selectedFormId = targetId;
                                        this.isMultiEntry = ifAllowMultiForm;
                                        if (!this.isUploadEnable) {
                                            //this.isUploadEnable = true;
                                            this.showAfterUploadBtn = false;
                                            this.disableViewBtn = true;
                                            this.disableSubmitBtn = true;
                                            this.disableDeleteBtn = true;
                                        }


                                    }
                                    this.fetchInstruction();
                                }
                                else {
                                    if (!this.entryLimitReached) {
                                        var status = 'Viewed';
                                        //this.isUploadEnable = true;
                                        this.showAfterUploadBtn = false;
                                        this.disableViewBtn = true;
                                        this.disableSubmitBtn = true;
                                        this.disableDeleteBtn = true;
                                        if (entryType == 'one per account') {
                                            if (fres != null && fres != undefined) {
                                                fres.forEach(entry => {
                                                    if (entry.Status__c != 'Viewed') {
                                                        status = '';
                                                        this.entryId = entry.Id;
                                                    }
                                                });
                                            }
                                        }
                                        this.showPdf = fileDownloadUrl + contVerId;
                                        this.downloadModal = true;
                                        this.isViewPDFFormEntry = false;
                                        if (this.isUploadEnable && status != '') {
                                            this.updateUserViewed(this.formType, this.formDataId, this.cemId, this.entryId, status, "", "");
                                        }
                                        this.fetchInstruction();
                                    }
                                }
                            }

                            if (this.formCategory == 'Manual') {
                                if (formManName == 'Contractors Space Only Regulations') {
                                    this.manualTermCon = manualLabel1;
                                }
                                else if (formManName == 'Exhibitor Code of Conduct') {
                                    this.manualTermCon = manualLabel2;
                                }
                                else if (formManName == 'Venue Technical Guidelines') {
                                    this.manualTermCon = manualLabel3;
                                }
                                else {
                                    this.manualTermCon = 'I have read and agree to the contents of this document';
                                }
                                var status = 'Viewed';
                                this.isManual = true;
                                this.showPdf = fileDownloadUrl + contVerId;
                                this.downloadModal = true;
                                this.isViewPDFFormEntry = false;
                                this.updateUserViewed(this.formType, this.formDataId, this.cemId, this.entryId, status, "", "");



                            }
                        }
                        else {
                            showToast(this, 'No PDF found for this ' + this.formCategory, 'error', 'Error');
                        }
                    })
                    .catch(error => {
                        console.log("===IMCC_FormsTable======openAction===");
                        console.log(error);
                        console.log("===IMCC_FormsTable======openAction===");
                        handleUIErrors(this, error);
                    });
            }
        }
    }

    makeSecureUrl(url) {
        let finalUrl;
        if (url.includes("?")) {
            if (!url.includes("http:") && !url.includes("https:")) {
                finalUrl = "https://" + url;
            }
            else {
                finalUrl = url;
            }
        }
        else {
            if (!url.includes("http:") && !url.includes("https:")) {
                finalUrl = "https://" + url + '?accId=' + this.accountId + '&edcode=' + this.eventcode + '&conId=' + this.contactId + '&ceid=' + this.cemId;
            } else {
                finalUrl = url + '?accId=' + this.accountId + '&edcode=' + this.eventcode + '&conId=' + this.contactId + '&ceid=' + this.cemId;
            }
        }
        return finalUrl;
    }

    closeModalLinkForm() {
        this.isModalOpenLink = false;
        //this.downloadModal = false;
        this.redirect(this.task.page, { "accId": this.accountId, "edcode": this.eventcode, "tabId": this.task.tabId });
    }

    //Open Form for Selected Booth
    openFormForBooth() {
        if (this.selectedBooth === '') {
            showToast(this, 'Please select a booth', 'error', 'Form Error');
            return false;
        }
        let tempFD = this.mapFdPd[this.selectedBooth + '_' + this.formAllocId];
        this.formDataId = tempFD.Id;
        var entryId = '';
        if (tempFD.Form_Response_Entries__r != null && tempFD.Form_Response_Entries__r != undefined) {
            tempFD.Form_Response_Entries__r.forEach(entry => {
                if ((entry.Status__c == 'Viewed' || tempFD.Forms_Permission__r.Form_Allocation__r.Form_Entry__c == 'One Per Booth') && entry.Purchase_Data__c == this.selectedBooth) {
                    entryId = entry.Id;
                }
            });
        }
        this.entryId = entryId;

        if (this.formType == 'Online') {
            this.redirect('FormPreview__c', {
                id: this.selectedFormId,
                ceid: this.cemId,
                check: this.isMultiEntry,
                b: this.selectedBooth,
                ref: "new",
                accId: this.accountId,
                edcode: this.eventcode,
                tabId: this.task.tabId,
                formDataId: this.formDataId,
                entryId: entryId
            });
            //this.closeBoothSelector();
        }
        else {
            var status = 'Viewed';
            this.showAfterUploadBtn = false;
            this.disableViewBtn = true;
            this.disableSubmitBtn = true;
            this.disableDeleteBtn = true;
            this.isOpenBoothSelector = false;
            this.downloadModal = true;
            if (this.isUploadEnable) {
                this.updateUserViewed(this.formType, this.formDataId, this.cemId, this.entryId, status, this.selectedBooth, "");
            }
        }
    };

    //Close Booth Selector Modal
    closeBoothSelector() {
        this.isOpenBoothSelector = false;
        this.selectedFormId = '';
        this.isMultiEntry = 0;
        this.selectedBooth = '';
        this.redirect(this.task.page, { "accId": this.accountId, "edcode": this.eventcode, "tabId": this.task.tabId });
    }

    //Booth Selection Handler Method
    handleBoothSelect(event) {
        this.selectedBooth = event.target.value;
    }

    openLinkForm() {
        this.isModalOpenLink = false;
        window.open(this.makeSecureUrl(this.formUrl), '_blank');
        console.log('cEMID ' + this.cemId);
        this.updateUserViewed(this.formType, this.formDataId, this.cemId, this.entryId, 'Submitted', "", "link");
    }

    //To Create/Update Form Response Entry
    updateUserViewed(formType, formId, conMapId, entryId, formStatus, boothId, callFrom) {
        this.methodName = 'updateUserFormData';
        updateUserFormData({
            formType: formType,
            formId: formId,
            conEdMapId: conMapId,
            entryId: entryId,
            status: formStatus,
            pdId: boothId
        })
            .then(result => {
                this.entryId = result.Id;
                console.log('ENTRY ID ' + this.entryId);
                if (callFrom == "link") {
                    this.dispatchEvent(new CustomEvent('formsubmitted', { detail: formId }));
                }
                if (callFrom == "Pdf") {
                    showToast(this, 'Form has been submitted successfully.', 'success', 'Success!');
                    this.downloadModal = false;
                    this.isViewPDFFormEntry = false;
                    this.closeBoothSelector();
                }
            })
            .catch(error => {
                console.log("===IMCC_FormsTable======updateUserViewed===");
                console.log(error);
                console.log("===IMCC_FormsTable======updateUserViewed===");
                this.error = error;
                handleUIErrors(this, error);
            });
    }

    get isTrue() {
        return this.spinner;
    }

    redirect(pageName, paramObj) {
        redirect(this, NavigationMixin.Navigate, pageName, paramObj);
    };

    //#region Manual Related Methods
    handleAgreeManual(event) {
        this.isVisibleSaveOnLoad = true;
        this.isManaulAgree = event.target.checked;
        this.isSaveBtnDisable = !this.isManaulAgree;
    }

    saveFormData() {
        if (!this.isManaulAgree) {
            showToast(this, 'Please check agreement.', 'error', 'Manual Validation Error!');
            return false;
        }

        this.spinner = true;
        this.methodName = 'updateFormAgreed';
        updateFormAgreed({ formDataId: this.formDataId })
            .then(res => {
                this.spinner = false;
                //this.refreshTable();
                this.downloadModal = false;
                showToast(this, 'You have successfully viewd and agreed manual.', 'success', 'Success!');
                this.redirect(this.task.page, { "accId": this.accountId, "edcode": this.eventcode, "tabId": this.task.tabId });
            })
            .catch(error => {
                console.log("===IMCC_FormsTable======saveFormData===");
                console.log(error);
                console.log("===IMCC_FormsTable======saveFormData===");
                this.spinner = false;
                //showToast(this, error);
                handleUIErrors(this, error);
            })
    }

    //#region PDF Form Related Methods
    get acceptedFormats() {
        return ['.pdf'];
    }

    closeViewPopup() {
        this.viewModal = false;
        this.isViewPDFFormEntry = false;
    }

    uploadedFiles = [];
    fileData = [];
    handleUploadFinished(event) {
        // Get the list of uploaded files
        this.isUpload = true;
        this.uploadedFiles = event.detail.files;
        //this.contentVerId = uploadedFiles[0].contentVersionId;
        let fileSize = [];
        this.uploadedFiles.forEach(item => {
            fileSize.push(item.contentVersionId);
        })
        console.log('fileSize:', fileSize);
        this.isSubmit = false;

        fetchfileUploadSize({ idList: fileSize[0] })
            .then(result => {
                if (result.length > 0) {
                    let tempData = result;
                    console.log('result:', JSON.stringify(result));
                    tempData.forEach(item => {
                        item.sizeInKB = Math.round((item.ContentSize / 1024));
                        this.showAfterUploadBtn = true;
                        this.disableSubmitBtn = false;
                        this.disableViewBtn = false;
                        this.disableDeleteBtn = false;
                    })
                    this.fileData = tempData;
                }
            })
            .catch(error => {
                this.error = error;
                this.showAfterUploadBtn = false;
                this.disableSubmitBtn = false;
                this.disableViewBtn = false;
                this.disableDeleteBtn = false;
                handleUIErrors(this, error);
            });
    }

    viewModel(event) {
        let contVerId = event.target.name;
        if (contVerId) {
            this.viewPdf = fileDownloadUrl + contVerId;
            this.viewModal = true;
            this.disableSubmitBtn = false;
        }
    }

    submitPdf() {
        this.isSubmit = true;
        this.updateUserViewed(this.formType, this.formDataId, this.cemId, this.entryId, 'Submitted', "", "Pdf");
    }

    handledeletePdfModal() {
        this.isDeletePdfModal = true;
    }

    deletePdf() {
        let entryId = this.entryId;
        this.isSubmit = true;
        this.deleteRecentPdf(entryId);
    }

    deleteRecentPdf(linkEntId) {
        this.methodName = 'deleteUploadedPdf';
        this.isDeletePdfModal = false;
        deleteUploadedPdf({ linkEntId: linkEntId })
            .then(result => {
                let message = result;
                if (message == 'Success') {
                    showToast(this, 'Form submission has been successfully deleted.', 'success', 'Success!');
                    this.disableSubmitBtn = true;
                    this.disableViewBtn = true;
                    this.disableDeleteBtn = true;
                    this.isDeletePdfModal = false;
                }
                else if (message == 'Error') {
                    showToast(this, 'No Form submission found for deletion.', 'error', 'Error!');
                    this.disableSubmitBtn = true;
                    this.disableViewBtn = true;
                    this.disableDeleteBtn = true;
                    this.isDeletePdfModal = false;
                }

            })
            .catch(error => {
                console.log("===IMCC_FormsTable======deleteRecentPdf===");
                console.log(error);
                // this.isDeletePdfModal = false;
                console.log("===IMCC_FormsTable======deleteRecentPdf===");
                handleUIErrors(this, error);
            });
    }

    closePdfDeleteModal() {
        this.isDeletePdfModal = false;
    }

    ClosePopup() {
        if (this.isSubmit == true) {
            this.downloadModal = false;
        }
        else if (this.isUpload == true) {
            this.downloadModal = false;
            if (this.entryId && this.formCategory == 'Form') {
                this.deleteRecentPdf(this.entryId);
            }
        }
        else {
            this.downloadModal = false;
        }
        this.isViewPDFFormEntry = false;
        this.viewModal = false;
        this.redirect(this.task.page, { "accId": this.accountId, "edcode": this.eventcode, "tabId": this.task.tabId });
    }
    //#endregion

    @track Instruction = [];
    fetchInstruction() {
        pdfInstruction()
            .then(res => {
                console.log('data:', JSON.stringify(res));
                let temp = res;
                console.log('value:', temp[0].Value__c);
                this.Instruction = temp[0].Value__c.split('\r\n').join('\n');
                console.log('this.Instruction:', this.Instruction);
            })
            .catch(error => {
                console.log('error:', error);
            });
    }
}