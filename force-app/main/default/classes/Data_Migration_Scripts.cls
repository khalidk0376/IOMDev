/**
* Created By       :   IBM(Bharath)
* Created On       :   26 May 2023
* @description     :   [GECI-1481]-Data Migration Scripts
* Test Class       :   Data_Migration_Scripts_Test (100%)
*                      
***********************************************************************************************
*/
public class Data_Migration_Scripts {
    /**@description  Constructor for coverage only*/
    public Data_Migration_Scripts(){
        System.debug(LoggingLevel.DEBUG, 'Data_Migration_Scripts');
    }
    
    /*//@description  Scripts to run IM Org
    public static void Script_IM_02_Quote_Update() {
        //Set<String> iomOppNumbers = new Set<String>{'IMO-00394'}; // CRM_IOM_Opportunity_Number__c IN :iomOppNumbers
        // Update the IOM Opportunity in the TEMP Object and set the Close Date in the Primary Quote
        List<TEMP_Order_Migration__c> omList = new List<TEMP_Order_Migration__c>();
        // Collect the Opp Numbers
        Set<String> oppNumberSet = new Set<String>();
        Map<Id, TEMP_Order_Migration__c> oppTempMigMap = new Map<Id, TEMP_Order_Migration__c>();
        for(TEMP_Order_Migration__c migRec: [SELECT Id, Name, CRM_Opportunity_Id__c, CRM_Opportunity_Name__c, CRM_IOM_Opportunity_Number__c, CRM_Invoice_Id__c, 
                                                    CRM_Invoice_Name__c, CRM_Invoice_Date__c, CRM_SAP_Order_Id__c, CRM_Invoice_Status__c, CRM_Product_Name__c, 
                                                    IOM_Billing_Schedule__c, IOM_Opportunity__c, IOM_Billing_Transaction__c, Status__c, Stage__c  
                                               FROM TEMP_Order_Migration__c WHERE CRM_IOM_Opportunity_Number__c <> NULL AND IOM_Opportunity__c = NULL AND Status__c = 'Pending' AND Stage__c = 'Step 01']) {
            oppNumberSet.add(migRec.CRM_IOM_Opportunity_Number__c);
            oppTempMigMap.put(migRec.Id, migRec);
        }
        
        // Read the Opportunity Id and Close Date
        Map<String, Opportunity> oppNumberMap = new Map<String, Opportunity>();
        List<SBQQ__Quote__c> quoteList = new List<SBQQ__Quote__c>();
        for(Opportunity opp: [SELECT Id, CloseDate, Opportunity_Number__c, SBQQ__PrimaryQuote__c FROM Opportunity WHERE Opportunity_Number__c IN :oppNumberSet LIMIT 15]) {
            oppNumberMap.put(opp.Opportunity_Number__c, opp);
            quoteList.add(new SBQQ__Quote__c(Id = opp.SBQQ__PrimaryQuote__c, SBQQ__StartDate__c = opp.CloseDate, SBQQ__Ordered__c = TRUE));
        }
        
        // Set the Opportunity in Temp Rec
        for(TEMP_Order_Migration__c tempRec : oppTempMigMap.values()) {
            if(oppNumberMap.containsKey(tempRec.CRM_IOM_Opportunity_Number__c)) {
                tempRec.IOM_Opportunity__c = oppNumberMap.get(tempRec.CRM_IOM_Opportunity_Number__c).Id;
                tempRec.Status__c = 'In Progress';
                tempRec.Stage__c = 'Step 02';
                omList.add(tempRec);
            }
        }
        
        System.DEBUG('Total # of TEMP Records to be updated = ' + omList.size());
        System.DEBUG('Total # of Quote Records to be updated = ' + quoteList.size());
        
        // Update the Temp Records
        update omList;
        
        // Update the Quote List
        update quoteList;
    }

	//@description  Scripts to run IM Org
    public static void Script_IM_03A_OrderProduct_DuplicateFix(){
        // Update the IOM Opportunity in the TEMP Object and set the Close Date in the Primary Quote
        List<TEMP_Order_Migration__c> omList = new List<TEMP_Order_Migration__c>();
        
        // Collect the Order and Order Product Info
        String oppId = '006DI000001s9LnYAI';
        
        List<TEMP_Order_Migration__c> oppTempMigList = new List<TEMP_Order_Migration__c>();
        for(TEMP_Order_Migration__c migRec: [SELECT Id, CRM_IOM_Opportunity_Number__c, CRM_Invoice_Id__c, CRM_Line_Total_Amount__c, CRM_Line_Tax_Amount__c,
                                                    CRM_Invoice_Name__c, CRM_Invoice_Date__c, CRM_Invoice_Status__c, CRM_Product_Name__c, 
                                                    IOM_Billing_Schedule__c, IOM_Opportunity__c, IOM_Billing_Transaction__c, IOM_Order__c, IOM_Order_Product__c,
                                                    Status__c, Stage__c  
                                            FROM TEMP_Order_Migration__c 
                                            WHERE IOM_Opportunity__c = :oppId   
                                            ORDER BY CRM_Invoice_Name__c, CRM_Product_Name__c]) {
            oppTempMigList.add(migRec);
        }
        
        // Collect the Orders for updating the Invoice Batch
        String orderId;
        Map<String, OrderItem> productOLIMap = new Map<String, OrderItem>();
        Map<String, List<OrderItem>> product_OLIs_Map = new Map<String, List<OrderItem>>();
        List<OrderItem> OIList = new List<OrderItem>();
        
        for(OrderItem oiRec : [SELECT Id, OrderId, Order.OpportunityId, Product2.ProductCode, TotalPrice, SBQQ__TaxAmount__c FROM OrderItem WHERE Order.OpportunityId = :oppId ORDER BY Order.OpportunityId, Product2.ProductCode]) {
            orderId = oiRec.OrderId;
            // For Non - Duplciates
            productOLIMap.put(oiRec.Product2.ProductCode, oiRec);
        
            // For Duplicates
            if(product_OLIs_Map.containsKey(oiRec.Product2.ProductCode)) {
                OIList = product_OLIs_Map.get(oiRec.Product2.ProductCode);
            } else {
                OIList = new List<OrderItem>();
            }
            OIList.add(oiRec);
            product_OLIs_Map.put(oiRec.Product2.ProductCode, OIList);
        }
        
        Set<String> usedInvoiceProducts = new Set<String>();
        Map<String, Set<String>> invoice_OLIs_Map = new Map<String, Set<String>>();
        Set<String> usedOLIs = new Set<String>();
        Boolean foundCorrectOrderProductFlag = false;
        for(TEMP_Order_Migration__c omRec : oppTempMigList) {
            System.debug('Processing for omRec ' + omRec.Id + ':' + omRec.CRM_Invoice_Name__c + ':' + omRec.CRM_Product_Name__c);
            if(productOLIMap.containsKey(omRec.CRM_Product_Name__c)) {
                OrderItem oiRec = productOLIMap.get(omRec.CRM_Product_Name__c);
                omRec.IOM_Order__c = oiRec.OrderId;
                omRec.IOM_Order_Product__c = oiRec.Id;
                omRec.Status__c = 'In Progress';
                omRec.Stage__c = 'Step 03';
                omList.add(omRec);
        
                // Finding the right value first time
                if(product_OLIs_Map.get(omRec.CRM_Product_Name__c).size() > 1 && !usedInvoiceProducts.contains(omRec.CRM_Invoice_Name__c + ':'+ omRec.CRM_Product_Name__c)) {
                    foundCorrectOrderProductFlag = false;
                    for(OrderItem oi: product_OLIs_Map.get(omRec.CRM_Product_Name__c)) {
                        if(!foundCorrectOrderProductFlag && oi.SBQQ__TaxAmount__c == omRec.CRM_Line_Tax_Amount__c) {
                            System.debug('Got Correct Order Product ' + oi.Id + ' instead of ' + omRec.IOM_Order_Product__c);
                            omRec.IOM_Order_Product__c = oi.Id;
                            foundCorrectOrderProductFlag = true;
                        }
                    }
                }
        
                // Fix for avoiding duplicate OP Id
                if(usedInvoiceProducts.contains(omRec.CRM_Invoice_Name__c + ':'+ omRec.CRM_Product_Name__c)) {
                    // System.debug('Found Duplicate Order Product - ' + omRec.IOM_Order_Product__c + ' of Order - ' + omRec.IOM_Order__c);
                    foundCorrectOrderProductFlag = false;
                    if(product_OLIs_Map.containsKey(omRec.CRM_Product_Name__c)) {
                        for(OrderItem oi: product_OLIs_Map.get(omRec.CRM_Product_Name__c)) {
                            // System.debug('Got value in product_OLIs_Map - ' + oi.Id);
                            if(!invoice_OLIs_Map.get(omRec.CRM_Invoice_Name__c).contains(oi.Id)) {
                                if(!foundCorrectOrderProductFlag && oi.SBQQ__TaxAmount__c == omRec.CRM_Line_Tax_Amount__c) {
                                    // System.debug('Got Correct Order Product ' + oi.Id + ' instead of ' + omRec.IOM_Order_Product__c);
                                    omRec.IOM_Order_Product__c = oi.Id;
                                    foundCorrectOrderProductFlag = true;
        
                                    // For Duplicates
                                    usedOLIs = invoice_OLIs_Map.get(omRec.CRM_Invoice_Name__c);
                                    usedOLIs.add(oi.Id);
                                    invoice_OLIs_Map.put(omRec.CRM_Invoice_Name__c, usedOLIs);
                                }
                            }
                        }
        
                        if(!foundCorrectOrderProductFlag) {
                            System.debug('Issue identifying right Order Product for ' + omRec.Id + ' - ' + omRec.IOM_Order_Product__c + ' - ' + omRec.CRM_Product_Name__c);
                        }
                    } else {
                        // System.debug('No key ' + omRec.IOM_Opportunity__c + ':' + omRec.CRM_Product_Name__c + ' found in ' + OP_OLI_Map.keySet());
                    }
                } else {
                    // System.debug('Adding Order - ' + omRec.IOM_Order__c + ' and Order Product - ' + omRec.IOM_Order_Product__c);
                    usedInvoiceProducts.add(omRec.CRM_Invoice_Name__c + ':'+ omRec.CRM_Product_Name__c);
                    invoice_OLIs_Map.put(omRec.CRM_Invoice_Name__c, new Set<String>{omRec.IOM_Order_Product__c});
                }
            } else {
                System.debug('Problem in - ' + omRec.IOM_Opportunity__c + ':' + omRec.CRM_Product_Name__c);
            }
		}

        System.debug('Number of Order Migration Records = ' + omList.size());
        update omList;
    }
    
    //@description  Scripts to run IM Org
    public static void Script_IM_03_Order_OrderProduct_Update(){
             //Set<String> iomOppNumbers = new Set<String>{'IMO-00199'}; // CRM_IOM_Opportunity_Number__c IN :iomOppNumbers
            // Update the IOM Opportunity in the TEMP Object and set the Close Date in the Primary Quote
            List<TEMP_Order_Migration__c> omList = new List<TEMP_Order_Migration__c>();
            
            // Collect the Order and Order Product Info
            Set<String> oppIdSet = new Set<String>();
            Map<String, TEMP_Order_Migration__c> oppTempMigMap = new Map<String, TEMP_Order_Migration__c>();
            for(TEMP_Order_Migration__c migRec: [SELECT Id, Name, CRM_Opportunity_Id__c, CRM_Opportunity_Name__c, CRM_IOM_Opportunity_Number__c, CRM_Invoice_Id__c, 
                                                        CRM_Invoice_Name__c, CRM_Invoice_Date__c, CRM_SAP_Order_Id__c, CRM_Invoice_Status__c, CRM_Product_Name__c, 
                                                        IOM_Billing_Schedule__c, IOM_Opportunity__c, IOM_Billing_Transaction__c, IOM_Order__c, IOM_Order_Product__c,
                                                        Status__c, Stage__c  
                                                FROM TEMP_Order_Migration__c 
                                                WHERE IOM_Order__c = NULL AND Status__c = 'In Progress' AND Stage__c = 'Step 03'   
                                                ORDER BY CRM_Opportunity_Id__c, CRM_Invoice_Date__c, CRM_Product_Name__c]) {
                oppIdSet.add(migRec.IOM_Opportunity__c);
                oppTempMigMap.put(migRec.Id, migRec);
            }
            
            // Collect the Orders for updating the Invoice Batch
            Set<Id> orderIds = new Set<Id>();
            Map<Id, Id> orderOppMap = new Map<Id, Id>();
            Map<String, OrderItem> oppProductMap = new Map<String, OrderItem>();
            Map<String, List<OrderItem>> OP_OLI_Map = new Map<String, List<OrderItem>>();
            List<OrderItem> OIList = new List<OrderItem>();
            
            for(OrderItem oiRec : [SELECT Id, OrderId, Order.OpportunityId, Product2.ProductCode FROM OrderItem WHERE Order.OpportunityId IN :oppIdSet ORDER BY Order.OpportunityId, Product2.ProductCode]) {
                orderOppMap.put(oiRec.OrderId, oiRec.Order.OpportunityId);
                // System.debug(oiRec.Order.OpportunityId + ':' + oiRec.Product2.ProductCode);
                oppProductMap.put(oiRec.Order.OpportunityId + ':' + oiRec.Product2.ProductCode, oiRec);
                orderIds.add(oiRec.OrderId);
                
                // MR - Fix for avoiding duplicate Order Product in Temp Table
                if(OP_OLI_Map.containsKey(oiRec.Order.OpportunityId + ':' + oiRec.Product2.ProductCode)) {
                    OIList = OP_OLI_Map.get(oiRec.Order.OpportunityId + ':' + oiRec.Product2.ProductCode);
                } else {
                    OIList = new List<OrderItem>();
                }
                OIList.add(oiRec);
                OP_OLI_Map.put(oiRec.Order.OpportunityId + ':' + oiRec.Product2.ProductCode, OIList);
            }
            
            // Limit for the 20 Orders update in 1 go
            Set<Id> limitOrderIdSet = new Set<Id>();
            Set<Id> selectedOrderIds = new Set<Id>();
            Set<Id> limitOppIdSet = new Set<Id>();
            
            for(String orderId: orderIds) {
                if(limitOrderIdSet.size() < 20) {
                    limitOrderIdSet.add(orderId);
                    limitOppIdSet.add(orderOppMap.get(orderId));
                }
            }
            System.debug('Filtered Opps List => '+ limitOppIdSet.size() + ' out of ' + oppIdSet.size());
            System.debug('Filtered Orders List => '+ limitOrderIdSet.size() + ' out of ' + orderOppMap.size());
            System.debug(limitOppIdSet);
            
            // Set<Id> usedOrderProductId = new Set<Id>();
            Set<String> usedInvNameOrderProductId = new Set<String>();
            Boolean foundCorrectOrderProductFlag = false;
            for(TEMP_Order_Migration__c omRec : oppTempMigMap.values()) {
                if(limitOppIdSet.contains(omRec.IOM_Opportunity__c)) {
                    System.debug('Processing for omRec ' + omRec.Id + ':' + omRec.CRM_Invoice_Name__c + ':' + omRec.CRM_Product_Name__c);
                    if(oppProductMap.containsKey(omRec.IOM_Opportunity__c + ':' + omRec.CRM_Product_Name__c)) {
                        OrderItem oiRec = oppProductMap.get(omRec.IOM_Opportunity__c + ':' + omRec.CRM_Product_Name__c);
                        omRec.IOM_Order__c = oiRec.OrderId;
                        omRec.IOM_Order_Product__c = oiRec.Id;
                        omRec.Status__c = 'In Progress';
                        omRec.Stage__c = 'Step 03';
                        omList.add(omRec);
                        selectedOrderIds.add(omRec.IOM_Order__c);
            
                        // Fix for avoiding duplicate OP Id
                        if(usedInvNameOrderProductId.contains(omRec.CRM_Invoice_Name__c + ':' + oiRec.Id)) {
                            System.debug('Found Duplicate Order Product - ' + omRec.IOM_Order_Product__c + ' of Order - ' + omRec.IOM_Order__c);
                            foundCorrectOrderProductFlag = false;
                            if(OP_OLI_Map.containsKey(omRec.IOM_Opportunity__c + ':' + omRec.CRM_Product_Name__c)) {
                                for(OrderItem oi: OP_OLI_Map.get(omRec.IOM_Opportunity__c + ':' + omRec.CRM_Product_Name__c)) {
                                    // System.debug('Got value in OP_OLI_Map - ' + oi.Id);
                                    if(!foundCorrectOrderProductFlag) {
                                        for(String invOPStr: usedInvNameOrderProductId) {
                                            if(!foundCorrectOrderProductFlag) {
                                                // System.debug('Review Used Inv Name Map - ' + invOPStr);
                                                List<String> strArray = invOPStr.split(':');
                                                if(strArray[0] == omRec.CRM_Invoice_Name__c && strArray[1] <> oi.Id) {
                                                    System.debug('Got Correct Order Product ' + oi.Id + ' instead of ' + omRec.IOM_Order_Product__c);
                                                    omRec.IOM_Order_Product__c = oi.Id;
                                                    usedInvNameOrderProductId.add(omRec.CRM_Invoice_Name__c + ':'+ oi.Id);
                                                    foundCorrectOrderProductFlag = true;
                                                }
                                            }
                                        }
                                    }
                                }
                            } else {
                                // System.debug('No key ' + omRec.IOM_Opportunity__c + ':' + omRec.CRM_Product_Name__c + ' found in ' + OP_OLI_Map.keySet());
                            }
                        } else {
                            // System.debug('Adding Order - ' + omRec.IOM_Order__c + ' and Order Product - ' + omRec.IOM_Order_Product__c);
                            // usedOrderProductId.add(oiRec.Id);
                            usedInvNameOrderProductId.add(omRec.CRM_Invoice_Name__c + ':'+ oiRec.Id);
                        }
                    } else {
                        System.debug('Problem in - ' + omRec.IOM_Opportunity__c + ':' + omRec.CRM_Product_Name__c);
                    }
                }
            }
            
            System.debug('Number of Order Migration Records = ' + omList.size());
            update omList;
            
            if(omList.size() > 0) {
                // Set the Invoice Batch for Orders
                List<Order> orderList = new List<Order>();
                Integer batchBucket = 1;
                for(Order ord: [SELECT Id, blng__InvoiceBatch__c FROM Order WHERE Id IN :selectedOrderIds]) {
                    ord.blng__InvoiceBatch__c = 'DM ' +  (math.mod(batchBucket, 10) + 1);
                    System.debug(ord.blng__InvoiceBatch__c);
                    orderList.add(ord);
                    batchBucket++;
                }
            
                System.debug('Number of Order Records to be updated = ' + orderList.size());
                // update orderList;
            } else {
                System.debug(' no more orders to fetch');
            }
            
            System.debug('Number of Order Migration Records = ' + omList.size());
 
    }


    //@description  Scripts to run IM Org
	public static void Script_IM_04_CustomBillingScheduler(){
        // Set<String> iomOppNumbers = new Set<String>{'IMO-00199'};  // CRM_IOM_Opportunity_Number__c IN :iomOppNumbers
        // Skip the Opp Id
        Set<Id> skipOppIds = new Set<Id>();
        
        // Update the IOM Billing Schedule and Billing Transactions in the TEMP Object
        List<TEMP_Order_Migration__c> omList = new List<TEMP_Order_Migration__c>();
        
        // Collect the Opp Numbers
        Set<String> oppIdSet = new Set<String>();
        Map<Id, Map<Date, Integer>> oppInvDatePercentMap = new Map<Id, Map<Date, Integer>>();
        Map<Date, Integer> invDatePercentMap = new Map<Date, Integer>();
        Map<String, TEMP_Order_Migration__c> oppbtbsMap = new Map<String, TEMP_Order_Migration__c>();
        for(TEMP_Order_Migration__c migRec: [SELECT Id, Name, CRM_Opportunity_Id__c, CRM_Opportunity_Name__c, CRM_IOM_Opportunity_Number__c, CRM_Invoice_Id__c, 
                                                    CRM_Invoice_Name__c, CRM_Invoice_Date__c, CRM_Invoice_Percent__c, CRM_SAP_Order_Id__c, CRM_Invoice_Status__c, CRM_Product_Name__c, 
                                                    IOM_Billing_Schedule__c, IOM_Opportunity__c, IOM_Billing_Transaction__c, IOM_Order__c, IOM_Order_Product__c,
                                                    Status__c, Stage__c 
                                               FROM TEMP_Order_Migration__c 
                                              WHERE Status__c = 'In Progress' AND Stage__c = 'Step 03' AND CRM_Invoice_Status__c <> 'Cancelled' AND IOM_Order__r.Status = 'Activated' 
                                              ORDER BY CRM_Opportunity_Id__c, CRM_Invoice_Date__c, CRM_Product_Name__c]) {
            oppIdSet.add(migRec.IOM_Opportunity__c);
            oppbtbsMap.put(migRec.IOM_Opportunity__c + ':' + migRec.CRM_Invoice_Date__c + ':' + migRec.IOM_Order_Product__c, migRec);
            
            // Logic to get the # of Txn based on the Invoice Date
            if(oppInvDatePercentMap.containsKey(migRec.IOM_Opportunity__c)) {
                invDatePercentMap = oppInvDatePercentMap.get(migRec.IOM_Opportunity__c);
            } else {
                invDatePercentMap = new Map<Date, Integer>();
            }
            invDatePercentMap.put(migRec.CRM_Invoice_Date__c, Integer.valueOf(migRec.CRM_Invoice_Percent__c));
            oppInvDatePercentMap.put(migRec.IOM_Opportunity__c, invDatePercentMap);
        }
        
        // Limit for the 25 Orders update in 1 go
        Set<Id> limitOppIdSet = new Set<Id>();
        for(String oppId: oppIdSet) {
            if(limitOppIdSet.size() < 10) {
                limitOppIdSet.add(oppId);
            }
        }
        
        System.debug('Filtered Opps List => '+ limitOppIdSet.size() + ' out of ' + oppIdSet.size());
        System.debug(limitOppIdSet);
        
        // Select the Order based on the Opportunity
        for(Order orderRec : [SELECT Id, OpportunityId FROM Order WHERE OpportunityId IN :limitOppIdSet]) {
            System.debug('Order Processing - ' + orderRec.Id + ' and Opportunity Processing - ' + orderRec.OpportunityId);
            List<blng__BillingSchedule__c> bsList = new List<blng__BillingSchedule__c>();
            Map<Id, List<blng__BillingTransaction__c>> oi_bt_Map = new Map<Id, List<blng__BillingTransaction__c>>();
            List<blng__BillingTransaction__c> btList = new List<blng__BillingTransaction__c>();
            
            List<Date> invDates = new List<Date>(oppInvDatePercentMap.get(orderRec.OpportunityId).keySet());
            Map<Date, Integer> datePercentMap = oppInvDatePercentMap.get(orderRec.OpportunityId);
            Integer nbrOfTransaction = invDates.size();
        
            // Default Percentages
            Decimal[] cutOffPercentages = new Decimal[3];
            cutOffPercentages[0] = Decimal.valueOf(25);
            cutOffPercentages[1] = Decimal.valueOf(25);
            cutOffPercentages[2] = Decimal.valueOf(50);
        
            if(nbrOfTransaction == 1) { cutOffPercentages[0] = 100; } 
            else if(nbrOfTransaction == 2) { cutOffPercentages[0] = 50; cutOffPercentages[1] = 50;} 
        
            // Percentage based on CRM Data
            Decimal[] crmCutOffPercentages = new Decimal[invDates.size()];
            invDates.sort();
            Integer dateIndex = 0;
            Boolean errFlag = false;
        
            for(Date invDt: invDates) {
                crmCutOffPercentages[dateIndex] = datePercentMap.get(invDt);
                // Validation
                if(crmCutOffPercentages[dateIndex] != cutOffPercentages[dateIndex]) {
                    System.debug('ERROR on Cut-Off Percentages');
                    errFlag = true;
                }
                dateIndex++;
            }
        
            if(!errFlag) {
                List<OrderItem> orderItems = Database.query('SELECT Id, OrderItemNumber, TotalPrice, Quantity, Order.CurrencyIsoCode FROM OrderItem where OrderId = \''+String.escapeSingleQuotes(orderRec.Id)+'\'');
                
                for(OrderItem orderItemRecord : orderItems) {
                    System.debug('Creating BS for ' + orderItemRecord.TotalPrice + ' amount with ' + nbrOfTransaction + ' txns');
                    //Create and insert the billing Schedule record
                    blng__BillingSchedule__c billingSchedule = new blng__BillingSchedule__c(
                        Name ='BS-'+orderItemRecord.OrderItemNumber,
                        blng__Amount__c=orderItemRecord.TotalPrice,
                        blng__OrderProduct__c=orderItemRecord.Id,
                        Billing_Schedule_Reason__c = 'Opportunity Level',
                        Payment_Term_Reason__c = 'Edition Level',
                        CurrencyIsoCode = orderItemRecord.order.CurrencyIsoCode 
                    );
                
                    bsList.add(billingSchedule);
                
                    List<blng__BillingTransaction__c> billingTransactions = new List<blng__BillingTransaction__c>();
                    Decimal amount = 0;
                    Decimal totalPreviousAmount = 0;
                    Decimal totalPreviousPercentage = 0;
                
                    for(Integer i = 0;i < nbrOfTransaction;i++) {
                        if(i<nbrOfTransaction-1) {
                            amount = (billingSchedule.blng__Amount__c * crmCutOffPercentages[i].setScale(2) / 100).setScale(2);
                            totalPreviousAmount+=amount;
                            totalPreviousPercentage+=crmCutOffPercentages[i].setScale(2);
                        } else {
                            amount=billingSchedule.blng__Amount__c  - totalPreviousAmount ;
                            cutOffPercentages[i] = 100.00 - totalPreviousPercentage;
                        }
        
                        System.debug('Creating BT for ' + amount + ' amount for ' + invDates[i] + ' date');
        
                        billingTransactions.add(new blng__BillingTransaction__c(blng__Amount__c = amount,
                                                                                Name = 'Transaction '+(i+1),
                                                                                blng__Status__c = 'Pending',
                                                                                blng__BillingTargetDate__c = invDates[i],
                                                                                Billing_sequence__c = (i+1)+' of '+nbrOfTransaction,
                                                                                Billing_Percentage__c = cutOffPercentages[i].setScale(2),
                                                                                blng__Quantity__c = orderItemRecord.Quantity,
                                                                                CurrencyIsoCode = orderItemRecord.order.CurrencyIsoCode ));
                    }
                    oi_bt_Map.put(orderItemRecord.Id, billingTransactions);
                }
        
                try {
                    insert bsList;
                
                    Map<Id, Id> bs_oi_Map = new Map<Id, Id>();
                    for(blng__BillingSchedule__c bs : bsList) {   
                        bs_oi_Map.put(bs.Id, bs.blng__OrderProduct__c);
                        for(blng__BillingTransaction__c bt : oi_bt_Map.get(bs.blng__OrderProduct__c)){
                            bt.blng__BillingSchedule__c = bs.Id;
                            btList.add(bt);
                        }                  
                    }
                    
                    if(!btList.isEmpty()) {
                        system.debug('Number of BT records ' + btList.size());
                        insert btList;
                    }
                
                    for(blng__BillingTransaction__c bt: btList) {
                        String oiId = bs_oi_Map.get(bt.blng__BillingSchedule__c);
                        if(oppbtbsMap.containsKey(orderRec.OpportunityId + ':'+ bt.blng__BillingTargetDate__c + ':' + oiId)) {
                            TEMP_Order_Migration__c omRec = oppbtbsMap.get(orderRec.OpportunityId + ':'+ bt.blng__BillingTargetDate__c + ':' + oiId);
                            omRec.IOM_Billing_Schedule__c = bt.blng__BillingSchedule__c;
                            omRec.IOM_Billing_Transaction__c = bt.Id;
                            omRec.Status__c = 'In Progress';
                            omRec.Stage__c = 'Step 04';
                            omList.add(omRec);            
                        }
                    }
                
                    PaymentTermOnOrder_Trig.setPaymentTermOnOrderFromOrderItem(orderRec.Id);
                } catch(Exception e) {
                    System.debug(e.getMessage());
                    for(blng__BillingSchedule__c bs: bsList) {
                        for(Integer i = 0;i < nbrOfTransaction;i++) {
                            if(oppbtbsMap.containsKey(orderRec.OpportunityId + ':'+ invDates[i] + ':' + bs.blng__OrderProduct__c)) {
                                TEMP_Order_Migration__c omRec = oppbtbsMap.get(orderRec.OpportunityId + ':'+ invDates[i] + ':' + bs.blng__OrderProduct__c);
                                omRec.Status__c = 'Error';
                                omRec.Stage__c = 'Step 03';
                                omList.add(omRec);            
                            }
                        }
                    }
                }
            } else {
                System.debug('Check the order - ' + orderRec.Id);
            }
        }
        
        System.debug('Number of Order Migration Records = ' + omList.size());
        update omList;
    }


    //@description  Scripts to run IM Org
	public static void Script_IM_05A_InvoiceScheduler() {
        //05A_Invoice_Scheduler.cls
          for(Integer i=1;i<=10;i++) {
            Set<Date> invDates = new Set<Date>();
            String invBatch = 'DM '+i;
            for(TEMP_Order_Migration__c tempRecord: [SELECT Id, CRM_Invoice_Date__c, Stage__c 
                                                       FROM TEMP_Order_Migration__c 
                                                      WHERE Status__c = 'In Progress' 
                                                        AND Stage__c = 'Step 04'
                                                        AND CRM_Invoice_Status__c = 'Posted' 
                                                        AND IOM_Billing_Schedule__c <> NULL 
                                                        AND IOM_Invoice__c = null AND IOM_Order__r.blng__InvoiceBatch__c=:invBatch]) {
                invDates.add(tempRecord.CRM_Invoice_Date__c);
            }
            InvoiceRunDataMigration_Trig.invokeDataMigrationSchedulers(invDates,invBatch);
        }
    }


    //@description  Scripts to run IM Org
    public static void Script_IM_05B_Inv_InvLine_Update() {
        //05B_Inv_InvLine_Update script
            List<TEMP_Order_Migration__c> omList = new List<TEMP_Order_Migration__c>();
            List<TEMP_Order_Migration__c> omRefList = new List<TEMP_Order_Migration__c>();
            
            Set<Date> invDates = new Set<Date>();
            // Get all the invoices date to be scheduled
            for(TEMP_Order_Migration__c tempRecord: [SELECT Id, CRM_Invoice_Date__c, Stage__c 
                                                       FROM TEMP_Order_Migration__c 
                                                      WHERE Status__c = 'In Progress' 
                                                        AND Stage__c = 'Step 04' 
                                                        AND IOM_Invoice__c = NULL]) {
                invDates.add(tempRecord.CRM_Invoice_Date__c);
            }
            
            // Limit for the 25 Orders update in 1 go
            Set<Date> limitInvDates = new Set<Date>();
            for(Date invDate: invDates) {
                if(limitInvDates.size() < 15) {
                    limitInvDates.add(invDate);
                }
            }
            
            for(Date invDate: limitInvDates) {
                System.debug('Processing for ' + invDate);
                // tempRecord.CRM_Invoice_Date__c
                datetime sd = invDate;
                // Update Invoice Line and Invoice for the invoice group date
                Date invSchedulerDate = Date.newInstance(sd.year(),sd.month(),sd.day());
                // Collect the Billing Txns based on the Invoice Scheduler Target Date
                Set<Id> btIds = new Set<Id>();
                List<TEMP_Order_Migration__c> omRefList = new List<TEMP_Order_Migration__c>();
                for(TEMP_Order_Migration__c migRec: [SELECT Id, Name, CRM_Opportunity_Id__c, CRM_Opportunity_Name__c, CRM_IOM_Opportunity_Number__c, CRM_Invoice_Id__c, 
                                                            CRM_Invoice_Name__c, CRM_Invoice_Date__c, CRM_Due_Date__c, CRM_SAP_Order_Id__c, CRM_Invoice_Status__c, CRM_Product_Name__c, 
                                                            IOM_Billing_Schedule__c, IOM_Opportunity__c, IOM_Billing_Transaction__c, IOM_Order__c, IOM_Order_Product__c,
                                                            IOM_Invoice__c, IOM_Invoice_Line__c, Status__c, Stage__c, CRM_Invoice_Number_Text__c  
                                                    FROM TEMP_Order_Migration__c 
                                                    WHERE CRM_Invoice_Date__c = :invSchedulerDate 
                                                      AND Status__c = 'In Progress' 
                                                      AND Stage__c = 'Step 04' 
                                                      AND IOM_Billing_Transaction__c <> NULL]) {
                    btIds.add(migRec.IOM_Billing_Transaction__c);
                    omRefList.add(migRec);
                }
            
                System.debug('Got Migration Records ' + omRefList.size());
                // Get the Invoice Line and Invoice
                Map<Id, blng__InvoiceLine__c> bt_il_Map = new Map<Id, blng__InvoiceLine__c>();
                for(blng__InvoiceLine__c ilRec : [SELECT Id, blng__ChargeDate__c, blng__Invoice__c, blng__Invoice__r.blng__InvoiceDate__c, 
                                                        blng__Invoice__r.blng__InvoiceStatus__c, blng__Invoice__r.IM_Invoice_No__c, 
                                                        blng__Invoice__r.ERP_Sync_Status__c, blng__Invoice__r.blng__ARStatus__c, 
                                                        blng__Invoice__r.Order_Hub_Sync_Status__c, blng__Invoice__r.blng__TargetDate__c, 
                                                        blng__Invoice__r.ERP_Reference__c, blng__BillingTransaction__c 
                                                    FROM blng__InvoiceLine__c WHERE blng__BillingTransaction__c IN :btIds AND blng__Invoice__r.blng__InvoiceStatus__c = 'Draft']) {
                    bt_il_Map.put(ilRec.blng__BillingTransaction__c, ilRec);
                }
                System.debug('Got BT & IL Records ' + bt_il_Map.size());
            
                List<blng__Invoice__c> invList = new List<blng__Invoice__c>();
                Set<Id> invIds = new Set<Id>();
                for(TEMP_Order_Migration__c omRec : omRefList) {
                    if(bt_il_Map.containsKey(omRec.IOM_Billing_Transaction__c)) {
                        // System.debug('Found matching BT to IL');
                        blng__InvoiceLine__c ilRec = bt_il_Map.get(omRec.IOM_Billing_Transaction__c); 
                        omRec.IOM_Invoice__c = ilRec.blng__Invoice__c;
                        omRec.IOM_Invoice_Line__c = ilRec.Id;
                        omRec.Stage__c = 'Step 05B';
                        omList.add(omRec);
            
                        // Set the Invoice with correct date & GE Number
                        if(!invIds.contains(ilRec.blng__Invoice__c)) {
                            invIds.add(ilRec.blng__Invoice__c);
                    
                            blng__Invoice__c inv = new blng__Invoice__c();
                            inv.Id = ilRec.blng__Invoice__c;
                            inv.blng__InvoiceDate__c = omRec.CRM_Invoice_Date__c; // ilRec.blng__Invoice__r.blng__TargetDate__c;
                            inv.blng__DueDate__c = omRec.CRM_Due_Date__c;
                            // inv.ERP_Reference__c = omRec.CRM_SAP_Order_Id__c;
                            inv.Invoice_Number_Text__c = omRec.CRM_Invoice_Number_Text__c;
                            invList.add(inv);
                        }
                    }
                }
            
                System.debug('Number of Invoice Records = ' + invList.size());
                update invList;
            }
            
            System.debug('Number of Order Migration Records = ' + omList.size());
            update omList;
    }


    //@description  Scripts to run IM Org
    public static void Script_IM_05C_Invoice_Posted_Update() {
        //script 05C_Invoice_Posted_Update
          Set<String> iomOppNumbers = new Set<String>();
        // Invoice Status Update
        Set<Date> invDates = new Set<Date>();
        Set<String> invNameSet = new Set<String>();
        
        // Get all the invoices date to be scheduled
        for(TEMP_Order_Migration__c tempRecord: [SELECT Id, CRM_Invoice_Number_Text__c, CRM_Invoice_Date__c, Stage__c 
                                                   FROM TEMP_Order_Migration__c 
                                                  WHERE Status__c = 'In Progress' 
                                                    AND Stage__c = 'Step 05B'
                                                    AND IOM_Invoice_Line__c <> NULL]) {
            invDates.add(tempRecord.CRM_Invoice_Date__c);
            invNameSet.add(tempRecord.CRM_Invoice_Number_Text__c);
        }
        
        // Limit for the 25 Orders update in 1 go
        Set<Date> limitInvDates = new Set<Date>();
        for(Date invDate: invDates) {
            if(limitInvDates.size() < 10) {
                limitInvDates.add(invDate);
            }
        }
        
        // Limit for the 25 Orders update in 1 go
        Set<String> limitInvNames = new Set<String>();
        for(String invName: invNameSet) {
            if(limitInvNames.size() < 25) {
                limitInvNames.add(invName);
            }
        }
        
        List<TEMP_Order_Migration__c> omList = new List<TEMP_Order_Migration__c>();
        List<blng__Invoice__c> invList = new List<blng__Invoice__c>();
        
        for(Date invDate: limitInvDates) {
            for(TEMP_Order_Migration__c migRec: [SELECT Id, Name, CRM_Opportunity_Id__c, CRM_Opportunity_Name__c, CRM_IOM_Opportunity_Number__c, CRM_Invoice_Id__c, 
                                                        CRM_Invoice_Name__c, CRM_Invoice_Date__c, CRM_Due_Date__c, CRM_SAP_Order_Id__c, CRM_Invoice_Status__c, CRM_Product_Name__c, 
                                                        IOM_Billing_Schedule__c, IOM_Opportunity__c, IOM_Billing_Transaction__c, IOM_Order__c, IOM_Order_Product__c,
                                                        IOM_Invoice__c, IOM_Invoice_Line__c, Status__c, Stage__c 
                                                FROM TEMP_Order_Migration__c 
                                                WHERE CRM_Invoice_Date__c = :invDate 
                                                  AND Status__c = 'In Progress' 
                                                  AND Stage__c = 'Step 05B' 
                                                  AND IOM_Invoice_Line__c <> NULL
                                                  AND CRM_Invoice_Number_Text__c IN :limitInvNames]) {
                migRec.Status__c = 'Migrated';
                migRec.Stage__c = 'Step 05C';
                iomOppNumbers.add(migRec.CRM_IOM_Opportunity_Number__c);
                omList.add(migRec);
            }
        
            for(blng__Invoice__c inv: [SELECT Id, blng__InvoiceStatus__c 
                                        FROM blng__Invoice__c 
                                        WHERE blng__Order__r.Opportunity.Opportunity_Number__c IN :iomOppNumbers 
                                          AND blng__InvoiceStatus__c = 'Draft' 
                                          AND blng__InvoiceDate__c =: invDate
                                          AND Invoice_Number_Text__c IN :limitInvNames]) {
                inv.blng__InvoiceStatus__c = 'Posted';
                invList.add(inv);
            }
        }
        
        System.debug('Number of Invoice Records = ' + invList.size());
        update invList;
        
        System.debug('Number of Order Migration Records = ' + omList.size());
        update omList;
    }


    //@description  Scripts to run GE Org
    public static void Script_GE_03_Opportunity_Updates(){
        //03_Opportunity_Updates
        // Get the Events identified for Migration
        Date dmDate = Date.newInstance(2023, 05, 23);
        Set<Id> eventIds = new Set<Id>();
        for(Event_Edition__c ee: [SELECT Id FROM Event_Edition__c WHERE IOM_Data_Migration_Date__c =:dmDate]) {
            eventIds.add(ee.Id);
        }
        // List of Opps to be skipped
        Set<Id> oppIds = new Set<Id>();

        //oppIds.add('006D600000XdLnyIAF');
        //oppIds.add('006D600000XdLnzIAF');
        //oppIds.add('006D600000XdLPFIA3');
        //oppIds.add('006D600000XdLPvIAN');


        // Get the opportunities to be updated
        List<Opportunity> oppList = new List<Opportunity>();

        for(Opportunity opp: [Select Id, AccountId, IOM_Do_not_send_for_Billing__c FROM Opportunity WHERE EventEdition__c IN :eventIds AND StageName = 'Closed Won' AND IOM_Opportunity_No__c = null AND Do_Not_activate_Billing__c = true order by EventEdition__c, LastModifiedDate]) {
            if(opp.IOM_Do_not_send_for_Billing__c == false) {
                opp.IOM_Do_not_send_for_Billing__c = true;
                oppList.add(opp);
            }
        }

        System.debug('# of Opportunities to be updated = ' + oppList.size());
        update oppList;
    }


    //@description  Scripts to run GE Org
    public static void Script_GE_04_Opportunity_Type_Updates(){
        //04_Opportunity_Type_Updates
        // Get the Events identified for Migration
        Date dmDate = Date.newInstance(2023, 05, 23);
        Set<Id> eventIds = new Set<Id>();
        for(Event_Edition__c ee: [SELECT Id FROM Event_Edition__c WHERE IOM_Data_Migration_Date__c =:dmDate]) {
            eventIds.add(ee.Id);
        }
        // List of Opps to be skipped
        Set<Id> oppIds = new Set<Id>();

        // Get the opportunities to be updated
        List<Opportunity> oppList = new List<Opportunity>();

        for(Opportunity opp: [Select Id, Type, AccountId FROM Opportunity WHERE EventEdition__c IN :eventIds AND StageName = 'Closed Won' AND Status__c = 'Awaiting Payment' AND IOM_Opportunity_No__c = null AND Type = NULL AND Id NOT IN :oppIds order by EventEdition__c, LastModifiedDate]) {
            if(opp.AccountId <> NULL) {
                opp.Type = 'New';
                oppList.add(opp);
            } else {
                oppIds.add(opp.Id);
                System.debug('Missing Account Id for Opportunity ' + opp.Id);
            }
        }

        System.debug('# of Opportunities to be updated = ' + oppList.size());

        // System.debug(oppList);
        update oppList;
    }


    //@description  Scripts to run GE Org
    public static void Script_GE_05_Opp_Bill_To_Account_Updates() {
        //05_Opp_Bill_To_Account_Updates
        // Get the Events identified for Migration
        Date dmDate = Date.newInstance(2023, 05, 23);
        Set<Id> eventIds = new Set<Id>();
        for(Event_Edition__c ee: [SELECT Id FROM Event_Edition__c WHERE IOM_Data_Migration_Date__c =:dmDate]) {
            eventIds.add(ee.Id);
        }
        // List of Opps to be skipped
        Set<Id> oppIds = new Set<Id>();

        // Get the opportunities to be updated
        List<Opportunity> oppList = new List<Opportunity>();

        for(Opportunity opp: [SELECT Id, AccountId, Billing_Contact__r.AccountId, IOM_Bill_To_Account__c FROM Opportunity WHERE EventEdition__c IN :eventIds AND StageName = 'Closed Won' AND Status__c = 'Awaiting Payment' AND IOM_Opportunity_No__c = NULL AND IOM_Bill_To_Account__c = NULL AND Id NOT IN :oppIds order by EventEdition__c, LastModifiedDate]) {
            if(opp.AccountId <> NULL) {
                opp.IOM_Bill_To_Account__c = opp.Billing_Contact__r.AccountId;
                oppList.add(opp);
            } else {
                oppIds.add(opp.Id);
                System.debug('Missing Account Id for Opportunity ' + opp.Id);
            }
        }

        System.debug('# of Opportunities to be updated = ' + oppList.size());

        // System.debug(oppList);
        update oppList;
    }


    //@description  Scripts to run GE Org
    public static void Script_GE_06_QLI_Date_Updates() {
        //05C_06_QLI_Date_Updates.cls
        //Get the Events identified for Migration
        Date dmDate = Date.newInstance(2023, 05, 23);
        Set<Id> eventIds = new Set<Id>();
        for(Event_Edition__c ee: [SELECT Id FROM Event_Edition__c WHERE IOM_Data_Migration_Date__c =:dmDate]) {
            eventIds.add(ee.Id);
        }
        // List of Opps to be skipped
        Set<Id> oppIds = new Set<Id>();

        // Get the opportunities to be updated
        List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
        List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c>();

        for(OpportunityLineItem oli: [Select Id, IOM_OLI_Number__c, SBQQ__QuoteLine__c, SBQQ__QuoteLine__r.Start_Date__c, SBQQ__QuoteLine__r.End_Date__c, Start_Date__c, End_Date__c, Opportunity.Type, Opportunity.EventEdition__r.Start_Date__c, Opportunity.EventEdition__r.End_Date__c, OpportunityId FROM OpportunityLineItem WHERE OpportunityId IN (SELECT Id FROM Opportunity WHERE EventEdition__c IN :eventIds AND StageName = 'Closed Won' AND Status__c = 'Awaiting Payment' AND IOM_Opportunity_No__c = null AND Id NOT IN :oppIds) AND (Start_Date__c = NULL OR End_Date__c = NULL)]) {
            if(oli.SBQQ__QuoteLine__c <> NULL && (oli.SBQQ__QuoteLine__r.Start_Date__c == NULL || oli.SBQQ__QuoteLine__r.End_Date__c == NULL)) {
                // System.debug('QLI to be updated = ' + oli.SBQQ__QuoteLine__c);
                SBQQ__QuoteLine__c qli = new SBQQ__QuoteLine__c();
                qli.Id = oli.SBQQ__QuoteLine__c;
                qli.Start_Date__c = oli.Opportunity.EventEdition__r.Start_Date__c;
                qli.End_Date__c = oli.Opportunity.EventEdition__r.End_Date__c;
                qliList.add(qli);
            }

            if(oli.Start_Date__c == NULL || oli.End_Date__c == NULL) {
                // System.debug('OLI to be updated = ' + oli.Id);
                OpportunityLineItem oli_new = new OpportunityLineItem();
                oli_new.Id = oli.Id;
                oli_new.Start_Date__c = oli.Opportunity.EventEdition__r.Start_Date__c;
                oli_new.End_Date__c = oli.Opportunity.EventEdition__r.End_Date__c;
                oliList.add(oli_new);
            }
        }

        System.debug('# of QLI to be updated = ' + qliList.size());
        System.debug('# of OLI to be updated = ' + oliList.size());

        // System.debug(qliList);
        update qliList;

        // System.debug(oliList);
        update oliList;
    }


    //@description  Scripts to run GE Org
    public static void Script_GE_07_OLI_DNB_Updates() {
        //07_OLI_DNB_Updates
        // Get the Events identified for Migration
        Date dmDate = Date.newInstance(2023, 05, 23);
        Set<Id> eventIds = new Set<Id>();
        for(Event_Edition__c ee: [SELECT Id FROM Event_Edition__c WHERE IOM_Data_Migration_Date__c =:dmDate]) {
            eventIds.add(ee.Id);
        }
        // List of Opps to be skipped
        Set<Id> oppIds = new Set<Id>();


        //Product 2 fields

        //IOM_Do_not_send_for_Billing__c - Flag
        //IOM_ERP_Hidden_when__c - Picklist
        //IOM_ProductCode_Text__c - Text
        //IOM_Tobe_Hidden_in_ERP__c - Flag4


        // Get the QLI to be updated
        List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c>();

        for(SBQQ__QuoteLine__c qli: [Select Id, SBQQ__Product__c, SBQQ__Product__r.IOM_Tobe_Hidden_in_ERP__c, SBQQ__Product__r.IOM_ERP_Hidden_when__c, IOM_Tobe_Hidden_in_ERP__c, IOM_ERP_Hidden_when__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c IN (SELECT SBQQ__PrimaryQuote__c FROM Opportunity WHERE EventEdition__c IN :eventIds AND StageName = 'Closed Won' AND Status__c = 'Awaiting Payment' AND IOM_Opportunity_No__c = null AND Id NOT IN :oppIds) AND SBQQ__Product__r.IOM_Tobe_Hidden_in_ERP__c = TRUE]) {
            // System.debug('OLI to be updated = ' + oli.Id);
            SBQQ__QuoteLine__c qli_new = new SBQQ__QuoteLine__c();
            qli_new.Id = qli.Id;
            qli_new.IOM_Tobe_Hidden_in_ERP__c = true;
            qli_new.IOM_ERP_Hidden_when__c = qli.SBQQ__Product__r.IOM_ERP_Hidden_when__c;
            qliList.add(qli_new);
        }

        // Get the OLI to be updated
        List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();

        for(OpportunityLineItem oli: [Select Id, Product2Id, Product2.IOM_Do_not_send_for_Billing__c, IOM_Do_not_send_for_Billing__c FROM OpportunityLineItem WHERE OpportunityId IN (SELECT Id FROM Opportunity WHERE EventEdition__c IN :eventIds AND StageName = 'Closed Won' AND Status__c = 'Awaiting Payment' AND IOM_Opportunity_No__c = null AND Id NOT IN :oppIds) AND Product2.IOM_Do_not_send_for_Billing__c = TRUE]) {
            // System.debug('OLI to be updated = ' + oli.Id);
            OpportunityLineItem oli_new = new OpportunityLineItem();
            oli_new.Id = oli.Id;
            oli_new.IOM_Do_not_send_for_Billing__c = true;
            oliList.add(oli_new);
        }

        System.debug('# of QLI to be updated = ' + qliList.size());
        System.debug('# of OLI to be updated = ' + oliList.size());

        // System.debug(qliList);
        update qliList;

        // System.debug(oliList);
        update oliList;
    }


    //@description  Scripts to run GE Org
    public static void Script_GE_08_Opportunity_Sync() {
        //08_Opportunity_Sync.class
        // Get the Events identified for Migration
        Date dmDate = Date.newInstance(2023, 05, 23);
        Set<Id> eventIds = new Set<Id>();
        for(Event_Edition__c ee: [SELECT Id FROM Event_Edition__c WHERE IOM_Data_Migration_Date__c =:dmDate]) {
            eventIds.add(ee.Id);
        }
        // List of Opps to be skipped
        Set<Id> oppIds = new Set<Id>();

        // Get the opportunities to be updated
        List<Opportunity> oppList = new List<Opportunity>();

        for(Opportunity opp: [Select Id, AccountId, IOM_Do_not_send_for_Billing__c, IOM_Ready_For_Ordering__c FROM Opportunity WHERE EventEdition__c IN :eventIds AND AccountId <> NULL AND StageName = 'Closed Won' AND Status__c = 'Awaiting Payment' AND IOM_Opportunity_No__c = NULL AND IOM_Ready_For_Ordering__c = NULL AND Id NOT IN :oppIds]) {
            opp.IOM_Do_not_send_for_Billing__c = false;
            opp.IOM_Ready_For_Ordering__c = 'Yes';
            oppList.add(opp);
        }

        System.debug('# of Opportunities to be updated = ' + oppList.size());
        update oppList;
    }*/
}