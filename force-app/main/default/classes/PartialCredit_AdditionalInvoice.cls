/**
* File:         PartialCredit_AdditionalInvoice
* Project:      PoC SFDC Informa 
* Test Class:   PartialCredit_AdditionalInvoiceTest
* Coverage:     99%
* *******************************************************************************************************
* @description : This code will deal with the 4 PC/AI sceanarios
SCENARIO 1 : DOWNGRADE PRODUCT
SCENARIO 2 : UPGRADE PRODUCT
SCENARIO 3 : ADDITION OF A PRODUCT
SCENARIO 4 : REMOVAL OF A PRODUCT

* @author: Ayoub Ouarti (aouarti@salesforce.com)
* @date: 20/01/2020
* *******************************************************************************************************
History
-------
VERSION     AUTHOR              DATE            DETAIL
1.0     SF(Ayoub Ouarti)    20/01/2020    	Initial Dev
2.0     SF(Ayoub Ouarti)    12/02/2020    	Fix P1 & P2 issues
3.0     SF(Ayoub Ouarti)   	14/02/2020    	Fix issue with Percentages + Credit Note Line P1
4.0 	Girikon(Ashish)		17 March-20		Fixed issue with invoice Lines [IML2R-1304]
5.0 	Girikon(Deepak)		26 March-20		Fixed issue with invoice Lines [IML2R-2008]
6.0     Girikon(Ashish)     11 April 2023   [GECI-679] added start/End date to BT from Order Products
* *******************************************************************************************************/

public class  PartialCredit_AdditionalInvoice {
    
