import { LightningElement, track, api, wire } from 'lwc';
import updateUserFormData from '@salesforce/apex/IMCC_FormsCtrl.updateFormDataNew';
import getFormDataDetail from '@salesforce/apex/IMCC_FormsCtrl.getFormDataDetail';
import updateApplicableFormData from '@salesforce/apex/IMCC_FormsCtrl.updateApplicableFormData';
import fetchContVerId from '@salesforce/apex/IMCC_FloorplanCtrl.fetchManualPdfDetails';
import deleteUploadedPdf from '@salesforce/apex/IMCC_FormsCtrl.deleteUploadedPdf';
import updateFormAgreed from '@salesforce/apex/IMCC_FormsCtrl.updateFormAgreed';
import deleteFormResponse from '@salesforce/apex/FormPreviewController.deleteFormRespEntry';
import assignFormsToDelegate from '@salesforce/apex/IMCC_FormsCtrl.assignFormsToDelegate';
import pdfInstruction from '@salesforce/apex/IMCC_FormsCtrl.fetchGlobalConstant';
import fetchfileUploadSize from '@salesforce/apex/IMCC_FormsCtrl.fetchfileUploadSize';
import fileDownloadUrl from '@salesforce/label/c.File_Download_URL';
import manualLabel1 from '@salesforce/label/c.Contractors_Space_Only_Regulations_Manual';
import manualLabel2 from '@salesforce/label/c.Exhibitor_Code_of_Conduct_Manual';
import manualLabel3 from '@salesforce/label/c.Venue_Technical_Guidelines_Manual';
import { showToast, redirect, handleUIErrors } from 'c/imcc_lwcUtility';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { loadScript } from 'lightning/platformResourceLoader';
import InformaMarketsCSS from '@salesforce/resourceUrl/InformaMarketsCSS';


export default class Imcc_formTable extends NavigationMixin(LightningElement) {
    //#region Parameters
    @api conEdMapId;
    @api contactId;
    @api tabtype;
    @api formtype = '';
    @api showTabContextIn;
    @api purchaseDatas = [];
    @api formDatas = [];
    @api allContactsDatas = [];
    @api nodata = false;

    @track methodName;
    className = 'iMCC_formTable';
    comp_type = 'LWC';


    @track tableData;
    //@track deadlineDate;
    //filter1
    filter1Label = 'Status';
    filterField1 = 'Overall_Status__c';
    filterField1Options;
    filterField1Value = '';
    //filter 2
    filter2Label = 'Form Provider';
    filterField2 = 'Form_Provider__c';
    filterField2Options;
    filterField2Value = '';
    //filter 3
    filterField3 = 'Form_Category__c';
    filter3Label = 'Form Category';
    filterField3Options;
    filterField3Value = '';

    boothList;
    pdList;
    conData = [];
    searchValue = '';
    formUrl;
    formDataId;
    entryId;
    formType;
    formHeader;
    isModalOpen = false;
    isModalOpenLink = false;
    isPdfAgreed = false;
    indexNum;
    rejectionReason;
    isUploadEnable = true;
    showAfterUploadBtn = false;
    isUpload = false;
    formAllocId;
    eventcode;
    accountId;
    tabId;
    progressPercent = 0;
    showMan = false;
    showAdd = false;
    showOpt = false;
    isShowInMan = false;
    isShowInAdd = false;
    isShowInOpt = false;
    error;
    spinner;
    isShow;
    downloadModal = false;
    manualTermCon;
    viewModal = false;
    showTable = false;
    showSpinner = true;
    selectedCon = '';
    isManual = false;
    isDeleteModal = false;
    isDeletePdfModal = false;
    isReasonModal = false;
    disableSubmitBtn = true;
    disableViewBtn = true;
    disableDeleteBtn = true;
    formPDFUrl;
    contentVerId;
    isSubmit = false;
    isViewPDFFormEntry = false;
    isMoboFilterApplied = false;
    isOpenBoothSelector = false;
    selectedFormId = '';
    isMultiEntry = 0;
    selectedBooth = '';
    isManaulAgree;
    isSaveBtnDisable;
    isVisibleSaveOnLoad = false;
    currentFormDataId;
    mapPDFD = {};
    mapFDExpand = {};
    filterFormDatas = [];
    allFormDatas = [];
    sortByName = 'formName';
    sortType = 'asc';
    showPdf = '';
    //#endregion

    //#region Page Load Method
    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        loadScript(this, InformaMarketsCSS + '/CustomerCenterWS11/js/jquery-1.7.1.min.js')
            .then(() => {
                let that = this;
                window.jQuery("body").click(function (event) {
                    that.closeFilterOption(null);
                });
            })
            .catch(errors => {
                console.log(errors);
            });

        this.spinner = false;

        if (this.showTabContextIn == 'mandatory') {
            this.isShowInMan = true;
        }
        if (this.showTabContextIn == 'additional') {
            this.isShowInAdd = true;
        }
        if (this.showTabContextIn == 'optional') {
            this.isShowInOpt = true;
        }

        this.isShow = this.spinner === false;
        if (this.formtype === 'Mandatory') {
            this.showMan = true;
            this.showAdd = false;
            this.showOpt = false;
        }
        if (this.formtype === 'Additional') {
            this.showAdd = true;
            this.showMan = false;
            this.showOpt = false;
        }
        if (this.formtype === 'Optional') {
            this.showOpt = true;
            this.showMan = false;
            this.showAdd = false;
        }
        if (this.tabtype == 'Manuals') {
            this.formHeader = 'Manual';
            this.isManual = true;
            this.filter3Label = 'Manual Category';
            this.filter2Label = 'Manual Provider';
        }
        if (this.tabtype == 'Forms') {
            this.formHeader = 'Form';
            this.isManual = false;
        }
        this.allFormDatas = JSON.parse(JSON.stringify(this.formDatas));
        this.filterFormDatas = JSON.parse(JSON.stringify(this.allFormDatas));
        this.handleFilterChange();

        if (this.filterField1 !== undefined) {
            this.setFilterOptions(1, this.filterField1);
        }

        if (this.filterField2 !== undefined) {
            this.setFilterOptions(2, this.filterField2);
        }

        if (this.filterField3 !== undefined) {
            this.setFilterOptions(3, this.filterField3);
        }

