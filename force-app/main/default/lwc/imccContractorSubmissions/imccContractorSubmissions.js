import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import editions from '@salesforce/apex/Imcc_ContractorSubmissions.getAllActiveEditions';
import getContractorMapping from '@salesforce/apex/Imcc_ContractorSubmissions.getContractorMap';
import updateRecords from '@salesforce/apex/Imcc_ContractorSubmissions.updateRecords';
import { handleErrors,showToast } from 'c/imcc_lwcUtility';

export default class ImccContractorSubmissions extends NavigationMixin(LightningElement) {
    @track spinner;    
    @track editionsList;
    @track eId;
    @track st;
    @track tableData;
    @track approveConfirmation;
    @track rejectConfirmation;
    @track rejectionReason;
    //show hide contractor/stand submission by a flag 
    @track showContractor;
    @track showBooth;
    @track showStand;
    @track selectedRows;
    @track currentOption;
    @track listEdition;
    eventCode;
    @track columns = [
        {label: 'View', type: 'button-icon', initialWidth: 60, typeAttributes:
                { label: { fieldName: 'actionLabel'}, title: 'View Contractor Submission', name: 'view', 
                iconName: 'utility:preview',variant:'bare'}
        },
        { label: 'Exhibitor/Reseller Name', fieldName: 'ExContactName',type:'url',wrapText: true,typeAttributes:{label: { fieldName: 'Exhibitor_Contact_Name' }} },
        { label: 'Exhibitor/Reseller Company', fieldName: 'ExAccountName', type: 'url',wrapText: true,typeAttributes:{label: { fieldName: 'Exhibitor_Account_Name' }} },
        { label: 'User Type', fieldName: 'Exhibitor_User_Type', type: 'text',wrapText: true },
        { label: 'Booth No/Pavilion', fieldName: 'Booth_No', type: 'text' },
        { label: 'Booth Product Type', fieldName: 'Booth_Type', type: 'text',wrapText: true },
        { label: 'Contractor Account Details', fieldName: 'AccountName', type: 'url',wrapText: true,typeAttributes:{label: { fieldName: 'Contractor_Account_Name' }} },
        { label: 'Contractor Contact Name', fieldName: 'ContactName', type: 'url',wrapText: true,typeAttributes:{label: { fieldName: 'Contractor_Contact_Name' }} },
        {label : 'Contractor Status',fieldName:'Contractor_Status',type:'text',wrapText: true},
        { label: 'Email', fieldName: 'Contractor_Contact_Email', type: 'email' },
        { label: 'Mobile', fieldName: 'Contractor_Contact_Mobile', type: 'phone' },
        { label: 'Submission Date', fieldName: 'Submission_Date', type: 'date'}
    ];

    connectedCallback(){
        this.st='';
        this.eId='';
        this.tableData = [];
        this.selectedRows = [];
        this.getEditions();        
    };

    getListData(){
        this.spinner = true;
        this.tableData = [];
        getContractorMapping({editionId:this.eId})
        .then(res=>{
            const data = JSON.parse(JSON.stringify(res));
            const d = data.listConMapping;
            const listPD = data.listPD;
            let mapPD = {};
            listPD.forEach(pd=>{
                mapPD[pd.Contractor_Mapping__c] = pd;
            });
            const temp = [];    
            try{        
                d.forEach(i=>{
                    temp.push({
                        Id:i.Id,
                        Exhibitor_CEM:mapPD[i.Id].Contact_Edition_Mapping__c,
                        Exhibitor_Account_Id:mapPD[i.Id].Contact_Edition_Mapping__r.Account__c,
                        ExAccountName:'/'+mapPD[i.Id].Contact_Edition_Mapping__r.Account__c,
                        Exhibitor_Account_Name:mapPD[i.Id].Contact_Edition_Mapping__r.Account__r.Name,
                        Exhibitor_Contact_Id:mapPD[i.Id].Contact_Edition_Mapping__r.Contact__c,
                        ExContactName:'/'+mapPD[i.Id].Contact_Edition_Mapping__r.Contact__c,
                        Exhibitor_Contact_Name:mapPD[i.Id].Contact_Edition_Mapping__r.Contact__r.Name,
                        Exhibitor_User_Type:mapPD[i.Id].Contact_Edition_Mapping__r.Access_Type__c,
                        Booth_Id:mapPD[i.Id].Id,
                        Booth_No:mapPD[i.Id].Booth_Number__c,
                        Booth_Type:mapPD[i.Id].Booth_Product_Type__c,                    
                        Contractor_Account_Name:i.TempContact__r.Account__c ?i.TempContact__r.Account__r.Name:i.TempContact__r.TempAccount__c?i.TempContact__r.TempAccount__r.Name:'',
                        AccountName:'/'+(i.TempContact__r.Account__c?i.TempContact__r.Account__c:i.TempContact__r.TempAccount__c?i.TempContact__r.TempAccount__c:''),
                        Contractor_Contact_Name:i.TempContact__r.FirstName__c+' '+i.TempContact__r.LastName__c,
                        ContactName:'/'+i.TempContact__c,
                        Contractor_Contact_Email:i.TempContact__r.Email__c,
                        Contractor_Contact_Mobile:i.TempContact__r.MobilePhone__c,
                        Contractor_Status:i.Contractor_Status__c,
                        TempContactId:i.TempContact__c,
                        Submission_Date:i.TempContact__r.CreatedDate        
                    });
                }); 
            }
            catch(e){
                console.error(e);
            }       
            this.tableData = temp;
        })
        .catch(error=>{
            handleErrors(this,error);
        })
        .finally(()=>{
            this.spinner = false;
        })
    };

