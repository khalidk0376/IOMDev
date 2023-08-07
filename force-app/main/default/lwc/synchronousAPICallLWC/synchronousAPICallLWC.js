import { LightningElement, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LWCExternal from '@salesforce/resourceUrl/LWCExternal';
import { loadStyle } from 'lightning/platformResourceLoader';
import createOrderTaxAPITransaction from '@salesforce/apex/SynchronousAPICallController.createOrderTaxAPITransaction';
import createInvoiceTaxAPITransaction from '@salesforce/apex/SynchronousAPICallController.createInvoiceTaxAPITransaction';
import getAsyncJob from '@salesforce/apex/SynchronousAPICallController.getJobs';
import getTransactionDetail from '@salesforce/apex/SynchronousAPICallController.getTransactionDetail';

export default class SynchronousAPICallLWC extends NavigationMixin(LightningElement){
    @track progress = 0;
    @track processStatus = '';
    @track totalJobItems;
    @track allErrors;
    @track jobsProcessed;
    @api recordId;
    @api callType;
    @api batchId;
    @api tranId;
    @api logId;
    @track JobItemsProcessed;
    @track totalProgress;
    @track showLogButton = false;
    @track showTranButton = false;
    @track buttonIsVisible = false;
    @track isShowTransactionDetail = false;
    @track isShowStatusProgress = false;
    @track currentStep = 0;
    @track hasError = false;
    @track batchStatus = [];
    @track transDetail = {};
    @track headerText = '';
    @track buttonText = '';
    @track callCount = 0;
    @track isLoaded = false;

    userProfile()
    {
        this.buttonIsVisible = true;
        this.error = undefined;
    }

    connectedCallback() {
        console.log("connectedCallback====");
        loadStyle(this, LWCExternal);
        this.batchStatus.push({label:"Holding",step:1,hasError:false});
        this.batchStatus.push({label:"Queued",step:2,hasError:false});
        this.batchStatus.push({label:"Preparing",step:3,hasError:false});
        this.batchStatus.push({label:"Processing",step:4,hasError:false});
        this.batchStatus.push({label:"Completed",step:5,hasError:false});
        this.batchStatus.push({label:"Failed",step:6,hasError:true});
        this.batchStatus.push({label:"Aborted",step:7,hasError:true});
        this.userProfile();
        
        console.log("this.callType====",this.callType);
        if(this.recordId != undefined)
        {
            this.totalProgress = 0;
            this.buttonText = 'Close';
            this.headerText = 'Calculate Tax';
            if(this.callType == "Order Tax"){
                this.APITransactionForOrder();
            }
            if(this.callType == "Invoice Tax"){
                this.APITransactionForInvoice();
            }
        }
    }


    cancel()
    {
        this.dispatchEvent(new CustomEvent('close'));   
    }

    APITransactionForOrder(){
        createOrderTaxAPITransaction({ orderId : this.recordId,thirdParty:'Onesource'})
        .then(data => {
            if(data)
            {
                console.log("APITransactionForProductSync====",JSON.stringify(data));
                if(data.trasactionId.indexOf("error:") != -1){
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error!',
                            message: data.trasactionId.replace('error:',''),
                            variant: 'error'
                        })
                    );
                    this.isLoaded = true;
                    this.cancel();
                }
                else{
                    this.batchId = data.batchId;
                    this.tranId = data.trasactionId;
                    this.logId = data.interfaceLogId;
                    this.error = undefined;
                    this.currentStep = 1;
                    this.isShowStatusProgress = true;
                    this.isLoaded = true;
                    this.batchinProgress();
                }
            }
        })
        .catch(error => {
            this.error = error;
            this.isLoaded = true;
        });
    }

    APITransactionForInvoice(){
        createInvoiceTaxAPITransaction({ invoiceId : this.recordId,thirdParty:'Onesource'})
        .then(data => {
            if(data)
            {
                console.log("APITransactionForProductSync====",JSON.stringify(data));
                if(data.trasactionId.indexOf("error:") != -1){
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error!',
                            message: data.trasactionId.replace('error:',''),
                            variant: 'error'
                        })
                    );
                    this.isLoaded = true;
                    this.cancel();
                }
                else{
                    this.batchId = data.batchId;
                    this.tranId = data.trasactionId;
                    this.logId = data.interfaceLogId;
                    this.error = undefined;
                    this.currentStep = 1;
                    this.isShowStatusProgress = true;
                    this.isLoaded = true;
                    this.batchinProgress();
                }
            }
        })
        .catch(error => {
            this.error = error;
            this.isLoaded = true;
        });
    }

    batchinProgress(){
        this._interval = setInterval(() => {
            getAsyncJob({ batchId : this.batchId})
            .then(data => {
                console.log('wrapperData' +JSON.stringify(data));
                this.totalJobItems = data['TotalJobItems'];
                this.allErrors = data['NumberOfErrors'];
                this.jobsProcessed = data['JobItemsProcessed'];
                let currentStatus = data.Status;
                for(let i=0;i<this.batchStatus.length;i++){
                    if(this.batchStatus[i].label == currentStatus){
                        this.currentStep = this.batchStatus[i].step;
                        this.hasError = this.batchStatus[i].hasError;
                    }
                }
                this.progress = this.jobsProcessed;
                this.processStatus = currentStatus + '...';
                
                if(this.totalProgress === 100 && currentStatus === 'Completed') 
                {
                    if(this.buttonIsVisible)
                    {
                        this.showTranButton = true;
                    }
                    clearInterval(this._interval);
                    this.transactionDetail();
                }
                else if(this.totalProgress !== 100 && this.totalJobItems !== 0){
                    this.totalProgress = Math.round((this.jobsProcessed/this.totalJobItems)*100);
                }
            })
            .catch(error => {
                this.error = error;
            });
        }, 500);
    }

    transactionDetail(){
        this.isLoaded = false;
        this.processStatus = 'Completed' + '...';
        this._interval2 = setInterval(() => {
            getTransactionDetail({ txnId : this.tranId})
            .then(data => {
                if(data){
                    if(data.Status__c == 'Completed' || data.Status__c == 'Completed With Errors'){
                        this.isShowTransactionDetail = true;
                        this.transDetail.Status = data.Status__c;
                        this.transDetail.Total = data.API_Synchronization_Items__r.length;
                        this.transDetail.Processed = 0;
                        this.transDetail.Success = 0;
                        this.transDetail.Error = 0;
                        this.transDetail.InterfaceLog = data.Interface_Log__c;
                        if(data.Interface_Log__c != '' && data.Interface_Log__c != null)
                        {
                            this.showLogButton = true;
                            this.logId = data.Interface_Log__c;
                        }
                        for(let i=0;i<data.API_Synchronization_Items__r.length;i++){
                            let item = data.API_Synchronization_Items__r[i];
                            if(item.Status__c !== 'Paused'){
                                this.transDetail.Processed++;
                            }
                            if(item.Status__c === 'Completed'){
                                this.transDetail.Success++;
                            }
                            if(item.Status__c === 'Error'){
                                this.transDetail.Error++;
                            }
                        }
                        this.transDetail.hasError = (this.transDetail.Error>0);
                        this.isLoaded = true;
                        this.processStatus = 'Completed' + '...';
                        if(this._interval2){
                            clearInterval(this._interval2);
                        }
                    }
                }
            })
            .catch(error => {
                console.log("error" + JSON.stringify(error));
                this.error = error;
                if(this._interval2){
                    clearInterval(this._interval2);
                }
                this.isLoaded = true;
            });
        }, 1000);
    }

    disconnectedCallback() {
        if(this._interval){
            clearInterval(this._interval);
        }
        if(this._interval2){
            clearInterval(this._interval2);
        }
    }

    navigateToTransactionRecordPage() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                "recordId": this.tranId,
                "objectApiName": "API_Synchronization_Transaction__c",
                "actionName": "view"
            },
        });
    }

    navigateToInterfaceLogRecordPage() {
        if(this.logId != '' && this.logId != null){
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    "recordId": this.logId,
                    "objectApiName": "Interface_Log__c",
                    "actionName": "view"
                },
            });
        }
    }
}