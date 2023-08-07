({
	scriptsLoaded2: function(component, event, helper) {
        helper.callScriptsLoaded(component, event);
    },
    hideModal:function(component, event, helper){ 
        helper.crudModalEvent(component, event, true, false);
    },
    doInit:function(component, event, helper){ 
        
        helper.getAllSections(component, event,component.get("v.QnaireId"));
    },
    saveSortedSection:function(component, event, helper){ 
        var lstQstnGrp=component.get("v.lstQuestnGroup");
        if(lstQstnGrp.length>0){
            helper.updateSortedSections(component, event,lstQstnGrp);
        }
    }
})