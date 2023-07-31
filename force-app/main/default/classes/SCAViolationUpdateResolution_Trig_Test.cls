/**
 * Created by : Hailey Niemand 
 * Created on : 10/11/2020 
 * Apex Class : TriggerInterfaceHelper
 */

@isTest
public class SCAViolationUpdateResolution_Trig_Test {
    
    public static copado__Static_Code_Analysis_Violation__c createSCAViolation (string file, string rule, string resolution, integer line, Id resultId){
    	copado__Static_Code_Analysis_Violation__c scaViolation = new copado__Static_Code_Analysis_Violation__c ();
        scaViolation.copado__Static_Code_Analysis_Result__c = resultId;
        scaViolation.copado__File__c = file;
        scaViolation.copado__Rule__c = rule;
        scaViolation.copado__Resolution__c = resolution;
        scaViolation.copado__Line__c =  line;
		return scaViolation;
    }
    
    @isTest
    public static void newViolationsCreatedTest() {
        
        copado__Static_Code_Analysis_Result__c scaResult = new copado__Static_Code_Analysis_Result__c();
        insert scaResult;
        
        List<copado__Static_Code_Analysis_Violation__c> existingScaViolations = new List<copado__Static_Code_Analysis_Violation__c>();
        copado__Static_Code_Analysis_Violation__c scaViolation1 = createSCAViolation('UpdateNewRecords', 'AvoidSoqlInLoops', 'Unresolved', 132, scaResult.Id);
        existingScaViolations.add(scaViolation1);
		copado__Static_Code_Analysis_Violation__c scaViolation2 = createSCAViolation('InsertNewRecords', 'AvoidSoqlInLoops', 'False Positive', 27, scaResult.Id);
        existingScaViolations.add(scaViolation2);
		copado__Static_Code_Analysis_Violation__c scaViolation3 = createSCAViolation('UpdateExistingRecords', 'AvoidSoqlInLoops', 'Fixed', 27, scaResult.Id);
        existingScaViolations.add(scaViolation3);
        copado__Static_Code_Analysis_Violation__c scaViolation4 = createSCAViolation('InsertNewRecords', 'AvoidDMLInLoops', 'Unresolved', 132, scaResult.Id);
        existingScaViolations.add(scaViolation4);
        copado__Static_Code_Analysis_Violation__c scaViolation5 = createSCAViolation('UpdateNewRecords', 'AvoidSoqlInLoops', 'Unresolved', 132, scaResult.Id);
        existingScaViolations.add(scaViolation5);
        Insert  existingScaViolations;
        
		TriggerInterfaceHelper.runTrigger('SCAViolationUpdateResolution_Trig','copado__Static_Code_Analysis_Violation__c',99, 'bi', null,null,'All');
        
        copado__Static_Code_Analysis_Result__c scaResult1 = new copado__Static_Code_Analysis_Result__c();
        insert scaResult1;
        
        List<copado__Static_Code_Analysis_Violation__c> newScaViolations = new List<copado__Static_Code_Analysis_Violation__c>();
        //Record to be updated to 'False Positive'
		copado__Static_Code_Analysis_Violation__c scaViolation6 = createSCAViolation('InsertNewRecords', 'AvoidSoqlInLoops', 'Unresolved', 27, scaResult1.Id);
        newScaViolations.add(scaViolation6);
        //Record to be updated to 'Fixed'
        copado__Static_Code_Analysis_Violation__c scaViolation7 = createSCAViolation('UpdateExistingRecords', 'AvoidSoqlInLoops', 'Unresolved', 27, scaResult1.Id);
        newScaViolations.add(scaViolation7);
        //Record which shouldn't be update
        copado__Static_Code_Analysis_Violation__c scaViolation8 = createSCAViolation('UpdateNewRecords', 'AvoidDMLInLoops', 'Unresolved', 327, scaResult1.Id);
        newScaViolations.add(scaViolation8);
        Insert newScaViolations;
        
        List<copado__Static_Code_Analysis_Violation__c> updatedSCA = [SELECT Id, copado__Resolution__c, copado__File__c, copado__Rule__c, copado__Line__c
                                                                FROM copado__Static_Code_Analysis_Violation__c 
                                                                WHERE Id IN :newScaViolations];
        system.debug('HNTest UpdatedSCA Size ' + updatedSCA.size());

        For (copado__Static_Code_Analysis_Violation__c uSCA : updatedSCA){
            string violationKey = SCAViolationUpdateResolution_Trig.generateKey(uSCA);
            if(violationKey == 'InsertNewRecords_AvoidSoqlInLoops_27'){
                system.assertEquals('False Positive', uSCA.copado__Resolution__c, 'Resolutions Match');
            } if (violationKey == 'UpdateExistingRecords_AvoidSoqlInLoops_27'){
                system.assertEquals('Fixed', uSCA.copado__Resolution__c, 'Resolutions Match');
            } if (violationKey == 'UpdateNewRecords_AvoidDMLInLoops_327'){
                system.assertEquals('Unresolved', uSCA.copado__Resolution__c, 'Resolutions Match');
            }
        }
    }
    
    @isTest
    public static void getLatestResolutionTest() {
        List<copado__Static_Code_Analysis_Violation__c> scaList = new List<copado__Static_Code_Analysis_Violation__c>();
        copado__Static_Code_Analysis_Result__c scaResult = new copado__Static_Code_Analysis_Result__c();
        insert scaResult;
        scaList.add(createSCAViolation('InsertNewRecords', 'AvoidSoqlInLoops', 'Unresolved', 27, scaResult.Id));
        scaList.add(createSCAViolation('InsertNewRecords', 'AvoidSoqlInLoops', 'False Positive', 27, scaResult.Id));
        Map<String, String> latestResolutions = SCAViolationUpdateResolution_Trig.getLatestResolution(scaList);
        system.assertEquals(1, latestResolutions.size(),'Only 1 item added to map');
    }
    
    @isTest
    public static void setNewResolutionTest() {
        List<copado__Static_Code_Analysis_Violation__c> scaList = new List<copado__Static_Code_Analysis_Violation__c>();
        copado__Static_Code_Analysis_Result__c scaResult = new copado__Static_Code_Analysis_Result__c();
        insert scaResult;
        scaList.add(createSCAViolation('UpdateNewRecords', 'AvoidSoqlInLoops', 'Unresolved', 132, scaResult.Id));
        scaList.add(createSCAViolation('InsertNewRecords', 'AvoidSoqlInLoops', 'Unresolved', 27, scaResult.Id));
        Map<String, String> latestResolutions = new Map<String, String>();
        latestResolutions.put('InsertNewRecords_AvoidSoqlInLoops_27','False Positive');
        SCAViolationUpdateResolution_Trig.setNewResolution(scaList, latestResolutions);
        system.assertEquals('False Positive', scaList[1].copado__Resolution__c,'New resolution correct');
    }
}