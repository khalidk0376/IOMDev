import { LightningElement, track, wire } from 'lwc';
import { CurrentPageReference,NavigationMixin } from 'lightning/navigation';
import getTabContext from '@salesforce/apex/IMCC_HomeCtrl.getTabContext';
import { handleErrors,handleUIErrors,redirect } from 'c/imcc_lwcUtility';

export default class ImccPageHeader extends NavigationMixin(LightningElement) {
    tabId;
    eventCode;
    accountId;
    className='imccPageHeader';
    comp_type='LWC';
    @track dynamicContent =[];
    @track methodName;
    
    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {         
        if (currentPageReference) {
            this.tabId = currentPageReference.state.tabId;
            this.accountId = currentPageReference.state.accId;
            this.eventCode = currentPageReference.state.edcode;
            if(this.tabId){
                this.getTabData();
            }            
        }
    };

    getTabData(){
        this.methodName='getTabData';
        getTabContext({eventCode:this.eventCode,accountId:this.accountId,tabId:this.tabId})
        .then(res=>{
            console.log('res==>>',JSON.stringify(res));
            let tempdata = JSON.parse(JSON.stringify(res));
            this.dynamicContent = tempdata;
            console.log('dynamicContent==>>',JSON.stringify(this.dynamicContent));
        })
        .catch(error=>{
            //handleErrors(this,error);
            handleUIErrors(this,error);
        })
    };
}