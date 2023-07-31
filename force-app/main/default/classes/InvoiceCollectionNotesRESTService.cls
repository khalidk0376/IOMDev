/**
* File         :   InvoiceOutstandingBalanceRESTService 
* Project      :   Order & Billing Plateform [IOM-669]
* Created Date :   10th Jan 2022
* Created By   :   Girikon(Ashish)
* Test Class   :   InvoiceRESTService_Test(88%)
* ***************************************************************************************************
@description : Apex rest class to update Invoice CollectionNotes
*****************************************************************************************************
* Modification log : 
* 1.
*/
@RestResource(urlMapping='/InvoiceCollectionNotes/*')
global with sharing class InvoiceCollectionNotesRESTService 
{
    private Static Final String FILTER_FIELD_API_METANAME = 'Invoice_External_No_Field';
     /**
    * @description  This method is used to update Invoice fields
    * @return String 
    */
    @HttpPut
    global static ResponseData upsertCollectionNotesOnInv() 
    {
        ResponseData resWrap = new ResponseData();
        resWrap.status = 'Unknown';
        resWrap.message = 'Invalid Request Data';
        RestRequest req = RestContext.request;
        String requestJSONString = req.requestBody.toString();
        try {
            InvoiceWapper invWrap = (InvoiceWapper)JSON.deserialize(requestJSONString,InvoiceWapper.class);
        
            if(String.isNotBlank(invWrap.invoiceNumber))
            {
                List<Collection_Note__c> listCollectionNotes = new List<Collection_Note__c>();

                //List<blng__Invoice__c> invList = new List<blng__Invoice__c>([SELECT Id,Name,(SELECT Id,NoteID__c from Collection_Notes__r) FROM blng__Invoice__c WHERE Name =: invWrap.invoiceNumber WITH SECURITY_ENFORCED]);

                String filterFieldAPI = !Test.isRunningTest()?GlobalConstants.getValue(FILTER_FIELD_API_METANAME):'Name';
                filterFieldAPI = String.isNotBlank(filterFieldAPI)?filterFieldAPI:'Name';
                List<blng__Invoice__c> invList = Database.query('SELECT Id,Name,(SELECT Id,NoteID__c from Collection_Notes__r) FROM blng__Invoice__c WHERE '+String.escapeSingleQuotes(filterFieldAPI)+' = \''+String.escapeSingleQuotes(invWrap.invoiceNumber)+'\'');
                                
                resWrap.status = 'Error';
                resWrap.message = 'No Invoice found with Invoice Number '+invWrap.invoiceNumber;
                if(!invList.isEmpty())
                {
                    if(invWrap.collectionNotes != null && !invWrap.collectionNotes.isEmpty())
                    {
                        Map<String,Collection_Note__c> collectionNotesMap =  getInvoiceCollectionNotesMap(invList.get(0).Collection_Notes__r);

                        for(CollectionNote cn :invWrap.collectionNotes)
                        {
                            Collection_Note__c cNote =  new Collection_Note__c();
                            cNote.Invoice__c     = invList.get(0).Id;
                            cNote.NoteID__c     = cn.noteID;
                            cNote.Note_Date__c  = cn.noteDate;
                            cNote.Note__c       = cn.note;
                            cNote.Note_Type__c  = cn.type;
                            cNote.User__c       = cn.user;
                            cNote.Account_Number__c     = cn.accountNumber;
                            cNote.Invoice_Reference_Number__c   = cn.invoiceReferenceNumber;

                            if(String.isNotBlank(cn.noteID) && collectionNotesMap.containsKey(cn.noteID))
                            {
                                cNote.Id = collectionNotesMap.get(cn.noteID).id;
                            }
                            listCollectionNotes.add(cNote);
                        }
                    }
                    if(Schema.sObjectType.Collection_Note__c.isUpdateable() && !listCollectionNotes.isEmpty())
                    {
                        upsert listCollectionNotes;
                    }
                    resWrap.status = 'Success';
                    resWrap.message = 'Collection Note updated';
                }
            }
        }catch (Exception e) 
        {
            resWrap.status = 'Error';resWrap.message = e.getMessage();
            system.debug(logginglevel.DEBUG,'Error_Message__c --> '+ resWrap.message +' At Line' + e.getLineNumber()); system.debug(logginglevel.DEBUG,' Trace --> '+ e.getStackTraceString());
        }
        return resWrap;
    }

    /************************** UTILITY METHORDS **************************/
    /**
    * @description : Methord to get a map of Collection Notes where key is Unique Id
    * @param collectionNotes List of Collection Notes
    * @return Map<String,Collection Notes> 
    */
    private static Map<String,Collection_Note__c> getInvoiceCollectionNotesMap(list<Collection_Note__c> collectionNotes)
    {
        Map<String,Collection_Note__c> collectionNotesMap = new Map<String,Collection_Note__c>();

        for(Collection_Note__c cNote:collectionNotes)
        {
            collectionNotesMap.put(cNote.NoteID__c,cNote);
        }
        return collectionNotesMap;
    }

    /************************** Data Wrapper Class **************************/
    /**
    * @description  This method is used to update Invoice fields    
    */
    public class InvoiceWapper{
        public String invoiceNumber;	    //INV-00015 [Required]  
        public CollectionNote[] collectionNotes;
    }

    /**
    * @description  This method is used to update Invoice fields    
    */
    public class CollectionNote {
        public String accountNumber;	        // 0001
		public String invoiceReferenceNumber;	// 006
		public String noteID;	                // CN-005
		public String note;	                    // Text
		public String type;	                    //Callback
        public String user;	                    //user
		public DateTime noteDate;	           //2019-08-18T00:00:00
    }

    /**
    * @description  This Class is to return Reponse Data
    */
    global class ResponseData 
    {
        public String status;	        // Success / Error /Unknown
		public String message;	        // 006
    }
}

// {"invoiceNumber":"INV-0025","collectionNotes":[{"accountNumber":"0001","invoiceReferenceNumber":"006","noteID":"CN-005","note":"Chasing - 1st contact; copies of amended inv sent to contact@rechner.com asking for confirmation they can be paid. [18 Aug]","type":"Callback","noteDate":"2019-08-18T00:00:00"},{"accountNumber":"0001","invoiceReferenceNumber":"006","noteID":"CN-008","note":"Chasing - 1st contact; copies of amended inv sent to contact@rechner.com asking for confirmation they can be paid. [18 Aug]","type":"Callback","noteDate":"2021-11-18T00:00:00"}]}