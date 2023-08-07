({
	deleteModalEvent :function(component,event,close,isRecordDeleting){
        var appEvent = $A.get("e.c:FBDeleteModalEvent");
        // Optional: set some data for the event (also known as event shape)
        // A parameter’s name must match the name attribute
        // of one of the event’s <aura:attribute> tags
        appEvent.setParams({"closeDeleteModel" : close,"deleteRecord":isRecordDeleting});
        appEvent.fire();
    },
    deleteSectionHelper : function(component,event,secId,questionaryId){
        var action = component.get("c.deleteSectionWithQuestionsAndQstnQustnry"); 
        action.setParams({ 
            sectionId : secId,
            questionaryId:questionaryId
        });
        action.setCallback(this,function(res){
            var state = res.getState(); 
            if(state === "SUCCESS"){
                this.deleteModalEvent(component,event,true,true);
            }
            else{
                this.showToast(component,'error',res.getError()[0].message);
            } 
        });        
        $A.enqueueAction(action);
    },
    showToast:function(component,type,message){
        $A.createComponent(
            "c:FBToast",
            {
                "msgbody": message,
                "msgtype": type
            },
            function(newToast, status, errorMessage){                
                if (status === "SUCCESS") {
                    var body = component.get("v.body");
                    body.push(newToast);
                    component.set("v.body", body);
                }
                else if (status === "INCOMPLETE") {
                    console.log("No response from server or client is offline.")
                    // Show offline error
                }
                else if (status === "ERROR") {
                    console.log("Error: " + errorMessage);
                    // Show error message
                }
            }
        );
    }
})