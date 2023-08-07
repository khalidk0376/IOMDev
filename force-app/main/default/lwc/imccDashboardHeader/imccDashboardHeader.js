import { LightningElement, track, wire } from 'lwc';
import { CurrentPageReference,NavigationMixin } from 'lightning/navigation';
import fetchUserTabDetail from "@salesforce/apex/IMCC_HeaderCtrl.fetchUserTabDetails";
import fetchAccountLst from '@salesforce/apex/IMCC_AccountSelectionCtrl.fetchAccountFromEditionMapping';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import { handleErrors,handleUIErrors,redirect } from 'c/imcc_lwcUtility';
import basePath from '@salesforce/community/basePath';
import { loadScript } from 'lightning/platformResourceLoader';
import InformaMarketsCSS from '@salesforce/resourceUrl/InformaMarketsCSS';

export default class ImccDashboardHeader extends NavigationMixin(LightningElement) {
    eventcode;
    accountId;
    tabId;
    className ='imccDashboardHeader';
    comp_type ='LWC';
    @track userObj={};
    @track accountName; 
    @track accLst;    
    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {        
        if (currentPageReference) {
            this.eventcode = currentPageReference.state.edcode;
            this.accountId = currentPageReference.state.accId;
            this.tabId = currentPageReference.state.tabId;
            this.doInit(); 
            console.log('PAGE REFERENE ' +JSON.stringify(currentPageReference)); 
        }
    }
    @wire(getRecord,{recordId:USER_ID,fields:["User.Name","User.Email","User.Username","User.SmallPhotoUrl", "User.FullPhotoUrl", "User.MediumPhotoUrl"]})
    wireuser({error,data}){
        if (error) {
            handleErrors(this,error);
         } else if (data) {
            this.userObj.Name = data.fields.Name.value;
            this.userObj.SmallPhotoUrl = data.fields.SmallPhotoUrl.value;
            this.userObj.FullPhotoUrl = data.fields.FullPhotoUrl.value;
            this.userObj.MediumPhotoUrl = data.fields.MediumPhotoUrl.value;
            this.userObj.Username = data.fields.Username.value;
            this.userObj.Email = data.fields.Email.value;
        } 
    }
    
    doInit() {
        this.fetchAccount();
        this.fetchTabDetails();  
        
        loadScript(this, InformaMarketsCSS + '/CustomerCenterWS11/js/jquery-1.7.1.min.js')            
        .then(() => {
            const that = this;
            window.jQuery("body").click(function(){
                that.hideDropdown(that);
            });    
        })
        .catch(errors => {
            window.console.log(errors);
        });
    }

    fetchAccount(){
        this.methodName='fetchAccount';
        fetchAccountLst({eventcode : this.eventcode}) 
        .then(result => {
            let data = result;
            let accDetailLsts = [];
            data.forEach(row => {
                if(row.Id===this.accountId){
                    this.accountName = row.Name;
                }
                accDetailLsts.push(row);
            });
            this.accLst = accDetailLsts;
            console.log(JSON.stringify(this.accLst));
        })
        .catch(error=>{
            //handleErrors(this,error);
            handleUIErrors(this, error);
        });            
    };

    fetchTabDetails() {
        this.methodName='fetchTabDetails';
        fetchUserTabDetail({ eventCode: this.eventcode, accountId: this.accountId })
        .then(result => {            
            if (result.accountName) {
                this.accountName = result.accountName;
            }
        })
        .catch(error=>{
            //handleErrors(this,error);
            handleUIErrors(this, error);
        })        
    };
    openProfileMenu(event){
        event.stopPropagation();
        const domElement = this.template.querySelector(".user-profile-dropdown");
        domElement.classList.toggle("active");
        const domElement2 = this.template.querySelector(".name-link");
        domElement2.classList.toggle("active-name");
        this.hideAccountDropdown();
    }
    openAccountList(event){
        event.stopPropagation();
        const domElement = this.template.querySelector(".account-list");
        domElement.classList.toggle("active");
        const domElement2 = this.template.querySelector(".switch-account-label");
        domElement2.classList.toggle("active");
        this.hideUserMenuDropdown();
    };
    
    hideAccountDropdown(){
        const domElement = this.template.querySelector(".account-list");
        domElement.classList.remove("active");
        const domElement2 = this.template.querySelector(".switch-account-label");
        domElement2.classList.remove("active");        
    }

    hideUserMenuDropdown(){
        const domElement = this.template.querySelector(".user-profile-dropdown");
        domElement.classList.remove("active");
        const domElement2 = this.template.querySelector(".name-link");
        domElement2.classList.remove("active-name");
    }

    switchAccount(event){
        let accId = event.currentTarget.dataset.account;
        this.template.querySelector(".account-list").classList.remove("active");
        this.redirect('editionselection__c',{"accId":accId});        
    };
    
    handleClickOnTop(event){
        event.stopPropagation();
    };

    hideDropdown(that){
        const domElement = that.template.querySelector(".account-list");
        domElement.classList.remove("active");
        const domElement2 = that.template.querySelector(".switch-account-label");
        domElement2.classList.remove("active");

        const profileMenu = that.template.querySelector(".user-profile-dropdown");
        profileMenu.classList.remove("active");
        const profileMenu2 = that.template.querySelector(".name-link");
        profileMenu2.classList.remove("active-name");
    };
    
    logOut() {
        localStorage.removeItem('UserSession');
        let url = location.host;
        let portal = basePath.split("/")[1];
        if (this.eventcode == '' || this.eventcode == undefined || this.eventcode == null) {
            console.log('Block 1');
            location.href = '../secur/logout.jsp?retUrl=https://' + url + '/'+portal+'/IMCC_UserLogin';
        }
        else {
            location.href = '../secur/logout.jsp?retUrl=https://' + url + '/'+portal+'/IMCC_UserLogin?edcode=' + this.eventcode;
        }
    }   

    redirect(pageName,paramObj){
        redirect(this,NavigationMixin.Navigate,pageName,paramObj);        
    }
}