({
	crudModalEvent: function(component, event, closeModel, isUpdateRecord) {
        var appEvent = $A.get("e.c:FBCloseEvent");
        // Optional: set some data for the event (also known as event shape)
        // A parameter’s name must match the name attribute
        // of one of the event’s <aura:attribute> tags
        appEvent.setParams({ "closeModel": closeModel, "isUpdateRecord": isUpdateRecord, "modelName": "AddQstnSection" });
        appEvent.fire();
    },
    saveQuestnInSectn:function(component,event, selectedSectionId,qstnQnaireId,targetCol) {

        var action=component.get("c.saveQstnInSection");
		action.setParams({
            qquaireId: qstnQnaireId,
            selectedSectionId:selectedSectionId,
            targetCol:'col'+targetCol
        });
        action.setCallback(this, function(res) {
            var state = res.getState();
            if (state === "SUCCESS") {                
				if(res.getReturnValue()===false){                	
                    this.showToast(component,'success','Question is already in this section.');
				}
				else{
                    this.showToast(component,'success','Question has been moved successfully.');
                }
                var self = this;
                window.setTimeout($A.getCallback(function() {
                    self.crudModalEvent(component, event, false, true);
                }), 2500);
            } 
            else {
                this.showToast(component,'error',res.getError()[0].message);
            }
        });
        $A.enqueueAction(action);
    },
    showToast: function(component,type,message) {
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
    }
})