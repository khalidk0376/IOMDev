/*** This component use on stand design submisison (Step 2) page */
import { LightningElement, track, api, wire } from 'lwc';
import getDatas from '@salesforce/apex/IMCC_CommonTableController.getGenericObjectRecord';
import getAggregateData from '@salesforce/apex/IMCC_CommonTableController.getAggregateData2';
import updateUserFormData from '@salesforce/apex/IMCC_FormsCtrl.updateFormData';
import updateFormAgreed from '@salesforce/apex/IMCC_StandDesignSubmissionCtrl.updateFormAgreed';
import updateApplicableFormData from '@salesforce/apex/IMCC_FormsCtrl.updateApplicableFormData';
import updateFormDataAfterUpload from '@salesforce/apex/IMCC_FormsCtrl.updateFormDataAfterUpload';
import fetchContVerId from '@salesforce/apex/IMCC_FloorplanCtrl.fetchManualPdfDetails';
import assignFormsToDelegate from '@salesforce/apex/IMCC_FormsCtrl.assignFormsToDelegate';
import fileDownloadUrl from '@salesforce/label/c.File_Download_URL';
import fileDownloadUrlForOpsUser from '@salesforce/label/c.File_Download_URL_For_OPS_USER';
import userId from '@salesforce/user/Id';
import { handleErrors, showToast,redirect } from 'c/imcc_lwcUtility';
import { CurrentPageReference,NavigationMixin } from 'lightning/navigation';
import { loadScript } from 'lightning/platformResourceLoader';
import InformaMarketsCSS from '@salesforce/resourceUrl/InformaMarketsCSS';
import IMCC2 from '@salesforce/resourceUrl/IMCC2';
import manualLabel1 from '@salesforce/label/c.Contractors_Space_Only_Regulations_Manual';
import manualLabel2 from '@salesforce/label/c.Exhibitor_Code_of_Conduct_Manual';
import manualLabel3 from '@salesforce/label/c.Venue_Technical_Guidelines_Manual';

const DELAY = 100;
export default class ImccManuals extends LightningElement {
    
    //Pagination properties
    @track pagesize = 1000;
    @track currentPageNo = 1;
    @track totalPages = 0;
    // pagination item list like (1..2-3-4-5..6)    
    @track pageList;
    @track totalrows = 0;
    @track offst = 0;
    @track hasNext = false;
    @track hasPrev = false;
    @track searchValue = '';
    @track showPageView = '0';
    @track sortByFieldName = 'Forms_Permission__r.Form_Allocation__r.Name';
    @api sortByName = 'Forms_Permission__r.Form_Allocation__r.Name';
    @api sortType = 'ASC';
    @api isInReview;
    @api utype;

    //Set object and fields to create datatable
    @track tableData;
    @track tableColumn;
    @api objectName = 'Form_Data__c';
    @api objectLabel = 'Form Data';
    
    @track formUrl;
    @track formDataId;
    @track formType;
    @track uploadAttachId;
    @track url;
    @track formHeader;
    @track isModalOpen = false;
    @track isModalOpenLink = false;
    @track manualTermCon;

    @api fields = 'Forms_Permission__r.Form_Allocation__r.Name,Forms_Permission__r.Form_Allocation__r.Form__r.Category__c,Forms_Permission__r.Form_Allocation__r.Form_Type__c,Forms_Permission__r.Form_Allocation__r.Form_Category__c,Forms_Permission__r.Form_Allocation__r.Form_Provider__c,Forms_Permission__r.Form_Allocation__r.Submission_Deadline__c,Forms_Permission__r.Form_Allocation__r.Form__c,Is_Viewed__c,Is_Agreed__c,Forms_Permission__r.Form_Allocation__r.Approval_Required__c,Forms_Permission__r.Form_Allocation__r.Form_Heading__c,Forms_Permission__r.Form_Allocation__r.CountMultiSubmission__c,Forms_Permission__r.Form_Allocation__r.Allow_Submissions_after_Due_date__c,Status1__c';
    @api fieldsLabel = 'FORM NAME,CATEGORY,FORM TYPE,PROVIDER,DEADLINE,VIEWED,STATUS';
    @api condition = 'Id!=\'\'';
    @api disableLink;
    @api conEdMapId;
    @api searchEnabled;
    @api contactId;
    @api tabtype;
    @track tempCondition = '';    
    @api isViewFile = 'false';    
    @api formtype = '';
    @api editionCode;
    @api accId;
    @track eventcode;
    @track accountId;
    @track tabId;
    @track showLinkOrPdfDialog = false;
    @track showFileUpload = false;
    @track progressPercent = 0;
    //Filter property
    
    @track showMan = false;
    @track showAdd = false;
    @track showOpt = false;

