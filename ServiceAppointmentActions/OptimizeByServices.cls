/*	
	Type: 			Service appointment (gantt) custom action
	Description: 	This action will call resource schedule optimization with the selected services as "Unschedulable services".
 Optimization will optimize the resource's schedule and group work that is near by the selected services.
*/

global class OptimizeByServices implements FSL.CustomGanttServiceAppointmentAction {
 
    global String action(List<Id> serviceAppointmentsIds, Datetime ganttStartDate, Datetime ganttEndDate, Map<String, Object> additionalParameters) {
        FSL__Scheduling_Policy__c policy = [select id from FSL__Scheduling_Policy__c where Name = 'Customer First'];
        Id resourceId = [select ServiceResourceId from AssignedResource where ServiceAppointmentId in: serviceAppointmentsIds][0].ServiceResourceId;
        Id territoryId = [Select ServiceTerritoryId from ServiceAppointment where id in: serviceAppointmentsIds][0].ServiceTerritoryId;
        
        List<ServiceAppointment> saList = [SELECT AppointmentNumber, Latitude, Longitude FROM ServiceAppointment WHERE Id in : serviceAppointmentsIds];
        
        List<String> saNames = new List<String>();
        
        for (ServiceAppointment s : saList) {
            saNames.add(s.AppointmentNumber);
        }
       
        String reply = String.join(saNames, ', ');
        
        Decimal latitude = saList[0].Latitude, Longitude = saList[0].Longitude;
        List<ServiceAppointment> lstCandidates = [select id from ServiceAppointment where ServiceTerritoryId =: territoryId and EarliestStartTime <: ganttEndDate and DueDate>: ganttStartDate and StatusCategory = 'None' ORDER BY DISTANCE(Address, GEOLOCATION(:latitude, :longitude), 'mi') limit 100];
        Set<Id> candidatesSAs = new Set<Id>();
        
        for(ServiceAppointment sa : lstCandidates)
        {
            candidatesSAs.add(sa.Id);
        }
        
        Set<Id> unschedulableServices = new Set<Id>(serviceAppointmentsIds);
        
        
        FSL.OAAS oaas = new FSL.OAAS();
        Decimal radius = 2, timeForOptimization = 60;
        oaas.ResourceDayOptimization(resourceId, policy.Id, new FSL.TimeInterval(ganttStartDate, ganttEndDate), true, false, radius, candidatesSAs, unschedulableServices, timeForOptimization);
        
        return 'Optimization started for: ' + reply;
    }
   
}
