import { api, LightningElement, track, wire } from 'lwc';
import publishStandSettings from '@salesforce/apex/IMCC_StandDesignSubmissionCtrl.publishStandSettings';

import { showToast,handleErrors } from 'c/imcc_lwcUtility';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin,CurrentPageReference } from 'lightning/navigation';

export default class ImccPublishStandSettings extends NavigationMixin(LightningElement) {

    recordId;
    @track spinner;

    @api invoke() {
        console.log("Hi, I'm an action.");
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {        
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
        }                
    };

    publish(){
        this.spinner = true;
        let setting = {sobjectType:'Stand_Setting__c',Id:this.recordId,Status__c:'Published'};
        publishStandSettings({setting:setting})
        .then(res=>{
            this.spinner = false;
            showToast(this,'Stand Setting was published.','success','Success');
            window.location.reload();            
            this.dispatchEvent(new CloseActionScreenEvent());
        })
        .catch(error=>{
            this.spinner = false;
            handleErrors(this,error);
        })
    };

    hideModal(){    
        this.dispatchEvent(new CloseActionScreenEvent());
    };
}