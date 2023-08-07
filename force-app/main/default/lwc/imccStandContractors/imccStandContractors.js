import { api, LightningElement, track, wire } from 'lwc';
import { CurrentPageReference,NavigationMixin } from 'lightning/navigation';
import getAccountContacts from '@salesforce/apex/IMCC_StandContractorCtrl.getAccountContacts';
import createCompany from '@salesforce/apex/IMCC_StandContractorCtrl.setAccountContacts';
import setContact from '@salesforce/apex/IMCC_StandContractorCtrl.setContact';
import getCountries from '@salesforce/apex/IMCC_StandContractorCtrl.getCountries';
import getCountryCodeByName from '@salesforce/apex/IMCC_StandContractorCtrl.getCountryCodeByName';
import { getPicklistValues,getObjectInfo } from 'lightning/uiObjectInfoApi';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import BillingStateCode_FIELD from '@salesforce/schema/Account.BillingStateCode';
import createContactMap from '@salesforce/apex/IMCC_StandContractorCtrl.createContactMap';
import IMCC2 from '@salesforce/resourceUrl/IMCC2';

import { handleErrors,showToast,redirect } from 'c/imcc_lwcUtility';

export default class ImccStandContractors extends NavigationMixin(LightningElement) {
    @api selectedBoothName;
    @api selectedBoothId;
    @api selectedBoothData;
    @api editionCode;
    @api byOpsUser;
    eventCode;
    accountId;
    tabId;
    countries;
    allStateList; //for store all state
    stateListToDraw; // this is vary base on country selection
    isDisable = false
    selectedCheckbox = [];
    showMultiBoothCheckBoxGroup= false;
    isButtonDisable = false;
    @track spinner = false;    
    @track selectedAccountId='';
    @track selectedAccountName='';    
    @track selectedAccountCountryName='';
    @track accountList;
    @track newAccountObj;
    @track newContactObj;
    @track contractorMap;

    plus = IMCC2+'/icons/Plus.svg';
    minus = IMCC2+'/icons/Minus.svg';
    
    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {  
        this.stateListToDraw = [{label:'None',value:''}];
        this.newAccountObj = {sobjectType:"TempAccount__c",Address__c:"",City__c:"",Country__c:"",Name:"",State__c:"",Zip__c:""};
        this.newContactObj = {sobjectTpe:"TempContact__c",Id:null,Account__c:null,TempAccount__c:null,FirstName__c:"",LastName__c:"",MobilePhone__c:"",Phone__c:"",Country_Code__c:"",Email__c:""}
        if (currentPageReference) {
            this.eventCode = currentPageReference.state.edcode;
            this.accountId = currentPageReference.state.accId;
            this.tabId = currentPageReference.state.tabId;            
            this.getCountries();
            this.fetchAccountContacts('');
           }
    };

    @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
    accountObject;

    @wire(getPicklistValues, { recordTypeId: '$accountObject.data.defaultRecordTypeId', fieldApiName: BillingStateCode_FIELD})
    wiredata(result,error){
        if(result){            
            const obj = JSON.parse(JSON.stringify(result));
            if(obj.data){
                this.allStateList = JSON.parse(JSON.stringify(obj.data));                
            }
        }
        else if(error){
            console.error(error);
        }
    };

    //set new company state fields options
    setStateOptionByCountryCode(countryCode){
        const opt = [{label:'None',value:''}];
        //state value and label same to store in temp account
        console.log('countryCode: '+countryCode);
        if(this.allStateList && this.allStateList.values.length>0 && countryCode)
        {
            let validFor = this.allStateList.controllerValues[countryCode];
            this.allStateList.values.forEach(item=>{
                if(item.validFor[0]===validFor){
                    opt.push({label:item.label,value:item.label});
                }
            });
        }
        this.stateListToDraw = opt;
    };

    //new company country field
    getCountries(){
        getCountries({})
        .then(res=>{
            const c = JSON.parse(res);
            c.forEach(item=>{
                item.class = 'slds-listbox__item';
            })
            this.countries = c;
        })
        .catch(error=>{
            handleErrors(this,error);
        })
    };
    
