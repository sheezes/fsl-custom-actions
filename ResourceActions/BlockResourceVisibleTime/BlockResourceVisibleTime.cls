/*
	Author: 		Shai Ziv
	
	Type: 			Service Resource custom action
	Description: 	This action will add a Service Absence (Non Availability) that spans across
					the visible day(s) on the gantt to the selected resource
*/

global class BlockResourceVisibleTime implements CustomGanttServiceResourceAction {

	global String action(Id resourceId, Id stmId, Datetime ganttStartDate, Datetime ganttEndDate, Map<String, Object> additionalParameters) {

		ResourceAbsence na = new ResourceAbsence();

		RecordType recordTypeNA = [
			SELECT 
				Id, SobjectType, Name 
			FROM 
				RecordType 
			WHERE 
				DeveloperName =: 'Non_Availability' 
				AND 
				SObjectType =: ResourceAbsence.getSobjectType().getDescribe().getName() 
			];

		na.RecordTypeId = recordTypeNA.Id;
		na.ResourceId = resourceId;
		na.Approved__c = true;
		na.Start = ganttStartDate;
		na.End = ganttEndDate;

		insert na;

		ServiceResource resource = [SELECT Name FROM ServiceResource WHERE Id =: resourceId];

		return 'Blocked availability to ' + resource.Name + ' from ' + ganttStartDate.format() + ' to ' + ganttEndDate.format();

	}

}