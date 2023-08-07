import { api, LightningElement, track, wire } from 'lwc';
import fetchStandDetails from "@salesforce/apex/IMCC_GreetingPopup.fetchStandDetails";
import getPurchaseSummary from '@salesforce/apex/IMCC_HomeCtrl.getPurchaseSummary';
import updatePurchaseSummary from '@salesforce/apex/IMCC_HomeCtrl.updatePurchaseSummary';
import {CurrentPageReference,NavigationMixin } from 'lightning/navigation';
import { handleUIErrors, redirect,showToast,gotoPage } from 'c/imcc_lwcUtility';
import {refreshApex} from '@salesforce/apex';
import expocadBaseUrl from '@salesforce/label/c.Expocad_Base_Url';
//import standSummaryInfo from '@salesforce/label/c.Stand_Summary_Quick_Info';

export default class ImccPurchaseSummary extends NavigationMixin(LightningElement) {
    @api userDtls;

    @track eventcode;
    @track accountId;
    @track boothDtlSize;
    @track boothDtls;
    @track openStandSummaryModal=false;
    @track purchaseSummaryList; //except stand type
    @track isShowStandSummary; 
    @track isOpenConfirmation;
    @track completedStatus;
    @track conEdMapId;
    @track contactId;

    @track standSummaryHeader;
    @track standSummaryInfo;

