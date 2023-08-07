/* eslint-disable @lwc/lwc/no-async-operation */
import { LightningElement, api, track } from 'lwc';
import {NavigationMixin} from 'lightning/navigation';
import getAgreements from '@salesforce/apex/SSCDashboardLtngCtrl.getAgreements';
import getAttachment from '@salesforce/apex/CommonTableController.getFileDetail';
import { handleErrors } from 'c/lWCUtility';
const DELAY=300;

//Retrieve Custom Labels
//import Last_Modified_Date from '@salesforce/label/c.Last_Modified_Date';
//import Opportunity from '@salesforce/label/c.Opportunity';

export default class PendingContractContactTab extends NavigationMixin(LightningElement) {
    @api recordId;
    @track agreementData;
    @track totalRows;
    @track searchValue;
    @track spinner;
    @track isShow;
    @track firstTime;
    @track pagesize;
    @track LASTMODIFIEDDATE;
    @track OPPORTUNITY;

    connectedCallback(){
        //this.LASTMODIFIEDDATE = Last_Modified_Date;
        //this.OPPORTUNITY = Opportunity;
        this.firstTime=true;
        this.searchValue = '';
        this.spinner = false;
        this.isShow = this.spinner===false && this.firstTime;
        this.getData();
    }

    getData(){
        this.spinner = true;
        getAgreements({oppId:this.recordId,searchValue:this.searchValue})
        .then(result=>{
            this.firstTime = false;
            this.spinner = false;
            this.agreementData = result;
            if(result.length>0){
                this.totalRows = result.length;
            }
            else{
                this.totalRows = undefined;
            }
            this.isShow = this.spinner===false && this.firstTime;
        })
        .catch(error=>{
            handleErrors(this,error);
        });
    }

    onPageSizeChange(){
        window.clearTimeout(this.delayTimeout);
        this.delayTimeout = setTimeout(() => {
        },DELAY);
    }

    get isTrue(){
        return this.spinner && !this.firstTime;        
    }

    get pagesizeList(){
        return [
            {'label':'5','value':'5'},
            {'label':'10','value':'10'},
            {'label':'15','value':'15'},
            {'label':'20','value':'20'},
            {'label':'30','value':'30'},
            {'label':'50','value':'50'}
        ];
    }

    /**
     * Fire whenever user type in search box, but data load if search field empty
     */
    reloadData(){
        let searchValue = this.template.querySelector(".search-box").value;
        searchValue = searchValue.trim();
        if(searchValue===''){
            window.clearTimeout(this.delayTimeout);
            this.delayTimeout = setTimeout(() => {
                this.searchValue = searchValue;
                this.getData();
            },DELAY);
        }
    }

    searchData(){        
        let searchValue = this.template.querySelector(".search-box").value;
        searchValue = searchValue.trim();
        window.clearTimeout(this.delayTimeout);
        this.delayTimeout = setTimeout(() => {
            this.searchValue = searchValue;
            this.getData();
        },DELAY);
    }

    openAttachment(event){
        let parentId = event.target.dataset.recordId;
        getAttachment({objectName:'Attachment',fields:'Id',parentId:parentId})
        .then(res=>{
            if(res.length>0){
                window.open('/servlet/servlet.FileDownload?file='+res[0].Id);
            }
        })
        .catch(error=>{
            handleErrors(this,error);
        })
    }

    goToRecord(event){
        let recordId = event.target.dataset.recordId;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: 'Agreement__c',
                actionName: 'view'
            },
        });
        
    }

    goToOpp(event){
        let oppId = event.target.dataset.recordId;        
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: oppId,
                objectApiName: 'Opportunity',
                actionName: 'view'
            },
        });
    }

    goToSample(){
        window.open("/servlet/servlet.FileDownload?file=00P18000001i8vf")
    }

}