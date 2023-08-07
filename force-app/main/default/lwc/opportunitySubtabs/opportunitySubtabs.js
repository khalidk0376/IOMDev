import { LightningElement } from 'lwc';

export default class OpportunitySubtabs extends LightningElement {

    /**
     * description : This method is used to refresh table once the tab is changed.
     */
    handleTabClick(event){
        if(event.target.label==='Approved Contracts'){            
            if(this.template.querySelector('c-approved-contract-dashboard')!==null){
                this.template.querySelector('c-approved-contract-dashboard').refreshTableOnTabChange();
            }
        }
        if(event.target.label==='Rejected Contracts'){
            if(this.template.querySelector('c-rejected-contract-dashboard')!==null){
                this.template.querySelector('c-rejected-contract-dashboard').refreshTableOnTabChange();
            }
        }
        if(event.target.label==='No Order Flagged Option'){
            if(this.template.querySelector('c-no-Order-Flagged-Dashboard')!==null){
                this.template.querySelector('c-no-Order-Flagged-Dashboard').refreshTableOnTabChange();
            }
        }
    }
    
}