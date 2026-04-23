public without sharing class ServiceReportPdfController {

    public Id recordId { get; set; }
    public Boolean isPreview  { get; set; }
    public Service_Report__c record { get; set; }
    public Date today { get; set; }
    public String serviceCheckIn { get; set; }
    public string serviceCheckOut { get; set; }
    public String serviceCheckInDate { get; set; }
    public string serviceCheckOutDate { get; set; }
    public String repairStartTimeIST { get; set; }
    public String repairEndTimeIST { get; set; }
    public Service_Appointment__c serviceAppointments { get; set; }
    public List<Spare_Request__c> spareRequests { get; set; }
    public Decimal spareRequestTotal { get; set; }
    public Decimal serviceRequestTotal { get; set; }
    public String totalInWords { get; set; }
    public DateTime now { get { return System.now(); } set; }
    public Service_Resource__c serviceResource { get; set; }
    public Asset_Warranty__c assetWarranty { get; set; }
    public Asset_AMC__c assetAMC { get; set; }
    public List<Service_Report_Observation__c> sroList{ get; set; }
    public Map<String, List<Work_Order_Checklist__c>> categorizedChecklists { get; set; }
    public Map<String, List<Object>> balancedChecklists { get; set; }
    public List<List<Work_Order_Checklist__c>> col1 { get; set; }
    public List<List<Work_Order_Checklist__c>> col2 { get; set; }
    public List<Service_Appointment__c> additionalResourceServiceAppointments {get; set;}
    // Preformatted HTML version of Customers_Comments__c for PDF wrapping
    public String customersCommentsHtml { get; set; }

    public Boolean isExcellentFeedback {get; set;}
    public List<Service_Report_Printer_Parameter__c> serviceReportParameters {get; set;}



    public ServiceReportPdfController() {
        recordId = ApexPages.currentPage().getParameters().get('id');
        System.debug('recordId'+ recordId);
        String isPreviewParam = ApexPages.currentPage().getParameters().get('isPreview');
        System.debug('isPreview'+ isPreview);

        if (isPreviewParam != null) {
            isPreview = Boolean.valueOf(isPreviewParam);
        } else {
            isPreview = false;
        }

        today = System.today();
        DateTime dt = DateTime.now();
        serviceCheckIn = dt.format('dd MMM yyyy hh:mm a');
        serviceCheckInDate = dt.format('dd MMM yyyy');
        serviceCheckOut = dt.format('dd MMM yyyy hh:mm a');
        serviceCheckOutDate = dt.format('dd MMM yyyy');
        
        // Initialize serviceReportParameters to avoid null reference
        // serviceReportParameters = new List<Service_Report_Printer_Parameter__c>();

        if (recordId != null) {
            try {
                record = [SELECT Id, Name,Root_Cause_Analysis__c,Action_Taken__c,Customer_Remark__c,SR_Remark__c,Customer_Problem_Statement__c,
                        Case__c, isAverageFeedback__c, isGoodFeedback__c, isVeryGoodFeedback__c, isExcellentFeedback__c, isExpired__c, isUnderAMC__c, isUnderWarranty__c,
                        Case__r.CreatedDate,Case__r.Account.Name,Case__r.ContactEmail,SR_End_Date__c,
                        Case__r.Case_Sub_Type__c,Case__r.Account.SAP_Customer_code__c,Case__r.Asset.Invoice_Number__c,Case__r.Asset.Id,Case__r.Asset.SerialNumber,
                        Case__r.Asset.OEM_Serial_Number__c, Case__r.Asset.Ship_to_Address__c,Case__r.Asset.Ship_to_City__c,Case__r.Asset.Ship_to_Pin__c,Case__r.Asset.Ship_to_Country__c,
                        Case__r.Contact.Name,Case__r.ContactMobile,Case__r.Description,Case__r.OwnerId,
                        Product__r.ProductCode, Product__r.Name, Product__r.OEM_Material_Code__c, Signature_by__c,case__r.Owner.Name,Customer_Feedback__c,Hour_Meter__c,
                        case__r.Owner.Phone, case__r.Owner.Email, Case__r.Asset.Product2Id, Case__r.Asset.Product2.Id, Case__r.Asset.Product2.Material_Group_5__c,
                        Work_Order__c,Work_Order__r.Owner.Name,Work_Order__r.Spare_Request_Total__c,Work_Order__r.Service_Request_Total__c,Signature__c, Service_Appointment__c, Service_Appointment__r.Case__c, Service_Appointment__r.Scheduled_Start__c,
                        Customer_Email__c,Customer_Contact_Number__c,Customer_Designation__c,Next_Visit_Proposed_Date__c,
                        Customers_Comments__c, Service_Rating__c,
                        // CIJ (P01) specific fields
                        Ink_Part_No__c, Ink_Customer_Stock__c, Ink_Exp_Date__c, MakeUp_Part_No__c, MakeUp_Customer_Stock__c, Make_Up_Exp_Date__c,
                        Visc_Set_Point__c, Visc_Actual__c, Ink_Temp__c, Cabinet_Temp__c, Head_Temp__c, Ink_Pressure__c,
                        Heater_Point__c, Modulation__c, Charge_Value__c, EHT_Range_Min__c, EHT_Range_Max__c, EHT_Grade__c, Gutter_Mode__c,
                        Print_Quality__c,  Print_Head_Set__c , Ink_Type__c, VMC_Calibration__c, Software_No__c, Customer_Application__c, Customer_Application_TTO__c, Pump_Run_Hours__c,Complaint_Details__c,
                        Nozzle_Serial_No__c, Checkout_Time__c, Checkin_Time__c,
                        // TIJ (P03) specific fields
                        TIJ_Model_No__c, Ink_Cartridge_Part__c, Cartridge_Exp_Date__c, Product_Counter__c,
                        Complaint_Status__c, Repair_End_Time__c, Repair_Start_Time__c,
                        // Machine status fields
                        MC_Breakdown__c, MC_Temporary_Down__c, MC_Running__c, Spare_Replaced__c,
                        // TTO (P02) specific fields
                        TTO_Model_No__c, Print_head_Kms__c, Ribbon_Part__c, Ribbon_Customer_Stock__c, Expiration_Date__c,
                        Input_Air_Pressure__c, Print_Head_Resistance__c, Ribbon_Dia_D1__c, Ribbon_Dia_D2__c, Print_Speed__c,
                        Ribbon_Fail_Count__c, Registration_Dot__c, Debounce_Time__c, Print_Delay__c, PR_GO_Ignore__c,
                        PR_GO_Edge__c, Heating_Mode__c, Ribbon_Gap__c, Output_Air_Pressure__c, Head_Out_Time__c,
                        Head_In_Time__c, Start_Border_Trim__c, End_Border_Trim__c, Darkness__c, Head_Serial_Number__c,
                        // Travel & Expense fields for Labour Charges
                        TravelDate__c, Travel_From_1__c, Travel_To_1__c, Lodging_Per_Day_1__c, Boarding_Per_Day_1__c, 
                        Conven__c, Remark1__c, Travel_Date_2__c, Travel_From_2__c, Travel_To_2__c, 
                        Lodging_Per_Day_2__c, Boarding_Per_Day_2__c, Conveyance_2__c, Remark2__c, Date_To__c, Date_To_2__c
                        FROM Service_Report__c
                        WHERE Id = :recordId LIMIT 1];
                System.debug(record.Id);
                System.debug('Service_Appointment__r.Case__c'+ record.Service_Appointment__r.Case__c);

                isExcellentFeedback = record.Customer_Feedback__c == 'Excellent';

                // Prepare wrapped HTML for Customer's Comments so it renders as multi-line
                customersCommentsHtml = formatMultiline(record.Customers_Comments__c);

                sroList = [SELECT Id, Name, Cause__c, Sub_Cause__c, Actual_Observation_by_Engineer__c, Correction__c
                        FROM Service_Report_Observation__c
                        WHERE Service_Report__c = :record.Id];

                spareRequestTotal = record.Work_Order__r.Spare_Request_Total__c != null ? record.Work_Order__r.Spare_Request_Total__c : 0;
                serviceRequestTotal = record.Work_Order__r.Service_Request_Total__c != null ? record.Work_Order__r.Service_Request_Total__c : 0;

                Decimal totalAmount = spareRequestTotal + serviceRequestTotal;

                totalInWords = numberToWords(totalAmount);


                additionalResourceServiceAppointments = [
                    SELECT Id, Owner.Name, Owner.Email, Owner.Phone
                    FROM Service_Appointment__c
                    WHERE Case__c = :record.Service_Appointment__r.Case__c AND
                    Scheduled_Start__c = :record.Service_Appointment__r.Scheduled_Start__c AND
                    Check_In_Date_Time__c != NULL AND
                    Is_Additional_Resource__c = TRUE AND
                    Remote_Support__c = FALSE
                ];

                System.debug('additionalResourceServiceAppointments: ' + additionalResourceServiceAppointments);
                System.debug('additionalResourceServiceAppointments size: ' + additionalResourceServiceAppointments.size());


                Service_Appointment__c serviceAppointments = new Service_Appointment__c();
                try {
                    serviceAppointments = [
                        SELECT Id, Check_In_Date_Time__c, Check_Out_Date_Time__c, CreatedDate
                        FROM Service_Appointment__c
                        WHERE Id = :record.Service_Appointment__c
                    ];
                }
                catch (Exception e) {
                    System.debug('Error: ' + e.getMessage());
                }

                System.debug(serviceAppointments.Check_In_Date_Time__c);
                if (serviceAppointments.Check_In_Date_Time__c != null) {
                    serviceCheckIn = serviceAppointments.Check_In_Date_Time__c.format('dd MMM yyyy hh:mm a');
                    serviceCheckInDate = serviceAppointments.Check_In_Date_Time__c.format('dd MMM yyyy');
                }

                if (serviceAppointments.Check_Out_Date_Time__c != null) {
                    serviceCheckOut = serviceAppointments.Check_Out_Date_Time__c.format('dd MMM yyyy hh:mm a');
                    serviceCheckOutDate = serviceAppointments.Check_Out_Date_Time__c.format('dd MMM yyyy');
                }

                // Convert Repair_Start_Time__c and Repair_End_Time__c from GMT to IST (UTC+5:30)
                if (record.Repair_Start_Time__c != null) {
                    repairStartTimeIST  = record.Repair_Start_Time__c.format('dd MMM yyyy hh:mm a');
                    //repairStartTimeIST = repairStartTimeISTDateTime.format('dd MMM yyyy hh:mm a');
                }

                if (record.Repair_End_Time__c != null) {
                    repairEndTimeIST  = record.Repair_End_Time__c.format('dd MMM yyyy hh:mm a');
                    //repairEndTimeIST = repairEndTimeISTDateTime.format('dd MMM yyyy hh:mm a');
                }

                if (record.Signature__c != null) {
                    record.Signature__c = record.Signature__c.replace('<img ', '<img style="width:150px; height:50px;" ');
                }

                System.debug('Service Appointments: ' + serviceAppointments);

                List<Work_Order_Checklist__c> workOrderChecklists = FieldServiceCaptureInteraction.getChecklistData(record.Work_Order__c);
                System.debug('Work Order Checklists: ' + workOrderChecklists.size());

                categorizedChecklists = new Map<String, List<Work_Order_Checklist__c>>();
                // for (Work_Order_Checklist__c checklist : workOrderChecklists) {
                //     String category = checklist.Checklist_Category__c;
                //     if (!categorizedChecklists.containsKey(category)) {
                //         categorizedChecklists.put(category, new List<Work_Order_Checklist__c>());
                //     }
                //     categorizedChecklists.get(category).add(checklist);
                // }
                for (Work_Order_Checklist__c checklist : workOrderChecklists) {
                    if (!String.isBlank(checklist.Observation__c)) {
                        String category = checklist.Checklist_Category__c;

                        if (!categorizedChecklists.containsKey(category)) {
                            categorizedChecklists.put(category, new List<Work_Order_Checklist__c>());
                        }
                        categorizedChecklists.get(category).add(checklist);
                    }
                }

                balancedChecklists = balanceColumns(categorizedChecklists);

                spareRequests = [SELECT Id, Name, Case__c, Work_Order__c, Spare_Status__c, Item_Description__c, Quantity_Required__c, 
                Item_Master__r.ProductCode, Item_Master__r.HSN_Code__r.Name, Item_Master__r.Base_UOM__r.Name, Billed_Value__c
                                FROM Spare_Request__c
                                WHERE Work_Order__c = :record.Work_Order__c];
                Map<String, List<List<Work_Order_Checklist__c>>> balancedData = balanceColumns(categorizedChecklists);
                col1 = balancedData.get('col1');
                col2 = balancedData.get('col2');

                System.debug('Spare Requests: ' + spareRequests);
                Integer rowNumber = 1;
                if (!spareRequests.isEmpty()) {
                    for (Spare_Request__c spareRequest : spareRequests) {
                        //spareRequest.put('RowNumber', rowNumber); // Adds a custom RowNumber field
                        rowNumber++;
                        System.debug('Spare Request: ' + spareRequest.Name + ', Quantity: ' + spareRequest.Quantity_Required__c);
                    }
                } else {
                    System.debug('No Spare Requests found for this Work Order.');
                }
                if (record.Case__r != null && record.Case__r.OwnerId != null) {
                    List<Service_Resource__c> serviceResources = [SELECT Id, User__c, Signature__c
                                                                FROM Service_Resource__c
                                                                WHERE User__c = :record.Case__r.OwnerId
                                                                LIMIT 1];

                    if (!serviceResources.isEmpty()) {
                        serviceResource = serviceResources[0];
                        System.debug('Service Resource Signature: ' + serviceResource.Signature__c);

                        // Modify the Service_Resource__c.Signature__c field if it's not null
                        if (serviceResource.Signature__c != null) {
                            serviceResource.Signature__c = serviceResource.Signature__c.replace('<img ', '<img style="width:150px; height:50px;" ');
                        }
                    }
                }

                // Fetch Service Report Parameters for TIJ (P03)
                serviceReportParameters = [
                    SELECT Id, Name, Selection_Options_List__c, Selected_Type__c, 
                           Selection_Value__c, Display_Order__c
                    FROM Service_Report_Printer_Parameter__c 
                    WHERE Service_Report__c = :record.Id
                    ORDER BY Display_Order__c NULLS LAST, CreatedDate
                ];
                System.debug('Service Report Parameters: ' + serviceReportParameters);

            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Record not found.'));
            }
        }
    }

        private Map<String, List<List<Work_Order_Checklist__c>>> balanceColumns(Map<String, List<Work_Order_Checklist__c>> data) {
        // private Map<String, List<Object>> balanceColumns(Map<String, List<Work_Order_Checklist__c>> data) {
            List<Map<String, Object>> types = new List<Map<String, Object>>();
            for (String type : data.keySet()) {
                types.add(new Map<String, Object>{
                    'type' => type,
                    'list' => data.get(type),
                    'count' => data.get(type).size()
                });
            }

            types.sort(new ComparatorMapByCount());

            // List<List<Object>> col1 = new List<List<Object>>();
            // List<List<Object>> col2 = new List<List<Object>>();
            List<List<Work_Order_Checklist__c>> col1 = new List<List<Work_Order_Checklist__c>>();
            List<List<Work_Order_Checklist__c>> col2 = new List<List<Work_Order_Checklist__c>>();
            Integer col1Count = 0;
            Integer col2Count = 0;

            for (Map<String, Object> item : types) {
                List<Work_Order_Checklist__c> checklistItems = (List<Work_Order_Checklist__c>) item.get('list');
                Integer itemCount = (Integer) item.get('count');

                // if (col1Count <= col2Count) {
                    //     col1.add((List<Object>)item.get('list'));
                    //     col1Count += (Integer)item.get('count');
                // } else {
                    //     col2.add((List<Object>)item.get('list'));
                    //     col2Count += (Integer)item.get('count');
                // }
                if (col1Count <= col2Count) {
                    col1.add(checklistItems);
                    col1Count += itemCount;
                } else {
                    col2.add(checklistItems);
                    col2Count += itemCount;
                }
            }

            return new Map<String, List<List<Work_Order_Checklist__c>>>{
                'col1' => col1,
                'col2' => col2
            };
        }


    public class ComparatorMapByCount implements Comparator<Map<String, Object>> {
            public Integer compare(Map<String, Object> a, Map<String, Object> b) {
                Integer countA = (Integer)a.get('count');
                Integer countB = (Integer)b.get('count');
                if (countA > countB) return -1;
                if (countA < countB) return 1;
                return 0;
            }
        }


    public String numberToWords(Decimal total) {
        Long wholeNumber = total.longValue();
        String wordString = '';
        return 'Total Amount in Words: ' + wholeNumber;
    }

    // Helper to break long textarea content into multiple lines for PDF.
    // Inserts <br/> every 80 characters so very long words don't overflow.
    private String formatMultiline(String input) {
        if (String.isBlank(input)) {
            return '';
        }

        String normalized = input;
        // Normalize line breaks to <br/>
        normalized = normalized.replace('\r\n', '\n');
        normalized = normalized.replace('\r', '\n');

        String[] lines = normalized.split('\n');
        List<String> resultLines = new List<String>();

        for (String line : lines) {
            if (line == null) {
                continue;
            }
            Integer len = line.length();
            if (len <= 80) {
                resultLines.add(line);
            } else {
                for (Integer i = 0; i < len; i += 80) {
                    Integer endIdx = Math.min(i + 80, len);
                    resultLines.add(line.substring(i, endIdx));
                }
            }
        }

        return String.join(resultLines, '<br/>');
    }

    /**
     * Calculate Total for Row 1: (Lodging Per Day + Boarding Per Day + Conveyance Per Day) * (Integer(Date To - Date From) + 1)
     */
    public Decimal getTotalRow1() {
        Decimal lodging = record.Lodging_Per_Day_1__c != null ? record.Lodging_Per_Day_1__c : 0;
        Decimal boarding = record.Boarding_Per_Day_1__c != null ? record.Boarding_Per_Day_1__c : 0;
        Decimal conveyance = record.Conven__c != null ? record.Conven__c : 0;
        Decimal dailyTotal = lodging + boarding + conveyance;
        
        Integer numberOfDays = 0;
        if (record.TravelDate__c != null && record.Date_To__c != null) {
            // Calculate difference in days (integer)
            // Convert Date to DateTime at midnight for accurate calculation
            DateTime dateFrom = DateTime.newInstance(record.TravelDate__c, Time.newInstance(0, 0, 0, 0));
            DateTime dateTo = DateTime.newInstance(record.Date_To__c, Time.newInstance(0, 0, 0, 0));
            Long diffTime = dateTo.getTime() - dateFrom.getTime();
            Long diffDays = diffTime / (1000 * 60 * 60 * 24);
            // Add 1 to include both start and end dates (e.g., Dec 25 to Dec 25 = 1 day)
            numberOfDays = diffDays.intValue() + 1;
        }
        
        return dailyTotal * numberOfDays;
    }

    /**
     * Calculate Total for Row 2: (Lodging Per Day + Boarding Per Day + Conveyance Per Day) * (Integer(Date To - Date From) + 1)
     */
    public Decimal getTotalRow2() {
        Decimal lodging = record.Lodging_Per_Day_2__c != null ? record.Lodging_Per_Day_2__c : 0;
        Decimal boarding = record.Boarding_Per_Day_2__c != null ? record.Boarding_Per_Day_2__c : 0;
        Decimal conveyance = record.Conveyance_2__c != null ? record.Conveyance_2__c : 0;
        Decimal dailyTotal = lodging + boarding + conveyance;
        
        Integer numberOfDays = 0;
        if (record.Travel_Date_2__c != null && record.Date_To_2__c != null) {
            // Calculate difference in days (integer)
            // Convert Date to DateTime at midnight for accurate calculation
            DateTime dateFrom = DateTime.newInstance(record.Travel_Date_2__c, Time.newInstance(0, 0, 0, 0));
            DateTime dateTo = DateTime.newInstance(record.Date_To_2__c, Time.newInstance(0, 0, 0, 0));
            Long diffTime = dateTo.getTime() - dateFrom.getTime();
            Long diffDays = diffTime / (1000 * 60 * 60 * 24);
            // Add 1 to include both start and end dates (e.g., Dec 25 to Dec 25 = 1 day)
            numberOfDays = diffDays.intValue() + 1;
        }
        
        return dailyTotal * numberOfDays;
    }

}