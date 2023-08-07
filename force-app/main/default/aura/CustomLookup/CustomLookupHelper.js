({
	getDatas : function(component,pageNumber,srchKey) {   
        var pageSize=10;
		component.set("v.spinner", true);        
		var action = component.get("c.getLookupDatas");
        action.setParams({
            objectName: component.get("v.objectName"),
            nameFieldApi: component.get("v.nameFieldApi"),
            searchKey:srchKey,
            accId: component.get("v.accountId"),
            partnerAccId:component.get("v.parterAccId"),
            isBilling:component.get("v.isBilling"),
            pageNumber:pageNumber,
            pageSize:pageSize
        });
        action.setCallback(this, function(res) {
            component.set("v.spinner", false);
            var state = res.getState();
            if (state === "SUCCESS"){
                console.log(res.getReturnValue());   
                var result=res.getReturnValue();       
                component.set("v.lookupData", result.recordList);
                component.set("v.PageNumber", result.pageNumber);
                component.set("v.TotalRecords", result.totalRecords);
                component.set("v.RecordStart", result.recordStart);
                component.set("v.RecordEnd", result.recordEnd);
                component.set("v.TotalPages", Math.ceil(result.totalRecords / pageSize));
            } 
            else {
                window._LtngUtility.handleErrors(res.getError());
            }
        });
        $A.enqueueAction(action);
	},
	
})