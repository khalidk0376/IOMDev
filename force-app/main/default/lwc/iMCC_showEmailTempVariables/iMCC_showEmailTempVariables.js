import { LightningElement, wire, track, api } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import GROUPNAME1 from '@salesforce/schema/Event_Edition_Email_Template__c.Email_Template__r.Group_Name__c';
import GROUPNAME2 from '@salesforce/schema/Email_Templates__c.Group_Name__c';
import fetchEmailTemp from "@salesforce/apex/Trig_UpdateStatusOnFormData_Handler.getEmailTemplateKeyWordsByModuleALL";

export default class IMCC_showEmailTempVariables extends LightningElement {
    @track templateKeywords = [];
    @track module;
    @track isShowHeader=false;
    @api recordId;
    @api objectApiName;
    recordFields;
    headerText = 'Keywords for Email Templates';
    
    connectedCallback(){
        if(this.objectApiName == 'Email_Templates__c'){
            this.recordFields = [GROUPNAME2];
        }
        else{
            this.recordFields = [GROUPNAME1];
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: '$recordFields' })
    wiredData({ error, data }) {
        if (data) {
            if(this.objectApiName == 'Email_Templates__c'){
                let fieldValue = getFieldValue(data,GROUPNAME2);
                this.module = fieldValue;
            }
            else{
                let fieldValue = getFieldValue(data,GROUPNAME1);
                this.module = fieldValue;
            }
            if(this.module){
                this.headerText = 'Keywords for ' + this.module + ' module Email Templates';
            }
            this.getKeyWords();
        }
        if(error) {
            console.log("error===",error);
        }
    }

    getKeyWords(){
        fetchEmailTemp({module : this.module})
        .then(result => {
            let tempMap = {};
            result.forEach((row) => {
                if(!tempMap.hasOwnProperty(row.Group_Name__c)){
                    tempMap[row.Group_Name__c] = [];
                }
                if(!row.Do_Not_Show_To_Users__c){
                    tempMap[row.Group_Name__c].push(row);
                }
            });
            let templateKeywords = [];
            for(const moduleName in tempMap) {
                let obj = {"Module":moduleName,"Keywords":tempMap[moduleName]};
                templateKeywords.push(obj);
            }
            this.templateKeywords = templateKeywords;
            this.isShowHeader = (this.templateKeywords.length>1);
            console.log('--result ',templateKeywords);
        })
        .catch(error => {
            window.console.log('error...' + JSON.stringify(error));
        });
    }
}