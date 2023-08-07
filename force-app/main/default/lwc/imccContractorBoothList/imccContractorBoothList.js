import { api, LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getActivePHDatas from "@salesforce/apex/IMCC_ContractorNominationsCTRL.getActivePHDatas";
import getstandDetailDelete from "@salesforce/apex/IMCC_ContractorNominationsCTRL.getstandDetailDelete";
import { handleErrors,showToast } from 'c/imcc_lwcUtility';

export default class ImccContractorBoothList extends LightningElement {
    //dueDate;
    //showDueDate;
    @api editionId;
    @api eventCode;
    selectedOption;
    @api get currentOption(){return selectedOption;}
    set currentOption(data){this.selectedOption = data;
    this.showBoothData();}
    //@track tableData;
    //@track selectedRows;
    //@track purchaseDataList;
    @track data;
    @track data;
    //@track selectedBooth;
    //@track nominationationDueDate;
    @track buttonStatus = false;
    @track isContextVisible = false;
    @track isReasonModal = false;
    @track showRejectReasonHeader = false;
    @track contractorNominate = false;
    @track standSubmit = false;
    contactRejectionReason;
    selectedOwnBoothId;
    selectedBoothName;
    selectedBoothId;
    spinner ;
    accountId;
    contactormapId;
    showBooth = false;
    @track selectedBoothData = [];

    showBoothData() {
        this.spinner = true;  
        this.contractorNominate = false;
        this.standSubmit = false;  
        this.showBooth = false;  
        if(this.selectedOption == 'cn'){
           this.contractorNominate = true;
        }  
        else if(this.selectedOption == 'sd'){
            this.standSubmit = true;
        }
        
        getActivePHDatas({editionId:this.editionId})
        .then(res => {
            let tempData = [];
            let tempData2 = [];
            res.data.forEach(item => {
                if(item.contractorLength == 1) {
                    if(item.contractor.Contractor_Status__c == 'Contractor Declined Nomination' || item.contractor.Contractor_Status__c == 'New Contractor Nomination Rejected') {
                        item.rejectionReason = item.contractor.Contractor_Status__c == 'Contractor Declined Nomination'? item.contractor.Rejection_Reason__c: item.contractor.TempContact__r.Rejection_Reason__c ;
                        item.showRejectReason = true;
                        this.showRejectReasonHeader = true;
                        if(!item.toBeNominated) {
                            item.isButtonDisable = true;
                        }
                        tempData.push(item);
                    }
                    else {
                        if(item.contractor.Contractor_Status__c != 'New Contractor Nomination In Review') {
                            item.accountName = item.contractor.Account__c ? item.contractor.Account__r.Name : item.contractor.TempContact__r.TempAccount__r.Name;
                            item.contactName = item.contractor.Contact__c ? item.contractor.Contact__r.Name : item.contractor.TempContact__r.Name;
                            item.submissionStatus = item.standDetailLength == 1?item.standDetail.Stand_Detail_Status__c:'';
                            item.submissionDate = item.standDetailLength == 1?item.standDetail.Stand_Detail_Submitted_On__c:'';
                            item.manageBtn = item.contractor.Contractor_Status__c == 'Contractor Nominated' ?true:false;
                            item.isDelBtnDisable = (item.standDetailLength == 0 || item.contractor.Contractor_Status__c == 'Viewed')?true:false;
                            tempData2.push(item);
                       }
                    }
                }
                else {
                    if(!item.toBeNominated) {
                        item.isButtonDisable = true;
                    }
                    tempData.push(item);
                }


            });
            if(this.contractorNominate){
                this.data = tempData;
            }
            if(this.standSubmit){
                this.data = tempData2;
            }
            this.spinner = false;   
            console.log('data==',JSON.stringify(this.data));
        })
        .catch(error => {
            handleErrors(this, error);
            this.spinner = false;   
        })
        .finally(()=>{
            this.spinner = false;
        });
        
    }

    openSearchModal(event) {
        console.log('event.target.dataset.boothName==>'+event.target.dataset.boothName);
        console.log('event.target.dataset.boothId==>'+event.target.dataset.boothId);
        this.selectedBoothName = event.target.dataset.boothName;
        this.selectedBoothId = event.target.dataset.boothId;
        this.data.forEach(item => {
            if (item.boothId !== this.selectedBoothId){
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

    handleClose() {
        this.selectedBoothName = undefined;
        this.selectedBoothId = undefined;
        eval("$A.get('e.force:refreshView').fire();");
    }

    handleCloseStandPage(){
    this.showBoothData();
    }

    refreshboothtable(){
        this.selectedBoothName = undefined;
        this.selectedBoothId = undefined;
        this.selectedBoothData = [];
        this.showBoothData();
    }

    openReasonModal(event) {
        this.isReasonModal = true;
        this.contactRejectionReason = event.target.value;
        console.log('rejectionEntry', this.contactRejectionReason);
    }

    openStandSubmissionPage(event){        
        try{
            this.contactormapId = event.target.value;
            this.accountId = event.target.dataset.accountId;
            this.showBooth = true;
            setTimeout(()=>{
            this.template.querySelector('c-imcc-stand-design-steps').doInit(true);
            },500);
        }
        catch(e){
            console.log(e);
        }
    };

    standSubmissiondeletion(event){
        this.spinner = true;
        const standDetailId = event.target.value;
        const contactormapId = event.target.dataset.contactormapId;
        getstandDetailDelete({standDetailId : standDetailId,contactormapId : contactormapId})
        .then(res => {
            this.spinner = false;
            showToast(this,'Stand Detail is deleted','success','Success');
            this.showBoothData();
        })
        .catch(error => {
            handleErrors(this, error);
        })

    }

    closeModal() {
        this.isReasonModal = false;
    }
}