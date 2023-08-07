({
    MAX_FILE_SIZE: 4500000, //Max file size 4500000(4.5 MB), 20971520 (20.0 MB)
    CHUNK_SIZE: 750000,      //Chunk Max size 750Kb 
    getParameterByName: function (name) {
        name = name.replace(/[\[\]]/g, "\\$&");
        var url = window.location.href;
        var regex = new RegExp("[?&]" + name + "(=([^&#]*)|&|#|$)");
        var results = regex.exec(url);
        if (!results) return null;
        if (!results[2]) return '';
        return decodeURIComponent(results[2].replace(/\+/g, " "));
    },
    uploadHelper: function(component, event) {
        // start/show the loading spinner   
        component.set("v.showLoadingSpinner", true);
        // get the selected files using aura:id [return array of files]
        var fileInput = component.find("fileId").get("v.files");
        // get the first file using array index[0]  
        var file = fileInput[0];
        var self = this;
        // check the selected file size, if select file size greter then MAX_FILE_SIZE,
        // then show a alert msg to user,hide the loading spinner and return from function  
        if (file.size > self.MAX_FILE_SIZE) {
            component.set("v.showLoadingSpinner", false);
            component.set("v.fileName", 'Alert : File size cannot exceed ' + self.MAX_FILE_SIZE + ' bytes.\n' + ' Selected file size: ' + file.size);
            return;
        }
 
        // create a FileReader object 
        var objFileReader = new FileReader();
        // set onload function of FileReader object   
        objFileReader.onload = $A.getCallback(function() {
            var fileContents = objFileReader.result;
            var base64 = 'base64,';
            var dataStart = fileContents.indexOf(base64) + base64.length;
 
            fileContents = fileContents.substring(dataStart);
            // call the uploadProcess method 
            self.uploadProcess(component, file, fileContents);
        });
 
        objFileReader.readAsDataURL(file);
    },
 
    uploadProcess: function(component, file, fileContents) {
        // set a default size or startpostiton as 0 
        var startPosition = 0;
        // calculate the end size or endPostion using Math.min() function which is return the min. value   
        var endPosition = Math.min(fileContents.length, startPosition + this.CHUNK_SIZE);
 		
        // start with the initial chunk, and set the attachId(last parameter)is null in begin
        this.uploadInChunk(component, file, fileContents, startPosition, endPosition, '');
    	
    },
 
 
    uploadInChunk: function(component, file, fileContents, startPosition, endPosition, attachId) {
        // call the apex method 'saveChunk'
        
        var getchunk = fileContents.substring(startPosition, endPosition);
        var userDetail = this.getCookie('FBUserSessionID');
        var action = component.get("c.saveChunk");
        var conEdMapId = this.getParameterByName('ceid');
        console.log('component.get("v.version") ==='+ component.get("v.version"));
        var version = component.get("v.version");
        action.setParams({
            entryId : component.get("v.entryId"),
            ceid : conEdMapId,
            questionId : component.get("v.questionId"),
            questionerId : component.get("v.questionerId"),
            questionQuestionnairesId : component.get("v.questionQuestionnairesId"),
            fileName : file.name,
            base64Data : encodeURIComponent(getchunk),
            contentType : file.type,
            fileId : attachId,
            fileDescription : 'fileDescrption',
            version : version,
            isAllowMutliple : component.get("v.isAllowMultiple")                 
        });
 
        // set call back 
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                // store the response / Attachment Id   
                attachId = response.getReturnValue();
                if(attachId.length>18){
                // if return error message
                this.showToast(component,attachId,'Error!','error');
                component.set("v.showLoadingSpinner", false);
               }
                // update the start position with end postion
                startPosition = endPosition;
                endPosition = Math.min(fileContents.length, startPosition + this.CHUNK_SIZE);
                // check if the start postion is still less then end postion 
                // then call again 'uploadInChunk' method , 
                // else, diaply alert msg and hide the loading spinner
                if (startPosition < endPosition) {
                    this.uploadInChunk(component, file, fileContents, startPosition, endPosition, attachId);
                } else {
                    this.showToast(component,'your file is uploaded successfully','Success!','success');
                    this.getAttachments(component);
                }
                // handel the response errors        
            } else if (state === "INCOMPLETE") {
                this.showToast(component, "From server: " + response.getReturnValue(),'Alert!','error');
            } else if (state === "ERROR") {
                component.set("v.spinner", false);
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
    },
    showToast: function(component, message,title,type) {
        var toastEvent = $A.get("e.force:showToast");
        if(toastEvent!=undefined && toastEvent!=null){
            toastEvent.setParams({
                title: title,
                message: message,
                duration: ' 5000',
                type: type,
                mode: 'dismissible'
            });
            toastEvent.fire();    
        }
        else{
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
    },
	getCookie : function(cname) {
        var name = cname + "=";
        var decodedCookie = decodeURIComponent(document.cookie);
        var ca = decodedCookie.split(';');
        for(var i = 0; i <ca.length; i++) {
            var c = ca[i];
            while (c.charAt(0) == ' ') {
                c = c.substring(1);
            }
            if (c.indexOf(name) == 0) {
                return c.substring(name.length, c.length);
            }
        }
        return "";  
    },
    getAttachments : function(component) {
        let isMulti = component.get("v.isAllowMultiple");
        if(isMulti){
            var action = component.get("c.getAllAttchments");
            var conEdMapId = this.getParameterByName('ceid');
            action.setParams({
                entryId : component.get("v.entryId"),
                ceid : conEdMapId,
                questionId : component.get("v.questionId"),
                questionerId : component.get("v.questionerId"),
                questionQuestionnairesId : component.get("v.questionQuestionnairesId")              
            });
     
            // set call back 
            action.setCallback(this, function(response) {
                component.set("v.showLoadingSpinner", false);
                var state = response.getState();
                if (state === "SUCCESS") {
                    let attch = response.getReturnValue();
                    let fileName = '';
                    attch.forEach(row => {
                        fileName += (fileName==''?'':',') + row.Name;
                    });
                    component.set("v.fileName",fileName); 
                    component.set("v.listAttchments",response.getReturnValue());    
                } else if (state === "INCOMPLETE") {
                    this.showToast(component, "From server: " + response.getReturnValue(),'Alert!','error');
                } else if (state === "ERROR") {
                    component.set("v.spinner", false);
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
        else{
            component.set("v.showLoadingSpinner", false);
            component.set("v.listAttchments",[]);
        }
    }
})