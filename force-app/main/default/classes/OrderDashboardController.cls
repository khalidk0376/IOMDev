/**
 * Created By       :   Girikon(Ansh)
 * Created On       :   25/08/2012
 * @description     :   This class is used in SSCDashboard for Order Translation
 * Test Class       :   OrderDashboardControllerTest(88%)
 * Modification log:
 * Modified By  :
 **/
public class OrderDashboardController {
    
    /*
    * @description [Get record detail by passing object api name,comma seperated all fields api name and recordId]
    * @param objectName [set object api name]
    * @param allFields [comma seperated fields api name]
    * @param recordId [recordId]
    * @return [list of sObject]
    */
    @AuraEnabled
    public static List<sobject> getaccTransRecordDetail(String objectName,String allFields,String accId){
        return Database.query('Select '+String.escapeSingleQuotes(allFields)+' from '+String.escapeSingleQuotes(objectName)+' WHERE Account__c=:accId');
    }
    
    /*
    * @description [Get record detail by passing object api name,comma seperated all fields api name and recordId]
    * @param objectName [set object api name]
    * @param allFields [comma seperated fields api name]
    * @param recordId [recordId]
    * @return [list of sObject]
    */
    @AuraEnabled
    public static List<sobject> getconTransRecordDetail(String objectName,String allFields,String conId){
        return Database.query('Select '+String.escapeSingleQuotes(allFields)+' from '+String.escapeSingleQuotes(objectName)+' WHERE Contact__c=:conId');
    }
    /*
    * @description [This method is used to update records]
    * @param transdata [Translated obj data]
    * @param condata [Contact data]
    * @param accdata [Account data]
    * @return [success msg]
    */
    @AuraEnabled
    public static string updateSobjDetails(String transdata, String condata, String accdata){
        String msg = 'Success';
        if(transdata != null && transdata != ''){
            List<Translated_Record__c> lstTransRec = (List<Translated_Record__c>) JSON.deserialize( transdata, List<Translated_Record__c>.class );
        	upsert lstTransRec;
        }
        if(accdata != null && accdata != ''){
            Account acc = (Account) JSON.deserialize( accdata, Account.class );
        	upsert acc;
        }
        if(condata != null && condata != ''){
            Contact con = (Contact) JSON.deserialize( condata, Contact.class );
        	upsert con;
        }
        return msg;
    }
    /*
    * @description [This method is used to return status]
    * @param orderId [Id of Order obj]
    * @return [status]
    */
    @AuraEnabled
    public static string getOrderProcessingStatus(Id orderId){
        String status = '';
        Order ord = [SELECT Id,Status,(Select ERP_Sync_Status__c from blng__OrderInvoices__r) FROM Order WHERE Id =: orderId WITH SECURITY_ENFORCED];
        if(ord.blng__OrderInvoices__r.size() > 0){
            for(blng__Invoice__c inv : ord.blng__OrderInvoices__r){
                if(ord.Status == 'Activated' && (inv.ERP_Sync_Status__c == 'Sync Required' || string.isBlank(inv.ERP_Sync_Status__c ))){
                    status = 'inProgress';
                }else if(ord.Status == 'Activated' && inv.ERP_Sync_Status__c == 'Synced'){
                    status = 'completed';
                }else if(ord.Status == 'Activated' && inv.ERP_Sync_Status__c == 'Error'){
                    status = 'error';
                }
            }
        }else{
            status = 'inProgress';
        }
        return status;
    }
}