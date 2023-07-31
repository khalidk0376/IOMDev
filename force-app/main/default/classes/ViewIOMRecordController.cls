/**
* File         :   ViewIOMRecordController 
* Project      :   GECI
* Created Date :   20th Feb 2023
* Created By   :   IBM 
* Test Class   :   ViewIOMRecordController_Test (99%)
* ***************************************************************************************************
* @description : Controller class for ViewIOMRecord Visualforce Page (GECI-737)
* ***************************************************************************************************
* Modification log :  
*/
public class ViewIOMRecordController {
    public Boolean showErrorMessage{set;get;}
    
    /** 
     * @description : method to search for Opportunity by IM Opp No and redirect to the opp detail page
	 * @return PageReference
	 */
    public PageReference redirectToRecordPage(){
        string imOppNo=ApexPages.currentPage().getParameters().get('iomoppno');
        
        List<Opportunity> opps = [Select Id FROM Opportunity WHERE IM_Opportunity_No__c=:imOppNo];
        if(!opps.isEmpty()){
        	return new PageReference('/'+opps[0].Id);    
        }
        showErrorMessage = true;
        return null;  
    }
}