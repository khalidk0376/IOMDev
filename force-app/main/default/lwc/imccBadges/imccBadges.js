import { LightningElement, track, wire } from 'lwc';
import { CurrentPageReference,NavigationMixin } from 'lightning/navigation';
import getDatas from "@salesforce/apex/IMCC_BadgeCtrl.getDatas";
import getDatas2 from "@salesforce/apex/IMCC_BadgeCtrl.getDatas2";
import { handleErrors,redirect } from 'c/imcc_lwcUtility';
import getTabContext from '@salesforce/apex/IMCC_HomeCtrl.getTabContext';

export default class ImccBadges extends NavigationMixin(LightningElement) {
    
    dueDate;
    showDueDate;
    @track editionCode;
    @track accountId;
    @track tabId;
    @track purchaseDataList;
    @track badges;
    @track selectedBooth;
    @track buttonStatus;
    unfilteredBadges;

    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        this.selectedBooth = '';
        this.disabledBtn();
        if (currentPageReference) {
            this.editionCode = currentPageReference.state.edcode;
            this.accountId = currentPageReference.state.accId;
            this.tabId = currentPageReference.state.tabId;            
            this.doInit();
        }
    }

    doInit(){
        if(this.accountId && this.editionCode){
            //this.loadData();
            this.loadBadgeData();
        } 
    }

    loadData(){
        getDatas({accountId:this.accountId,editionCode:this.editionCode})
        .then(res=>{
            const data = JSON.parse(JSON.stringify(res));
            
            let options = [{label:"All Booths",value:""}];
            data.purchaseData.forEach(item=>{        
                
                item.Total_Badges__c = item.Total_Badges__c?item.Total_Badges__c:0;
                item.Addition_Badge_Count__c = item.Addition_Badge_Count__c?item.Addition_Badge_Count__c:0;
                item.Badge_Allocated__c = item.Badge_Allocated__c?item.Badge_Allocated__c:0;
                item.Submitted_Badge__c = item.Submitted_Badge__c?item.Submitted_Badge__c:0;
                item.Remaining_Badges__c = item.Remaining_Badges__c?item.Remaining_Badges__c:item.Total_Badges__c;
                options.push({label:item.Booth_Number__c+' - '+item.Booth_Product_Type__c,value:item.Id});
            });
            this.badges = data.purchaseData;
            this.purchaseDataList = options;
            //console.log()
        })
        .catch(error=>{
            handleErrors(this, error);
        });
    }
    
    loadBadgeData(){
        getDatas2({accountId:this.accountId,editionCode:this.editionCode})
        .then(res=>{
            const data = res;
            console.log('data===='+JSON.stringify(data));
            let options = [{label:"All Booths",value:""}];
            data.forEach(item=>{        
                this.dueDate = item.dueDate;
                this.showDueDate = item.showDueDate;
                item.badgeDataId = item.badgeDataId;
                item.firstName = item.firstName;
                item.lastName = item.lastName;
                item.email = item.email;
                item.jobTitle = item.jobTitle;
                item.country = item.country;
                item.standNo = item.standNo;
                item.status = item.status;
                item.boothProduct = item.boothProduct;
                options.push({label:item.standNo,value:item.standNo});
                
            });
            let result = options.reduce((unique, o) => {
                if(!unique.some(obj => obj.label === o.label && obj.value === o.value)) {
                  unique.push(o);
                }
                return unique;
            },[]);
            this.unfilteredBadges = data;
            this.badges = data;
            this.purchaseDataList = result;
            //console.log()
        })
        .catch(error=>{
            handleErrors(this, error);
        });
    }

    handleBoothChange(event){
        this.selectedBooth = event.target.value;
        let badges = [];
        if(this.selectedBooth == ""){
              this.badges = this.unfilteredBadges;
        }
        else{
            this.unfilteredBadges.forEach(item=>{ 
                if(item.standNo == this.selectedBooth){
                    badges.push(item);
                }
               })
               this.badges = badges;
        }
        
        this.disabledBtn();
    }

    disabledBtn(){
        let disable = false;
        if(this.selectedBooth == undefined || this.selectedBooth==''){
            disable = true;    
        }
        else{
            disable = false;
            this.badges.forEach(item=>{
                if(item.Id == this.selectedBooth && item.Remaining_Badges__c<=0){
                    disable = true;
                }
            });
        }
        console.log('Test: '+disable);
        this.buttonStatus = disable;
    }

    redirect(pageName,paramObj){
        redirect(this,NavigationMixin.Navigate,pageName,paramObj);        
    };
}