    //new company state field 
    get isStateDisabled(){
        return this.stateListToDraw && this.stateListToDraw.length<2?true:false;
    };
    get isStateRequired(){
        return this.stateListToDraw && this.stateListToDraw.length>1?true:false;
    }

    focusCountry(){
        this.template.querySelector('.country-list').classList.add('slds-is-open');
    };

    selectCountry(event){        
        this.newAccountObj.Country__c = event.currentTarget.dataset.country;
        const countryCode =  event.currentTarget.dataset.countryCode;//use for getting dependent picklist options
        this.setStateOptionByCountryCode(countryCode);
        this.template.querySelector('.country-list').classList.remove('slds-is-open');
        let that = this;
        setTimeout(function(){
            that.validate();
        },300)
    };

    searchAccList;//show on combobox 
    fetchAccountContacts(searchText){
        getAccountContacts({searchText:searchText})
        .then(res=>{
            const data = JSON.parse(JSON.stringify(res));
            if(searchText!='' && this.isNewAccountModal && data.length>0){
                this.searchAccList = data;
                if(data[0].Name.toLowerCase()===searchText.toLowerCase()){
                    this.isDisabledSaveAcc = true;
                }
                else{
                    this.isDisabledSaveAcc = false;
                }
                this.showSearchAccList();
            }
            else{
                this.searchAccList = undefined;
                this.isDisabledSaveAcc = false;
                this.showSearchAccList();
            }
            if(!this.isNewAccountModal){
                data.forEach(item=>{
                    //item.total = item.Contacts?item.Contacts.length:0;
                    item.total = item.AccountContactRelations?item.AccountContactRelations.length:0;
                })
                this.accountList = data;
            }
        })
        .catch(error=>{
            handleErrors(this,error);
        });
    };

    // Button actions
    @track isOpenAccountModal;
    @api openAccountModal(){        
        this.isOpenAccountModal = true;
    };

    //close company(account) search modal
    closeAccountModal(){
        this.isOpenAccountModal = false;
        if(!this.byOpsUser){
            this.dispatchEvent(new CustomEvent('closesearchmodal'));
        }
        
    };

    //toggle account child contact record
    openChildContacts(event){
        try{

            this.selectedAccountId = event.currentTarget.dataset.accId;
            this.selectedAccountName = event.currentTarget.dataset.accName;
            this.selectedAccountCountryName = event.currentTarget.dataset.accCountry;
            
            const el = this.template.querySelector("div[data-id='"+this.selectedAccountId+"']");
            el.classList.toggle("slds-hide");            
            if(el.classList.contains("slds-hide")){
                if(event.currentTarget.querySelector('.plus-icon')){
                    event.currentTarget.querySelector('.plus-icon').setAttribute("src",this.plus);
                }
            }
            else{
                if(event.currentTarget.querySelector('.plus-icon')){
                    event.currentTarget.querySelector('.plus-icon').setAttribute("src",this.minus);
                }
            }
        }
        catch(e){
            console.log(e);
        }
    };

    //search company by keyword
    handleCompanySearch(event){
        let searchTerm = event.detail.value;
        if(searchTerm.length>2 || searchTerm.length==0){
            this.fetchAccountContacts(searchTerm);
        }
    };

    //New Account code
    @track isNewAccountModal;
    openNewAccountModal(){
        this.isNewAccountModal = true;    
        this.isOpenAccountModal = false;        
    };

    //close new company(account) modal
    closeNewAccountModal(){
        this.newAccountObj = {sobjectType:"TempAccount__c",Address__c:"",City__c:"",Country__c:"",Name:"",State__c:"",Zip__c:""};
        this.isNewAccountModal = false;
        this.isOpenAccountModal = true;
    };

