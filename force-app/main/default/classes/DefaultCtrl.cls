/*
Created By    : Girikon(Sunil)
Created On    : Sep 06 2019
@description   : This class is used to redirect the user to the customer center community.
Test Class    : 
Modification log :
Modified By    : 
*/
public class DefaultCtrl {
  
    public  String  eventCode;
    public DefaultCtrl(){
        eventCode = apexpages.currentpage().getparameters().get('eventcode');
    }

    public PageReference redirectCommunity(){
        string strUrl='https://informamarkets.force.com/CustomerCenter';
        if(string.isNotBlank(eventCode)) {
            strUrl=strUrl+'?eventcode='+eventCode.escapeHtml4();
        }
        return new PageReference(strUrl);  
    } 
}