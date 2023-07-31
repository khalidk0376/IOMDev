/**
 * File:        AccountRelatedAccountValidationCtrl
 * Date:        7 jan 2020
 * Created By : Girikon(Ashish)
 * Test Class : AccountRelatedAccountValidation_Test
 * *************************************************************************
 * Description: This class calls billing address API to validate the Account billing  Addess.
 * *************************************************************************
 * History:     Girikon(Ashish) 28 Feb 2020 - Removed CallOut IML2R-795 
 */
public class AccountRelatedAccountValidationCtrl implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    
    /* Variables */
    public string opportunityId            { get; set; }
    public string errorMsg             { get; set; }
    public string error                { get; set; }
    public List <Account> accountLst   { get; set; }
    public String callVerb             { get; set; }
    public String serviceName          { get; set; }
    public String integrationUrl       { get; set; }
    public String integrationUsername  { get; set; }
    public String integrationPassword  { get; set; }
    public Id batchProcessId           { get; set; }
    public String batchProgress        { get; set; }    
    public set <Id> accIds             { get; set; }
    public Boolean batchProcessEnabled { get; set; }
    public String batchStatus          { get; set; }
    public String redirectUrl          { get; set; }

    // Private Id opportunityId;
    private map<Id,Id> accountContactmap;
    public map<Id,Contact> accountIdContactmap;
    public Boolean oppAddressValid;
    public Boolean billingAddressvalid;
    
    /* Constructor */
    
    public AccountRelatedAccountValidationCtrl(ApexPages.StandardController controller) {
        batchProgress = '0';
        batchStatus   = 'init';
        error         = '';
        opportunityId     = '';
        redirectUrl   = '';
        opportunityId     = ApexPages.currentPage( ).getParameters( ).get('id');
        oppAddressValid = false;
        billingAddressvalid = false;
    }
    public AccountRelatedAccountValidationCtrl( set <Id> accIds, map<Id,Contact> primaryContactMap,Id opportunityId) 
    {
        errorMsg                 = '';
        this.accIds              = accIds;
        this.opportunityId       = opportunityId;
        this.callVerb            = 'POST';
        this.serviceName         = 'VALIDATE_CUSTOMER';
        this.integrationUrl      = '';
        this.integrationUsername = '';
        this.integrationPassword = '';
        accountLst               = new List <Account> ( );
        accountContactmap        =  new map<Id,Id>();
        this.accountIdContactmap      =  primaryContactMap; // Map Of Acc id and it's primary Contact
        oppAddressValid = false;
        billingAddressvalid = false;
    }
    public Pagereference validateAccountBillingAddress( ) 
    {        
        redirectUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + opportunityId;
        Pagereference pg = new PageReference('/lightning/r/opportunity/' + opportunityId +'/view');
        /** new Function  */    
        set<Id> setConIds = new Set<Id>();
        if(String.isNotBlank(opportunityId))
        {
            List<opportunity> listopp = New List<opportunity>();
            listopp = [Select id,Billing_Contact__c,Address_Status__c,Opportunity_Contact__c,Partner_Account__c,Account.Address_Status__c,AccountId,Bill_To_Account__c,Bill_To_Account__r.Address_Status__c from opportunity where id =: opportunityId];

            oppAddressValid =  (listopp.get(0).Account.Address_Status__c == 'Valid')?true:false;
            billingAddressvalid = (listopp.get(0).Bill_To_Account__r.Address_Status__c == 'Valid')?true:false;
            
            System.debug('listopp : ' + listopp);
            if(!listopp.isEmpty() && listopp.get(0).Address_Status__c == 'Valid')
            {
                error = 'Opportunity Address Already Verified !';
                batchStatus = 'stop';
                return null;
                //return pg;                
            }    
            if(String.isBlank(listopp.get(0).Billing_Contact__c) || String.isBlank(listopp.get(0).Bill_To_Account__c))
            {
                error = 'Bill To Account & Billing Contact can not be blank';
                batchStatus = 'stop';
                return null;
            }
            if(String.isBlank(listopp.get(0).Opportunity_Contact__c) || String.isBlank(listopp.get(0).AccountId))
            {
                error = 'Account & Opportunity Contact can not be blank';
                batchStatus = 'stop';
                return null;
            }
            if(!listopp.isEmpty() && oppAddressValid && billingAddressvalid )
            {
                listopp[0].Address_Status__c = 'Valid';
                update listopp;
                batchStatus = 'stop';
                return pg;
            }
            if(!listopp.isEmpty() && listopp.get(0).Billing_Contact__c != null && !billingAddressvalid)
            {
                setConIds.add(listopp.get(0).Billing_Contact__c);
                System.debug(listopp.get(0).Billing_Contact__c +'  billingAddressvalid : ' + oppAddressValid);
            }
            if(!listopp.isEmpty() && listopp.get(0).Opportunity_Contact__c != null && !oppAddressValid)
            {
                setConIds.add(listopp.get(0).Opportunity_Contact__c);
                System.debug(listopp.get(0).Opportunity_Contact__c+'   : oppAddressValid : ' + oppAddressValid);
            }
            System.debug('setConIds : ' + setConIds);
        }

        /** Old Finction  */

        if(!setConIds.isEmpty()) 
        {
            /*
            List <Contact> contacts = [ SELECT Id,AccountId,Email, Phone, Title, Name, FirstName, LastName, AccountId,MailingStreet, MailingCity, MailingPostalCode, MailingState, MailingCountry, Fax,Address_Verified__c FROM Contact WHERE Id in : setConIds ];
            List <String> accIds = new List <String> ( );
            if( contacts.size( ) > 0 ) 
            {
                for( AccountContactRelation accConRel : [ SELECT AccountId From AccountContactRelation WHERE opportunityId = : setConIds]) 
                {
                    accIds.add(accConRel.AccountId);
                }
            }
            */    
            map<Id,Contact> accConMap = new map<Id,Contact>();
            for(Contact con: [SELECT Id,AccountId,Email, Phone, Title, Name, FirstName, LastName,MailingStreet, MailingCity, MailingPostalCode, MailingState, MailingCountry, Fax,Address_Verified__c FROM Contact WHERE Id in : setConIds])
            {
                accConMap.put(con.AccountId,con);
            }
            System.debug('accConMap '+accConMap);
            if(!accConMap.isEmpty()) 
            {
                batchStatus         = 'start';
                batchProcessEnabled = TRUE;
                AccountRelatedAccountValidationCtrl accAddValidBtch = new AccountRelatedAccountValidationCtrl(accConMap.keySet(),accConMap,opportunityId);
                if(!Test.isRunningTest())
                {
                    batchProcessId = Database.executeBatch(accAddValidBtch, 1 );    
                }
            }
        }
        return null;
    }

    /**  batch process **/
    public Database.QueryLocator start( Database.BatchableContext bc ) 
    {
        
        return Database.getQueryLocator( [ SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, Phone, Fax, blng__BillToContact__c, Tax_Id__c, BillingCountryCode, BillingStateCode FROM Account WHERE ID IN : accIds ] );
    }
    public void execute( Database.BatchableContext bc, List <Account> scope ) {
        for( Account acc : scope ) 
        {
            if(accountIdContactmap.containsKey(acc.id))
            {    ValidateCustomerRequest vCustomerRequest = new ValidateCustomerRequest(acc,accountIdContactmap.get(acc.id));
                //System.debug('vCustomerRequest === ' + vCustomerRequest);
                String validateCustomerPayload = ValidateCustomerRequest.serializeToString( vCustomerRequest );
                System.debug('validateCustomerPayload === ' + validateCustomerPayload);
                String response = '';
            
                // response = OutboundCallHelper.makeClientIdTypeHttpRequest( integrationUrl, callVerb, validateCustomerPayload, integrationUsername, integrationPassword );
                
                // Dummy Response till the End point Is Avalible 
                response = '{"Header":{"Systems":{"SystemReference":"0011F000009bKCwQAM","MessageStatusText":"","MessageStatus":"","MessageDate":"2018-07-17","CallingApplication":"SFDC-GE"},"DataPacket":[]},"Content":{"AddressWrapper":{"Person":{"LastName":"testLN","FirstNames":"TestFN"},"Customer":{"CustomerNumberType":"web","CustomerNumber":"","CustomerGroup":"","CustomerEmail":"test.test@gmail.com"},"Address":{"State":"Delhi","PostalCode":"110025","PhoneNumber":"1234567890","PhoneExtension":"","Organisation":"","FaxNumber":"1234567890","Department":"","Country":"IN","City":"Las Vegas","AddressLine2":"","AddressLine1":"456 Zepplin Avenue"}}}}';

                System.debug('response === ' + response);        
                ValidateCustomerResponse customerResponse = ValidateCustomerResponse.parse( response );
                if( customerResponse.Header != null && ( String.isBlank( customerResponse.Header.Systems.MessageStatus ) || customerResponse.Header.Systems.MessageStatus == 'OK' || customerResponse.Header.Systems.MessageStatus == 'UPDATED' ) ) 
                {
                    acc.Address_Status__c = 'Valid';
                } else 
                {
                    for( ValidateCustomerResponse.Message message: customerResponse.Messages ) 
                    {
                        errorMsg += '[ <a href="/'+ acc.Id +'" target="_blank">' + acc.Name +'</a> : ' + message.MessageType + ' ::' + message.MessageText +' ] <br></br>';
                    }
                    acc.Address_Status__c = 'Error';
                }
                accountLst.add( acc );
            }else
            {
                System.debug('Error!');
            }     
        }
    }
    public void finish( Database.BatchableContext bc ) 
    {
        list<Contact> listContact = new List<Contact>();
        for( Account acc : accountLst )
        {
            System.debug('acc '+acc);
            if(acc.Address_Status__c == 'Valid') 
            {
                Contact con = accountIdContactmap.get(acc.id);
                con.Address_Verified__c = TRUE;
                listContact.add(con);
                accountIdContactmap.remove(acc.id); 
            }
        }
        //Database.update(accountLst,false);
        update accountLst;
        update listContact;
        if(accountIdContactmap.isEmpty())
        {
            opportunity opp = new opportunity();
            opp.Id = opportunityId;
            opp.Address_Status__c = 'Valid';
            update opp;
        }
    }
    public void batchProcess( ) {
        AsyncApexJob aaj;
        if( String.isNotEmpty( batchProcessId ) && batchStatus == 'start' ) 
        {   
            aaj = [ SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors FROM AsyncApexJob WHERE ID =: batchProcessId ];
            try {
                Integer process = aaj.JobItemsProcessed;
                Integer tot     = aaj.TotalJobItems;
                batchProgress   = String.valueOf( ( process * 100 ) / tot );
            } catch( MathException mathError ) 
            {
                System.debug('mathError !');
            }
            if( aaj.Status == 'Completed' ) 
            {
                batchProcessEnabled = false;
                batchStatus         = 'stop';
            }
        }
    }
    public pageReference back2opportunity( ) {
        PageReference pageRef = new PageReference('/'+opportunityId);
        return pageRef;
    }
}