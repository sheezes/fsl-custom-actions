/*
    Author:         Ori Fishman
    
    Type:           Service Appointment custom action
    Description:    This action will toggle the In Jeopardy checkbox from true to false and vice versa.
*/
global class toggleServiceAppointmentJeopardy implements FSL.CustomGanttServiceAppointmentAction {
 
    global String action(List<Id> serviceAppoitmentsIds, Datetime ganttStartDate, Datetime ganttEndDate, Map<String, Object> additionalParameters) {
       
        List<ServiceAppointment> saList = [SELECT InJeopardy__c, AppointmentNumber FROM ServiceAppointment WHERE Id in : serviceAppointmentsIds];
        String reply = '';
        List<String> saNames = new List<String>();

        for (ServiceAppointment s : saList) {
            s.InJeopardy__c = !s.InJeopardy__c;
            saNames.add(s.AppointmentNumber);
        }
       
        upsert saList;

        reply = String.join(saNames, ', ');
        return 'Service Appointments successfully processed: ' + reply;
    }
   
}