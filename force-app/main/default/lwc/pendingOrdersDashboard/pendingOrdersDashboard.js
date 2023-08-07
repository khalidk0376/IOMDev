import { LightningElement, track } from 'lwc';
import getdata from '@salesforce/apex/SSCDashboardLtngCtrl.getSSCTeamMember';
import getRecordDetail from '@salesforce/apex/CommonTableController.getRecordDetail';
import strUserId from '@salesforce/user/Id';
import {handleErrors} from 'c/lWCUtility';
const DELAY=300;

export default class PendingOrdersDashboard extends LightningElement {

    @track openActionModal=false;
    @track readonly = false;
    @track recordId='';
    @track error;
    @track pendingOrderCond;
    @track ordFields = '';
    @track ordFieldsLabels = '';

    /**
    * Description: This method will call at the time of load.
    */
    connectedCallback(){
        this.getUserDetail();
        this.getSSCTeamMember();
    }
    
    /**
    * Description: This method will fetch the list of event series from ssc team member.
    */
    getSSCTeamMember(){
        getdata()
        .then(data=>{
            let ids = [];
            let datas = JSON.parse(JSON.stringify(data));
            for(let i=0; i<datas.length; i++){
                if(datas[i].Action_Team__r.Series__c!==undefined){
                    ids.push(datas[i].Action_Team__r.Series__c);
                }                
            }           
            this.pendingOrderCond = "(Order_Translation_Status__c=\'Pending\' AND Edition__r.Part_of_Series__c IN ('"+ids.join("','")+"'))";
        })
        .catch(error=>{
           handleErrors(this,error);
        });
    }

    /**
    * Description: This method will fetch the list of userrole from user based on login user id.
    */
    getUserDetail(){
        getRecordDetail({objectName:'User',allFields:'UserRole.Name',recordId:strUserId})
        .then(res=>{
            if(res.length > 0){               
                    this.ordFields = 'OrderNumber,blng__BillingAccount__r.Name,Order_Translation_Status__c,Edition__r.Name';                
                    this.ordFieldsLabels = 'Order Number,Account, Order Translation Status, Edition';              
            } 
        })
        .catch(error=>{
            handleErrors(this,error);
        })
    }

    /**
    * Description: This method will call once user click on popup icon.
    */
    handleActionModal(event){
        this.recordId = event.detail;
        window.clearTimeout(this.delayTimeout);        
        this.openActionModal = false;
        this.delayTimeout = setTimeout(()=>{
            this.recordId = event.detail;
            this.openActionModal = true; 
            this.template.querySelector('c-pending-order-modal').getOrdDetail(this.recordId);           
        },DELAY);
    }

    /*
        * @description [This method is used to refresh this table while click on tab]
    */   
    handleRefreshPendingOrder(){
        this.template.querySelector('c-common-table').refreshTable();
   }
}