    @track methodName;
    className='imccPurchaseSummary';
    comp_type='LWC';

    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        this.boothDtlSize = 0;
        if (currentPageReference && currentPageReference.type == "comm__namedPage" && currentPageReference.attributes.name == "Overview__c") {
            this.refreshEventSummary = true;
            this.eventcode = currentPageReference.state.edcode;
            this.accountId = currentPageReference.state.accId;
            if(this.eventcode){
                this.fetchStandDetails(this.eventcode, this.accountId);
            }
        }
    };

    fetchStandDetails(eventcode,accountId) {
        this.methodName = 'fetchStandDetails';
        fetchStandDetails({ eventCode: eventcode,accountId: accountId })
        .then(result => {
            let expocadEventCode;
                if(result.expocadEventCode){
                    expocadEventCode = result.expocadEventCode;
                }
            let data = result.purchaseDtls;
            let boothDataLst = [];
            if (data) {
                data.forEach((row) => {
                    let boothDetailLst = {};
                    boothDetailLst.ExhibitorName =  (row.Exhibiting_Name__c == null || row.Exhibiting_Name__c == '')?row.Account__r.Name:row.Exhibiting_Name__c;
                    boothDetailLst.BoothNumber = row.Booth_Number__c;
                    boothDetailLst.BoothType = row.Booth_Product_Type__c;
                    boothDetailLst.BoothSize = row.Quantity_Area__c;
                    boothDetailLst.UnitMeasurement = row.Unit_of_Measurement__c;
                    boothDetailLst.ViewBoothLink = expocadBaseUrl + expocadEventCode + '/exfx.html?zoomto=' + row.Booth_Number__c;

                    boothDataLst.push(boothDetailLst);

                });
                this.boothDtls = boothDataLst;
                this.boothDtlSize = boothDataLst.length;
                //console.log('Booth length' + this.boothDtlSize);
                //console.log('Booth Data 1' + this.boothDtls);                
            }   
            this.fetchPurchaseSummary();
        })
        .catch(error => {
            window.console.error('error...3435' + JSON.stringify(error));
            handleUIErrors(this,error); 
        });
    };

    @track onlineBadges;
    fetchPurchaseSummary(){  
        this.methodName = 'fetchPurchaseSummary';      
        getPurchaseSummary({eventCode:this.eventcode,accountId:this.accountId})
        .then(res=>{
            this.onlineBadges = 0;
            let mediaBasePath = '/IMCC/sfc/servlet.shepherd/document/download/';
            const purchaseSummary = JSON.parse(JSON.stringify(res.ps));
            const conEdMap = JSON.parse(JSON.stringify(res.cem));
            if(conEdMap){
                this.conEdMapId = conEdMap.Id;
                this.contactId = conEdMap.Contact__c;
            }
            const videos = JSON.parse(JSON.stringify(res.media));
            let badges = JSON.parse(JSON.stringify(res.badges));
            let leadRetrieval = res.lr;
            const fb = [];
            let isAllOnlineUnlimited = true;
            badges.forEach(item=>{
                if(item.Booth_Number__c){
                    item.Booth_Number__c = 'Stand '+item.Booth_Number__c;
                    fb.push(item);    
                }
                else{
                    item.isOnline = true;
                    this.onlineBadges += item.Total_Badges__c?item.Total_Badges__c:0; 
                    if(!item.Unlimited_Badges__c){
                        isAllOnlineUnlimited = false;
                    }
                }                
            });
            if(this.onlineBadges>0){
                fb.push({isOnline:true,Booth_Number__c:'Online',Total_Badges__c:this.onlineBadges,Unlimited_Badges__c:isAllOnlineUnlimited});
            }
            badges = fb;
            
            const virtualEvents = res.ve;
            this.completedStatus = res.cem.Completed_Purchase_Summaries__c?res.cem.Completed_Purchase_Summaries__c:'';
            this.completedStatus = this.completedStatus + ";" + (res.pcem!=null?res.pcem.Completed_Purchase_Summaries__c:'');
            purchaseSummary.forEach((item,index)=>{                
                item.key = item.Id+'_'+index;                
                item.badges = [];
                item.virtualEvents = [];
                if(item.Purchase_Summary_Type__c==='Stand'){
                    item.Name = item.Name+ '('+this.boothDtlSize+')';
                    item.isStand = true;
                    this.standSummaryHeader = item.Standard_Header_Text__c;
                    this.standSummaryInfo = item.Standard_Sub_Header_Text__c;
                    item.className="link link-d-small-medium link-m-small-medium";
                    if(this.boothDtlSize===0 || !item.Is_Active__c){
                        item.className = item.className + " disabled";
                    }
                }
                else if(item.Purchase_Summary_Type__c==='Badge'){                
                    item.Name = item.Name + '('+badges.length+')';
                    item.badges = badges;
                    item.isBadge = true;
                    item.internalLink = 'Learn more about your Registrations';
                    item.className="link link-d-small-medium link-m-small-medium";
                    if(badges.length===0 || !item.Is_Active__c){
                        item.className = item.className + " disabled";
                    }
                }
                else if(item.Purchase_Summary_Type__c==='Lead Retrieval'){
                    item.isLeadRetrieval = true;
                    item.Name = item.Name + '('+leadRetrieval.length+')';                    
                    item.lr = leadRetrieval;
                    item.internalLink = 'Learn more about your Lead Retrieval';
                    item.className="link link-d-small-medium link-m-small-medium";
                    if(leadRetrieval.length==0 || !item.Is_Active__c){
                        item.className = item.className + " disabled";
                    }
                }
                else if(item.Purchase_Summary_Type__c==='Virtual Event'){
                    item.isVirtualEvent = true;
                    item.Name = item.Name + '('+virtualEvents.length+')';
                    item.virtualEvents = virtualEvents;
                    item.internalLink = 'Learn more about Your Virtual Event';
                    item.className="link link-d-small-medium link-m-small-medium";
                    if(virtualEvents.length===0 || !item.Is_Active__c){
                        item.className = item.className + " disabled";
                    }
                }
                //set internal link empty if tab not defind on purchase summary
                if(!item.Event_Tab__c){
                    item.internalLink='';
                }

                item.video = videos.filter(i=>i.LinkedEntityId===item.Id);
                item.media = item.video && item.video.length>0?item.video[0]:undefined;
                item.mediaURL = item.media?mediaBasePath+item.media.ContentDocumentId:'';
            });
            //console.log(JSON.stringify(purchaseSummary));
            this.purchaseSummaryList = purchaseSummary;
        })
        .catch(error=>{
            handleUIErrors(this,error);
        });
    };
    
    openInernalPage(){
        console.log("Deepak===",JSON.stringify(this.selectedPurchaseData.Event_Tab__r));
        const eventTabs = this.selectedPurchaseData.Event_Tab__r;
        let tabType = eventTabs.Tab_Type__c;
        let stndrdTabType = eventTabs.Standard_Tab_Type__c;
        let tabName = eventTabs.Tab_Code__c;        
        gotoPage(this,NavigationMixin.Navigate,{"tabType":tabType,"stdtabtype":stndrdTabType,"accId":this.accountId,"edcode":this.eventcode,"tabId":tabName});                
    };

    @track selectedPurchaseData;
    @track openGenricModal;
    openGenericModal(event){
        let index = parseInt(event.currentTarget.dataset.index,10);
        const item = this.purchaseSummaryList[index];
        
        this.selectedPurchaseData = item;
        this.selectedPurchaseData.isCompleted = false;
        if(this.completedStatus.indexOf(this.selectedPurchaseData.Purchase_Summary_Type__c)>=0 && this.selectedPurchaseData.Is_Active__c){
            this.selectedPurchaseData.isCompleted = true;
        }

        if((item.Purchase_Summary_Type__c==='Stand' || item.Purchase_Summary_Type__c==='stand') && this.boothDtlSize>0 && this.selectedPurchaseData.Is_Active__c){            
            this.openStandSummaryModal = true;
        }
        else if((item.Purchase_Summary_Type__c==='Badge' || item.Purchase_Summary_Type__c==='badge') && item.badges.length>0 && this.selectedPurchaseData.Is_Active__c){
            this.openGenricModal = true;
        }
        else if((item.Purchase_Summary_Type__c==='Lead Retrieval' || item.Purchase_Summary_Type__c==='lead retrieval') && item.lr.length>0 && this.selectedPurchaseData.Is_Active__c){
            this.openGenricModal = true;
        }
        else if((item.Purchase_Summary_Type__c==='Virtual Event' || item.Purchase_Summary_Type__c==='virtual event') && item.virtualEvents.length>0 && this.selectedPurchaseData.Is_Active__c){
            this.openGenricModal = true;
        }
    };
    
    yesComplete(){
        this.methodName = 'yesComplete'; 
        updatePurchaseSummary({type:this.selectedPurchaseData.Purchase_Summary_Type__c,cemId: this.userDtls.Id})
        .then(res=>{
            this.completedStatus = res;
            this.selectedPurchaseData.isCompleted = true;
            console.log('completed');
            this.isOpenConfirmation = false;
            this.dispatchEvent(new CustomEvent('reloadtask'));
            showToast(this,'Task has been completed.','success','Success');
            refreshApex(this.purchaseSummaryList);
        })  
        .catch(error=>{
            handleUIErrors(this,error);
        });
    };

    noClose(){
        try{
            //this.template.querySelector("input[name='is-completed']").checked = false;
            this.selectedPurchaseData.isCompleted = false;
            this.isOpenConfirmation = false;        
        }
        catch(e){
            console.error(e);
        }
    };

    makeTaskAsComplete(event){
        if(event.target.checked){
            this.selectedPurchaseData.isCompleted = true;
            this.isOpenConfirmation = true;
        }
    };

    handleButtonClick(){
        window.open(this.makeSecureUrl(this.selectedPurchaseData.External_Link__c),'_blank');
    };

    makeSecureUrl(url) {
        let finalUrl;
        if (!url.includes("http:") && !url.includes("https:")) {
            finalUrl = "https://" + url + '?accId=' + this.accountId + '&edcode=' + this.eventcode + '&conId=' + this.contactId + '&ceid=' + this.conEdMapId;
        } else {
            finalUrl = url + '?accId=' + this.accountId + '&edcode=' + this.eventcode + '&conId=' + this.contactId + '&ceid=' + this.conEdMapId;
        }
        return finalUrl;
    }

    cancelModal(){
        this.selectedPurchaseData = false;
        this.openStandSummaryModal = false;
        this.isOpenConfirmation = false;
        this.openGenricModal = false;
    }; 
    
    redirect(pageName,paramObj){
        redirect(this,NavigationMixin.Navigate,pageName,paramObj);        
    };

    get isShowOnlineBadge(){
        return this.onlineBadges>0;
    }
}