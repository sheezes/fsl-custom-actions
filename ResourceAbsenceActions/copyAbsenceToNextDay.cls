/*
    Author:         Ori Fishman
    
    Type:           Resource Absence custom action
    Description:    This action will copy the absence to the next day (only if of type 'na')
*/

global class copyAbsenceToNextDay implements FSL.CustomGanttResourceAbsenceAction {
 
    global String action(Id absenceId, String absenceType, Datetime ganttStartDate, Datetime ganttEndDate, Map<String, Object> additionalParameters) {
       
        if (absenceType != 'na')
            return 'Action available only for resource absences of type non availability';

        ResourceAbsence resourceAbsence = [SELECT Id, AbsenceNumber, Start, End, ResourceId FROM ResourceAbsence WHERE Id =: absenceId LIMIT 1];

        ResourceAbsence raClone = resourceAbsence.clone(false, true, false, false);
        raClone.Start = resourceAbsence.Start.addDays(1);
        raClone.End = resourceAbsence.End.addDays(1);
        raClone.ResourceId = resourceAbsence.ResourceId;

        insert raClone;

        return 'Resource Absence successfully copied.';
    }
   
}