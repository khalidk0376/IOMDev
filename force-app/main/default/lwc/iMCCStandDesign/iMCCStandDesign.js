import { LightningElement, track, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import getActivePHDatas from "@salesforce/apex/IMCCStandDesignCTRL.getActivePHDatas";
import buildOwnStandContactorMap from "@salesforce/apex/IMCCStandDesignCTRL.buildOwnStandContactorMap";

import { handleErrors, redirect } from 'c/imcc_lwcUtility';
//This component for stand contractor
export default class ImccStandDesign extends NavigationMixin(LightningElement) {

    dueDate;
    showDueDate;
    @track editionCode;
    @track accountId;
    @track tabId;
    @track purchaseDataList;
    @track data;
    @track selectedBooth;
    @track nominationationDueDate;
    @track buttonStatus = false;
    @track isContextVisible = false;
    @track isReasonModal = false;
    @track showRejectReasonHeader = false;
    @track totalProgressValue=0;
    contactRejectionReason;
    

    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        if (currentPageReference) {
            this.editionCode = currentPageReference.state.edcode;
            this.accountId = currentPageReference.state.accId;
            this.tabId = currentPageReference.state.tabId;
            this.doInit();
        }
    };

    doInit() {
        if (this.accountId && this.editionCode) {
            this.loadData();
        }
    };

    viewStandDesign(event){
        let boothId = event.target.value;
        //accId=00119000014LxcqAAC&edcode=SBARHE1&tabId=T-0047&b=a6B19000000IUbzEAG
        this.redirect('Stand_Design_Submission__c',{"accId":this.accountId,"edcode":this.editionCode,"tabId":this.tabId,"b":boothId,"type":"c"});
    };

    loadData() {
        getActivePHDatas({ accountId: this.accountId, editionCode: this.editionCode })
            .then(res => {
                let progressValue=0;
                this.DueDate = (res.DueDate.length>0?res.DueDate[0]:this.DueDate);
                let tempData = res.data;
                console.log('data111', JSON.stringify(tempData));
                let totalBooth = tempData.length;
                tempData.forEach(item => {
                    if (item.contractorLength == 1) {
                        if (item.contractor.Contractor_Status__c == 'Contractor Declined Nomination' || item.contractor.Contractor_Status__c == 'New Contractor Nomination Rejected') {
                            item.rejectionReason = item.contractor.Contractor_Status__c == 'Contractor Declined Nomination'? item.contractor.Rejection_Reason__c: item.contractor.TempContact__r.Rejection_Reason__c ;
                            item.showRejectReason = true;
                            this.showRejectReasonHeader = true;
                            item.isContextVisible = false;
                            if (!item.toBeNominated) {
                                item.isButtonDisable = true;
                            }
                            console.log('showRejectReason', item.showRejectReason);
                        }
                        else {
                            item.accountName = item.contractor.Account__c ? item.contractor.Account__r.Name : item.contractor.TempContact__r.TempAccount__r.Name;
                            item.contactName = item.contractor.Contact__c ? item.contractor.Contact__r.Name : item.contractor.TempContact__r.Name;
                            item.submissionStatus = item.standDetailLength == 1?item.standDetail.Stand_Detail_Status__c:'';
                            item.submissionDate = item.standDetailLength == 1?item.standDetail.Stand_Detail_Submitted_On__c:'';
                            item.isContextVisible = true;
                            item.isButtonDisable = false;
                            item.currentStep = item.standDetailLength == 1?item.standDetail.Current_Step__c:'';
                        }

                        //calculate total value of progress bar                    
                        if(item.contractor.Contractor_Status__c==='New Contractor Nomination In Review' && item.standDetailLength === 0){
                            progressValue = progressValue + .1;
                        }
                        else if(item.contractor.Contractor_Status__c==='Contractor Nominated' && item.standDetailLength === 0){
                            progressValue = progressValue + .2;
                        }
                        else if(item.contractor.Contractor_Status__c==='Contractor Accepted Nomination' && item.standDetailLength === 0){
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
                    }
                    else {
                        item.isContextVisible = false;
                        if (!item.toBeNominated) {
                            item.isButtonDisable = true;
                        }
                    }
                });
                this.data = tempData;
                console.log('data==',JSON.stringify(this.tempData));
                if(totalBooth>0){
                    this.totalProgressValue = Math.round((progressValue * 100)/totalBooth);
                }
                console.log('progressValue: '+progressValue);                                
            })
            .catch(error => {
                handleErrors(this, error);
            });
    };

    disabledBtn() {
        let disable = false;
        this.buttonStatus = disable;
    };    

    redirect(pageName, paramObj) {
        redirect(this, NavigationMixin.Navigate, pageName, paramObj);
    };

    selectedBoothName;
    selectedBoothId;
    selectedOwnBoothName;
    selectedOwnBoothId;
    @track selectedBoothData = [];
    openSearchModal(event) {
        this.selectedBoothName = event.target.dataset.boothName;
        this.selectedBoothId = event.target.dataset.boothId;
        this.data.forEach(item => {
            if (item.boothId !== this.selectedBoothId) {
                if (item.contractorLength == 1) {
                    if (item.contractor.Contractor_Status__c == 'Contractor Declined Nomination' || item.contractor.Contractor_Status__c == 'New Contractor Nomination Rejected') {
                        item.boothId = item.boothId;
                        item.boothNumber = item.boothNumber;
                        this.selectedBoothData.push(item);
                    }
                }
                else {
                    item.boothId = item.boothId;
                    item.boothNumber = item.boothNumber;
                    this.selectedBoothData.push(item);
                }
            }
        })
        this.template.querySelector('c-imcc-stand-contractors').openAccountModal();
    }

    handleClick(event){
        this.selectedOwnBoothName = event.target.dataset.boothName;
        this.selectedOwnBoothId = event.target.dataset.boothId;
        buildOwnStandContactorMap({boothId: this.selectedOwnBoothId,editionCode: this.editionCode,accountId: this.accountId})
            .then(res => {

            })
            eval("$A.get('e.force:refreshView').fire();");
    }

    handleClose() {
        this.selectedBoothName = undefined;
        this.selectedBoothId = undefined;
        eval("$A.get('e.force:refreshView').fire();");
    }
    
    openReasonModal(event) {
        this.isReasonModal = true;
        this.contactRejectionReason = event.target.value;
        console.log('rejectionEntry', this.contactRejectionReason);
    }

    closeModal() {
        this.isReasonModal = false;
    }
    
}