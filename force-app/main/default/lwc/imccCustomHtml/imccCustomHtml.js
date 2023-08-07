import { LightningElement, track, wire } from 'lwc';
import getHtml from '@salesforce/apex/IMCC_HomeCtrl.getHtml';
import getTabId from '@salesforce/apex/IMCC_HomeCtrl.getTabId';
import {CurrentPageReference,NavigationMixin } from 'lightning/navigation';
import { handleErrors,handleUIErrors,showToast,gotoPage } from 'c/imcc_lwcUtility';
import { loadScript } from 'lightning/platformResourceLoader';
import jquery from '@salesforce/resourceUrl/Imcc_jquery';
import msg from '@salesforce/label/c.Error_Message_For_Feathr_Link';

export default class ImccCustomHtml extends NavigationMixin(LightningElement) {
    richtext;
    eventCode;
    accountId;
    @track spinner;

    @track methodName;
    className='imccCustomHtml';
    comp_type='LWC';
    
    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        this.methodName = 'getHtml';
        if (currentPageReference) {
            let tabId = currentPageReference.state.tabId;
            this.eventCode = currentPageReference.state.edcode;
            this.accountId = currentPageReference.state.accId;
            
            //Load jquery
            loadScript(this, jquery)
            .then(()=>{                
                getHtml({tabCode: tabId})
                .then(result => { 
                    //get tab id to replace link by community page
                    this.getTabIds(result);
                })
                .catch(error => {
                    handleUIErrors(this,error);                
                });
            })
            .catch(error => {
                showToast(this, error, 'error', 'Error');
            })            
        }
    };

    handleClick(event){
        console.log('click');
    }

    getTabIds(data){
        this.methodName = 'getTabIds';
        getTabId({edcode:this.eventCode,accountId:this.accountId})
        .then(res=>{
            const tabIds = res.tab;
            const cem = res.cem;

            tabIds.forEach(item=>{
                let url = this.getPageUrlByType(item.Tab_Type__c,item.Standard_Tab_Type__c);                
                data = data.replaceAll('"tabId='+item.ExtTabId__c+'"', '"'+url+'?edcode='+this.eventCode+'&tabId='+item.Tab_Code__c+'&accId='+this.accountId+'" data-tabid="'+item.Tab_Code__c+'" data-tabtype="'+item.Tab_Type__c+'" data-stdtabtype="'+item.Standard_Tab_Type__c+'"');
            });
            //replace missing link with home page
            data = data.replaceAll('"tabId=','"/IMCC/s/?edcode='+this.eventCode+'&accId='+this.accountId+'" data-tabid="home"');
            
            //replace feathr link
            if(cem.length>0){
                cem[0].Feathr_Unique_Link__c = cem[0].Feathr_Unique_Link__c?cem[0].Feathr_Unique_Link__c:'#';
                data = data.replaceAll('href="feathr-link"','href="'+cem[0].Feathr_Unique_Link__c+'"');
            }
            //this.richtext = data;            
            this.template.querySelector('.informa-html').classList.add('slds-hide');
            this.template.querySelector('.informa-html').innerHTML = data;
            let self = this;
            this.spinner = true;
            setTimeout(()=>{
                self.template.querySelector('.informa-html').classList.remove('slds-hide');
                self.spinner = false;
            },5000);

            if(window.jQuery){
            window.jQuery(".feathr-link").click(function (event){
                event.preventDefault();
                if($(this).attr('href')!='#'){
                    window.open($(this).attr('href'),'_blank');
                }                
                else{                    
                    showToast(self,msg,'error','Error');
                }
            });

            window.jQuery('a[href*="/IMCC/s"]').click(function (event){
                event.preventDefault();
                let tabId = $(this).data('tabid');
                let tabType = $(this).data('tabtype');
                let stdtabtype = $(this).data('stdtabtype');
                if($(this).data('tabid')=='home'){                    
                    redirect(self,NavigationMixin.Navigate,'Home',{"accId":self.accountId,"edcode":self.eventCode}); 
                }
                else{                    
                    gotoPage(self,NavigationMixin.Navigate,{"tabType":tabType,"stdtabtype":stdtabtype,"accId":self.accountId,"edcode":self.eventCode,"tabId":tabId});
                }
            });            
            }           
        })
        .catch(error=>{
            handleUIErrors(this,error);
        });
    }



    getPageUrlByType(tabType,stndrdTabType){
        let urlStr = '';
        if (tabType == 'Custom') {
            if(stndrdTabType == 'HTML'){                
                urlStr ='/IMCC/s/custom-html';                
            }
            else{
                urlStr ='/IMCC/s/custompages';
            }
        }
        if (tabType == 'Standard') {
            if(stndrdTabType == 'Floorplan'){            
                urlStr ='/IMCC/s/floorplan';
            }
            if(stndrdTabType == 'FAQ'){
                urlStr ='/IMCC/s/faqs';
            }
            if(stndrdTabType == 'Forms'){
                urlStr ='/IMCC/s/forms';                               
            }
            if(stndrdTabType == 'Manuals'){
                urlStr ='/IMCC/s/manuals';
            }
            if(stndrdTabType == 'Badges'){
                urlStr ='/IMCC/s/badges';
            }
            if(stndrdTabType == 'Stand Contractors'){
                urlStr ='/IMCC/s/stand-contractors';
            }
            if(stndrdTabType == 'Stand Design'){
                urlStr ='/IMCC/s/stand-design';
            }
            if(stndrdTabType == 'Lead Retrieval'){                
                urlStr ='/IMCC/s/lead-retrieval';
            }
            if(stndrdTabType == 'Virtual Event'){
                urlStr ='/IMCC/s/virtual-event';
            }
            if(stndrdTabType == 'Badge Registration'){
                urlStr ='/IMCC/s/badge-registration';
            }
        }
        return urlStr;
    };    
}