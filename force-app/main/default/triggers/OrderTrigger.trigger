/**
* @author: Ayoub Ouarti (aouarti@salesforce.com)
* @date: 25/11/2019
* @description:  Trigger for Order
*/
trigger OrderTrigger on Order (after update,before Update,after insert, before insert) {

     new OrderTriggerHandler().run();
    
}