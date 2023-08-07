import { LightningElement,track,wire,api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import getContactEditionMappings from '@salesforce/apex/IMCC_EditionWelcomeEmail.getContactEditionMappings';
import sendWelcomeEmail from '@salesforce/apex/IMCC_EditionWelcomeEmail.sendWelcomeEmail';
import checkSendWelcomeEmailStatus from '@salesforce/apex/IMCC_EditionWelcomeEmail.checkSendWelcomeEmailStatus';
import getAsyncJob from '@salesforce/apex/IMCC_EditionWelcomeEmail.getJobs';
import welcomeEmailAlert from '@salesforce/label/c.IMCC_Send_WelcomeEmail_Alert';
import sendWelcomeEmailErrorMessage from '@salesforce/label/c.IMCC_Send_Welcome_Email_Error_Message';
import welcomeEmailErrorMsg3 from '@salesforce/label/c.IMCC_Welcome_Email_Error_Msg3';
import welcomeEmailErrorMsg4 from '@salesforce/label/c.IMCC_Welcome_Email_Error_Msg4';
import { loadStyle } from "lightning/platformResourceLoader";
import QuickActionPanel from "@salesforce/resourceUrl/QuickActionPanel";

export default class IMCC_welcomeEmail extends LightningElement {
    @track sortedDirection = 'asc';
    @track sortedBy = 'ContactName';
    @api searchKey = '';
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
    isPageChanged = false;
    @track progress = 0;
    @track processStatus = 'In Progress';
    @track transDetail = {};
    
    tableData;
    rows =[];
    showModal = false;
    showModal2 = false;
    sendEmailResult;
    recordId;
    edition;
    isLoaded = false;
    isShowTable = false;
    isShowProgress = false;
    isShowBatchProgress = false;
    isShowDetailedInfo = false;
    cssClass = "cemRecordsContainer";
    delayTimeout;
      
    label = {
        welcomeEmailAlert : welcomeEmailAlert, 
        sendWelcomeEmailErrorMessage : sendWelcomeEmailErrorMessage, 
        welcomeEmailErrorMsg3 : welcomeEmailErrorMsg3, 
        welcomeEmailErrorMsg4 : welcomeEmailErrorMsg4
    };

    isShowBatch1StatusProgress;
    batch1Step;
    batch1hasError;
    batch1Name;
    batch1processStatus;
    batch1Id;
    batch1Size;
    isShowItem1Progress = false;
    process1Status;
    total1Progress;
    batch1processStatusMain;
    totalRecords;
    hasSyncErrors = false;
    allRecords;
    batchSize = 50;
    @track batchStatus = [];
		
		@track valueEL = 'All';
		get eventLoggers() {
            return [
                { label: 'All', value: 'All' },
                { label: 'Who logged in', value: 'Whologgedin' },
                { label: 'Did not log in', value: 'Didnotlogin' },
            ];
		}

		handleChangeEventLoggers(event) {
            this.valueEL = event.detail.value;
            this.getAllOrFilteredCEMRecords();
        }
		
        @track valueER = 'All';
		get welcomeEmailreceivers() {
            return [
                { label: 'All', value: 'All' },
                { label: 'Received Email', value: 'ReceivedEmail' },
                { label: 'Did not receive email', value: 'Didnotreceiveemail' },
            ];
		}

		handleChangeWelcomeEmailreceivers(event) {
            this.valueER = event.detail.value; 
            this.getAllOrFilteredCEMRecords();
        }
		
    /*
    @track selectedOption;
    changeHandler(event) {
        const field = event.target.name;
        if (field === 'optionSelect') {
            this.selectedOption = event.target.value;  
        }
    }*/


    @track columns=[
        {label: 'First Login Date Time', fieldName:'FirstLoginDateTime', type: 'date',sortable: true, typeAttributes: {day: 'numeric',  
            month: 'short',  
            year: 'numeric',  
            hour: '2-digit',  
            minute: '2-digit',  
            second: '2-digit',  
            hour12: true} },
        {label: 'Contact Name', fieldName:'ContactName', type: 'text',sortable: true },
        {label: 'Company Name ', fieldName:'AccountName', type: 'text',sortable: true },
        {label: 'Contact Email ', fieldName:'ContactEmail', type: 'email',sortable: true },
        {label: 'Is Email Sent', fieldName:'IsEmailSent', type: 'boolean',sortable: true },
        {label: 'Email Sent Date ', fieldName:'EmailSentDate', type: 'date',sortable: true },
        {label: 'User Type ', fieldName:'UserType', type: 'text',sortable: true }
    ];

    connectedCallback() {
        loadStyle(this, QuickActionPanel);      
        this.batch1processStatusMain ='';
        this.batchStatus.push({label:"Initiating",step:1,hasError:false});                
        this.batchStatus.push({label:"Holding",step:2,hasError:false});
        this.batchStatus.push({label:"Queued",step:3,hasError:false});
        this.batchStatus.push({label:"Preparing",step:4,hasError:false});
        this.batchStatus.push({label:"Processing",step:5,hasError:false});
        this.batchStatus.push({label:"Completed",step:6,hasError:false});
        this.batchStatus.push({label:"Failed",step:7,hasError:true});
        this.batchStatus.push({label:"Aborted",step:8,hasError:true});
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if(currentPageReference){
            this.isLoaded = false;
            this.checkWelcomeEmail(currentPageReference.state.recordId);
        }
    }

    getAllOrFilteredCEMRecords(){
        getContactEditionMappings({ editionId: this.recordId, searchKey: this.searchKey, sortBy: this.sortedBy, sortDirection: this.sortedDirection,eventLogger: this.valueEL, eventReceiver: this.valueER})
            .then(data => {
                let contactLists = [];
                this.tableData = [];
                this.items = [];
                data.forEach((row) => {            
                    let contact = {};
                    contact.Id=row.Id;
                    if(row.First_Login_Date_Time__c !=null){
                        contact.FirstLoginDateTime = row.First_Login_Date_Time__c;
                    }else{
                        //contact.FirstLoginDateTime = Datetime.Now(); 
                    }
                    contact.ContactName = row.Contact__r.Name;
                    contact.IsEmailSent = row.IsEmailSent__c;
                    contact.EmailSentDate = row.Email_Sent__c;
                    contact.ContactEmail = row.Contact_Email__c;
                    contact.AccountName = row.Account__r.Name;
                    contact.UserType = row.Access_Type__c;
                    contactLists.push(contact);
                });
                   
                this.items = contactLists;
                this.allRecords = JSON.parse(JSON.stringify(contactLists));
                this.totalRecountCount = contactLists.length; 
                this.totalPage = Math.ceil(this.totalRecountCount / this.pageSize);
                if(this.totalPage == 1){
                    this.page = 1;
                }
                this.displayRecordPerPage(this.page);
                this.isLoaded = true;
            })
            .catch(error => {
                console.error(error);
            });
    }
    
    checkWelcomeEmail(recId){
        checkSendWelcomeEmailStatus({editionId : recId}) 
        .then(result => {
            this.sendEmailResult = (result.editionRecs[0].Customer_Center_Status__c == 'Active');
            this.edition = result.editionRecs[0];
            if(this.sendEmailResult === false){
                this.isLoaded = true;
                const evt = new ShowToastEvent({
                    title : 'Customer center status is not Active.',
                    variant : 'error'
                });
                this.dispatchEvent(evt);
                this.closeAction();
            }
            if(!result.hasWelcomeEmailTemplate){
                this.isLoaded = true;
                const evt = new ShowToastEvent({
                    title :  this.label.welcomeEmailErrorMsg4,
                    variant : 'error'
                });
                this.dispatchEvent(evt);
                this.closeAction();
            }
            if(this.sendEmailResult == true && result.hasWelcomeEmailTemplate == true){
                if(this.edition.Welcome_Email_Job_Status__c == 'In Progress'){
                    this.cssClass = "progressContainer";
                    this.isShowTable = false;
                    this.isShowProgress = true;
                    this.isShowBatchProgress = true;
                    this.batch1Id = this.edition.Welcome_Email_Job_Id__c;
                    this.batchinProgress(this.batch1Id);
                    this.isLoaded = true;
                }
                else{
                    this.recordId = recId;
                    this.getAllOrFilteredCEMRecords();
                    this.isShowTable = true;
                    this.isLoaded = true;
                }
            }
        })
        .catch(error => {
            this.error = error;
            console.log('Error ' , error );
        });
    }

    handleDialogClose(){
        this.showModal = false;
        this.showModal2 = false;
    }

    handleShowModal(){
        this.showModal = true;
    }

    handleShowModal2(){
        this.showModal2 = true;
    }	

    handleSendWelcomeEmail(){
        if(this.allSelectedRows.length > 0){
            let cemListTemp = [];
            for(var i=0;i<this.allSelectedRows.length;i++){
                let cem = {'sobjectType': 'Contact_Edition_Mapping__c', Id: this.allSelectedRows[i]};
                cemListTemp.push(cem);
            }
            this.rows = cemListTemp;
            this.sendEmail();
        }
        else{
            const evt = new ShowToastEvent({
                title :  'Select at least one record before sending welcome email.',
                variant : 'error'
            });
            this.dispatchEvent(evt);
        }
    }

    handleSendWelcomeEmailToAll(){
        this.rows = this.allRecords;
        this.sendEmail();
    }

    sendEmail(){
        this.cssClass = "progressContainer";
        let selectedrecords = this.rows;
        this.isShowTable = false;
        this.isShowProgress = true;
        this.isShowBatchProgress = false;
        this.isShowDetailedInfo = false;
        if(selectedrecords.length > this.batchSize){
            this.isShowBatchProgress = true;
        }
        else{
            this.progress = 0;
            this.processStatus = 'Processed ' + this.progress + '/' + selectedrecords.length + ' records.';
        }
        this.handleDialogClose();

        sendWelcomeEmail({cemList : selectedrecords})
        .then(result => { 
            if(selectedrecords.length <= this.batchSize){
                this.progress = 100;
                this.processStatus = 'Processed ' + selectedrecords.length + '/' + selectedrecords.length + ' records.';
                if(this.progress === 100) {
                    this.transDetail = {};
                    this.transDetail.Total = selectedrecords.length;
                    this.transDetail.Success = 0;
                    this.transDetail.Error = 0;
                    this.hasSyncErrors = false;
                    result.forEach((row) => {            
                        if(row.IsEmailSent__c){
                            this.transDetail.Success = this.transDetail.Success + 1;
                        }
                        else{
                            this.transDetail.Error = this.transDetail.Error + 1;
                            this.hasSyncErrors = true;
                        }
                    });
                    this.transDetail.Status = (this.transDetail.Error > 0?'Completed With Error':'Completed');
                    this.isShowDetailedInfo = true;
                }
                this.showSuccess('All Records Processed.');
            }
            else{
                //this.showSuccess('Welcome Email Send Request has been captured. It will be processed in background.');
                //Batch Method Will Go Here
                this.batch1Id = result[0].Edition__r.Welcome_Email_Job_Id__c;
                this.batchinProgress(this.batch1Id);
            }
            this.handleDialogClose();
        })
        .catch(error => {
            this.error = error;
            console.log('Error ' , error );
        });
    }

    batchinProgress(batchId){
        this._interval = setInterval(() => {
            getAsyncJob({ batchId : batchId})
            .then(result => {
                let data = result.apexJobs;
                let cems = result.listCEM;
                this.batch1Size = this.batchSize;
                this.totalJobItems = data['TotalJobItems'];
                this.totalRecords = cems.length;
                this.jobsProcessed = data['JobItemsProcessed'];
                let currentStatus = data.Status;
                this.progress = this.jobsProcessed*this.batch1Size;

                for(let i=0;i<this.batchStatus.length;i++){
                    if(this.batchStatus[i].label == currentStatus){
                        this.batch1Step = this.batchStatus[i].step;
                        this.batch1hasError = this.batchStatus[i].hasError;
                    }
                }
                if(this.progress > this.totalRecords){
                    this.progress = this.totalRecords;
                }
                if(currentStatus == 'Processing' || currentStatus == 'Completed')
                {
                    this.isShowItem1Progress = true;
                }
                this.batch1processStatusMain = currentStatus + '...';
                if(this.isShowItem1Progress){
                    this.batch1processStatus = 'Processed ' + this.progress +'/'+ this.totalRecords + ' records.' ;
                    if(this.total1Progress === 100) 
                    {
                        this.isLoaded = false;
                        if(currentStatus == 'Completed')
                        {
                            this.transDetail = {};
                            this.transDetail.Total = this.totalRecords;
                            this.transDetail.Success = 0;
                            this.transDetail.Error = 0;
                            this.hasSyncErrors = false;
                            cems.forEach((row) => {            
                                if(row.IsEmailSent__c){
                                    this.transDetail.Success = this.transDetail.Success + 1;
                                }
                                else{
                                    this.transDetail.Error = this.transDetail.Error + 1;
                                    this.hasSyncErrors = true;
                                }
                            });
                            this.transDetail.Status = (this.transDetail.Error > 0?'Completed With Error':'Completed');
                            this.isShowDetailedInfo = true;
                            this.isLoaded = true;
                            clearInterval(this._interval);
                        }
                    }
                    else if(this.total1Progress !== 100 && this.totalJobItems !== 0){
                        this.total1Progress = Math.round((this.progress/this.totalRecords)*100);
                    }
                }
            })
            .catch(error => {
                this.error = error;
            });
        }, 500);
    }

    closeAction(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    //clicking on previous button this method will be called
    previousHandler() {
        this.isPageChanged = true;
        if (this.page > 1) {
            this.page = this.page - 1; //decrease page by 1
            this.displayRecordPerPage(this.page);
        }
    }

    //clicking on next button this method will be called
    nextHandler() {
        this.isPageChanged = true;
        if((this.page<this.totalPage) && this.page !== this.totalPage){
            this.page = this.page + 1; //increase page by 1
            this.displayRecordPerPage(this.page);            
        }
    }

    //this method displays records page by page
    displayRecordPerPage(page){
        this.isNext = (this.page == this.totalPage || this.totalPage == 0);
        this.isPrev = (this.page == 1 || this.totalRecountCount < this.pageSize);          
        this.startingRecord = ((page -1) * this.pageSize) ;
        this.endingRecord = (this.pageSize * page);      
        this.endingRecord = (this.endingRecord > this.totalRecountCount)? this.totalRecountCount : this.endingRecord; 

        let data = this.items.slice(this.startingRecord, this.endingRecord);
        this.startingRecord = this.startingRecord + 1;
        this.selectedRows = [];

        data.forEach(cem =>{
            if(this.allSelectedRows.indexOf(cem.Id) != -1){
                this.selectedRows.push(cem.Id);
            }
        });

        this.tableData = data;
        let self = this;
        setTimeout(function(){
            self.isPageChanged = false;
        },500);
    } 

    sortColumns( event ) {
        this.sortedDirection = event.detail.sortDirection;
        this.sortedBy = event.detail.fieldName;
        this.getAllOrFilteredCEMRecords();
    }

    handleKeyChange( event ) {
        let searchValue = event.detail.value;
        window.clearTimeout(this.delayTimeout);
        this.delayTimeout = setTimeout(() => {
            this.searchKey = searchValue;
            console.log('Search Key ' + this.searchKey);
            this.getAllOrFilteredCEMRecords();
        }, 750);
    }

    onRowSelection(event){  
        if(!this.isPageChanged){
            this.processSelectedRows(event.detail.selectedRows);
        }
        this.isPageChanged = false;   
    }
    
    processSelectedRows(selectedCEM) {
        let selectedCEMIds = [];
        selectedCEM.forEach(cem =>{
            selectedCEMIds.push(cem.Id);
            if(this.allSelectedRows.indexOf(cem.Id) == -1){
                this.allSelectedRows.push(cem.Id);
            }
        });

        let visibleCEMIds = [];
        this.tableData.forEach(cem =>{
            visibleCEMIds.push(cem.Id);
        });

        let tempSelectedIds = JSON.parse(JSON.stringify(this.allSelectedRows))
        tempSelectedIds.forEach(cemId =>{
            if(visibleCEMIds.indexOf(cemId) != -1 && selectedCEMIds.indexOf(cemId) == -1){
                let index = this.allSelectedRows.indexOf(cemId);
                this.allSelectedRows.splice(index, 1);
            }
        });
        console.log("this.allSelectedRows",JSON.stringify(this.allSelectedRows));
    }

    showSuccess(msg){
        const evt = new ShowToastEvent({
            title : msg,
            variant : 'success'
        });
        this.dispatchEvent(evt);
        //this.closeAction();
    }
}