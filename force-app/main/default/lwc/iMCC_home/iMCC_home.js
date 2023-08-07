import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference,NavigationMixin } from 'lightning/navigation';
import fetchPopupDetails from "@salesforce/apex/IMCC_GreetingPopup.fetchPopupDetails";
import updateMarkAsReadCEM from "@salesforce/apex/IMCC_GreetingPopup.updateMarkAsRead";
import userId from '@salesforce/user/Id';
import PopupFooter from '@salesforce/label/c.Greeting_Popup_Footer'; 
import cancel from '@salesforce/label/c.Cancel'; 
import markAsRead from '@salesforce/label/c.Mark_as_read';
import purchaseSummary from '@salesforce/label/c.Purchase_Summary';
import eventSummary from '@salesforce/label/c.Event_Summary';
import standSummaryInfo from '@salesforce/label/c.Stand_Summary_Quick_Info';
import { handleUIErrors} from 'c/imcc_lwcUtility';

export default class IMCC_home extends NavigationMixin(LightningElement) {
    @track eventcode;
    @track accountId;
    @track eventDtls;
    @track userDtls;
    @track userType;
    @track edPopup;
    @track popupDtls;
    @track isGreetingPopUp =false; 
    @track isPopupText = true;
    @track isPopupMarkedasRead =false;
    @track eventeditionName;
    @track refreshEventSummary;

    @track methodName;
    className ='iMCC_home';
    comp_type ='LWC';

    @track logoURL;
    userId = userId;
    @track cemId;
    
    label = { PopupFooter,cancel,markAsRead,standSummaryInfo,purchaseSummary,eventSummary };
    
    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        if (currentPageReference) {
            this.refreshEventSummary = true;
            this.eventcode = currentPageReference.state.edcode;
            this.accountId = currentPageReference.state.accId;
            if(this.eventcode){
                this.fetchUserDtls(this.eventcode, this.accountId);                
            }
        }
    };

    fetchUserDtls(eventcode,accountId) {
    this.methodName='fetchUserDtls';    
    fetchPopupDetails({ eventCode: eventcode,accountId: accountId })
        .then(result => {
            //console.log(JSON.stringify(result));
            this.isPopupMarkedasRead =false;
            this.isGreetingPopUp = false;
            this.eventDtls = result;
            this.userDtls = result.CEM;
            this.popupDtls = result.popupText;
            this.edPopup = result.editionPopup;            
            if(this.edPopup){
                if(this.edPopup.Is_Visible__c){
                    this.isGreetingPopUp = true;
                }
            }
            if (this.userDtls){
                this.userType = this.userDtls.Access_Type__c;
                this.eventeditionName = this.userDtls.Edition__r.Name;
                this.logoURL = this.userDtls.Edition__r.SizedLogo__c?this.userDtls.Edition__r.SizedLogo__c:'';
                this.logoURL = this.logoURL.replace(' style=',' data-style=');
                if(this.logoURL){
                    let arr1 = this.logoURL.split('src="');  
                    let arr2 = arr1.length>1?arr1[1].split('/servlet/'):arr1[0];
                    this.logoURL = arr1[0] +'src="/servlet/'+ (arr2.length>1?arr2[1]:arr2[0]);                    
                }
                if(this.logoURL.indexOf('id=&')>0){
                    this.logoURL = '';
                }
                if(this.userDtls.Popup_Marked_as_Read__c == false){
                    this.isPopupMarkedasRead =true;
                }
            }
            if(this.popupDtls){
                this.popupText = result.popupText;                
            }
        })
        .catch(error => {
            handleUIErrors(this,error);
            window.console.log('error...' + JSON.stringify(error));
        });
    };    

    updateMarkAsRead(){
        this.methodName='updateMarkAsRead';
        updateMarkAsReadCEM({ cemId :this.userDtls.Id})
        .then(result =>{
            //console.log('Update done...');
            this.isGreetingPopUp =false;
        })
        .catch(error =>{
            handleUIErrors(this,error);
            window.console.log('error...' + JSON.stringify(error)); 
        })
    };
    
    //called this method when event fired from purchase summary component
    reloadAfterTaskComplete(){
        this.refreshEventSummary = false;
        setTimeout(()=>{
            this.refreshEventSummary = true;
        },300);
        //console.log('event fired');        
    };

    //called this method when event fired from event summary component
    @track task;
    @track allDueDates;
    haldleDataLoad(event){
        this.task = undefined;
        this.allDueDates = undefined;
        setTimeout(()=>{
            this.task = event.detail.task;
            this.allDueDates = event.detail.dueDate;
        },300);        
    };

    cancelModal(){        
        this.isGreetingPopUp =false;         
    };
    
    redirect(pageName,paramObj){
        redirect(this,NavigationMixin.Navigate,pageName,paramObj);        
    };
}