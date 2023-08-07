({
	doInit : function(component, event, helper) {
		component.set("v.formId",helper.getParameterByName('id'));
        var userDetail = helper.getCookie('FBUserSessionID');
        console.log(encodeURIComponent(userDetail));
        component.set("v.userData",encodeURIComponent(userDetail));
	},
	downloadResponse : function(component, event, helper) {	
		if(window.location.href.indexOf('/IMCC/')>0){	
			component.find("download-link").getElement().setAttribute("href","/IMCC/apex/DownloadResponsePDF?qnaireId="+component.get("v.formId")+"&ref="+component.get("v.userData"));			
		}
		else{
			component.find("download-link").getElement().setAttribute("href","/apex/DownloadResponsePDF?qnaireId="+component.get("v.formId")+"&ref="+component.get("v.userData"));			
		}
		component.find("download-link").getElement().click();
	}
})