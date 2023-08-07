/* eslint-disable no-console */
import { LightningElement,track,api } from 'lwc';

export default class MultiPicklist extends LightningElement {

    @track visibleToUser;
    @track allSelectedOptions;
    
    
    @api label;
    @api placeholder;
    @api filterName;
    @api selectedOptions;
    @api options;

    connectedCallback(){
        this.options = [{label:'All '+this.placeholder,value:'',isChecked:true}];
          
        this.selectOptionHelper(this.placeholder,false);   
         
    }

    selectOptionHelper(label,isCheck) {
        let allOptions = JSON.parse(JSON.stringify(this.options));
        let selectedOption='';
        let selOpt=[];
        for(let i=0;i<allOptions.length;i++){            

            if(allOptions[i].value === label)
            {
                if(isCheck === 'true'){
                    allOptions[i].isChecked = false;
                }else{                    
                    allOptions[i].isChecked = true;					                    
                }
            }
            
            if(label==='' && i!==0 && allOptions[i].isChecked){
                allOptions[i].isChecked = false;
            }
            if(label!=='' && i===0 && allOptions[i].isChecked){
                allOptions[i].isChecked = false;
            }

            if(allOptions[i].isChecked){
                selOpt.push(allOptions[i].value);
                selectedOption=allOptions[i].label;//use to show only
            }
        }

        if(selOpt.length>1){
            selectedOption = selOpt.length+' items selected';
        }
    
        this.allSelectedOptions = selOpt;
        if(selOpt.length>0){
        	this.selectedValues = selOpt.join("\',\'");
        }
        else{
            this.selectedValues = "";    
        }
        this.visibleToUser = selectedOption;
        this.options = allOptions;
        this.selectedOptions = this.selectedValues;
        this.dispatchEvent(new CustomEvent('multipicklistselect',{selectedOptions:this.selectedValues}));
	}
    selectOption(event){        
        const value = event.currentTarget.getAttribute("data-value");
        const isCheck = event.currentTarget.getAttribute("data-ischecked");
       /* if(this.selectedValues.split("\',\'").length===1 && isCheck==='true' && value==='')
        {
        }
        else{
            this.selectOptionHelper(value,isCheck);
        }*/
    }    
    openDropdown(){
        this.template.querySelector('.dropdown').classList.add('slds-is-open');
        this.template.querySelector('.dropdown').classList.remove('slds-is-close');        
    }
    closeDropDown(){
        this.template.querySelector('.dropdown').classList.add('slds-is-close');
        this.template.querySelector('.dropdown').classList.remove('slds-is-open');
    }
}