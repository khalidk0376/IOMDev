/**
* File:         PaymentTermAndProdInvoProp_Trig
* Project:      PoC SFDC Informa 
* Test Class:   PaymentTermAndProdInvoProp_Test
* Coverage:     100%
* *******************************************************************************************************
* @description : Trigger Hundler on OrderItem to set the Product Invoice property & the Payement term on the order Item 
*          From Edition Product
* @author: Ayoub Ouarti (aouarti@salesforce.com)
* @date: 17/12/2019
* *******************************************************************************************************
History
-------
VERSION         AUTHOR              DATE            DETAIL
1.0         Ayoub Ouarti      17/12/2019      Initial Dev

* *******************************************************************************************************/
public class PaymentTermAndProdInvoProp_Trig implements TriggerInterface_OrderItem.Runnable{
    public void run(TriggerInterface_OrderItem.Trig trig) {
        if (trig.isBefore && trig.isInsert ) {
            
            if (trig.triggerSize > 0) {                
                Set<Id> productIds = new Set<Id>();
                Set<Id> editionIds = new Set<Id>();
                for(OrderItem oi : trig.newList){
                    productIds.add(oi.Product2Id);
                    editionIds.add(oi.Edition__c);
                }
                
                List<Product_Edition__c > listProductEdition = Database.query('SELECT Product__c ,Edition__c ,Product_Invoice_property__c , Payment_Term__c from Product_Edition__c  where Product__c IN :productIds AND  Edition__c IN :editionIds');
                for(OrderItem eachOrderItem : trig.newList){
                    for(Product_Edition__c eachProductEdition :listProductEdition ){
                        if(eachOrderItem.Edition__c == eachProductEdition.Edition__c && eachOrderItem.Product2Id == eachProductEdition.Product__c ){
                            System.Debug('INFO: Update Product_Invoice_property__c  and Payment_Term__c');
                            eachOrderItem.Product_Invoice_property__c =eachProductEdition.Product_Invoice_property__c;
                            eachOrderItem.Payment_Term__c =eachProductEdition.Payment_Term__c;
                            break;
                        }  
                    } 
                }
            }
        }
    }
}