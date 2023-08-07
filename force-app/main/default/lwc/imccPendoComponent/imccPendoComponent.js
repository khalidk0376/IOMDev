import { LightningElement, track } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import pendoJs from '@salesforce/resourceUrl/Pendo';
import getMetaData from "@salesforce/apex/IMCC_PendoAgentController.getMetadata";
import { handleUIErrors } from 'c/imcc_lwcUtility';
import IMCCLoadPendo from '@salesforce/label/c.IMCC_Load_Pendo';

export default class ImccPendoComponent extends LightningElement {

    @track isPendoInitialized = false;
    @track methodName;
    className = 'imccPendoComponent';
    comp_type = 'LWC';

    connectedCallback() {
        console.log("IMCCLoadPendo===",IMCCLoadPendo);
        if(IMCCLoadPendo == 'true'){
            /*Promise.all([
                loadScript(this, pendoJs),
            ]).then(() => {
                this.doInit();
            });*/
        }
    }

    doInit() {
        this.methodName = 'doInit';
        console.log('pendo doInit 1: ', this.isPendoInitialized);
        console.log('pendo doInit 2: ', window.pendo);
        if (!this.isPendoInitialized && window.pendo) {
            getMetaData()
                .then(result => {
                    console.log('RESULT#### ' + JSON.stringify(result));
                    console.log('visitor#### ' + JSON.stringify(result.visitor));
                    console.log('account#### ' + JSON.stringify(result.account));
                    window.pendo.initialize({
                        visitor: result.visitor,
                        account: result.account
                    })
                    this.isPendoInitialized = true;
                })
                .catch(error => {
                    console.log('ERROR');
                    //handleUIErrors(this, error);
                });
        }
    }
}