    handleAccountFieldChange(event){
        try{
            let fieldName = event.target.name;
            let value = event.detail.value?event.detail.value.trim():'';        
            console.log('country: '+value);
            switch (fieldName) {
                case "name":
                this.newAccountObj.Name = value;
                this.fetchAccountContacts(value);                        
                break;
                case "address":
                this.newAccountObj.Address__c = value;
                break;
                case "cty-name":
                    const c = JSON.parse(JSON.stringify(this.countries));
                    let isExactMatch=false;
                    let countryCode='';
                    c.forEach(item=>{
                        item.class = item.Country_Name__c.toLowerCase().indexOf(value.toLowerCase())>=0 || value=='' ?'slds-listbox__item':'slds-listbox__item slds-hide';
                        if(item.Country_Name__c.toLowerCase()===value.toLowerCase()){
                            isExactMatch = true;
                            countryCode = item.Controlling_Field_Code__c;
                        }
                    });
                    this.countries = c;
                    //this.newAccountObj.Country__c = '';
                    if(isExactMatch){
                        this.newAccountObj.Country__c = value;
                        this.template.querySelector('.country-list').classList.remove('slds-is-open');
                    }
                    else{
                        this.template.querySelector('.country-list').classList.add('slds-is-open');
                    }
                    this.setStateOptionByCountryCode(countryCode);
                break;
                case "city":
                this.newAccountObj.City__c = value;
                break;
                case "zip":
                this.newAccountObj.Zip__c = value;
                break;
                case "state":
                this.newAccountObj.State__c = value;
                break;
            }            
            console.log(JSON.stringify(this.newAccountObj));
        }
        catch(e){
            console.error(e);
        }
    };

    validate(){
        let isValid = true;
        try{
            
            const el = this.template.querySelectorAll('lightning-input');
            el.forEach(item=>{
                if(item.name=='cty-name' && this.newAccountObj.Country__c==''){
                    item.value = "";
                }
                item.value = item.value.trim();
            });

            const allValid = [
                ...this.template.querySelectorAll('lightning-input'),
            ].reduce((validSoFar, inputCmp) => {
                inputCmp.value.trim();
                if(inputCmp.name==='cty-name'){
                    let isMatch = false;
                    const c = JSON.parse(JSON.stringify(this.countries));
                    c.forEach(item=>{                        
                        if(item.Country_Name__c===inputCmp.value){
                            isMatch = true;
                        }
                    })
                    if(!isMatch){
                        inputCmp.setCustomValidity('Selected country does not exist');
                    }
                    else{                        
                        inputCmp.setCustomValidity('');
                    }
                    this.template.querySelector('.country-list').classList.remove('slds-is-open');
                }

                inputCmp.reportValidity();                
                return validSoFar && inputCmp.checkValidity();
            }, true);

            let allValid2 = true;
            if(this.template.querySelector('lightning-combobox')){
                allValid2 = [
                    ...this.template.querySelectorAll('lightning-combobox'),
                ].reduce((validSoFar, inputCmp) => {
                    inputCmp.value.trim();
                    inputCmp.reportValidity();
                    return validSoFar && inputCmp.checkValidity();
                }, true);
            }
            
            isValid = allValid && allValid2;
        }
        catch(e){
            console.error(e);
        }
        return isValid;
    };

    get options() {
        let options =[];
        if(this.selectedBoothData && this.selectedBoothData.length > 0){
            this.selectedBoothData.forEach(item=>{ 
                options.push({ label: item.boothNumber, value: item.boothId });
            });
        }
        return options;
    }
    
    // get selectedValues() {
    //     return this.selectedCheckbox.join(',');
    // }

    handleChange(e) {
        this.selectedCheckbox = e.detail.value;
    }

    saveNewAccount(){
         
        if(this.validate()){
            this.spinner = true;
            createCompany({jsonString:JSON.stringify(this.newAccountObj)})
            .then(res=>{
                this.spinner = false;
                if(res.error){
                    //duplicate record found
                    showToast(this,"Duplicate account found in the system, please click on the existing account or click Cancel.","error","Duplicate found")
                }
                else{     
                                   
                    this.newContactObj.Account__c = null;
                    this.newContactObj.TempAccount__c = res.success[0].Id;
                     this.isOpenNewContactModal = true;
                    this.isDisable = false;
                    this.selectedAccountId = null;
                    this.selectedAccountName = this.newAccountObj.Name;
                    this.selectedAccountCountryName = this.newAccountObj.Country__c;
                    this.closeNewAccountModal();
                    this.isOpenAccountModal = false;
                    this.getCountryTelCode();
                    if(this.selectedBoothData && this.selectedBoothData.length > 0){
                        this.showMultiBoothCheckBoxGroup = true;}  
                    showToast(this,"Company was created.","success","Success");
                }
                console.log('newContactObj',JSON.stringify(this.newContactObj));
            })
            .catch(error=>{
                this.spinner = false;
                handleErrors(this,error);
            });
        }
        else{
            showToast(this,"Please update the invalid form entries and try again.","error","Validation Error")
        }
    };

