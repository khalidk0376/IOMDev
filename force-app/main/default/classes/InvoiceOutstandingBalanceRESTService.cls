/**
* File         :   InvoiceOutstandingBalanceRESTService 
* Project      :   Order & Billing Plateform [IOM-669]
* Created Date :   10th Jan 2022
* Created By   :   Girikon(Ashish)
* Test Class   :   InvoiceRESTService_Test(84%)
****************************************************************************************************
@description : Apex rest class to update Invoice fields
****************************************************************************************************
* Modification log : 
* 1.Girikon (Ashish) [IOM-1147] 04 April 2022 : Used ERP Reference Number to update Outstanding Balance
*/
@RestResource(urlMapping='/InvoiceOutstandingBalance/*')
global with sharing class InvoiceOutstandingBalanceRESTService 
{
    /**
    * @description  This method is used to update Invoice fields
    * @return String 
    */
    @HttpPut
    global static ResponseData updateOutstandingBalanceOnInv() 
    {
        ResponseData resWrap = new ResponseData();
        resWrap.status = 'Unknown';
        resWrap.message = 'Invalid Request Data';
        RestRequest req = RestContext.request;
        String requestJSONString = req.requestBody.toString();
        try {
            InvoiceWapper invWrap = (InvoiceWapper)JSON.deserialize(requestJSONString,InvoiceWapper.class);
        
            if(String.isNotBlank(invWrap.invoiceNumber))
            {
                List<blng__Invoice__c> invList = new List<blng__Invoice__c>([SELECT Id,Name,Outstanding_Balance__c,Outstanding_Balance_Home__c,Outstanding_Balance_Local__c,Local_Exchange_Rate__c,CurrencyIsoCode,Ledger_Exchange_Rate__c,(SELECT Id,Name,Due_Dates__c,Outstanding_Balance__c,Invoice__r.Name from Payment_Schedules__r) FROM blng__Invoice__c WHERE ERP_Reference__c =: invWrap.invoiceNumber WITH SECURITY_ENFORCED]);
                
                
                resWrap.status = 'Error';
                resWrap.message = 'No Invoice found with Invoice ERP Number : '+invWrap.invoiceNumber;
                if(!invList.isEmpty() && Schema.sObjectType.blng__Invoice__c.isUpdateable())
                {  
                    string erMessage=''; 
                    List<Payment_Schedule__c> listPaymentSchedules = new List<Payment_Schedule__c>();
                    Double outStandingBal = invWrap.outstandingBalance !=null ? invWrap.outstandingBalance : 0;
                    Double localExchageRate = invList.get(0).Local_Exchange_Rate__c !=null ? invList.get(0).Local_Exchange_Rate__c : 1;
                    Double homeExchageRate = invList.get(0).Ledger_Exchange_Rate__c !=null ? invList.get(0).Ledger_Exchange_Rate__c : 1;

                    blng__Invoice__c inv = new blng__Invoice__c(Id=invList.get(0).Id);
                    inv.Outstanding_Balance__c      = outStandingBal;
                    inv.Outstanding_Balance_Home__c = outStandingBal*homeExchageRate;
                    inv.Outstanding_Balance_Local__c = outStandingBal*localExchageRate;
                    
                    if(invWrap.paymentSchedules != null && !invWrap.paymentSchedules.isEmpty())
                    {
                        Map<String,Payment_Schedule__c> paymentScheduleMap = getInvoicePaymentScheduleMap(invList.get(0).Payment_Schedules__r);
                        for(PaymentSchedule ps :invWrap.paymentSchedules)
                        {
                            string key = convertDateToString(ps.dueDate.date());
                            if(String.isNotBlank(key) && paymentScheduleMap.containsKey(key))
                            {
                                Payment_Schedule__c pamSch = paymentScheduleMap.get(key);
                                pamSch.Outstanding_Balance__c = ps.outstandingBalance;
                                listPaymentSchedules.add(pamSch);
                            }else{
                                
                                erMessage = (String.isNotBlank(erMessage)?',':'')+'No Payment Schedule found with due date '+ps.dueDate;
                            }
                        }
                    }
                    resWrap.status = 'Unknown';resWrap.message = erMessage;
                    if(Schema.sObjectType.Payment_Schedule__c.isUpdateable() && !listPaymentSchedules.isEmpty())
                    {
                        update listPaymentSchedules;
                        resWrap.status = 'Success';
                        resWrap.message = 'Outstanding data updated';
                    }
                    update inv;                    
                }
            }
        }catch (Exception e) 
        {
            resWrap.status = 'Error';resWrap.message = e.getMessage();
            system.debug(logginglevel.DEBUG,'Error_Message__c --> '+ resWrap.message +' At Line' + e.getLineNumber()); system.debug(logginglevel.DEBUG,' Trace --> '+ e.getStackTraceString());
        }
        return resWrap;
    }

    /************************** UTILITY METHORDS **************************/
    /**
    * @description : Methord to get a map of Payment_Schedules where key is Unique value
    * @param paymentSchedules List of Payment_Schedule
    * @return Map<String,Payment_Schedule__c> 
    */
    private static Map<String,Payment_Schedule__c> getInvoicePaymentScheduleMap(list<Payment_Schedule__c> paymentSchedules)
    {
        Map<String,Payment_Schedule__c> paymentScheduleMap = new Map<String,Payment_Schedule__c>();

        for(Payment_Schedule__c pysch:paymentSchedules)
        {
            paymentScheduleMap.put(convertDateToString(pysch.Due_Dates__c),pysch);
        }
        return paymentScheduleMap;
    }
     /**
    * @description : Methord to get Convert Date to String - YYYY-MM-DD to YYYYMMDD 
    * @param dtDate Date Input
    * @return Date as String
    */
    private static string convertDateToString(Date dtDate)
    {
        string strDate = '00000000';
        if(dtDate != null)
        {
            strDate = String.valueOf(dtDate.year())+String.valueOf(dtDate.month())+String.valueOf(dtDate.day());
        }
        return strDate;
    }
    /************************** Data Wrapper Class **************************/
    /**
    * @description  This method is used to update Invoice fields    
    */
    public class InvoiceWapper{
        public String invoiceNumber;	    //INV-00015 [Required]
        public Decimal outstandingBalance;	//36.00
        public String currencyISOCode;	    //USD   
        public PaymentSchedule[] paymentSchedules;
    }

    /**
    * @description  This method is used to update Invoice fields    
    */
    public class PaymentSchedule {
        public String paymentScheduleNumber;	// PS-00002
        public Decimal outstandingBalance;	    // 0.00
        public DateTime dueDate;	            // YYYY/MM/DD
    }

    /**
    * @description  This Class is to return Reponse Data
    */
    global class ResponseData 
    {
        public String status;	        // Success / Error /Unknown
		public String message;	        // 006
    }

    // {"invoiceNumber":"INV-00015","outstandingBalance":350.5,"currencyISOCode":"USD","PaymentSchedules":[{"paymentScheduleNumber":"PS-0001","outstandingBalance":0,"dueDate":"2021-12-21"},{"paymentScheduleNumber":"PS-0002","outstandingBalance":350.5,"dueDate":"2022-01-15"}]}
}