({
    doInit : function(component, event, helper) {        
        helper.getAllBranchingRecord(component,event);
    },
    addBranching : function(component,event, helper){
        var selectedOptionId = component.get("v.selectedOptionId");
        var selectedOptionBranching = component.get("v.selectedOptionBranching");
        var vMainQuesQuetnnaireId = component.get("v.MainQuesQuetnnaireId");
        var show_Question_QuestionnaireID = event.getSource().get("v.value");
        var branchingMap = {
            qstnOptionId: selectedOptionId,
            question_QuestionnaireID: vMainQuesQuetnnaireId,
            show_Question_QuestionnaireID :show_Question_QuestionnaireID
        };
        var isExist =false;
        for(var i=0 ; i<selectedOptionBranching.length;i++){
            if(selectedOptionBranching[i].qstnOptionId ===selectedOptionId && selectedOptionBranching[i].question_QuestionnaireID ===vMainQuesQuetnnaireId 
                && selectedOptionBranching[i].show_Question_QuestionnaireID ===show_Question_QuestionnaireID){
                selectedOptionBranching.splice(i,1);
                isExist =true;
            }
        }
        if(isExist === false){
            selectedOptionBranching.push(branchingMap);
        }
        component.set("v.selectedOptionBranching",selectedOptionBranching);
    }, 
    onChangeOption : function(component,event,helper){
        var selectedOptionId= component.get("v.selectedOptionId");
        if(selectedOptionId !== undefined && selectedOptionId !== "" && selectedOptionId.length !==0 ){
            helper.getQuestionWithoutBranching(component,event);
        }
        else{
            component.set("v.selectedOptionId","");
        }
    },
    closeModal : function(component,event, helper){
        var appEvent = $A.get("e.c:FBCloseEvent");
        // Optional: set some data for the event (also known as event shape)
        // A parameter’s name must match the name attribute
        // of one of the event’s <aura:attribute> tags
        appEvent.setParams({ "closeModel": true, "isUpdateRecord": false, "modelName": "Branching" });
        appEvent.fire();
    },
    saveBranchingRecord :function (component,event, helper){
        helper.helperUpdateBreachingRecord(component,event);        
    } 
})