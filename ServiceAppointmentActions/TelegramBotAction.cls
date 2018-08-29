global class TelegramBotAction implements CustomGanttServiceAppointmentAction {
 
    global String action(List<Id> serviceAppoitmentsIds, Datetime ganttStartDate, Datetime ganttEndDate, Map<String, Object> additionalParameters) {

        List<ServiceAppointment> saList = [SELECT Id, (Select ServiceResourceId From ServiceResources) FROM ServiceAppointment WHERE Id in : serviceAppoitmentsIds];
		List<Id> resourceIdList = new List<Id>();
       	List<Id> userIdList = new List<Id>();
            
        for (ServiceAppointment s : saList) {
            System.debug('sa ::: ' + s.ServiceResources.get(0).ServiceResourceId);
            resourceIdList.add(s.ServiceResources.get(0).ServiceResourceId);
        }
        
        List<ServiceResource> resourceList = [SELECT Id, RelatedRecordId FROM ServiceResource WHERE Id in : resourceIdList];
        
        for (ServiceResource resource : resourceList) {
            System.debug('resource ::: ' + resource.RelatedRecordId);
            userIdList.add(resource.RelatedRecordId);
        }
        
        List<User> userList = [SELECT Id, TelegramId__c FROM User WHERE Id in : userIdList];
        
        for (User usr : userList) {
            Telegram.sendMessage('Hello FSL', usr, '676657173:AAE9dY3gutKyv7PBLB5_NP06uoUspTArlW8');
        }
        
        return '';
    } 
    
    public static String sendMessage (String message, String telegram_user_id, String botId) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.telegram.org/bot' + botId + '/sendMessage');
        req.setMethod('POST');
        req.setHeader('content-type', 'application/json');
        req.setBody('{"chat_id" : "' + telegram_id + '", "text" : "' + message + '"}');
        Http http = new Http();
        HttpResponse res = http.send(req);
        return res.getBody();
    }
}