    //filter1
    @api filterField1;
    @api filter1Label;    
    @track filterField1Options;
    @track filterField1Value = '';

    //filter 2
    @api filterField2;
    @api filter2Label;
    @track filterField2Options;
    @track filterField2Value = '';

    //filter 3
    @api filterField3;
    @api filter3Label;    
    @track filterField3Options;
    @track filterField3Value = '';

    @track error;    
    @track spinner;
    @track isShow;
    @track colSpan;

    @track downloadModal = false;
    @track pdf;
    @track bShowModal;
    @track showPagination;
    @track showTable;
    @track url;
    @track showSpinner = true;
    @track recordIdToupload;
    @api eventEditionCode; // used from customer list component
    @track conData =[];
    @track selectedCon = '';
    opsUser = false;

    iconForms = IMCC2+'/icons/form-blue.svg';
    iconFilter = IMCC2+'/icons/filter.svg';
    iconChevron = IMCC2+'/icons/chevron-down-indigo.svg';
    
    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        //alert('utype: '+this.utype);
        loadScript(this, InformaMarketsCSS + '/CustomerCenterWS11/js/jquery-1.7.1.min.js')
        .then(() => {            
            let that = this;
            window.jQuery("body").click(function(event){
                that.closeFilterOption();
            });            
        })
        .catch(errors => {
            console.log(errors);
        });

