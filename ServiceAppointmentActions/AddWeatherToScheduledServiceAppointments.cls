/*
    Type:           Service Appointment custom action
    Description:    This action will query the darksky.net weather api and update the service appointment gnatt label and gnatt icon with a summerized weather report.
    FSL Version:    7.0.0+
*/

global class addWeatherToScheduledServiceAppointments implements CustomGanttServiceAppointmentAction {
 
    //TODO: Setup API key
    private final static String API_KEY='';

    private final static String API_URL_FORMAT = 'https://api.darksky.net/forecast/{0}/{1},{2},{3}?exclude=minutely,hourly,daily,alerts,flags';
    private final static String WEATHER_SUMMARY_IDENTIFIER = '☼';
    private final static String WEATHER_SUMMARY_FORMAT = '{0} Weather: {1}, Feels like: {2}°F, Windspeed: {2} MPH {0}';

    // Icons were taken from https://www.flaticon.com/packs/weather-78, Designed by Good Ware (https://www.flaticon.com/authors/good-ware)
    private final static Map<String, String> ICON_MAP = new Map<String, String> {
        'clear-day' => 'https://image.flaticon.com/icons/svg/606/606795.svg',
        'clear-night' => 'https://image.flaticon.com/icons/svg/606/606807.svg',
        'rain' => 'https://image.flaticon.com/icons/svg/606/606801.svg',
        'wind' => 'https://image.flaticon.com/icons/svg/606/606802.svg',
        'cloudy' => 'https://image.flaticon.com/icons/svg/606/606796.svg',
        'partly-cloudy-day' => 'https://image.flaticon.com/icons/svg/606/606800.svg',
        'partly-cloudy-night' => 'https://image.flaticon.com/icons/svg/606/606800.svg',
        'thunderstorm' => 'https://image.flaticon.com/icons/svg/606/606799.svg',
        'default' => 'https://image.flaticon.com/icons/svg/606/606810.svg'
    };

    private Http m_WeatherClient;


    global addWeatherToScheduledServiceAppointments() {
        m_WeatherClient = new Http();
    }

    global String action(List<Id> serviceAppointmentsIds, Datetime ganttStartDate, Datetime ganttEndDate, Map<String, Object> additionalParameters) {
        String responseResult;

        if (String.isBlank(API_KEY)) {
            responseResult = 'No API key is configured, Cannot continue.';
        } else {
            List<String> serviceNames = new List<String>();
            List<ServiceAppointment> servicesToCalculateWeather = [SELECT Id, AppointmentNumber, Longitude, Latitude, SchedStartTime, FSL__GanttIcon__c FROM ServiceAppointment WHERE Id IN :serviceAppointmentsIds AND SchedStartTime != null AND SchedEndTime != null AND Latitude != null AND Longitude != null];
            if (servicesToCalculateWeather != null && !servicesToCalculateWeather.isEmpty()) {
                for (ServiceAppointment sa : servicesToCalculateWeather) {
                    calculateWeatherForSA(sa);
                    serviceNames.add(sa.AppointmentNumber);
                }
                upsert servicesToCalculateWeather;
                responseResult = 'Updated weather info for service appointments: ' + String.join(serviceNames, ', ');
            } else {
                responseResult = 'No valid service appointments were selected, make sure selected service appointments are scheduled and have Lat\\Long';
            }
        }

        return responseResult;
    }

    private void calculateWeatherForSA(ServiceAppointment i_Service) {
        List<String> formatParameters = new List<String>();
        formatParameters.add(API_KEY);
        formatParameters.add(String.valueOf(i_Service.Latitude));
        formatParameters.add(String.valueOf(i_Service.Longitude));
        Long serviceStartEpochInSeconds = i_Service.SchedStartTime.getTime() / 1000;
        formatParameters.add(String.valueOf(serviceStartEpochInSeconds));

        String compiledURL = String.format(API_URL_FORMAT, formatParameters);
        System.debug(LoggingLevel.FINE, 'Requesting weather information from: ' + compiledURL);
        HttpRequest weatherRequest = new HttpRequest();
        weatherRequest.setEndpoint(compiledURL);
        weatherRequest.setMethod('GET');
        HttpResponse weatherResponse = m_WeatherClient.send(weatherRequest);
        String weatherJSON = weatherResponse.getBody();
        processWeatherResultsForSA(i_Service, weatherJSON);
    }

    private void processWeatherResultsForSA(ServiceAppointment i_Service, String i_JSONResults) {
        System.debug(LoggingLevel.FINE, 'Processing weather results for service appointment ' + i_Service.AppointmentNumber);
        Map<String, Object> parsedResults = (Map<String, Object>) JSON.deserializeUntyped(i_JSONResults);

        // To see a full list of the results content and their purpose, check the dark sky developer docs: https://darksky.net/dev/docs
        Map<String, Object> currentWeatherAtServiceStart = (Map<String, Object>) parsedResults.get('currently');
        System.debug(LoggingLevel.FINE, 'Current weather information: ' + currentWeatherAtServiceStart);

        // Creating a summerized weather report which will contain summary, temperature and windspeed.
        // summary can be changed based on Service Appointment parameters like WorkType.
        List<String> weatherSummaryParameters = new List<String>();
        weatherSummaryParameters.add(WEATHER_SUMMARY_IDENTIFIER);
        weatherSummaryParameters.add(String.valueOf(currentWeatherAtServiceStart.get('summary')));
        weatherSummaryParameters.add(String.valueOf(currentWeatherAtServiceStart.get('apparentTemperature')));
        weatherSummaryParameters.add(String.valueOf(currentWeatherAtServiceStart.get('windSpeed')));
        String weatherSummary = String.format(WEATHER_SUMMARY_FORMAT, weatherSummaryParameters);

        // Updating the Service Appointment GanttLabel field with the formatted current weather summary.
        i_Service.FSL__GanttLabel__c = weatherSummary;
        // Updating the Service Appointment GanttIcon.
        i_Service.FSL__GanttIcon__c = updateGanttIconWithWeatherIconMap(i_Service.FSL__GanttIcon__c, String.valueOf(currentWeatherAtServiceStart.get('icon')));
    }

    private String updateGanttIconWithWeatherIconMap(String i_ServiceIcons, String i_WeatherIconName) {
        String iconURL = ICON_MAP.get(i_WeatherIconName);
        if (String.isEmpty(iconURL)) {
            iconURL = ICON_MAP.get('default');
        }

        // Search for known icon url and replace it.
        if (String.isNotBlank(i_ServiceIcons)) {
            List<String> iconsURLS = i_ServiceIcons.split(';');
            Boolean foundAMatchingURL = false;
            for (Integer i=0; i<iconsURLS.size(); i++) {
                if (ICON_MAP.values().contains(iconsURLS.get(i))) {
                    iconsURLS[i] = iconURL;
                    foundAMatchingURL = true;
                    break;
                }
            }

            if (foundAMatchingURL) {
                iconURL = String.join(iconsURLS, ';');
            } else {
                iconURL += ';' + i_ServiceIcons;
            }
        }

        return iconURL;
    }  
}