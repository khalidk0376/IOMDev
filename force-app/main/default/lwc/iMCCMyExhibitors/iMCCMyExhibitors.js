import { LightningElement, track, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'

import setUpdatedValue from "@salesforce/apex/IMCCStandContractorDataCTRL.setUpdatedValue";
import getActiveDatas from "@salesforce/apex/IMCCStandContractorDataCTRL.getActiveDatas";

import { handleErrors, redirect } from 'c/imcc_lwcUtility';
//This component for exhibitors
export default class IMCCMyExhibitors extends NavigationMixin(LightningElement) {

    @track editionCode;
    @track accountId;
    @track tabId;
    @track statusOptions;
    @track data;
    @track selectedBooth;
    @track buttonStatus;
    @track showRejectReason;
    @track isReasonModal = false;
    @track showRejectReasonHeader = false;
    @track totalProgressValue=0;
    contactRejectionReason;
    standSubmitDueDate;
    selectedBoothId;
    showConfirmationPopup = false;
    isAcceptSelected = false;
    isDeclineSelected = false;
    rejectBody;

    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        this.selectedBooth = '';
        if (currentPageReference) {
            this.editionCode = currentPageReference.state.edcode;
            this.accountId = currentPageReference.state.accId;
            this.tabId = currentPageReference.state.tabId;
            this.doInit();
        }
    }

    doInit() {
        if (this.accountId && this.editionCode) {
            this.getOptions();
            this.loadData();

        }
    }

    getOptions() {
        let options = [{ label: "--Select--", value: "" }];
        options.push({ label: "Accept", value: "Contractor Accepted Nomination" });
        options.push({ label: "Decline", value: "Contractor Declined Nomination" });
        this.statusOptions = options;
    }

    loadData() {
        
        getActiveDatas({ accountId: this.accountId, editionCode: this.editionCode })
            .then(res => {
                console.log('data', JSON.stringify(res));
                const tempData = JSON.parse(JSON.stringify(res.data));
                let today = res.dates.split('_')[0];
                let standSubmitDate = res.dates.split('_')[1];
                let standSubmitDueDate = new Date(standSubmitDate);
                this.standSubmitDueDate = standSubmitDueDate.setHours(0, 0, 0, 0);
                let todayDate = new Date(today);
                todayDate.setHours(0, 0, 0, 0);
                let totalBooth = tempData.length;
                let progressValue=0;
                tempData.forEach(item => {
                    let standSubmissionDate = new Date(item.contractor.Edition__r.Stand_Design_Completion_Due_Date__c);
                    standSubmissionDate.setHours(0, 0, 0, 0);
                    console.log('todayDate', todayDate);
                    console.log('standSubmissionDate', standSubmissionDate);
                    
                    if (!item.contractor.Edition__r.Stand_Setting__r.Allow_Stand_Design_Submission__c && standSubmissionDate < todayDate) {
                        console.log('Contractor_Status__c', item.contractor.Contractor_Status__c);
                        if ((item.contractor.Contractor_Status__c !== 'Contractor Nominated' && item.contractor.Contractor_Status__c !== 'New Contractor Nomination In Review')
                        && item.contractor.Contractor_Status__c !== 'New Contractor Nomination Rejected') {
                        item.contractor.Contractor_Status__c = 'Contractor Accepted Nomination';}
                        item.submissionStatus = item.standDetailLength == 1?item.standDetail.Stand_Detail_Status__c:'';
                        item.submissionDate = item.standDetailLength == 1?item.standDetail.Stand_Detail_Submitted_On__c:'';
                        item.currentStep = item.standDetailLength == 1?item.standDetail.Current_Step__c:'';
                        item.rejectionReason = (item.standDetailLength == 1 && item.standDetail.Stand_Detail_Status__c == 'Stand Design Rejected/Incomplete')?item.Rejection_Reason__c:'';
                        if(item.rejectionReason != ''){
                            item.showRejectReason = true;
                            this.showRejectReasonHeader = true;
                        }
                        item.isButtonDisable = true;
                        item.isComboBoxDisable = true;
                        console.log('rejectionReason1', item.rejectionReason);
                        console.log('showRejectReason', item.showRejectReason);
                    }
                    else {
                        if ((item.contractor.Contractor_Status__c !== 'Contractor Nominated' && item.contractor.Contractor_Status__c !== 'New Contractor Nomination In Review')
                            && item.contractor.Contractor_Status__c !== 'New Contractor Nomination Rejected') {
                            item.contractor.Contractor_Status__c = 'Contractor Accepted Nomination';
                            item.submissionStatus = item.standDetailLength == 1?item.standDetail.Stand_Detail_Status__c:'';
                            item.submissionDate = item.standDetailLength == 1?item.standDetail.Stand_Detail_Submitted_On__c:'';
                            item.currentStep = item.standDetailLength == 1?item.standDetail.Current_Step__c:'';
                            item.rejectionReason = (item.standDetailLength == 1 && item.standDetail.Stand_Detail_Status__c == 'Stand Design Rejected/Incomplete')?item.standDetail.Rejection_Reason__c:'';
                            if(item.rejectionReason != '' && item.rejectionReason != undefined){
                                item.showRejectReason = true;
                                this.showRejectReasonHeader = true;
                            }
                            item.isComboBoxDisable = true;
                            item.isButtonDisable = false;
                            console.log('rejectionReason2', item.rejectionReason);
                            console.log('showRejectReason', item.showRejectReason);
                        }
                        else {
                            item.isComboBoxDisable = false;
                            item.isButtonDisable = true;
                            item.contractor.Contractor_Status__c = '';
                        }
                    }

                    //calculate total value of progress bar                    
                    
                    /*if(!item.TempContact__c && item.standDetailLength === 0){
                        progressValue = progressValue + .2;
                    }
                    else if((item.submissionStatus==='Contractor Nominated' || item.Is_Self_Managed__c) && item.standDetailLength === 0){
                        progressValue = progressValue + .1;
                    }*/
                    if(item.contractor.Contractor_Status__c==='Contractor Accepted Nomination' && item.standDetailLength === 0){
                        progressValue = progressValue + .3;
                    }
                    else if(item.submissionStatus==='Viewed'){
                        progressValue = progressValue + .3;
                    }
                    else if(item.currentStep==='1' && 'Cancelled,Stand Design Rejected/Incomplete'.indexOf(item.submissionStatus)<0){
                        progressValue = progressValue + .4;
                    }
                    else if(item.currentStep==='2' && 'Cancelled,Stand Design Rejected/Incomplete'.indexOf(item.submissionStatus)<0){
                        progressValue = progressValue + .5;
                    }
                    else if(item.currentStep==='3' && 'Cancelled,Stand Design Rejected/Incomplete'.indexOf(item.submissionStatus)<0){
                        progressValue = progressValue + .6;
                    }
                    else if(item.currentStep==='4' && 'Cancelled,Stand Design Rejected/Incomplete'.indexOf(item.submissionStatus)<0){
                        progressValue = progressValue + .7;
                    }
                    else if(item.currentStep==='5' && 'Cancelled,Stand Design Rejected/Incomplete'.indexOf(item.submissionStatus)<0){
                        progressValue = progressValue + .8;
                    }
                    else if(item.currentStep==='6' && 'Cancelled,Stand Design Rejected/Incomplete'.indexOf(item.submissionStatus)<0){
                        progressValue = progressValue + .9;
                    }
                    else if(item.submissionStatus==='Permission to Build'){
                        progressValue = progressValue + 1;
                    }                    
                });
                this.data = tempData;                
                console.log('progressValue: '+progressValue);
                console.log('totalBooth: '+totalBooth);
                if(totalBooth>0){
                    this.totalProgressValue = Math.round((progressValue * 100)/totalBooth);
                }
            })
            .catch(error => {
                handleErrors(this, error);
            });
    }

    handleChange(event) {
        this.selectedBooth = event.target.value;
        this.selectedBoothId = event.target.name;
        console.log('selectedBoothId', this.selectedBoothId);
        if (this.selectedBooth == "Contractor Accepted Nomination") {
            this.showConfirmationPopup = true;
            this.isAcceptSelected = true;
            this.isDeclineSelected = false;
        }
        else if (this.selectedBooth == "Contractor Declined Nomination") {
            this.showConfirmationPopup = true;
            this.isAcceptSelected = false;
            this.isDeclineSelected = true;
        }

    }

    onYesClick() {
        console.log('this.rejectBody', this.rejectBody);
        console.log('this.isDeclineSelected', this.isDeclineSelected);
        let dateCmp = this.template.querySelector('lightning-textarea[data-id=rejectedReason]');
        if (this.isDeclineSelected && !this.rejectBody) {
            dateCmp.setCustomValidity("value is required");
            dateCmp.reportValidity();
        } else {
            this.showConfirmationPopup = false;
            this.data.forEach(item => {
                if (item.contractor.Id == this.selectedBoothId) {
                    if (this.selectedBooth == "Contractor Accepted Nomination") {
                        item.isComboBoxDisable = true;
                        item.isButtonDisable = false;
                    }
                    else if (this.selectedBooth == "Contractor Declined Nomination") {
                        item.isComboBoxDisable = true;
                    }
                }
            })
            setUpdatedValue({ statusValue: this.selectedBooth, rejectReason: this.rejectBody, cmId: this.selectedBoothId })
                .then(res => {
                    this.startToast('Success!', 'Status Updated');
                })
                .catch(error => {
                    handleErrors(this, error);
                });

        }
    }

    onNoClick(){
        this.showConfirmationPopup = false;
    }

    openReasonModal(event) {
        this.isReasonModal = true;
        this.contactRejectionReason = event.target.value;
        console.log('rejectionEntry', this.contactRejectionReason);
    }

    closeModal() {
        this.isReasonModal = false;
    }

    handleRejectReasonChange(event) {
        let dateCmp = this.template.querySelector('lightning-textarea[data-id=rejectedReason]');
        console.log('dateCmp', dateCmp);
        let dtValue = dateCmp.value;
        console.log('dtValue', dtValue);
        this.rejectBody = dtValue;
        if (!dtValue) {
            dateCmp.setCustomValidity("value is required");
            dateCmp.reportValidity();
            return false;
        } else {
            dateCmp.setCustomValidity("");
            dateCmp.reportValidity();
            return true;
        }
    };


    startToast(title, msg) {
        let event = new ShowToastEvent({
            title: title,
            message: msg,
            variant: 'success',
        });
        this.dispatchEvent(event);
    };

    openStandSubmissionPage(event){        
        try{
            let boothId = event.target.value;
            this.redirect('Stand_Design_Submission__c',{"accId":this.accountId,"edcode":this.editionCode,"tabId":this.tabId,"b":boothId});
        }
        catch(e){
            console.log(e);
        }
    };

    redirect(pageName, paramObj) {
        redirect(this, NavigationMixin.Navigate, pageName, paramObj);
    };
}