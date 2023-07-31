/**
* File         :   DeleteOverrideCtrl 
* Project      :   Informa Order Management [IOM-1659]
* Created Date :   23rd Jun 2022
* Created By   :   Girikon(Ansh)
* Test Class   :   DeleteOverrideCtrl_Test(92%)
* ******************************************************************************************************
* @description : To prevent user from deleting records
********************************************************************************************************
* Modification log :
*/
public class DeleteOverrideCtrl {

    public boolean isDelete {get;set;}
    public static Id sId {get;set;}
    
    public DeleteOverrideCtrl(ApexPages.StandardController controller) {
        if(!test.isRunningTest())
		sId = ApexPages.currentPage().getParameters().get('id');
        String sobjectType = sId.getSObjectType().getDescribe().getName();
        sobjectType = sobjectType.replace('__c', '').replace('__','_')+'_Delete';

        this.isDelete = false;
        string accValue = GlobalConstants.getValue(sobjectType);
        
        List<String> profileList = String.isNotBlank(accValue)?accValue.split(','):new List<String>();
        
        List<Profile> usrProfileList = [Select Id,Name from Profile where Id =: userInfo.getProfileId()];

        for(Profile p : usrProfileList){
            isDelete = profileList.contains(p.Name);
        }

	}
}