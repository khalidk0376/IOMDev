/**
* File:         BillingTransactionGenerator
* Project:      PoC SFDC Informa 
* Test Class:   BillingTransactionGeneratorTest
* Coverage:     85%
* *******************************************************************************************************
* @description : Generate billing transaction.
* @author: Ayoub Ouarti (aouarti@salesforce.com)
* @date: 25/11/2019
* *******************************************************************************************************
History
-------
VERSION         AUTHOR              DATE            DETAIL
1.0         Ayoub Ouarti        25/11/2019      Initial Dev
2.0         Ayoub Ouarti    29/11/2019      Add the test on the billing schedule if exist we use them 
3.0      Ayoub Ouarti    11/12/2019    [IML2R-417] Reduce the number of queries , implement the Queueable interface for Query limit exceeded error on the Billing Transactions when the order is Activated  
4.0      Ayoub Ouarti    20/12/2019    [IML2R-188] Scheduled Billing Rules, [IML2R-126] Event Director determine Separate Payment Terms at an Edition level and Product level (For Exhibition Editions)
5.0      Ayoub Ouarti    08/01/2020    Setting the quantity on the billing transaction from the order item, update the Order payement term after finfding the payment term used in the calculation.
6.0      Ayoub Ouarti    14/01/2020    [IML2R-615] Setting the CurrencyIsoCode on the Billing Schedule & the Billing transaction 
7.0      Ayoub Ouarti    16/01/2020    [IML2R-580] adding the Issue date to the Order Item to generate just one Billing transaction with 100% and dueDate
8.0      Ayoub Ouarti    24/01/2020    Adding the Partial Credit Treatment
9.0      Ayoub Ouarti    12/02/2020    Fix P1 & P2 issues
10.      Girikon(Ashish) 28 Nov 2022   Used Bill to Account in place of Opp Account [GECI-280]
10.1     IBM             06 Mar 2023   [GECI-824] BillingTransactionGenerator Changes to skip Migrated Opportunity/Orders
11.      Girikon(Ashish) 11 April 2023  [GECI-679] added start/End date to BT from Order Products

* *******************************************************************************************************/

