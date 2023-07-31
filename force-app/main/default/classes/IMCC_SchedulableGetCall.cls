/**
* Created/Modified By    : Girikon(Arushi [IMCC-4862])
* Created On             : 22-Nov-2022
* @description           : Schedulable can be scheduled for every 1 or 6 hr to make API Callout 
* Test Class             : Imcc_APICallOutVisit_Test
* Code Coverage          : 100%
**/
public class IMCC_SchedulableGetCall implements Schedulable {
    /**
    * @description this method will be executed to call visit get api when scheduler runs
    * @param sc
    */
    public void execute(SchedulableContext sc) {
        IMCC_APICallOutVisit.makeGetCallout();
    }
}