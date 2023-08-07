({
    doInit: function(component, event, helper) {
        helper.getAttachments(component);
    },
    doSave: function(component, event, helper) {
        if (component.find("fileId").get("v.files").length > 0) {
            helper.uploadHelper(component, event);
        } else { 
            helper.showToast(component, 'Please select a valid file','Alert!','alert');
        }
    },
    handleFilesChange: function(component, event, helper) {
        var fileName = 'No File Selected..';
        if (event.getSource().get("v.files").length > 0) {
            fileName = event.getSource().get("v.files")[0]['name'];
        }
        component.set("v.fileName", fileName);
        if (component.find("fileId").get("v.files").length > 0) {
            helper.uploadHelper(component, event);
        } else {
            helper.showToast(component, 'Please select a valid file','Alert!','alert');
        }
    },
    handleDelete: function(component, event, helper) {
        component.set("v.spinner", true);
        let ids = event.getSource().get("v.value").split("_");
        var action = component.get("c.deleteAllAttchments");
        action.setParams({
            attachId : ids[0],
            qrid : ids[1]            
        });
    
        // set call back 
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                let attch = response.getReturnValue();
                let fileName = '';
                attch.forEach(row => {
                    fileName += (fileName==''?'':',') + row.Name;
                });
                component.set("v.fileName",fileName);
                component.set("v.listAttchments",response.getReturnValue());   
                this.showToast(component,'your file is deleted successfully','Success!','success'); 
            } else if (state === "INCOMPLETE") {
                this.showToast(component, "From server: " + response.getReturnValue(),'Alert!','error');
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        this.showToast(component,"Error: "+errors[0].message,'Alert!','error');
                    }
                } 
            }
        });
        // enqueue the action
        $A.enqueueAction(action);
    }
})