({
	getQuoteDetail : function(component) {
		component.set("v.spinner", true);
		let param = JSON.stringify({oppId: component.get("v.oppId")});

		var action = component.get("c.invoke");
        action.setParams({action:'get_quote',parameters:param});
        action.setCallback(this, function(res) {
            component.set("v.spinner", false);
            var state = res.getState();
            if (state === "SUCCESS"){
                let quoteCount = parseInt(res.getReturnValue(),10); 
                if(quoteCount>0){   
	                component.set("v.isQuoteExist", true);
	            }
            } 
            else {
                window._LtngUtility.handleErrors(res.getError());
            }
        });
        $A.enqueueAction(action);
	},
})