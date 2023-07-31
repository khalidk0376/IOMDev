/**
* Trigger Name  :   trig_EmailToCase
* Project       :   Service Console Informa
* Created By    :   Garima Gupta(Girikon)
* Coverage      :   100%
* Created Date  :   22nd Feb 2021
 ******************************************************************************************************
* @description : Calling Handler class to Populate Edition or Series or Brand on Case in Email to Case
 ******************************************************************************************************
* Last Modified By :
*/

trigger trig_EmailToCase on EmailMessage (after insert) {
    
    Trig_EmailToCase_Handler trigEmailCase = new Trig_EmailToCase_Handler();
    trigEmailCase.updateEditionInEmailToCase(trigger.new);
    
}