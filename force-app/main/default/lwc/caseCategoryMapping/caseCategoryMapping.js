import { LightningElement,api,track} from 'lwc';
import { getRecord, updateRecord} from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import Case_Object from '@salesforce/schema/Case';
import LWCExternal from '@salesforce/resourceUrl/LWCExternal';
import { loadStyle } from 'lightning/platformResourceLoader';
import Category_1 from '@salesforce/schema/Case.Category_1__c';
//import Category_4 from '@salesforce/schema/Case.Category_1__r.Name';
import Category_2 from '@salesforce/schema/Case.Category_2__c';
import Category_3 from '@salesforce/schema/Case.Category_3__c';
import ID_FIELD from '@salesforce/schema/Case.Id';
import getCaseCategory from '@salesforce/apex/CaseCategoryMappingCtrl.getCaseCategoryValues';
import getCaseCategoryValue from '@salesforce/apex/CaseCategoryMappingCtrl.getCategoryValueOnCase';

export default class CaseCategoryMapping extends LightningElement {

    @api recordId;

    caseId;
    @track sObjectname = 'Case';
    @track category1;
    @track category2;
    @track category3;

    @track isEditMode = false;
    @track isShow = false;
    @track category1Options;
    @track category2Options;
    @track category3Options;
    @track caseDataShow;
    @track categoryName1;
    @track categoryName2;
    @track categoryName3;
    //@track caseClosed;
    categoryMap = {};


    connectedCallback(){
        this.caseId = this.recordId;
        loadStyle(this, LWCExternal);
        this.getCaseData();

    }
    
    getCaseData()
    {
        getCaseCategoryValue({ recordId : this.recordId })
            .then(result => {
                this.caseDataShow = result;
                //console.log('CAse Data' ,JSON.stringify(result) );
                this.categoryName1  =   this.caseDataShow.Category_1__r==null?null:this.caseDataShow.Category_1__r.Name;
                this.categoryName2  =   this.caseDataShow.Category_2__r==null?null:this.caseDataShow.Category_2__r.Name;
                this.categoryName3  =   this.caseDataShow.Category_3__r==null?null:this.caseDataShow.Category_3__r.Name;
                this.category1  =   this.caseDataShow.Category_1__c;
                this.category2  =   this.caseDataShow.Category_2__c;
                this.caseId     =   this.caseDataShow.Id;
                //this.caseClosed =   this.caseDataShow.IsClosed;
                if(this.category1)
            {
                this.fetchpicklistvals('L2' , this.category1);
            }
            if(this.category2)
            {
                this.fetchpicklistvals('L3' , this.category2);
            }
            })
            .catch(error => {
                this.error = error;
                console.log('Error ' , error );
            });
    
        this.fetchpicklistvals( 'L1' , null);
    }


    fetchpicklistvals(level,parentid)
    {
        //console.log('fetchpicklistvals');
        getCaseCategory({ level: level, parentCategoryId : parentid})

            .then(result => {                       
                let currentData = [];
                 
                let ResultData = result;                
                currentData.push({value: 'none', label:'--NONE--'});		// None 		        
                ResultData.forEach((row) => { 
                    this.categoryMap[row.Id]  = row.Name;              
                    var opt = { label: row.Name , value: row.Id};      
                    currentData.push(opt);					
                }); 
                //console.log('Category MAp : '+JSON.stringify(this.categoryMap));

                // console.log('currentData Role : '+JSON.stringify(this.categoryMap));                        
            if(level === 'L1')
            {
                this.category1Options = currentData;
            }
            if(level === 'L2')
            {                   
                this.category2Options = currentData;
            }
            if(level === 'L3')
            {
                this.category3Options = currentData;
            }            
            });
    }


    handleCategoryChange1(event) {
        event.preventDefault();
        let Name = event.target.name;
        let value = event.detail.value; 
        //let category1 =this.template.querySelector(".category1");
        
    
        if(value != 'none')
        {
            this.fetchpicklistvals('L2' , value);
           this.categoryName1 = this.categoryMap[value];
           
        }
        else{
            this.categoryName1 = null;
        } 
        /*else{
            if(this.caseClosed == true){
                
                category1.setCustomValidity("Category 1 can not be blank");
                category1.reportValidity();
            }
            else{
                this.categoryName1 = null;
            }
            
            
        }*/
        
        this.category1 = value;        
        this.category2 = null;
        this.category3 = null;
        this.categoryName2 = null;
        this.categoryName3 = null;
        //this.updateCase(false);

    }
    handleCategoryChange2(event) {
        event.preventDefault();
        let Name = event.target.name;
        let value = event.detail.value;  
        if(value != 'none')
        {
            this.fetchpicklistvals('L3' , value);
            this.categoryName2 = this.categoryMap[value];
        }
        else{
            this.categoryName2 = null;

        }
        this.category2 = value;
        this.category3 = null;
        
        this.categoryName3 = null;
        //this.updateCase(false);
    }
    handleCategoryChange3(event) {
        event.preventDefault();
        let Name = event.target.name;
        let value = event.detail.value;  
        if(value != 'none')
        {

            this.categoryName3 = this.categoryMap[value];
        }
        else{
            this.categoryName3 = null;
        }
        this.category3 = value;
        this.updateCase(false);
    }

    editRecord(event){
        //console.log('Edit !');
        this.isEditMode = true;
    }
    get disableCategory2()
    {
        // console.log('category1 '+this.category1);
        return this.category1  ? false: true;
    }
    get disableCategory3()
    {
        // console.log('category2 '+this.category2);
        return (this.category2 || this.category2 != null) ? false: true;
    }

    updateCase(showToast) {
        const fields = {};
        //console.log('category1 '+this.category1);
        fields[ID_FIELD.fieldApiName]   = this.caseId;
        fields[Category_1.fieldApiName] = this.category1 =='none'?null:this.category1;
        fields[Category_2.fieldApiName] = this.category2 =='none'?null:this.category2;
        fields[Category_3.fieldApiName] = this.category3 =='none'?null:this.category3;

        const recordInput = { fields };
        //console.log("recordInput data ==",JSON.stringify(recordInput));
        updateRecord(recordInput)
            .then(() => {
                this.isEditMode = false;
                console.log('UPDATED!');
                if(showToast){
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Records updated',
                            variant: 'success'
                        })
                    );
                }                
                // Display fresh data in the form
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error updating record',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            });
    }
}