    @track isDisabledSaveAcc;
    selectAccount(event){
        this.newAccountObj.Name =  event.currentTarget.dataset.accName;
        this.isDisabledSaveAcc = true;
        this.template.querySelector(".temp-list").classList.remove("slds-is-open");        
    };

    showSearchAccList(){
        const el = this.template.querySelector(".temp-list");
        if(this.searchAccList && this.searchAccList.length>0 && el){
            el.classList.add("slds-is-open");
        }
        else if(el){
            el.classList.remove("slds-is-open");
        }
    };

    //open new contact modal
    @track isOpenNewContactModal;
    @track countryTelCode='';
    openNewContactModal(){
        this.newContactObj.Account__c = this.selectedAccountId;
        this.isOpenNewContactModal = true;
        this.isOpenAccountModal = false;
        this.isDisable = false;
        this.getCountryTelCode();
        if(this.selectedBoothData && this.selectedBoothData.length > 0){
            this.showMultiBoothCheckBoxGroup = true;
        }
    };

    selectContact(event){

        const selectedAccountId = event.currentTarget.dataset.accId;
        const selectedContactId = event.currentTarget.dataset.conId;
        let accountMap = new Map();
        this.accountList.forEach(item=>{
            if(item.total >0){
                 //accountMap.set(item.Id,item.Contacts);
                 accountMap.set(item.Id,item.AccountContactRelations);
            }
         });
        
         let Contacts = [];
         Contacts = accountMap.get(selectedAccountId);
         //AccountContactRelations = accountMap.get(selectedAccountId);
            Contacts.forEach(con=>{
                //AccountContactRelations.forEach(con=>{
                if(con.ContactId == selectedContactId){
                    this.newContactObj.sobjectTpe = "Contact";
                    this.newContactObj.Account__c = selectedAccountId;
                    this.newContactObj.FirstName__c = con.Contact.FirstName;
                    this.newContactObj.LastName__c = con.Contact.LastName;
                    this.newContactObj.MobilePhone__c = con.Contact.MobilePhone;
                    this.newContactObj.Phone__c = con.Contact.Phone;
                    this.newContactObj.Id = con.Contact.Id;
                    this.newContactObj.Email__c = con.Contact.Email;
                    this.getCountryTelCode();   
                }
            });
        this.isDisable = true;
        this.isOpenNewContactModal = true;
        this.isOpenAccountModal = false;
        if(this.selectedBoothData && this.selectedBoothData.length > 0){
            this.showMultiBoothCheckBoxGroup = true;
        }
    }

    getCountryTelCode(){
        getCountryCodeByName({countryName:this.selectedAccountCountryName})
        .then(res=>{
            this.countryTelCode = res;
            this.newContactObj.Country_Code__c = res;
        })
        .catch(error=>{
            handleErrors(this,error);
        })
    }

    closeNewContactModal(){
        this.newContactObj = {
            sobjectTpe:"TempContact__c",
            Account__c:null,
            TempAccount__c:null,
            FirstName__c:"",
            LastName__c:"",
            MobilePhone__c:"",
            Phone__c:"",
            Country_Code__c:"",
            Email__c:"",
            Id:null
        }
        this.isOpenNewContactModal = false;
        this.isOpenAccountModal = true;
    };
    
    handleContactFieldChange(event){
        let fieldName = event.target.name;
        let value = event.detail.value?event.detail.value.trim():'';            
        switch (fieldName) {
            case "firstname":
            this.newContactObj.FirstName__c = value;            
            break;
            case "lastname":
            this.newContactObj.LastName__c = value;            
            break;
            case "mobilephone":
            this.newContactObj.MobilePhone__c = value;            
            break;
            case "phone":
            this.newContactObj.Phone__c = value;            
            break;
            case "email":
            this.newContactObj.Email__c = value;            
            break;
        }
    };

