import { LightningElement, track, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import getPurchaseSummary from '@salesforce/apex/IMCC_HomeCtrl.getPurchaseSummary';
import updatePurchaseSummary from '@salesforce/apex/IMCC_HomeCtrl.updatePurchaseSummary';
import { handleUIErrors,showToast } from 'c/imcc_lwcUtility';

export default class ImccVirtualEvent extends LightningElement {

    @track editionCode;
    @track accountId;
    @track tabId;
    @track isVirtualEvent=false;
    @track ExternalLink;
    @track conEdMapId;
    @track contactId;
    @track showExternalLink = false;
    @track externalLinkLabel;
    @track completedStatus;
    @track isCompleted = false;
    @track isOpenConfirmation = false;
    @track markTaskHelpText;
    @track progressPercent = 0;
    @track virtualEventLst;

    @track methodName;
    className='imccVirtualEvent';
    comp_type='LWC';

    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        if (currentPageReference) {
            this.editionCode = currentPageReference.state.edcode;
            this.accountId = currentPageReference.state.accId;
            this.tabId = currentPageReference.state.tabId;
            console.log('this.editionCode ' +this.editionCode);
            console.log('this.accountId ' +this.accountId);
            console.log('this.tabId ' +this.tabId);
            this.fetchPurchaseSummary();            
        }
    }

    fetchPurchaseSummary(){ 
        this.methodName = 'fetchPurchaseSummary';       
        getPurchaseSummary({eventCode:this.editionCode,accountId:this.accountId})
        .then(res=>{
            const purchaseSummary = JSON.parse(JSON.stringify(res.ps));
            const conEdMap = JSON.parse(JSON.stringify(res.cem));
            const virtualEvent = JSON.parse(JSON.stringify(res.ve));
            console.log('res ' +JSON.stringify(res));
            if(conEdMap){
                this.conEdMapId = conEdMap.Id;
                this.contactId = conEdMap.Contact__c;
            }
            this.completedStatus = res.cem.Completed_Purchase_Summaries__c?res.cem.Completed_Purchase_Summaries__c:'';
            this.completedStatus = this.completedStatus + ";" + (res.pcem!=null?res.pcem.Completed_Purchase_Summaries__c:'');
            var purchaseSummaryType = [];
            if (this.completedStatus) {
                purchaseSummaryType = this.completedStatus.split(";");
                purchaseSummaryType.forEach(type => {
                    if (type.indexOf('Virtual Event')>=0) {
                        this.progressPercent = 100;
                        this.isCompleted = true;
                    }
                });
            }
            purchaseSummary.forEach((item,index)=>{                
                if(item.Purchase_Summary_Type__c==='Virtual Event' && virtualEvent.length>0){
                    this.isVirtualEvent = true;
                    this.virtualEventLst = virtualEvent;
                    this.markTaskHelpText = item.Mark_This_Task_Helptext__c?item.Mark_This_Task_Helptext__c:'';
                    this.ExternalLink = item.External_Link__c;
                    this.externalLinkLabel = item.External_Link_Label__c;
                    
                }
            });
            console.log(JSON.stringify(purchaseSummary));
            //this.purchaseSummaryList = purchaseSummary;
        })
        .catch(error=>{
            handleUIErrors(this,error);
        });
    };

    handleButtonClick(){
        window.open(this.makeSecureUrl(this.ExternalLink),'_blank');
    };

    makeTaskAsComplete(event){
        if(event.target.checked){
            this.isCompleted = true;
            this.isOpenConfirmation = true;
        }
    };

    yesComplete(){
        this.methodName = 'yesComplete';
        updatePurchaseSummary({type:'Virtual Event',cemId: this.conEdMapId})
        .then(res=>{
            this.completedStatus = res;
            this.isCompleted = true;
            this.progressPercent = 100;
            this.isOpenConfirmation = false;
            //this.dispatchEvent(new CustomEvent('reloadtask'));
            showToast(this,'Task has been completed.','success','Success');            
        })  
        .catch(error=>{
            handleUIErrors(this, error);
        });
    };

    noClose(){
        try{
            this.isCompleted = false;
            this.isOpenConfirmation = false;        
        }
        catch(e){
            console.error(e);
        }
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
}