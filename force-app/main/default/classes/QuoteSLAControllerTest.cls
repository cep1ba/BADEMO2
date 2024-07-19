/**
 * Created by BA on 09/12/2023.
 */

@IsTest
private class QuoteSLAControllerTest {
    
    @IsTest
    static void test() {
        Test.startTest();
        QuoteSLAController.Input input = new QuoteSLAController.Input();
        input.sla=10;

        QuoteSLAController.getDueDAte(new List<QuoteSLAController.Input>{input});
        Test.stopTest();
    }

}