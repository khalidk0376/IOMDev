import { LightningElement } from 'lwc';
import getAllowIOMCallout from '@salesforce/apex/IOM_ConnectionCallbackCtrl.isReadyForIOMCallout';
import fetchURL from '@salesforce/apex/IOM_ConnectionCallbackCtrl.getAuthenticationURL';

export default class Iom_Configuration extends LightningElement 
{
    outhURL;
    hasIOMFolder;

    connectedCallback()
    {
        this.hasIOMFolder = false;
        this.checkHasIomFolder();
    }
    
    getOuthURL()
    {
        fetchURL()
            .then(data => {
                console.log('fetchURL .. '+data);
                if(data)
                {
                    this.outhURL = data;
                    // console.log('outhURL - ',this.outhURL);
                }
            })
            .catch(error2 => {
                this.isAllowCallout = false;
            });
    }

    checkHasIomFolder()
    {
        getAllowIOMCallout()
            .then(data => {
                console.log('getAllowIOMCallout .. '+data);
                this.hasIOMFolder = data;
                this.getOuthURL();
            })
            .catch(error2 => {
                this.isAllowCallout = false;
            });
    }
       
    getToken()
    {        
        window.open(this.outhURL,'_top');
    }
}