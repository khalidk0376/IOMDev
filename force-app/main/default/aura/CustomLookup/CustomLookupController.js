({
	doInit : function(component, event, helper) {
		helper.getDatas(component,component.get("v.PageNumber"));
	},
	searchContact : function(component, event, helper) {
		 if(component.get("v.searchKey").length>2){
            helper.getDatas(component,component.get("v.PageNumber"),component.get("v.searchKey"));    
        }
        else if(component.get("v.searchKey").length==0){
            helper.getDatas(component,component.get("v.PageNumber"),'');  
        }
	},	
	selectLookup : function(component, event, helper) {
		component.set("v.selectedItem",event.getSource().get("v.value"));
		component.set("v.selectedItemId",event.getSource().get("v.value").Id);
		component.set("v.isOpenModal",false);
	},
	closeModal : function(component, event, helper) {
		component.set("v.isOpenModal",false);
	},
 	handleNext: function(component, event, helper) {
        var pageNumber = component.get("v.PageNumber");  
        pageNumber++;
        helper.getDatas(component, pageNumber);
    },
 	handlePrev: function(component, event, helper) {
        var pageNumber = component.get("v.PageNumber");  
        pageNumber--;
        helper.getDatas(component, pageNumber);
    } 
})