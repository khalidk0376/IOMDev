import { LightningElement, track, api} from 'lwc';
import getdata from '@salesforce/apex/SSCDashboardLtngCtrl.getSSCTeamMember';
import getRecordDetail from '@salesforce/apex/CommonTableController.getRecordDetail';
import strUserId from '@salesforce/user/Id';
import {handleErrors} from 'c/lWCUtility';
const DELAY=300;

export default class NoOrderFlaggedDashboard extends LightningElement {
    @track noorderflagged;
    @track openActionModal;
    @track oppFields = '';
    @track oppFieldsLabels = '';

    connectedCallback(){
        this.getUserDetail();
        this.getOppData();
    }

    /**
     * description: This method will fetch the data from ssc team also it contains different conditions.
     */
    getOppData(){
        getdata()
        .then(data=>{
            let ids = [];
            let datas = JSON.parse(JSON.stringify(data));
            for(let i=0; i<datas.length; i++){
                if(datas[i].Action_Team__r.Series__c!==undefined){
                    ids.push(datas[i].Action_Team__r.Series__c);
                }                 
            }
            this.noorderflagged = '(No_Order__c = true AND Default_Edition__r.Part_of_Series__c IN (\''+ids.join('\',\'')+'\'))';
            
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
                    this.oppFields = 'Name,Account.Name,Default_Edition__r.Name,CloseDate,StageName';
                    this.oppFieldsLabels = 'Opportunity Name,Account Name,Edition,Close Date,Stage';
            }
        })
        .catch(error=>{
            handleErrors(this,error);
        })
    }

    /**
     * description: This method will the reject contract model.
     */
    handleActionModal(event){
        this.recordId = event.detail;
        window.clearTimeout(this.delayTimeout);
        this.openActionModal = false;
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.delayTimeout = setTimeout(()=>{
            this.openActionModal = true;
            this.template.querySelector('c-no-Order-Flagged-Model').getOppDetail(this.recordId);
        },DELAY);
    }


    //handle to refresh table(Mukesh)
    @api 
    refreshTableOnTabChange(){
        if(this.template.querySelector('c-common-table')){
            this.template.querySelector('c-common-table').refreshTable();
        }
    }
}