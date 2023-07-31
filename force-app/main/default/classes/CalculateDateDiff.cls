/**
* File         :   CalculateDateDiff 
* Project      :   Order & Billing Plateform
* Created Date :   17th March 2022
* Created By   :   Girikon(Deepak)
* Test Class   :   CalculateDateDiff_Test(86%)
* ******************************************************************************************************
@description : Apex rest class to Calculate Difference Betweend Start Date And End Date Of Quote Lines
*******************************************************************************************************
* Modification log : 
* 1.
*/
@RestResource(urlMapping='/calculatedatediff')
global class CalculateDateDiff {
    /**
    * @description  This method is used to Calculate Difference Betweend Start Date And End Date Of Quote Lines
    * @return Map<String,String> 
    */
    @HttpPost
    global static Map<String,String> dateDiff() 
    {
        Map<String,String> mapReturn = new Map<String,String>();
        RestRequest req = RestContext.request;
        String requestJSONString = req.requestBody.toString();
        Map<String,RequestWrapper> mapReqWrap = (Map<String,RequestWrapper> )JSON.deserialize(requestJSONString,Map<String,RequestWrapper>.class);
        for(String key : mapReqWrap.keySet()){
            RequestWrapper reqWrap = mapReqWrap.get(key);
            Integer monthsBetween = reqWrap.startDate.monthsBetween(reqWrap.endDate.addDays(1));
            Date tempEndDate = reqWrap.startDate.addMonths(monthsBetween);
            if(tempEndDate > reqWrap.endDate.addDays(1)){
                monthsBetween -= 1;
                tempEndDate = reqWrap.startDate.addMonths(monthsBetween);
            }
            Integer daysBetween = tempEndDate.daysBetween(reqWrap.endDate.addDays(1));
            mapReturn.put(key, (monthsBetween + '-' + daysBetween));
        }
        return mapReturn;
    }

    /**
    * @description  RequestWrapper
    */
    public class RequestWrapper{
        public Date startDate;
        public Date endDate;
    }
}