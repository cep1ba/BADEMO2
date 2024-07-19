@IsTest public with sharing class SigninControllerTest {
    @IsTest(SeeAllData=true) 
    public static void test() {         
        SigninController controller = new SigninController();
        controller.username = 'test@force.com';
        controller.password = 'Password1'; 
        
        System.assertEquals(controller.login(),null);   
    }    
}