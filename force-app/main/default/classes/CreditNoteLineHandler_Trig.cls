/**
* Raider Data Services, TT
* @description Handler Class for CreditNoteLineTrigger to Calculate Ammounts from its Exchage rates and
* its Total ammount paid with tax.
* Date: 12/09/2019
* Test Class    :   CreditNoteLineHandler_TrigTest(94%)
***************************************************************
* Modification log:
* 1. [IML2R-1998]  Girikon(Ashish) 26 march 2020 -  Error handing for event Currency missing Records
* 2. [IOM-839]     Girikon(Ashish) [14 Feb 2022], Updated Query to include new tax line fields
* 3. [GECI-615]    Girikon(Ashish) [24 Jan 2023], Changed logic to create percent from subtotal
*/
public with sharing class CreditNoteLineHandler_Trig implements TriggerInterface_CreditNoteLine.Runnable {
    /**
* @description Trigger handler method for CreditNoteline based on the event called, the processing is dispatched accordingly
* @param trig TriggerInterface_CreditNoteLine.Trig class instance
*/
    public void run(TriggerInterface_CreditNoteLine.Trig trig){
        if(trig.isBefore && trig.isInsert){
            //Method to add sequence Numberson InvoiceLines
            addCrdNoteLineSequenceNo(trig.newList);	
        }
        if(trig.isAfter && trig.isInsert)
        {
            //Method to insert Tax Lines under affected Credit Note lines.
            createTaxLines(trig.newList);	
        } 
    }
    
    /**
	 *@description add sequence No on invoiceLines   
	 *@param listOfCrdNoteLine list of CreditNoteLines	
	 */    
    private static void addCrdNoteLineSequenceNo(List<blng__CreditNoteLine__c> listOfCrdNoteLine){
        Map<Id,Integer> mapCreditNoteIdStartSequenceNum = new Map<Id,Integer>();
        Set<Id> setOfInvLineIds = new Set<Id>();
        for(blng__CreditNoteLine__c crdNoteLine : listOfCrdNoteLine){
            mapCreditNoteIdStartSequenceNum.put(crdNoteLine.blng__CreditNote__c,0);
            setOfInvLineIds.add(crdNoteLine.blng__InvoiceLine__c);
        }

        for(blng__CreditNoteLine__c crdNoteLine : [SELECT Id,Line_Item_Number__c,blng__CreditNote__c FROM blng__CreditNoteLine__c WHERE blng__CreditNote__c IN:mapCreditNoteIdStartSequenceNum.keySet() WITH Security_Enforced ORDER BY blng__CreditNote__c,Line_Item_Number__c ASC]){
            mapCreditNoteIdStartSequenceNum.put(crdNoteLine.blng__CreditNote__c,Integer.valueOf(crdNoteLine.Line_Item_Number__c));
        }
        
        for(blng__CreditNoteLine__c crdNoteLine : listOfCrdNoteLine){
            Integer seqNo = mapCreditNoteIdStartSequenceNum.get(crdNoteLine.blng__CreditNote__c) + 1;
            crdNoteLine.Line_Item_Number__c = seqNo;
            mapCreditNoteIdStartSequenceNum.put(crdNoteLine.blng__CreditNote__c,seqNo);
        }
        
        Map<Id,blng__InvoiceLine__c> mapOfInvLines = new Map<Id,blng__InvoiceLine__c>([SELECT Id, Name, UOM__c, blng__TaxLocationCode__c, blng__TaxCounty__c FROM blng__InvoiceLine__c WHERE Id IN:setOfInvLineIds WITH SECURITY_ENFORCED]);
        for(blng__CreditNoteLine__c crdNoteLine : listOfCrdNoteLine){
            blng__InvoiceLine__c invLine = mapOfInvLines.get(crdNoteLine.blng__InvoiceLine__c);
            if(invLine != null && invLine.UOM__c != null){
                crdNoteLine.UOM__c = String.valueOf(invLine.UOM__c);
            }
            if(invLine != null && invLine.blng__TaxLocationCode__c != null){
                crdNoteLine.Tax_Location_Code_Override__c = invLine.blng__TaxLocationCode__c;
            }
            if(invLine != null && invLine.blng__TaxCounty__c != null){
                crdNoteLine.Tax_County_Override__c = invLine.blng__TaxCounty__c;
            }
        }
    }
    
    /**
	 *@description add sequence No on invoiceLines   
	 *@param listOfCrdNoteLine list of CreditNoteLines	
	 */ 
    public void createTaxLines(List<blng__CreditNoteLine__c> listOfCrdNoteLine){    
        Set<Id> setOfInvLineIds = new set<Id>();
        Set<Id> setOfCrnoteIds = new set<Id>();
        List<Tax_Lines__c> txLinestoInsert = new List<Tax_Lines__c>();
        for(blng__CreditNoteLine__c crdNoteLine : listOfCrdNoteLine){
            setOfInvLineIds.add(crdNoteLine.blng__InvoiceLine__c);
            setOfCrnoteIds.add(crdNoteLine.blng__CreditNote__c);
        }
        
        Map<Id,blng__InvoiceLine__c> mapOfInvLines = new Map<Id,blng__InvoiceLine__c>([SELECT Id, Name,blng__Invoice__c,blng__TotalAmount__c ,blng__Subtotal__c FROM blng__InvoiceLine__c WHERE Id IN:setOfInvLineIds WITH SECURITY_ENFORCED]);
        
        String taxLinesQuery = 'Select '+String.escapeSingleQuotes(new CPQAPIUtils().dynamicGetAllFieldsQuery('Tax_Lines__c'))+ ' From Tax_Lines__c Where Invoice_Line__c IN: setOfInvLineIds';
        Map<Id,Tax_Lines__c> mapOfInvTaxLines = new Map<Id,Tax_Lines__c>((List<Tax_Lines__c>)Database.query(taxLinesQuery));

        Map<Id, blng__CreditNoteLine__c> mapOfCrdNtLine = new Map<Id, blng__CreditNoteLine__c>([SELECT Id,blng__CreditNote__r.blng__CreditNoteSourceAction__c FROM blng__CreditNoteLine__c WHERE blng__CreditNote__c IN: setOfCrnoteIds WITH SECURITY_ENFORCED]);

        Decimal percentageOfAmount = 0;
        for(blng__CreditNoteLine__c crdNoteLine : listOfCrdNoteLine){
            blng__InvoiceLine__c invLine = mapOfInvLines.get(crdNoteLine.blng__InvoiceLine__c);
            
            if(invLine != null && invLine.blng__Subtotal__c != null && invLine.blng__Subtotal__c > 0  && mapOfCrdNtLine.get(crdNoteLine.Id).blng__CreditNote__r.blng__CreditNoteSourceAction__c != 'Manual')
            { 
                percentageOfAmount = ((invLine.blng__Subtotal__c - crdNoteLine.blng__Subtotal__c)/invLine.blng__Subtotal__c) * 100; // [GECI-615]
            }
            
            for(Tax_Lines__c txLine : mapOfInvTaxLines.values()){
                if(txLine.Invoice_Line__c != null && crdNoteLine.blng__InvoiceLine__c != null && txLine.Invoice_Line__c == crdNoteLine.blng__InvoiceLine__c)
                {
                    Tax_Lines__c crdNtLineTxLine = txLine.clone(false,false,false,false);
                    crdNtLineTxLine.Invoice_Line__c = null;
                    crdNtLineTxLine.Credit_Note_Line__c = crdNoteLine.Id;
                    crdNtLineTxLine.Tax_Code__c = txLine.Tax_Code__c;
                    crdNtLineTxLine.Tax_Rate__c = txLine.Tax_Rate__c;
                    crdNtLineTxLine.Tax_Amount__c = txLine.Tax_Amount__c != null ? (txLine.Tax_Amount__c - (txLine.Tax_Amount__c * (percentageOfAmount/100))) : 0;
                    crdNtLineTxLine.CurrencyIsoCode = txLine.CurrencyIsoCode;
                    txLinestoInsert.add(crdNtLineTxLine);
                }
            }
        }

        if(!txLinestoInsert.isEmpty() && Schema.sObjectType.Tax_Lines__c.isCreateable()){
            insert txLinestoInsert;
        }
    }
}