    public static  void Create_PartialCredit_OR_AddtionalInvoice(Order order ){
        // Get All order Product with Invoice Plan for the New Order
        List<OrderItem> orderItems =  Database.query('SELECT  ServiceDate,EndDate,SBQQ__QuoteLine__r.SBQQ__Source__c ,PC_AI_Sub_scenario__c,Upgrade_Downgrade_Delta_Amount__c,SBQQ__QuoteLine__r.SBQQ__RequiredBy__c ,SBQQ__RequiredBy__c ,OrderItemNumber,SBQQ__RevisedOrderProduct__r.TotalPrice,Linked_Order_Item_for_PC_AI__r.SBQQ__RevisedOrderProduct__c,Linked_Order_Item_for_PC_AI__c ,SBQQ__BundleRoot__c,Product2Id , SBQQ__RevisedOrderProduct__c,OriginalOrderItemId,Issue_Date__c,SBQQ__Activated__c,OrderId,Payment_Term_used_for_BT_Calculation__c,Product_Invoice_property__c, Payment_Term__c,Quantity , blng__InvoiceRunProcessingStatus__c  ,Edition__c ,TotalPrice,SBQQ__QuoteLine__c ,SBQQ__BillingFrequency__c  FROM OrderItem where SBQQ__BillingFrequency__c = \'Invoice Plan\' and OrderId = \''+String.escapeSingleQuotes(order.Id)+'\'');
        List<String> originalOrderItemIds = new List<String>();
        String originalOrderId = null;
        for(OrderItem oi : orderItems){
            if(oi.Quantity<=0 && !originalOrderItemIds.contains(oi.SBQQ__RevisedOrderProduct__c) && oi.SBQQ__RevisedOrderProduct__c!= null){
                originalOrderItemIds.add(oi.SBQQ__RevisedOrderProduct__c);
            }
        }
        
        List<OrderItem> originalOrderItems =  Database.query('SELECT ServiceDate,EndDate,SBQQ__QuoteLine__r.SBQQ__Source__c,PC_AI_Sub_scenario__c,Upgrade_Downgrade_Delta_Amount__c,SBQQ__QuoteLine__r.SBQQ__RequiredBy__c,SBQQ__RequiredBy__c ,OrderItemNumber,SBQQ__RevisedOrderProduct__r.TotalPrice,Linked_Order_Item_for_PC_AI__r.SBQQ__RevisedOrderProduct__c, Linked_Order_Item_for_PC_AI__c ,SBQQ__BundleRoot__c,Product2Id,SBQQ__RevisedOrderProduct__c,OrderId,OriginalOrderItemId,Issue_Date__c,SBQQ__Activated__c,Payment_Term_used_for_BT_Calculation__c,Product_Invoice_property__c, Payment_Term__c,Quantity , blng__InvoiceRunProcessingStatus__c  ,Edition__c ,TotalPrice,SBQQ__QuoteLine__c ,SBQQ__BillingFrequency__c  FROM OrderItem where Id in :originalOrderItemIds');
        if(OriginalOrderId==null && originalOrderItems.size()>0){
            originalOrderId = originalOrderItems.get(0).OrderId;
        }
        
        Map<Id,OrderItem> mapOriginalOrderItemWithId = new Map<Id,OrderItem>(originalOrderItems);
        List<OrderItem> orderProductToUpdate = new List<OrderItem>();
        // for the New Order , Set for each Order Item the Original Order Item based on the Edition , Product and SBQQ__RequiredBy__c  if exist
        list<String> listOfInvoiceLInes = new List<String>();
        
        List<OrderItem> negatifOrderItem = new List<OrderItem>();
        List<OrderItem> positifOrderItem = new List<OrderItem>();
        
        for(OrderItem eachOrderItem : orderItems){  
            if(eachOrderItem.Quantity<0)  {
                negatifOrderItem.add(eachOrderItem); 
            }
            else if(eachOrderItem.Quantity>0)  {
                positifOrderItem.add(eachOrderItem); 
            }
        }
        for(OrderItem eachOrderItem : negatifOrderItem){  
            for(OrderItem eachOrderItem2 : positifOrderItem){  
                if(eachOrderItem.Id!=eachOrderItem2.Id 
                   && eachOrderItem.Product2Id == eachOrderItem2.Product2Id 
                   && eachOrderItem.Edition__c == eachOrderItem2.Edition__c
                   && ((eachOrderItem.SBQQ__QuoteLine__r.SBQQ__RequiredBy__c  == null   
                        && ( eachOrderItem2.SBQQ__QuoteLine__r.SBQQ__Source__c!=null && eachOrderItem2.SBQQ__QuoteLine__r.SBQQ__Source__c ==  eachOrderItem.SBQQ__QuoteLine__r.SBQQ__Source__c))
                       || (eachOrderItem.SBQQ__QuoteLine__r.SBQQ__RequiredBy__c  != null && eachOrderItem2.SBQQ__QuoteLine__r.SBQQ__RequiredBy__c ==eachOrderItem.SBQQ__QuoteLine__r.SBQQ__RequiredBy__c )
                      )
                  ){
                      eachOrderItem2.Linked_Order_Item_for_PC_AI__c=eachOrderItem.Id;
                      eachOrderItem.Linked_Order_Item_for_PC_AI__c =eachOrderItem2.Id; 
                      orderProductToUpdate.add(eachOrderItem2);
                      orderProductToUpdate.add(eachOrderItem);
                      listOfInvoiceLInes.add(eachOrderItem2.Id);
                      listOfInvoiceLInes.add(eachOrderItem.Id); 
                      break;
                  }
            }
        }

        // update the order item with the original order item
        update orderProductToUpdate;
        // Get the list of the order Product updated with Invoice Plan for the New Order
        orderItems =  Database.query('SELECT ServiceDate,EndDate,PC_AI_Sub_scenario__c,Upgrade_Downgrade_Delta_Amount__c,OrderItemNumber,SBQQ__RevisedOrderProduct__r.TotalPrice,Linked_Order_Item_for_PC_AI__r.SBQQ__RevisedOrderProduct__c,Linked_Order_Item_for_PC_AI__c ,SBQQ__BundleRoot__c,Product2Id,SBQQ__RevisedOrderProduct__c,OriginalOrderItemId,Issue_Date__c,SBQQ__Activated__c,OrderId,Payment_Term_used_for_BT_Calculation__c,Product_Invoice_property__c, Payment_Term__c,Quantity , blng__InvoiceRunProcessingStatus__c  ,Edition__c ,TotalPrice,SBQQ__QuoteLine__c ,SBQQ__BillingFrequency__c  FROM OrderItem where SBQQ__BillingFrequency__c = \'Invoice Plan\' and OrderId = \''+String.escapeSingleQuotes(order.Id)+'\'');
        List<String> orderItemIds = new List<String>();
        //gather the OrderIds
        for(OrderItem oi : orderItems){
            if(!orderItemIds.contains(oi.Id)){
                orderItemIds.add(oi.Id);
            }
        }
        // get The Billing schedule for the Original order's order products
        List<blng__BillingSchedule__c> billingScheduleFromBD = Database.query('SELECT Name,Payment_Term_Reason__c,Billing_Schedule_Reason__c, blng__Amount__c,  blng__OrderProduct__c FROM blng__BillingSchedule__c WHERE blng__OrderProduct__c in :originalOrderItemIds ');
        List<String> billingScheduleFromBDIds = new List<String>();
        for(blng__BillingSchedule__c bs : billingScheduleFromBD){
            if(!billingScheduleFromBDIds.contains(bs.Id)){
                billingScheduleFromBDIds.add(bs.Id);
            } 
        }
        Map<Id,List<blng__BillingTransaction__c>> mapBillingTransactionWithOrderItemId = new Map<Id,List<blng__BillingTransaction__c>>();
        //get The Billinf transaction for each order item related to the Original Order
        List<blng__BillingTransaction__c> billingTransactionFromBD = Database.query('SELECT blng__OverrideStatus__c,PC_AI_Original_Invoice_Line__r.blng__LegalEntity__c,PC_AI_Original_Invoice_Line__r.blng__Invoice__c,PC_AI_Original_Invoice_Line__r.blng__Subtotal__c,PC_AI_Original_Invoice_Line__r.blng__TaxAmount__c,PC_AI_Original_Invoice_Line__r.blng__TaxPercentageApplied__c,PC_AI_Original_Invoice_Line__c ,Amendment_Adjustment__c ,CurrencyIsoCode,blng__BillingSchedule__c,blng__Amount__c , Name , blng__Status__c , blng__BillingTargetDate__c , Billing_sequence__c ,  Billing_Percentage__c , blng__Quantity__c FROM blng__BillingTransaction__c WHERE blng__BillingSchedule__c in :billingScheduleFromBDIds');
        List<String> billngTransactionIds = new List<String>();
        //Map each order item with the sum of Billed BT's Percentages
        Map<Id,Decimal> mapOrderItemWithBilledPercantages = new Map<Id,Decimal>();
        //Map each order item with the number of Billed BT
        Map<Id,Integer> mapOrderItemWithNumberOfBilledBTs = new Map<Id,Integer>();
        Integer nbrOfTransaction = 0;
        Integer lastBilledTransaction=0;
        // Map the billing transactionn with the related order item (using the billing schedules)
        for(blng__BillingSchedule__c  bs : billingScheduleFromBD){
            lastBilledTransaction=0;
            for(blng__BillingTransaction__c bt : billingTransactionFromBD){
                if(!billngTransactionIds.contains(bt.Id)){
                    billngTransactionIds.add(bt.Id);
                }
                if(bs.Id == bt.blng__BillingSchedule__c ){
                    if(mapBillingTransactionWithOrderItemId.get(bs.blng__OrderProduct__c)==null){
                        mapBillingTransactionWithOrderItemId.put(bs.blng__OrderProduct__c, new List<blng__BillingTransaction__c>());
                        mapBillingTransactionWithOrderItemId.get(bs.blng__OrderProduct__c).add(bt);
                        if('Billed'.equals(bt.blng__Status__c) || 'Cancelled'.equals(bt.blng__OverrideStatus__c) && 'Cancelled BT for Invoiced Amount'.equals(bt.Amendment_Adjustment__c )){
                            mapOrderItemWithBilledPercantages.put(bs.blng__OrderProduct__c,bt.Billing_Percentage__c);
                        }
                        if('Billed'.equals(bt.blng__Status__c)){
                            if(lastBilledTransaction<integer.valueof( ((String)bt.Name).substring( ((String)bt.Name).length() -1, ((String)bt.Name).length() ))){
                                lastBilledTransaction=integer.valueof( ((String)bt.Name).substring( ((String)bt.Name).length() -1, ((String)bt.Name).length() ));
                            }
                        }
                    }
                    else if(!mapBillingTransactionWithOrderItemId.get(bs.blng__OrderProduct__c).contains(bt)){
                        mapBillingTransactionWithOrderItemId.get(bs.blng__OrderProduct__c).add(bt);
                        if('Billed'.equals(bt.blng__Status__c)){
                            if(lastBilledTransaction<integer.valueof( ((String)bt.Name).substring( ((String)bt.Name).length() -1, ((String)bt.Name).length() ))){
                                lastBilledTransaction=integer.valueof( ((String)bt.Name).substring( ((String)bt.Name).length() -1, ((String)bt.Name).length() ));
                            }
                        }
                        if('Billed'.equals(bt.blng__Status__c) || 'Cancelled'.equals(bt.blng__OverrideStatus__c) && 'Cancelled BT for Invoiced Amount'.equals(bt.Amendment_Adjustment__c )){
                            mapOrderItemWithBilledPercantages.put(bs.blng__OrderProduct__c,mapOrderItemWithBilledPercantages.get(bs.blng__OrderProduct__c)+ bt.Billing_Percentage__c);
                        } else {
                            nbrOfTransaction = integer.valueof( ((String)bt.Billing_sequence__c).substring( ((String)bt.Billing_sequence__c).length() -1, ((String)bt.Billing_sequence__c).length() ));
                        }
                    }
                }
            }
            mapOrderItemWithNumberOfBilledBTs.put(bs.blng__OrderProduct__c,lastBilledTransaction);
        }
        List<blng__InvoiceLine__c> billingTransactionInvoiceLines = Database.query('SELECT Id,blng__Invoice__r.blng__BillToContact__c,blng__Invoice__c , blng__BillingTransaction__c,blng__Subtotal__c,blng__TaxAmount__c,blng__TaxPercentageApplied__c,blng__LegalEntity__c FROM blng__InvoiceLine__c WHERE blng__BillingTransaction__c  in :billngTransactionIds ');// Added fields blng__Subtotal__c,blng__TaxAmount__c,blng__TaxPercentageApplied__c for Bug Fix [IML2R-2008]
        Map<Id,blng__InvoiceLine__c> mapBillingTransactionWithInvoicLine = new Map<Id,blng__InvoiceLine__c>();
        //Map BT with Invoice line
        for(blng__InvoiceLine__c eachInvoiceLine : billingTransactionInvoiceLines){
            if(mapBillingTransactionWithInvoicLine.get(eachInvoiceLine.blng__BillingTransaction__c)==null){                
                mapBillingTransactionWithInvoicLine.put(eachInvoiceLine.blng__BillingTransaction__c,eachInvoiceLine);
            }
        }
        List<blng__CreditNoteLine__c> listOfCreditNoteLine;
        List<blng__InvoiceLine__c> listOfInvoiceLine;
        Decimal newAmount = 0;
        blng__CreditNote__c creditNote = null;
        Decimal amountToBeIvoiced = 0;
        Map<Id,blng__BillingTransaction__c> mapOfBillingTransactionToUpdate = new Map<Id,blng__BillingTransaction__c>();
        blng__BillingSchedule__c billingSchedule = new blng__BillingSchedule__c();
        List<blng__CreditNote__c> listOfCreditNote = new List<blng__CreditNote__c>();
        Decimal sumPercentages = 0;
        Decimal deltaAmount = 0;
        Decimal deltaOrderAmount = 0;
        listOfCreditNoteLine = new List<blng__CreditNoteLine__c>();
        List<OrderItem> listOrderItemToGenerateBTs = new List<OrderItem>();
        orderProductToUpdate = new List<Orderitem>();
        creditNote = new blng__CreditNote__c();
        Map<Id,blng__CreditNote__c> mapInvoiceWithCreditNote = new Map<Id,blng__CreditNote__c>();
        Id invoiceId = null;
        Id invoiceLineId = null;
        blng__BillingTransaction__c billingTransactionToInsert = new blng__BillingTransaction__c();
        List<blng__BillingSchedule__c> listOfBillingSchedule = new List<blng__BillingSchedule__c>();
        Map<Id,List<blng__BillingTransaction__c>>  mapListBillingTransactionWithOrderItem = new Map<Id,List<blng__BillingTransaction__c>>();
        Map<Id,blng__CreditNote__c>  mapCreditNoteWithOrderItem =  new  Map<Id,blng__CreditNote__c>();
        Map<Id,List<blng__CreditNoteLine__c>>  mapListCreditNoteLineWithInvoice =  new  Map<Id,List<blng__CreditNoteLine__c>>();
        List<blng__BillingTransaction__c > listOfBillingTransactionToInsert = new List<blng__BillingTransaction__c >();
        for(OrderItem oi : orderItems){
            if(oi.Quantity>0  ){
                //Adding a new product with a corresponding negative line for the same product,
                //this part of code covers the upgrade or a downgrade scenarios under PC/AI
                if(oi.Linked_Order_Item_for_PC_AI__c!=null){
                    newAmount = 0;
                    amountToBeIvoiced = 0;
                    //SCENARIO 1 : DOWNGRADE PRODUCT
                    if(oi.TotalPrice < mapOriginalOrderItemWithId.get(oi.Linked_Order_Item_for_PC_AI__r.SBQQ__RevisedOrderProduct__c).TotalPrice){
                        System.Debug('SCENARIO 1 : DOWNGRADE PRODUCT');
                        deltaOrderAmount = oi.TotalPrice-mapOriginalOrderItemWithId.get(oi.Linked_Order_Item_for_PC_AI__r.SBQQ__RevisedOrderProduct__c).TotalPrice;
                        oi.Upgrade_Downgrade_Delta_Amount__c = deltaOrderAmount;
                        oi.PC_AI_Sub_scenario__c ='Product Downgrade';
                        oi.Linked_Order_Item_for_PC_AI__r.Upgrade_Downgrade_Delta_Amount__c = deltaOrderAmount;
                        oi.Linked_Order_Item_for_PC_AI__r.PC_AI_Sub_scenario__c='Product Downgrade';
                        orderProductToUpdate.add(oi);
                        orderProductToUpdate.add(oi.Linked_Order_Item_for_PC_AI__r);
                        billingSchedule = new blng__BillingSchedule__c(
                            Name ='BS-'+oi.OrderItemNumber,
                            blng__Amount__c=oi.TotalPrice,
                            blng__OrderProduct__c=oi.Id,
                            CurrencyIsoCode = order.CurrencyIsoCode );
                        listOfBillingSchedule.add(billingSchedule);
                        for(blng__BillingTransaction__c bt : mapBillingTransactionWithOrderItemId.get(oi.Linked_Order_Item_for_PC_AI__r.SBQQ__RevisedOrderProduct__c)){
                            if('Billed'.equals(bt.blng__Status__c)){
                                invoiceId = mapBillingTransactionWithInvoicLine.get(bt.Id).blng__Invoice__c;
                                invoiceLineId=mapBillingTransactionWithInvoicLine.get(bt.Id).Id;
                                if(mapInvoiceWithCreditNote.get(invoiceId)==null){ 
                                    creditNote = new  blng__CreditNote__c(CurrencyIsoCode=bt.CurrencyIsoCode,
                                                                          blng__CreditNoteSourceAction__c='Manual',
                                                                          blng__Account__c =order.AccountId,
                                                                          blng__CreditNoteDate__c=Date.toDay(),
                                                                          blng__Status__c='Draft',
                                                                          blng__Notes__c='Generated as a result of PC/AI downgrade scenarios',
                                                                          blng__RelatedInvoice__c=invoiceId,
                                                                          blng__BillToAccount__c = order.blng__BillingAccount__c,
                                                                          blng__BillToContact__c = order.BillToContactId);
                                    listOfCreditNote.add(creditNote);
                                    mapInvoiceWithCreditNote.put(creditNote.blng__RelatedInvoice__c,creditNote);
                                }
                                listOfCreditNoteLine = mapListCreditNoteLineWithInvoice.get(creditNote.blng__RelatedInvoice__c);
                                if(listOfCreditNoteLine  ==null || listOfCreditNoteLine.size()==0){
                                    listOfCreditNoteLine = new List<blng__CreditNoteLine__c>();
                                }
                                // Added for Bug Fix [IML2R-2008]
                                blng__InvoiceLine__c invLine = mapBillingTransactionWithInvoicLine.get(bt.Id);
                                Decimal creditLineSubtotal = (bt.blng__Amount__c- (bt.Billing_Percentage__c * oi.TotalPrice / 100)).setScale(2);
                                Decimal creditLineTax = 0;
                                if(invLine.blng__Subtotal__c !=null && invLine.blng__Subtotal__c != 0 && invLine.blng__TaxAmount__c != null){
                                    creditLineTax = (invLine.blng__TaxAmount__c * (creditLineSubtotal/invLine.blng__Subtotal__c)).setScale(2);
                                }

                                listOfCreditNoteLine.add(new blng__CreditNoteLine__c(blng__Product__c=oi.Product2Id,
                                                                                     blng__InvoiceLine__c =invoiceLineId,
                                                                                     blng__Subtotal__c=creditLineSubtotal,
                                                                                     blng__TaxAmount__c=creditLineTax,
                                                                                     blng__TaxPercentageApplied__c=invLine.blng__TaxPercentageApplied__c,
                                                                                     blng__LegalEntity__c=invLine.blng__LegalEntity__c));
                                mapListCreditNoteLineWithInvoice.put(creditNote.blng__RelatedInvoice__c,listOfCreditNoteLine);
                                billingTransactionToInsert = new blng__BillingTransaction__c(blng__Amount__c =(bt.Billing_Percentage__c * oi.TotalPrice / 100).setScale(2),
                                                                                             Name = 'Previously Billed Transaction',//+bt.Name,
                                                                                             blng__Status__c ='Pending',
                                                                                             blng__OverrideStatus__c='Cancelled',
                                                                                             blng__BillingTargetDate__c= Date.toDay() ,
                                                                                             Billing_Percentage__c = bt.Billing_Percentage__c,
                                                                                             //blng__BillingSchedule__c=billingSchedule.Id,
                                                                                             blng__Quantity__c = oi.Quantity, 
                                                                                             Amendment_Adjustment__c ='Cancelled BT for Invoiced Amount',
                                                                                             PC_AI_Original_Invoice_Line__c =invoiceLineId,
                                                                                             CurrencyIsoCode = order.CurrencyIsoCode );
                                listOfBillingTransactionToInsert.add(billingTransactionToInsert);
                            }else if('Cancelled'.equals(bt.blng__OverrideStatus__c)  && 'Cancelled BT for Invoiced Amount'.equals(bt.Amendment_Adjustment__c ) && bt.PC_AI_Original_Invoice_Line__c!=null){
                                invoiceId = bt.PC_AI_Original_Invoice_Line__r.blng__Invoice__c;
                                invoiceLineId=bt.PC_AI_Original_Invoice_Line__c;
                                creditNote = new  blng__CreditNote__c(CurrencyIsoCode=bt.CurrencyIsoCode,
                                                                      blng__CreditNoteSourceAction__c='Manual',
                                                                      blng__Account__c =order.AccountId,
                                                                      blng__CreditNoteDate__c=Date.toDay(),
                                                                      blng__Status__c='Draft',
                                                                      blng__Notes__c='Generated as a result of PC/AI downgrade scenarios',
                                                                      blng__RelatedInvoice__c=invoiceId,
                                                                      blng__BillToAccount__c = order.blng__BillingAccount__c,
                                                                      blng__BillToContact__c = order.BillToContactId);
                                listOfCreditNote.add(creditNote);  
                                mapInvoiceWithCreditNote.put(creditNote.blng__RelatedInvoice__c,creditNote);
                                listOfCreditNoteLine = mapListCreditNoteLineWithInvoice.get(creditNote.blng__RelatedInvoice__c);
                                if(listOfCreditNoteLine  ==null || listOfCreditNoteLine.size()==0){
                                    listOfCreditNoteLine = new List<blng__CreditNoteLine__c>();
                                }

                                // Added for Bug Fix [IML2R-2008]
                                Decimal creditLineSubtotal = (bt.blng__Amount__c- (bt.Billing_Percentage__c * oi.TotalPrice / 100)).setScale(2);
                                Decimal creditLineTax = 0;
                                if(bt.PC_AI_Original_Invoice_Line__r.blng__Subtotal__c !=null && bt.PC_AI_Original_Invoice_Line__r.blng__Subtotal__c != 0 && bt.PC_AI_Original_Invoice_Line__r.blng__TaxAmount__c != null){
                                    creditLineTax = (bt.PC_AI_Original_Invoice_Line__r.blng__TaxAmount__c * (creditLineSubtotal/bt.PC_AI_Original_Invoice_Line__r.blng__Subtotal__c)).setScale(2);
                                }

                                listOfCreditNoteLine.add(new blng__CreditNoteLine__c(blng__Product__c=oi.Product2Id,
                                                                                     blng__InvoiceLine__c =invoiceLineId,
                                                                                     blng__Subtotal__c=creditLineSubtotal,
                                                                                     blng__TaxAmount__c=creditLineTax,
                                                                                     blng__TaxPercentageApplied__c=bt.PC_AI_Original_Invoice_Line__r.blng__TaxPercentageApplied__c,
                                                                                     blng__LegalEntity__c=bt.PC_AI_Original_Invoice_Line__r.blng__LegalEntity__c));
                                                                                     
                                mapListCreditNoteLineWithInvoice.put(creditNote.blng__RelatedInvoice__c,listOfCreditNoteLine);

                                billingTransactionToInsert=new blng__BillingTransaction__c(blng__Amount__c =(bt.Billing_Percentage__c * oi.TotalPrice / 100).setScale(2),
                                                                                           Name = bt.Name,
                                                                                           blng__Status__c =bt.blng__Status__c,
                                                                                           blng__OverrideStatus__c=bt.blng__OverrideStatus__c,
                                                                                           blng__BillingTargetDate__c= Date.toDay() ,
                                                                                           Billing_Percentage__c = bt.Billing_Percentage__c,
                                                                                           blng__Quantity__c = bt.blng__Quantity__c, 
                                                                                           Amendment_Adjustment__c =bt.Amendment_Adjustment__c,
                                                                                           PC_AI_Original_Invoice_Line__c =bt.PC_AI_Original_Invoice_Line__c,
                                                                                           CurrencyIsoCode = order.CurrencyIsoCode ); 
                                listOfBillingTransactionToInsert.add(billingTransactionToInsert); 
                            }else{
                                bt.blng__OverrideStatus__c='Cancelled';
                                mapOfBillingTransactionToUpdate.put(bt.Id,bt);
                                billingTransactionToInsert = new blng__BillingTransaction__c(blng__Amount__c =(bt.Billing_Percentage__c * oi.TotalPrice / 100).setScale(2),
                                                                                             Name = bt.Name,
                                                                                             blng__Status__c ='Pending',
                                                                                             blng__BillingTargetDate__c= bt.blng__BillingTargetDate__c ,
                                                                                             Billing_Percentage__c = bt.Billing_Percentage__c,
                                                                                             blng__Quantity__c = oi.Quantity, 
                                                                                             Billing_sequence__c =bt.Billing_sequence__c,
                                                                                             CurrencyIsoCode = order.CurrencyIsoCode );  
                                listOfBillingTransactionToInsert.add(billingTransactionToInsert); 
                            }
                        }

                    }else{
                        //SCENARIO 2 : UPGRADE PRODUCT
                        Decimal previousAmount = 0;
                        Decimal previousPercetage = 0;
                        system.debug(oi.TotalPrice+' = new order , old order = '+mapOriginalOrderItemWithId.get(oi.Linked_Order_Item_for_PC_AI__r.SBQQ__RevisedOrderProduct__c).TotalPrice);
                        if(oi.TotalPrice > mapOriginalOrderItemWithId.get(oi.Linked_Order_Item_for_PC_AI__r.SBQQ__RevisedOrderProduct__c).TotalPrice){
                            System.Debug('SCENARIO 2 : UPGRADE PRODUCT');
                            deltaOrderAmount =  oi.TotalPrice - mapOriginalOrderItemWithId.get(oi.Linked_Order_Item_for_PC_AI__r.SBQQ__RevisedOrderProduct__c).TotalPrice ;
                            oi.Upgrade_Downgrade_Delta_Amount__c = deltaOrderAmount;  
                            oi.PC_AI_Sub_scenario__c ='Product Upgrade';
                            oi.Linked_Order_Item_for_PC_AI__r.Upgrade_Downgrade_Delta_Amount__c = deltaOrderAmount;
                            oi.Linked_Order_Item_for_PC_AI__r.PC_AI_Sub_scenario__c='Product Downgrade';
                            orderProductToUpdate.add(oi);
                            orderProductToUpdate.add(oi.Linked_Order_Item_for_PC_AI__r);
                            system.debug(oi.Upgrade_Downgrade_Delta_Amount__c);
                            sumPercentages = mapOrderItemWithBilledPercantages.get(mapOriginalOrderItemWithId.get(oi.Linked_Order_Item_for_PC_AI__r.SBQQ__RevisedOrderProduct__c).Id);
                            newAmount = (sumPercentages * mapOriginalOrderItemWithId.get(oi.Linked_Order_Item_for_PC_AI__r.SBQQ__RevisedOrderProduct__c).TotalPrice / 100).setScale(2);
                            billingSchedule = new blng__BillingSchedule__c(
                                Name ='BS-'+oi.OrderItemNumber,
                                blng__Amount__c=oi.TotalPrice,
                                blng__OrderProduct__c=oi.Id,
                                CurrencyIsoCode = order.CurrencyIsoCode );
                            listOfBillingSchedule.add(billingSchedule);

                            previousPercetage = (newAmount * 100 / oi.TotalPrice);

                            previousAmount+=deltaAmount;

                            deltaAmount =  ((oi.TotalPrice * sumPercentages/100) - newAmount).setscale(2);
                            previousAmount+=deltaAmount;

                            billingTransactionToInsert= new blng__BillingTransaction__c(blng__Amount__c =deltaAmount ,
                                                                                        Name = 'Transaction '+mapOrderItemWithNumberOfBilledBTs.get(oi.Linked_Order_Item_for_PC_AI__r.SBQQ__RevisedOrderProduct__c),
                                                                                        blng__Status__c ='Pending',
                                                                                        blng__BillingTargetDate__c= Date.toDay() ,
                                                                                        Billing_Percentage__c = (sumPercentages - previousPercetage),//sumPercentages, 25 - 16.67 = 8.33
                                                                                        // blng__BillingSchedule__c=billingSchedule.Id,
                                                                                        Billing_sequence__c =mapOrderItemWithNumberOfBilledBTs.get(oi.Linked_Order_Item_for_PC_AI__r.SBQQ__RevisedOrderProduct__c)+' of '+nbrOfTransaction,
                                                                                        blng__Quantity__c = oi.Quantity, 
                                                                                        Amendment_Adjustment__c ='Additional amount - product upgrade',
                                                                                        CurrencyIsoCode = order.CurrencyIsoCode );

                            previousPercetage+=sumPercentages - (newAmount * 100 / oi.TotalPrice).setScale(2);
                            listOfBillingTransactionToInsert.add(billingTransactionToInsert); 

                            for(blng__BillingTransaction__c bt : mapBillingTransactionWithOrderItemId.get(oi.Linked_Order_Item_for_PC_AI__r.SBQQ__RevisedOrderProduct__c)){

                                if('Billed'.equals(bt.blng__Status__c)){
                                    billingTransactionToInsert = new blng__BillingTransaction__c(blng__Amount__c =( bt.Billing_Percentage__c * mapOriginalOrderItemWithId.get(oi.Linked_Order_Item_for_PC_AI__r.SBQQ__RevisedOrderProduct__c).TotalPrice / 100).setScale(2),
                                                                                                 Name = 'Previously Billed Transaction',//+bt.Name,
                                                                                                 blng__Status__c ='Pending',
                                                                                                 blng__OverrideStatus__c='Cancelled',
                                                                                                 blng__BillingTargetDate__c= Date.toDay() ,
                                                                                                 Billing_Percentage__c = ((bt.Billing_Percentage__c * mapOriginalOrderItemWithId.get(oi.Linked_Order_Item_for_PC_AI__r.SBQQ__RevisedOrderProduct__c).TotalPrice) / oi.TotalPrice),
                                                                                                 blng__Quantity__c = oi.Quantity, 
                                                                                                 Amendment_Adjustment__c ='Cancelled BT for Invoiced Amount',
                                                                                                 PC_AI_Original_Invoice_Line__c =mapBillingTransactionWithInvoicLine.get(bt.Id).Id,
                                                                                                 CurrencyIsoCode = order.CurrencyIsoCode );
                                    listOfBillingTransactionToInsert.add(billingTransactionToInsert); 
                                    system.debug('insert the BT : '+billingTransactionToInsert);

                                }else if('Cancelled'.equals(bt.blng__OverrideStatus__c)){
                                    billingTransactionToInsert = new blng__BillingTransaction__c(blng__Amount__c =bt.blng__Amount__c,
                                                                                                 Name = bt.Name,
                                                                                                 blng__Status__c =bt.blng__Status__c,
                                                                                                 blng__OverrideStatus__c=bt.blng__OverrideStatus__c,
                                                                                                 blng__BillingTargetDate__c= Date.toDay() ,
                                                                                                 Billing_Percentage__c = ((bt.Billing_Percentage__c * mapOriginalOrderItemWithId.get(oi.Linked_Order_Item_for_PC_AI__r.SBQQ__RevisedOrderProduct__c).TotalPrice) / oi.TotalPrice),
                                                                                                 // blng__BillingSchedule__c=billingSchedule.Id,
                                                                                                 blng__Quantity__c = bt.blng__Quantity__c, 
                                                                                                 Amendment_Adjustment__c =bt.Amendment_Adjustment__c,
                                                                                                 PC_AI_Original_Invoice_Line__c =bt.PC_AI_Original_Invoice_Line__c,
                                                                                                 CurrencyIsoCode = order.CurrencyIsoCode ); 
                                    listOfBillingTransactionToInsert.add(billingTransactionToInsert);
                                    system.debug('insert the BT : '+billingTransactionToInsert);
                                }else{
                                    previousAmount+=(oi.TotalPrice * bt.Billing_Percentage__c/100).setScale(2);
                                    previousPercetage+=bt.Billing_Percentage__c;
                                    billingTransactionToInsert = new blng__BillingTransaction__c(blng__Amount__c =(oi.TotalPrice * bt.Billing_Percentage__c/100).setScale(2),
                                                                                                 Name=bt.Name,
                                                                                                 blng__Status__c ='Pending',
                                                                                                 blng__BillingTargetDate__c= bt.blng__BillingTargetDate__c ,
                                                                                                 Billing_Percentage__c = bt.Billing_Percentage__c,
                                                                                                 // blng__BillingSchedule__c=billingSchedule.Id,
                                                                                                 blng__Quantity__c = oi.Quantity, 
                                                                                                 Billing_sequence__c =bt.Billing_sequence__c,
                                                                                                 CurrencyIsoCode = order.CurrencyIsoCode ); 
                                    listOfBillingTransactionToInsert.add(billingTransactionToInsert); 
                                    system.debug('insert the BT : '+billingTransactionToInsert);
                                    bt.blng__OverrideStatus__c='Cancelled';
                                    mapOfBillingTransactionToUpdate.put(bt.Id,bt);
                                }
                            }
                        }
                    }
                }
                //SCENARIO 3 : ADDITION OF A PRODUCT
                //Adding a new product without a coresponding negative line for the same product 
                //Generate the Billing Transactions
                else{
                    System.Debug('SCENARIO 3 : ADDITION OF A PRODUCT');
                    oi.PC_AI_Sub_scenario__c ='Product Addition';
                    orderProductToUpdate.add(oi);
                    listOrderItemToGenerateBTs.add(oi);
                } 
            }
            else if(oi.Quantity<0 ){
                //SCENARIO 4 : REMOVAL OF A PRODUCT
                //Null value for 'Linked order item' means, there is no corresponding +ve line for this product and hence this is just a removal.
                //else, Not null value for 'Linked order item ' means this is an upgrade or a downgrade which will be processed 
                //through correpsponding positive line and hence we will do no further treatment of this negative line.
                if(oi.Linked_Order_Item_for_PC_AI__c==null){
                    creditNote = new  blng__CreditNote__c();
                    oi.PC_AI_Sub_scenario__c ='Product Removal';
                    orderProductToUpdate.add(oi);
                    //Cancel the previous 'Pending' Billing Transactions, and create Credit Notes for the Invoiced Billing Transactions.
                    System.Debug('SCENARIO 4 : REMOVAL OF A PRODUCT AND Linked_Order_Item_for_PC_AI__c = NULL');
                    for(blng__BillingTransaction__c bt : mapBillingTransactionWithOrderItemId.get(oi.SBQQ__RevisedOrderProduct__c)){
                        if('Billed'.equals(bt.blng__Status__c)){
                            if(mapBillingTransactionWithInvoicLine.get(bt.Id)!=null && mapInvoiceWithCreditNote.get(mapBillingTransactionWithInvoicLine.get(bt.Id).blng__Invoice__c)==null){
                                invoiceLineId=mapBillingTransactionWithInvoicLine.get(bt.Id).Id; // Added for Bug Fix [IML2R-1304]
                                creditNote = new  blng__CreditNote__c(CurrencyIsoCode=bt.CurrencyIsoCode,
                                                                      blng__CreditNoteSourceAction__c='Manual',
                                                                      blng__Account__c =order.AccountId,
                                                                      blng__CreditNoteDate__c=Date.toDay(),
                                                                      blng__Status__c='Draft',
                                                                      blng__Notes__c='Generated as a result of PC/AI downgrade scenarios',
                                                                      blng__RelatedInvoice__c=mapBillingTransactionWithInvoicLine.get(bt.Id).blng__Invoice__c,
                                                                      blng__BillToAccount__c = order.blng__BillingAccount__c,
                                                                      blng__BillToContact__c = order.BillToContactId);
                                listOfCreditNote.add(creditNote); 
                                mapInvoiceWithCreditNote.put(creditNote.blng__RelatedInvoice__c,creditNote);
                            }
                            listOfCreditNoteLine = mapListCreditNoteLineWithInvoice.get(creditNote.blng__RelatedInvoice__c);
                            if(listOfCreditNoteLine  ==null || listOfCreditNoteLine.size()==0){
                                listOfCreditNoteLine = new List<blng__CreditNoteLine__c>();
                            }

                            // Added for Bug Fix [IML2R-2008]
                            blng__InvoiceLine__c invLine = mapBillingTransactionWithInvoicLine.get(bt.Id);
                            Decimal creditLineSubtotal = (bt.blng__Amount__c- (bt.Billing_Percentage__c * oi.TotalPrice / 100)).setScale(2);//bt.blng__Amount__c;
                            Decimal creditLineTax = 0;
                            if(invLine.blng__Subtotal__c !=null && invLine.blng__Subtotal__c != 0 && invLine.blng__TaxAmount__c != null){
                                creditLineTax = (invLine.blng__TaxAmount__c * (creditLineSubtotal/invLine.blng__Subtotal__c)).setScale(2);
                            }

                            listOfCreditNoteLine.add(new blng__CreditNoteLine__c(blng__Product__c=oi.Product2Id,
                                                                                 blng__InvoiceLine__c =invoiceLineId,
                                                                                 blng__Subtotal__c=creditLineSubtotal,
                                                                                 blng__TaxAmount__c=creditLineTax,
                                                                                 blng__TaxPercentageApplied__c=invLine.blng__TaxPercentageApplied__c,
                                                                                 blng__LegalEntity__c=invLine.blng__LegalEntity__c));

                            mapListCreditNoteLineWithInvoice.put(creditNote.blng__RelatedInvoice__c,listOfCreditNoteLine);
                        }else{
                            bt.blng__OverrideStatus__c='Cancelled';
                            mapOfBillingTransactionToUpdate.put(bt.Id,bt);
                        }
                    }
                }
            }
            mapListBillingTransactionWithOrderItem.put(oi.Id,listOfBillingTransactionToInsert); 
            listOfBillingTransactionToInsert = new List<blng__BillingTransaction__c>();
            listOfCreditNoteLine = new List<blng__CreditNoteLine__c>();
        }
        upsert listOfBillingSchedule;
        //Prepar the Billing transactions to be stored
        List<blng__BillingTransaction__c > listOfBTsTobeStored = new List<blng__BillingTransaction__c>(); 
        System.debug('---------------------------------------------- Final result ----------------------------------------------');
        for(blng__BillingSchedule__c bs : listOfBillingSchedule){
            System.debug('--------------- bs = '+bs+' ---------------');
            for(blng__BillingTransaction__c bt : mapListBillingTransactionWithOrderItem.get(bs.blng__OrderProduct__c)){
                if(bt.Id==null){
                    bt.blng__BillingSchedule__c=bs.Id;
                }
                listOfBTsTobeStored.add(bt);

                System.debug('bt = '+bt);
            }
        }

        insert listOfCreditNote;

        // prepar credit note lines to be inserted
        System.debug('listOfCreditNote = '+listOfCreditNote.size());
        for(blng__CreditNote__c cn : listOfCreditNote){

            //The line below will be removed when the Tax api call is ready. At that point, the api call will be done and appropriate tax status will be calculated.
            cn.Tax_Status__c='Tax Complete';
            //---------------------------------------
            cn.blng__Status__c='Posted';
            System.debug('cn = '+cn);
            for(blng__CreditNoteLine__c crl : mapListCreditNoteLineWithInvoice.get(cn.blng__RelatedInvoice__c)){
                crl.blng__CreditNote__c = cn.Id;
                listOfCreditNoteLine.add(crl);
                System.debug('crl = '+crl);
            }
        }

        if(listOrderItemToGenerateBTs.size()>0){
            BillingTransactionGenerator.setOrderItems(listOrderItemToGenerateBTs);
            BillingTransactionGenerator.generateBillingTransaction(order);
            BillingTransactionGenerator.setOrderItems(null);
        }
        if(orderProductToUpdate!=null && orderProductToUpdate.size()>0){
            upsert orderProductToUpdate;
        }
        if(listOfCreditNoteLine!=null && listOfCreditNoteLine.size()>0){
            upsert listOfCreditNoteLine;
        }
        if(listOfCreditNote!=null && listOfCreditNote.size()>0){
            upsert listOfCreditNote;
        }

        if(listOfBTsTobeStored!=null && listOfBTsTobeStored.size()>0){
            upsert listOfBTsTobeStored;
        }

        if(mapOfBillingTransactionToUpdate.values()!=null && mapOfBillingTransactionToUpdate.values().size()>0){
            upsert mapOfBillingTransactionToUpdate.values();
        }
    }
}