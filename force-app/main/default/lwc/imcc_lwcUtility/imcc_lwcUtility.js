/* eslint-disable no-console */
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import logUIException from '@salesforce/apex/HandleAllCustomException.logUIException';

import UI_Msg from '@salesforce/label/c.IMCC_Custom_UI_Error_Message';
/**
 * Handle error that is thrown by Apex action and show Error in toast(ShowToastEvent)
 * 
 * @param that pass this object of lwc component
 * @param error pass error object return by apex AuraEnabled action  
 */
const handleErrors = (that,error)=>{
    console.error(JSON.stringify(error));
    let message = 'Unknown Error';
    let title = 'Error';
    if (error) {

        if (error.body!==undefined && Array.isArray(error.body)) {
            message = error.body.map(e => e.message).join(', ');
        } 
        else if (error.body!==undefined && typeof error.body.message === 'string') {
            message = error.body.message;
        }
        else if(error.detail!==undefined && error.detail!==''){
            message = error.detail;
        }
        else if(error.message!==undefined && error.message!==''){
            message = error.message;
        }
        else if(error.body && error.body.pageErrors){
            message = error.body.pageErrors[0].message;
            title = error.body.pageErrors[0].statusCode;
        }
    }    
    return that.dispatchEvent(new ShowToastEvent({
        variant:'error',
        title:title,
        mode:'sticky',
        message : message
    }));        
}


const handleAuraErrors = (comp_name,method_name,error)=>{
   
    
    let message = 'Unknown Aura Error';
    message = error[0].message;    

        let mesgstr,stacktracestr;
        if(message.indexOf('Message=')!=-1) {
   
            mesgstr = message.substring(8,message.lastIndexOf('Stacktrace='));                 
            stacktracestr = message.substring(message.lastIndexOf('Stacktrace=')+11,message.length);

        } else {
            mesgstr=message;
            stacktracestr='';
        }

        console.log('Message'+mesgstr+'Stacktrace'+stacktracestr);
        if(mesgstr != 'Disconnected or Canceled' && mesgstr != 'The requested resource does not exist' && mesgstr != 'Unknown Error' && mesgstr != 'Communication error, please retry or reload the page'){
            logUIException({comp_type:'Aura',className:comp_name,methodName:method_name,currcdId:null,mesg:mesgstr,stackTrace:stacktracestr}).then()
         .catch(error =>{
          console.error('could not write to custom error log'+JSON.stringify(error));         
         });
        }   
    
    return true;   

}
/**
 * Handle error that is thrown by UI and show Error in toast(ShowToastEvent)
 * 
 * @param that pass this object of lwc component
 * @param error pass error object return by apex AuraEnabled action  
 */
const handleUIErrors = (that,error)=>{
    console.error(JSON.stringify(error));


    let message = 'Unknown Error';
    let title = 'Error';
    if (error) {

        if (error.body!==undefined && typeof error.body.message === 'string') {
            message = error.body.message;
        } else if (error.body!==undefined && Array.isArray(error.body)) {
            message = error.body.map(e => e.message).join(', ');
        }         
        else if(error.detail!==undefined && error.detail!==''){
            message = error.detail;
        }
        else if(error.message!==undefined && error.message!==''){
            message = error.message;
        }
        else if(error.body && error.body.pageErrors){
            message = error.body.pageErrors[0].message;
            title = error.body.pageErrors[0].statusCode;
        }
    }  
        let mesgstr,stacktracestr;
        if(message.indexOf('Message=')!=-1) {
   
            mesgstr = message.substring(8,message.lastIndexOf('Stacktrace='));              
            stacktracestr = message.substring(message.lastIndexOf('Stacktrace=')+11,message.length);
        } else {

            mesgstr=message;
            stacktracestr='';

        }

        console.log('comp_type',that.comp_type);
        console.log('className',that.className);
        console.log('methodName',that.methodName);
        console.log('stacktracestr',stacktracestr);
        console.log('mesg',mesgstr);

        let recId = that.recordId == undefined?null:that.recordId;
        console.log('currcdId',recId);
        if(mesgstr != 'Disconnected or Canceled' && mesgstr != 'The requested resource does not exist' && mesgstr != 'Unknown Error' && mesgstr != 'Communication error, please retry or reload the page'){
        logUIException({comp_type:that.comp_type,className:that.className,methodName:that.methodName,currcdId:recId,mesg:mesgstr,stackTrace:stacktracestr
        })
        .then()
        .catch(error =>{
            console.error('could not write to custom error log'+JSON.stringify(error));
        });
        }

      
    
    return that.dispatchEvent(new ShowToastEvent({
        variant:'error',
        title:title,
        mode:'sticky',
        message : UI_Msg
    }));        
}

