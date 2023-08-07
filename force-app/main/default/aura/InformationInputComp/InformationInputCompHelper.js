({
    showToast: function(component, type, message) {
        $A.createComponent("c:FBToast",{"msgbody": message,"msgtype": type},function(newToast, status, errorMessage){
            if (status === "SUCCESS") {
                var body = component.get("v.body");
                body.push(newToast);
                component.set("v.body", body);
            }
            else if (status === "INCOMPLETE") {
                console.log("No response from server or client is offline.")
            }
            else if (status === "ERROR") {
                console.log("Error: " + errorMessage);
            }
        });
    },
    createQuestion: function(component, event, vQnaireId, vSectionId, vDragId, colNumber, colorCode, textcolor) {
        var vQues = component.get("v.objCrteQues");
        vQues.Type__c = vDragId;
        vQues.Label__c = component.get('v.description').trim();
        vQues.Label__c = this.removePTag(vQues.Label__c);
        var vQnaireName = component.get("v.QnaireName");
        var action = component.get("c.createQuestnAndQuestnQnaire"); //Calling Apex class controller 'createQueQnaire' method
        var vQuesOrder = component.get("v.questOrderNum");
        action.setParams({
            qnaireId: vQnaireId,
            qGroupId: vSectionId,
            question: vQues,
            qnaireName: vQnaireName,
            qOrder: vQuesOrder,
            colNumber: colNumber,
            colorCode: colorCode,
            textColor:textcolor
        });
        action.setCallback(this, function(res) {
            var state = res.getState();
            if (state === "SUCCESS") {
                this.crudModalEvent(component, event, false, true);

            } else {
                this.showToast(component,'error',res.getError()[0].message);
            }
        });
        $A.enqueueAction(action);
    },
    helperSaveEditQues: function(component, event) {
        var vQnaireId = component.get("v.QnaireId");
        var vSectionId = component.get("v.QuestnGroupId");
        var vDesc = component.get("v.description");
        component.set("v.objeditQues.Label__c", vDesc);
        var vQues = component.get("v.objeditQues");
        vQues.Label__c = vQues.Label__c.trim();
        vQues.Label__c = this.removePTag(vQues.Label__c);
        var action = component.get("c.saveEditQuesRecord"); //Calling Apex class controller 'saveEditQuesRecord' method
        action.setParams({
            oQues: vQues,
            qnaireId: vQnaireId,
            sectionId: vSectionId
        });
        action.setCallback(this, function(res) {
            var state = res.getState();
            if (state === "SUCCESS") {
                this.crudModalEvent(component, event, false, true);
            } else {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error :",
                    "mode": "sticky",
                    "message": res.getError()[0].message
                });
                toastEvent.fire();
            }
        });
        $A.enqueueAction(action);
    },
    crudModalEvent: function(component, event, closeModel, isUpdateRecord) {
        var vDragId = component.get("v.modalHeader");
        var appEvent = $A.get("e.c:FBCloseEvent");
        appEvent.setParams({ "closeModel": closeModel, "isUpdateRecord": isUpdateRecord, "modelName": vDragId });
        appEvent.fire();
    },
    onlyReturnString: function(valueWithHtmlTag) {
        var regex = /(<([^>]+)>)/ig
        return valueWithHtmlTag.replace(regex, "");
    },
    removePTag: function(labelText) {        
        return labelText;
    }
})