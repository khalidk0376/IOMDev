/**
 * Created By   :   Girikon(Prashant)
 * Created On   :   Nov 18 2019
 * @description :   [States and Countries cannot be created by deploying Address Settings. This class submits all states into the Setup screen using page scraping.]
 * Test Class   :   StateCodeServices_Test ()
 * Modification Log----- 
 * Modified by  : 
**/

public inherited sharing class StateCodeServices implements Database.Batchable<String>, Database.AllowsCallouts, HttpCalloutMock {

    public String stateCodes {get; set;}
    ApexPages.StandardController controller;
    
    public StateCodeServices(ApexPages.StandardController controller){
        this.controller = controller;
        this.stateCodes = Json.serializePretty(scope2state);
    }
    
    public PageReference action(){
        if (this.controller.getId() != null){
            this.controller.reset();
            return null;
        } else {
            List<AsyncApexJob> jobs = [SELECT Id FROM AsyncApexJob WHERE CompletedDate = null AND ApexClass.Name = 'StateCodeServices'];
            if (!jobs.isEmpty()){ 
                return new PageReference('/apex/StateCodesServicesVF?id=' + jobs[0].Id); 
            } else {
                return null;
            }
        }
    }
    
    public PageReference startBatch() {
        try{
            Object scope2state = Json.deserialize(stateCodes, Map<String,String>.class);
            Id jobId = run((Map<String,String>)scope2state);
            PageReference redirect = new PageReference('/apex/StateCodesServicesVF');
            redirect.getParameters().put('id', jobId);
            redirect.setRedirect(true);
            return redirect;
        } catch (Exception e) {
            ApexPages.addMessages(e);
            return null;
        }
    }
    
    public void abortBatch(){
        try {
            System.AbortJob(controller.getId());
            this.controller.reset();
        } catch (Exception e) {
            ApexPages.addMessages(e);
        }
    }
    
    /**
     * Runs batch to create 4,936 default ISO states
     */
    static public Id run(Map<String,String> scope2state) {
        if (isRunning()) {
            throw new AsyncException('Batch already running');
        }
        StateCodeServices batch = new StateCodeServices();
        if (scope2state != null) {
            batch.scope2state = scope2state;
        }
        return Database.executeBatch(batch, 1);
    }

    /**
     * Avoid simultaneous jobs
     */
    static Boolean isRunning(){
        return ![
            SELECT Id
            FROM AsyncApexJob
            WHERE CompletedDate = null
            AND ApexClass.Name = 'StateCodes'
        ].isEmpty();
    }
    
    /**
     * Private constructor to avoid
     * running with wrong scope size
     */
    @TestVisible StateCodeServices(){
        System.debug('This is StateCodeServices');
    }

    /**
     * Iterate all codes so we get 1
     * execution context for each state
     */
    public Iterable<String> start(Database.BatchableContext context) {
        // check remote site setting to base url
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint(Url.getOrgDomainUrl().toExternalForm());
        if (!Test.isRunningTest()) {
            new Http().send(request);
        }
        
        return new List<String>(scope2state.keySet());
    }

    /**
     * Attempt to create each state inside its country,
     * failures are written to documents in user folder
     */
    public void execute(Database.BatchableContext context, List<String> scopes) {
        List<Document> documents = new List<Document>();
        
        for (String scope : scopes) {
            String countryCode = scope.substringBefore('-');
            String stateCode = scope.substringAfter('-');
            String stateName = scope2state.get(scope);
            
            try {
                newState(countryCode, stateCode, stateName);
            } catch (HandledException e) {
                // eg state already exists
                continue;
            } catch (UnsupportedOperationException e) {
                // save in document
                documents.add(new Document(
                    Name = scope + '.txt',
                    FolderId = UserInfo.getUserId(),
                    Body = Blob.valueOf(e.getMessage()
                )));
            }
        }
        insert documents;
    }

    /**
     * Email to notify the
     * batch has finished
     */
    public void finish(Database.BatchableContext context) {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setSaveAsActivity(false);
        email.setTargetObjectId(UserInfo.getUserId());
        email.setSubject('State Codes - batch completed');
        email.setPlainTextBody('See results in Documents and Apex Jobs page');
        Messaging.sendEmail(new List<Messaging.Email>{email});
    }
    
    /**
     * Attempting two callouts helps mitigate 'Read timed out' exceptions
     * (this class makes only idempotent requests to configure new states)
     */
    static HttpResponse sendTwice(HttpRequest request) {
        request.setTimeout(60 * 1000);
        try {
            // attempt 1
            return new Http().send(request);
        } catch (CalloutException e) {
            // attempt 2
            if (Test.isRunningTest()) {
                throw e; 
            } else { 
                return new Http().send(request);
            }
        }
    }

    /**
     * Grab the HTML for the 'Configure New State' form
     * and post back to the server with name/code values
     */
    public void newState(String countryCode, String stateCode, String stateName) {
        String orgUrl = Url.getOrgDomainUrl().toExternalForm();
        // extract form page
        HttpRequest getRequest = new HttpRequest();
        getRequest.setMethod('GET');
        getRequest.setEndpoint(orgUrl + '/i18n/ConfigureNewState.apexp?countryIso=' + countryCode);
        getRequest.setHeader('Cookie', 'sid=' + UserInfo.getSessionId());
        
        if (Test.isRunningTest()) {
            Test.setMock(HttpCalloutMock.class, this);
        }
        HttpResponse getResponse = sendTwice(getRequest);
        
        // extract viewstate params (country code is stored inside here)
        String viewState = getResponse.getBody().substringBetween('com.salesforce.visualforce.ViewState" value="', '"');
        String viewStateMac = getResponse.getBody().substringBetween('com.salesforce.visualforce.ViewStateMAC" value="', '"');
        String viewStateCsrf = getResponse.getBody().substringBetween('com.salesforce.visualforce.ViewStateCSRF" value="', '"');
        String viewStateVersion = getResponse.getBody().substringBetween('com.salesforce.visualforce.ViewStateVersion" value="', '"');
        
        // prepare post data
        PageReference postdata = new PageReference('');
        Map<String,String> parameters = postdata.getParameters();
        
        // add new state form fields
        parameters.put('configurenew:j_id1', 'configurenew:j_id1');
        parameters.put('configurenew:j_id1:blockNew:j_id43:addButton', 'Add');
        parameters.put('configurenew:j_id1:blockNew:j_id9:nameSectionItem:editName', stateName);
        parameters.put('configurenew:j_id1:blockNew:j_id9:codeSectionItem:editIsoCode', stateCode);
        parameters.put('configurenew:j_id1:blockNew:j_id9:intValSectionItem:editIntVal', stateName);
        
        // add viewstate params
        parameters.put('com.salesforce.visualforce.ViewState', viewState);
        parameters.put('com.salesforce.visualforce.ViewStateVersion', viewStateVersion);
        parameters.put('com.salesforce.visualforce.ViewStateMAC', viewStateMac);
        parameters.put('com.salesforce.visualforce.ViewStateCSRF', viewStateCsrf);
        
        // submit form
        HttpRequest postRequest = new HttpRequest();
        postRequest.setMethod('POST');
        postRequest.setBody(postdata.getUrl().substringAfter('?'));
        postRequest.setEndpoint(orgUrl + '/i18n/ConfigureNewState.apexp');
        postRequest.setHeader('Cookie', 'sid=' + UserInfo.getSessionId());
        postRequest.setHeader('Content-Type', 'application/x-www-form-urlencoded');

        if (Test.isRunningTest()) {
            Test.setMock(HttpCalloutMock.class, this);
        }
        HttpResponse postResponse = sendTwice(postRequest);
        
        if (postResponse.getBody().contains('<h4>Errors</h4>')){
            String message = postResponse.getBody().substringBetween('<li style="padding-top:5px">', '</li>').trim();
            throw new HandledException(message);
        }
        
        if (postResponse.getBody().contains('<h4>Error:</h4>')){
            String message = postResponse.getBody().substringBetween('<h4>Error:</h4></span>', '<').trim();
            throw new HandledException(message);
        }
        
        if (postResponse.getBody().contains('You are missing information')){
            String message = 'Country does not exist: ' + countryCode;
            throw new HandledException(message);
        }
        
        if (!postResponse.getBody().contains('success=true')){
            String message = 'Cannot find success redirect: ' + postResponse.getBody();
            throw new UnsupportedOperationException(message);
        }
    }
    
    public HttpResponse respond(HttpRequest request) {
        HttpResponse response = new HttpResponse();
        if (request.getMethod() == 'GET') {
            response.setBody('<html></html>');
        }
        if (request.getMethod() == 'POST') {
            response.setBody('<a href="/?success=true">OK</a>');
        }
        return response;
    }

    /**
     * All ISO assigned states in the format:
     * {CountryCode}-{StateCode} = {StateName}
     */
    Map<String,String> scope2state = new Map<String,String> {
        'US-AK' => 'Alaska',
        'US-AL' => 'Alabama',
        'US-AR' => 'Arkansas',
        'US-AZ' => 'Arizona',
        'US-CA' => 'California',
        'US-CO' => 'Colorado',
        'US-CT' => 'Connecticut',
        'US-DC' => 'District of Columbia',
        'US-DE' => 'Delaware',
        'US-FL' => 'Florida',
        'US-GA' => 'Georgia',
        'US-HI' => 'Hawaii',
        'US-IA' => 'Iowa',
        'US-ID' => 'Idaho',
        'US-IL' => 'Illinois',
        'US-IN' => 'Indiana',
        'US-KS' => 'Kansas',
        'US-KY' => 'Kentucky',
        'US-LA' => 'Louisiana',
        'US-MA' => 'Massachusetts',
        'US-MD' => 'Maryland',
        'US-ME' => 'Maine',
        'US-MI' => 'Michigan',
        'US-MN' => 'Minnesota',
        'US-MO' => 'Missouri',
        'US-MS' => 'Mississippi',
        'US-MT' => 'Montana',
        'US-NC' => 'North Carolina',
        'US-ND' => 'North Dakota',
        'US-NE' => 'Nebraska',
        'US-NH' => 'New Hampshire',
        'US-NJ' => 'New Jersey',
        'US-NM' => 'New Mexico',
        'US-NV' => 'Nevada',
        'US-NY' => 'New York',
        'US-OH' => 'Ohio',
        'US-OK' => 'Oklahoma',
        'US-OR' => 'Oregon',
        'US-PA' => 'Pennsylvania',
        'US-RI' => 'Rhode Island',
        'US-SC' => 'South Carolina',
        'US-SD' => 'South Dakota',
        'US-TN' => 'Tennessee',
        'US-TX' => 'Texas',
        'US-UT' => 'Utah',
        'US-VA' => 'Virginia',
        'US-VT' => 'Vermont',
        'US-WA' => 'Washington',
        'US-WI' => 'Wisconsin',
        'US-WV' => 'West Virginia',
        'US-WY' => 'Wyoming'
    };
}