({
    invoke : function(component, event, helper) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type": "success",
            "title": "Success!",
            "message": component.get("v.message")
        });
        toastEvent.fire();

        // Get the record ID attribute
        var record = component.get("v.recordId");
        
        // Get the Lightning event that opens a record in a new tab
        var redirect = $A.get("e.force:navigateToSObject");
        
        // Pass the record ID to the event
        redirect.setParams({
           "recordId": record
        });
             
        // Open the record
        redirect.fire();
     }
})