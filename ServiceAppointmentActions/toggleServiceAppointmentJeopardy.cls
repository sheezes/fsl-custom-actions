/*
    Author:         Ori Fishman
    
    Type:           Service Appointment custom action
    Description:    This action will toggle the In Jeopardy checkbox from true to false and vice versa.
*/

public class toggleServiceAppointmentJeopardy implements FSL.CustomGanttServiceAppointmentAction {
 
    public String action(List<Id> serviceAppoitmentsIds, Datetime ganttStartDate, Datetime ganttEndDate, Map<String, Object> additionalParameters) {
       
        List<ServiceAppointment> sas = [SELECT InJeopardy__c, AppointmentNumber FROM ServiceAppointment WHERE Id in : serviceAppoitmentsIds];
        String reply = '';
        List<String> saNames = new List<String>();

        for (ServiceAppointment s : sas) {
            s.InJeopardy__c = !s.InJeopardy__c;
            saNames.add(s.AppointmentNumber);
        }
       
        upsert sas;

        reply = String.join(saNames, ', ');
        return 'Service Appointments Successfully processed: ' + reply;
    }
   
}