        this.selectedOwner = userId;
        this.spinner = false;
        this.hasNext = false;
        this.hasPrev = false;
        this.pagesize = 50;
        this.offst = 0;

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
        }
        if (this.tabtype == 'Forms') {
            this.formHeader = 'Form';            
        }
        this.handleFilterChange();
        
        this.filterField1Options = [{label:'Approved',value:'Approved',isChecked:false},
            {label:'In progress',value:'In progress',isChecked:false},
            {label:'In Review',value:'In Review',isChecked:false},
            {label:'Not Started',value:'Not Started',isChecked:false},            
            {label:'Re-submitted',value:'Resubmitted',isChecked:false},
            {label:'Submitted',value:'Submitted',isChecked:false},
            {label:'Viewed',value:'Viewed',isChecked:false}];

        if(this.filterField2!==undefined){
            this.setFilterOptions(2,this.filterField2);
        } 
        if(this.filterField3!==undefined){            
            this.setFilterOptions(3,this.filterField3);
        }

        if (currentPageReference && currentPageReference.state) {
            this.eventcode = currentPageReference.state.edcode;
            this.accountId = currentPageReference.state.accId;
            this.tabId = currentPageReference.state.tabId;                    
        }
    }

    connectedCallback() {
        //alert('utype: '+this.utype);
         if(!window.location.href.includes('IMCC')){
            console.log('window.location.href:::'+window.location.href);
            this.opsUser = true;
            loadScript(this, InformaMarketsCSS + '/CustomerCenterWS11/js/jquery-1.7.1.min.js')
            .then(() => {            
                let that = this;
                window.jQuery("body").click(function(event){
                    that.closeFilterOption();
                });            
            })
            .catch(errors => {
                console.log(errors);
            });
    
            this.selectedOwner = userId;
            this.spinner = false;
            this.hasNext = false;
            this.hasPrev = false;
            this.pagesize = 50;
            this.offst = 0;
    
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
            }
            if (this.tabtype == 'Forms') {
                this.formHeader = 'Form';            
            }
            this.handleFilterChange();
            
            this.filterField1Options = [{label:'Approved',value:'Approved',isChecked:false},
                {label:'In progress',value:'In progress',isChecked:false},
                {label:'In Review',value:'In Review',isChecked:false},
                {label:'Not Started',value:'Not Started',isChecked:false},            
                {label:'Re-submitted',value:'Resubmitted',isChecked:false},
                {label:'Submitted',value:'Submitted',isChecked:false},
                {label:'Viewed',value:'Viewed',isChecked:false}];
    
            if(this.filterField2!==undefined){
                this.setFilterOptions(2,this.filterField2);
            } 
            if(this.filterField3!==undefined){            
                this.setFilterOptions(3,this.filterField3);
            }
    
                this.eventcode = this.editionCode;
                this.accountId = this.accId;
        }
   }

    getData() {
        console.log('Get Data ', 'Get Data');
        this.pagesizeVisible = this.pagesize.toString();
        this.spinner = true;
        getDatas({
            searchValue: this.searchValue,
            objectName: this.objectName,
            fieldstoget: this.fields,
            pagesize: this.pagesize,
            next: this.hasNext,
            prev: this.hasPrev,
            off: this.offst,
            sortBy: this.sortByName,
            sortType: this.sortType,
            condition: this.tempCondition,
            isAggregate: false
        })        
        .then(data => {
            if (this.offst === -1) {
                this.offst = 0;
            }
                            
            this.spinner = false;
            this.isShow = this.spinner === false;

            const totalRows = data.total > 2000 ? 2000 : data.total;
            //this.tableColumn = data.ltngTabWrap?data.ltngTabWrap.tableColumn:[];
            this.tableData = JSON.parse(JSON.stringify(data.ltngTabWrap.tableRecord));;

            this.totalPage = Math.ceil(totalRows / this.pagesize);
            this.totalRows = totalRows;
            this.isMoreThan2000 = data.total > 2000 ? true : false;
            let lastind = parseInt(data.offst + this.pagesize, 10);

            if (data.total < lastind) {
                lastind = data.total;
            }
            if (this.totalRows > 15) {
                this.showPagination = true;
            }
            this.showPageView = 'Showing: ' + parseInt(data.offst + 1, 10) + '-' + lastind;

            //this.generatePageListUtil();
            if (totalRows === 0) {
                this.error = 'No record found';
                console.log('SHow Table ' + this.error);
                this.tableData = undefined;
                this.pageList = undefined;
            } else {
                this.error = undefined;
                this.showTable = 'true';                
                let date2;
                let today = new Date().setHours(0, 0, 0, 0);
                console.log('Today ' + today);
                let manFormCount = 0;
                let totalSum = 0;
                this.tableData.forEach(row => {
                    let deadline = row.Forms_Permission__r.Form_Allocation__r.Submission_Deadline__c;
                    if (deadline) {
                        
                        date2 = new Date(deadline).setHours(0, 0, 0, 0);
                        let prev7Days = new Date(new Date().getTime()-(7*24*60*60*1000)).setHours(0, 0, 0, 0)
                        let next7Days = new Date(new Date().getTime()+(7*24*60*60*1000)).setHours(0, 0, 0, 0);
                        row.statusClass = 's';                        
                        
                        if (row.Status1__c === 'Submitted' || row.Status1__c === 'Approved' || row.Status1__c === 'Agreed') {
                            row.statusClass = 's s-green';
                        }
                        else{
                            if(date2 < today){
                                row.statusClass = 's s-red';
                                //check expired
                                if((!row.Is_Viewed__c || !row.Is_Agreed__c) && !row.Forms_Permission__r.Form_Allocation__r.Allow_Submissions_after_Due_date__c){
                                    row.isExpired = true;
                                }
                            }
                            else if(date2 > next7Days){
                                row.statusClass = 's s-gray';
                            }                        
                            else if(date2 >= prev7Days || date2==today){
                                row.statusClass = 's s-purple';
                            }                            
                        }
                    }



                    let type = row.Forms_Permission__r.Form_Allocation__r.Form_Type__c;
                    row.isLink = type==='Link'?true:false;
                    
                    if (this.formtype == 'Mandatory' && row.Not_Applicable__c == false) {
                        manFormCount = manFormCount + 1;
                        if (row.Status1__c == 'In Review' || row.Status1__c == 'Resubmitted') {
                            totalSum = totalSum + 0.5;
                        }
                        if (row.Status1__c == 'Submitted' || row.Status1__c == 'Approved') {
                            totalSum = totalSum + 1;
                        }
                    }
                    row.notShowAsLink = '';
                    row.checkAssigned = false;
                    //check if pdf and viewed
                    if (row.Forms_Permission__r.Form_Allocation__r.Form_Type__c == 'PDF' && (row.Status1__c == 'Viewed' || row.Status1__c == 'Declined' || row.Status1__c == 'Submitted')) {
                        row.showFileUpload = true;
                    }

                    if (row.Form_Unlock__c == true) {
                        row.notShowAsLink = '';
                        row.showFileUpload = true;
                    }
                    else {
                        if (deadline == null || deadline == '') {
                            if ((row.Status1__c == 'Approved' || row.Status1__c == 'In Review' || row.Status1__c == 'Resubmitted') && row.Forms_Permission__r.Form_Allocation__r.Approval_Required__c == true) {
                                row.notShowAsLink = 'true';
                                row.showFileUpload = false;
                            }
                            else {
                                row.notShowAsLink = '';
                            }
                        }
                        else {
                            if (row.Forms_Permission__r.Form_Allocation__r.Allow_Submissions_after_Due_date__c != true) {
                                if (date2 >= today) {
                                    if ((row.Status1__c == 'Approved' || row.Status1__c == 'In Review' || row.Status1__c == 'Resubmitted') && row.Forms_Permission__r.Form_Allocation__r.Approval_Required__c == true) {
                                        row.notShowAsLink = 'true';
                                        row.showFileUpload = false;
                                    }
                                    else {
                                        row.notShowAsLink = '';
                                    }
                                }
                                else {
                                    row.notShowAsLink = 'true';
                                    row.showFileUpload = false;
                                }
                            }
                            else {
                                if ((row.Status1__c == 'Approved' || row.Status1__c == 'In Review' || row.Status1__c == 'Resubmitted') && row.Forms_Permission__r.Form_Allocation__r.Approval_Required__c == true) {
                                    row.notShowAsLink = 'true';
                                    row.showFileUpload = false;
                                }
                                else {
                                    row.notShowAsLink = '';
                                }

                            }
                        }
                    }
                    if(this.disableLink){
                        row.notShowAsLink=true;
                    }
                });
                if (manFormCount == 0) {
                    this.progressPercent = 100;
                }
                else {
                    this.progressPercent = ((totalSum * 100) / manFormCount).toFixed(2);
                }
            }
            this.showSpinner = false;

        })
        .catch(error => {
            this.tableData = undefined;
            this.error = error;
            handleErrors(this, error);
            this.showSpinner = false;
        });
    }

    clearFilter(){
        
        let option1 = this.filterField1Options;
        option1.forEach(item=>{
            item.isChecked = false;
        });
        this.filterField1Options = option1;

        let option2 = this.filterField2Options;
        option2.forEach(item=>{
            item.isChecked = false;
        });
        this.filterField2Options = option2;

        let option3 = this.filterField3Options;
        option3.forEach(item=>{
            item.isChecked = false;
        });
        this.filterField3Options = option3;

        let condition = this.buildCondition();
        window.clearTimeout(this.delayTimeout);
        
        if(this.isMoboFilterApplied){
            this.closeMobileMenu();
            this.isMoboFilterApplied = false;
        }

        this.delayTimeout = setTimeout(() => {
            this.offst = 0;
            this.currentPageNo = 1;
            this.hasNext = false;
            this.hasPrev = false;
            this.tempCondition = condition;
            this.getData();
        }, DELAY)
    };
    toggleMoboFilter(event){
        let className = event.currentTarget.dataset.filter;
        if(className==='filter1'){
            this.template.querySelector('.mob-filter2').classList.remove("active");
            this.template.querySelector('.mob-filter3').classList.remove("active");
            this.template.querySelector('.mob-'+className).classList.toggle("active");
        }
        if(className==='filter2'){
            this.template.querySelector('.mob-filter1').classList.remove("active");
            this.template.querySelector('.mob-filter3').classList.remove("active");
            this.template.querySelector('.mob-'+className).classList.toggle("active");
        }
        if(className==='filter3'){
            this.template.querySelector('.mob-filter1').classList.remove("active");
            this.template.querySelector('.mob-filter2').classList.remove("active");
            this.template.querySelector('.mob-'+className).classList.toggle("active");
        }
    };

    @track isMoboFilterApplied=false;
    moboFilterChange(event){
        let index = parseInt(event.target.dataset.index,10);
        let filterName = event.target.dataset.filter;
        if(filterName=="1"){
            this.isMoboFilterApplied = true;
            this.filterField1Options[index].isChecked = event.target.checked;            
        }
        else if(filterName=="2"){
            this.isMoboFilterApplied = true;
            this.filterField2Options[index].isChecked = event.target.checked;            
        }
        else if(filterName=="3"){
            this.isMoboFilterApplied = true;
            this.filterField3Options[index].isChecked = event.target.checked;            
        }
    }

    applyMobileFilter(){
        if(this.isMoboFilterApplied)
        {
            this.closeMobileMenu();
            let condition = this.buildCondition();
            window.clearTimeout(this.delayTimeout);
            console.log('Condition *** ' + condition);
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            this.delayTimeout = setTimeout(() => {
                this.offst = 0;
                this.currentPageNo = 1;
                this.hasNext = false;
                this.hasPrev = false;
                this.tempCondition = condition;
                this.getData();
            }, DELAY);
        }
        else{
            showToast(this,'Please select filter before apply','error','Validation Error');
        }
    };

    @track pagesizeVisible
    handleFilterChange(event) {
        if(event){
            let index = parseInt(event.target.dataset.index,10);
            let filterName = event.target.dataset.filter;
            if(filterName=="1"){
                this.filterField1Options[index].isChecked = event.target.checked;            
            }
            else if(filterName=="2"){
                this.filterField2Options[index].isChecked = event.target.checked;            
            }
            else if(filterName=="3"){
                this.filterField3Options[index].isChecked = event.target.checked;            
            }
        }
        console.log(this.filterField1Options);

        let condition = this.buildCondition();
        window.clearTimeout(this.delayTimeout);
        console.log('Condition *** ' + condition);
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.delayTimeout = setTimeout(() => {
            this.offst = 0;
            this.currentPageNo = 1;
            this.hasNext = false;
            this.hasPrev = false;
            this.tempCondition = condition;
            this.getData();
        }, DELAY)
    }

    resetColumnClass() {
        const els = this.template.querySelectorAll(".slds-is-sortable");
        els.forEach((item) => {            
            item.querySelector('lightning-icon').iconName = 'utility:arrowup';
            item.querySelector('lightning-icon').style = 'fill:rgb(0, 112, 210)';
        });
    }

    handleSorting(event) {
        let prevSortDir = this.sortType;
        let prevSortedBy = this.sortByName;
        const newSortedBy = event.currentTarget.id.split('-')[0];
        let iconName = 'utility:up';
        let sortFieldName = newSortedBy;

        this.sortByFieldName = sortFieldName;
        if (sortFieldName.toLowerCase().indexOf('namelink') >= 0 || sortFieldName.toLowerCase().indexOf('name__clink') >= 0) {
            const n = sortFieldName.lastIndexOf('Link');
            sortFieldName = sortFieldName.slice(0, n) + sortFieldName.slice(n).replace('Link', '').trim();
        }
        this.sortByName = sortFieldName;
        if (sortFieldName === prevSortedBy && prevSortDir === 'asc') {
            this.sortDirection = 'desc';
            this.sortType = 'desc';
            iconName = 'utility:down';
        }
        else if (sortFieldName === prevSortedBy && prevSortDir === 'desc') {
            this.sortDirection = 'asc';
            this.sortType = 'asc';
            iconName = 'utility:up';
        }
        else if (sortFieldName !== prevSortedBy) {
            this.sortDirection = 'asc';
            this.sortType = 'asc';
            iconName = 'utility:up';
        }
        window.clearTimeout(this.delayTimeout);
        const ele = event.currentTarget;
        this.resetColumnClass();        
        event.currentTarget.querySelector('lightning-icon').iconName = iconName;

        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.delayTimeout = setTimeout(() => {
            this.currentPageNo = 1;
            this.offst = 0;
            this.hasNext = false;
            this.hasPrev = false;
            this.getData();
        }, DELAY);
    }

    get isTrue() {
        return this.spinner;
    }

    get acceptedFormats() {
        return ['.pdf'];
    }
    @track isOpenBoothSelector=false;
    @track selectedFormId = '';
    @track isMultiEntry=0;
    @track selectedFormName='';
    @track selectedBooth='';
    @track delegateId='';
    @track isAlreadyAgreed;
    openAction(event) {
        
        const index = parseInt(event.target.dataset.id, 10);
        const data = this.tableData[index];
        //return if expired
        if(data.isExpired){            
            return false;
        }
        this.formType = data.Forms_Permission__r.Form_Allocation__r.Form_Type__c;        
        this.formDataId = data.Id;         
        let formUrl = data.Forms_Permission__r.Form_Allocation__r.Form_Url__c;
        this.formUrl = formUrl;
        let formAllocId = data.Forms_Permission__r.Form_Allocation__c;
        let formAllocName = data.Forms_Permission__r.Form_Allocation__r.Name;
        let entryType = data.Forms_Permission__r.Form_Allocation__r.Form_Entry__c;        
        entryType = entryType?entryType.toLowerCase():'';
        
        if (this.formType == 'PDF') {
            this.tableData[index].showFileUpload = true;
            fetchContVerId({ linkEntId: formAllocId })
            .then(result => {
                let contVerId = result;
                console.log('contVerId ' + contVerId);
                if (contVerId) {
                    this.isAlreadyAgreed = data.Is_Agreed__c?true:false;
                    if(this.opsUser){
                        this.showPdf = fileDownloadUrlForOpsUser + contVerId;
                    }
                    else{
                        this.showPdf = fileDownloadUrl + contVerId;
                    }
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
                    this.downloadModal = true;
                    //alert('tttt: '+data.Is_Viewed__c);
                    if(!data.Is_Viewed__c && !this.isInReview){
                        this.updateUserViewed(this.formType, this.formDataId, 'true', null, this.conEdMapId);
                    }
                }
            })
            .catch(error => {
                console.error('error...12' + JSON.stringify(error));
            });
        }
        this.tableData[index] = data;
    };
    
    closeBoothSelector(){
        this.isOpenBoothSelector = false;
        this.selectedFormId = '';
        this.isMultiEntry = 0;
        this.selectedBooth='';
    };

    handleBoothSelect(event){
        this.selectedBooth = event.target.value;
    };

    openOnlineForm(){        
        if(this.selectedBooth===''){
            showToast(this,'Please select a both','error','Form Error');
            return false;
        }
        this.redirect('FormPreview__c',{
            id:this.selectedFormId,
            ceid:this.delegateId?this.delegateId:this.conEdMapId,
            check:this.isMultiEntry,
            b:this.selectedBooth,
            ref:"new",
            accId:this.accountId,
            edcode:this.eventcode,
            tabId:this.tabId,
            formDataId:this.formDataId
        });
        this.closeBoothSelector();
    };

    updateUserViewed(formType, formId, isView, targetId, conMapId) {
        updateUserFormData({
            formType: formType,
            formId: formId,
            isViewed: isView,
            formTempId: targetId,
            conEdMapId: conMapId
        })
        .then(result => {
            this.view = result.Is_Viewed__c;
            console.log('Viewed +++ ' + result);
            this.refreshTable();
        })
        .catch(error => {
            window.console.log('error...' + JSON.stringify(error));
            this.error = error;
        });
    }
    makeSecureUrl(url) {
        let finalUrl;
        if (!url.includes("http:") && !url.includes("https:")) {
            finalUrl = "https://" + url + '?accId=' + this.accountId + '&edcode=' + this.eventcode + '&conId=' + this.contactId + '&ceid=' + this.conEdMapId;
        } else {
            finalUrl = url + '?accId=' + this.accountId + '&edcode=' + this.eventcode + '&conId=' + this.contactId + '&ceid=' + this.conEdMapId;
        }
        return finalUrl;
    }
    handleUploadFinished(event) {
        // Get the list of uploaded files
        const uploadedFiles = event.detail.files;
        let formDataId = this.tableData[event.target.dataset.id].Id;
        updateFormDataAfterUpload({
            formId: formDataId
        })
            .then(result => {
                console.log('Message ' + result);
                this.refreshTable();

            })
            .catch(error => {
                window.console.log('error...' + JSON.stringify(error));
                this.error = error;
            });
    }
    saveApplicable(event) {
        let isApplicable = event.target.checked;
        let formDataId = this.tableData[event.target.dataset.id].Id;
        console.log('Value 123 ' + isApplicable);
        console.log('formDataId ' + formDataId);
        updateApplicableFormData({
            formId: formDataId,
            isApplicable: isApplicable
        })
            .then(result => {
                console.log('Viewed +++ ' + result);
                this.refreshTable();
            })
            .catch(error => {
                window.console.log('error...' + JSON.stringify(error));
                this.error = error;
            });
    }

    ClosePopup() {
        this.downloadModal = false;
    }

    @api
    refreshTable() {
        this.getData();
    }
    
    @track indeterminates;
    checkAssignTo(event) {
        let isApplicable = event.target.checked;
        let formDataId = this.tableData[event.target.dataset.id].Id;        
        this.tableData[event.target.dataset.id].checkAssigned = isApplicable;
        this.tableData[event.target.dataset.id].isChecked = isApplicable;
        
        let isAllChecked = true;
        let isSomeChecked = false;
        
        this.tableData.forEach(item=>{            
            if(item.isChecked){
                isSomeChecked = true;
            }
            if(!item.isChecked){
                isAllChecked = false;
            }
        });

        if(isSomeChecked){            
            this.template.querySelector('.all').classList.add('indeterminate');
            this.template.querySelector('.all').checked = false;
        }
        else{
            this.template.querySelector('.all').classList.remove('indeterminate');
        }
        if(isAllChecked){
            this.template.querySelector('.all').classList.remove('indeterminate');
            this.template.querySelector('.all').checked = true;
        }

    }    

    openAssignToModal() {
        // to open modal set isModalOpen tarck value as true
        this.isModalOpen = true;
    }

    closeModal() {
        // to close modal set isModalOpen tarck value as false
        this.isModalOpen = false;
        this.refreshTable();
    }
    submitDetails() {
        //Adding code after assigning the contact for forms delegate
        //alert(this.selectedCon);
        this.isModalOpen = false;
        let selectedForms = [];
        this.tableData.forEach((row) => {
            if(row.checkAssigned){
                selectedForms.push(row.Id);
            }
        });
        console.log('===FormIds',selectedForms);
        //assignFormsToDelegate(this.selectedCon,this.eventcode,selectedForms);
        assignFormsToDelegate({
            conId: this.selectedCon,
            eventCode: this.eventcode,
            formDataIds:selectedForms,
            accountId:this.accountId
        })
        this.refreshTable();
    }
    handleRadioChange(event) {
        const selectedOption = event.detail.value;
        this.selectedCon = selectedOption;
    }
    openMobileMenu(event){
        event.stopPropagation();
        let height = screen.height - 160;
        this.template.querySelector(".mobile-menu-body").style="height:"+height+"px";        
        let progress = 480;
        this._interval = setInterval(() => {
            progress = progress - 100;              
            if ( progress <= 0 ) {  
                progress = 0;
                clearInterval(this._interval);  
                this.template.querySelector(".modal-overlay").classList.add("active");
            }
            this.template.querySelector(".mobile-menu").style = "display: block;transform-style: preserve-3d;-webkit-transform:translate3d("+progress+"px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);-moz-transform:translate3d("+progress+"px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);-ms-transform:translate3d("+progress+"px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);transform:translate3d("+progress+"px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);";
        }, 10);
    };

    closeMobileMenu(){  
        /* working good, don't remove comment before ticket assign*/
        let progress = 0;
        this._interval = setInterval(() => {  
            progress = progress + 100;
            if ( progress >= 480 ) {  
                progress = 480;
                clearInterval(this._interval);  
                this.template.querySelector(".modal-overlay").classList.remove("active");
                this.template.querySelector(".mobile-menu").style = "display: none;transform-style: preserve-3d;-webkit-transform:translate3d("+progress+"px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);-moz-transform:translate3d("+progress+"px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);-ms-transform:translate3d("+progress+"px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);transform:translate3d("+progress+"px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);";
            }
            this.template.querySelector(".mobile-menu").style = "transform-style: preserve-3d;-webkit-transform:translate3d("+progress+"px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);-moz-transform:translate3d("+progress+"px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);-ms-transform:translate3d("+progress+"px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);transform:translate3d("+progress+"px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);";
        }, 10);
    };

    /**
     * Called apex action to get aggregate data to set filter options
     * @param filterNum pass which filter number there are three filter but you have to pass filter number
     * @param fieldName field api name name 
     */
    setFilterOptions(filterNum,fieldName){
        getAggregateData({condition:this.condition,objectName:this.objectName,fieldName:fieldName})
        .then(result=>{
            let f = fieldName.split('.');
            if(f.length === 1){
                f = fieldName;
            }
            else if(f.length === 2){
                f = f[1];
            }
            else if(f.length === 3){
                f = f[2];
            }
            else if (f.length === 4) {
                f = f[3];
            }
            else if (f.length === 5) {
                f = f[4];
            }

            let obj = JSON.parse(JSON.stringify(result));
            let opt =[];
            
            for(let i=0;i<obj.length;i++){
                if(obj[i][f]===undefined){
                    opt.push({label:'N/A',value:'NULL',isChecked:false});
                }
                else{
                    opt.push({label:obj[i][f],value:obj[i][f],isChecked:false});
                }
            }
            if(filterNum === 1){
                //opt.splice(0,0,{label:'All '+this.filter1Label,value:'',isChecked:true});
                this.filterField1Options = opt;    
            }
            else if(filterNum === 2){
                //opt.splice(0,0,{label:'All '+this.filter2Label,value:'',isChecked:true});
                this.filterField2Options = opt;    
            }
            else if(filterNum === 3){
                //opt.splice(0,0,{label:'All '+this.filter3Label,value:'',isChecked:true});
                this.filterField3Options = opt;    
            }
            console.log(opt);
        })
        .catch(error=>{
            console.error(error);
            handleErrors(this,error);
        });
    }

    /**
     * Fire whenever user type in search box, but data load if search field empty      * 
     */
     searchForm(event){
        let searchValue = event.detail.value;
        searchValue = searchValue.trim();
        window.clearTimeout(this.delayTimeout);
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.delayTimeout = setTimeout(() => {
            this.offst = 0;
            this.currentPageNo = 1;
            this.hasNext = false;
            this.hasPrev = false;   
            this.searchValue = searchValue;                
            this.getData();
        },DELAY);
    };

    get showFormCount(){
        let selectedRows = 0;
        if(this.tableData){
            this.tableData.forEach(item=>{
                if(item.isChecked){
                    selectedRows += 1;
                }
            });
        }
        let str = 'Showing 0 '+this.tabtype;
        if(selectedRows>0){
            str = 'Selected '+selectedRows+' '+this.tabtype;
        }
        else if(this.tableData){
            str = 'Showing '+this.tableData.length+' '+this.tabtype;
        }
        
        if((this.tableData && this.tableData.length===1) || selectedRows===1){
            str = str.replace('Forms','Form').replace('Manuals','Manual');
        }
        return str;
    }

    

    /**
     * Used to build condition of all three filters value and fields
     */
    buildCondition(){
        let condition = this.condition;        
        
        if(this.filterField1Options){
            let str = '';
            this.filterField1Options.forEach(item=>{
                if(str===''){
                    str = item.isChecked?item.value:''; 
                }
                else{
                    str += item.isChecked?"','"+item.value:''; 
                }
            });
            this.filterField1Value = str;
        }
        
        if(this.filterField2Options){
            let str = '';
            this.filterField2Options.forEach(item=>{
                if(str===''){
                    str = item.isChecked?item.value:''; 
                }
                else{
                    str += item.isChecked?"','"+item.value:''; 
                }
            });
            this.filterField2Value = str;
        }

        if(this.filterField3Options){
            let str = '';
            this.filterField3Options.forEach(item=>{
                if(str===''){
                    str = item.isChecked?item.value:''; 
                }
                else{
                    str += item.isChecked?"','"+item.value:''; 
                }
            });
            this.filterField3Value = str;
        }

        const selectedValue1 = this.filterField1Value?this.filterField1Value:'';
        const selectedValue2 = this.filterField2Value?this.filterField2Value:'';
        const selectedValue3 = this.filterField3Value?this.filterField3Value:'';

        let customCond = '';
        if(selectedValue1!=='' && selectedValue2!=='' && selectedValue3!=='')
        {            
            customCond = customCond + ' AND ('+this.filterField1+' IN (\''+selectedValue1+'\') ';
            customCond = customCond + ' AND '+this.filterField2+' IN (\''+selectedValue2+'\') ';
            customCond = customCond + ' AND '+this.filterField3+' IN (\''+selectedValue3+'\')) ';
        }
        else if(selectedValue1!=='' && selectedValue2!=='' && selectedValue3===''){
            customCond = customCond + ' AND ('+this.filterField1+' IN (\''+selectedValue1+'\') ';
            customCond = customCond + ' AND '+this.filterField2+' IN (\''+selectedValue2+'\')) ';
        }
        else if(selectedValue1!=='' && selectedValue2==='' && selectedValue3!==''){
            customCond = customCond + ' AND ('+this.filterField1+' IN (\''+selectedValue1+'\') ';
            customCond = customCond + ' AND '+this.filterField3+' IN (\''+selectedValue3+'\')) ';
        }
        else if(selectedValue1==='' && selectedValue2!=='' && selectedValue3!==''){
            customCond = customCond + ' AND ('+this.filterField2+' IN (\''+selectedValue2+'\') ';
            customCond = customCond + ' AND '+this.filterField3+' IN (\''+selectedValue3+'\')) ';
        }
        else if(selectedValue1!==''){
            customCond = customCond + ' AND ('+this.filterField1+' IN (\''+selectedValue1+'\')) ';
        }
        else if(selectedValue2!==''){
            customCond = customCond + ' AND ('+this.filterField2+' IN (\''+selectedValue2+'\')) ';
        }
        else if(selectedValue3!==''){
            customCond = customCond + ' AND ('+this.filterField3+' IN (\''+selectedValue3+'\')) ';
        }
        customCond = customCond.replace(/NULL/g,'');
        console.log('filterField1Value: '+this.filterField1Value);
        return condition+customCond;
    };
    
    openFilterOption(event){
        event.stopPropagation();        
        this.closeFilterOption();        
        event.currentTarget.classList.toggle('active');        
    };
    closeFilterOption(){
        this.isDropdownOpen = false;
        const filter1 = this.template.querySelector('.filter1');
        if(filter1){
            filter1.classList.remove('active');   
        }
        const filter2 = this.template.querySelector('.filter2');
        if(filter2){
            filter2.classList.remove('active');   
        }
        const filter3 = this.template.querySelector('.filter3');
        if(filter3){
            filter3.classList.remove('active');   
        }
    };

    onTopClick(event){
        event.stopPropagation();
    };

    get isFilterApplied(){
        return this.filterField1Value || this.filterField2Value || this.filterField3Value;
    };

    selectAllRows(event){
        this.template.querySelector('.all').classList.remove('indeterminate');
        const datas = JSON.parse(JSON.stringify(this.tableData));
        datas.forEach(item=>{
            item.isChecked = event.target.checked;
            item.checkAssigned = event.target.checked;
        })
        this.tableData = datas;
    };

    redirect(pageName,paramObj){
        redirect(this,NavigationMixin.Navigate,pageName,paramObj);        
    };

    openLinkForm() {
        this.isModalOpenLink = false;
        window.open(this.makeSecureUrl(this.formUrl), '_blank');
        this.updateUserViewed(this.formType, this.formDataId, 'true', null, null);        
    }

    closeModalLinkForm() {
        this.isModalOpenLink = false;
    }

    @track isManaulAgree;
    @track isSaveBtnDisable;
    handleAgreeManual(event){         
        this.isManaulAgree = event.target.checked;
        this.isSaveBtnDisable = !this.isManaulAgree;
    }
    
    saveFormData(){
        if(!this.isManaulAgree){
            showToast(this,'Please check agreement.','error','Manual Validation Error!');
            return false;
        }

        this.spinner = true;
        updateFormAgreed({formDataId:this.formDataId})
        .then(res=>{
            this.spinner = false;
            this.getData();
            this.downloadModal = false;
            this.dispatchEvent(new CustomEvent('agreemanual'));
            showToast(this,'You have successfully view and agreed manual.','success','Success!');
        })
        .catch(error=>{
            this.spinner = false;
            showToast(this,error);
        })
    }
}