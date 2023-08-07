import { LightningElement, api } from "lwc";
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import getUserLoginData from '@salesforce/apex/IMCC_LoginAsUser.getUserLoginData';
import { handleUIErrors } from 'c/imcc_lwcUtility';

export default class IMCC_LoginAsUser extends LightningElement {
    @api recordId;
    isExecuting = false;
    className ='iMCC_LoginAsUser';
    comp_type ='LWC';

    @api async invoke() {
        this.isExecuting = true;
        this.methodName='getUserLoginData';
        getUserLoginData({contactId:this.recordId})
        .then(data => {
            if(data.UserId == ""){
                let event = new ShowToastEvent({
                    title: 'Error!',
                    message: 'Community User Not Found.',
                    variant: 'error'
                });
                this.dispatchEvent(event);
            }
            else{
                let url = data.BaseURL + '/servlet/servlet.su?oid=' + data.OrgId + '&retURL= ' + '&sunetworkid=' + data.NetworkId + '&sunetworkuserid=' + data.UserId; 
                window.open(url, "_blank");
            }
            this.isExecuting = false;
        })
        .catch(error => {
          
            this.isExecuting = false;
            handleUIErrors(this,error);
        });
        await this.sleep(2000);
    }

    sleep(ms) {
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        return new Promise(resolve => setTimeout(resolve, ms));
    }
}