        if (currentPageReference && currentPageReference.state) {
            this.eventcode = currentPageReference.state.edcode;
            this.accountId = currentPageReference.state.accId;
            this.tabId = currentPageReference.state.tabId;
            this.allContactsDatas = this.allContactsDatas ? this.allContactsDatas : [];
            let contactsDatas = JSON.parse(JSON.stringify(this.allContactsDatas));
            contactsDatas.forEach(row => {
                this.conData.push({ label: row.Name, value: row.Id });
            });
            this.pdList = JSON.parse(JSON.stringify(this.purchaseDatas));
        }
    }
    //#endregion

    //#region Form Data Related Methods
    //Get Form Data And Entries
    getData() {
        this.methodName = 'getData';
        let f = this.sortByName;
        let d = this.sortType;
        this.filterFormDatas.sort(function (a, b) {
            var ret = ((a[f] < b[f]) ? (-1) : ((a[f] > b[f]) ? (1) : (0)));
            return (d == "asc" ? ret : (0 - ret));
        });

        this.spinner = false;
        this.isShow = (this.spinner === false);

        if (this.filterFormDatas.length === 0) {
            this.error = 'No record found';
            this.tableData = undefined;
        }
        else {
            this.tableData = JSON.parse(JSON.stringify(this.filterFormDatas));
            this.error = undefined;
            this.showTable = true;
            let date2;
            let today = new Date().setHours(0, 0, 0, 0);
            let manFormCount = 0;
            let totalSum = 0;

            //Code to Show Only Unique Form Datas : Start
            let uniqueformAllocs = {};
            let mapFormAllocsListFD = {};
            this.mapPDFD = {};
            let fdIndex = -1;
            this.tableData.forEach(row => {
                row.isShowFormData = false;
                let fAllocId = row.Forms_Permission__r.Form_Allocation__c;
                fdIndex++;
                mapFormAllocsListFD[fAllocId] = mapFormAllocsListFD.hasOwnProperty(fAllocId) ? mapFormAllocsListFD[fAllocId] : [];
                mapFormAllocsListFD[fAllocId].push(row);
                if (!uniqueformAllocs.hasOwnProperty(fAllocId)) {
                    uniqueformAllocs[fAllocId] = fdIndex;
                    row.isShowFormData = true;
                    if (row.Purchase_Data__c != null) {
                        this.mapPDFD[row.Purchase_Data__c + '_' + fAllocId] = row;
                    }
                }
                else {
                    let firstFDIndex = uniqueformAllocs[fAllocId];

                    this.tableData[firstFDIndex].Form_Response_Entries__r = this.tableData[firstFDIndex].Form_Response_Entries__r == null ? [] : this.tableData[firstFDIndex].Form_Response_Entries__r;

                    if (row.Form_Response_Entries__r != null) {
                        Array.prototype.push.apply(this.tableData[firstFDIndex].Form_Response_Entries__r, row.Form_Response_Entries__r);
                    }
                    if (row.Purchase_Data__c != null) {
                        this.mapPDFD[row.Purchase_Data__c + '_' + fAllocId] = row;
                    }
                }
            });
            //Code to Show Only Unique Form Datas : End

            //Code to Process Form Datas : Start
            this.tableData.forEach(row => {
                let formCategory = row.Forms_Permission__r.Form_Allocation__r.Feature_Category__c;
                let formType = row.Forms_Permission__r.Form_Allocation__r.Form_Type__c;
                let formEntry = row.Forms_Permission__r.Form_Allocation__r.Form_Entry__c;
                let approvalRequired = row.Forms_Permission__r.Form_Allocation__r.Approval_Required__c;
                let allowAfterDueDate = row.Forms_Permission__r.Form_Allocation__r.Allow_Submissions_after_Due_date__c;
                let entryLimit = row.Forms_Permission__r.Form_Allocation__r.Entry_Limit__c;
                /*IMCC-4506 */
                let deadline = row.Forms_Permission__r.Form_Allocation__r.Submission_Deadline__c;
                let date = row.Forms_Permission__r.Form_Allocation__r.Submission_Deadline__c ? row.Forms_Permission__r.Form_Allocation__r.Submission_Deadline__c.split("-") : [];
                let dateFormatted = date && date.length == 3 ? date[2] + ' ' + this.getMonth(date[1]) + ' ' + date[0] : '';
                row.Forms_Permission__r.Form_Allocation__r.Submission_Deadline__c = dateFormatted;
                /*IMCC-4506 */
                let notApplicable = row.Not_Applicable__c;

                row.checkAssigned = false;
                row.isLink = (formType === 'Link');
                row.isMultiEntry = (formCategory != 'Manual' && formType != 'Link');
                if (!this.mapFDExpand.hasOwnProperty(row.Id)) {
                    this.mapFDExpand[row.Id] = row.expand;
                }
                else {
                    row.expand = this.mapFDExpand[row.Id];
                }
                row.colspan = 9;
                row.isViewed = false;
                row.noData = true;
                row.showFormIcon = false;
                row.showPdfIcon = false;
                row.showLinkIcon = false;
                row.showRelateIcon = false;

                if (formType == 'Online') {
                    row.showFormIcon = true;
                }
                else if (formType == 'PDF') {
                    row.showPdfIcon = true;
                }
                else {
                    row.showLinkIcon = true;
                }

                if (formEntry == 'Multiple Per Account' || formEntry == 'Multiple Per Booth') {
                    row.titleForMultiple = formEntry;
                    row.showRelateIcon = true;
                }

                if (notApplicable) {
                    row.customCSS = 'slds-hint-parent table-height strikeThrough';
                }
                else {
                    row.customCSS = 'slds-hint-parent table-height';
                }

                if (deadline) {
                    date2 = new Date(deadline).setHours(0, 0, 0, 0);
                }

                //for Processing Responses : Start
                if (row.Form_Response_Entries__r != null) {
                    row.Form_Response_Entries__r.sort((a, b) => (a.Entry_Number__c > b.Entry_Number__c) ? 1 : ((b.Entry_Number__c > a.Entry_Number__c) ? -1 : 0));
                    row.Form_Response_Entries__r.forEach(entry => {
                        entry.rejectIcon = false;
                        entry.Status = entry.Status__c;

                        if (approvalRequired && entry.Approval_Status__c != null && entry.Approval_Status__c != '') {
                            entry.Status = entry.Approval_Status__c;
                        }

                        if (entry.Approval_Status__c == 'Rejected') {
                            row.isRejected = true;
                            entry.rejectIcon = true;
                        }

                        if (entry.Status__c != 'Viewed' && (formType == 'Online' || formType == 'PDF')) {
                            entry.Show = true;
                            row.noData = false;
                        }

                        if (formCategory == 'Manual') {
                            row.entryId = entry.Id;
                        }
                        else if (formType == 'Link') {
                            row.entryId = entry.Id;
                            row.isViewed = (entry.Status__c == 'Submitted' || entry.Status__c == 'Viewed');
                        }
                        else {
                            //for Response Name : Start
                            if (formEntry == 'One Per Account' || formEntry == 'Multiple Per Account') {
                                entry.responseName = ((formType == 'Online') ? ('Response-' + entry.Entry_Number__c) : entry.File_Name__c);
                            }
                            if (formEntry == 'One Per Booth') {
                                entry.responseName = ((formType == 'Online') ? entry.Purchase_Data__r.Booth_Number__c : (entry.Purchase_Data__r.Booth_Number__c + '-' + entry.File_Name__c));
                            }

                            if (formEntry == 'Multiple Per Booth') {
                                entry.responseName = ((formType == 'Online') ? (entry.Purchase_Data__r.Booth_Number__c + ' Response-' + entry.Entry_Number__c) : (entry.Purchase_Data__r.Booth_Number__c + '-' + entry.File_Name__c));
                            }
                            //for Response Name : End

                            //for Form data Status : Start
                            if (formEntry == 'One Per Account') {
                                row.entryId = entry.Id;
                            }
                            //for Form data Status : End

                            //for Form Response Entry Click Options : Start
                            entry.isUploadEnable = true;
                            entry.showDeleteOption = true;
                            if (approvalRequired && (deadline == null || deadline == '' || allowAfterDueDate || (!allowAfterDueDate && date2 >= today))) {
                                if (entry.Approval_Status__c == 'Approved' || entry.Approval_Status__c == 'Rejected' || entry.Approval_Status__c == 'In Review') {
                                    entry.showDeleteOption = false;
                                    entry.isUploadEnable = false;
                                    if (entry.Approval_Status__c == 'Rejected') {
                                        entry.isUploadEnable = true;
                                    }
                                }
                                else if (entry.Approval_Status__c == 'In Review') {
                                    entry.isUploadEnable = false;
                                }
                            }

                            if (deadline != null && deadline != '' && !allowAfterDueDate && date2 < today) {
                                entry.showDeleteOption = false;
                                entry.isUploadEnable = false;
                            }

                            if (entry.Form_Unlock__c) {
                                entry.isUploadEnable = true;
                            }
                            //for Form Response Entry Click Options : End
                        }
                    });
                }
                //for Processing Responses : End

                //For Color on bases for priority : Start
                if (deadline) {
                    date2 = new Date(deadline).setHours(0, 0, 0, 0);
                    let prev7Days = new Date(new Date().getTime() - (7 * 24 * 60 * 60 * 1000)).setHours(0, 0, 0, 0);
                    let next7Days = new Date(new Date().getTime() + (7 * 24 * 60 * 60 * 1000)).setHours(0, 0, 0, 0);
                    row.statusClass = 's';
                    row.statusClassDate = 's slds-truncate para paragraph-d-small paragraph-m-small';

                    if (row.Overall_Status__c === 'Submitted' || row.Overall_Status__c === 'Resubmitted' || row.Overall_Status__c === 'Approved' || row.Overall_Status__c === 'Agreed') {
                        row.statusClass = 's s-green';
                        row.statusClassDate += ' s-green';
                    }
                    else {
                        if (date2 < today) {
                            row.statusClass = 's s-red';
                            row.statusClassDate += ' s-red';
                        }
                        else if (date2 > next7Days) {
                            row.statusClass = 's s-gray';
                            row.statusClassDate += ' s-gray';
                        }
                        else if (date2 >= prev7Days || date2 == today) {
                            row.statusClass = 's s-purple';
                            row.statusClassDate += ' s-purple';
                        }
                    }
                }
                //For Color on bases for priority : End

                //For Progessbar Of Mandatory Forms/Manuals : Start
                if (this.formtype == 'Mandatory' && !row.Not_Applicable__c) {
                    manFormCount = manFormCount + 1;
                    if (row.Status1__c == 'In Review') {
                        totalSum = totalSum + 0.5;
                    }
                    if (row.Status1__c == 'Submitted' || row.Status1__c == 'Resubmitted' || row.Status1__c == 'Approved' || row.Status1__c == 'Agreed') {
                        totalSum = totalSum + 1;
                    }
                }
                if (manFormCount == 0) {
                    this.progressPercent = 100;
                }
                else {
                    this.progressPercent = ((totalSum * 100) / manFormCount).toFixed(0);
                }
                //For Progessbar Of Mandatory Forms/Manuals : End

                //for Form Data Click Options : Start
                row.notShowAsLink = '';
                row.isUploadEnable = true;
                row.showFileUpload = false;
                if (formCategory == 'Manual' || (formCategory == 'Form' && formType == 'Link')) {
                    if (deadline != null && deadline != '' && !allowAfterDueDate && date2 < today) {
                        if (row.entryId == null || row.Is_Viewed__c == true) {
                            row.notShowAsLink = 'true';
                        }
                        row.isUploadEnable = false;
                    }
                    if (row.Is_Agreed__c && formCategory == 'Manual') {
                        row.isUploadEnable = false;
                    }
                }

                if (formCategory == 'Form') {
                    if ((formEntry == 'One Per Account') && (deadline == null || deadline == '' || allowAfterDueDate || (!allowAfterDueDate && date2 >= today))) {
                        if ((row.Status1__c == 'Approved' || row.Status1__c == 'In Review') && approvalRequired) {
                            row.isUploadEnable = false;
                        }
                    }
                    if (deadline != null && deadline != '' && !allowAfterDueDate && date2 < today) {
                        /*if((row.entryId == null && formType != 'PDF' && formEntry == 'One Per Account') || formEntry == 'Multiple Per Account'){
                            row.notShowAsLink = 'true';
                        }
                        row.isUploadEnable = false;*/
                        row.notShowAsLink = 'true';
                    }

                    if (entryLimit != null && entryLimit != '' && formEntry == 'Multiple Per Account') {
                        let entryLimitInt = parseInt(entryLimit, 10);
                        let submittedResp = row.Submitted_Responses__c;
                        if (entryLimitInt == submittedResp) {
                            if (formType != 'PDF') {
                                row.notShowAsLink = 'true';
                            }
                            row.isUploadEnable = false;
                        }
                    }
                }
                if (row.Not_Applicable__c) {
                    row.notShowAsLink = 'true';
                }
                //for Form Data Click Options : End
            });
        }
        this.showSpinner = false;
    }

    //IMCC-4506
    getMonth(month) {
        let mon;
        if (month === '01') { mon = 'Jan'; }
        if (month === '02') { mon = 'Feb'; }
        if (month === '03') { mon = 'Mar'; }
        if (month === '04') { mon = 'Apr'; }
        if (month === '05') { mon = 'May'; }
        if (month === '06') { mon = 'Jun'; }
        if (month === '07') { mon = 'Jul'; }
        if (month === '08') { mon = 'Aug'; }
        if (month === '09') { mon = 'Sept'; }
        if (month === '10') { mon = 'Oct'; }
        if (month === '11') { mon = 'Nov'; }
        if (month === '12') { mon = 'Dec'; }
        return mon;
    };

    //Get Form Data And Entries
    refreshTable() {
        this.methodName = 'refreshTable';
        this.showSpinner = true;
        let allFormdataIds = [];
        let index = -1;
        let formdataIndex = -1;
        this.allFormDatas.forEach(row => {
            index++;
            allFormdataIds.push(row.Id);
            if (row.Id == this.currentFormDataId) {
                formdataIndex = index;
            }
        });
        getFormDataDetail({
            formDataId: this.currentFormDataId,
            allFormdataIds: allFormdataIds
        })
            .then(result => {
                let formData = JSON.parse(JSON.stringify(result.formData));
                let mapFormData = JSON.parse(JSON.stringify(result.mapFormData));
                formData.Form_Response_Entries__r = [];
                formData.expand = this.mapFDExpand[this.currentFormDataId];
                formData.Form_Category__c = formData.Forms_Permission__r.Form_Allocation__r.Form_Category__c;
                formData.Form_Provider__c = formData.Forms_Permission__r.Form_Allocation__r.Form_Provider__c;
                formData.formName = formData.Forms_Permission__r.Form_Allocation__r.Name;
                formData.Submission_Deadline__c = formData.Forms_Permission__r.Form_Allocation__r.Submission_Deadline__c
                formData.Form_Type__c = formData.Forms_Permission__r.Form_Allocation__r.Form_Type__c;
                formData.Form_Entry__c = formData.Forms_Permission__r.Form_Allocation__r.Form_Entry__c;
                if (result.listEntries != null) {
                    let listEntries = JSON.parse(JSON.stringify(result.listEntries));
                    listEntries.forEach(entry => {
                        formData.Form_Response_Entries__r.push(entry);
                    });
                }
                this.allFormDatas.splice(formdataIndex, 1, formData);
                let mapStatuses = {};
                let isAnyChecked = false;
                this.filterField1Options.forEach(row => {
                    mapStatuses[row.value] = row.isChecked;
                    if (row.isChecked) {
                        isAnyChecked = true;
                    }
                });
                let opt = [];
                let listLabel = [];
                this.allFormDatas.forEach(row => {
                    row.Overall_Status__c = mapFormData[row.Id].Overall_Status__c;
                    row.Not_Applicable__c = mapFormData[row.Id].Not_Applicable__c;
                    if (listLabel.indexOf(row.Overall_Status__c) == -1) {
                        let obj = { label: row.Overall_Status__c, value: row.Overall_Status__c, isChecked: false };
                        if (mapStatuses.hasOwnProperty(row.Overall_Status__c)) {
                            obj.isChecked = mapStatuses[row.Overall_Status__c];
                        }
                        opt.push(obj);
                        listLabel.push(row.Overall_Status__c);
                    }
                });
                if (isAnyChecked) {
                    opt.forEach(row => {
                        if (row.value == formData.Overall_Status__c) {
                            row.isChecked = true;
                        }
                    });
                }
                this.filterField1Options = opt;

                this.filterFormData();
                this.getData();
                this.showSpinner = false;
            })
            .catch(error => {
                console.log("===IMCC_FormsTable======refreshTable===");
                console.log(error);
                console.log("===IMCC_FormsTable======refreshTable===");
                this.error = error;
                //  showToast(this, error);
                this.showSpinner = false;
                handleUIErrors(this, error);

            });
    }

    //On Form Data Click Action
    openAction(event) {
        this.methodName = 'openAction';
        const index = parseInt(event.target.dataset.id, 10);
        this.indexNum = index;
        const data = this.tableData[index];
        this.formType = data.Forms_Permission__r.Form_Allocation__r.Form_Type__c;
        let targetId = data.Forms_Permission__r.Form_Allocation__r.Form__c;
        this.formDataId = data.Id;
        this.isPdfAgreed = data.Is_Agreed__c;

        this.formUrl = data.Forms_Permission__r.Form_Allocation__r.Form_Url__c;
        let entryId = data.entryId;
        console.log('ENTRYIDS @@@' + entryId);
        if (entryId == null) {
            entryId = '';
        }
        this.entryId = entryId;
        let formAllocId = data.Forms_Permission__r.Form_Allocation__c;
        let formAllocName = data.Forms_Permission__r.Form_Allocation__r.Name;
        this.formAllocId = formAllocId;
        let entryType = data.Forms_Permission__r.Form_Allocation__r.Form_Entry__c;
        let boothType = data.Forms_Permission__r.Form_Allocation__r.Booth_Product_Types__c;
        let entryLimit = data.Forms_Permission__r.Form_Allocation__r.Entry_Limit__c;
        let ifAllowMultiForm = entryType && (entryType === 'Multiple Per Account' || entryType === 'Multiple Per Booth') ? 1 : 0;
        entryType = entryType ? entryType.toLowerCase() : '';
        let formCategory = data.Forms_Permission__r.Form_Allocation__r.Feature_Category__c;

        const options = [{ label: 'Select booth', value: '' }];
        var pdList = [];
        var bType = (boothType == null || boothType == '' ? [] : boothType.split(';'));
        if (entryType === 'multiple per booth' || entryType === 'one per booth') {
            var submittedIds = [];
            var countOnPDId = {};
            this.boothList = [];
            if (data.Form_Response_Entries__r != null) {
                //alert('Response ' +JSON.stringify(data.Form_Response_Entries__r));
                data.Form_Response_Entries__r.forEach(entry => {
                    if (entry.Status__c == 'Submitted' || entry.Status__c == 'Resubmitted') {
                        if (!entry.Form_Unlock__c) {
                            submittedIds.push(entry.Purchase_Data__c);
                        }
                        countOnPDId[entry.Purchase_Data__c] = (countOnPDId[entry.Purchase_Data__c] == null ? 0 : countOnPDId[entry.Purchase_Data__c]) + 1;
                    }
                });
            }
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
            if (data.isViewed) {
                window.open(this.makeSecureUrl(this.formUrl), '_blank');
            }
            else {
                this.isModalOpenLink = true;
            }
        }
        else if (this.formType == 'Online') {
            if (entryType === 'multiple per account' || entryType === 'one per account') {
                this.redirect('FormPreview__c', {
                    id: targetId,
                    ceid: this.conEdMapId,
                    check: ifAllowMultiForm,
                    ref: "new",
                    accId: this.accountId,
                    edcode: this.eventcode,
                    tabId: this.tabId,
                    formDataId: this.formDataId,
                    entryId: entryId
                });
            }
            else if ((entryType === 'multiple per booth' || entryType === 'one per booth')) {
                if (pdList.length == 0) {
                    let errMSG = (bType.length == 0 ? 'Booths not found' : ('Booths not found for booth types : ' + boothType));
                    showToast(this, errMSG, 'error', 'Error');
                }
                if (pdList.length > 0 && options.length == 1) {
                    let errMSG = (bType.length == 0 ? 'Submission has been made for all booths' : ('Submission has been made for all booths of booth types : ' + boothType));
                    showToast(this, errMSG, 'error', 'Error');
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
        else if (this.formType == 'PDF') {
            this.tableData[index].showFileUpload = false;
            fetchContVerId({ linkEntId: formAllocId })
                .then(result => {
                    let contVerId = result;
                    if (contVerId) {
                        if (formCategory == 'Form') {
                            if ((entryType === 'multiple per booth' || entryType === 'one per booth')) {
                                if (pdList.length == 0) {
                                    let errMSG = (bType.length == 0 ? 'Booths not found' : ('Booths not found for booth types : ' + boothType));
                                    showToast(this, errMSG, 'error', 'Error');
                                }
                                if (pdList.length > 0 && options.length == 1) {
                                    let errMSG = (bType.length == 0 ? 'Submission has been made for all booths' : ('Submission has been made for all booths of booth types : ' + boothType));
                                    showToast(this, errMSG, 'error', 'Error');
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
                                    if (!data.isUploadEnable) {
                                        this.isUploadEnable = data.isUploadEnable;
                                        this.showAfterUploadBtn = false;
                                        this.disableViewBtn = true;
                                        this.disableDeleteBtn = true;
                                        this.disableSubmitBtn = true;
                                    }
                                }
                                this.fetchInstruction();
                            }
                            else {
                                var status = 'Viewed';
                                this.isUploadEnable = data.isUploadEnable;
                                this.showAfterUploadBtn = false;
                                this.disableViewBtn = true;
                                this.disableDeleteBtn = true;
                                this.disableSubmitBtn = true;
                                if (entryType == 'one per account') {
                                    if (data.Form_Response_Entries__r != null) {
                                        data.Form_Response_Entries__r.forEach(entry => {
                                            this.isUploadEnable = entry.isUploadEnable;
                                            if (entry.Status__c != 'Viewed') {
                                                status = '';
                                            }
                                        });
                                    }
                                }
                                this.showPdf = fileDownloadUrl + contVerId;
                                this.downloadModal = true;
                                this.isViewPDFFormEntry = false;
                                if (this.isUploadEnable && status != '') {
                                    this.updateUserViewed(this.formType, this.formDataId, this.conEdMapId, this.entryId, status, "");
                                }
                                this.fetchInstruction();
                            }
                        }

                        if (formCategory == 'Manual') {
                            if(formAllocName == 'Contractors Space Only Regulations'){
                                this.manualTermCon = manualLabel1;
                            }
                            else if(formAllocName == 'Exhibitor Code of Conduct'){
                                this.manualTermCon = manualLabel2;
                            }
                            else if(formAllocName == 'Venue Technical Guidelines'){
                                this.manualTermCon = manualLabel3;
                            }
                            else{
                                this.manualTermCon = 'I have read and agree to the contents of this document';
                            }
                            var status = 'Viewed';
                            this.showPdf = fileDownloadUrl + contVerId;
                            this.downloadModal = true;
                            this.isViewPDFFormEntry = false;
                            if (data.isUploadEnable) {
                                this.updateUserViewed(this.formType, this.formDataId, this.conEdMapId, this.entryId, status, "");
                            }
                        }
                    }
                    else {
                        showToast(this, 'No PDF found for this ' + formCategory, 'error', 'Error');
                    }
                })
                .catch(error => {
                    console.log("===IMCC_FormsTable======openAction===");
                    console.log(error);
                    console.log("===IMCC_FormsTable======openAction===");
                    handleUIErrors(this, error);
                });
        }
        this.tableData[index] = data;
    }

    //To Save Not Appicable Logic
    saveApplicable(event) {
        this.methodName = 'saveApplicable';
        this.showSpinner = true;
        let isApplicable = event.target.checked;
        let formDataId = this.tableData[event.target.dataset.id].Id;
        this.currentFormDataId = formDataId;
        updateApplicableFormData({
            formId: formDataId,
            isApplicable: isApplicable
        })
            .then(result => {
                this.showSpinner = false;
                this.refreshTable();
            })
            .catch(error => {
                console.log("===IMCC_FormsTable======saveApplicable===");
                console.log(error);
                console.log("===IMCC_FormsTable======saveApplicable===");
                this.error = error;
                this.showSpinner = false;
                handleUIErrors(this, error);
            });
    }
    //#endregion

    //#region Form Response Entry Related Methods
    //To Create/Update Form Response Entry
    updateUserViewed(formType, formId, conMapId, entryId, formStatus, boothId) {
        this.currentFormDataId = formId;
        this.methodName = 'updateUserViewed';
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
                this.refreshTable();
            })
            .catch(error => {
                console.log("===IMCC_FormsTable======updateUserViewed===");
                console.log(error);
                console.log("===IMCC_FormsTable======updateUserViewed===");
                this.error = error;
                handleUIErrors(this, error);
            });
    }

    //On Form Response Entry Click Action
    openActionEntry(event) {
        const indexEntry = parseInt(event.target.dataset.id, 10);
        const index = parseInt(event.target.dataset.parentid, 10);
        const data = this.tableData[index];
        const dataEntry = data.Form_Response_Entries__r[indexEntry];
        var formType = data.Forms_Permission__r.Form_Allocation__r.Form_Type__c;
        var targetId = data.Forms_Permission__r.Form_Allocation__r.Form__c;
        var formDataId = data.Id;
        this.formAllocId = data.Forms_Permission__r.Form_Allocation__r.Id;
        let formdataTemp = this.tableData[index];

        let entryLimit = data.Forms_Permission__r.Form_Allocation__r.Entry_Limit__c;
        let formEntry = data.Forms_Permission__r.Form_Allocation__r.Form_Entry__c;

        if (dataEntry.Purchase_Data__c != null) {
            formdataTemp = this.mapPDFD[dataEntry.Purchase_Data__c + '_' + this.formAllocId];
            console.log(JSON.stringify(formdataTemp));
            formDataId = formdataTemp.Id;
        }
        let isPerformAction = true;
        if (dataEntry.Status == 'In Progress' && entryLimit != null && entryLimit != '' && (formEntry == 'Multiple Per Account' || formEntry == 'Multiple Per Booth')) {
            let entryLimitInt = parseInt(entryLimit, 10);
            let submittedResp = formdataTemp.Submitted_Responses__c;
            if (entryLimitInt <= submittedResp) {
                isPerformAction = false;
            }
        }
        if (isPerformAction) {
            let entryId = dataEntry.Id;
            let cemId = dataEntry.Contact_Edition_Mapping__c;
            let contentVerId = dataEntry.Content_Version__c;

            if (formType == 'Online') {
                this.redirect('FormPreview__c', {
                    id: targetId,
                    ceid: cemId,
                    check: 0,
                    ref: "new",
                    accId: this.accountId,
                    edcode: this.eventcode,
                    tabId: this.tabId,
                    formDataId: formDataId,
                    entryId: entryId
                });
            }
            else if (formType == 'PDF') {
                if (dataEntry.isUploadEnable) {
                    let formAllocId = data.Forms_Permission__r.Form_Allocation__c;
                    this.entryId = entryId;
                    this.formType = formType;
                    this.formDataId = formDataId;
                    fetchContVerId({ linkEntId: formAllocId })
                        .then(result => {
                            let contVerId = result;
                            if (contVerId) {
                                this.isUploadEnable = dataEntry.isUploadEnable;
                                this.showAfterUploadBtn = false;
                                this.disableViewBtn = true;
                                this.disableDeleteBtn = true;
                                this.disableSubmitBtn = true;
                                this.showPdf = fileDownloadUrl + contentVerId;
                                this.downloadModal = true;
                                this.formPDFUrl = fileDownloadUrl + contVerId;
                                this.isViewPDFFormEntry = true;
                                this.fetchInstruction();
                            }
                        })
                        .catch(error => {
                            console.log("===IMCC_FormsTable======openActionEntry===");
                            console.log(error);
                            console.log("===IMCC_FormsTable======openActionEntry===");
                        });
                }
                else {
                    if (contentVerId) {
                        this.viewPdf = fileDownloadUrl + contentVerId;
                        this.viewModal = true;
                    }
                }
            }
        }
        else {
            showToast(this, 'Number of allowed submission has been submitted' + (formEntry == 'Multiple Per Booth' ? ' for booth: ' + dataEntry.Purchase_Data__r.Booth_Number__c + '.' : ''), 'error', 'Error');
        }
    }

    //Form Response Entry Delete Modal Opening Method
    handleDelete(event) {
        this.isDeleteModal = true;
        const index = parseInt(event.target.dataset.id, 10);
        const indexParent = parseInt(event.target.dataset.parentid, 10);
        const data = this.tableData[indexParent];
        const dataEntry = data.Form_Response_Entries__r[index];
        this.entryId = dataEntry.Id;
        this.currentFormDataId = dataEntry.Form_Data__c;
    }

    //Form Response Entry Delete Method
    openDeleteAction() {
        this.methodName = 'openDeleteAction';
        this.isDeleteModal = false;
        this.showSpinner = true;
        deleteFormResponse({
            formRespEntryId: this.entryId
        })
            .then(result => {
                let message = result;
                if (message == 'Success') {
                    this.refreshTable();
                    showToast(this, 'Form has been deleted successfully.', 'success', 'Success!');
                }

                this.showSpinner = false;
            })
            .catch(error => {
                console.log("===IMCC_FormsTable======openDeleteAction===");
                console.log(error);
                console.log("===IMCC_FormsTable======openDeleteAction===");
                this.error = error;
                //   showToast(this, error);
                this.showSpinner = false;
                handleUIErrors(this, error);
            });
    }

    //To View Rejection Reason For Form Response Entry
    openReasonModal(event) {
        this.isReasonModal = true;
        const index = parseInt(event.target.dataset.id, 10);
        const indexParent = parseInt(event.target.dataset.parentid, 10);
        const data = this.tableData[indexParent];
        const dataEntry = data.Form_Response_Entries__r[index];
        this.rejectionReason = dataEntry.Rejection_Reason__c;
    }

    //To Show/Hide Form Response Entries List
    toggleDrawer(event) {
        const index = parseInt(event.target.dataset.id, 10);
        this.tableData[index].expand = !this.tableData[index].expand;
        this.mapFDExpand[this.tableData[index].Id] = this.tableData[index].expand;
    }
    //#endregion

    //#region Booth Related Methods
    //Open Form for Selected Booth
    openFormForBooth() {
        if (this.selectedBooth === '') {
            showToast(this, 'Please select a booth', 'error', 'Form Error');
            return false;
        }

        const data = this.tableData[this.indexNum];
        let tempFD = this.mapPDFD[this.selectedBooth + '_' + this.formAllocId];
        this.formDataId = tempFD.Id;

        var entryId = '';
        if (tempFD.Form_Response_Entries__r != null) {
            tempFD.Form_Response_Entries__r.forEach(entry => {
                if ((entry.Status__c == 'Viewed' || tempFD.Forms_Permission__r.Form_Allocation__r.Form_Entry__c == 'One Per Booth') && entry.Purchase_Data__c == this.selectedBooth) {
                    entryId = entry.Id;
                }
            });
        }
        this.entryId = entryId;

        if (data.Forms_Permission__r.Form_Allocation__r.Form_Type__c == 'Online') {
            this.redirect('FormPreview__c', {
                id: this.selectedFormId,
                ceid: this.conEdMapId,
                check: this.isMultiEntry,
                b: this.selectedBooth,
                ref: "new",
                accId: this.accountId,
                edcode: this.eventcode,
                tabId: this.tabId,
                formDataId: this.formDataId,
                entryId: entryId
            });
            this.closeBoothSelector();
        }
        else {
            var status = 'Viewed';
            this.isUploadEnable = data.isUploadEnable;
            this.showAfterUploadBtn = false;
            this.disableViewBtn = true;
            this.disableDeleteBtn = true;
            this.disableSubmitBtn = true;
            this.isOpenBoothSelector = false;
            this.downloadModal = true;
            if (this.isUploadEnable) {
                this.updateUserViewed(this.formType, this.formDataId, this.conEdMapId, this.entryId, status, this.selectedBooth);
            }
        }
    };

    //Close Booth Selector Modal
    closeBoothSelector() {
        this.isOpenBoothSelector = false;
        this.selectedFormId = '';
        this.isMultiEntry = 0;
        this.selectedBooth = '';
    }

    //Booth Selection Handler Method
    handleBoothSelect(event) {
        this.selectedBooth = event.target.value;
    }
    //#endregion

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
        console.log('uploadedFiles:', this.uploadedFiles);
        //this.contentVerId = uploadedFiles[0].contentVersionId;
        let fileSize = [];
        this.uploadedFiles.forEach(item => {
            fileSize.push(item.contentVersionId);
        })
        console.log('fileSize:', fileSize);
        this.isSubmit = false;

        fetchfileUploadSize({ idList: fileSize[0] })
            .then(result => {
                if(result.length > 0){
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
        this.updateUserViewed(this.formType, this.formDataId, this.conEdMapId, this.entryId, 'Submitted', "");
        showToast(this, 'Form has been submitted successfully.', 'success', 'Success!');
        this.downloadModal = false;
        this.isViewPDFFormEntry = false;
        this.closeBoothSelector();
    }

    handledeletePdfModal() {
        this.isDeletePdfModal = true;
    }

    deletePdf() {
        console.log('this.entryId:', this.entryId);
        let entryId = this.entryId;
        this.isSubmit = true;
        this.deleteRecentPdf(entryId);
    }

    deleteRecentPdf(linkEntId) {
        this.methodName = 'deleteRecentPdf';
        this.isDeletePdfModal = false;
        deleteUploadedPdf({ linkEntId: linkEntId })
            .then(result => {
                let message = result;
                if (message == 'Success') {
                    showToast(this, 'Form submission has been successfully deleted.', 'success', 'Success!');
                    this.disableSubmitBtn = true;
                    this.disableViewBtn = true;
                    this.disableDeleteBtn = true;
                }
                else if (message == 'Error') {
                    showToast(this, 'No Form submission found for deletion.', 'error', 'Error!');
                    this.disableSubmitBtn = true;
                    this.disableViewBtn = true;
                    this.disableDeleteBtn = true;
                }
                //this.isDeletePdfModal = false;
            })
            .catch(error => {
                console.log("===IMCC_FormsTable======deleteRecentPdf===");
                console.log(error);
                //this.isDeletePdfModal = false;
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
            if (this.entryId && this.tabtype == 'Forms') {
                this.deleteRecentPdf(this.entryId);
            }
        }
        else {
            this.downloadModal = false;
        }
        this.isViewPDFFormEntry = false;
        this.viewModal = false;
    }
    //#endregion

    //#region Link Form Related Methods
    openLinkForm() {
        this.isModalOpenLink = false;
        window.open(this.makeSecureUrl(this.formUrl), '_blank');
        this.updateUserViewed(this.formType, this.formDataId, this.conEdMapId, this.entryId, 'Submitted', "");
    }

    makeSecureUrl(url) {
        let finalUrl;
        if(url.includes("?")){
            if (!url.includes("http:") && !url.includes("https:")) {
                finalUrl = "https://" + url;
            }
            else{
                finalUrl = url;
            }
        }
        else{
            if (!url.includes("http:") && !url.includes("https:")) {
                finalUrl = "https://" + url + '?accId=' + this.accountId + '&edcode=' + this.eventcode + '&conId=' + this.contactId + '&ceid=' + this.conEdMapId;
            } else {
                finalUrl = url + '?accId=' + this.accountId + '&edcode=' + this.eventcode + '&conId=' + this.contactId + '&ceid=' + this.conEdMapId;
            }
        }
        return finalUrl;
    }

    closeModalLinkForm() {
        this.isModalOpenLink = false;
    }
    //#endregion

    //#region Manual Related Methods
    handleAgreeManual(event) {
        this.isVisibleSaveOnLoad = true;
        this.isManaulAgree = event.target.checked;
        this.isSaveBtnDisable = !this.isManaulAgree;
    }

    saveFormData() {
        this.currentFormDataId = this.formDataId;
        this.methodName = 'saveFormData';
        if (!this.isManaulAgree) {
            showToast(this, 'Please check agreement.', 'error', 'Manual Validation Error!');
            return false;
        }

        this.spinner = true;
        updateFormAgreed({ formDataId: this.formDataId })
            .then(res => {
                this.spinner = false;
                this.refreshTable();
                this.downloadModal = false;
                this.isViewPDFFormEntry = false;
                this.dispatchEvent(new CustomEvent('agreemanual'));
                showToast(this, 'You have successfully view and agreed manual.', 'success', 'Success!');
            })
            .catch(error => {
                console.log("===IMCC_FormsTable======saveFormData===");
                console.log(error);
                console.log("===IMCC_FormsTable======saveFormData===");
                this.spinner = false;
                // showToast(this, error);
                handleUIErrors(this, error);
            })
    }
    //#endregion

    //#region Filter/Sorting Methods
    clearFilter() {
        let option1 = this.filterField1Options;
        option1.forEach(item => {
            item.isChecked = false;
        });
        this.filterField1Options = option1;

        let option2 = this.filterField2Options;
        option2.forEach(item => {
            item.isChecked = false;
        });
        this.filterField2Options = option2;

        let option3 = this.filterField3Options;
        option3.forEach(item => {
            item.isChecked = false;
        });
        this.filterField3Options = option3;

        this.filterFormData();

        if (this.isMoboFilterApplied) {
            this.closeMobileMenu();
            this.isMoboFilterApplied = false;
        }
        this.getData();
    }

    toggleMoboFilter(event) {
        let className = event.currentTarget.dataset.filter;
        if (className === 'filter1') {
            this.template.querySelector('.mob-filter2').classList.remove("active");
            this.template.querySelector('.mob-filter3').classList.remove("active");
            this.template.querySelector('.mob-' + className).classList.toggle("active");
        }
        if (className === 'filter2') {
            this.template.querySelector('.mob-filter1').classList.remove("active");
            this.template.querySelector('.mob-filter3').classList.remove("active");
            this.template.querySelector('.mob-' + className).classList.toggle("active");
        }
        if (className === 'filter3') {
            this.template.querySelector('.mob-filter1').classList.remove("active");
            this.template.querySelector('.mob-filter2').classList.remove("active");
            this.template.querySelector('.mob-' + className).classList.toggle("active");
        }
    }

    moboFilterChange(event) {
        let index = parseInt(event.target.dataset.index, 10);
        let filterName = event.target.dataset.filter;
        if (filterName == "1") {
            this.isMoboFilterApplied = true;
            this.filterField1Options[index].isChecked = event.target.checked;
        }
        else if (filterName == "2") {
            this.isMoboFilterApplied = true;
            this.filterField2Options[index].isChecked = event.target.checked;
        }
        else if (filterName == "3") {
            this.isMoboFilterApplied = true;
            this.filterField3Options[index].isChecked = event.target.checked;
        }
    }

    applyMobileFilter() {
        if (this.isMoboFilterApplied) {
            this.closeMobileMenu();
            this.filterFormData();
            this.getData();
        }
        else {
            showToast(this, 'Please select filter before apply', 'error', 'Validation Error');
        }
    }

    handleFilterChange(event) {
        if (event) {
            let index = parseInt(event.target.dataset.index, 10);
            let filterName = event.target.dataset.filter;
            if (filterName == "1") {
                this.filterField1Options[index].isChecked = event.target.checked;
            }
            else if (filterName == "2") {
                this.filterField2Options[index].isChecked = event.target.checked;
            }
            else if (filterName == "3") {
                this.filterField3Options[index].isChecked = event.target.checked;
            }
        }

        this.filterFormData();
        this.getData();
    }

    handleSorting(event) {
        let prevSortDir = this.sortType;
        let prevSortedBy = this.sortByName;
        this.sortByName = event.currentTarget.id.split("-")[0];
        let iconName = 'utility:up';

        if (this.sortByName === prevSortedBy && prevSortDir === 'asc') {
            this.sortType = 'desc';
            iconName = 'utility:down';
        }
        else if (this.sortByName === prevSortedBy && prevSortDir === 'desc') {
            this.sortType = 'asc';
        }
        else if (this.sortByName !== prevSortedBy) {
            this.sortType = 'asc';
        }
        event.currentTarget.querySelector('lightning-icon').iconName = iconName;
        this.getData();
    }

    setFilterOptions(filterNum, fieldName) {
        let f = fieldName;
        let obj = JSON.parse(JSON.stringify(this.allFormDatas));
        let opt = [];
        let listLabel = [];
        for (let i = 0; i < obj.length; i++) {
            if (obj[i][f] === undefined) {
                if (listLabel.indexOf("N/A") == -1) {
                    opt.push({ label: 'N/A', value: 'NULL', isChecked: false });
                    listLabel.push("N/A");
                }
            }
            else {
                if (listLabel.indexOf(obj[i][f]) == -1) {
                    opt.push({ label: obj[i][f], value: obj[i][f], isChecked: false });
                    listLabel.push(obj[i][f]);
                }
            }
        }
        if (filterNum === 1) {
            this.filterField1Options = opt;
        }
        else if (filterNum === 2) {
            this.filterField2Options = opt;
        }
        else if (filterNum === 3) {
            this.filterField3Options = opt;
        }
    }

    //Fire whenever user type in search box, but data load if search field empty
    searchForm(event) {
        let searchValue = event.detail.value;
        window.clearTimeout(this.delayTimeout);
        this.delayTimeout = setTimeout(() => {
            this.searchValue = searchValue;
            this.filterFormData();
            this.getData();
        }, 750);
    }

    //Used to filter list using all three filters value and fields
    filterFormData() {
        if (this.filterField1Options) {
            let str = "";
            this.filterField1Options.forEach(item => {
                str += (item.isChecked ? ((str === "" ? "" : "','") + item.value) : "");
            });
            this.filterField1Value = str;
        }

        if (this.filterField2Options) {
            let str = '';
            this.filterField2Options.forEach(item => {
                str += (item.isChecked ? ((str === "" ? "" : "','") + item.value) : "");
            });
            this.filterField2Value = str;
        }

        if (this.filterField3Options) {
            let str = '';
            this.filterField3Options.forEach(item => {
                str += (item.isChecked ? ((str === "" ? "" : "','") + item.value) : "");
            });
            this.filterField3Value = str;
        }

        const selectedValue1 = this.filterField1Value ? this.filterField1Value : '';
        const selectedValue2 = this.filterField2Value ? this.filterField2Value : '';
        const selectedValue3 = this.filterField3Value ? this.filterField3Value : '';

        this.filterFormDatas = [];
        let formDatas = JSON.parse(JSON.stringify(this.allFormDatas));
        let formDatasTemp = [];
        formDatas.forEach(row => {
            let f1 = this.filterField1;
            let f2 = this.filterField2;
            let f3 = this.filterField3;
            let val1 = "'" + (row[f1] == null ? "NULL" : row[f1]) + "'";
            let val2 = "'" + (row[f2] == null ? "NULL" : row[f2]) + "'";
            let val3 = "'" + (row[f3] == null ? "NULL" : row[f3]) + "'";
            let include1 = true;
            let include2 = true;
            let include3 = true;
            if (selectedValue1 !== '') {
                if (("'" + selectedValue1 + "'").indexOf(val1) == -1) {
                    include1 = false;
                }
            }
            if (selectedValue2 !== '') {
                if (("'" + selectedValue2 + "'").indexOf(val2) == -1) {
                    include2 = false;
                }
            }
            if (selectedValue3 !== '') {
                if (("'" + selectedValue3 + "'").indexOf(val3) == -1) {
                    include3 = false;
                }
            }
            if (include1 && include2 && include3) {
                formDatasTemp.push(row);
            }
        });

        if (this.searchValue != null && this.searchValue.trim() != '') {
            let searchValue = this.searchValue.trim();
            formDatasTemp.forEach(row => {
                if ((row.Form_Category__c != null && row.Form_Category__c.toLowerCase().indexOf(searchValue.toLowerCase()) != -1)
                    || (row.Form_Provider__c != null && row.Form_Provider__c.toLowerCase().indexOf(searchValue.toLowerCase()) != -1)
                    || (row.formName != null && row.formName.toLowerCase().indexOf(searchValue.toLowerCase()) != -1)
                    || (row.Form_Type__c != null && row.Form_Type__c.toLowerCase().indexOf(searchValue.toLowerCase()) != -1)
                    || (row.Form_Entry__c != null && row.Form_Entry__c.toLowerCase().indexOf(searchValue.toLowerCase()) != -1)
                    || (row.Overall_Status__c != null && row.Overall_Status__c.toLowerCase().indexOf(searchValue.toLowerCase()) != -1)) {
                    this.filterFormDatas.push(row);
                }
            });
        }
        else {
            formDatasTemp.forEach(row => {
                this.filterFormDatas.push(row);
            });
        }
    }

    openFilterOption(event) {
        event.stopPropagation();
        event.currentTarget.classList.toggle('active');
        var classList = "," + event.currentTarget.className.split(" ").join(",") + ",";
        var className = '';
        if (classList.indexOf(',filter1,') != -1) {
            className = 'filter1';
        }
        if (classList.indexOf(',filter2,') != -1) {
            className = 'filter2';
        }
        if (classList.indexOf(',filter3,') != -1) {
            className = 'filter3';
        }
        this.closeFilterOption(className);
    }

    closeFilterOption(className) {
        this.isDropdownOpen = false;
        if (className == null) {
            const filter1 = this.template.querySelector('.filter1');
            if (filter1) {
                filter1.classList.remove('active');
            }
            const filter2 = this.template.querySelector('.filter2');
            if (filter2) {
                filter2.classList.remove('active');
            }
            const filter3 = this.template.querySelector('.filter3');
            if (filter3) {
                filter3.classList.remove('active');
            }
        }
        else {
            if (className != 'filter1') {
                const filter1 = this.template.querySelector('.filter1');
                if (filter1) {
                    filter1.classList.remove('active');
                }
            }
            if (className != 'filter2') {
                const filter2 = this.template.querySelector('.filter2');
                if (filter2) {
                    filter2.classList.remove('active');
                }
            }
            if (className != 'filter3') {
                const filter3 = this.template.querySelector('.filter3');
                if (filter3) {
                    filter3.classList.remove('active');
                }
            }
        }
    }

    onTopClick(event) {
        event.stopPropagation();
    }

    get isFilterApplied() {
        return this.filterField1Value || this.filterField2Value || this.filterField3Value;
    }

    openMobileMenu(event) {
        event.stopPropagation();
        let height = screen.height - 160;
        this.template.querySelector(".mobile-menu-body").style = "height:" + height + "px";
        let progress = 480;
        this._interval = setInterval(() => {
            progress = progress - 100;
            if (progress <= 0) {
                progress = 0;
                clearInterval(this._interval);
                this.template.querySelector(".modal-overlay").classList.add("active");
            }
            this.template.querySelector(".mobile-menu").style = "display: block;transform-style: preserve-3d;-webkit-transform:translate3d(" + progress + "px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);-moz-transform:translate3d(" + progress + "px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);-ms-transform:translate3d(" + progress + "px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);transform:translate3d(" + progress + "px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);";
        }, 10);
    }

    closeMobileMenu() {
        /* working good, don't remove comment before ticket assign*/
        let progress = 0;
        this._interval = setInterval(() => {
            progress = progress + 100;
            if (progress >= 480) {
                progress = 480;
                clearInterval(this._interval);
                this.template.querySelector(".modal-overlay").classList.remove("active");
                this.template.querySelector(".mobile-menu").style = "display: none;transform-style: preserve-3d;-webkit-transform:translate3d(" + progress + "px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);-moz-transform:translate3d(" + progress + "px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);-ms-transform:translate3d(" + progress + "px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);transform:translate3d(" + progress + "px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);";
            }
            this.template.querySelector(".mobile-menu").style = "transform-style: preserve-3d;-webkit-transform:translate3d(" + progress + "px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);-moz-transform:translate3d(" + progress + "px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);-ms-transform:translate3d(" + progress + "px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);transform:translate3d(" + progress + "px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);";
        }, 10);
    }
    //#endregion

    //#region Form Delegate
    checkAssignTo(event) {
        let isApplicable = event.target.checked;
        this.tableData[event.target.dataset.id].checkAssigned = isApplicable;
        this.tableData[event.target.dataset.id].isChecked = isApplicable;

        let isAllChecked = true;
        let isSomeChecked = false;

        this.tableData.forEach(item => {
            if (item.isChecked) {
                isSomeChecked = true;
            }
            if (!item.isChecked) {
                isAllChecked = false;
            }
        });

        if (isSomeChecked) {
            this.template.querySelector('.all').classList.add('indeterminate');
            this.template.querySelector('.all').checked = false;
        }
        else {
            this.template.querySelector('.all').classList.remove('indeterminate');
        }
        if (isAllChecked) {
            this.template.querySelector('.all').classList.remove('indeterminate');
            this.template.querySelector('.all').checked = true;
        }

    }

    get options() {
        return this.conData;
    }

    openAssignToModal() {
        // to open modal set isModalOpen tarck value as true
        this.isModalOpen = true;
    }

    closeModal() {
        //to close modal set isModalOpen tarck value as false
        this.isModalOpen = false;
        this.isDeleteModal = false;
        this.isReasonModal = false;
    }

    submitDetails() {
        //Adding code after assigning the contact for forms delegate
        this.isModalOpen = false;
        let selectedForms = [];
        this.tableData.forEach((row) => {
            if (row.checkAssigned) {
                selectedForms.push(row.Id);
            }
        });

        assignFormsToDelegate({
            conId: this.selectedCon,
            eventCode: this.eventcode,
            formDataIds: selectedForms,
            accountId: this.accountId
        })
            .then()
            .catch(error => {
                this.methodName = 'assignFormsToDelegate';
                handleUIErrors(this, error);
            });
    }

    handleRadioChange(event) {
        const selectedOption = event.detail.value;
        this.selectedCon = selectedOption;
    }

    selectAllRows(event) {
        this.template.querySelector('.all').classList.remove('indeterminate');
        const datas = JSON.parse(JSON.stringify(this.tableData));
        datas.forEach(item => {
            item.isChecked = event.target.checked;
            item.checkAssigned = event.target.checked;
        })
        this.tableData = datas;
    }
    //#endregion

    //#region Common Methods
    //to show/hide spinner
    get isTrue() {
        return this.spinner;
    }

    //to show form/manual count
    get showFormCount() {
        let selectedRows = 0;
        let tableRows = 0;
        if (this.tableData) {
            this.tableData.forEach(item => {
                if (item.isChecked && item.isShowFormData) {
                    selectedRows += 1;
                }
                if (item.isShowFormData) {
                    tableRows += 1;
                }
            });
        }
        let str = 'Showing 0 ' + this.tabtype;
        if (selectedRows > 0) {
            str = 'Selected ' + selectedRows + ' ' + this.tabtype;
        }
        else if (tableRows > 0) {
            str = 'Showing ' + tableRows + ' ' + this.tabtype;
        }

        if ((tableRows > 0 && tableRows === 1) || selectedRows === 1) {
            str = str.replace('Forms', 'Form').replace('Manuals', 'Manual');
        }
        return str;
    }

    //redirect to another page
    redirect(pageName, paramObj) {
        redirect(this, NavigationMixin.Navigate, pageName, paramObj);
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