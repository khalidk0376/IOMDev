({
    doInit: function(cmp) {
        var action = cmp.get("c.importMembers");
        var campRecordId = cmp.get("v.recordId");
        var toastId = cmp.find('toastId');
        action.setParams({
            campaignId : campRecordId
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            var result = response.getReturnValue();


            //console.log('result 1' +result);
            if (state === "SUCCESS") {
                console.log('Result** 1 ' +JSON.stringify(result));
                console.log('Result** 2 ' +result.duplicateMem);
                if(result.duplicateMem != '0'){
                  cmp.set("v.dupMemMsg", result.duplicateMem+ ' Duplicate Members found.Please check if needed');
                    console.log('result.duplicateMem ' +result.duplicateMem);
                }
                if(result.memNotFound != '0'){
                  cmp.set("v.memNotFoundMsg", result.memNotFound+ ' records were not matched, please check');
                }
                if(result.campMembers == '0'){


                    cmp.set("v.message", 'No New Campaign Members to add');
                    $A.util.addClass(toastId, 'slds-theme_error');
                } 
                else{


                    var campCount = result.campMembers;
                    cmp.set("v.message", campCount+ ' New Campaign Members added');
                    $A.util.addClass(toastId, 'slds-theme_success');
                }
                $A.get('e.force:refreshView').fire();


            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                 errors[0].message);
                    }


                }             }
        });
        $A.enqueueAction(action);
    }
})