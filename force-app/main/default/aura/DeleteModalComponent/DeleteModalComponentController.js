({
	hideModal :function(component, event, helper){
        helper.deleteModalEvent(component,event,true,false); 
    },
    deleteSection: function(component, event, helper){
        var vSectionId=component.get("v.sectionId");
        var vQnaireId=component.get("v.qnaireId");
        if(vSectionId !=="" && vQnaireId !== ""){
         	helper.deleteSectionHelper(component, event,vSectionId,vQnaireId);   
        }
    }
})