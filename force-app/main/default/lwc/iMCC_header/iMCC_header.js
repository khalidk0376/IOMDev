import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference,NavigationMixin } from 'lightning/navigation';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import InformaMarketsCSS from '@salesforce/resourceUrl/InformaMarketsCSS';
import fetchUserTabDetail from "@salesforce/apex/IMCC_HeaderCtrl.fetchUserTabDetails";
import fetchEventLst from '@salesforce/apex/IMCC_AccountSelectionCtrl.fetchEventFromEditionMapping';
import USER_ID from '@salesforce/user/Id';

import {getRecord} from 'lightning/uiRecordApi';

import basePath from '@salesforce/community/basePath';
import {handleUIErrors,gotoPage,redirect } from 'c/imcc_lwcUtility';

export default class IMCC_header extends NavigationMixin(LightningElement) {
    @track isHideBreadcrumb=false;
    @track eventcode;
    @track accountId;
    @track tabId;
    @track userObj={};
    @track userRole;
    @track eventDtls;
    @track eventLogo;
    @track eventTabs;
    @track accountName;
    
    @track eventLocation;
    @track eventDate;
    
    @track methodName;
    className ='iMCC_header';
    comp_type ='LWC';

    @track cssmenu = 'cssmenu container-standard dashboard-h';
    @track borderClass;
    @track eventName;
    @track lstEventNameList;
    @track eventList;
    @track accountList;
    @track lstAccountNameList;
    @track openedMenuId;
    @track openedMenuIdMobile;
    @track listContext;
    @track tabShow;
    @track openMenuLabel;
    @track havingCEMRecordsOnAccount;
    _interval;    
    communityPrefix='IMCC';
    prfName='';
    currentPageName='';
    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        console.log('CRP' +JSON.stringify(currentPageReference));
        if (currentPageReference) {
            if(currentPageReference.attributes.name != 'editionselection__c'){
                this.eventcode = currentPageReference.state.edcode;
                this.accountId = currentPageReference.state.accId;
                this.tabId = currentPageReference.state.tabId;
                //this.openedMenuId = '';
                this.doInit();
            }
            this.currentPageName = currentPageReference.attributes.name;            
      }
    }
    @wire(getRecord,{recordId:USER_ID,fields:["User.Name","User.Email","User.Username","User.SmallPhotoUrl","User.Profile.Name"]})
    wireuser({error,data}){
        if (error) {
            this.methodName='getRecord';
            handleUIErrors(this,error);
            
        } 
        else if (data) {
            let prfName =data.fields.Profile.value.fields.Name.value;                           
            this.prfName = prfName;
            
            if(this.eventcode == undefined && this.accountId == undefined && prfName != 'System Administrator'){                
                console.log('window.location.href: '+window.location.href);
                console.log('prfName: '+prfName);
                if(window.location.href.indexOf('live-preview.salesforce-experience.com')<0){
                    this.redirect('Home',undefined);
                }
            }
            this.userObj.Name = data.fields.Name.value;
            this.userObj.ProfileName = data.fields.Profile.value.fields.Name.value;
            this.userObj.SmallPhotoUrl = data.fields.SmallPhotoUrl.value;            
            this.userObj.Username = data.fields.Username.value;
            this.userObj.Email = data.fields.Email.value;
        } 
    }
    
    doInit() {

        this.methodName='doInit';
        this.communityPrefix = basePath.split("/")[1];
        this.eventDtls = {};
        this.fetchTabDetails(this.eventcode, this.accountId);
        if(this.accountId != null && this.accountId != ''){
            this.fetchEventList(this.accountId);
        }
        
        loadScript(this, InformaMarketsCSS + '/CustomerCenterWS11/js/jquery-1.7.1.min.js')
        .then(() => {            
            let that = this;
            window.jQuery("body").click(function(event){                
                that.closeMegaMenu();                
                that.hideEventList(that);
                that.hideProfileMenu(that);                
            });            
        })
        .catch(errors => {
            window.console.error(errors);
            //handleUIErrors(this,errors);
        });
    };

    openMenuClick(event){
        event.stopPropagation();        
    };
    handleClickOnProfile(event){
        event.stopPropagation();
    };

    @track isNewFound; // this variable use for mobile nav
    @track totalNewCount=0; // this variable use for mobile nav too

    @track tabGroup;
    @track activeTabName;
    fetchTabDetails(eventcode, accountId) {

        this.methodName='fetchTabDetails';
        fetchUserTabDetail({ eventCode: eventcode, accountId: accountId })
        .then(result => {
            this.tabShow = [];            
            this.eventDtls = result.edition;
            this.userRole = result.userRole;
            this.havingCEMRecordsOnAccount = result.havingCEMRecords;
            //console.log('HAVING CEM ' +this.havingCEMRecordsOnAccount);
            //console.log('this.userRole ' +this.userRole);
            //console.log('isAdmin ' +this.isAdmin);
            //redirect to home page if logged in user role not platform admin
            if(!this.isAdmin && this.currentPageName=='TeamsManager__c' && this.prfName != 'System Administrator'){
                //alert('1');
                this.redirect('Home',undefined);
            }
            
            if(!this.havingCEMRecordsOnAccount && this.prfName != 'System Administrator'){
                this.redirect('Home',undefined);
            }

            if (this.eventDtls) {
                this.formatEventDtls(this.eventDtls);
                this.eventLogo = '/'+this.communityPrefix+'/servlet/servlet.FileDownload?file=' + this.eventDtls.Edition_Image_URL__c;
                this.eventName = this.eventDtls.Name;
            }
            if (result.accountName) {
                this.accountName = result.accountName;
            }
            
            if (result.userTypeEventTabs) {
                this.eventTabs = result.userTypeEventTabs;
                let savedTabs = JSON.parse(localStorage.getItem('UserSessionTab-'+this.eventcode + '-' + this.accountId+'-'+USER_ID));
                this.eventTabs.forEach(row => {
                    if(this.tabId == row.Event_Tab__r.Tab_Code__c){
                        row.customCSS = "customTabCss";
                    }
                    else{
                        row.customCSS = "customBlank";
                    }
                    this.listContext = result.listTabContextForNew;
                                        
                    if(this.listContext!=undefined){
                        this.listContext.forEach((row1) => {  
                            let tabKeyMatch = this.eventcode + '-' + this.accountId + '-' + USER_ID + '-' + row1.Id;
                            if(row.Event_Tab__r.Tab_Code__c === row1.Event_Tab__r.Tab_Code__c){
                                row.showNew = true;
                                row.tanConextId = row1.Id;
                                if(savedTabs && savedTabs.length>0){
                                    let isPreExistInLocalStorage = false;
                                    savedTabs.forEach((ele) => {
                                        if(ele.tab === tabKeyMatch && row1.Last_Published_Number__c > ele.publishSeq){
                                            this.tabShow.push({'tab':tabKeyMatch,'isVisible':true,'publishSeq':row1.Last_Published_Number__c});
                                            isPreExistInLocalStorage = true;
                                        }                           
                                        else if( (ele.tab === tabKeyMatch )){ 
                                            this.tabShow.push({'tab':tabKeyMatch,'isVisible':ele.isVisible,'publishSeq':row1.Last_Published_Number__c}); 
                                            isPreExistInLocalStorage = true;
                                        }
                                    });
                                    if(!isPreExistInLocalStorage){
                                        this.tabShow.push({'tab':tabKeyMatch,'isVisible':true,'publishSeq':row1.Last_Published_Number__c});
                                    }
                                }
                                else {
                                    this.tabShow.push({'tab':tabKeyMatch,'isVisible': true,'publishSeq':row1.Last_Published_Number__c});                                    
                                }                                
                            }        
                        });                        
                    }   
                    
                    if(savedTabs && this.listContext){
                        this.listContext.forEach((row2) => {  
                            savedTabs.forEach((ele) => {        
                                let tabKeyMatch = this.eventcode + '-' + this.accountId + '-' + USER_ID + '-' + row2.Id;
                                if(ele.tab === tabKeyMatch && !ele.isVisible ){
                                    if(ele.tab === tabKeyMatch && row.Event_Tab__r.Tab_Code__c == row2.Event_Tab__r.Tab_Code__c && row2.Last_Published_Number__c > ele.publishSeq){
                                        row.showNew = true;                                    
                                    }
                                    else if(row2.Last_Published_Number__c <= ele.publishSeq && row.Event_Tab__r.Tab_Code__c == row2.Event_Tab__r.Tab_Code__c){
                                        row.showNew = false;
                                    } 
                                }
                            });
                        });
                    }
                });
            }
            localStorage.setItem('UserSessionTab-'+this.eventcode + '-' + this.accountId+'-'+USER_ID,JSON.stringify(this.tabShow));
            //Add child menu in main menu
            const tabGroup = result.tabGroup;
            //console.log('Tab Group ' +JSON.stringify(tabGroup));
            //console.log('Tabs ' +JSON.stringify(this.eventTabs));
            if(tabGroup){
                tabGroup.forEach(item=>{
                    item.count = 0;
                    item.hasChild = false;
                    item.liClass = 'nav-item';
                    item.class = "link link-d-standard link-d-small";
                    if(item.Type__c && item.Type__c.toLowerCase() ==='multiple'){
                        item.class = "link link-d-standard link-d-small has-child";
                        item.hasChild = true;
                    }
                    item.subMenu = [];
                    if(this.eventTabs){
                        this.eventTabs.forEach(child=>{                        
                            if(item.Id === child.Event_Tab__r.Tab_Group__c){
                                if(child.Event_Tab__r.Standard_Tab_Type__c == 'Manage Team' && (this.userRole != 'Platform Admin' && this.userRole != 'Secondary Admin')){
                                   return; 
                                }
                                item.count = item.count + (child.showNew?1:0);
                                if(item.count>0){
                                    this.isNewFound = true;
                                    this.totalNewCount = this.totalNewCount + (child.showNew?1:0);
                                }
                                item.subMenu.push(child);
                                if(this.tabId===child.Event_Tab__r.Tab_Code__c){
                                    item.liClass = 'nav-item active';
                                    this.activeTabName = item.Name;
                                    this.openMenuLabel = child.Event_Tab__r.Tab_Title__c;                                    
                                }
                            }
                        });
                    }
                    item.tabGroupDisable = (item.Type__c.toLowerCase() ==='multiple' && item.subMenu.length == 0)?true:false;

                    item.isShowNew = item.count>0?true:false;
                });
                if((this.tabId===''||this.tabId===undefined || window.document.title==='Home') && tabGroup.length>0){
                    tabGroup[0].liClass = 'nav-item active';
                    this.openMenuLabel = tabGroup[0].Name;
                }
                this.tabGroup = tabGroup;
            }            
            this.isHideBreadcrumb = window.document.title==='Home'?false:true;
        })
        .catch(error => {
            handleUIErrors(this,error);
        });
    }
    fetchEventList(accountId) {
        this.methodName='fetchEventList';
        fetchEventLst({ accountId: accountId })
        .then(result => {
            this.eventList = result;
            if (this.eventList) {
                let tempArr = [];
                for (let i = 0; i < this.eventList.length; i++) {
                    tempArr.push({ label: this.eventList[i].Name, value: this.eventList[i].Edition_Code__c })
                }
                this.lstEventNameList = tempArr?tempArr:[];
            }
        })
        .catch(error => {
            window.console.log('error...' + JSON.stringify(error));
            handleUIErrors(this,error);
        });
    };

    handleChange(event) {
        //localStorage.removeItem('UserSession');        
        this.redirect('Overview__c',{"accId":this.accountId,"edcode":event.detail.value});
    }
    switchAccount(){
        this.redirect('Home',undefined);
    }
    
    formatEventDtls(eventDtls) {
        let Venue;
        if (eventDtls.Venue__c) {
            this.eventLocation =  eventDtls.Venue__c;
        }
        else {
            this.eventLocation = '';
        }

        let startDate = eventDtls.Start_Date__c;
        let endDate = eventDtls.End_Date__c;
        let startMOnth;
        let endMOnth;
        if (startDate) {
            startMOnth = this.formatDate(startDate);
        }
        else{
            startMOnth = '';
        }
        if (endDate) {
            endMOnth = ' - ' + this.formatDate(endDate);
        }
        else {
            endMOnth = '';
        }
        this.eventDate = startMOnth + endMOnth;
    }

    formatDate(date) {
        let dt = new Date(date), month = '' + (dt.getUTCMonth() + 1), day = '' + dt.getUTCDate(), year = dt.getFullYear(), mon = '';
        if (month === '1') { mon = 'Jan'; }
        if (month === '2') { mon = 'Feb'; }
        if (month === '3') { mon = 'Mar'; }
        if (month === '4') { mon = 'Apr'; }
        if (month === '5') { mon = 'May'; } 
        if (month === '6') { mon = 'Jun'; }
        if (month === '7') { mon = 'Jul'; }
        if (month === '8') { mon = 'Aug'; }
        if (month === '9') { mon = 'Sept'; }
        if (month === '10') { mon = 'Oct'; }
        if (month === '11') { mon = 'Nov'; }
        if (month === '12') { mon = 'Dec'; }
        if (day.length < 2) day = '0' + day;
        return [day, mon, year].join(' ');
    }

    get utilityBarBranding() {
        return 'background-color:#11253f;color:#FFF;';
    }

    get utilityBarTextColor() {
        return 'color:#11253f;';
    }

    get menuBarBranding() {
        return 'color:#11253f;';
    }
    
    handleClick(event) {                        
        event.preventDefault();
        let tabId = event.target.dataset.id;
        let tabContextId = event.target.dataset.tabContextid;
        let type = event.target.dataset.type;
        if(type==="mobile"){
            this.closeMobileMenu();
        }
        else{
            this.closeMegaMenu();
        }
        let tempArr = this.eventTabs;
        let tabType;
        let tabName;
        let stndrdTabType;
        
        let tabKeyMatch = this.eventcode + '-' + this.accountId + '-' + USER_ID + '-' + tabContextId; 
        this.tabShow.forEach((row) => {                 
            if (row.tab === tabKeyMatch) {                  
                row.isVisible = false; 
            }
        }); 
        
        localStorage.setItem('UserSessionTab-'+this.eventcode + '-' + this.accountId+'-'+USER_ID,JSON.stringify(this.tabShow));
        
        tempArr.forEach((row) => {
            if (row.Id == tabId) {
                tabType = row.Event_Tab__r.Tab_Type__c;
                tabName = row.Event_Tab__r.Tab_Code__c;
                stndrdTabType = row.Event_Tab__r.Standard_Tab_Type__c;
                this.openMenuLabel = row.Event_Tab__r.Tab_Title__c;
            }
        });
        
        gotoPage(this,NavigationMixin.Navigate,{"tabType":tabType,"stdtabtype":stndrdTabType,"accId":this.accountId,"edcode":this.eventcode,"tabId":tabName});
    };

    gotoTeamsManager(){        
        try{
            this.hideProfileMenu(this);
            if(this.currentPageName!=='TeamsManager__c'){
                this[NavigationMixin.Navigate]({        
                    type:'comm__namedPage',        
                    attributes: {            
                        name:'TeamsManager__c'        
                    },
                    state: {
                        "accId":this.accountId,
                        "edcode":this.eventcode,
                        "tabId":''
                    }
                });
            }
        }
        catch(e){
            console.error(e.message);
        }        
    };

    openProfileMenu(event){
        event.stopPropagation();
        const domElement = this.template.querySelector(".user-profile-dropdown");
        domElement.classList.toggle("active");
        const domElement2 = this.template.querySelector(".name-link");
        domElement2.classList.toggle("active-name");
        this.hideEventList(this);
    };
    hideProfileMenu(that){
        const domElement = that.template.querySelector(".user-profile-dropdown");
        domElement.classList.remove("active");
        const domElement2 = that.template.querySelector(".name-link");
        domElement2.classList.remove("active-name");
    };

    openEventList(event){
        event.stopPropagation();
        const domElement = this.template.querySelector(".event-list");
        domElement.classList.toggle("active");
        const domElement2 = this.template.querySelector(".switch-event-label");
        domElement2.classList.toggle("active");
        this.hideProfileMenu(this);        
    };

    hideEventList(that){        
        const domElement = that.template.querySelector(".event-list");
        domElement.classList.remove("active");
        const domElement2 = that.template.querySelector(".switch-event-label");
        domElement2.classList.remove("active");        
    };

    handleIconClick(event){        
        this.redirect('Overview__c',{"accId":this.accountId,"edcode":this.eventcode});
    };

    gotoDashboard(){
        this.redirect('editionselection__c',{"accId":this.accountId});
    };

    switchEvent(event){
        //localStorage.removeItem('UserSession');
        let eventcode = event.currentTarget.dataset.eventcode;
        this.template.querySelector(".event-list").classList.remove("active");
        this.redirect('Overview__c',{"accId":this.accountId,"edcode":eventcode});        
    };
    
    logOut() {
        //localStorage.removeItem('UserSession');
        let url = location.host;
        let portal = basePath.split("/")[1];
        if (this.eventcode == '' || this.eventcode == undefined || this.eventcode == null) {
            location.href = '../secur/logout.jsp?retUrl=https://' + url + '/'+portal+'/IMCC_UserLogin';
        }
        else {
            location.href = '../secur/logout.jsp?retUrl=https://' + url + '/'+portal+'/IMCC_UserLogin?edcode=' + this.eventcode;
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
    
    openMobileSubMenu(event){
        event.stopPropagation();  
        this.openedMenuId = event.currentTarget.dataset.mobileMenuid;
        this.openedMenuIdMobile = event.currentTarget.dataset.mobileMenuid;
        
        const menuBodyId = event.currentTarget.dataset.menuBodyid;
        this.openMenuLabel = event.currentTarget.dataset.menuLabel;
        //alert(submenuId+','+menuBodyId+','+this.openMenuLabel);        
        let height = screen.height - 160;
        this.template.querySelector("div[data-menu-body-id="+menuBodyId+"]").style="height:"+height+"px";        
        let progress = 480;
        this._interval = setInterval(() => {  
            progress = progress - 100;              
            if ( progress <= 0 ) {  
                progress = 0;
                clearInterval(this._interval);      
            }
            this.template.querySelector("div[data-mobile-menu-id="+this.openedMenuId+"]").style = "display: block;transform-style: preserve-3d;-webkit-transform:translate3d("+progress+"px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);-moz-transform:translate3d("+progress+"px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);-ms-transform:translate3d("+progress+"px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);transform:translate3d("+progress+"px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);";
        }, 10);
    };

    closeMobileSubMenu(){  
        /* working good, don't remove comment before ticket assign*/        
        let progress = 0;
        this._interval = setInterval(() => {  
            progress = progress + 100;              
            if ( progress >= 480 ) {  
                progress = 480;
                clearInterval(this._interval);               
                this.template.querySelector("div[data-mobile-menu-id="+this.openedMenuIdMobile+"]").style = "display: none;transform-style: preserve-3d;-webkit-transform:translate3d("+progress+"px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);-moz-transform:translate3d("+progress+"px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);-ms-transform:translate3d("+progress+"px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);transform:translate3d("+progress+"px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);";
                this.openedMenuIdMobile = '';
            }
            this.template.querySelector("div[data-mobile-menu-id="+this.openedMenuIdMobile+"]").style = "transform-style: preserve-3d;-webkit-transform:translate3d("+progress+"px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);-moz-transform:translate3d("+progress+"px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);-ms-transform:translate3d("+progress+"px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);transform:translate3d("+progress+"px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);";
        }, 10);        
    };    
    
    openMegaMenu(event){
        //if solo menu item
        this.methodName='openMegaMenu';
        if(event.currentTarget.dataset.type.toLowerCase()==='solo'){
            let index = parseInt(event.currentTarget.dataset.index,10);
            if(index===0){
                this.redirect('Overview__c',{accId:this.accountId,edcode:this.eventcode});
            }
            return;
        }

        event.stopPropagation(); 
        if(this.openedMenuId!==event.currentTarget.dataset.menuId){
            this.closeMegaMenu();
        }
        else if(this.openedMenuId && this.openedMenuId!==''){
            this.closeMegaMenu();
            return false;
        }

        try{
            this.openedMenuId = event.currentTarget.dataset.menuId;
            event.currentTarget.parentElement.classList.add("hover");
            let progress = 0;
            this._interval = setInterval(() => {  
                progress = progress + 15;              
                if ( progress >= 294 ) {  
                    progress = 294;
                    clearInterval(this._interval);                    
                }
                this.template.querySelector("div[data-megamenu-id="+this.openedMenuId+"]").style = "display: block;transform: translate3d(0px, "+progress+"px, 0px) scale3d(1, 1, 1) rotateX(0deg) rotateY(0deg) rotateZ(0deg) skew(0deg, 0deg); transform-style: preserve-3d;";
            }, 15);
        }
        catch(e){
            console.error(e);
            handleUIErrors(this,error);
        }
    }

    closeMegaMenu(){
        this.methodName='closeMegaMenu';
        try{
            if(this.openedMenuId && this.openedMenuId!==''){
                this.template.querySelector("div[data-megamenu-id="+this.openedMenuId+"]").style = "display: none;transform: translate3d(0px, 0px, 0px) scale3d(1, 1, 1) rotateX(0deg) rotateY(0deg) rotateZ(0deg) skew(0deg, 0deg); transform-style: preserve-3d;";
                if(this.template.querySelector(".hover")){
                    this.template.querySelector(".hover").classList.remove("hover");
                }
                this.openedMenuId='';
            }
        }
        catch(e){
            console.error(e);
            handleUIErrors(this,error);
        }
    }

    redirect(pageName,paramObj){
        redirect(this,NavigationMixin.Navigate,pageName,paramObj);        
    };

    get isAdmin(){
        return this.userRole && (this.userRole=='Platform Admin' || this.userRole=='Secondary Admin')?true:false;
    }

    
}