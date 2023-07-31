/**
 * @description : Class containing tests for SiteRegisterController
 */
@IsTest public with sharing class SiteRegisterControllerTest {
    static testMethod void testRegistration() {
        SiteRegisterController controller = new SiteRegisterController();
        controller.username = 'test@force.com';
        controller.email = 'test@force.com';
        controller.communityNickname = 'test';
        System.assert(controller.registerUser() == null, 'registerUser will always return null when the page isnt accessed as a guest user');    
        
        controller.password = 'abcd1234';
        controller.confirmPassword = 'abcd123';
        System.assert(controller.registerUser() == null, 'registerUser will always return null when the page isnt accessed as a guest user');  
    }
}