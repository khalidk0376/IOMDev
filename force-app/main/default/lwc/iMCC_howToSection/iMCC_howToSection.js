import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import fetchHowToDetails from '@salesforce/apex/IMCC_FAQCtrl.fetchHowToDetails';
import fetchContVerId from '@salesforce/apex/IMCC_FAQCtrl.fetchContentVerId';
import fileDownloadUrl from '@salesforce/label/c.File_Download_URL';

import { handleUIErrors} from 'c/imcc_lwcUtility';

export default class IMCC_howToSection extends LightningElement {

    label = {
        fileDownloadUrl
    };

    @track eventcode;
    @track accountId;
    @track tabId;
    @track howToLst;

    @track methodName;
    className ='iMCC_howToSection';
    comp_type ='LWC';


    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        if (currentPageReference) {
            this.eventcode = currentPageReference.state.edcode;
            this.accountId = currentPageReference.state.accId;
            this.tabId = currentPageReference.state.tabId;
            console.log('Tab Code How To Guide====',this.tabId);
            console.log('Tab Code How To Guide^^^^',this.eventcode);
            console.log('Tab Code How To Guide*****',this.accountId);
            this.getHowToDetails();
        }
    }

    connectedCallback(){
    }

    getHowToDetails(){
        this.methodName='getHowToDetails';
        this.howToLst = null;
        if(this.tabId!=undefined){
        fetchHowToDetails({ eventCode: this.eventcode, accountId: this.accountId, tabId: this.tabId })
            .then(result => {
                if(result != null){
                   if(result.length>0){
                    this.howToLst = result;
                    console.log('howToLst  ' + JSON.stringify(this.howToLst));
                   }
                }
            })
            .catch(error => {
                window.console.log('error...12' + JSON.stringify(error));
                handleUIErrors(this,error);
            });
    }

     }

    openHowToSection(event){
        this.methodName='openHowToSection';
        let howToId = event.currentTarget.dataset.id;
        let tempArr = this.howToLst;
        let hyperlink;
        tempArr.forEach((row) => {
            if (row.Id == howToId) {
                hyperlink = row.HyperLink__c;
            }

        });
        if(hyperlink != '' && hyperlink != undefined){
            console.log('hyperlink ' + hyperlink);
            window.open(this.makeSecureUrl(hyperlink),'_blank');
        }
        else{
            fetchContVerId({ howToId : howToId })
            .then(result => {
                
                    let pdfId = result;
                    if(pdfId){
                        console.log('Pdf Id ' + pdfId);
                        window.open(fileDownloadUrl+pdfId);
                    }
            })
            .catch(error => {
                window.console.log('error...12' + JSON.stringify(error));
                handleUIErrors(this,error);
            });  
        }
    }
    makeSecureUrl(url) {
        let finalUrl;
        if (!url.includes("http:") && !url.includes("https:")) {
            finalUrl = "https://" + url;
        } else {
            finalUrl = url;
        }
        return finalUrl;
    }
}