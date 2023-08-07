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

export default class ImccAccountSelectionHeader extends NavigationMixin(LightningElement) {
    eventcode;
    accountId;
    tabId;
    _interval;
    className ='imccAccountSelectionHeader';
    comp_type ='LWC';
    @track userObj={};
    @track methodName;
    @track accountName;
    @track accLst;
    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        if (currentPageReference) {
            this.eventcode = currentPageReference.state.edcode;
            this.accountId = currentPageReference.state.accId;
            this.tabId = currentPageReference.state.tabId;
            this.doInit();  
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
            data.forEach((row) => {
                accDetailLsts.push(row);
            });
            this.accLst = accDetailLsts;
            console.log(JSON.stringify(this.accLst));
        })
        .catch(error=>{
            //handleErrors(this,error);
            handleUIErrors(this,error);
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
            handleUIErrors(this,error);
        })        
    };
    openProfileMenu(event){
        event.stopPropagation();
        const domElement = this.template.querySelector(".user-profile-dropdown");
        if(domElement){
            domElement.classList.toggle("active");
        }
        const domElement2 = this.template.querySelector(".name-link");
        if(domElement2){
            domElement2.classList.toggle("active-name");
        }
        this.hideAccountDropdown();
    }
    openAccountList(event){
        event.stopPropagation();
        const domElement = this.template.querySelector(".account-list");
        if(domElement){
            domElement.classList.toggle("active");
        }
        const domElement2 = this.template.querySelector(".switch-account-label");
        if(domElement2){
            domElement2.classList.toggle("active");
        }
        this.hideUserMenuDropdown();
    };
    
    hideAccountDropdown(){
        const domElement = this.template.querySelector(".account-list");
        if(domElement){
            domElement.classList.remove("active");
        }
        const domElement2 = this.template.querySelector(".switch-account-label");
        if(domElement2){
            domElement2.classList.remove("active");        
        }
    }

    hideUserMenuDropdown(){
        const domElement = this.template.querySelector(".user-profile-dropdown");
        if(domElement){
            domElement.classList.remove("active");
        }
        const domElement2 = this.template.querySelector(".name-link");
        if(domElement2){
            domElement2.classList.remove("active-name");
        }
    }
    
    handleClicmOnTop(event){        
        event.stopPropagation();
    }
    
    hideDropdown(that){
        const domElement = that.template.querySelector(".account-list");
        if(domElement){
            domElement.classList.remove("active");
        }
        const domElement2 = that.template.querySelector(".switch-account-label");
        if(domElement2){
            domElement2.classList.remove("active");
        }
        const profileMenu = that.template.querySelector(".user-profile-dropdown");
        if(profileMenu){
            profileMenu.classList.remove("active");
        }
        const profileMenu2 = that.template.querySelector(".name-link");
        if(profileMenu2){
            profileMenu2.classList.remove("active-name");
        }
    };
    
    openMobileMenu(event){
        event.stopPropagation();
        let height = screen.height - 160;
        this.template.querySelector(".mobile-menu-body").style="height:"+height+"px";        
        let progress = 480;
        this._interval = setInterval(() => {
            progress = progress - 100;              
            if ( progress <= 0 ) {  
                progress = 0;
                clearInterval(this._interval);  
                this.template.querySelector(".modal-overlay").classList.add("active");
            }
            this.template.querySelector(".mobile-menu").style = "display: block;transform-style: preserve-3d;-webkit-transform:translate3d("+progress+"px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);-moz-transform:translate3d("+progress+"px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);-ms-transform:translate3d("+progress+"px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);transform:translate3d("+progress+"px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);";
        }, 10);
    };

    closeMobileMenu(event){  
        /* working good, don't remove comment before ticket assign*/
        //event.stopPropagation();        
        let progress = 0;
        this._interval = setInterval(() => {  
            progress = progress + 100;              
            if ( progress >= 480 ) {  
                progress = 480;
                clearInterval(this._interval);  
                this.template.querySelector(".modal-overlay").classList.remove("active");
                this.template.querySelector(".mobile-menu").style = "display: none;transform-style: preserve-3d;-webkit-transform:translate3d("+progress+"px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);-moz-transform:translate3d("+progress+"px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);-ms-transform:translate3d("+progress+"px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);transform:translate3d("+progress+"px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);";
            }
            this.template.querySelector(".mobile-menu").style = "transform-style: preserve-3d;-webkit-transform:translate3d("+progress+"px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);-moz-transform:translate3d("+progress+"px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);-ms-transform:translate3d("+progress+"px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);transform:translate3d("+progress+"px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);";
        }, 10);
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