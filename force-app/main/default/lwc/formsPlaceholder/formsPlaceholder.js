import { LightningElement,api } from 'lwc';

export default class FormsPlaceholder extends LightningElement 
{
    @api isShow = false;

    get className()
    {
        let clname = 'slds-hide forceListViewPlaceholder';
        if(this.isShow){
            clname = 'forceListViewPlaceholder';
        }
        return clname;
    }
}