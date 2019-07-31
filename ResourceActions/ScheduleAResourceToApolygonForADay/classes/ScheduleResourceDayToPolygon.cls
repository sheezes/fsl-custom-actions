/*
    Author:         Yonatan Bar-Yehuda

    Type:           Resource custom action
    Description:    This action will create STM based on the selected polygon for a specific date and will run RSO for that date
*/

global class ScheduleResourceDayToPolygon {
    // success
    Public string selectedPolygon{get;set;}
    public Date dat {get;set;}
    private Map<Id, FSL__Polygon__c> polygons = new Map<Id, FSL__Polygon__c>();

    Public List<Selectoption> getselectedPloygons(){
        List<Selectoption> lstnamesel = new List<selectoption>();
        lstnamesel.add(new selectOption('', '- None -'));
        List<FSL__Polygon__c> polygonsLst = [SELECT Id, Name, FSL__Description__c, FSL__Service_Territory__c FROM FSL__Polygon__c ORDER BY Name ASC];
        for(FSL__Polygon__c polygon : polygonsLst){
            lstnamesel.add(new selectoption(polygon.Id, polygon.Name));
            polygons.put(polygon.Id, polygon);
        }
        return lstnamesel;
    }

    public void go(){
        ServiceTerritoryMember resSTM = new ServiceTerritoryMember();
        resSTM.ServiceResourceId = ApexPages.currentPage().getParameters().get('id');
        resSTM.ServiceTerritoryId = polygons.get(selectedPolygon).FSL__Service_Territory__c;
        resSTM.EffectiveStartDate = dat;
        resSTM.EffectiveEndDate = dat.addDays(1);
        resSTM.Latitude = 34.10141393466459;
        resSTM.Longitude = -118.30524170474597;
        insert resSTM;

        Id currentUser = UserInfo.getUserId();
        CallRSO(ApexPages.currentPage().getParameters().get('id'), currentUser, dat);
    }

    @future(callout=true)
    private static void CallRSO(Id resId, Id currentUser, Date dat) {
        //call RSO
        FSL.TimeInterval ti = new FSL.TimeInterval(DateTime.newInstance(Dat, Time.newInstance(0, 0, 0, 0)), DateTime.newInstance(Dat.addDays(1), Time.newInstance(0, 0, 0, 0)));
        FSL.OAAS o = new FSL.OAAS();
        o.ResourceDayOptimization(resId,
                                  [Select Id, FSL__User__c, FSL__Gantt_Policy__c FROM FSL__UserSetting__c WHERE FSL__User__c =: currentUser LIMIT 1].FSL__Gantt_Policy__c,
                                  ti,
                                  true,
                                  false,
                                  0,
                                  'ForDemo__c',
                                  'InJeopardy__c',
                                  120);
    }
}
