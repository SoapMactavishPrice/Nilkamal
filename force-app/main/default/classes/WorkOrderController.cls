public with sharing class WorkOrderController {
    //
        @AuraEnabled(cacheable=true)
    public static Map<String, List<Map<String, String>>> getPicklistValues() {
        Map<String, List<Map<String, String>>> picklistTerritoryMap = new Map<String, List<Map<String, String>>>();

        try {
            // Fetch picklist values for Lead Source
            List<Map<String, String>> territoryPicklistValues = new List<Map<String, String>>();
            Schema.DescribeFieldResult territoryField = Service_Appointment__c.Territory__c.getDescribe();
            List<Schema.PicklistEntry> territoryValues = territoryField.getPicklistValues();
            for (Schema.PicklistEntry pickListVal : territoryValues) {
                Map<String, String> mp = new Map<String, String>();
                mp.put('label', pickListVal.getLabel());
                mp.put('value', pickListVal.getValue());
                territoryPicklistValues.add(mp);
            }

            picklistTerritoryMap.put('territory', territoryPicklistValues);

            return picklistTerritoryMap;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching picklist values: ' + e.getMessage());
        }
    }
    //

    @AuraEnabled
    public static Work_Order__c getWorkOrderDetails(Id workOrderId) {
        return [SELECT Id, Name, Work_Order_Type__c, Case__c, case__r.AccountId, case__r.Case_Pincode__r.Name, Case__r.Case_Territory__r.Name
                FROM Work_Order__c
                WHERE Id =: workOrderId];
    }

    @AuraEnabled
    public static List<Service_Appointment__c> getServiceAppointments(Id workOrderId) {
        return [SELECT Id, Name, Work_Order__c, WO_Type__c, Assigned_Date__c, Due_Date__c
                FROM Service_Appointment__c
                WHERE Work_Order__c =: workOrderId];
    }

    @AuraEnabled
    public static Service_Appointment__c getServiceAppointmentDetails(Id serviceAppointmentId) {
        try {
            return [
                SELECT Id, Assigned_Date__c,WO_Type__c,Due_Date__c,Work_Order__c,Territory__c,Address__c
                FROM Service_Appointment__c
                WHERE Id = :serviceAppointmentId];
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching Service Appointment details: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static Service_Appointment__c saveServiceAppointment(string serviceAppointmentId, string caseId, string workOrderId,  string workType, String address, Date earliestStartPermitted, Date dueDate)
    {
        Service_Appointment__c appointment = new Service_Appointment__c();

        if (serviceAppointmentId != null && serviceAppointmentId != '') {
            appointment.Id = serviceAppointmentId;
        } else {
            appointment.Case__c = caseId;
            appointment.Work_Order__c = workOrderId;
        }

        // appointment.Address__c = address;
        // appointment.Partner_Function_Address_Information__c = address;
        // appointment.Territory__c = territory;
        appointment.Assigned_Date__c = earliestStartPermitted;
        appointment.Due_Date__c = dueDate;
        appointment.WO_Type__c = workType;

        if (appointment.Id == null) {
            insert appointment;
        } else {
            update appointment;
        }

        return appointment;
    }


    @AuraEnabled
    public static Object getServiceResourceAvailability(String woId) {
        try {
            Map<Date, List<Object>> finalAvailabilityMap = new Map<Date, List<Object>>();
            List<Date> next7Days = new List<Date>();
            Date today = Date.today();
            for(Integer i = 0; i < 7; i++) {
                next7Days.add(today.addDays(i));
                finalAvailabilityMap.put(today.addDays(i), new List<Object>());
            }

            Work_Order__c workOrder = [SELECT Id, Case__r.Case_Pincode__c, Case__r.Division__c FROM Work_Order__c WHERE Id =: woId];

            List<Service_Resource_Pincode__c> serviceResourcePinCodes = [SELECT Id, Service_Resource__c,
                                                                        Service_Resource__r.User__c, Service_Resource__r.User__r.Name, Service_Resource__r.Role__c
                                                                        FROM Service_Resource_Pincode__c
                                                                        WHERE Pin_Code_Master__c =: workOrder.Case__r.Case_Pincode__c AND Division__c = :workOrder.Case__r.Division__c AND Service_Resource__r.isActive__c = TRUE AND Service_Resource__r.User__r.isActive = TRUE];

            List<Service_Resource__c> serviceResources = new List<Service_Resource__c>();
            for(Service_Resource_Pincode__c serviceResourcePincode : serviceResourcePinCodes) {
                serviceResources.add(new Service_Resource__c(Id = serviceResourcePincode.Service_Resource__c,
                                                            User__c = serviceResourcePincode.Service_Resource__r.User__c,
                                                            Role__c = serviceResourcePincode.Service_Resource__r.Role__c,
                                                            User__r = serviceResourcePincode.Service_Resource__r.User__r)
                );
            }


            List<Service_Resource_Working_Hour__c> workingHours = [SELECT Id, Service_Resource__c, Start_Hour__c, End_Hour__c, Weekday__c
                                                                FROM Service_Resource_Working_Hour__c
                                                                WHERE Service_Resource__c IN: serviceResources];

            Date startDate = next7Days[0];
            Date endDate = next7Days[next7Days.size() - 1];
            List<Service_Resource_Leave__c> leaves = [SELECT Id, Service_Resource__c, Start_Date__c, End_Date__c
                                                    FROM Service_Resource_Leave__c
                                                    WHERE Service_Resource__c IN: serviceResources AND
                                                    (
                                                        (Start_Date__c <=: startDate AND End_Date__c >=: endDate)
                                                        OR
                                                        (Start_Date__c <=: endDate AND End_Date__c >=: startDate)
                                                        OR
                                                        (Start_Date__c <=: endDate AND End_Date__c >=: endDate)
                                                        OR
                                                        (Start_Date__c >=: startDate AND Start_Date__c <=: endDate)
                                                    )];
            Map<Id, Map<Date, Boolean>> serviceResourceWiseLeaves = new Map<Id, Map<Date, Boolean>>();
            for(Service_Resource_Leave__c leave : leaves) {
                for(Date dt = leave.Start_Date__c; dt <= leave.End_Date__c; dt = dt.addDays(1)) {
                    if(!serviceResourceWiseLeaves.containsKey(leave.Service_Resource__c)) {
                        serviceResourceWiseLeaves.put(leave.Service_Resource__c, new Map<Date, Boolean>());
                    }
                    serviceResourceWiseLeaves.get(leave.Service_Resource__c).put(dt, true);
                }
            }

            for(Date dt : next7Days) {
                for(Service_Resource__c serviceResource : serviceResources) {
                    if(serviceResourceWiseLeaves.containsKey(serviceResource.Id) && serviceResourceWiseLeaves.get(serviceResource.Id).containsKey(dt)) {
                        continue;
                    } else {
                        Map<String, Object> availableSlot = new Map<String, Object>();
                        for(Service_Resource_Working_Hour__c workingHour : workingHours) {
                            if(workingHour.Service_Resource__c == serviceResource.Id && workingHour.Weekday__c == Datetime.newInstance(dt.year(), dt.month(), dt.day()).format('EEEE')) {
                                availableSlot.put('startHour', workingHour.Start_Hour__c);
                                availableSlot.put('endHour', workingHour.End_Hour__c);
                                availableSlot.put('formattedStartHour', String.valueOf(workingHour.Start_Hour__c.hour()).leftPad(2, '0') + ':' + String.valueOf(workingHour.Start_Hour__c.minute()).leftPad(2, '0'));
                                availableSlot.put('formattedEndHour', String.valueOf(workingHour.End_Hour__c.hour()).leftPad(2, '0') + ':' + String.valueOf(workingHour.End_Hour__c.minute()).leftPad(2, '0'));
                                availableSlot.put('dt', dt);
                                availableSlot.put('formattedDt', Datetime.newInstance(dt.year(), dt.month(), dt.day()).format('yyyy-MM-dd'));

                                Map<String, Object> availabilityMap = new Map<String, Object> {
                                    'userName' => serviceResource.User__r.Name,
                                    'userId' => serviceResource.User__c,
                                    'serviceResourceId' => serviceResource.Id,
                                    'role' => serviceResource.Role__c,
                                    'availableSlot' => availableSlot
                                };
                                finalAvailabilityMap.get(dt).add(availabilityMap);
                                break;
                            }
                        }
                    }
                }
            }

            return finalAvailabilityMap;
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
//
    @AuraEnabled
    public static String saveAvailability(String serviceAppointmentId, String userName, String selectedDate, String selectedSlot) {
        try {
            // Query the User record by Name (assuming userName is unique)
            User user = [SELECT Id FROM User WHERE Name = :userName LIMIT 1];

            // Query the ServiceAppointment record by Id
            Service_Appointment__c serviceAppointment = [SELECT Id, Scheduled_Start__c, Scheduled_End__c
                                                    FROM Service_Appointment__c
                                                    WHERE Id = :serviceAppointmentId LIMIT 1];

            // Split the selectedSlot into start and end times
            List<String> slotParts = selectedSlot.split(' - ');
            if (slotParts.size() != 2) {
                throw new CustomException('Invalid time slot format. Expected format is "HH:mm - HH:mm".');
            }
            String startTime = slotParts[0];  // Start time (e.g., "02:00")
            String endTime = slotParts[1];    // End time (e.g., "10:00")

            // Parse the date and time to create DateTime values
            DateTime arrivalWindowStart = Datetime.valueOf(selectedDate + ' ' + startTime +':00');
            DateTime arrivalWindowEnd = Datetime.valueOf(selectedDate + ' ' + endTime +':00');

            // Update the Arrival Window Start and End fields on the Service Appointment
            serviceAppointment.Scheduled_Start__c = arrivalWindowStart;
            serviceAppointment.Scheduled_End__c = arrivalWindowEnd;

            // Optionally, you can update the assigned user as well
            serviceAppointment.OwnerId = user.Id;  // If you're associating a user with the appointment

            // Update the ServiceAppointment record
            update serviceAppointment;

            // Return success message
            return JSON.serialize(serviceAppointment);
        } catch (Exception e) {
            // Handle any errors and return a failure message
            system.debug('getMessage'+e.getMessage());
            throw new AuraHandledException('Error saving availability: ' + e.getMessage());
        }
    }
//


// @AuraEnabled
//     public static String saveAvailability(String serviceAppointmentId, String userName, String selectedDate, String selectedSlot) {
//         try {
//             // Query the User record by Name (assuming userName is unique)
//             // User user = [SELECT Id FROM User WHERE Name = : userName LIMIT 1];

//             // Query the ServiceAppointment record by Id
//             Service_Appointment__c serviceAppointment = [SELECT Id, Arrival_Window_Start__c, Arrival_Window_End__c
//                                                      FROM Service_Appointment__c
//                                                      WHERE Id = : serviceAppointmentId LIMIT 1];

//             // Split the selectedSlot into start and end times
//             List < String > slotParts = selectedSlot.split(' - ');
//             if (slotParts.size() != 2) {
//                 throw new AuraHandledException('Invalid time slot format. Expected format is "hh:mm a - hh:mm a".');
//             }
//             String startTime = slotParts[0];  // Start time (e.g., "12:00 PM")
//             String endTime = slotParts[1];    // End time (e.g., "02:00 PM")

//             // Convert the selectedDate (DD/MM/YYYY) and time strings into a valid DateTime format
//             DateTime arrivalWindowStart = parseCustomDateTime(selectedDate, startTime);
//             DateTime arrivalWindowEnd = parseCustomDateTime(selectedDate, endTime);

//             // Update the Arrival Window Start and End fields on the Service Appointment
//             serviceAppointment.Arrival_Window_Start__c = arrivalWindowStart;
//             serviceAppointment.Arrival_Window_End__c = arrivalWindowEnd;

//             // Optionally, you can update the assigned user as well
//             serviceAppointment.Assigned_User__c = user.Id;  // If you're associating a user with the appointment

//             // Update the ServiceAppointment record
//             update serviceAppointment;

//             // Return success message
//             return 'Availability saved successfully for Service Appointment: ' + serviceAppointmentId;
//         } catch (Exception e) {
//             // Handle any errors and return a failure message
//             throw new AuraHandledException('Error saving availability: ' + e.getMessage());
//         }
//     }

//     // Helper method to parse the custom date/time format (DD/MM/YYYY, hh:mm a)
//     private static DateTime parseCustomDateTime(String selectedDate, String time) {
//         // Ensure the selectedDate is in DD/MM/YYYY format
//         List < String > dateParts = selectedDate.split('/');
//         if (dateParts.size() != 3) {
//             throw new AuraHandledException('Invalid date format. Expected format is "DD/MM/YYYY".');
//         }

//         String day = dateParts[0];
//         String month = dateParts[1];
//         String year = dateParts[2];

//         // Parse the time into 24-hour format if it is in AM/PM format
//         Time t = Time.newInstance(Integer.valueOf(time.substring(0, 2)),
//             Integer.valueOf(time.substring(3, 5)),
//             0,
//             0);

//         // Check if the time is in PM and adjust the hour accordingly
//         Boolean isPM = time.contains('PM');
//         if (isPM && t.hour() < 12) {
//             t = t.addHours(12); // Add 12 hours to PM times (e.g., "12:00 PM" becomes 12:00:00, "01:00 PM" becomes 13:00:00)
//         } else if (!isPM && t.hour() == 12) {
//             t = t.addHours(-12); // Handle 12:00 AM (midnight) case
//         }

//         // Build the full date-time string in Salesforce's format: "YYYY-MM-DD HH:mm:ss"
//         String dateTimeStr = year + '-' + month + '-' + day + ' ' + t.hour() + ':' + t.minute() + ':00';

//         // Parse it into a DateTime object
//         return DateTime.parse(dateTimeStr);
//     }


}