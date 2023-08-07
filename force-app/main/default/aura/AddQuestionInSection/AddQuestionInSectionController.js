({	
    hideModal:function(component, event, helper){ 
        helper.crudModalEvent(component, event, true, false);
    },
    saveQuestionInSection:function(component, event, helper){
        var selectedSectionId=component.get("v.selTabId");
        var qstnQnaireObject=component.get("v.qstnQnaireObject");
        var totalCol=0,targetCol=0;
        var prevCol = parseInt(qstnQnaireObject.Related_To_Column__c.replace('col',''),10);
        var sectionList = component.get("v.lstQuesGroup");        
        for(var i=0;i<sectionList.length;i++){
            //console.log(sectionList[i].Question_Group__c+'=='+selectedSectionId)
            if(sectionList[i].Question_Group__c===selectedSectionId){
                totalCol = sectionList[i].Question_Group__r.No_Of_Columns__c;
            }
        }        
        if(totalCol<prevCol){
            targetCol = totalCol;
        }
        else{
            targetCol = prevCol;
        }

        if(targetCol==0){
            targetCol=1;
        }

        if(qstnQnaireObject.branchingQuestnQuetnnaire !==undefined && 
            qstnQnaireObject.branchingQuestnQuetnnaire !== null && 
            qstnQnaireObject.branchingQuestnQuetnnaire.length>0)
        {
            component.set("v.showConfirmModal",true);
        }
        else{
        	helper.saveQuestnInSectn(component,event, selectedSectionId,qstnQnaireObject.Id,targetCol);
        }
        //console.log(JSON.stringify(qstnQnaireObject));
    },
    saveQuestionInSectionWithBranching:function(component, event, helper){
        var selectedSectionId=component.get("v.selTabId");
        var qstnQnaireObject=component.get("v.qstnQnaireObject");
        var totalCol=0,targetCol=0;
        var prevCol = parseInt(qstnQnaireObject.Related_To_Column__c.replace('col',''),10);
        var sectionList = component.get("v.lstQuesGroup");        
        for(var i=0;i<sectionList.length;i++){
            console.log(sectionList[i].Question_Group__c+'=='+selectedSectionId)
            if(sectionList[i].Question_Group__c==selectedSectionId){
                totalCol = sectionList[i].Question_Group__r.No_Of_Columns__c;
            }
        }
        
        if(totalCol<prevCol){
            targetCol = totalCol;
        }
        else{
            targetCol = prevCol;
        }
        
        if(targetCol==0){
            targetCol=1;
        }

        helper.saveQuestnInSectn(component,event, selectedSectionId,qstnQnaireObject.Id,targetCol);
    }
})