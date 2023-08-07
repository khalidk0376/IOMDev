import { api, LightningElement, track } from 'lwc';
import getStandFileTypes from '@salesforce/apex/IMCC_StandDesignSubmissionCtrl.getStandFileTypes';
import deleteStandFileTypes from '@salesforce/apex/IMCC_StandDesignSubmissionCtrl.deleteStandFileTypes';
import { handleErrors,showToast } from 'c/imcc_lwcUtility';

export default class ImccStandFileTypes extends LightningElement {
    @api recordId;

    @track fileTypes;
    @track isFileTypeFound;
    @track spinner;
    @track isPublished;
    @track isEdit;
    @track isView;
    @track isDelete;
    @track selectedId;
    connectedCallback(){
        this.getAll();
    };

    getAll(){
        this.spinner = true;
        getStandFileTypes({standSettingId:this.recordId,type:''})
        .then(res=>{
            this.fileTypes = res;
            this.isFileTypeFound = res.length>0?true:false;
            //this.isPublished = true;
            if(this.isFileTypeFound){
                this.isPublished = res[0].Stand_Setting__r.Status__c==='Published'?true:false;
            }
        })
        .catch(error=>{
            handleErrors(this,error);
        })
        .finally(()=>{
            this.spinner = false;
        });
    }

    openRecord(event){
        let index = parseInt(event.currentTarget.dataset.index,10);
        this.selectedId = this.fileTypes[index].Id;
        this.isView = true;
    };

    addFileType(){
        this.isEdit = true;
        this.selectedId='';
    };

    handleMenuSelect(event) {        
        const selectedItemValue = event.detail.value;        
        const index = parseInt(event.currentTarget.dataset.index,10);
        
        if(selectedItemValue==="delete"){
            this.selectedId = this.fileTypes[index].Id;
            this.isDelete = true;
        }
        else if(selectedItemValue==="edit"){
            this.selectedId = this.fileTypes[index].Id;
            this.isEdit = true;
        }
    };

    close(){
        this.selectedId = '';
        this.isDelete = false;
        this.isEdit = false;
        this.isView = false;
    };

    yesRemove(){
        this.spinner = true;
        deleteStandFileTypes({id:this.selectedId})
        .then(()=>{
            showToast(this,'Record was deleted','success','Success');
            this.close();
            this.getAll();
        })
        .catch(error=>{
            handleErrors(this,error);
        })
        .finally(()=>{
            this.spinner = false;
        });
    };

    handleSubmit(event){        
        event.preventDefault();       // stop the form from submitting
        const fields = event.detail.fields;
        if(!fields.Name || !fields.Type__c){
            showToast(this,'Please enter name and type','error','Validation Error');
            return false;
        }
        this.template.querySelector('lightning-record-edit-form').submit(fields);
        this.spinner = true;
     };

     handleSucess(event){
        this.spinner = false;
        showToast(this,'Record was '+this.btnLabel+'d.','success','Success');
        this.close();
        this.getAll();
     }

    get fileCount(){
        return this.fileTypes ? this.fileTypes.length : 0;
    };

    get btnLabel(){
        return this.selectedId ? 'Update' : 'Create';
    }
}