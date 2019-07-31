global class LikeButton2 implements FSL.CustomGanttServiceAppointmentAction{
	global String action(List<Id> serviceAppoitmentsIds, Datetime ganttStartDate, Datetime ganttEndDate, Map<String, Object> additionalParameters) {
       
        List<ServiceAppointment> saList = [SELECT AppointmentNumber, FSL__GanttIcon__c FROM ServiceAppointment WHERE Id in : serviceAppoitmentsIds];
        String reply = '';
        List<String> saNames = new List<String>(); 

        for (ServiceAppointment s : saList) {
            s.FSL__GanttIcon__c = 'https://image.freepik.com/free-icon/facebook-like-hand-symbol-outline_318-56026.jpg';
            saNames.add(s.AppointmentNumber);
        }
       
        upsert saList;

        reply = String.join(saNames, ', ');
        return 'Service Appointments successfully liked: ' + reply;
    }
}