    saveNewContact(){
        console.log('selectedCheckbox111',JSON.stringify(this.selectedCheckbox));
        let isPhoneValid = true;
        var phonepattern = /^[-\+\#\s\(\)\./0-9]*$/;
        isPhoneValid = phonepattern.test(this.newContactObj.MobilePhone__c);
        isPhoneValid = isPhoneValid?phonepattern.test(this.newContactObj.Phone__c):false;
        if(!isPhoneValid && !this.isDisable){
            showToast(this,"Please enter valid mobile/phone number.","error","Validation Error");
            return false;
        }

        let emailpattern = /^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,15})+$/;
        let isEmailValid = emailpattern.test(this.newContactObj.Email__c);
        if(!isEmailValid && !this.isDisable){
            showToast(this,"Please enter valid email address.","error","Validation Error");            
            return false;
        }

        if((this.validate() && !this.isDisable) || this.isDisable){
            this.spinner = true;
            if(this.spinner){
                this.isButtonDisable = true;
            }
            this.selectedCheckbox.push(this.selectedBoothId);
             if(this.byOpsUser){
                this.eventCode = this.editionCode;
                if(this.newContactObj.sobjectTpe == "TempContact__c"){
                    this.accountId = this.newContactObj.TempAccount__c;
                }
                else if(this.newContactObj.sobjectTpe == "Contact"){
                    this.accountId = this.newContactObj.Account__c;
                }
            }
            this.newContactObj.Name = this.newContactObj.FirstName__c+' '+this.newContactObj.LastName__c;
            if(this.newContactObj.sobjectTpe == "TempContact__c"){
                setContact({jsonString:JSON.stringify(this.newContactObj),boothIds:this.selectedCheckbox,eventCode:this.eventCode,AccountId:this.accountId})
                .then(res=>{
                this.spinner = false;                
                const result = JSON.parse(JSON.stringify(res));
                if(result.success){  
                    this.isOpenNewContactModal = false;                  
                    showToast(this,'Contact was created','success','Success');
                    if(this.byOpsUser){
                        this.dispatchEvent(new CustomEvent('refreshboothtable'));
                    }
                    this.closeAccountModal();
                }
                else{
                    this.isButtonDisable = false;
                    showToast(this,result.error,'error','Duplicate Error');
                    this.selectedCheckbox = [];
                }
                //this.newContactObj = {sobjectTpe:"TempContact__c",Account__c:null,TempAccount__c:null,FirstName__c:"",LastName__c:"",MobilePhone__c:"",Phone__c:"",Country_Code__c:"",Email__c:""}
                })
                .catch(error=>{
                this.spinner = false; 
                this.isButtonDisable = false;               
                handleErrors(this,error);
                this.selectedCheckbox = [];
                })
            }
            else if(this.newContactObj.sobjectTpe == "Contact"){
                let alreadyExistCon = true;
                let newContactObj = {
                    sobjectTpe:"Contact",
                    Id:this.newContactObj.Id,
                    AccountId:this.newContactObj.Account__c,
                    FirstName:this.newContactObj.FirstName__c,
                    LastName:this.newContactObj.LastName__c,
                }
                console.log('jsonString',JSON.stringify(newContactObj));
                createContactMap({alreadyExistCon: alreadyExistCon,boothIds:this.selectedCheckbox, objTempCon: null,eventCode:this.eventCode,jsonString:JSON.stringify(newContactObj),AccountId:this.accountId})
                .then(res=>{
                    this.spinner = false;
                    this.isOpenNewContactModal = false;  
                    this.contractorMap = res;  
                    console.log('result',res); 
                    showToast(this,'Contractor is nominated','success','Success');
                    if(this.byOpsUser){
                        this.dispatchEvent(new CustomEvent('refreshboothtable'));
                    }
                    this.closeAccountModal();
                })
                .catch(error=>{
                    this.spinner = false; 
                    this.isButtonDisable = false;               
                    handleErrors(this,error);
                    this.selectedCheckbox = [];
                });                    
            }           
        }
        else{
            showToast(this,"Please update the invalid form entries and try again.","error","Validation Error")
            this.selectedCheckbox = [];
        }       
    };

    get isRequired(){
        return this.isDisable?false:true;
    }
}