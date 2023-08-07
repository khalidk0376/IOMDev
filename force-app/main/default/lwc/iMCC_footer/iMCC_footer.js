import { LightningElement, track, wire,api } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import fecthEvent from "@salesforce/apex/IMCC_AccountSelectionCtrl.getEditionDetails";

import POLICY_TEXT from '@salesforce/label/c.Privacy_Policy_Text';
import POLICY_LINK from '@salesforce/label/c.Privacy_Policy_Link';
import communityURL from '@salesforce/label/c.CommunityURL';
import {handleUIErrors } from 'c/imcc_lwcUtility';

export default class IMCC_footer extends LightningElement {
    @track eventDtls;
    @track edWebsiteDtls = [];
    @track eventCode;
    accountId;
    @track methodName;

    className ='iMCC_footer';
    comp_type ='LWC';
    
    @track privacyPolicyText = POLICY_TEXT;
    @track privacyPolicyLink = POLICY_LINK;

    @track showTimingLiveValues;
    @track showTimingOnlineValues;

    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        this.showTimingLiveValues = [];
        this.showTimingOnlineValues = [];
        if(currentPageReference){
            if(this.eventCode != null && this.eventCode != ''){
                if(this.eventCode != currentPageReference.state.edcode){
                    this.template.querySelectorAll(".chatWindowFrame")[0].src = this.template.querySelectorAll(".chatWindowFrame")[0].src;
                }
            }
            this.eventCode = currentPageReference.state.edcode;
            this.accountId = currentPageReference.state.accId;
            if(this.eventCode){
                this.fetchEditionDetails(this.eventCode);
            }
        }
    };

    connectedCallback() { // invoke the method when component rendered or loaded                    
        window.addEventListener( "message", this.handleVFResponse.bind(this), false );    
    };

    handleVFResponse(message){
        // check the origin match for both source and target
        //if (message.origin === "https://servcloud-globalexhibitions.cs24.force.com") { 
        if (message.origin === communityURL){
            console.log(message.data);
            if(message.data == "afterMaximize"){
                this.template.querySelectorAll(".chatWindowFrame")[0].height = "500px";
                this.template.querySelectorAll(".chatWindowFrame")[0].width = "300px";
            }
            if(message.data == "onSettingsCallCompleted" || message.data == "afterMinimize"  || message.data == "afterDestroy" ){
                this.template.querySelectorAll(".chatWindowFrame")[0].height = "50px";
                this.template.querySelectorAll(".chatWindowFrame")[0].width = "205px";
            }
            if(message.data == "reloadFrame"){
                this.template.querySelectorAll(".chatWindowFrame")[0].src = this.template.querySelectorAll(".chatWindowFrame")[0].src;
            }
        }
    };

    fetchEditionDetails(eventCode){
        this.methodName='fetchEditionDetails';
        console.log('--eventCode ',eventCode);
        fecthEvent({eventcode : eventCode})
        .then(result => {
            this.eventDtls = result.event;
            const data = result.editionWeb;
           
            console.log('--result ',result);
            if (result.showTimingLiveLst) {
                console.log('--result.showTimingLiveLst ',result.showTimingLiveLst);
                this.showTimingLiveValues = result.showTimingLiveLst;
            }
            if (result.showTimingOnlineLst) {
                this.showTimingOnlineValues = result.showTimingOnlineLst;                
            }
            if(data != null && data != undefined){
                data.forEach(item => {
                    if(item.Website_Link__c && item.Website_Link__c.indexOf('http')<0){
                        item.Website_Link__c = 'https://'+item.Website_Link__c;
                    }
                });
            }
            this.edWebsiteDtls = data;
        })
        .catch(error => {
            window.console.log('error...' + JSON.stringify(error));
            handleUIErrors(this,error);  
        });   
    };
    
    get isLinksVisible() {
        if (this.edWebsiteDtls) {
            return true;
        }
        return false;
    };

    get isShowhrsVisible() {
        if (this.eventDtls && this.eventDtls.Show_Hours__c) {
            return true;
        }
        return false;
    };

    get isFollowVisible()
    {
        if ((this.eventDtls) && (this.eventDtls.FaceBook__c || this.eventDtls.Twitter__c || this.eventDtls.LinkedIn__c || this.eventDtls.YouTube__c)) {
            return true;
        }
        return false;
    };

    get isLive(){
        return this.showTimingLiveValues && this.showTimingLiveValues.length>0?true:false;
    }

    get isOnline(){
        return this.showTimingOnlineValues && this.showTimingOnlineValues.length>0?true:false;
    }

    get homePageLink(){
        return '/IMCC/s?edcode='+this.eventCode+'&accId='+this.accountId;
    }
}