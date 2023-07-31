/**
 * Created By   :   Girikon(Prashant)
 * Created On   :   Nov 18 2019
 * @description :   [This class is the test class of StateCodeServices.]
 * Apex Class   :   StateCodeServices
 * Modification Log----- 
 * Modified by  : 
**/

@IsTest public class StateCodeServices_Test {

    @IsTest static void testStart()
    {
        // arrange
        Database.Batchable<String> batch = new StateCodeServices();
        
        // act
        Iterable<String> iterable = batch.start(null);
        
        // assert
        System.assert(iterable.iterator().hasNext(), 'Batch Process has started.');
    }
    
    @IsTest static void testExecute()
    {
        // arrange
        Database.Batchable<String> batch = new StateCodeServices();
         Map<String,String> scope2state = new Map<String,String>
    	{
        	'US-AK' => 'Alaska'
        };
        // act
        batch.execute(null, new List<String>{'US-CA'});
        System.assertEquals(2, Limits.getCallouts(), 'Only two callouts allowed');
        StateCodeServices.run(scope2state);
        batch.finish(null); 
        StateCodeServices stateCode = new StateCodeServices();
        stateCode.abortBatch();
        stateCode.startBatch();
        
    }
    
    

}