/**
 * Show toast message in Lightning Experience and Lightning community only.
 * 
 * @param that pass this object of lwc component
 * @param message pass message text body 
 * @param type toast type
 * @param title toast title
 */
const showToast = (that,message,type,title)=>{    
    return that.dispatchEvent(new ShowToastEvent({
        variant:type,
        title:title,        
        message : message
    }));    
};

const redirect = (that,nav,pageName,paramObj)=>{
    that[nav]({        
        type:'comm__namedPage',        
        attributes: {            
            name:pageName        
        },
        state: paramObj
    });
};


const gotoPage = (self,nav,data)=>{    
    if (data.tabType == 'Custom') {
        if(data.stdtabtype == 'HTML'){
            window.location.href='/IMCC/s/custom-html?accId='+data.accId+'&edcode='+data.edcode+'&tabId='+data.tabId;                
        }
        else{
            redirect(self,nav,'custompages__c',{"accId":data.accId,"edcode":data.edcode,"tabId":data.tabId});
        }
    }
    if (data.tabType == 'Standard') {
        if(data.stdtabtype == 'Floorplan'){            
            redirect(self,nav,'floorplan__c',{"accId":data.accId,"edcode":data.edcode,"tabId":data.tabId});
        }
        if(data.stdtabtype == 'FAQ'){
            redirect(self,nav,'faqs__c',{"accId":data.accId,"edcode":data.edcode,"tabId":data.tabId});                
        }
        if(data.stdtabtype == 'Forms'){
            redirect(self,nav,'forms__c',{"accId":data.accId,"edcode":data.edcode,"tabId":data.tabId});                                         
        }
        if(data.stdtabtype == 'Manuals'){
            redirect(self,nav,'manuals__c',{"accId":data.accId,"edcode":data.edcode,"tabId":data.tabId});                
        }
        if(data.stdtabtype == 'Badges'){
            redirect(self,nav,'Badges__c',{"accId":data.accId,"edcode":data.edcode,"tabId":data.tabId});                
        }
        if(data.stdtabtype == 'Stand Contractors'){
            redirect(self,nav,'StandContractors__c',{"accId":data.accId,"edcode":data.edcode,"tabId":data.tabId});                
        }
        if(data.stdtabtype == 'Stand Design'){
            redirect(self,nav,'StandDesign__c',{"accId":data.accId,"edcode":data.edcode,"tabId":data.tabId});                
        }
        if(data.stdtabtype == 'Lead Retrieval'){                
            redirect(self,nav,'leadRetrieval__c',{"accId":data.accId,"edcode":data.edcode,"tabId":data.tabId});                             
        }
        if(data.stdtabtype == 'Virtual Event'){                
            redirect(self,nav,'VirtualEvent__c',{"accId":data.accId,"edcode":data.edcode,"tabId":data.tabId});                             
        }
        if(data.stdtabtype == 'Badge Registration'){
            redirect(self,nav,'badgeRegistration__c',{"accId":data.accId,"edcode":data.edcode,"tabId":data.tabId});                
        }
        if(data.stdtabtype == 'Manage Team'){
            redirect(self,nav,'TeamsManager__c',{"accId":data.accId,"edcode":data.edcode,"tabId":data.tabId});                
        }
    }
};

const isFieldLocked = (currentStatus)=>{
    currentStatus = ','+currentStatus.toLowerCase()+',';
    let lockStatus = ',in review,pending sales approval,stand design resubmitted,pending venue approval,tentative approval,permission to build,';
    return lockStatus.indexOf(currentStatus)>=0?true:false;
};

const sortBy = (property)=>{
    let sortOrder = 1;
    if(property[0] === "-") {
        sortOrder = -1;
        property = property.substr(1);
    }
    return function(a,b) {
        /* next line works with strings and numbers, 
         * and you may want to customize it to your needs
         */
        let result = (a[property] < b[property]) ? -1 : (a[property] > b[property]) ? 1 : 0;
        return result * sortOrder;
    }
};

export {sortBy,handleErrors,handleUIErrors,handleAuraErrors,showToast,redirect,isFieldLocked,gotoPage}