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
    createQuestion: function(component, event, vQnaireId, vSectionId, vDragId, colNumber) {

        var vQues = component.get("v.objCrteQues");        
        vQues.Label__c = vQues.Label__c.trim();
        vQues.Label__c = this.removePTag(component, event, vQues.Label__c.trim());
        vQues.Type__c = vDragId;
        var vQnaireName = component.get("v.QnaireName");
        var action = component.get("c.createQuestnAndQuestnQnaire"); //Calling Apex class controller 'createQueQnaire' method
        var vQuesOrder = component.get("v.questOrderNum");
        action.setParams({
            qnaireId: vQnaireId,
            qGroupId: vSectionId,
            question: vQues,
            qnaireName: vQnaireName,
            qOrder: vQuesOrder,
            colNumber: colNumber
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
    removePTag: function(component, event, labelText) {
        var text = labelText.split("<p>");
        var myString ="";
        if(text !== undefined && text.length>0){
            for(var index=0 ;index<text.length;index++){
                myString = myString + text[index].replace("<p>", "");
                myString = myString.replace("</p>", "<br/>");
            }
            var strBr = myString.substr(myString.length - 5, myString.length);
            if(strBr ==='<br/>'){
                return myString.slice(0, -5);
            }
            return myString;            
        }
        return labelText;
    },
    helperSaveEditQues: function(component, event) {
        var vQnaireId = component.get("v.QnaireId");
        var vSectionId = component.get("v.QuestnGroupId");
        var vDesc = component.get("v.description");
        component.set("v.objeditQues.Label__c", vDesc);
        var vQues = component.get("v.objeditQues");
        vQues.Label__c = vQues.Label__c.trim();
        vQues.Label__c = this.removePTag(component, event, vQues.Label__c.trim());
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
                this.showToast(component,'error',res.getError()[0].message);
            }
        });
        $A.enqueueAction(action);
    },
    crudModalEvent: function(component, event, closeModel, isUpdateRecord) {
        var vDragId = component.get("v.modalHeader");
        var appEvent = $A.get("e.c:FBCloseEvent");
        // Optional: set some data for the event (also known as event shape)
        // A parameter’s name must match the name attribute
        // of one of the event’s <aura:attribute> tags
        appEvent.setParams({ "closeModel": closeModel, "isUpdateRecord": isUpdateRecord, "modelName": vDragId });
        appEvent.fire();
    },
    getAllCurrencySymbol: function(component, event) {

        var action = component.get("c.getQueCurrencySymbol"); //Calling Apex class controller 'getQueCurrencySymbol' method
        action.setCallback(this, function(res) {
            var state = res.getState();
            if (state === "SUCCESS") {
                component.set("v.lstQuesCurrenctSymbol", res.getReturnValue());
            } else {
                this.showToast(component,'error',res.getError()[0].message);
            }
        });
        $A.enqueueAction(action);
    },
    onlyReturnString: function(valueWithHtmlTag) {
        var regex = /(<([^>]+)>)/ig
        console.log(valueWithHtmlTag);
        if(valueWithHtmlTag!=undefined){
            return valueWithHtmlTag.replace(regex, "");
        }
        else{
            return '';
        }
    }
})