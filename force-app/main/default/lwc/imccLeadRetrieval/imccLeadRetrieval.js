import { LightningElement, track, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import getPurchaseSummary from '@salesforce/apex/IMCC_HomeCtrl.getPurchaseSummary';
import {handleUIErrors} from 'c/imcc_lwcUtility';

export default class ImccLeadRetrieval extends LightningElement {

    @track editionCode;
    @track accountId;
    @track tabId;
    @track isLeadRetrieval=false;
    @track ExternalLink;
    @track conEdMapId;
    @track contactId;
    //@track showExternalLink = false;
    @track externalLinkLabel;
    @track methodName;
    className ='imccLeadRetrieval';
    comp_type ='LWC';

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
            console.log('purchaseSummary%%% ' +purchaseSummary);
            const conEdMap = JSON.parse(JSON.stringify(res.cem));
            const leadRetrieval = JSON.parse(JSON.stringify(res.lr));
            if(conEdMap){
                this.conEdMapId = conEdMap.Id;
                this.contactId = conEdMap.Contact__c;
            }
            //this.completedStatus = res.cem.Completed_Purchase_Summaries__c?res.cem.Completed_Purchase_Summaries__c:'';
            purchaseSummary.forEach((item,index)=>{                
                if(item.Purchase_Summary_Type__c==='Lead Retrieval' && leadRetrieval.length>0){
                    this.isLeadRetrieval = true;
                    this.ExternalLink = item.External_Link__c;
                    //this.showExternalLink = true;
                    this.externalLinkLabel = item.External_Link_Label__c;
                }
                //set internal link empty if tab not defind on purchase summary
                if(!item.Event_Tab__c){
                    this.internalLink='';
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