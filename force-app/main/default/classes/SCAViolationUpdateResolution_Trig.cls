/*
Created By: Hailey Niemand
Created On: 10/11/2020 
Description/Purpose: When a new Static Code Anaysis is run and there are Static Code Analysis Violations, we need to check whether the 
					 resolution for that violation was previously changed, if it was we should set the same Resolution for the current 
					 violation. Match is performed based on 1) FileName, 2) Rule Violated and 3) Line Number
Test Class: SCAViolationUpdateResolution_Trig_Test - 100%
*/
public without sharing class SCAViolationUpdateResolution_Trig implements TriggerInterface_SCAViolation.Runnable {
    
    public static string generateKey(copado__Static_Code_Analysis_Violation__c sca){
        return sca.copado__File__c + '_' + sca.copado__Rule__c + '_' + sca.copado__Line__c;
    }
    
    public static Map<String, String> getLatestResolution(List<copado__Static_Code_Analysis_Violation__c> scaViolationsList){
        Map<String, String> existingResolutions = new Map<String, String>();
        for (copado__Static_Code_Analysis_Violation__c rSCAViolation : scaViolationsList) {
            string violationKey = generateKey(rSCAViolation);
            if (!existingResolutions.containsKey(violationKey)) {
                existingResolutions.put(violationKey, rSCAViolation.copado__Resolution__c);
            }
        }
        return existingResolutions;
    }
    
    public static void setNewResolution(List<copado__Static_Code_Analysis_Violation__c> newList, Map<String, String> existingResolutions){
        for (copado__Static_Code_Analysis_Violation__c newSca : newList) {				
            String resolution = existingResolutions.get(GenerateKey(newSca));
            if (resolution != null && resolution != '') {
                newSca.copado__Resolution__c = resolution;
            }
        }
    }
    
	public void run(TriggerInterface_SCAViolation.Trig trig) {
        if (trig.isBefore && trig.isInsert) {
            if (!Schema.sObjectType.copado__Static_Code_Analysis_Violation__c.fields.Name.isUpdateable()) {
                //List of existing violations that have had Resolution updated 
                List<copado__Static_Code_Analysis_Violation__c> resolvedSCAViolations = [SELECT Id, copado__File__c, copado__Rule__c, copado__Line__c, copado__Resolution__c 
                                                                                         FROM copado__Static_Code_Analysis_Violation__c
                                                                                         WHERE copado__Resolution__c != 'Unresolved'
                                                                                         ORDER BY createdDate desc];
                
                //set key for existing resolved records
                Map<String, String> existingResolutions = SCAViolationUpdateResolution_Trig.getLatestResolution(resolvedSCAViolations);
                
                //set new resolution value on records being inserted
                SCAViolationUpdateResolution_Trig.setNewResolution(trig.newList, existingResolutions);
            }
        }
    }
}