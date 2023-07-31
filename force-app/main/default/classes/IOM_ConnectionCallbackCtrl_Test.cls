/**
* File         :   IOM_ConnectionCallbackCtrl_Test 
* Project      :   Order & Billing Plateform
* Created Date :   24th Jan 2022
* Created By   :   Girikon(Ashish)
* ******************************************************************************************************
 @description : Test Class to cover IOM_ConnectionCallbackCtrl
*******************************************************************************************************
* Modification log :
* 1. 
*/
@isTest
private with sharing class IOM_ConnectionCallbackCtrl_Test 
{
    @isTest static void testGetFirstAccesstoken() 
    {
        Map<String,String> mapURIBody = new Map<String,String>();
        string resJSON = '{"access_token":"SESSION_ID_REMOVED","refresh_token":"5Aep861G2bBygx8kRWkcDuPiQZM54wa1tC.eGQodJtQqTP96dKOppiRP_c_meds53_dn.HiVx8JC.8ZX","signature":"pjtsaEf2uPghKHynhd1NWIkm/5HoPAbNIoOiF4=","scope":"refresh_token full","id_token":"eyJraWQiOiIyMzYiLCJiLCJhbGciOiJSUzI1NiJ9.eyJhdF9oYXNoIjoicXBNSmZaeVpOWVBjM29UeXB4NmVKUSIsInN1YiI6Imh0dHBzOi8vdGVzdC5zYWxlc2ZvcmNlLmNvbS9pZC8wMEQwNTAwMDAwMDhuaVVFQVEvMDA1NFAwMDAwMEJ3RmFiwiYXVkIjoiM01WRzlGeV8xWm5nYlhxT0RZXzdBWTUyZUE2aFJscG16ejZGazdHaWpoYlBMbklFYlpWa0JEMWRucXVyQUtCV0xteGloa0wxUFc5UzdjMXY3aV9jUiIsImlzcyI6Imh0dHBzOi8vdGVzdC5zYWxlc2ZvcmNlLmNvbSIsImV4cCI6MTY0MzAxNzM1MSwiaWF0IjoxNjQzMDE3MjMxfQ.by7GJNDK_KBxfYv4mLNTfaK6yarWBKBj7s7pd6EokO-28TWuhx-6wZMbwm10vlo0fD0K7SqQM28pSQYdht2yW9oZb758r0-tDGPb2RPg5d5DiikBjI47Sd7_4Cbn6TRvuZvQnEAojEyd1TzRs5KhBwOVl3yBu_auJJvk98sDn7y8H7f5GmPj0mRbkvAYnjWM4JCAEEWKAAfBuM_bRiGCtGvUC2JD_s7RFjRexEIoObQ4c_7hCAVaJt-H7f7dlJbCBtaT5AiT0O1RFUDCYLV4vrsLriDpN3f2bNi_X95fIy0UvMrxQZB0rphAoj7_cJ5fYg0VQA0jeECWNyecrcS59bllWHR6-DxVtWczGSAAX1mSdOfK38_1fWbvfo-iqJOEPWB0Al9zqcjwYKYsSN9CKtyJ4CZni5JVpEqYDtztfXll25dW9xHqaTGRRPDHQVI3cvsjOIOrwZllcptUFpYeZLYaqDu92-F_i5i5anmi5ZIR6YesfLbNv8Zb-EV27NzrTYqFINpP6RHogma_vFbVzV8gdfPo_fE-2l4GClEjnCTvEYI2GvcpBwUPWrgzZFF8NM_NvhWRz9_KYOBPDfy6-wmFT_T2HgtynckY5n35b-0fxdhRkEXfweBVFnbMYiu5Dr0LcEK6rQ","instance_url":"https:/Test.o.my.salesforce.com","id":"https://test.salesforce.com/id/00D000008niUEAQ/000BwFaHQAV","token_type":"Bearer","issued_at":"1643017231442"}';
        mapURIBody.put('services/oauth2/token','200###'+resJSON);

        Test.setMock(HttpCalloutMock.class, new IOM_ConnectionCallbackMock(mapURIBody));        
        IOM_ConnectionCallbackCtrl.IOM_REFRESH_TOKEN_FILE_NAME = 'My_Test_File_001';
        ApexPages.CurrentPage().getparameters().put('code','hfxghkshitvbnfnjiocbwajnxiuiby');
        IOM_ConnectionCallbackCtrl conObj = new IOM_ConnectionCallbackCtrl();
        Pagereference pg = conObj.initAction();
        System.assertNotEquals(null,pg,'authentication Failed');
    }
    @isTest static void testGetRefreshTokenfromSystem() 
    {
        Map<String,String> mapURIBody = new Map<String,String>();
        string resJSON = '{"access_token":"SESSION_ID_REMOVED","refresh_token":"5Aep861G2bBygx8kRWkcDuPiQZM54wa1tC.eGQodJtQqTP96dKOppiRP_c_meds53_dn.HiVx8JC.8ZX","signature":"pjtsaEf2uPghKHynhd1NWIkm/5HoPAbNIoOiF4=","scope":"refresh_token full","id_token":"eyJraWQiOiIyMzYiLCJiLCJhbGciOiJSUzI1NiJ9.eyJhdF9oYXNoIjoicXBNSmZaeVpOWVBjM29UeXB4NmVKUSIsInN1YiI6Imh0dHBzOi8vdGVzdC5zYWxlc2ZvcmNlLmNvbS9pZC8wMEQwNTAwMDAwMDhuaVVFQVEvMDA1NFAwMDAwMEJ3RmFiwiYXVkIjoiM01WRzlGeV8xWm5nYlhxT0RZXzdBWTUyZUE2aFJscG16ejZGazdHaWpoYlBMbklFYlpWa0JEMWRucXVyQUtCV0xteGloa0wxUFc5UzdjMXY3aV9jUiIsImlzcyI6Imh0dHBzOi8vdGVzdC5zYWxlc2ZvcmNlLmNvbSIsImV4cCI6MTY0MzAxNzM1MSwiaWF0IjoxNjQzMDE3MjMxfQ.by7GJNDK_KBxfYv4mLNTfaK6yarWBKBj7s7pd6EokO-28TWuhx-6wZMbwm10vlo0fD0K7SqQM28pSQYdht2yW9oZb758r0-tDGPb2RPg5d5DiikBjI47Sd7_4Cbn6TRvuZvQnEAojEyd1TzRs5KhBwOVl3yBu_auJJvk98sDn7y8H7f5GmPj0mRbkvAYnjWM4JCAEEWKAAfBuM_bRiGCtGvUC2JD_s7RFjRexEIoObQ4c_7hCAVaJt-H7f7dlJbCBtaT5AiT0O1RFUDCYLV4vrsLriDpN3f2bNi_X95fIy0UvMrxQZB0rphAoj7_cJ5fYg0VQA0jeECWNyecrcS59bllWHR6-DxVtWczGSAAX1mSdOfK38_1fWbvfo-iqJOEPWB0Al9zqcjwYKYsSN9CKtyJ4CZni5JVpEqYDtztfXll25dW9xHqaTGRRPDHQVI3cvsjOIOrwZllcptUFpYeZLYaqDu92-F_i5i5anmi5ZIR6YesfLbNv8Zb-EV27NzrTYqFINpP6RHogma_vFbVzV8gdfPo_fE-2l4GClEjnCTvEYI2GvcpBwUPWrgzZFF8NM_NvhWRz9_KYOBPDfy6-wmFT_T2HgtynckY5n35b-0fxdhRkEXfweBVFnbMYiu5Dr0LcEK6rQ","instance_url":"https:/Test.o.my.salesforce.com","id":"https://test.salesforce.com/id/00D000008niUEAQ/000BwFaHQAV","token_type":"Bearer","issued_at":"1643017231442"}';
        mapURIBody.put('services/oauth2/token','200###'+resJSON);

        Test.setMock(HttpCalloutMock.class, new IOM_ConnectionCallbackMock(mapURIBody));     
        Document document = new Document();
        document.Body = Blob.valueOf('5Aep861G2bBygx8kRWkcDuPiQZM54wa1tC.eGQodJtQ');
        document.ContentType = 'text/plain';
        document.DeveloperName = 'My_Test_File_002';
        document.IsPublic = true;
        document.Name = 'IOM Refresh Token Detail';
        document.FolderId = [select id from folder where name =: IOM_ConnectionCallbackCtrl.IOM_FOLDER_NAME].id;
        insert document;
        Test.startTest();
            IOM_ConnectionCallbackCtrl.IOM_REFRESH_TOKEN_FILE_NAME = 'My_Test_File_002';
            ApexPages.CurrentPage().getparameters().put('iomOppNum','IM-00026');
            ApexPages.CurrentPage().getparameters().put('compCode','CN-001');
            IOM_ConnectionCallbackCtrl conObj = new IOM_ConnectionCallbackCtrl();
            conObj.initAction();
        System.assertNotEquals(null,conObj.sessionId,'No authentication Id Found');
        Test.stopTest();
    }
    @isTest static void testStaticMethords() 
    {
        Boolean isReadyForIOMCallout	= IOM_ConnectionCallbackCtrl.isReadyForIOMCallout();
        Boolean hasIOMFolder			= IOM_ConnectionCallbackCtrl.hasIOMFolder();
        string authenticationURL		= IOM_ConnectionCallbackCtrl.getAuthenticationURL();
        System.assertEquals(false, isReadyForIOMCallout,'Document Alredy exist');
        System.assertEquals(true,hasIOMFolder,'NO IOM Details Folder found,Please Create and try again');
        System.assertNotEquals(null,authenticationURL,'No authentication URL Found');
    }
}