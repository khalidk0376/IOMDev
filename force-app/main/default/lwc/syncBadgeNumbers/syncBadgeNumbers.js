import { LightningElement,api,wire,track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'

//Start - Importing of Apex classes required in this component
import getData from '@salesforce/apex/IMCC_SyncBadgeNumbersBulkCtrl.getData';
//End - Importing of Apex Class

export default class SyncBoothNumbers extends LightningElement {
    @api recordId;
    showNotification = true;
    
    @api invoke() {
        this.startToast('Sync Badge Numbers!','Starting syncing process...');
        //Call the cloning imperative apex js method
        this.syncNow();
    }

    syncNow(){
        getData({badgeSettingId: this.recordId})
        .then(result => {
            this.startToast('Sync Badge Numbers!','Syncing Process Completed');
         })
         .catch(error => {
            this.startToast('Sync Badge Numbers!','An Error occured during syncing'+error.body.message);
         });
    }
    
    startToast(title,msg){
        let event = new ShowToastEvent({
            title: title,
            message: msg,
        });
        this.dispatchEvent(event);
    }

    cancel(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}