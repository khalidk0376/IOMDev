import { LightningElement, track, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import getProgressPercent from "@salesforce/apex/IMCC_BadgeRegistrationCTRL.getProgressPercent";
import getPurchaseData from "@salesforce/apex/IMCC_BadgeRegistrationCTRL.getPurchaseData";
import setUpdatedValue from "@salesforce/apex/IMCC_BadgeRegistrationCTRL.setUpdatedValue";
import getPurchaseSummary from "@salesforce/apex/IMCC_BadgeRegistrationCTRL.getPurchaseSummary";
import { handleUIErrors} from 'c/imcc_lwcUtility';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'

export default class ImccBadgeRegistraction extends LightningElement {

    @track editionCode;
    @track accountId;
    @track tabId;
    @track badges = [];
    @track selectedPurchaseSummary = [];
    @track progressPercent = 0;
    @track onlineTotalBadges = 0;
    @track onlineBadgeAllocated = 0;
    @track taskIsCompleted = false;
    @track confirmationPopup = false;
    showOnlineCard = false;
    showPortalButton = false;
    selectedPurchaseSummarylength = false;
    onlineBooth;
    contactId;
    conEdMapId;
    badgeDueDate;
    statusClass;
    eventProgressCountStatus;
    progressBarStatus;

    @track methodName;
    className='imccBadgeRegistraction';
    comp_type='LWC';

    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        if (currentPageReference) {
            this.editionCode = currentPageReference.state.edcode;
            this.accountId = currentPageReference.state.accId;
            this.tabId = currentPageReference.state.tabId;
            this.doInit();
        }
    }

    doInit() {
        if(this.accountId && this.editionCode != null && this.editionCode != '') {
            this.loadProgressPercent();
            this.loadData();
            this.loadPurchaseSummaryData();
        }
    }

    loadProgressPercent() {
        this.methodName = 'loadProgressPercent';
        getProgressPercent({ accountId: this.accountId, editionCode: this.editionCode })
            .then(res => {
                if (res) {
                    let tempdata = res;
                    console.log('res==>>', JSON.stringify(tempdata));
                    var purchaseSummaryType = [];
                    if (tempdata.Completed_Purchase_Summaries__c !== undefined) {
                        purchaseSummaryType = tempdata.Completed_Purchase_Summaries__c.split(";");
                        purchaseSummaryType.forEach(type => {
                            if (type == 'Badge') {
                                this.progressPercent = 100;
                                this.taskIsCompleted = true;
                            }
                        });

                    }
                    this.contactId = tempdata.Contact__c;
                    this.conEdMapId = tempdata.Id;
                }
            })
            .catch(error => {
                handleUIErrors(this, error);
            });
    }

    loadData() {
        this.methodName = 'loadData';
        getPurchaseData({ accountId: this.accountId, editionCode: this.editionCode })
            .then(res => {
                let tempDataOnline = {};
                let tempdata = JSON.parse(JSON.stringify(res));
                console.log('tempdata2==>>', JSON.stringify(tempdata));
                let isAllOnlineUnlimited = true;
                tempdata.forEach(item => {
                    if (item.Booth_Number__c !== undefined) {
                        console.log('booth==>>', item.Booth_Number__c);
                        item.Total_Badges__c = item.Total_Badges__c ? item.Total_Badges__c : 0;
                        item.Addition_Badge_Count__c = item.Addition_Badge_Count__c ? item.Addition_Badge_Count__c : 0;
                        item.Badge_Allocated__c = item.Badge_Allocated__c ? item.Badge_Allocated__c : 0;
                        this.badges.push(item);
                    }
                    else {

                        tempDataOnline.Booth_Number__c = 'Online';
                        this.onlineTotalBadges = item.Total_Badges__c ? this.onlineTotalBadges + item.Total_Badges__c : 0;
                        this.onlineBadgeAllocated = item.Badge_Allocated__c ? this.onlineBadgeAllocated + item.Badge_Allocated__c : 0;
                        if(!item.Unlimited_Badges__c){
                            isAllOnlineUnlimited = false;
                        }
                    }

                });
                if (this.onlineTotalBadges) {
                    tempDataOnline.Total_Badges__c = this.onlineTotalBadges;
                    tempDataOnline.Badge_Allocated__c = this.onlineBadgeAllocated;
                    tempDataOnline.Unlimited_Badges__c = isAllOnlineUnlimited;
                    this.badges.push(tempDataOnline);
                }
                console.log('badges==>>', JSON.stringify(this.badges));
            })
            .catch(error => {
                handleUIErrors(this, error);
            });
    }

    loadPurchaseSummaryData() {
        this.methodName = 'loadPurchaseSummaryData';
        getPurchaseSummary({ editionCode: this.editionCode, accountId: this.accountId })
            .then(res => {
                if (res != null && res.length > 0) {
                    let tempdata = JSON.parse(JSON.stringify(res));
                    console.log('purchaseData==>>', JSON.stringify(tempdata));
                    tempdata.forEach(item => {
                        if (item.External_Link__c) {
                            this.showPortalButton = item.External_Link_Label__c ? true : false;
                            console.log('tempdata.External_Link__c==>>', item.External_Link__c);
                        }
                    });
                    this.selectedPurchaseSummary = tempdata[0];
                    // this.selectedPurchaseSummarylength = this.selectedPurchaseSummary.length > 0 ? true : false;
                }
                else{
                    this.errorToast('Error!', 'No active Purchase summary data is found.');
                }
            })
            .catch(error => {
                handleUIErrors(this, error);
            });

    }

    makeTaskAsComplete(event) {
        if (event.target.checked) {
            this.taskIsCompleted = true;
            this.confirmationPopup = true;
        }
    }

    onNoClick() {
        this.confirmationPopup = false;
        this.taskIsCompleted = false;
    }

    closeModal() {
        this.confirmationPopup = false;
        this.taskIsCompleted = false;
    }

    onYesClick() {
        this.confirmationPopup = false;
        this.methodName = 'onYesClick';
        setUpdatedValue({ type: this.selectedPurchaseSummary.Purchase_Summary_Type__c, cemId: this.conEdMapId })
            .then(res => {
                this.progressPercent = 100;
                this.taskIsCompleted = true;
                this.successToast('Success!', 'Task is Completed');
            })
            .catch(error => {
                handleUIErrors(this, error);
            });
    }

    handleButtonClick() {
        window.open(this.makeSecureUrl(this.selectedPurchaseSummary.External_Link__c), '_blank');
    };

    makeSecureUrl(url) {
        let finalUrl;
        if (!url.includes("http:") && !url.includes("https:")) {
            finalUrl = "https://" + url + '?accId=' + this.accountId + '&edcode=' + this.editionCode + '&conId=' + this.contactId + '&ceid=' + this.conEdMapId;
        } else {
            finalUrl = url + '?accId=' + this.accountId + '&edcode=' + this.editionCode + '&conId=' + this.contactId + '&ceid=' + this.conEdMapId;
        }
        return finalUrl;
    }

    successToast(title, msg) {
        let event = new ShowToastEvent({
            title: title,
            message: msg,
            variant: 'success',
        });
        this.dispatchEvent(event);
    };
    errorToast(title, msg) {
        let event = new ShowToastEvent({
            title: title,
            message: msg,
            variant: 'error',
        });
        this.dispatchEvent(event);
    };


}