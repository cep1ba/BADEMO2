/**
 * Created by BA on 19/12/2023.
 */
global without sharing class QuoteSLAController {
    private static String errorMessage;
    
    public class Input {
        @InvocableVariable public Integer SLA;
    }

    public class Output {
        @InvocableVariable public Datetime dueDate;

        public Output (Datetime dueDate) {
            this.dueDate = dueDate;
        }
    }
    
    @InvocableMethod
    public static List<Output> getDueDAte(List<Input> input) {
        List<Output> outputs= new List<Output>();
        BusinessHours dhDefault= [SELECT id from BusinessHours Where IsDefault = true];
        Integer SLAMilliseconds = input.get(0).SLA * 60 * 60 *1000;
        
        Output output = new Output(BusinessHours.add(dhDefault.Id,Datetime.now(), SLAMilliseconds));
        
        
        outputs.add(output);
        return outputs;
    }
}