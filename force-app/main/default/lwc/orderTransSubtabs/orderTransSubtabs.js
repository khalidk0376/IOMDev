import { LightningElement } from 'lwc';

export default class OrderTransSubtabs extends LightningElement {

    /**
     * description : This method is used to refresh table once the tab is changed.
     */
    handleTabClick(event){
        if(event.target.label==='Completed Orders'){            
            if(this.template.querySelector('c-completed-orders-dashboard')!==null){
                this.template.querySelector('c-completed-orders-dashboard').refreshTableOnTabChange();
            }
        }
    }
    
}