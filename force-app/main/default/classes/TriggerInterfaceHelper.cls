/*
* Created by Himanshu RANA- 31-08-2020
* 
*/

public with sharing class TriggerInterfaceHelper {
    public static List<Trigger__c> listTriggers = new List<Trigger__c>();
    public static Map<String,Map<Id,Map<String,String>>> mapTriggerRecordtypes = new Map<String,Map<Id,Map<String,String>>>();
    public static Set<String> triggerAlreadyRan = new Set<String>();
    public static boolean alreadyRan = false; 

    public static void initTriggerMapAndList(String objectName) { 
        //if (!alreadyRan && !test.isRunningTest()) { // @@Avi (Avi made this change to increase test coverage so he could deploy the class.  @@Jeff)
        if (!alreadyRan) { 
            alreadyRan = true;
            listTriggers = [SELECT Name, Object__c, Execution_Order__c, Before_Insert__c, Before_Update__c, Before_Delete__c,
                                After_Insert__c, After_Update__c, After_Delete__c, After_UnDelete__c, Recursive_Execution_Allowed__c,
                                Run_for_Recordypes__c,Excluded_Profiles__c,Excluded_Users__c,Parameters__c,
                                (SELECT Name, Recordtype_Id__c, Excluded_Profiles__c, Excluded_Users__c, Parameters__c
                                 FROM Trigger_Recordtypes__r
                                 WHERE Enabled__c = true)
                            FROM Trigger__c t
                            WHERE Enabled__c = true
                            //and Object__c =:objectName
                            //and Object__c =:objectName // @@Avi (Avi, why did you add this? If you are going to add this, then you must remove the check for alreadyRan. @@Jeff)
                            ORDER BY Execution_Order__c];

            String profileId = String.valueOf(UserInfo.getProfileId()).left(15);
            String userId = String.valueOf(UserInfo.getUserId()).left(15);
            system.debug('listTriggers#####'+listTriggers);
            for(Trigger__c t : listTriggers) {
                List<Trigger_Recordtype__c> rts = t.Trigger_Recordtypes__r;
                if(rts.size() > 0) {
                    for (Trigger_Recordtype__c rt : rts) {
                        if ((rt.Excluded_Profiles__c == null || !rt.Excluded_Profiles__c.contains(profileId)) && (rt.Excluded_Users__c == null || !rt.Excluded_Users__c.contains(userId))) {
                            Map<Id,Map<String,String>> mapRtIdsAndParams = new Map<Id,Map<String,String>>();
                            if (mapTriggerRecordtypes.containsKey(t.Name))
                                mapRtIdsAndParams = mapTriggerRecordtypes.get(t.Name);
                            else
                                mapRtIdsAndParams = new Map<Id,Map<String,String>>();
                            Map<String,String> mapParams = new Map<String,String>();
                            if (rt.Parameters__c != null) { 
                                List<String> split1 = rt.Parameters__c.split(';');
                                for (String param : split1) {
                                    if (param.contains('=')) {
                                        List<String> split2 = param.split('=');
                                        mapParams.put(split2[0], split2[1]);
                                    } else {
                                        mapParams.put('Parameters', param);
                                    }
                                }
                            }
                            mapRtIdsAndParams.put(rt.Recordtype_Id__c, mapParams);              
                            mapTriggerRecordtypes.put(t.Name, mapRtIdsAndParams);
                        }
                    }
                } else {
                    Map<Id,Map<String,String>> mapRtIdsAndParams = new Map<Id,Map<String,String>>();
                    mapTriggerRecordtypes.put(t.Name, mapRtIdsAndParams);
                }
            }                      
        }
    }

    public static void runTrigger(String triggerName, String objectName, Integer executionOrder, String executionType,  String recordtypeId, String params,String runFor) {
        system.debug('LUP: inside runTrigger');
        Set<String> setExecutionType = new Set<String>();
        setExecutionType.addAll(executionType.split(','));
        Trigger__c t;
        for (Trigger__c existingTrigger : listTriggers) {
            if (existingTrigger.Name == triggerName) {
                t = existingTrigger;
                break;
            }
        }
        if (t == null) {
            t = new Trigger__c();
            t.Name = triggerName;
            t.Object__c = objectName;
            t.Execution_Order__c = executionOrder;
            t.Before_Insert__c = setExecutionType.contains('bi');
            t.Before_Update__c = setExecutionType.contains('bu');
            t.Before_Delete__c = setExecutionType.contains('bd');
            t.After_Insert__c = setExecutionType.contains('ai');
            t.After_Update__c = setExecutionType.contains('au');
            t.After_Delete__c = setExecutionType.contains('ad');
            t.After_UnDelete__c = setExecutionType.contains('aud');
            t.Run_for_Recordypes__c = runFor;
            listTriggers.add(t);
        }       
        if (recordtypeId != null) {
            Map<Id, Map<String,String>> mapIdToParams;
            Map<String,String> mapParams = new Map<String,String>();
            if (params != null) {
                List<String> split1 = params.split(';');
                for (String param : split1) {
                    if (param.contains('=')) {
                        List<String> split2 = param.split('=');
                        mapParams.put(split2[0], split2[1]);
                    } else {
                        mapParams.put('Parameters', param);
                    }
                }
            }
            if (mapTriggerRecordtypes.containsKey(triggerName))
                mapIdToParams = mapTriggerRecordtypes.get(triggerName);
            else
                mapIdToParams = new Map<Id, Map<String,String>>();
            mapIdToParams.put(recordtypeId, mapParams);
            mapTriggerRecordtypes.put(triggerName, mapIdToParams);
        } else {
            Map<Id, Map<String,String>> mapIdToParams = new Map<Id, Map<String,String>>();
            mapTriggerRecordtypes.put(triggerName, mapIdToParams);
        }
    }
}