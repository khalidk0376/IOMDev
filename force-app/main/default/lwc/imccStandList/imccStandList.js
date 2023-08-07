import { api, LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
import standDetailObj from '@salesforce/schema/Stand_Detail__c';
import RejectedSteps from "@salesforce/schema/Stand_Detail__c.Rejected_Steps__c";
import getStandList from '@salesforce/apex/Imcc_ContractorSubmissions.getStandList';
import approvalStandDesign from '@salesforce/apex/Imcc_ContractorSubmissions.approvalStandDesign';
import rejectStandDesign from '@salesforce/apex/Imcc_ContractorSubmissions.rejectStandDesign';
import { handleErrors } from 'c/imcc_lwcUtility';
import { showToast } from 'c/imcc_lwcUtility';

export default class ImccStandList extends NavigationMixin(LightningElement) {
    @api editionId;
    @track tableData;
    @track selectedStandIds;
    @track selectedRows;
    @track approveConfirmation;
    @track status;
    @track approvalDate;
    @track spinner;
    @track step;
    @track rejectionReason;
    @track statusOptions;
    @track rejectConfirmation;
    @track lstrejectedStepsOptions = [];
    @track yesBtnDisabled = true;
    @track columns = [{label: 'View Stand Submission', type: 'button-icon', initialWidth: 60, 
            typeAttributes:{
                label:{
                    fieldName: 'actionLabel'
                },
                title: 'View Stand Submission', 
                name: 'view',
                iconName: 'utility:preview',
                variant:'bare'
            }
        },
        { label: 'Exhibitor/Reseller Name', fieldName: 'ExContactName',type:'url',wrapText: true,typeAttributes:{label: { fieldName: 'Exhibitor_Contact_Name' }} },
        { label: 'User Type', fieldName: 'User_Type', type: 'text',wrapText: true },
        { label: 'Booth No.', fieldName: 'Booth_No', type: 'text' },
        { label: 'Booth Product Type', fieldName: 'Booth_Type', type: 'text',wrapText: true },
        { label: 'Contractor Company', fieldName: 'AccountName', type: 'url',wrapText: true,typeAttributes:{label: { fieldName: 'Contractor_Account_Name' }} },
        { label: 'Status', fieldName: 'Status', type: 'text' }
    ];
    @track spinner;

    @wire(getObjectInfo, { objectApiName: standDetailObj }) standDetailObjInfo;

    @wire(getPicklistValues, { recordTypeId: '$standDetailObjInfo.data.defaultRecordTypeId', fieldApiName: RejectedSteps })
    RejectedSteps(data, error) {
        if (data && data.data && data.data.values) {
            data.data.values.forEach(objPicklist => {
                this.lstrejectedStepsOptions.push({
                    label: objPicklist.label,
                    value: objPicklist.value
                });
            });
        } else if (error) {
            console.log(error);
        }
    };

    connectedCallback() {
        this.spinner = true; 
        this.approveConfirmation = false;       
        this.rejectConfirmation = false;
        this.getStandList();
        
    };

    getStandList(){
        getStandList({editionId:this.editionId})
        .then(res=>{
            let data = [];
            const allData = JSON.parse(JSON.stringify(res));
            const d = allData.listStandDetail;
            const listPD = allData.listPD;
            let mapPD = {};
            listPD.forEach(pd=>{
                mapPD[pd.Contractor_Mapping__c] = pd;
            });
            try{
                d.forEach(i=>{
                    data.push({
                        Id:i.Id,
                        Exhibitor_Contact_Name: mapPD[i.Contractor_Mapping__c].Contact_Edition_Mapping__r.Contact__c?mapPD[i.Contractor_Mapping__c].Contact_Edition_Mapping__r.Contact__r.Name:'',
                        ExContactName:'/'+mapPD[i.Contractor_Mapping__c].Contact_Edition_Mapping__r.Contact__c,
                        User_Type:mapPD[i.Contractor_Mapping__c].Contact_Edition_Mapping__r.Access_Type__c,
                        Booth_No:mapPD[i.Contractor_Mapping__c]?mapPD[i.Contractor_Mapping__c].Booth_Number__c:'',
                        Booth_Type:mapPD[i.Contractor_Mapping__c]?mapPD[i.Contractor_Mapping__c].Booth_Product_Type__c:'',
                        Contractor_Account_Name:i.Contractor_Mapping__r.Account__c ?i.Contractor_Mapping__r.Account__r.Name:'',
                        AccountName:'/'+(i.Contractor_Mapping__r.Account__c?i.Contractor_Mapping__r.Account__c:''),
                        Status:i.Stand_Detail_Status__c
                    })
                });
            }
            catch(e){
                console.error(e);
            }
            console.log(data);
            this.tableData = data;
        })
        .catch(error=>{
            handleErrors(this,error);
        })
        .finally(()=>{
            this.spinner = false;
        })
    }

    getStatusOptions() {
        let options = [];
        options.push({ label: "Pending Sales Approval", value: "Pending Sales Approval" });
        if(this.rejectConfirmation){
        options.push({ label: "Stand Design Rejected/Incomplete", value: "Stand Design Rejected/Incomplete" });
        }
        options.push({ label: "Pending Venue Approval", value: "Pending Venue Approval" });
        options.push({ label: "Tentative Approval", value: "Tentative Approval" });
        this.statusOptions = options;
    }

    //contractor company and submission status
    handleRowAction(event){
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        let standId = row.Id;
        switch (actionName) {
            case 'view':
                //navigate to temp contact record
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: standId,
                        objectApiName: 'Stand_Detail__c',
                        actionName: 'view'
                    }
                });
                break;
            default:
                console.log('row action not found');
        }
    };

    handleRowSelect(event){
        let data = [];
        this.selectedRows = event.detail.selectedRows;       
        this.selectedRows.forEach(i=>{
            data.push(i.Id);
        });
        this.selectedStandIds = data;
        console.log('this.selectedStandIds ::'+JSON.stringify(this.selectedStandIds) );
    };

    openApprovalModal(){
        this.approveConfirmation = true;
        this.getStatusOptions();
    };

    closeApprovalModal(){
        this.approveConfirmation = false;
        this.getStandList();
    };

    handleStatusChange(event){
       
        this.status = event.target.value;
        console.log('this.status ::'+this.status );
        if(this.status){
            this.yesBtnDisabled = false;
        }
        if(this.status==='Tentative Approval'){
            const dt = new Intl.DateTimeFormat('en', {
                year: 'numeric',
                month: '2-digit',
                day: '2-digit'
            });
            const [{value: mo}, , {value: da}, , {value: ye}] = dt.formatToParts(new Date());
            this.approvalDate = `${ye}-${mo}-${da}`;
            console.log('this.approvalDate ::'+this.approvalDate );
        }
        else{
            this.approvalDate = undefined;
        }
    }; 

    handleSubmit(){    
        this.spinner = true;    
        if(!this.status){
            this.spinner = false;
            showToast(this,'Please fill all required fields','error','Warning');
        }
       else if(this.status==='Stand Design Rejected/Incomplete' && !this.step){
            this.spinner = false;
            showToast(this,'Rejection step must be select','error','Warning');
        }
        else if(this.status==='Stand Design Rejected/Incomplete' && !this.rejectionReason){
            this.spinner = false;
            showToast(this,'Rejection reason must not empty','error','Warning');
        }
        else{
            approvalStandDesign({selectedStandIds : this.selectedStandIds,status :this.status,approvalDate: this.approvalDate})
            .then(res=>{
                this.spinner = false;
                this.closeApprovalModal();
                 showToast(this,'Stand Design(s) Approved','success','Success');
            })
            .catch(error=>{
                this.spinner = false;
                this.closeApprovalModal();
                handleErrors(this,error);
            })
            
        }        
    };    

    openRejectionModal(){
        this.step = undefined;
        this.rejectionReason = '';
        this.rejectConfirmation = true;
        this.getStatusOptions();
    };

    closeRejectionModal(){
        this.rejectionReason = '';
        this.rejectConfirmation = false;
        this.getStandList();
    };

    handleStepChange(event){        
        this.step = event.target.value;
        console.log('this.step::'+this.step);
    };

    handleRejectionReasonChange(event){
        console.log('event.target.value ::'+event.detail.value );
        this.rejectionReason = event.detail.value;
    };
    
    yesReject(){
        this.spinner = true;
        this.status = 'Stand Design Rejected/Incomplete';
        if(this.step && this.rejectionReason){
            rejectStandDesign({selectedStandIds : this.selectedStandIds,status :this.status,step:this.step.join(';'),rejectionReason: this.rejectionReason})
            .then(res=>{
                this.spinner = false;
                this.closeRejectionModal();
                 showToast(this,'Stand Design(s) Rejected','success','Success');
            })
            .catch(error=>{
                this.spinner = false;
                this.closeRejectionModal();
                handleErrors(this,error);
            })
           
        }
        else{
            showToast(this,'All values are required','error','Warning');
        }
        
    };

    get isRejectedStepShow(){
        console.log('this.status1::'+this.status);
        return this.status && this.status==='Stand Design Rejected/Incomplete';
    }

    refreshPage(){
        eval("$A.get('e.force:refreshView').fire();");
    };

    get isActionBtnDisabled(){
        return this.selectedRows && this.selectedRows.length>0 ? false : true;
    };

}