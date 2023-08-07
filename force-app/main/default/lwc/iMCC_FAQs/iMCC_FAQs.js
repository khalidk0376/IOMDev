import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import fetchQuesAnsLst from '@salesforce/apex/IMCC_FAQCtrl.fetchQuesAnsDetails';
import getTabContext from '@salesforce/apex/IMCC_HomeCtrl.getTabContext';
import { handleUIErrors } from 'c/imcc_lwcUtility';


export default class IMCC_FAQs extends LightningElement {

    @track eventcode;
    @track accountId;
    @track tabId;
    @track quesAnsLst;
    @track showExpanded = false;


    @track methodName;
    className ='iMCC_FAQs';
    comp_type ='LWC';

    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        if (currentPageReference) {
            this.eventcode = currentPageReference.state.edcode;
            this.accountId = currentPageReference.state.accId;
            this.tabId = currentPageReference.state.tabId;
            this.doInit();
        }
    }

    doInit() {
        this.methodName='doInit';
        fetchQuesAnsLst({ eventCode: this.eventcode, accountId: this.accountId, tabId: this.tabId })
            .then(result => {
              if(result){
                this.quesAnsLst = result;
                  console.log('Ques and Ans  ' + JSON.stringify(this.quesAnsLst));
              }

            })
            .catch(error => {
                window.console.log('error...12' + JSON.stringify(error));
                handleUIErrors(this,error);
            });
    }

    handleLike(event){
        event.preventDefault();
        let quesId = event.currentTarget.dataset.id;
        console.log('Question Id ' +quesId);
    }

    handleDislike(event){
        event.preventDefault();
        let quesId = event.target.dataset.Id;
        console.log('Question Id 1' +quesId);
    }

    handleButtonClick1(){
        this.showExpanded = true;
    }
    handleButtonClick2(){
        this.showExpanded = false;
    }
}