public with sharing class BillingTransactionGenerator implements Queueable{
    public Order order ;
    public static List<OrderItem> orderItems=null;
    public BillingTransactionGenerator(Order order){
        this.Order = order;
    }
    public static void setOrderItems(List<OrderItem> orders){
        orderItems=orders;
    }
    public void execute(QueueableContext context) {
        
        BillingTransactionGenerator.generateBillingTransaction(this.order);
    }
    public static void generateBillingTransaction(Order ord){
        
        System.Debug('METHOD CALLED: generateBillingTransaction');
        Integer nbrOfTransaction =0;
        Integer maxTransactionsforEdition=4;
        Integer maxTransactionsforOppty=12;
        
         //Temp variables to re-initalize the values
         Integer nbrOfTransactionTemp =0;
         Date[] cutOffDatesTemp = new Date[maxTransactionsforOppty];
         Decimal[] cutOffPercentagesTemp = new Decimal[maxTransactionsforOppty];

        //Api Names
        String cutOffApiName='CutoffDate_';
        // String cutOffPercentageApiName='Custom_Cut-Off_Percentage_';
        
        String mileDelDateApiNamePart1='Milestone_';
        String mileDelPercentApiNamePart1='Milestone_';
        String mileDelDateApiNamePart2='_Delivery_Date__c';
        String mileDelPercentApiNamePart2='_Percent__c';
        
        String billingSchedulesApiNameOppty='Payment_Schedule__c';
        
        String billingSchedulesApiNameEdition='Payment_Schedule__c';
        String paymentTermApiNameEdition = 'Invoice_to_be_issued_before__c';
        String paymentTermApiNameAccount = 'Payment_Term__c';
        String paymentTermApiNameOppty = 'Payment_Term__c';
        // String paymentTermApiNameOrderItem = 'Payment_Term__c';
        // cut Off dates field Api name to construct the query part
        String cutOffDatesApiNameQuerypart ='';
        // cut Off Percentages field Api name to construct the query part
        String cutOffPercentageQuerypart ='';
        
        // MilestoneDeliveryDateApiName to construct the query part
        String mileDelPercentQuerypart ='';
        // MilestoneDeliveryDateApiName to construct the query part
        String mileDelDateQuerypart ='';
        
        // to grouping all the cut off dates & percentages in a table
         Date[] cutOffDates ;//= new Date[maxTransactionsforOppty];
         Decimal[] cutOffPercentages;// = new Decimal[maxTransactionsforOppty];
        
        // to know if the Billing Schedule is overriden on the opportunity
        Boolean isOverriddenOnOppty = False;
        Boolean isOverriddenOnOpptyAndNotCustom = False;
        
        String nbrOfTransactionApiName='Total_No_of_payment__c';
        String cutOffDatesDebug='';   String cutOffPercentagesDebug='';
        String[] BillingSchedulesParts;
        
        for(Integer i=1;i<=maxTransactionsforOppty;i++){
            mileDelDateQuerypart+=','+mileDelDateApiNamePart1+i+mileDelDateApiNamePart2;
            mileDelPercentQuerypart+=+','+mileDelPercentApiNamePart1+i+mileDelPercentApiNamePart2;
        }
        

        Order order = Database.query('SELECT Id ,CurrencyIsoCode, Status , SBQQ__Quote__r.SBQQ__PaymentTerms__c, OpportunityId,EffectiveDate FROM Order WHERE Id  = \''+String.escapeSingleQuotes(ord.Id)+'\'');
        
        //Start [GECI-824]
        if(order.OpportunityId!=null){
            List<TEMP_Order_Migration__c> orderMigrations =  [SELECT IOM_Opportunity__c, Id FROM TEMP_Order_Migration__c WHERE IOM_Opportunity__c=:order.OpportunityId ];
			if(!orderMigrations.isEmpty()){
                return;
            }
        }
        //End [GECI-824]

        //Get the Oppertunity from the DataBase by the Order's OpportunityId 
        Opportunity  opp = Database.query('SELECT AccountId ,Bill_To_Account__c, '+nbrOfTransactionApiName +', '+billingSchedulesApiNameOppty+mileDelDateQuerypart +mileDelPercentQuerypart+' FROM Opportunity WHERE  Id = \''+String.escapeSingleQuotes(order.OpportunityId)+'\'');
        System.Debug('QRY :SELECT AccountId ,Bill_To_Account__c, '+nbrOfTransactionApiName +', '+billingSchedulesApiNameOppty+mileDelDateQuerypart +mileDelPercentQuerypart+' FROM Opportunity WHERE  Id = \''+String.escapeSingleQuotes(order.OpportunityId)+'\''); 
        
        // Used Bill to Account inplace of Opp Account [GECI-280]
        Account acc=null ;
        if(opp.Bill_To_Account__c == null){
            System.Debug('ERR FUNCTIONAL: Bill_To_Account field is empty on Opportunity ID = '+opp.Id);     
        }else{
            //Get the Account from the DataBase By the Opportunity's Billing AccountId
            acc = Database.query('SELECT '+paymentTermApiNameAccount+' FROM Account where Id = \'' +String.escapeSingleQuotes(opp.Bill_To_Account__c)+ '\'');
            System.Debug('QRY :SELECT '+paymentTermApiNameAccount+' FROM Account where Id = \'' +opp.Bill_To_Account__c+ '\'');            
        }
        
        String paymentTerm =null;
        if(orderItems ==null){
            //Get the All the Order Items from the DataBase By the orderId and with the 'Invoice Plan' on the Billing Frequency
            orderItems =  Database.query('SELECT ServiceDate,EndDate,blng__HoldBilling__c ,PC_AI_Sub_scenario__c,Upgrade_Downgrade_Delta_Amount__c,OrderItemNumber ,Issue_Date__c,SBQQ__Activated__c,OrderId,Payment_Term_used_for_BT_Calculation__c,Product_Invoice_property__c, Payment_Term__c,Quantity , blng__InvoiceRunProcessingStatus__c  ,Edition__c ,TotalPrice,SBQQ__QuoteLine__c ,SBQQ__BillingFrequency__c  FROM OrderItem where SBQQ__BillingFrequency__c = \'Invoice Plan\' and OrderId = \''+String.escapeSingleQuotes(order.Id)+'\'');
            System.Debug('QRY :SELECT blng__HoldBilling__c ,PC_AI_Sub_scenario__c,Upgrade_Downgrade_Delta_Amount__c,OrderItemNumber ,Issue_Date__c, SBQQ__Activated__c,OrderId, Payment_Term_used_for_BT_Calculation__c, Product_Invoice_property__c,Payment_Term__c,Quantity , blng__InvoiceRunProcessingStatus__c ,Edition__c ,TotalPrice,SBQQ__QuoteLine__c ,SBQQ__BillingFrequency__c  FROM OrderItem where SBQQ__BillingFrequency__c = \'Invoice Plan\' and OrderId = \''+order.Id+'\''); 
            
        }
        //Construct a list of the orderItems's Ids to be used when we are searching for the QuoteLines
        List<String> editionIds = new List<String>();
        List<String> orderItemIds = new List<String>();
        for(OrderItem oi : orderItems){
            if(!orderItemIds.contains(oi.Id)){
                orderItemIds.add(oi.Id);
            } 
            if(oi.Edition__c == null || String.isBlank(oi.Edition__c)){
                System.Debug('ERR FUNCTIONAL : Edition missing on the OrderItem number :'+oi.Id);
            }else{
                if(!editionIds.contains(oi.Edition__c)){
                    editionIds.add(oi.Edition__c);
                } 
            }
        }
        
        //Billing_Schedule is Overridden on the Opportunity find out if the billing is there
        if(opp.get(billingSchedulesApiNameOppty) !=null && String.isNotBlank((String)opp.get(billingSchedulesApiNameOppty))){
            
            System.Debug('INFO : Billing Schedule is Overridden on the Opportunity');
            //case 1 : Billing Schedules is Custom
            if('Custom'.equals(opp.get(billingSchedulesApiNameOppty))){
                System.Debug('INFO : Billing Schedule is Overridden on the Opportunity and is Custom');
                if(opp.get(nbrOfTransactionApiName)==null || opp.get(nbrOfTransactionApiName)==0){
                    System.Debug('ERR FUNCTIONAL: '+opp.get(nbrOfTransactionApiName)+' field is missing or is empty');
                }else{
                    nbrOfTransactionTemp = integer.valueof(opp.get(nbrOfTransactionApiName));
                    cutOffPercentagesTemp = new Decimal[nbrOfTransactionTemp];
                    cutOffDatesTemp = new Date[nbrOfTransactionTemp];
                    //get the CutOff Percentages from the Opportunity recorde
                    for(Integer i =0;i<nbrOfTransactionTemp;i++){
                        //Milestone_1_Delivery_Date__c
                        cutOffDatesTemp[i]= (Date)opp.get(mileDelDateApiNamePart1+(i+1)+mileDelDateApiNamePart2);
                        cutOffPercentagesTemp[i]=(Decimal)opp.get(mileDelPercentApiNamePart1+(i+1)+mileDelPercentApiNamePart2);
                    }  
                }
                
            }else{
                BillingSchedulesParts = ((String)opp.get(billingSchedulesApiNameOppty)).split('-');
                nbrOfTransactionTemp = BillingSchedulesParts.size();
                cutOffPercentagesTemp = new Decimal[nbrOfTransactionTemp];
                cutOffDatesTemp = new Date[nbrOfTransactionTemp];
                //Construct the cutOffDates table , cutOffPercentages table
                for(Integer i =0;i<nbrOfTransactionTemp;i++){
                    // we should use the cutOfdates from edition
                    cutOffPercentagesTemp[i]=Decimal.valueOf(BillingSchedulesParts[i]);
                }
                isOverriddenOnOpptyAndNotCustom = true;
            }
            isOverriddenOnOppty = true;
        }
        
        Map<Id, Edition__c> editionsMap = new Map<Id, Edition__c>();
        List<Edition__c> editions = new List<Edition__c>();
        //Billing_Schedule is NOT Overridden on the Opportunity Or its overrid
        
        //  if the BS is overriden on Oppty and not custom, we should get the cutOffDates from Edition so we construct the query part 
        if(!isOverriddenOnOppty){
           
            nbrOfTransactionTemp = maxTransactionsforEdition;
            system.debug('$$$$$$$$$ nbrOfTransactionTemp=='+nbrOfTransactionTemp);
        }
      //  if(!isOverriddenOnOppty || isOverriddenOnOpptyAndNotCustom)
      //  {
            for(Integer i=0;i<3;i++){
                if(i==0){
                    cutOffDatesApiNameQuerypart+=', '+cutOffApiName+'_c';
                    
                }else{
                    cutOffDatesApiNameQuerypart+=', '+cutOffApiName+i+'__c';
                    
                }
                
            }
     //   }
        
        //get the edition for each quoteLine 
        editions =  Database.query('SELECT Id, Start_Date__c,Edition_Cut_Off_days__c,CutoffDate_3__c,'+paymentTermApiNameEdition+','+ billingSchedulesApiNameEdition  + cutOffDatesApiNameQuerypart +'  FROM Edition__c where Id in :editionIds');
        System.Debug('QRY : SELECT Id,Start_Date__c,Edition_Cut_Off_days__c , '+paymentTermApiNameAccount+','+ billingSchedulesApiNameEdition  + cutOffDatesApiNameQuerypart +'  FROM Edition__c where Id in :'+listToString(editionIds));
        editionsMap = new Map<Id, Edition__c>(editions);  
        
        
        Edition__c edition=null;
        List<blng__BillingSchedule__c> listOfBillingScheduleToStore = new List<blng__BillingSchedule__c>();
        List<blng__BillingTransaction__c> listOfBillingTransactionsToStore = new List<blng__BillingTransaction__c>();
        Map<Id,List<blng__BillingTransaction__c>> mapBillingTransaction = new Map<Id,List<blng__BillingTransaction__c>>();
        List<blng__BillingTransaction__c> billingTransactions = new List<blng__BillingTransaction__c>();   
        List<blng__BillingSchedule__c> billingScheduleFromBD = Database.query('SELECT Name,Payment_Term_Reason__c,Billing_Schedule_Reason__c, blng__Amount__c,  blng__OrderProduct__c FROM blng__BillingSchedule__c WHERE blng__OrderProduct__c in :orderItemIds');
        Date orderStartDate = null;
        Decimal sum=0;
        blng__BillingSchedule__c billingSchedule = null;
        Decimal amount= 0;
        Decimal totalPreviousAmount= 0;
        Decimal totalPreviousPercatege = 0;
        String paymentTermLevel ='';
        Map<Id,blng__BillingSchedule__c> mapBillingScheduleFromBD = new Map<Id,blng__BillingSchedule__c>();
        for(blng__BillingSchedule__c bs : billingScheduleFromBD){
            if(!mapBillingScheduleFromBD.containsKey(bs.blng__OrderProduct__c)){
                mapBillingScheduleFromBD.put(bs.blng__OrderProduct__c,bs);
            }
        }
     
        
        for(OrderItem orderItemRecord : orderItems){
            System.debug('temp - nbrOfTransaction '+nbrOfTransactionTemp);
            System.debug('temp - cutOffDates '+cutOffDatesTemp);
            System.debug('temp - cutOffPercentages '+cutOffPercentagesTemp);
            
            paymentTerm=null;
            billingTransactions =  new List<blng__BillingTransaction__c>();
            cutOffDates = new List<Date>();
        	cutOffPercentages = new List<Decimal>();
            nbrOfTransaction = nbrOfTransactionTemp;
            for(Date dt:cutOffDatesTemp){
                cutOffDates.add(dt);
            }
            for(Decimal dc:cutOffPercentagesTemp){
                cutOffPercentages.add(dc);
            }
            //cutOffDates = cutOffDatesTemp;
            //cutOffPercentages = cutOffPercentagesTemp;
            
            System.debug('load - nbrOfTransaction '+nbrOfTransaction);
            System.debug('load - cutOffDates '+cutOffDates);
            System.debug('load - cutOffPercentages '+cutOffPercentages);
            
            if(orderItemRecord.Quantity>0 ){
                //Issue Date is populated (related to magazine advert product)so we are creating just one Billing transaction for 100% and with date billing date is date issue
                if(orderItemRecord.Issue_Date__c!=null){
                    billingSchedule = new blng__BillingSchedule__c();
                    if(!mapBillingScheduleFromBD.containsKey(orderItemRecord.Id)){
                        //Create and insert the billing Schedule record
                        billingSchedule = new blng__BillingSchedule__c(
                            Name ='BS-'+orderItemRecord.OrderItemNumber ,
                            blng__Amount__c=orderItemRecord.TotalPrice,
                            blng__OrderProduct__c=orderItemRecord.Id,
                            CurrencyIsoCode = order.CurrencyIsoCode );
                        
                    }else{
                        billingSchedule = mapBillingScheduleFromBD.get(orderItemRecord.Id);
                    }
                    listOfBillingScheduleToStore.add(billingSchedule);
                    
                    billingTransactions.add( new blng__BillingTransaction__c(blng__Amount__c =orderItemRecord.TotalPrice,
                                                                             Name ='Transaction 1',
                                                                             blng__Status__c ='Pending',
                                                                             blng__BillingTargetDate__c= orderItemRecord.Issue_Date__c ,
                                                                             Billing_sequence__c ='1 of 1',
                                                                             Billing_Percentage__c = 100,
                                                                             blng__Quantity__c = orderItemRecord.Quantity, 
                                                                             CurrencyIsoCode = order.CurrencyIsoCode,blng__ServicePeriodStart__c=orderItemRecord.ServiceDate,blng__ServicePeriodEnd__c=orderItemRecord.EndDate)); 
                    System.Debug('Issue Date is populated  = Create one Billing transaction for the orderItem Id = '+orderItemRecord.Id);
                    mapBillingTransaction.put(orderItemRecord.Id,billingTransactions);
                }
                else{
                    if(String.isNotBlank(orderItemRecord.Edition__c)) {
                        edition = editionsMap.get(orderItemRecord.Edition__c);
                    }
                    //Payement terme levels
                    //1)Product Edition Object- Product Level
                    if(orderItemRecord.Payment_Term__c!= null){
                        if('due on receipt'.equals(((String)orderItemRecord.Payment_Term__c).toLowercase())){
                            paymentTerm= null;
                        }else{
                            paymentTerm= ((String)orderItemRecord.Payment_Term__c).substring(((String)orderItemRecord.Payment_Term__c).indexOf(' ')+1);
                        }
                        paymentTermLevel='Product Edition Object Level';
                    }
                    //2)Quote level override
                    else if(paymentTerm==null  && order.SBQQ__Quote__r.SBQQ__PaymentTerms__c!= null){
                        if('due on receipt'.equals(((String)order.SBQQ__Quote__r.SBQQ__PaymentTerms__c).toLowercase())){
                            paymentTerm= null;
                        }else{
                            paymentTerm= ((String)order.SBQQ__Quote__r.SBQQ__PaymentTerms__c).substring(((String)order.SBQQ__Quote__r.SBQQ__PaymentTerms__c).indexOf(' ')+1);
                        }
                        paymentTermLevel='Quote level';
                    }
                    //3)Account level
                    else if(paymentTerm==null  && acc.Payment_Term__c!= null ){
                        if('due on receipt'.equals(((String)acc.Payment_Term__c).toLowercase())){
                            paymentTerm= null;
                        }else{
                            paymentTerm= ((String)acc.Payment_Term__c).substring(((String)acc.Payment_Term__c).indexOf(' ')+1);
                        }
                        paymentTermLevel='Account level';
                    }
                    //4)Edition level
                    if(paymentTerm == null){
                        if(edition!=null && edition.get(paymentTermApiNameEdition) !=null){
                            paymentTerm=(String)edition.get(paymentTermApiNameEdition);
                        }
                        paymentTermLevel='Edition level';
                    }
                    
                    
                    //if order is placed within Number_Of_Days__c days of Event Edition Start date then its just 1 Billing Transaction with a Billing Target date of today(
                    //i.e. Net Payment term of Zero for all products against this Edition)
                    if(edition.Start_Date__c!=null  && edition.Edition_Cut_Off_days__c!=null && edition.Start_Date__c.addDays(-1* integer.valueof(edition.Edition_Cut_Off_days__c))  <= Date.toDay()) {
                        
                        billingSchedule = new blng__BillingSchedule__c();
                        if(!mapBillingScheduleFromBD.containsKey(orderItemRecord.Id)){
                            //Create and insert the billing Schedule record
                            billingSchedule = new blng__BillingSchedule__c(
                                Name ='BS-'+orderItemRecord.OrderItemNumber ,
                                
                                blng__Amount__c=orderItemRecord.TotalPrice,
                                blng__OrderProduct__c=orderItemRecord.Id,
                                Billing_Schedule_Reason__c ='Edition Cut-off Days',
                                Payment_Term_Reason__c ='Edition Cut-off Days',
                                CurrencyIsoCode = order.CurrencyIsoCode );
                       
                        }else{
                            billingSchedule = mapBillingScheduleFromBD.get(orderItemRecord.Id);
                        }
                        listOfBillingScheduleToStore.add(billingSchedule);
                        System.Debug('Billing_Schedule_Reason__c ==== '+billingSchedule.Billing_Schedule_Reason__c+', Payment_Term_Reason__c ===  '+billingSchedule.Payment_Term_Reason__c);
                        
                        billingTransactions.add( new blng__BillingTransaction__c(blng__Amount__c =orderItemRecord.TotalPrice,
                                                                                 Name ='Transaction 1',
                                                                                 blng__Status__c ='Pending',
                                                                                 blng__BillingTargetDate__c= Date.toDay() ,
                                                                                 Billing_sequence__c ='1 of 1',
                                                                                 Billing_Percentage__c = 100,
                                                                                 blng__Quantity__c = orderItemRecord.Quantity, 
                                                                                 CurrencyIsoCode = order.CurrencyIsoCode,blng__ServicePeriodStart__c=orderItemRecord.ServiceDate,blng__ServicePeriodEnd__c=orderItemRecord.EndDate )); 
                        System.Debug('Edition start date - cut  of  date  < today  = Create one Billing transaction for the orderItem Id = '+orderItemRecord.Id);
                        mapBillingTransaction.put(orderItemRecord.Id,billingTransactions);
                    }else{
                        
                        //Billing Schedule Rules
                        //Invoice in Full
                        if('Invoice in Full'.equals(orderItemRecord.Product_Invoice_property__c )) {
                            billingSchedule = new blng__BillingSchedule__c();
                            if(!mapBillingScheduleFromBD.containsKey(orderItemRecord.Id)){
                                //Create and insert the billing Schedule record
                                billingSchedule = new blng__BillingSchedule__c(
                                    Name ='BS-'+orderItemRecord.OrderItemNumber ,
                                    
                                    blng__Amount__c=orderItemRecord.TotalPrice,
                                    blng__OrderProduct__c=orderItemRecord.Id,
                                    Billing_Schedule_Reason__c ='Product Edition Object Level',
                                    Payment_Term_Reason__c =paymentTermLevel,
                                    CurrencyIsoCode = order.CurrencyIsoCode );
                        
                            }else{
                                billingSchedule = mapBillingScheduleFromBD.get(orderItemRecord.Id);
                            }
                            listOfBillingScheduleToStore.add(billingSchedule);
                            System.Debug('Billing_Schedule_Reason__c ==== '+billingSchedule.Billing_Schedule_Reason__c+', Payment_Term_Reason__c ===  '+billingSchedule.Payment_Term_Reason__c);
                            
                            billingTransactions.add( new blng__BillingTransaction__c(blng__Amount__c =orderItemRecord.TotalPrice,
                                                                                     Name ='Transaction 1',
                                                                                     blng__Status__c ='Pending',
                                                                                     blng__BillingTargetDate__c= Date.today(),
                                                                                     Billing_sequence__c ='1 of 1',
                                                                                     Billing_Percentage__c = 100,
                                                                                     blng__Quantity__c = orderItemRecord.Quantity,
                                                                                     CurrencyIsoCode = order.CurrencyIsoCode,blng__ServicePeriodStart__c=orderItemRecord.ServiceDate,blng__ServicePeriodEnd__c=orderItemRecord.EndDate )); 
                            System.Debug('Invoice in Ful on the OrderItem = Create one Billing transaction for the orderItem Id = '+orderItemRecord.Id);
                            
                            mapBillingTransaction.put(orderItemRecord.Id,billingTransactions);
                        }
                        //Invoice in Full as per the first invoice schedule
                        else if('Invoice in Full as per the first invoice schedule'.equals(orderItemRecord.Product_Invoice_property__c)) {
                            billingSchedule = new blng__BillingSchedule__c();
                            if(!mapBillingScheduleFromBD.containsKey(orderItemRecord.Id)){
                                //Create and insert the billing Schedule record
                                billingSchedule = new blng__BillingSchedule__c(
                                    Name ='BS-'+orderItemRecord.OrderItemNumber ,
                                    
                                    blng__Amount__c=orderItemRecord.TotalPrice,
                                    blng__OrderProduct__c=orderItemRecord.Id,
                                    Billing_Schedule_Reason__c ='Product Edition Object Level',
                                    Payment_Term_Reason__c =paymentTermLevel,
                                    CurrencyIsoCode = order.CurrencyIsoCode );
                            
                            }else{
                                billingSchedule = mapBillingScheduleFromBD.get(orderItemRecord.Id);
                            }
                            listOfBillingScheduleToStore.add(billingSchedule);
                            System.Debug('Billing_Schedule_Reason__c ==== '+billingSchedule.Billing_Schedule_Reason__c+', Payment_Term_Reason__c ===  '+billingSchedule.Payment_Term_Reason__c);
                            Date cutOffDate = (Date)edition.get(cutOffApiName+'_c') !=null? (Date)edition.get(cutOffApiName+'_c'):Date.today();
                            billingTransactions.add( new blng__BillingTransaction__c(blng__Amount__c =orderItemRecord.TotalPrice,
                                                                                     Name ='Transaction 1',
                                                                                     blng__Status__c ='Pending',
                                                                                     blng__BillingTargetDate__c= cutOffDate.addDays(-1*Integer.valueOf(paymentTerm)) ,
                                                                                     Billing_sequence__c ='1 of 1',
                                                                                     Billing_Percentage__c = 100,
                                                                                     blng__Quantity__c = orderItemRecord.Quantity,
                                                                                     CurrencyIsoCode = order.CurrencyIsoCode,blng__ServicePeriodStart__c=orderItemRecord.ServiceDate,blng__ServicePeriodEnd__c=orderItemRecord.EndDate )); 
                            System.Debug('Invoice in Full as per the first invoice schedule on the OrderItem = Create one Billing transaction for the orderItem Id = '+orderItemRecord.Id);
                            mapBillingTransaction.put(orderItemRecord.Id,billingTransactions);
                        }
                        
                        //Invoice in Full as per the second invoice schedule
                        else if('Invoice in Full as per the second invoice schedule'.equals(orderItemRecord.Product_Invoice_property__c)) {
                            billingSchedule = new blng__BillingSchedule__c();
                            if(!mapBillingScheduleFromBD.containsKey(orderItemRecord.Id)){
                                //Create and insert the billing Schedule record
                                billingSchedule = new blng__BillingSchedule__c(
                                    Name ='BS-'+orderItemRecord.OrderItemNumber ,
                                    
                                    blng__Amount__c=orderItemRecord.TotalPrice,
                                    blng__OrderProduct__c=orderItemRecord.Id,
                                    Billing_Schedule_Reason__c ='Product Edition Object Level',
                                    Payment_Term_Reason__c =paymentTermLevel,
                                    CurrencyIsoCode = order.CurrencyIsoCode );
                         
                            }else{
                                billingSchedule = mapBillingScheduleFromBD.get(orderItemRecord.Id);
                            }
                            listOfBillingScheduleToStore.add(billingSchedule);
                            System.Debug('Billing_Schedule_Reason__c ==== '+billingSchedule.Billing_Schedule_Reason__c+', Payment_Term_Reason__c ===  '+billingSchedule.Payment_Term_Reason__c);
                            
                            billingTransactions.add( new blng__BillingTransaction__c(blng__Amount__c =orderItemRecord.TotalPrice,
                                                                                     Name ='Transaction 1',
                                                                                     blng__Status__c ='Pending',
                                                                                     blng__BillingTargetDate__c= ((Date)edition.get(cutOffApiName+'1__c')).addDays(-1*Integer.valueOf(paymentTerm)) ,
                                                                                     Billing_sequence__c ='1 of 1',
                                                                                     Billing_Percentage__c = 100,
                                                                                     blng__Quantity__c = orderItemRecord.Quantity,
                                                                                     CurrencyIsoCode = order.CurrencyIsoCode,blng__ServicePeriodStart__c=orderItemRecord.ServiceDate,blng__ServicePeriodEnd__c=orderItemRecord.EndDate )); 
                            System.Debug('Invoice in Full as per the second invoice schedule on the OrderItem = Create one Billing transaction for the orderItem Id = '+orderItemRecord.Id);
                            mapBillingTransaction.put(orderItemRecord.Id,billingTransactions);
                        }
                        else if('Invoice as per Invoice Plan'.equals(orderItemRecord.Product_Invoice_property__c) || orderItemRecord.Product_Invoice_property__c == null){
                            // Invoice as per Invoice Plan
                            //if(!isOverriddenOnOppty){
                                if(!isOverriddenOnOppty){ // Normal - Edition payment Schedule
                                    BillingSchedulesParts = ((String)edition.get(billingSchedulesApiNameEdition)).split('-');
                                    nbrOfTransaction = BillingSchedulesParts.size();
                                    for(Integer i =0;i<nbrOfTransaction;i++){
                                        //Construct the cutOffDates table , cutOffPercentages table
                                        if(i==0){                                            
                                            cutOffDates[i] = (Date)edition.get(cutOffApiName+'_c');
                                        }else{
                                            cutOffDates[i]= (Date)edition.get(cutOffApiName+i+'__c');
                                        }
                                        cutOffPercentages[i]=Decimal.valueOf(BillingSchedulesParts[i]);
                                    }
                                }else{ // Opportunity Override
                                    if(isOverriddenOnOpptyAndNotCustom){ // opp override Without Custom 
                                        BillingSchedulesParts = ((String)opp.get(billingSchedulesApiNameOppty)).split('-');
                                        nbrOfTransaction = BillingSchedulesParts.size();
                                        for(Integer i =0;i<nbrOfTransaction;i++){
                                            //Construct the cutOffDates table 
                                            if(i==0){
                                                cutOffDates[i] = (Date)edition.get(cutOffApiName+'_c');
                                            }else{
                                                cutOffDates[i]= (Date)edition.get(cutOffApiName+i+'__c');
                                            }
                                            cutOffPercentages[i]=Decimal.valueOf(BillingSchedulesParts[i]); 
                                        }
                                    }else{ // Custom Billing - Opportunity Overide
                                        for(Integer i =0;i<nbrOfTransaction;i++){ //[GECI-667]
                                            cutOffDates[i] = cutOffDates[i].addDays(Integer.valueOf(paymentTerm));                                             
                                        }
                                    }
                                }
                                if(!cutOffDates.isEmpty() && cutOffDates.get(0) == null)
                                {
                                    cutOffDates[0] = (cutOffDates.size() > 1 && cutOffDates[1]<Date.today())?cutOffDates[1] :Date.today();
                                }
                            //}
                                                        
                            // List<blng__BillingSchedule__c> billingScheduleFromBD = Database.query('SELECT blng__Amount__c,  blng__OrderProduct__c FROM blng__BillingSchedule__c WHERE blng__OrderProduct__c = \''+orderItemRecord.Id+'\'');
                            billingSchedule = new blng__BillingSchedule__c();
                            if(!mapBillingScheduleFromBD.containsKey(orderItemRecord.Id)){
                                //Create and insert the billing Schedule record
                                billingSchedule = new blng__BillingSchedule__c(
                                    Name ='BS-'+orderItemRecord.OrderItemNumber ,
                                    
                                    blng__Amount__c=orderItemRecord.TotalPrice,
                                    blng__OrderProduct__c=orderItemRecord.Id,
                                    Billing_Schedule_Reason__c =isOverriddenOnOppty?'Opportunity level':'Edition Level',
                                    Payment_Term_Reason__c =paymentTermLevel,
                                    CurrencyIsoCode = order.CurrencyIsoCode );
                             
                            }else{
                                billingSchedule = mapBillingScheduleFromBD.get(orderItemRecord.Id);
                            }
                            System.Debug('Billing_Schedule_Reason__c ==== '+billingSchedule.Billing_Schedule_Reason__c+', Payment_Term_Reason__c ===  '+billingSchedule.Payment_Term_Reason__c);
                            
                            listOfBillingScheduleToStore.add(billingSchedule);
                            //get the order Start Date from the order
                            orderStartDate=(Date)order.EffectiveDate;
                            sum=0;
                            
                            
                            system.debug('$$$$$$$$$ nbrOfTransaction beforeeeeeeeee =='+nbrOfTransaction);
                            //Generic treatment for handling all cases about the place of orderStartDate compared with the cutOff dates
                            nbrOfTransaction = getNbrOfTransactionAndUpdateCutOffTables(cutOffDates,cutOffPercentages, nbrOfTransaction, orderStartDate, paymentTerm);   
                            system.debug('$$$$$$$$$ nbrOfTransaction Afteeeeeeeeer =='+nbrOfTransaction);
                            //list of Billing transaction that will be inserted on the database        
                            billingTransactions = new List<blng__BillingTransaction__c>();   
                            amount= 0;
                            totalPreviousAmount= 0;
                            totalPreviousPercatege = 0;
                            // Create Billing transaction for each cutOf date and cutOf percentage
                            for(Integer i = 0;i < nbrOfTransaction;i++){
                                if(i<nbrOfTransaction-1){
                                    // Setscale=2  means We are rounding off to 2 decimal places 
                                    // because the standard 'amount' field on billing transaction is only upto 2 decimal places.
                                    amount = (billingSchedule.blng__Amount__c * cutOffPercentages[i].setScale(2) / 100).setScale(2);
                                    totalPreviousAmount+=amount;
                                    totalPreviousPercatege+=cutOffPercentages[i].setScale(2);
                                }else{
                                    // Calculate the billing transaction's amount
                                    amount=billingSchedule.blng__Amount__c  - totalPreviousAmount ;
                                    cutOffPercentages[i] = 100.00 - totalPreviousPercatege;
                                }
                                
                                // adding the new record on the list 
                                billingTransactions.add(new blng__BillingTransaction__c(blng__Amount__c =amount,
                                                                                        // blng__BillingSchedule__c=billingSchedule.Id,
                                                                                        Name ='Transaction '+(i+1),
                                                                                        blng__Status__c ='Pending',
                                                                                        blng__BillingTargetDate__c= cutOffDates[i],
                                                                                        Billing_sequence__c =(i+1)+' of '+nbrOfTransaction,
                                                                                        Billing_Percentage__c = cutOffPercentages[i].setScale(2),
                                                                                        blng__Quantity__c = orderItemRecord.Quantity,
                                                                                        CurrencyIsoCode = order.CurrencyIsoCode,blng__ServicePeriodStart__c=orderItemRecord.ServiceDate,blng__ServicePeriodEnd__c=orderItemRecord.EndDate ));
                                System.Debug('Invoice as per Invoice Plan or null the OrderItem = Create '+(i+1)+' of '+nbrOfTransaction+' Billing transaction for the orderItem Id = '+orderItemRecord.Id);  
                            }
                            //Insert all Billing transactions
                            //insert billingTransactions;
                            mapBillingTransaction.put(orderItemRecord.Id,billingTransactions);
                        }
                    }      
                }
            }
            orderItemRecord.Payment_Term_used_for_BT_Calculation__c=paymentTerm==null?'Due on receipt':'Net '+paymentTerm;
        } 
        
        upsert listOfBillingScheduleToStore;
        
        System.debug('------- Final result ------------');
        for(blng__BillingSchedule__c bs : listOfBillingScheduleToStore){
            System.debug('--------------- bs = '+bs+' ---------------');
            
            for(blng__BillingTransaction__c bt : mapBillingTransaction.get(bs.blng__OrderProduct__c)){
                bt.blng__BillingSchedule__c=bs.Id;
                System.debug('bt = '+bt);
                listOfBillingTransactionsToStore.add(bt);
            }            
        }
        if(!listOfBillingTransactionsToStore.isEmpty())
        {
            insert listOfBillingTransactionsToStore;
        }
        
        PaymentTermOnOrder_Trig.setPaymentTermOnOrderFromOrderItem(order.Id);
        
        System.Debug('INFO: generateBillingTransaction method end');
    } 

    public static Integer getNbrOfTransactionAndUpdateCutOffTables(Date[] cutOffDates, Decimal[] cutOffPercentages, Integer nbrOfTransaction,Date orderStartDate,String paymentTerms ){
        Decimal sum=0;
        System.debug('Before cutOffDates - '+cutOffDates);
        System.debug('Before cutOffPercentages - '+cutOffPercentages);
        //Generic treatment for handling all cases about the place of orderStartDate compared with the cutOff dates
        for(Integer i=0;i<nbrOfTransaction;i++){
           if(i+1 < nbrOfTransaction
               && (( orderStartDate > cutOffDates[i] && orderStartDate <= cutOffDates[i+1]) //1
                   || (orderStartDate > cutOffDates[i]&&  i==nbrOfTransaction-2))){
                       for(Integer j=0;j<nbrOfTransaction;j++){
                           if(j==0) {
                               for(Integer k=0;k<=i;k++){
                                   sum+=cutOffPercentages[k];
                               }  
                               cutOffDates[j]=orderStartDate;//cutOffDates[i+1];
                               cutOffPercentages[j]=sum;
                           }else{
                               if(i+j<nbrOfTransaction){
                                   cutOffDates[j]=cutOffDates[j+i];
                                   cutOffPercentages[j]=cutOffPercentages[i+j];  
                               }
                           }  
                       }
                       nbrOfTransaction = nbrOfTransaction -(i);
                       break;
                   }  
        }
        Date billingTargetCompareDate = (orderStartDate < Date.today()?Date.today():orderStartDate);
        for(Integer i=0;i<nbrOfTransaction;i++){
            cutOffDates[i]=cutOffDates[i].addDays(-1 * Integer.valueOf(paymentTerms));
            if(cutOffDates[i] < billingTargetCompareDate){
                cutOffDates[i] = billingTargetCompareDate;
            }
        }

        Map<Date,Decimal> mapDate = new Map<Date,Decimal>();
        for(Integer i=0;i<nbrOfTransaction;i++){
            Decimal percent = mapDate.containsKey(cutOffDates[i])?mapDate.get(cutOffDates[i]):(0);
            percent += cutOffPercentages[i];
            mapDate.put(cutOffDates[i], percent);
        }

        Integer index = -1;
        for(Date d : mapDate.keySet()){
            index++;
            cutOffDates[index] = d;
            cutOffPercentages[index] = mapDate.get(d);
        }
        System.debug('Final cutOffDates - '+cutOffDates);
        System.debug('Final cutOffPercentages - '+cutOffPercentages);
        nbrOfTransaction = index+1;
        return nbrOfTransaction;
    }

    /*public static Integer getNbrOfTransactionAndUpdateCutOffTablesV2(Date[] cutOffDates, Decimal[] cutOffPercentages, Integer nbrOfTransaction,Date orderStartDate,String paymentTerms ){
        Decimal sum=0;
        //Generic treatment for handling all cases about the place of orderStartDate compared with the cutOff dates
        for(Integer i=0;i<nbrOfTransaction;i++){
           if(i+1 < nbrOfTransaction
               && (( orderStartDate > cutOffDates[i] && orderStartDate <= cutOffDates[i+1]) //1
                   || (orderStartDate > cutOffDates[i]&&  i==nbrOfTransaction-2))){
                       for(Integer j=0;j<nbrOfTransaction;j++){
                           if(j==0) {
                               for(Integer k=0;k<=i;k++){
                                   sum+=cutOffPercentages[k];
                               }  
                               cutOffDates[j]=orderStartDate;//cutOffDates[i+1];
                               cutOffPercentages[j]=sum;
                           }else{
                               if(i+j<nbrOfTransaction){
                                   cutOffDates[j]=cutOffDates[j+i];
                                   cutOffPercentages[j]=cutOffPercentages[i+j];  
                               }
                           }  
                       }
                       nbrOfTransaction = nbrOfTransaction -(i);
                       break;
                   }  
        }
        System.debug('cutOffDates - '+cutOffDates);
        System.debug('cutOffPercentages - '+cutOffPercentages);

        for(Integer i=0;i<nbrOfTransaction;i++){
            cutOffDates[i]=cutOffDates[i].addDays(-1 * Integer.valueOf(paymentTerms));
            if(cutOffDates[i]<Date.today()){
                cutOffDates[i] = Date.today();
            }
        }
        
        return nbrOfTransaction;
    }*/

    /*   
    public static Integer  getNbrOfTransactionAndUpdateCutOffTablesV1 (Date[] cutOffDates, Decimal[] cutOffPercentages, Integer nbrOfTransaction,Date orderStartDate,String paymentTerms )
    {
        Decimal sum=0;
        //Generic treatment for handling all cases about the place of orderStartDate compared with the cutOff dates
        for(Integer i=0;i<nbrOfTransaction;i++){
           if(i+1 < nbrOfTransaction
               && (( orderStartDate > cutOffDates[i] && orderStartDate <= cutOffDates[i+1]) //1
                   || (orderStartDate > cutOffDates[i]&&  i==nbrOfTransaction-2))){
                       for(Integer j=0;j<nbrOfTransaction;j++){
                           if(j==0) {
                               for(Integer k=0;k<=i+1;k++){
                                   sum+=cutOffPercentages[k];
                               }  
                               cutOffDates[j]=cutOffDates[i+1];
                               cutOffPercentages[j]=sum;
                           }else{
                               if(i+j+1<nbrOfTransaction){
                                   cutOffDates[j]=cutOffDates[j+i+1];
                                   cutOffPercentages[j]=cutOffPercentages[i+j+1];  
                               }
                           }  
                       }
                       nbrOfTransaction = nbrOfTransaction -(i+1);
                       break;
                   }  
        }
        
        for(Integer i=0;i<nbrOfTransaction;i++){
            cutOffDates[i]=cutOffDates[i].addDays(-1 * Integer.valueOf(paymentTerms));
            if(cutOffDates[i]<Date.today()){
                cutOffDates[i] = Date.today();
            }
        }
        
        return nbrOfTransaction;
    }    */
    
    public static String listToString(List<Id> listElement){
        String str='';
        for(ID eachId : listElement){
            str+=' , '+eachId;
        }
        return str;
    }
}