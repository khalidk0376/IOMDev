/**
* Created By     :  Girikon(Arushi[IMCC-5437])
* Created On     :  18/07/2023
* @description   :  Disable IRIS Login when Community User is disabled in IMCC
* Apex Test Class: 
**/
public class IMCC_UserRevokeAccess implements Queueable{
    private List<User> userList;
    
    public IMCC_UserRevokeAccess(List<User> recs) {
        this.userList = recs;
    }
    
    public void execute(QueueableContext queCont) {
        
        Set<Id> userIds = new Set<Id>();
        Map<Id,ThirdPartyAccountLink> tpaMap = new Map<Id,ThirdPartyAccountLink>();
        for(User u : userList){
            userIds.add(u.Id);
        }
        
        List<ThirdPartyAccountLink> thirdPartyActLinkLST = new List<ThirdPartyAccountLink>(
            [SELECT Provider, UserId,remoteIdentifier, SsoProvider.id FROM ThirdPartyAccountLink WHERE  UserId IN : userIds WITH SECURITY_ENFORCED]);
        
        if(!thirdPartyActLinkLST.isEmpty()){
          for(ThirdPartyAccountLink tpal : thirdPartyActLinkLST){Auth.AuthToken.revokeAccess(tpal.SsoProvider.id,tpal.Provider,tpal.UserId,tpal.remoteIdentifier);}
        }
   }
}