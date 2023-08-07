import { LightningElement, track, api} from 'lwc';
import additionalUsersCEM from '@salesforce/apex/IMCC_EditionPopupHandler.additionalUsersCEM';
import searchContact from '@salesforce/apex/IMCC_EditionPopupHandler.searchContact';
import replaceUser from '@salesforce/apex/IMCC_EditionPopupHandler.replaceUser';
import { handleErrors,showToast } from 'c/imcc_lwcUtility';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';

import MSG from '@salesforce/label/c.Replace_User_Success_Msg';
import ReplaceUserMsg from '@salesforce/label/c.Replace_user_Screen_Message';  
import inactiveCheckbox from '@salesforce/label/c.IMCC_Label_Replace_User_Checkbox';
import cemNote from '@salesforce/label/c.IMCC_CEM_Inactive_Note';

export default class Imcc_ReplaceUserCEM extends NavigationMixin(LightningElement) {
    @api recordId;
    @track selectedValue;
    @track options = [];
    @track options2 = [];
    @track radioOpt;  
    @track checkboxFieldValue;  
    isLoaded;
    contactIds;//contact id list that has contact edition mapping record for this event
    editionId;
    accountId;
    contactId;
    isActiveCon;
    
    label = {
        ReplaceUserMsg,
        inactiveCheckbox,
        cemNote
    };
    renderedCallback(){
        console.log('recordId: '+this.recordId);
        if(!this.isLoaded && this.recordId){
            this.isLoaded = true;
            this.retreiveAdditionalCEMs();
        }
    }
    
    retreiveAdditionalCEMs() {
        console.log('CEMID'+this.recordId);
        additionalUsersCEM({ 
            recordId: this.recordId
        })
        .then(result => {            
            let opt = [];
            this.contactIds = [];
            result.forEach((row) => {
                this.contactIds.push(row.Contact__c);
                if(row.Id!=this.recordId){                      
                    if(row.Contact__r.Email){                  
                        opt.push( { label: row.Contact__r.Name+' ('+row.Contact__r.Email+') - '+row.Account__r.Name, value: row.Id,contactId:row.Contact__c });
                    }
                    else{
                        opt.push( { label: row.Contact__r.Name+' - '+row.Account__r.Name, value: row.Id,contactId:row.Contact__c });
                    }
                }
                else{
                    this.editionId = row.Edition__c;
                    this.accountId = row.Account__c;
                }
            }); 
            this.options = opt;
            this.radioOpt = opt;        
        })
        .catch(error => {
            handleErrors(this,error);            
        }); 
    };

    handleSearch(event){
        let searchKey = event.target.value;
        console.log('searchKey: '+searchKey);
        
        if(searchKey && searchKey.length>1){
            searchContact({key:searchKey})
            .then(res=>{
                let opt = [];                
                res.forEach(item=>{                    
                    if(this.contactIds.indexOf(item.Id)<0){
                        let email = item.Email?' ('+item.Email+') ':'';
                        if(item.Account){
                            opt.push({label:item.Name+email+' - '+item.Account.Name,value:item.Id,accountId:item.AccountId});
                        }
                        else{
                            opt.push({label:item.Name+email,value:item.Id,accountId:item.AccountId});
                        }
                    }
                });
                this.options2 = opt;
                let temp  = [];
                temp = temp.concat(this.options2);
                temp = temp.concat(this.options);                
                this.radioOpt = temp;
            })
            .catch(error=>{
                handleErrors(this,error);
            })
        }
        else{
            this.radioOpt = this.options;
        }
    }

    handleChange(event) {
        this.selectedValue = event.detail.value;
        this.options.forEach(item=>{
            if(this.selectedValue == item.value){
                this.contactId = item.contactId;
            }
        });
        this.options2.forEach(item=>{
            if(this.selectedValue == item.value){
                this.accountId = item.accountId;                
            }
        });
    };

    handleActiveChange(event){
        this.checkboxFieldValue = event.target.checked;
        this.isActiveCon = this.checkboxFieldValue;
    }


    @track spinner;
    replaceUser(){
        const data = {
            "editionId":this.editionId,
            "accountId":this.accountId,
            "selectedRecordId":this.selectedValue,
            "recordId":this.recordId,
            "contactId":this.contactId,
            "isActiveCon":this.isActiveCon
        }
        this.spinner = true;
        replaceUser({data:JSON.stringify(data)})
        .then(()=>{
            this.spinner = false;
            this.dispatchEvent(new CloseActionScreenEvent());
            showToast(this,MSG,'success','Success');
            // View a custom object record.
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.recordId,
                    objectApiName: 'c__Contact_Edition_Mapping__c', // objectApiName is optional
                    actionName: 'view'
                }
            });

        })
        .catch(error=>{
            this.spinner = false;
            handleErrors(this,error);
        })
    };

    get isButtonDisabled(){
        return !this.selectedValue;
    }
}