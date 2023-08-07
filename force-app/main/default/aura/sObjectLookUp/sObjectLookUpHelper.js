({
	searchRecordsHelper : function(component, event,value,serachKey) 
	{
		$A.util.removeClass(component.find("Spinner"), "slds-hide");
        component.set('v.message','');
		component.set('v.recordsList',null);
		

		//component.set("v.spinner", true);
        //var fieldValue = component.get("v.filterFieldValues");
        /*var fieldValue = ''
			if(Array.isArray(fieldValue))
			{
                fieldValue = fieldValue.toString();
            } */
		var param = JSON.stringify({
            objectName: component.get("v.objectName"),
            searchKey:serachKey,
            filterByFieldName: component.get("v.filterByFieldName") ? component.get("v.filterByFieldName") : '',
			filterByFieldValue:component.get("v.filterByvalue") ? component.get("v.filterByvalue") : '',
			fieldSetAsLabel:component.get("v.labelFieldAPI"),
			fieldSetAsValue:component.get("v.valueFieldAPI")
        });
		var action = component.get("c.getSObjects");
		action.setParams({
			prams:param
		});
		
        action.setCallback(this,function(response){
        	var objectlist = response.getReturnValue();
            console.log('response == : '+JSON.stringify(response.getState()));
			if(response.getState() === 'SUCCESS') 
			{
                console.log('data : '+ JSON.stringify(response.getReturnValue()));
                // To check if any records are found for searched keyword
				if(objectlist && objectlist.length > 0) 
				{
					var result = this.wrapsObjects(component, event, objectlist);
    				// To check if value attribute is prepopulated or not
					if( $A.util.isEmpty(value) )
					{
                        component.set('v.recordsList',result);
					} 
					else
					{
						var index = result.findIndex(x => x.value === value)
						if(index != -1)
						{
                            var selectedRecord = result[index];
                        }
                        component.set('v.selectedRecord',selectedRecord);
					}
				} else
				 {
    				component.set('v.message','No Records Found');
    			}
        	} else if(response.getState() === 'INCOMPLETE') 
            {
                component.set('v.message','No Server Response or client is offline');
            } else if(response.getState() === 'ERROR') 
            {
                // If server throws any error
                var errors = response.getError();
				if (errors && errors[0] && errors[0].message) 
				{
                    component.set('v.message', errors[0].message);
                }
            }
            // To open the drop down list of records
			if( $A.util.isEmpty(value) )
			{
				$A.util.addClass(component.find('resultsDiv'),'slds-is-open');
			}
        	$A.util.addClass(component.find("Spinner"), "slds-hide");
        });
        $A.enqueueAction(action);
	},
	wrapsObjects : function(component, event, objectList) 
	{
		var data = [];
		// console.log('objectList == '+JSON.stringify(objectList));  
		var namefield = component.get("v.labelFieldAPI"); 
		var idfield = component.get("v.valueFieldAPI"); 
		if(objectList && objectList.length > 0)
		{
			for(var i = 0 ;i<objectList.length ;i++)
			{
				var objectnode = {
					value  : objectList[i][idfield],
					label : (namefield.indexOf(".")==-1? objectList[i][namefield]: objectList[i][namefield.split(".")[0]][namefield.split(".")[1]])
				};
				console.log
				data.push(objectnode);
			}
		}
		return data;
	}
})