    handleRowSelect(event){
        this.selectedRows = event.detail.selectedRows;        
        console.log(JSON.stringify(this.selectedRows));
    };

    handleRowAction(event){
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        let tempContactId = row.TempContactId;
        switch (actionName) {
            case 'view':
                //navigate to temp contact record
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: tempContactId,
                        objectApiName: 'TempContact__c',
                        actionName: 'view'
                    }
                });
                break;
            default:
                console.log('row action not found');
        }
    };

    getEditions(){
        this.listEdition = [];
        let e = [{label:'--None--',value:''}];
        editions({})
        .then(res=>{
            console.log(JSON.stringify(res));
            this.listEdition = res;
            res.forEach(i => {
                e.push({label:i.Name,value:i.Id});
            });
            this.editionsList = e;
        })
        .catch(error=>{
            handleErrors(this,error);
        });
    };

    handleEditionChange(event){
        this.eId = event.target.value;
        this.listEdition.forEach(i => {
            if(i.Id === this.eId){
               this.eventCode = i.Edition_Code__c;
            }
        });
        if(this.eId && this.st==='cn'){
            this.showBooth = false;
            this.showContractor = false;
            this.showStand = false;
            setTimeout(()=>{
                this.showContractor = false;
                this.showStand = false;  
                this.showBooth = true; 
            },500);
        }
        else if(this.eId && this.st==='cs'){
            this.getListData();
        }
        else if(this.eId && this.st==='ss'){
            this.showContractor = false;
            this.showStand = false;
            this.showBooth = false;  
            setTimeout(()=>{
                this.showContractor = false;
                this.showStand = true; 
                this.showBooth = false;   
            },500);
        }
        else if(this.eId && this.st==='sd'){
            this.showContractor = false;
            this.showStand = false;
            this.showBooth = false;  
            setTimeout(()=>{
                this.showContractor = false;
                this.showStand = false; 
                this.showBooth = true;   
            },500);
        }
    };

    handleSTChange(event){
        this.st = event.target.value;
        if(this.st==='cn'){
            this.showContractor = false;
            this.showStand = false;
            this.showBooth = true;  
        }
        else if(this.st==='cs'){
            this.showContractor = true;
            this.showStand = false;
            this.showBooth = false; 
            this.getListData();
        }
        else if(this.st==='ss'){            
            this.showContractor = false;
            this.showStand = true;  
            this.showBooth = false;   
        }
        else if(this.st==='sd'){            
            this.showContractor = false;
            this.showStand = false;  
            this.showBooth = true;   
        }
        else{
            this.showContractor = false;
            this.showStand = false;
            this.showBooth = false; 
        }
    };
    
    openApprovalModal(){
        this.approveConfirmation = true;
    };

    closeApprovalModal(){
        this.approveConfirmation = false;
    };

    yesApprove(){
        const temp = [];
        const contactIds = [];
        this.selectedRows.forEach(item=>{
            if(contactIds.indexOf(item.TempContactId)<0){
                contactIds.push(item.TempContactId);
                temp.push({sobjectType:'TempContact__c',Contractor_Status__c:'Approved',Id:item.TempContactId});
            }
        });
        this.spinner = true;
        //call apex action to update temp contact records
        updateRecords({records:temp})
        .then(()=>{
            showToast(this,'Selected contractors have been approved.','success','Success');
            this.closeApprovalModal();
            this.getListData();
        })
        .catch(error=>{
            handleErrors(this,error);
        })
        .finally(()=>{
            this.spinner = false;
        })
    };

    openRejectionModal(){
        this.rejectionReason = '';
        this.rejectConfirmation = true;
    };

    closeRejectionModal(){
        this.rejectionReason = '';
        this.rejectConfirmation = false;
    };
    
    rejectionReasonChange(event){
        this.rejectionReason = event.target.value;
    };

    yesReject(){
        const temp = [];
        const contactIds = [];
        this.selectedRows.forEach(item=>{
            if(contactIds.indexOf(item.TempContactId)<0){
                contactIds.push(item.TempContactId);
                temp.push({sobjectType:'TempContact__c',Contractor_Status__c:'Rejected',Rejection_Reason__c:this.rejectionReason,Id:item.TempContactId});
            }
        });
        this.spinner = true;
        //call apex action to update temp contact records
        updateRecords({records:temp})
        .then(()=>{
            showToast(this,'Selected Contractors have been rejected.','success','Success');
            this.closeRejectionModal();
            this.getListData();
        })
        .catch(error=>{
            handleErrors(this,error);
        })
        .finally(()=>{
            this.spinner = false;
        })
    };

    get options(){
        return [
            {label:'--None--',value:''},
            {label:'Contractor Nomination',value:'cn'},
            {label:'Contractor Submission',value:'cs'},
            {label:'Stand Design Approval',value:'ss'},
            {label:'Stand Design Submissions',value:'sd'}
        ];
    };

    get isActionBtnDisabled(){
        return this.selectedRows && this.selectedRows.length>0 ? false : true;
    };

    get isYesRejectButtonDisable(){
        return !this.rejectionReason;
    }
}