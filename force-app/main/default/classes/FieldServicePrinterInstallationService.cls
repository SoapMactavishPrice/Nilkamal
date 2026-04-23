public without sharing class FieldServicePrinterInstallationService {

    @AuraEnabled
    public static Object getReportDetails(String workOrderId, String serviceAppointmentId, String reportType) {
        try {
            System.debug('DEBUG 1: Starting getReportDetails - workOrderId: ' + workOrderId + ', serviceAppointmentId: ' + serviceAppointmentId + ', reportType: ' + reportType);
            Work_Order__c workOrder = [
                SELECT Id,
                       Case__c,
                       Case__r.ContactId,
                       Case__r.Contact.Email,
                       Case__r.Contact.Name,
                       Case__r.ContactMobile,
                       Case__r.ContactEmail,
                       Case__r.Account.Name,
                       Case__r.Account.SAP_Customer_code__c,
                       Case__r.Owner.Name,
                       Case__r.Owner.Phone,
                       Case__r.AssetId,
                       Case__r.Asset.Name,
                       Case__r.Asset.SerialNumber,
                       Case__r.Asset.Product2Id,
                       Case__r.Asset.Is_Temp_Serial_Number__c,
                       Case__r.Asset.OEM_Serial_Number__c,
                       Case__r.Asset.Industry__c,
                       Case__r.Asset.Software_Number__c,
                       Case__r.Asset.Product2.Name,
                       Case__r.Asset.Product2.Material_Group_5__c,
                       Case__r.Asset.Product2.Material_Group_6__c,
                       Case__r.Division__c,
                       Case__r.Region__c,
                       Case__r.Subject,
                       Case__r.Description,
                       Case__r.Status,
                       Case__r.Case_Sub_Type__c
                FROM Work_Order__c
                WHERE Id = :workOrderId
            ];
            System.debug('DEBUG 2: Work Order queried successfully. Case__r: ' + (workOrder.Case__r != null ? 'NOT NULL' : 'NULL') + ', Asset: ' + (workOrder.Case__r != null && workOrder.Case__r.Asset != null ? 'NOT NULL' : 'NULL'));

            Service_Appointment__c serviceAppointment = [
                SELECT Id, Remote_Support__c, Case__c, Case__r.Description,
                Status__c, Check_In_Date_Time__c, Check_Out_Date_Time__c
                FROM Service_Appointment__c
                WHERE Id = :serviceAppointmentId
            ];
            System.debug('DEBUG 3: Service Appointment queried successfully. Case__r: ' + (serviceAppointment.Case__r != null ? 'NOT NULL' : 'NULL'));

            Boolean hourMeterRequired = false;
            System.debug('DEBUG 4: Checking hourMeterRequired. Case__r: ' + (workOrder.Case__r != null) + ', Asset: ' + (workOrder.Case__r != null && workOrder.Case__r.Asset != null) + ', Product2Id: ' + (workOrder.Case__r != null && workOrder.Case__r.Asset != null && workOrder.Case__r.Asset.Product2Id != null) + ', Product2: ' + (workOrder.Case__r != null && workOrder.Case__r.Asset != null && workOrder.Case__r.Asset.Product2 != null));
            if (workOrder.Case__r != null && workOrder.Case__r.Asset != null && workOrder.Case__r.Asset.Product2Id != null && workOrder.Case__r.Asset.Product2 != null) {
                System.debug('DEBUG 5: Inside hourMeterRequired check. Material_Group_6__c: ' + workOrder.Case__r.Asset.Product2.Material_Group_6__c);
                List<MG6_Mapping__mdt> mappings = [SELECT Id, Hour_Meter_Applicable__c, MG6_Type__c
                                                FROM MG6_Mapping__mdt
                                                WHERE MG6_Type__c = :workOrder.Case__r.Asset.Product2.Material_Group_6__c
                                                LIMIT 1];
                System.debug('DEBUG 6: Mappings query completed. Size: ' + mappings.size());

                if (!mappings.isEmpty()) {
                    hourMeterRequired = mappings[0].Hour_Meter_Applicable__c;
                }
            }
            System.debug('DEBUG 7: hourMeterRequired determined: ' + hourMeterRequired);

            Installation_Report__c installationReport;
            Service_Report__c serviceReport;
            List<Service_Report_Observation__c> sroList;
            List<Cause_Sub_Cause_Master__c> causeSubCauseList;

            System.debug('DEBUG 8: About to check reportType. reportType: ' + reportType);
            if(reportType == 'InstallationReport') {
                System.debug('DEBUG 9: Calling getInstallationReportRecordFromDB');
                installationReport = getInstallationReportRecordFromDB(workOrder);
                System.debug('DEBUG 10: getInstallationReportRecordFromDB completed');
            }
            else if(reportType == 'ServiceReport') {
                System.debug('DEBUG 11: Calling getServiceReportRecordFromDB');
                serviceReport = getServiceReportRecordFromDB(workOrder, serviceAppointment, hourMeterRequired);
                System.debug('DEBUG 12: getServiceReportRecordFromDB completed. serviceReport: ' + (serviceReport != null ? 'NOT NULL, Id: ' + serviceReport.Id : 'NULL'));

                // causeSubCauseList = [
                //     SELECT Id, Name, Cause__c, Sub_Cause__c
                //     FROM Cause_Sub_Cause_Master__c
                //     WHERE Product__c =: workOrder.Case__r.Asset.Product2Id 
                //     AND Cause__c != null AND Sub_Cause__c != null 
                //     AND Business_Vertical__c =: workOrder.Case__r.Division__c
                //     ORDER BY Cause__c, Sub_Cause__c
                // ];
                // causeSubCauseList.addAll([
                //     SELECT Id, Name, Cause__c, Sub_Cause__c
                //     FROM Cause_Sub_Cause_Master__c
                //     WHERE Product__c = null 
                //     AND Material_Group__c =: workOrder.Case__r.Asset.Product2.Material_Group_6__c
                //     AND Cause__c != null AND Sub_Cause__c != null 
                //     AND Business_Vertical__c =: workOrder.Case__r.Division__c
                //     ORDER BY Cause__c, Sub_Cause__c
                // ]);

                if (serviceReport != null && serviceReport.Id != null) {
                    System.debug('DEBUG 13: Querying Service_Report_Observation__c');
                    sroList = [
                        SELECT Id, Cause__c, Sub_Cause__c, Correction__c, Actual_Observation_by_Engineer__c
                        FROM Service_Report_Observation__c
                        WHERE Service_Report__c = :serviceReport.Id
                    ];
                    System.debug('DEBUG 14: Service_Report_Observation__c queried. Size: ' + (sroList != null ? sroList.size() : 0));
                }
            }

            System.debug('DEBUG 15: About to return Map. workOrder: ' + (workOrder != null) + ', serviceAppointment: ' + (serviceAppointment != null) + ', serviceReport: ' + (serviceReport != null));
            return new Map<String, Object>{
                'workOrder' => workOrder,
                'serviceAppointment' => serviceAppointment,
                'installationReport' => installationReport,
                'serviceReport' => serviceReport,
                'sroList' => sroList,
                // 'causeSubCauseList' => causeSubCauseList,
                'email' => workOrder.Case__r.Contact?.Email,
                'hourMeterRequired' => hourMeterRequired
            };
        }
        catch (Exception e) {
            System.debug('ERROR: Exception caught at line ' + e.getLineNumber() + ': ' + e.getMessage());
            System.debug('ERROR: Stack trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error at line ' + e.getLineNumber() + ': ' + e.getMessage());
        }
    }

    private static Installation_Report__c getInstallationReportRecordFromDB(Work_Order__c workOrder) {
        // NOTE:
        // For printer (CIJ) installation we use many additional fields on Installation_Report__c
        // which are surfaced in the printer LWC and must be available in the returned record.
        // Always keep this field list in sync with the fields used in
        // fieldServicePrinterInstallationAndServiceReport.html.
        List<Installation_Report__c> irList = [
            SELECT
                Id,
                Name,
                Case__c,
                Work_Order__c,
                Item_Master__c,
                Installation_Asset_Serial_Number__c,
                Installation_Start_Date__c,
                Installation_End_Date__c,
                Installation_Status__c,
                Reason_for_Hold__c,
                Warranty_Start_Date__c,
                IsSavedByUser__c,
                // Customer header / signature details
                Customer_Email__c,
                Customer_Contact_Number__c,
                Customer_Feedback__c,
                Customer_Remark__c,
                Customer_Designation__c,
                Signature__c,
                Signature_by__c,
                // Basic information
                Party_Code__c,
                Customer_Name__c,
                Location__c,
                // Printer details
                Printer_Model__c,
                Printer_Serial_Number__c,
                Ink_Part_No__c,
                Ink_Exp_Date__c,
                Make_Up_Part_No__c,
                Make_Up_Exp_Date__c,
                Software_No__c,
                Nozzle_Serial_No__c,
                // Physical check
                Print_Head_Stand__c,
                Printer_Stand__c,
                Tool_Box__c,
                Sensor__c,
                Encoder__c,
                // TTO Physical Check fields
                Packing_foam_intact__c,
                Print_head_position_lifted__c,
                BOM_Check_list_verified__c,
                Sensor_Encoder_end_connectors__c,
                FRL__c,
                Bracket_received_as_per_CRM_quopte__c,
                Bracket_received_as_per_CRM_quopte_Text__c,
                // TIJ header specifics
                TIJ_Model_No__c,
                Number_of_head__c,
                Customer_Application__c,
                // Firmware_Number__c,
                Used_ink_cartridge__c,
                Cartridge_Exp_Date__c,
                Product_Counter__c,
                Next_Visit_Proposed_Date__c,
                // Input AC voltage / UPS / Earthing
                L_N_volt__c,
                N_G_volt__c,
                G_L_volt__c,
                UPS__c,
                Earthing__c,
                // Mixer / pumps / fans
                Mixer_OK__c,
                Mixer_Low__c,
                Mixer_High__c,
                Detection__c,
                Chamber_Low__c,
                Chamber_High__c,
                Main_Pump__c,
                Fan_01__c,
                Fan_02__c,
                Gutter_Pump__c,
                Flush_Pump__c,
                // Customer & production
                Industry_Type__c,
                Substrate_Type__c,
                Line_Speed_meter_per_Min__c,
                Line_Speed_mm_per_Sec__c,
                Customer_Product_Name__c,
                Work_Load_Hrs_Day__c,
                Work_Load_Days_Wk__c,
                Shift__c,
                // Message configuration
                Font_Size__c,
                Width__c,
                Bold__c,
                Number_Of_Lines__c,
                Height__c,
                Reverse__c,
                Gap_between_prints__c,
                Dots__c,
                Inverse__c,
                Print_Quality__c,
                Delay__c,
                // Photocell / technical settings
                LEVEL__c,
                Trigger_Mode__c,
                Second_Sensing__c,
                Blocking_Time__c,
                Signal_Time__c,
                Mode__c,
                Shaft_Encoder__c,
                Print_Mode__c,
                Traverse__c,
                Visc_Actual__c,
                Visc_Set_Point__c,
                VMS_Calibration__c,
                Print_Head_Set__c,
                // Machine set
                Modulation__c,
                Charge_Value__c,
                Running_Pressure__c,
                Heater_Point__c,
                Gutter_Mode__c,
                EHT_Grade__c,
                EHT_Range_Max__c,
                EHT_Range_Min__c,
                Ink_Temp__c,
                Cabinet_Temp__c,
                Head_Temp__c,
                Ink_Pressure__c,
                Ink_Type__c,
                Level_1_Password__c,
                Level_2_Password__c,
                // Valve test fields (CIJ only)
                V1__c,
                V2__c,
                V3__c,
                V4__c,
                V5__c,
                V6__c,
                V7__c,
                V8__c,
                V9__c,
                V11__c,
                V12__c,
                V13__c,
                // TTO specific fields
                Ribbon_Part_No__c,
                Ribbon_Customer_Stock__c,
                Ribbon_EXP_date__c,
                Expiration_Date__c,
                Printer_Manual_Included__c,
                Print_head_serial_Number__c,
                Input_Air_pressure__c,
                Print_head_Resistance__c,
                Ribbon_Dia_D1__c,
                Ribbon_Dia_D2__c,
                Print_speed__c,
                Ribbon_fail_count__c,
                Registration_Dot__c,
                Debounce_time_ms__c,
                Print_Delay__c,
                Pr_GO_Ignore__c,
                PR_GO_Edge__c,
                Heating_mode__c,
                Ribbon_Gap__c,
                Output_Air_Pressure__c,
                Head_out_time_ms__c,
                Head_In_Time__c,
                Start_Border_Trim__c,
                End_Border_Trim__c,
                Darkness__c,
                // Misc / header / status fields used in PDF & UI
                Hour_Meter__c,
                Activity_Completion_Manadatory__c,
                M_C_Breakdown__c,
                M_C_Temporary_Down__c,
                M_C_Running__c,
                Complaint_Status__c,
                Service_Rating__c,
                Service_Engineer_Name__c,
                Mobile_No__c,
                Repair_Start_Time__c,
                Repair_End_Time__c
            FROM Installation_Report__c
            WHERE Work_Order__c = :workOrder.Id
            ORDER BY CreatedDate DESC
        ];
        
        if(irList.size() > 1) {
            List<Installation_Report__c> irToDelete = new List<Installation_Report__c>();
            for(Integer i = 1; i < irList.size(); i++) {
                irToDelete.add(irList[i]);
            }
            delete irToDelete;
            return irList[0];
        }
        else if(irList.size() == 1) {
            return irList[0];
        }
        else if(irList.size() == 0) {
            return createInstallationReportRecord(workOrder);
        }
        else {
            throw new CustomException('Something went wrong, please get in touch with your system administrator.');
        }
    }

    private static Service_Report__c getServiceReportRecordFromDB(Work_Order__c workOrder, Service_Appointment__c serviceAppointment, Boolean hourMeterRequired) {
        System.debug('DEBUG getServiceReportRecordFromDB 1: Starting. workOrder: ' + (workOrder != null) + ', serviceAppointment: ' + (serviceAppointment != null) + ', hourMeterRequired: ' + hourMeterRequired);
        // Find Service Report by Service Appointment
        // Note: Ink_Part_Details_JSON__c and MakeUp_Part_Details_JSON__c should be created as Long Text Area fields on Service_Report__c
        System.debug('DEBUG getServiceReportRecordFromDB 2: About to query Service_Report__c. serviceAppointment.Id: ' + (serviceAppointment != null ? serviceAppointment.Id : 'NULL'));
        List<Service_Report__c> srList = [
            SELECT Id, Name, Case__c, Customer_Feedback__c, Customer_Remark__c, Reason_for_Hold__c, Root_Cause_Analysis__c,
                   Signature__c, Signature_by__c, SR_End_Date__c, SR_Remark__c, SR_Start_Date__c, SR_Status__c,
                   Service_Appointment__c, Case__r.Asset.Product2Id, OEM_Serial_Number__c, Hour_Meter__c, 
                   Customer_Email__c, Customer_Contact_Number__c, IsSavedByUser__c,
                   Customer_Problem_Statement__c, Cause__c, Sub_Cause__c, Action_Taken__c, Correction__c,
                   Customer_Designation__c, Type_of_Service__c, Service_Rating__c,
                   Complaint_Status__c,
                   MC_Breakdown__c, MC_Temporary_Down__c, MC_Running__c,
                   Ink_Part_No__c, Ink_Customer_Stock__c, Ink_Exp_Date__c,
                   MakeUp_Part_No__c, MakeUp_Customer_Stock__c, Make_Up_Exp_Date__c,
                   Software_No__c, Pump_Run_Hours__c, Nozzle_Serial_No__c, Head_Serial_Number__c,
                   Repair_Start_Time__c, Repair_End_Time__c,
                   // Travel & Expense fields for Labour Charges
                   TravelDate__c, Travel_From_1__c, Travel_To_1__c, Lodging_Per_Day_1__c, Boarding_Per_Day_1__c, 
                   Conven__c, Remark1__c, Travel_Date_2__c, Travel_From_2__c, Travel_To_2__c, 
                   Lodging_Per_Day_2__c, Boarding_Per_Day_2__c, Conveyance_2__c, Remark2__c, Date_To__c, Date_To_2__c
            FROM Service_Report__c
            WHERE Service_Appointment__c = :serviceAppointment.Id 
            ORDER BY CreatedDate DESC
        ];
        System.debug('DEBUG getServiceReportRecordFromDB 3: Service_Report__c queried. Size: ' + srList.size());

        Service_Report__c serviceReport;
        if(srList.size() > 1) {
            // Keep only the latest one, delete others
            List<Service_Report__c> srToDelete = new List<Service_Report__c>();
            for(Integer i = 1; i < srList.size(); i++) {
                srToDelete.add(srList[i]);
            }
            delete srToDelete;
            serviceReport = srList[0];
            // Populate Software_No__c from Asset.Software_Number__c (always use Asset as source of truth)
            if (workOrder.Case__r != null && workOrder.Case__r.Asset != null && String.isNotBlank(workOrder.Case__r.Asset.Software_Number__c)) {
                serviceReport.Software_No__c = workOrder.Case__r.Asset.Software_Number__c;
            }
        }
        else if(srList.size() == 1) {
            serviceReport = srList[0];
            // Populate Software_No__c from Asset.Software_Number__c (always use Asset as source of truth)
            if (workOrder.Case__r != null && workOrder.Case__r.Asset != null && String.isNotBlank(workOrder.Case__r.Asset.Software_Number__c)) {
                serviceReport.Software_No__c = workOrder.Case__r.Asset.Software_Number__c;
            }
        }
        else if(srList.size() == 0) {
            System.debug('DEBUG getServiceReportRecordFromDB 4: No Service Report found, calling createServiceReportRecord');
            return createServiceReportRecord(workOrder, serviceAppointment, hourMeterRequired);
        }
        else {
            throw new CustomException('Something went wrong, please get in touch with your system administrator.');
        }
        
        // If existing Service Report doesn't have Ink Part No or Make Up Part No, populate from first Service Report
        if (serviceReport != null && (serviceReport.Ink_Part_No__c == null || serviceReport.MakeUp_Part_No__c == null)) {
            // Get the FIRST Service Appointment for the same Case
            List<Service_Appointment__c> firstServiceAppointment = [
                SELECT Id 
                FROM Service_Appointment__c 
                WHERE Case__c = :workOrder.Case__c 
                ORDER BY CreatedDate ASC 
                LIMIT 1
            ];
            
            if (!firstServiceAppointment.isEmpty() && firstServiceAppointment[0].Id != serviceAppointment.Id) {
                // Get the Service Report for the first Service Appointment
                List<Service_Report__c> firstSrList = [
                    SELECT Id, Ink_Part_No__c, MakeUp_Part_No__c
                    FROM Service_Report__c
                    WHERE Service_Appointment__c = :firstServiceAppointment[0].Id
                    ORDER BY CreatedDate ASC
                    LIMIT 1
                ];
                if (!firstSrList.isEmpty()) {
                    if (serviceReport.Ink_Part_No__c == null && firstSrList[0].Ink_Part_No__c != null) {
                        serviceReport.Ink_Part_No__c = firstSrList[0].Ink_Part_No__c;
                        System.debug('Populated Ink_Part_No__c from first Service Report: ' + serviceReport.Ink_Part_No__c);
                    }
                    if (serviceReport.MakeUp_Part_No__c == null && firstSrList[0].MakeUp_Part_No__c != null) {
                        serviceReport.MakeUp_Part_No__c = firstSrList[0].MakeUp_Part_No__c;
                        System.debug('Populated MakeUp_Part_No__c from first Service Report: ' + serviceReport.MakeUp_Part_No__c);
                    }
                }
            }
        }
        
        return serviceReport;
    }

    private static Installation_Report__c createInstallationReportRecord(Work_Order__c workOrder) {
        Installation_Report__c installationReport = new Installation_Report__c();
        installationReport.Case__c = workOrder.Case__c;
        installationReport.Work_Order__c = workOrder.Id;
        installationReport.Installation_Asset_Serial_Number__c = workOrder.Case__r != null && workOrder.Case__r.Asset != null ? workOrder.Case__r.Asset.Name : null;
        installationReport.Item_Master__c = workOrder.Case__r != null && workOrder.Case__r.Asset != null ? workOrder.Case__r.Asset.Product2Id : null;
        installationReport.Installation_Start_Date__c = System.today();
        installationReport.Installation_End_Date__c = System.today();
        
        // Complaint Status should mirror the parent Case Status and remain user-read-only on the LWC.
        installationReport.Complaint_Status__c = workOrder.Case__r.Status;
        
        // Pre-populate Industry Type from Asset
        installationReport.Industry_Type__c = workOrder.Case__r.Asset != null ? workOrder.Case__r.Asset.Industry__c : null;
        
        // Pre-populate Location from Case Region
        installationReport.Location__c = workOrder.Case__r.Region__c;
        
        // Pre-populate Printer Model from Product2 Name (for CIJ)
        // Model number mapping based on Material Group 5 (printer family)
        if (workOrder.Case__r != null && workOrder.Case__r.Asset != null && workOrder.Case__r.Asset.Product2 != null) {
            String mg5 = workOrder.Case__r.Asset.Product2.Material_Group_5__c;
            String modelValue = workOrder.Case__r.Asset.Product2.Name;

            if (mg5 != null && String.isNotBlank(modelValue)) {
                String mg5Upper = mg5.toUpperCase();

                // Pre-populate Party Code and Customer Name for all printer types (CIJ, TIJ, TTO) - same as Service Report
                installationReport.Party_Code__c = workOrder.Case__r.Account != null ? workOrder.Case__r.Account.SAP_Customer_code__c : null;
                installationReport.Customer_Name__c = workOrder.Case__r.Account != null ? workOrder.Case__r.Account.Name : null;
                
                // CIJ (P01) → Printer_Model__c
                if (mg5Upper.contains('P01')) {
                    installationReport.Printer_Model__c = modelValue;
                }
                // TIJ (P03) → TIJ_Model_No__c
                else if (mg5Upper.contains('P03')) {
                    installationReport.TIJ_Model_No__c = modelValue;
                }
                // TTO (P02) → Printer_Model__c (for TTO, still use Printer_Model__c)
                else if (mg5Upper.contains('P02')) {
                    installationReport.Printer_Model__c = modelValue;
                }
                // Fallback: if no Material Group 5 match, set Printer_Model__c for backward compatibility
                else if (String.isNotBlank(modelValue)) {
                    installationReport.Printer_Model__c = modelValue;
                }
            }
        }
        
        // Pre-populate Printer Serial Number from Asset SerialNumber
        if (workOrder.Case__r != null && workOrder.Case__r.Asset != null && String.isNotBlank(workOrder.Case__r.Asset.SerialNumber)) {
            installationReport.Printer_Serial_Number__c = workOrder.Case__r.Asset.SerialNumber;
        }
        
        // Populate Software_No__c from Asset.Software_Number__c
        if (workOrder.Case__r != null && workOrder.Case__r.Asset != null && String.isNotBlank(workOrder.Case__r.Asset.Software_Number__c)) {
            installationReport.Software_No__c = workOrder.Case__r.Asset.Software_Number__c;
        }
        
        insert installationReport;
        return installationReport;
    }

    private static Service_Report__c createServiceReportRecord(Work_Order__c workOrder, Service_Appointment__c serviceAppointment, Boolean hourMeterRequired) {
        System.debug('DEBUG createServiceReportRecord 1: Starting. workOrder: ' + (workOrder != null) + ', serviceAppointment: ' + (serviceAppointment != null) + ', hourMeterRequired: ' + hourMeterRequired);
        System.debug('DEBUG createServiceReportRecord 2: workOrder.Case__c: ' + (workOrder != null ? workOrder.Case__c : 'NULL') + ', workOrder.Case__r: ' + (workOrder != null && workOrder.Case__r != null ? 'NOT NULL' : 'NULL'));
        // 26-11
        Service_Report__c prevSrFromSameCase;
        Service_Report__c firstSrFromSameCase;
        try {
            System.debug('DEBUG createServiceReportRecord 3: Inside try block');
            // First, find the most recent Service Appointment for the same Case (excluding current one)
            // This is used for Software No and Pump Run Hours
            List<Service_Appointment__c> prevServiceAppointments = [
                SELECT Id 
                FROM Service_Appointment__c 
                WHERE Case__c = :workOrder.Case__c 
                AND Id != :serviceAppointment.Id
                ORDER BY CreatedDate DESC 
                LIMIT 1
            ];
            
            if (!prevServiceAppointments.isEmpty()) {
                // Get the Service Report for that previous Service Appointment
            prevSrFromSameCase = [SELECT Id, Name, Case__c, Service_Appointment__c, Work_Order__c, Case__r.Asset.Product2Id, Action_Taken__c,
                                    Cause__c, Sub_Cause__c, Other_Cause__c, Correction__c, Customer_Problem_Statement__c, Hour_Meter__c,OEM_Serial_Number__c,
                                    Software_No__c, Pump_Run_Hours__c, Nozzle_Serial_No__c, Head_Serial_Number__c
                                FROM Service_Report__c
                                    WHERE Service_Appointment__c = :prevServiceAppointments[0].Id
                                ORDER BY CreatedDate DESC
                                LIMIT 1];
            }
            
            // Get the FIRST Service Appointment for the same Case to get Ink Part No and Make Up Part No
            // These values should remain the same for all Service Reports for the Case
            List<Service_Appointment__c> firstServiceAppointment = [
                SELECT Id 
                FROM Service_Appointment__c 
                WHERE Case__c = :workOrder.Case__c 
                ORDER BY CreatedDate ASC 
                LIMIT 1
            ];
            
            System.debug('First Service Appointment query result size: ' + firstServiceAppointment.size());
            System.debug('Current Service Appointment Id: ' + serviceAppointment.Id);
            
            if (!firstServiceAppointment.isEmpty()) {
                System.debug('First Service Appointment Id: ' + firstServiceAppointment[0].Id);
                
                // Check if current Service Appointment is NOT the first one
                if (firstServiceAppointment[0].Id != serviceAppointment.Id) {
                    // Get the Service Report for the first Service Appointment
                    List<Service_Report__c> firstSrList = [
                        SELECT Id, Ink_Part_No__c, MakeUp_Part_No__c
                        FROM Service_Report__c
                        WHERE Service_Appointment__c = :firstServiceAppointment[0].Id
                        ORDER BY CreatedDate ASC
                        LIMIT 1
                    ];
                    System.debug('First Service Report query result size: ' + firstSrList.size());
                    if (!firstSrList.isEmpty()) {
                        firstSrFromSameCase = firstSrList[0];
                        System.debug('First Service Report found - Id: ' + firstSrFromSameCase.Id + ', Ink_Part_No__c: ' + firstSrFromSameCase.Ink_Part_No__c + ', MakeUp_Part_No__c: ' + firstSrFromSameCase.MakeUp_Part_No__c);
                    } else {
                        System.debug('No Service Report found for first Service Appointment');
                    }
                } else {
                    System.debug('Current Service Appointment IS the first one - fields will remain blank and editable');
                }
            } else {
                System.debug('No Service Appointments found for Case - this is the first one');
            }
        } catch (Exception ex) {
            System.debug('DEBUG createServiceReportRecord 4: Exception in try block: ' + ex.getMessage() + ' at line ' + ex.getLineNumber());
            prevSrFromSameCase = new Service_Report__c();
            prevSrFromSameCase.Customer_Problem_Statement__c  = serviceAppointment.Case__r != null ? serviceAppointment.Case__r.Description : null;
        }
        System.debug('DEBUG createServiceReportRecord 5: Creating new Service_Report__c');
        Service_Report__c serviceReport = new Service_Report__c();
        System.debug('DEBUG createServiceReportRecord 6: Setting basic fields');
        serviceReport.Case__c = workOrder.Case__c;
        serviceReport.Service_Appointment__c = serviceAppointment.Id;
        serviceReport.Work_Order__c = workOrder.Id;
        System.debug('DEBUG createServiceReportRecord 7: About to set Product__c. Case__r: ' + (workOrder.Case__r != null) + ', Asset: ' + (workOrder.Case__r != null && workOrder.Case__r.Asset != null));
        serviceReport.Product__c = workOrder.Case__r != null && workOrder.Case__r.Asset != null ? workOrder.Case__r.Asset.Product2Id : null;
        serviceReport.SR_Start_Date__c = System.today();
        serviceReport.SR_End_Date__c = System.today();
        
        // Populate Repair Start Time and Repair End Time from Service Appointment
        if (serviceAppointment.Check_In_Date_Time__c != null) {
            serviceReport.Repair_Start_Time__c = serviceAppointment.Check_In_Date_Time__c;
        }
        if (serviceAppointment.Check_Out_Date_Time__c != null) {
            serviceReport.Repair_End_Time__c = serviceAppointment.Check_Out_Date_Time__c;
        }
        
        System.debug('DEBUG createServiceReportRecord 8: Basic fields set');

        // Pre-populate key header / customer fields so they appear on the LWC
        // and PDF without manual entry.
        serviceReport.Customer_Name__c = workOrder.Case__r.Account != null ? workOrder.Case__r.Account.Name : null;
        serviceReport.Party_Code__c = workOrder.Case__r.Account != null ? workOrder.Case__r.Account.SAP_Customer_code__c : null;
        serviceReport.Contact_Person__c = workOrder.Case__r.Contact != null ? workOrder.Case__r.Contact.Name : null;
        // Type of Service should mirror Case Sub Type for consistency with the PDF
        serviceReport.Type_of_Service__c = workOrder.Case__r.Case_Sub_Type__c;
        // Default Signature_by__c to the Contact Person name so it's available even
        // if the signature modal is not used.
        serviceReport.Signature_by__c = serviceReport.Contact_Person__c;
        // Guard against STRING_TOO_LONG if ContactMobile exceeds the target field's length
        String contactMobile = workOrder.Case__r.ContactMobile;
        if (contactMobile != null && contactMobile.length() > 15) {
            contactMobile = contactMobile.substring(0, 15);
        }
        serviceReport.Customer_Contact_Number__c = contactMobile;
        serviceReport.Customer_Email__c = workOrder.Case__r.ContactEmail;
        serviceReport.Sr_No__c = workOrder.Case__r.Asset != null ? workOrder.Case__r.Asset.SerialNumber : null;

        // Populate Software_No__c from Asset.Software_Number__c
        if (workOrder.Case__r != null && workOrder.Case__r.Asset != null && String.isNotBlank(workOrder.Case__r.Asset.Software_Number__c)) {
            serviceReport.Software_No__c = workOrder.Case__r.Asset.Software_Number__c;
        }
        
        // Populate Pump_Run_Hours__c from previous Service Report for the same Case (if exists)
        // If this is the first Service Report for the Case, it will remain blank and editable
        if (prevSrFromSameCase != null && prevSrFromSameCase.Pump_Run_Hours__c != null) {
            serviceReport.Pump_Run_Hours__c = prevSrFromSameCase.Pump_Run_Hours__c;
        }
        
        // Populate Nozzle_Serial_No__c from previous Service Report for the same Case (if exists)
        // If this is the first Service Report for the Case, it will remain blank and editable (mandatory)
        if (prevSrFromSameCase != null && prevSrFromSameCase.Nozzle_Serial_No__c != null) {
            serviceReport.Nozzle_Serial_No__c = prevSrFromSameCase.Nozzle_Serial_No__c;
        }
        
        // Populate Head_Serial_Number__c from previous Service Report for the same Case (if exists)
        // If this is the first Service Report for the Case, it will remain blank and editable (mandatory)
        if (prevSrFromSameCase != null && prevSrFromSameCase.Head_Serial_Number__c != null) {
            serviceReport.Head_Serial_Number__c = prevSrFromSameCase.Head_Serial_Number__c;
        }
        
        // Populate Ink_Part_No__c and MakeUp_Part_No__c from FIRST Service Report for the same Case (if exists)
        // These values should remain the same for all Service Reports for the Case
        // If this is the first Service Report for the Case, these fields will remain blank and editable
        // Unlike Software_No__c, these fields will be read-only (disabled) in the UI when pre-populated
        if (firstSrFromSameCase != null) {
            System.debug('First Service Report found - Ink_Part_No__c: ' + firstSrFromSameCase.Ink_Part_No__c + ', MakeUp_Part_No__c: ' + firstSrFromSameCase.MakeUp_Part_No__c);
            if (firstSrFromSameCase.Ink_Part_No__c != null) {
                serviceReport.Ink_Part_No__c = firstSrFromSameCase.Ink_Part_No__c;
            }
            if (firstSrFromSameCase.MakeUp_Part_No__c != null) {
                serviceReport.MakeUp_Part_No__c = firstSrFromSameCase.MakeUp_Part_No__c;
            }
        } else {
            System.debug('No first Service Report found - this is likely the first Service Report for the Case');
        }

        // Complaint Status should mirror the parent Case Status and remain user-read-only on the LWC.
        // This ensures consistency between the Case and the Service Report / PDF.
        serviceReport.Complaint_Status__c = workOrder.Case__r.Status;

        // Model number mapping based on Material Group 5 (printer family)
        System.debug('DEBUG createServiceReportRecord 9: About to check Product2. Case__r: ' + (workOrder.Case__r != null) + ', Asset: ' + (workOrder.Case__r != null && workOrder.Case__r.Asset != null) + ', Product2: ' + (workOrder.Case__r != null && workOrder.Case__r.Asset != null && workOrder.Case__r.Asset.Product2 != null));
        if (workOrder.Case__r != null && workOrder.Case__r.Asset != null && workOrder.Case__r.Asset.Product2 != null) {
            System.debug('DEBUG createServiceReportRecord 10: Inside Product2 check');
            String mg5 = workOrder.Case__r.Asset.Product2.Material_Group_5__c;
            String modelValue = workOrder.Case__r.Asset.Product2.Name;

            if (mg5 != null) {
                String mg5Upper = mg5.toUpperCase();

                // CIJ (P01) → CIJ_Model_No__c
                if (mg5Upper.contains('P01')) {
                    serviceReport.CIJ_Model_No__c = modelValue;
                }
                // TIJ (P03) → TIJ_Model_No__c
                else if (mg5Upper.contains('P03')) {
                    serviceReport.TIJ_Model_No__c = modelValue;
                }
                // TTO (P02) → TTO_Model_No__c
                else if (mg5Upper.contains('P02')) {
                    serviceReport.TTO_Model_No__c = modelValue;
                }
            }
        }

        // Copy selected fields from the previous Service Report on the same Case
        System.debug('DEBUG createServiceReportRecord 11: About to copy from prevSrFromSameCase. prevSrFromSameCase: ' + (prevSrFromSameCase != null));
        serviceReport.Customer_Problem_Statement__c = prevSrFromSameCase != null ? prevSrFromSameCase.Customer_Problem_Statement__c : null;
        serviceReport.Cause__c = prevSrFromSameCase != null ? prevSrFromSameCase.Cause__c : null;
        serviceReport.Sub_Cause__c = prevSrFromSameCase != null ? prevSrFromSameCase.Sub_Cause__c : null;
        serviceReport.Other_Cause__c = prevSrFromSameCase != null ? prevSrFromSameCase.Other_Cause__c : null;
        serviceReport.Correction__c = prevSrFromSameCase != null ? prevSrFromSameCase.Correction__c : null;
        serviceReport.Action_Taken__c = prevSrFromSameCase != null ? prevSrFromSameCase.Action_Taken__c : null;
        serviceReport.Hour_Meter__c = prevSrFromSameCase != null ? prevSrFromSameCase.Hour_Meter__c : null;
        System.debug('DEBUG createServiceReportRecord 12: About to set OEM_Serial_Number__c');
        serviceReport.OEM_Serial_Number__c = workOrder.Case__r != null && workOrder.Case__r.Asset != null ? workOrder.Case__r.Asset.OEM_Serial_Number__c : null;
        if (hourMeterRequired && serviceReport.Hour_Meter__c == null && prevSrFromSameCase != null) {
            serviceReport.Hour_Meter__c = prevSrFromSameCase.Hour_Meter__c;
        }
        // 26-11

        // Service_Report__c serviceReport = new Service_Report__c();
        // serviceReport.Service_Appointment__c = serviceAppointment.Id;
        // serviceReport.Work_Order__c = workOrder.Id;
        // serviceReport.Case__c = workOrder.Case__c;
        // serviceReport.Product__c = workOrder.Case__r.Asset.Product2Id;
        // serviceReport.SR_Start_Date__c = System.today();
        // serviceReport.SR_End_Date__c = System.today();
        // serviceReport.SR_Status__c = 'Working';
        // serviceReport.Customer_Problem_Statement__c = workOrder.Case__r.Description;
        // serviceReport.OEM_Serial_Number__c = workOrder.Case__r.Asset.OEM_Serial_Number__c;
        // if (hourMeterRequired) {
        //     serviceReport.Hour_Meter__c = 0; // Default value
        // }
        // Service_Report__c previousReport = getPreviousServiceReport(workOrder.Case__c);
        // if (previousReport != null) {
        //     serviceReport.Cause__c = previousReport.Cause__c;
        //     serviceReport.Sub_Cause__c = previousReport.Sub_Cause__c;
        //     serviceReport.Correction__c = previousReport.Correction__c;
        //     serviceReport.Action_Taken__c = previousReport.Action_Taken__c;
        //     serviceReport.Root_Cause_Analysis__c = previousReport.Root_Cause_Analysis__c;
            
        //     if (hourMeterRequired && previousReport.Hour_Meter__c != null) {
        //         serviceReport.Hour_Meter__c = previousReport.Hour_Meter__c;
        //     }
        // }
        
        System.debug('DEBUG createServiceReportRecord 13: About to insert serviceReport');
        insert serviceReport;
        System.debug('DEBUG createServiceReportRecord 14: serviceReport inserted successfully. Id: ' + serviceReport.Id);
        return serviceReport;
    }

    private static Service_Report__c getPreviousServiceReport(String caseId) {
        try {
            return [SELECT Id, Cause__c, Sub_Cause__c, Correction__c, Action_Taken__c, 
                           Root_Cause_Analysis__c, Hour_Meter__c, Customer_Problem_Statement__c
                    FROM Service_Report__c 
                    WHERE Case__c = :caseId 
                    ORDER BY CreatedDate DESC 
                    LIMIT 1];
        } catch (Exception e) {
            return null;
        }
    }

    @AuraEnabled(cacheable=true)
    public static Decimal getMaxPumpRunHoursForCase(String caseId, String currentServiceReportId) {
        try {
            List<Service_Report__c> previousServiceReports;
            if (String.isNotBlank(currentServiceReportId)) {
                // Exclude current record if it's an update
                previousServiceReports = [
                    SELECT Pump_Run_Hours__c 
                    FROM Service_Report__c 
                    WHERE Case__c = :caseId 
                    AND Pump_Run_Hours__c != null
                    AND Id != :currentServiceReportId
                    ORDER BY Pump_Run_Hours__c DESC 
                    LIMIT 1
                ];
            } else {
                // New record - get all previous Service Reports
                previousServiceReports = [
                    SELECT Pump_Run_Hours__c 
                    FROM Service_Report__c 
                    WHERE Case__c = :caseId 
                    AND Pump_Run_Hours__c != null
                    ORDER BY Pump_Run_Hours__c DESC 
                    LIMIT 1
                ];
            }
            
            if (!previousServiceReports.isEmpty() && previousServiceReports[0].Pump_Run_Hours__c != null) {
                return previousServiceReports[0].Pump_Run_Hours__c;
            }
            return null;
        } catch (Exception e) {
            System.debug('Error getting max Pump Run Hours: ' + e.getMessage());
            return null;
        }
    }

    @AuraEnabled(cacheable=true)
    public static Boolean hasSpareRequestsForCase(String caseId) {
        try {
            if (String.isBlank(caseId)) {
                return false;
            }
            
            List<Spare_Request__c> spareRequests = [
                SELECT Id 
                FROM Spare_Request__c 
                WHERE Case__c = :caseId 
                LIMIT 1
            ];
            
            return !spareRequests.isEmpty();
        } catch (Exception e) {
            System.debug('Error checking spare requests: ' + e.getMessage());
            return false;
        }
    }

    @AuraEnabled
    public static Service_Report__c saveServiceReport(Service_Report__c serviceReportRecord, String workOrderId, String serviceAppointmentId, String currentReportParameters) {
        // Validate input
            if (serviceReportRecord == null) {
                throw new AuraHandledException('Service Report record is null');
            }
            
            // Create a new instance to ensure we're working with clean data
            Service_Report__c reportToSave = new Service_Report__c();
            
            // Copy ID if exists (for update)
            if (serviceReportRecord.Id != null) {
                reportToSave.Id = serviceReportRecord.Id;
            }
            
            // Copy all fields from the incoming record using safe field access
            // Use getPopulatedFieldsAsMap() to only copy fields that are actually set
            reportToSave.IsSavedByUser__c = true;
            
            // Get all populated fields from the incoming record
            Map<String, Object> populatedFields = serviceReportRecord.getPopulatedFieldsAsMap();
            System.debug('DEBUG saveServiceReport 828: populatedFields: ' + populatedFields);
            // List of all valid fields that can be copied to Service_Report__c
            Set<String> validFields = new Set<String>{
                'SR_Start_Date__c', 'SR_End_Date__c', 'SR_Status__c', 'Complaint_Status__c',
                'Customer_Problem_Statement__c', 'Cause__c', 'Sub_Cause__c', 'Action_Taken__c',
                'Correction__c', 'Root_Cause_Analysis__c', 'Type_of_Service__c', 'Customer_Feedback__c',
                'Customer_Remark__c', 'Service_Rating__c', 'Customer_Email__c', 'Customer_Contact_Number__c',
                'OEM_Serial_Number__c', 'Hour_Meter__c', 'Software_No__c', 'Pump_Run_Hours__c',
                'Reason_for_Hold__c', 'SR_Remark__c', 'TravelDate__c', 'Travel_From_1__c', 'Travel_To_1__c', 'Lodging_Per_Day_1__c', 'Boarding_Per_Day_1__c', 'Conven__c', 'Remark1__c', 'Travel_Date_2__c', 'Travel_From_2__c', 'Travel_To_2__c', 'Lodging_Per_Day_2__c', 'Boarding_Per_Day_2__c', 'Conveyance_2__c', 'Remark2__c', 'Date_To__c', 'Date_To_2__c',
                // CIJ fields
                'Ink_Part_No__c', 'Ink_Customer_Stock__c', 'Ink_Exp_Date__c', 'MakeUp_Part_No__c',
                'MakeUp_Customer_Stock__c', 'Make_Up_Exp_Date__c', 'Nozzle_Serial_No__c',
                'Visc_Set_Point__c', 'Visc_Actual__c', 'Ink_Temp__c', 'Cabinet_Temp__c',
                'Head_Temp__c', 'Ink_Pressure__c', 'Heater_Point__c', 'Modulation__c',
                'Charge_Value__c', 'EHT_Range_Min__c', 'EHT_Range_Max__c', 'EHT_Grade__c',
                'Gutter_Mode__c', 'Print_Quality__c', 'Ink_Type__c', 'VMC_Calibration__c',
                'Customer_Application__c', 'Complaint_Details__c',
                // TTO fields
                'Ribbon_Part__c', 'Ribbon_Customer_Stock__c', 'Ribbon_EXP_date__c', 'Expiration_Date__c', 'Printer_Manual_Included__c',
                'TTO_Model_No__c', 'Print_head_Kms__c', 'Input_Air_Pressure__c',
                'Print_Head_Resistance__c', 'Ribbon_Dia_D1__c', 'Ribbon_Dia_D2__c',
                'Print_Speed__c', 'Ribbon_Fail_Count__c', 'Registration_Dot__c',
                'Debounce_Time__c', 'Print_Delay__c', 'PR_GO_Ignore__c', 'PR_GO_Edge__c',
                'Heating_Mode__c', 'Ribbon_Gap__c', 'Output_Air_Pressure__c',
                'Head_Out_Time__c', 'Head_In_Time__c', 'Start_Border_Trim__c',
                'End_Border_Trim__c', 'Darkness__c', 'Head_Serial_Number__c',
                // TIJ fields
                'TIJ_Model_No__c', 'Ink_Cartridge_Part__c',
                'Cartridge_Exp_Date__c', 'Product_Counter__c',
                // Machine status fields
                'MC_Breakdown__c', 'MC_Temporary_Down__c', 'MC_Running__c',
                // Signature fields
                'Signature__c', 'Signature_by__c', 'Customer_Designation__c',
                // Repair time fields
                'Repair_Start_Time__c', 'Repair_End_Time__c'
            };
            
            // Copy only valid fields that are populated
            for (String fieldName : populatedFields.keySet()) {
                // Skip Id, Case__c, Service_Appointment__c as they are handled separately
                if (fieldName == 'Id' || fieldName == 'Case__c' || fieldName == 'Service_Appointment__c') {
                    continue;
                }
                
                // Only copy if it's a valid field
                if (validFields.contains(fieldName)) {
                    try {
                        Object fieldValue = populatedFields.get(fieldName);
                        if (fieldValue != null) {
                            reportToSave.put(fieldName, fieldValue);
                        }
                    } catch (SObjectException soe) {
                        System.debug(LoggingLevel.ERROR, 'Error setting field ' + fieldName + ': ' + soe.getMessage());
                        // Skip this field and continue
                    } catch (Exception e) {
                        System.debug(LoggingLevel.ERROR, 'Unexpected error setting field ' + fieldName + ': ' + e.getMessage());
                        // Skip this field and continue
                    }
                }
            }
            
            // Set the key relationship - Service Appointment
            if (serviceReportRecord.Service_Appointment__c != null) {
                reportToSave.Service_Appointment__c = serviceReportRecord.Service_Appointment__c;
            } else if (String.isNotBlank(serviceAppointmentId)) {
                reportToSave.Service_Appointment__c = serviceAppointmentId;
            }
            
            // Set Case if provided
            if (serviceReportRecord.Case__c != null) {
                reportToSave.Case__c = serviceReportRecord.Case__c;
            }
            
            // Validate required fields
            if (reportToSave.Service_Appointment__c == null) {
                throw new AuraHandledException('Service Appointment is required for Service Report.');
            }
            
            // Ensure Case is set - get from Service Appointment if not provided
            // Also populate Repair Start Time and Repair End Time from Service Appointment if not already set
            if (reportToSave.Service_Appointment__c != null && 
                (reportToSave.Case__c == null || reportToSave.Repair_Start_Time__c == null || reportToSave.Repair_End_Time__c == null)) {
                try {
                    List<Service_Appointment__c> saList = [
                        SELECT Case__c, Check_In_Date_Time__c, Check_Out_Date_Time__c 
                        FROM Service_Appointment__c 
                        WHERE Id = :reportToSave.Service_Appointment__c 
                        LIMIT 1
                    ];
                    
                    if (!saList.isEmpty()) {
                        Service_Appointment__c sa = saList[0];
                        if (reportToSave.Case__c == null && sa.Case__c != null) {
                reportToSave.Case__c = sa.Case__c;
                        }
                        // Populate Repair Start Time and Repair End Time from Service Appointment if not already set
                        if (reportToSave.Repair_Start_Time__c == null && sa.Check_In_Date_Time__c != null) {
                            reportToSave.Repair_Start_Time__c = sa.Check_In_Date_Time__c;
                        }
                        if (reportToSave.Repair_End_Time__c == null && sa.Check_Out_Date_Time__c != null) {
                            reportToSave.Repair_End_Time__c = sa.Check_Out_Date_Time__c;
                        }
                    }
                } catch (Exception e) {
                    System.debug(LoggingLevel.ERROR, 'Error querying Service Appointment: ' + e.getMessage());
                    System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
                    // Continue - Case might already be set, or we'll fail validation later
                }
            }
            
            // Validate Pump_Run_Hours__c: must be greater than previous Service Reports for the same Case
            if (reportToSave.Pump_Run_Hours__c != null && reportToSave.Case__c != null) {
                // Get the maximum Pump_Run_Hours__c from previous Service Reports for the same Case
                // Exclude the current Service Report if it's an update
                List<Service_Report__c> previousServiceReports;
                if (reportToSave.Id != null) {
                    // Exclude current record if it's an update
                    previousServiceReports = [
                        SELECT Pump_Run_Hours__c 
                        FROM Service_Report__c 
                        WHERE Case__c = :reportToSave.Case__c 
                        AND Pump_Run_Hours__c != null
                        AND Id != :reportToSave.Id
                        ORDER BY Pump_Run_Hours__c DESC 
                        LIMIT 1
                    ];
                } else {
                    // New record - get all previous Service Reports
                    previousServiceReports = [
                        SELECT Pump_Run_Hours__c 
                        FROM Service_Report__c 
                        WHERE Case__c = :reportToSave.Case__c 
                        AND Pump_Run_Hours__c != null
                        ORDER BY Pump_Run_Hours__c DESC 
                        LIMIT 1
                    ];
                }
                
                if (!previousServiceReports.isEmpty() && previousServiceReports[0].Pump_Run_Hours__c != null) {
                    Decimal maxPreviousValue = previousServiceReports[0].Pump_Run_Hours__c;
                    if (reportToSave.Pump_Run_Hours__c <= maxPreviousValue) {
                        throw new AuraHandledException('Pump Run Hours (' + reportToSave.Pump_Run_Hours__c + ') must be greater than the previous value (' + maxPreviousValue + ') from previous Service Reports for this Case.');
                    }
                }
            }   

            System.debug('DEBUG saveServiceReport 974: reportToSave: ' + reportToSave);
            
            // Upsert the record
            try {
            upsert reportToSave;
            } catch (DmlException dmlEx) {
                System.debug(LoggingLevel.ERROR, 'DML Error: ' + dmlEx.getMessage());
                System.debug(LoggingLevel.ERROR, 'DML Type: ' + dmlEx.getDmlType(0));
                System.debug(LoggingLevel.ERROR, 'DML Fields: ' + dmlEx.getDmlFieldNames(0));
                System.debug(LoggingLevel.ERROR, 'DML Status Code: ' + dmlEx.getDmlStatusCode(0));
                throw new AuraHandledException('Error saving Service Report: ' + dmlEx.getDmlMessage(0));
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Unexpected error saving Service Report: ' + e.getMessage());
                System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
                throw new AuraHandledException('Unexpected error saving Service Report: ' + e.getMessage());
            }
            
            // Parse and save parameters if provided
            if (String.isNotBlank(currentReportParameters) && reportToSave.Id != null) {
                try {
                    List<Service_Report_Printer_Parameter__c> parametersToSave = parseAndConvertParameters(currentReportParameters, reportToSave.Id);
                    if (parametersToSave != null && !parametersToSave.isEmpty()) {
                        // Delete existing parameters for this service report
                        delete [SELECT Id FROM Service_Report_Printer_Parameter__c WHERE Service_Report__c = :reportToSave.Id];
                        System.debug('parametersToSave: ' + parametersToSave);
                        // Insert new parameters
                        insert parametersToSave;
                    }
                } catch (Exception e) {
                    System.debug(LoggingLevel.ERROR, 'Error saving parameters: ' + e.getMessage());
                    System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
                    // Don't throw exception - parameters save failure shouldn't fail the entire save
                }
            }
            
            return reportToSave;
    }

    /**
     * @description Parse JSON string of parameters and convert to Service_Report_Printer_Parameter__c records
     * @param parametersJson JSON string containing array of parameter objects
     * @param serviceReportId The Service Report Id to link the parameters
     * @return List of Service_Report_Printer_Parameter__c records
     */
    private static List<Service_Report_Printer_Parameter__c> parseAndConvertParameters(String parametersJson, String serviceReportId) {
        List<Service_Report_Printer_Parameter__c> parameters = new List<Service_Report_Printer_Parameter__c>();
        
        if (String.isBlank(parametersJson) || String.isBlank(serviceReportId)) {
            return parameters;
        }
        
        try {
            // Parse the JSON string into a list of maps
            List<Object> paramList = (List<Object>) JSON.deserializeUntyped(parametersJson);
            
            Integer displayOrder = 1;
            for (Object paramObj : paramList) {
                Map<String, Object> paramMap = (Map<String, Object>) paramObj;
                System.debug('paramMap: ' + paramMap);
                Service_Report_Printer_Parameter__c param = new Service_Report_Printer_Parameter__c();
                param.Service_Report__c = serviceReportId;
                param.Display_Order__c = displayOrder++;
                
                // Extract parameterName
                if (paramMap.containsKey('parameterName') && paramMap.get('parameterName') != null) {
                    param.Name = String.valueOf(paramMap.get('parameterName'));
                }
                
                // Extract selectedType (check multiple possible field names)
                if (paramMap.containsKey('selectedType') && paramMap.get('selectedType') != null) {
                    param.Selected_Type__c = String.valueOf(paramMap.get('selectedType'));
                } else if (paramMap.containsKey('selectionType') && paramMap.get('selectionType') != null) {
                    param.Selected_Type__c = String.valueOf(paramMap.get('selectionType'));
                }
                
                // Extract selectionValue
                if (paramMap.containsKey('selectedValue') && paramMap.get('selectedValue') != null) {
                    param.Selection_Value__c = String.valueOf(paramMap.get('selectedValue'));
                }
                
                // Extract selectionOptionList or optionList (check multiple possible field names)
                if (paramMap.containsKey('selectedOption') && paramMap.get('selectedOption') != null) {
                    param.Selection_Options_List__c = String.valueOf(paramMap.get('selectedOption'));
                } else if (paramMap.containsKey('optionList') && paramMap.get('optionList') != null) {
                    param.Selection_Options_List__c = String.valueOf(paramMap.get('optionList'));
                }
                
                // Only add parameter if it has at least a name
                if (String.isNotBlank(param.Name)) {
                    parameters.add(param);
                }
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error parsing parameters JSON: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
            System.debug(LoggingLevel.ERROR, 'Parameters JSON: ' + parametersJson);
            // Don't throw exception - log error but continue
        }
        
        return parameters;
    }

    /**
     * Parse JSON string of parameters and convert to Installation_Report_Printer_Parameter__c records
     * @param parametersJson JSON string containing parameters array
     * @param installationReportId The Installation Report Id to link the parameters
     * @return List of Installation_Report_Printer_Parameter__c records
     */
    private static List<Installation_Report_Printer_Parameter__c> parseAndConvertInstallationParameters(String parametersJson, String installationReportId) {
        List<Installation_Report_Printer_Parameter__c> parameters = new List<Installation_Report_Printer_Parameter__c>();
        
        if (String.isBlank(parametersJson) || String.isBlank(installationReportId)) {
            return parameters;
        }
        
        try {
            // Parse the JSON string into a list of maps
            List<Object> paramList = (List<Object>) JSON.deserializeUntyped(parametersJson);
            
            Integer displayOrder = 1;
            for (Object paramObj : paramList) {
                Map<String, Object> paramMap = (Map<String, Object>) paramObj;
                System.debug('paramMap: ' + paramMap);
                Installation_Report_Printer_Parameter__c param = new Installation_Report_Printer_Parameter__c();
                param.Installation_Report__c = installationReportId;
                param.Display_Order__c = displayOrder++;
                
                // Extract parameterName
                if (paramMap.containsKey('parameterName') && paramMap.get('parameterName') != null) {
                    param.Name = String.valueOf(paramMap.get('parameterName'));
                }
                
                // Extract selectedType (check multiple possible field names)
                if (paramMap.containsKey('selectedType') && paramMap.get('selectedType') != null) {
                    param.Selected_Type__c = String.valueOf(paramMap.get('selectedType'));
                } else if (paramMap.containsKey('selectionType') && paramMap.get('selectionType') != null) {
                    param.Selected_Type__c = String.valueOf(paramMap.get('selectionType'));
                }
                
                // Extract selectionValue
                if (paramMap.containsKey('selectedValue') && paramMap.get('selectedValue') != null) {
                    param.Selection_Value__c = String.valueOf(paramMap.get('selectedValue'));
                }
                
                // Extract selectionOptionList or optionList (check multiple possible field names)
                if (paramMap.containsKey('selectedOption') && paramMap.get('selectedOption') != null) {
                    param.Selection_Options_List__c = String.valueOf(paramMap.get('selectedOption'));
                } else if (paramMap.containsKey('optionList') && paramMap.get('optionList') != null) {
                    param.Selection_Options_List__c = String.valueOf(paramMap.get('optionList'));
                }
                
                // Only add parameter if it has at least a name
                if (String.isNotBlank(param.Name)) {
                    parameters.add(param);
                }
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error parsing installation parameters JSON: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
            System.debug(LoggingLevel.ERROR, 'Parameters JSON: ' + parametersJson);
            // Don't throw exception - log error but continue
        }
        
        return parameters;
    }

    @AuraEnabled
    public static void saveServiceReportParameters(List<Service_Report_Printer_Parameter__c> parameters) {
            if (parameters != null && !parameters.isEmpty()) {
                // First delete existing parameters for this service report
                String serviceReportId = parameters[0].Service_Report__c;
                if (String.isNotBlank(serviceReportId)) {
                    delete [SELECT Id FROM Service_Report_Printer_Parameter__c WHERE Service_Report__c = :serviceReportId];
                }
                
                // Insert new parameters
                insert parameters;
        }
    }

    @AuraEnabled
    public static void saveInstallationReportParameters(List<Installation_Report_Printer_Parameter__c> parameters) {
        try {
            if (parameters != null && !parameters.isEmpty()) {
                // First delete existing parameters for this installation report
                String installationReportId = parameters[0].Installation_Report__c;
                
                if (String.isNotBlank(installationReportId)) {
                    delete [SELECT Id FROM Installation_Report_Printer_Parameter__c WHERE Installation_Report__c = :installationReportId];
                }
                
                // Insert new parameters
                insert parameters;
            }
        } catch (Exception e) {
            System.debug('Error saving installation parameters: ' + e.getMessage() + ' - ' + e.getStackTraceString());
            throw new AuraHandledException('Error saving installation parameters: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static List<Map<String, Object>> getServiceReportParameters(String serviceReportId) {
        try {
            List<Service_Report_Printer_Parameter__c> existingParams = [
                SELECT Id, Name, Selection_Options_List__c, Selected_Type__c, 
                       Selection_Value__c, Display_Order__c
                FROM Service_Report_Printer_Parameter__c 
                WHERE Service_Report__c = :serviceReportId
                ORDER BY Display_Order__c NULLS LAST, CreatedDate
            ];

            List<Map<String, Object>> wrappedParams = new List<Map<String, Object>>();
            
            if (!existingParams.isEmpty()) {
                for (Service_Report_Printer_Parameter__c param : existingParams) {
                    Map<String, Object> paramMap = new Map<String, Object>();
                    paramMap.put('key', param.Id);
                    paramMap.put('parameterName', param.Name);
                    paramMap.put('selectedType', param.Selected_Type__c);
                    paramMap.put('selectionValue', param.Selection_Value__c);
                    paramMap.put('dynamicOptions', parseOptionsToMap(param.Selection_Options_List__c));
                    
                    wrappedParams.add(paramMap);
                }
            } else {
                // Return default parameters if none exist
                wrappedParams = getDefaultParametersAsMap();
            }
            
            return wrappedParams;
            
        } catch (Exception e) {
            System.debug('Error loading parameters: ' + e.getMessage() + ' - ' + e.getStackTraceString());
            throw new AuraHandledException('Error loading parameters: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static List<Map<String, Object>> getInstallationReportParameters(String installationReportId) {
        try {
            List<Installation_Report_Printer_Parameter__c> existingParams = [
                SELECT Id, Name, Selection_Options_List__c, Selected_Type__c, 
                       Selection_Value__c, Display_Order__c
                FROM Installation_Report_Printer_Parameter__c 
                WHERE Installation_Report__c = :installationReportId
                ORDER BY Display_Order__c NULLS LAST, CreatedDate
            ];

            List<Map<String, Object>> wrappedParams = new List<Map<String, Object>>();
            
            if (!existingParams.isEmpty()) {
                for (Installation_Report_Printer_Parameter__c param : existingParams) {
                    Map<String, Object> paramMap = new Map<String, Object>();
                    paramMap.put('key', param.Id);
                    paramMap.put('parameterName', param.Name);
                    paramMap.put('selectedType', param.Selected_Type__c);
                    paramMap.put('selectionValue', param.Selection_Value__c);
                    paramMap.put('dynamicOptions', parseOptionsToMap(param.Selection_Options_List__c));
                    
                    wrappedParams.add(paramMap);
                }
            } else {
                // Return default parameters if none exist (same as service report for TIJ)
                wrappedParams = getDefaultParametersAsMap();
            }
            
            return wrappedParams;
            
        } catch (Exception e) {
            System.debug('Error loading installation parameters: ' + e.getMessage() + ' - ' + e.getStackTraceString());
            throw new AuraHandledException('Error loading installation parameters: ' + e.getMessage());
        }
    }

    // Helper method to parse options from string to Map format
    private static List<Map<String, String>> parseOptionsToMap(String optionsString) {
        List<Map<String, String>> options = new List<Map<String, String>>();
        if (String.isNotBlank(optionsString)) {
            List<String> optionList = optionsString.split(';');
            for (String opt : optionList) {
                if (String.isNotBlank(opt)) {
                    Map<String, String> optionMap = new Map<String, String>{
                        'label' => opt.trim(),
                        'value' => opt.trim()
                    };
                    options.add(optionMap);
                }
            }
        }
        return options;
    }

    // Default parameters setup as Map
    private static List<Map<String, Object>> getDefaultParametersAsMap() {
        List<Map<String, Object>> defaultParams = new List<Map<String, Object>>();
        
        List<Map<String, Object>> parameterConfigs = new List<Map<String, Object>>{
            new Map<String, Object>{
                'key' => '1',
                'parameterName' => 'Print head Firing Voltage',
                'selectedType' => 'Auto',
                'selectionValue' => '',
                'dynamicOptions' => new List<Map<String, String>>{
                    new Map<String, String>{'label' => 'Auto', 'value' => 'Auto'},
                    new Map<String, String>{'label' => 'Manual', 'value' => 'Manual'}
                }
            },
            new Map<String, Object>{
                'key' => '2',
                'parameterName' => 'Pulse Value',
                'selectedType' => 'N/A',
                'selectionValue' => '',
                'dynamicOptions' => new List<Map<String, String>>{
                    new Map<String, String>{'label' => 'N/A', 'value' => 'N/A'}
                }
            },
            new Map<String, Object>{
                'key' => '3',
                'parameterName' => 'Auto jet setting',
                'selectedType' => 'Auto',
                'selectionValue' => '',
                'dynamicOptions' => new List<Map<String, String>>{
                    new Map<String, String>{'label' => 'Auto', 'value' => 'Auto'},
                    new Map<String, String>{'label' => 'Manual', 'value' => 'Manual'}
                }
            },
            new Map<String, Object>{
                'key' => '4',
                'parameterName' => 'Nozzle Select',
                'selectedType' => 'Splice',
                'selectionValue' => '1',
                'dynamicOptions' => new List<Map<String, String>>{
                    new Map<String, String>{'label' => 'Splice', 'value' => 'Splice'},
                    new Map<String, String>{'label' => 'Head', 'value' => 'Head'}
                }
            },
            new Map<String, Object>{
                'key' => '5',
                'parameterName' => 'Purging auto jet',
                'selectedType' => 'Auto',
                'selectionValue' => '',
                'dynamicOptions' => new List<Map<String, String>>{
                    new Map<String, String>{'label' => 'Auto', 'value' => 'Auto'},
                    new Map<String, String>{'label' => 'Manual', 'value' => 'Manual'}
                }
            },
            new Map<String, Object>{
                'key' => '6',
                'parameterName' => 'DPI X',
                'selectedType' => 'N/A',
                'selectionValue' => '',
                'dynamicOptions' => new List<Map<String, String>>{
                    new Map<String, String>{'label' => 'N/A', 'value' => 'N/A'}
                }
            },
            new Map<String, Object>{
                'key' => '7',
                'parameterName' => 'DPI Y',
                'selectedType' => 'N/A',
                'selectionValue' => '',
                'dynamicOptions' => new List<Map<String, String>>{
                    new Map<String, String>{'label' => 'N/A', 'value' => 'N/A'}
                }
            },
            new Map<String, Object>{
                'key' => '8',
                'parameterName' => 'Printhead Delay',
                'selectedType' => 'N/A',
                'selectionValue' => '',
                'dynamicOptions' => new List<Map<String, String>>{
                    new Map<String, String>{'label' => 'N/A', 'value' => 'N/A'}
                }
            },
            new Map<String, Object>{
                'key' => '9',
                'parameterName' => 'Trigger Mode',
                'selectedType' => 'External',
                'selectionValue' => 'External',
                'dynamicOptions' => new List<Map<String, String>>{
                    new Map<String, String>{'label' => 'External', 'value' => 'External'},
                    new Map<String, String>{'label' => 'Internal', 'value' => 'Internal'}
                }
            },
            new Map<String, Object>{
                'key' => '10',
                'parameterName' => 'Continuous print',
                'selectedType' => 'Close',
                'selectionValue' => '',
                'dynamicOptions' => new List<Map<String, String>>{
                    new Map<String, String>{'label' => 'Close', 'value' => 'Close'},
                    new Map<String, String>{'label' => 'Times', 'value' => 'Times'}
                }
            },
            new Map<String, Object>{
                'key' => '11',
                'parameterName' => 'Photocell setting',
                'selectedType' => 'Beep',
                'selectionValue' => 'Beep',
                'dynamicOptions' => new List<Map<String, String>>{
                    new Map<String, String>{'label' => 'Beep', 'value' => 'Beep'},
                    new Map<String, String>{'label' => 'Signal shielding', 'value' => 'Signal shielding'}
                }
            },
            new Map<String, Object>{
                'key' => '12',
                'parameterName' => 'Encoder setting',
                'selectedType' => 'Yes',
                'selectionValue' => '',
                'dynamicOptions' => new List<Map<String, String>>{
                    new Map<String, String>{'label' => 'Yes', 'value' => 'Yes'},
                    new Map<String, String>{'label' => 'No', 'value' => 'No'}
                }
            }
        };

        return parameterConfigs;
    }

    // IMAGE HANDLING METHODS
    @AuraEnabled
    public static String uploadDiagnosticImage(String recordId, String fileName, String base64Data, String contentType, String imageType) {
        try {
            // Check if record exists
            Installation_Report__c report = [SELECT Id FROM Installation_Report__c WHERE Id = :recordId LIMIT 1];
            
            // Decode base64 data and validate image size (max 300KB)
            Blob imageBlob = EncodingUtil.base64Decode(base64Data);
            Integer maxSizeBytes = 300 * 1024; // 300KB in bytes
            
            if (imageBlob.size() > maxSizeBytes) {
                throw new AuraHandledException('Image size exceeds the maximum allowed size of 300KB. Current size: ' + 
                    String.valueOf(Math.round(imageBlob.size() / 1024.0)) + 'KB');
            }
            
            // Add image type to filename for identification
            String finalFileName = imageType + '_' + System.now().getTime() + '_' + fileName;
            
            // Create ContentVersion
            ContentVersion contentVersion = new ContentVersion();
            contentVersion.Title = finalFileName;
            contentVersion.PathOnClient = finalFileName;
            contentVersion.VersionData = imageBlob;
            contentVersion.FirstPublishLocationId = recordId;
            contentVersion.IsMajorVersion = true;
            insert contentVersion;
            
            // Get the ContentDocumentId
            contentVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id];
            
            return contentVersion.ContentDocumentId;
        } catch (Exception e) {
            throw new AuraHandledException('Error uploading image: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static List<Map<String, String>> getDiagnosticImages(String recordId, String imageType) {
        try {
            List<Map<String, String>> images = new List<Map<String, String>>();
            
            // Build dynamic query based on image type
            String query = 'SELECT ContentDocumentId, ContentDocument.Title, ContentDocument.LatestPublishedVersionId ' +
                          'FROM ContentDocumentLink ' +
                          'WHERE LinkedEntityId = :recordId ' +
                          'AND ContentDocument.FileType IN (\'JPG\', \'JPEG\', \'PNG\', \'GIF\', \'BMP\') ';
            
            // Filter by image type prefix in filename
            if (imageType == 'diagnostic') {
                query += 'AND ContentDocument.Title LIKE \'diagnostic_%\' ';
            } else if (imageType == 'modulation') {
                query += 'AND ContentDocument.Title LIKE \'modulation_%\' ';
            } else if (imageType == 'ribbon') {
                query += 'AND ContentDocument.Title LIKE \'ribbon_%\' ';
            } else if (imageType == 'earthing') {
                query += 'AND ContentDocument.Title LIKE \'earthing_%\' ';
            } else if (imageType == 'message') {
                query += 'AND ContentDocument.Title LIKE \'message_%\' ';
            } else if (imageType == 'printheadstand') {
                query += 'AND ContentDocument.Title LIKE \'printheadstand_%\' ';
            } else if (imageType == 'printerstand') {
                query += 'AND ContentDocument.Title LIKE \'printerstand_%\' ';
            } else if (imageType == 'toolbox') {
                query += 'AND ContentDocument.Title LIKE \'toolbox_%\' ';
            } else if (imageType == 'printermanual') {
                query += 'AND ContentDocument.Title LIKE \'printermanual_%\' ';
            } else if (imageType == 'sensor') {
                query += 'AND ContentDocument.Title LIKE \'sensor_%\' ';
            } else if (imageType == 'printheaddirection') {
                query += 'AND ContentDocument.Title LIKE \'printheaddirection_%\' ';
            } else if (imageType == 'printingmessage') {
                query += 'AND ContentDocument.Title LIKE \'printingmessage_%\' ';
            } else if (imageType == 'packingchecklist') {
                query += 'AND ContentDocument.Title LIKE \'packingchecklist_%\' ';
            } else if (imageType == 'printheadposition') {
                query += 'AND ContentDocument.Title LIKE \'printheadposition_%\' ';
            } else if (imageType == 'bomchecklist') {
                query += 'AND ContentDocument.Title LIKE \'bomchecklist_%\' ';
            } else if (imageType == 'sensortto') {
                query += 'AND ContentDocument.Title LIKE \'sensortto_%\' ';
            } else if (imageType == 'encodertto') {
                query += 'AND ContentDocument.Title LIKE \'encodertto_%\' ';
            } else if (imageType == 'gapbetweenprints') {
                query += 'AND ContentDocument.Title LIKE \'gapbetweenprints_%\' ';
            } else if (imageType == 'industrytype') {
                query += 'AND ContentDocument.Title LIKE \'industrytype_%\' ';
            }
            
            query += 'ORDER BY ContentDocument.CreatedDate DESC';
            
            List<ContentDocumentLink> links = Database.query(query);
            
            for (ContentDocumentLink link : links) {
                Map<String, String> imageInfo = new Map<String, String>();
                imageInfo.put('contentDocumentId', link.ContentDocumentId);
                imageInfo.put('title', link.ContentDocument.Title);
                imageInfo.put('contentVersionId', link.ContentDocument.LatestPublishedVersionId);
                images.add(imageInfo);
            }
            
            return images;
        } catch (Exception e) {
            throw new AuraHandledException('Error loading images: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static Boolean deleteDiagnosticImage(String contentDocumentId) {
        try {
            ContentDocument document = [SELECT Id FROM ContentDocument WHERE Id = :contentDocumentId];
            delete document;
            return true;
        } catch (Exception e) {
            throw new AuraHandledException('Error deleting image: ' + e.getMessage());
        }
    }

    // Persist only the customer signature and signer details for an existing
    // Installation_Report__c. This is used by the printer installation LWC
    // when the user clicks "Capture Signature", and does not affect any
    // non‑printer installation flows.
    @AuraEnabled
    public static Installation_Report__c saveInstallationSignature(Installation_Report__c installationReportRecord) {
        try {
            if (installationReportRecord == null || installationReportRecord.Id == null) {
                throw new AuraHandledException('Installation Report Id is required to save signature.');
            }

            Installation_Report__c ir = [
                SELECT Id,
                       Signature__c,
                       Signature_by__c,
                       Customer_Email__c,
                       Customer_Contact_Number__c,
                       Customer_Designation__c
                FROM Installation_Report__c
                WHERE Id = :installationReportRecord.Id
                LIMIT 1
            ];

            ir.Signature__c            = installationReportRecord.Signature__c;
            ir.Signature_by__c         = installationReportRecord.Signature_by__c;
            ir.Customer_Email__c       = installationReportRecord.Customer_Email__c;
            ir.Customer_Contact_Number__c = installationReportRecord.Customer_Contact_Number__c;
            ir.Customer_Designation__c = installationReportRecord.Customer_Designation__c;

            update ir;
            return ir;
        } catch (Exception e) {
            throw new AuraHandledException('Error saving installation signature: ' + e.getMessage());
        }
    }

    // REPORT SAVE AND PREVIEW METHODS
    @AuraEnabled
    public static Object saveReport(Installation_Report__c installationReportRecord, Service_Report__c serviceReportRecord, String reportType, List<Service_Report_Observation__c> serviceReportObservations, List<Work_Order_Checklist__c> workOrderChecklist, Id serviceAppointmentId, String currentReportParameters) {
        try {
            Map<string,Object> result = new Map<string,Object>();
            if(reportType == 'InstallationReport') {
                installationReportRecord.IsSavedByUser__c = true;
                upsert installationReportRecord;
                
                Installation_Report__c irFromDB = [SELECT Id, Name, Case__c, Case__r.AssetId, Case__r.Asset.Name, 
                                                    Case__r.Asset.SerialNumber, Case__r.Asset.Is_Temp_Serial_Number__c,
                                                    Case__r.Asset.Software_Number__c, Software_No__c
                                                    FROM Installation_Report__c
                                                    WHERE Id = :installationReportRecord.Id];

                Asset assetToUpdate = new Asset();
                assetToUpdate.Id = irFromDB.Case__r.AssetId;
                
                // Update Software_Number__c on Asset from Software_No__c in Installation Report
                if (installationReportRecord.Software_No__c != null) {
                    assetToUpdate.Software_Number__c = installationReportRecord.Software_No__c;
                }

                if(irFromDB.Case__r.Asset.Is_Temp_Serial_Number__c) {
                    update installationReportRecord;

                    assetToUpdate.Name = installationReportRecord.Installation_Asset_Serial_Number__c;
                    assetToUpdate.SerialNumber = installationReportRecord.Installation_Asset_Serial_Number__c;
                    assetToUpdate.Is_Temp_Serial_Number__c = false;
                    assetToUpdate.InstallDate = installationReportRecord.Installation_End_Date__c;
                    Database.update(assetToUpdate, true, AccessLevel.SYSTEM_MODE);

                } else {
                    assetToUpdate.InstallDate = installationReportRecord.Installation_End_Date__c;
                    Database.update(assetToUpdate, true, AccessLevel.SYSTEM_MODE);

                    update installationReportRecord;
                }

                installationReportRecord = [SELECT Id, Name, Work_Order__c
                                            FROM Installation_Report__c
                                            WHERE Id = :installationReportRecord.Id];

                // Parse and save parameters if provided
                if (String.isNotBlank(currentReportParameters) && installationReportRecord.Id != null) {
                    try {
                        List<Installation_Report_Printer_Parameter__c> parametersToSave = parseAndConvertInstallationParameters(currentReportParameters, installationReportRecord.Id);
                        if (parametersToSave != null && !parametersToSave.isEmpty()) {
                            // Delete existing parameters for this installation report
                            delete [SELECT Id FROM Installation_Report_Printer_Parameter__c WHERE Installation_Report__c = :installationReportRecord.Id];
                            System.debug('parametersToSave: ' + parametersToSave);
                            // Insert new parameters
                            insert parametersToSave;
                        }
                    } catch (Exception e) {
                        System.debug(LoggingLevel.ERROR, 'Error saving installation parameters: ' + e.getMessage());
                        System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
                        // Don't throw exception - parameters save failure shouldn't fail the entire save
                    }
                }

                // Use printer-specific installation PDF page
                string t1 = createFinalDocument(installationReportRecord, Page.InstallationReportPrinterPDF, 'Installation_Report_' + installationReportRecord.Name + '.pdf');
               result.put('Id',t1);
                return JSON.serialize(result);
            }
            else if(reportType == 'ServiceReport') {
                serviceReportRecord.IsSavedByUser__c = true;
                upsert serviceReportRecord;

                Service_Report__c srFromDB = [SELECT Id, Name, Signature__c, Signature_by__c,Case__c, 
                                            Case__r.AssetId, Case__r.Asset.OEM_Serial_Number__c,
                                            Case__r.Asset.Software_Number__c, Software_No__c
                                            FROM Service_Report__c
                                            WHERE Id = :serviceReportRecord.Id];

                Asset assetToUpdate = new Asset();
                assetToUpdate.Id = srFromDB.Case__r.AssetId;
                Boolean needsAssetUpdate = false;

                // Update OEM_Serial_Number__c on Asset if changed
                if(serviceReportRecord.OEM_Serial_Number__c != null &&
                serviceReportRecord.OEM_Serial_Number__c != srFromDB.Case__r.Asset.OEM_Serial_Number__c) {
                    assetToUpdate.OEM_Serial_Number__c = serviceReportRecord.OEM_Serial_Number__c;
                    needsAssetUpdate = true;
                }

                // Update Software_Number__c on Asset from Software_No__c in Service Report if changed
                if (serviceReportRecord.Software_No__c != null &&
                    serviceReportRecord.Software_No__c != srFromDB.Case__r.Asset.Software_Number__c) {
                    assetToUpdate.Software_Number__c = serviceReportRecord.Software_No__c;
                    needsAssetUpdate = true;
                }

                if (needsAssetUpdate) {
                    Database.update(assetToUpdate, true, AccessLevel.SYSTEM_MODE);
                }

                update serviceReportRecord;
                serviceReportRecord = [SELECT Id, Name, OEM_Serial_Number__c, Work_Order__c
                                        FROM Service_Report__c
                                        WHERE Id = :serviceReportRecord.Id];

                for(Service_Report_Observation__c sro : serviceReportObservations) {
                    if(sro.Id == null) {
                        sro.Service_Report__c = serviceReportRecord.Id;
                    }
                }
                if(!serviceReportObservations.isEmpty()) {
                    upsert serviceReportObservations;
                }

                if(!result.containsKey('OEM_Serial_Number__c')) {
                    result.put('OEM_Serial_Number__c', srFromDB.Case__r.Asset.OEM_Serial_Number__c);
                }

                string t2 = createFinalDocument(serviceReportRecord, Page.ServiceReportPrinterPDF, 'Service_Report_' + serviceReportRecord.Name + '.pdf');

                result.put('result', serviceReportObservations);
                result.put('Id', t2);
                result.put('OEM_Serial_Number__c', serviceReportRecord.OEM_Serial_Number__c);

                return JSON.serialize(result);
            }

            return null;
        }
        catch (Exception e) {
            system.debug('srvId'+e.getMessage() + e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Object previewReport(Installation_Report__c installationReportRecord, Service_Report__c serviceReportRecord, String reportType) {
        System.debug(LoggingLevel.ERROR, '=== PREVIEW REPORT METHOD START ===');
        System.debug(LoggingLevel.ERROR, 'DEBUG: reportType = ' + reportType);
        System.debug(LoggingLevel.ERROR, 'DEBUG: installationReportRecord = ' + installationReportRecord);
        System.debug(LoggingLevel.ERROR, 'DEBUG: serviceReportRecord = ' + serviceReportRecord);
        
        try {
            if(reportType == 'InstallationReport') {
                System.debug(LoggingLevel.ERROR, 'DEBUG: Processing InstallationReport');
                update installationReportRecord;
                
                installationReportRecord = [SELECT Id, Name, Sr_No_Preview__c, Signature__c
                                            FROM Installation_Report__c
                                            WHERE Id = :installationReportRecord.Id];

                // Validate that signature exists before generating preview
                if (String.isBlank(installationReportRecord.Signature__c)) {
                    throw new AuraHandledException('Customer signature is required before previewing PDF. Please capture the signature first.');
                }

                // Check if a preview document already exists for this Installation Report
                String previewTitlePattern = 'Installation_Report_Preview_' + installationReportRecord.Name + '%';
                List<ContentDocumentLink> existingLinks = [
                    SELECT ContentDocumentId, ContentDocument.Title
                    FROM ContentDocumentLink
                    WHERE LinkedEntityId = :installationReportRecord.Id
                    AND ContentDocument.Title LIKE :previewTitlePattern
                ];
                
                Id contentDocumentId;
                
                if (!existingLinks.isEmpty()) {
                    // Delete existing preview documents to keep only one
                    Set<Id> contentDocumentIds = new Set<Id>();
                    for (ContentDocumentLink link : existingLinks) {
                        contentDocumentIds.add(link.ContentDocumentId);
                    }
                    
                    if (!contentDocumentIds.isEmpty()) {
                        List<ContentDocument> documentsToDelete = [
                            SELECT Id
                            FROM ContentDocument
                            WHERE Id IN :contentDocumentIds
                        ];
                        if (!documentsToDelete.isEmpty()) {
                            delete documentsToDelete;
                        }
                    }
                }
                
                // Create new preview document (always create fresh one after deleting old)
                contentDocumentId = createPreviewDocument(installationReportRecord.Id, Page.InstallationReportPrinterPDF, 'Installation_Report_Preview_' + installationReportRecord.Name + '.pdf');

                return contentDocumentId;
            }
            else if(reportType == 'ServiceReport') {
                System.debug(LoggingLevel.ERROR, 'DEBUG: Processing ServiceReport');
                System.debug(LoggingLevel.ERROR, 'DEBUG: serviceReportRecord.Id = ' + (serviceReportRecord != null ? serviceReportRecord.Id : 'NULL'));
                System.debug(LoggingLevel.ERROR, 'DEBUG: About to update serviceReportRecord');
                
                // Update the record with all fields including Customer_Contact_Number__c, Customer_Email__c, etc.
                try {
                update serviceReportRecord;
                    System.debug(LoggingLevel.ERROR, 'DEBUG: serviceReportRecord updated successfully');
                    System.debug(LoggingLevel.ERROR, 'DEBUG: Updated serviceReportRecord = ' + serviceReportRecord);
                } catch (DmlException dmlEx) {
                    System.debug(LoggingLevel.ERROR, 'ERROR: DML Exception during update: ' + dmlEx.getMessage());
                    System.debug(LoggingLevel.ERROR, 'ERROR: DML Exception Type: ' + dmlEx.getTypeName());
                    System.debug(LoggingLevel.ERROR, 'ERROR: DML Exception Fields: ' + dmlEx.getDmlFieldNames(0));
                    throw dmlEx;
                }

                // Re-query to get the updated record for PDF generation
                System.debug(LoggingLevel.ERROR, 'DEBUG: About to re-query serviceReportRecord');
                try {
                    serviceReportRecord = [SELECT Id, Name, Sr_No_Preview__c, Signature__c, Customer_Contact_Number__c, Customer_Email__c, Customer_Designation__c
                                        FROM Service_Report__c
                                        WHERE Id = :serviceReportRecord.Id];
                    System.debug(LoggingLevel.ERROR, 'DEBUG: Re-query successful. serviceReportRecord.Id = ' + serviceReportRecord.Id);
                    System.debug(LoggingLevel.ERROR, 'DEBUG: Signature__c is blank? ' + String.isBlank(serviceReportRecord.Signature__c));
                } catch (Exception queryEx) {
                    System.debug(LoggingLevel.ERROR, 'ERROR: Exception during re-query: ' + queryEx.getMessage());
                    System.debug(LoggingLevel.ERROR, 'ERROR: Stack Trace: ' + queryEx.getStackTraceString());
                    throw queryEx;
                }
                
                // Validate that signature exists before generating preview
                if (String.isBlank(serviceReportRecord.Signature__c)) {
                    System.debug(LoggingLevel.ERROR, 'ERROR: Signature is blank - throwing exception');
                    throw new AuraHandledException('Customer signature is required before previewing PDF. Please capture the signature first.');
                }
                System.debug(LoggingLevel.ERROR, 'DEBUG: Signature validation passed');

                // Check if a preview document already exists for this Service Report
                String previewTitlePattern = 'Service_Report_Preview_' + serviceReportRecord.Name + '%';
                List<ContentDocumentLink> existingLinks = [
                    SELECT ContentDocumentId, ContentDocument.Title
                    FROM ContentDocumentLink
                    WHERE LinkedEntityId = :serviceReportRecord.Id
                    AND ContentDocument.Title LIKE :previewTitlePattern
                ];
                
                Id contentDocumentId;
                
                if (!existingLinks.isEmpty()) {
                    // Delete existing preview documents to keep only one
                    Set<Id> contentDocumentIds = new Set<Id>();
                    for (ContentDocumentLink link : existingLinks) {
                        contentDocumentIds.add(link.ContentDocumentId);
                    }
                    
                    if (!contentDocumentIds.isEmpty()) {
                        List<ContentDocument> documentsToDelete = [
                            SELECT Id
                            FROM ContentDocument
                            WHERE Id IN :contentDocumentIds
                        ];
                        if (!documentsToDelete.isEmpty()) {
                            delete documentsToDelete;
                        }
                    }
                }
                
                // Create new preview document (always create fresh one after deleting old)
                System.debug(LoggingLevel.ERROR, 'DEBUG: About to call createPreviewDocument');
                System.debug(LoggingLevel.ERROR, 'DEBUG: serviceReportRecord.Id = ' + serviceReportRecord.Id);
                System.debug(LoggingLevel.ERROR, 'DEBUG: serviceReportRecord.Name = ' + serviceReportRecord.Name);
                
                try {
                    contentDocumentId = createPreviewDocument(serviceReportRecord.Id, Page.ServiceReportPrinterPDF, 'Service_Report_Preview_' + serviceReportRecord.Name + '.pdf');
                    System.debug(LoggingLevel.ERROR, 'DEBUG: createPreviewDocument returned: ' + contentDocumentId);
                } catch (Exception createEx) {
                    System.debug(LoggingLevel.ERROR, 'ERROR: Exception in createPreviewDocument: ' + createEx.getMessage());
                    System.debug(LoggingLevel.ERROR, 'ERROR: Stack Trace: ' + createEx.getStackTraceString());
                    throw createEx;
                }

                System.debug(LoggingLevel.ERROR, 'DEBUG: Returning contentDocumentId: ' + contentDocumentId);
                return contentDocumentId;
            }

            return null;
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Object getDocumentId(String recordId, String reportType) {
        try {
            if(reportType == 'InstallationReport') {
                Installation_Report__c installationReportRecord = [SELECT Id, Name
                                                                FROM Installation_Report__c
                                                                WHERE Id = :recordId];
                // Use printer-specific installation PDF page
                return createFinalDocument(installationReportRecord, Page.InstallationReportPrinterPDF, 'Installation_Report_' + installationReportRecord.Name + '.pdf');
            }
            else if(reportType == 'ServiceReport') {
                Service_Report__c serviceReportRecord = [SELECT Id, Name
                                                        FROM Service_Report__c
                                                        WHERE Id = :recordId];
                return createFinalDocument(serviceReportRecord, Page.ServiceReportPrinterPDF, 'Service_Report_' + serviceReportRecord.Name + '.pdf');
            }
            return null;
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string deleteRecord(Id recordId) {
        system.debug(recordId);
        try {
            List<Service_Report_Observation__c> relatedObservations = [SELECT Id FROM Service_Report_Observation__c WHERE Id = :recordId limit 1];
            if(relatedObservations.size() > 0){
                delete relatedObservations;
            }
            return 'Success';
        }catch(exception e){
            return e.getMessage();
        }
    }

    // PRIVATE HELPER METHODS
    private static Id createFinalDocument(sObject record, PageReference pageRef, String title) {
        try {
            pageRef.getParameters().put('id', record.Id);

            try {
                delete [SELECT Id
                        FROM contentDocument
                        WHERE Title = :title
                        LIMIT 1];
            }
            catch(Exception e) {
                System.debug(e.getMessage());
            }

            ContentVersion contentVersion = new ContentVersion();
            contentVersion.ContentLocation = 'S';
            contentVersion.PathOnClient = title;
            contentVersion.isMajorVersion = true;
            contentVersion.Title = title;
            if(Test.isRunningTest()) {
                contentVersion.VersionData = Blob.valueOf('test');
            } else {
                contentVersion.VersionData = pageRef.getContentAsPDF();
            }
            insert contentVersion;

            ContentVersion = [SELECT Id, ContentDocumentId, Title, PathOnClient
                            FROM ContentVersion
                            WHERE Id = :contentVersion.Id];

            ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
            contentDocumentLink.ContentDocumentId = contentVersion.ContentDocumentId;
            contentDocumentLink.LinkedEntityId = record.Id;
            contentDocumentLink.ShareType = 'V';
            contentDocumentLink.Visibility = 'AllUsers';
            insert contentDocumentLink;

            return contentVersion.ContentDocumentId;
        }
        catch (Exception e) {
            system.debug('createFinalDocument'+e.getMessage() + e.getLineNumber());
            throw new CustomException(e.getMessage());
        }
    }

    private static Id createPreviewDocument(String recordId, PageReference pageRef, String title) {
        System.debug(LoggingLevel.ERROR, '=== CREATE PREVIEW DOCUMENT START ===');
        System.debug(LoggingLevel.ERROR, 'DEBUG: recordId = ' + recordId);
        System.debug(LoggingLevel.ERROR, 'DEBUG: title = ' + title);
        System.debug(LoggingLevel.ERROR, 'DEBUG: pageRef = ' + pageRef);
        
        try {
            System.debug(LoggingLevel.ERROR, 'DEBUG: Setting page parameters');
            pageRef.getParameters().put('id', recordId);
            pageRef.getParameters().put('isPreview',  'true');
            System.debug(LoggingLevel.ERROR, 'DEBUG: Page parameters set. id=' + recordId + ', isPreview=true');

            System.debug(LoggingLevel.ERROR, 'DEBUG: Creating ContentVersion');
            ContentVersion contentVersion = new ContentVersion();
            contentVersion.ContentLocation = 'S';
            contentVersion.PathOnClient = title;
            contentVersion.Title = title;
            
            if(Test.isRunningTest()) {
                System.debug(LoggingLevel.ERROR, 'DEBUG: Test mode - using test blob');
                contentVersion.VersionData = Blob.valueOf('test');
            } else {
                System.debug(LoggingLevel.ERROR, 'DEBUG: About to call pageRef.getContentAsPDF()');
                try {
                contentVersion.VersionData = pageRef.getContentAsPDF();
                    System.debug(LoggingLevel.ERROR, 'DEBUG: getContentAsPDF() completed. Blob size: ' + (contentVersion.VersionData != null ? String.valueOf(contentVersion.VersionData.size()) : 'NULL'));
                } catch (Exception pdfEx) {
                    System.debug(LoggingLevel.ERROR, 'ERROR: Exception during getContentAsPDF(): ' + pdfEx.getMessage());
                    System.debug(LoggingLevel.ERROR, 'ERROR: Stack Trace: ' + pdfEx.getStackTraceString());
                    throw pdfEx;
            }
            }
            
            System.debug(LoggingLevel.ERROR, 'DEBUG: About to insert ContentVersion');
            try {
            insert contentVersion;
                System.debug(LoggingLevel.ERROR, 'DEBUG: ContentVersion inserted. Id = ' + contentVersion.Id);
            } catch (DmlException dmlEx) {
                System.debug(LoggingLevel.ERROR, 'ERROR: DML Exception during ContentVersion insert: ' + dmlEx.getMessage());
                System.debug(LoggingLevel.ERROR, 'ERROR: DML Exception Fields: ' + dmlEx.getDmlFieldNames(0));
                throw dmlEx;
            }

            System.debug(LoggingLevel.ERROR, 'DEBUG: About to query ContentVersion');
            ContentVersion contentVersionQuery = [SELECT Id, ContentDocumentId, Title, PathOnClient
                            FROM ContentVersion
                            WHERE Id = :contentVersion.Id];
            System.debug(LoggingLevel.ERROR, 'DEBUG: ContentVersion queried. ContentDocumentId = ' + contentVersionQuery.ContentDocumentId);

            System.debug(LoggingLevel.ERROR, 'DEBUG: Creating ContentDocumentLink');
            ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
            contentDocumentLink.ContentDocumentId = contentVersionQuery.ContentDocumentId;
            contentDocumentLink.LinkedEntityId = recordId;
            contentDocumentLink.ShareType = 'V';
            
            System.debug(LoggingLevel.ERROR, 'DEBUG: About to insert ContentDocumentLink');
            try {
            insert contentDocumentLink;
                System.debug(LoggingLevel.ERROR, 'DEBUG: ContentDocumentLink inserted successfully');
            } catch (DmlException dmlEx) {
                System.debug(LoggingLevel.ERROR, 'ERROR: DML Exception during ContentDocumentLink insert: ' + dmlEx.getMessage());
                System.debug(LoggingLevel.ERROR, 'ERROR: DML Exception Fields: ' + dmlEx.getDmlFieldNames(0));
                throw dmlEx;
            }

            System.debug(LoggingLevel.ERROR, 'DEBUG: Returning ContentDocumentId: ' + contentVersionQuery.ContentDocumentId);
            return contentVersionQuery.ContentDocumentId;
        }
        catch (Exception e) {
            System.debug(LoggingLevel.ERROR, '=== CREATE PREVIEW DOCUMENT: EXCEPTION CAUGHT ===');
            System.debug(LoggingLevel.ERROR, 'ERROR: Exception Type: ' + e.getTypeName());
            System.debug(LoggingLevel.ERROR, 'ERROR: Exception Message: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'ERROR: Exception Cause: ' + e.getCause());
            System.debug(LoggingLevel.ERROR, 'ERROR: Stack Trace: ' + e.getStackTraceString());
            System.debug(LoggingLevel.ERROR, 'ERROR: Line Number: ' + e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getConsumablePartsByMG5(String mg5Value) {
        try {
            if (String.isBlank(mg5Value)) {
                return new List<Map<String, String>>();
            }

            // Normalize MG5 value for case-insensitive comparison
            // Handle both "P01" and "p01" formats
            String mg5Upper = mg5Value.toUpperCase();

            // SOQL doesn't support UPPER() in WHERE clause, so we query all and filter in Apex
            // Alternatively, we can query with case-insensitive comparison using the normalized value
            // Since MG5__c might have mixed case, we'll fetch records and filter in Apex
            List<Consumable_Parts__c> allParts = [
                SELECT Id, Material__c, MG5__c
                FROM Consumable_Parts__c
                WHERE MG5__c != null
                ORDER BY Material__c
            ];

            List<Map<String, String>> options = new List<Map<String, String>>();
            Set<String> uniqueMaterials = new Set<String>(); // Prevent duplicates
            
            // Filter by case-insensitive MG5 match
            for (Consumable_Parts__c part : allParts) {
                if (String.isNotBlank(part.MG5__c) && 
                    part.MG5__c.toUpperCase() == mg5Upper &&
                    String.isNotBlank(part.Material__c) && 
                    !uniqueMaterials.contains(part.Material__c)) {
                    uniqueMaterials.add(part.Material__c);
                    options.add(new Map<String, String>{
                        'label' => part.Material__c,
                        'value' => part.Material__c
                    });
                }
            }

            return options;
        } catch (Exception e) {
            System.debug('Error fetching consumable parts: ' + e.getMessage());
            throw new AuraHandledException('Error fetching consumable parts: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getConsumableParts(String mg5Value, String mg4Value) {
        try {
            if (String.isBlank(mg5Value) || String.isBlank(mg4Value)) {
                return new List<Map<String, String>>();
            }

            // Normalize MG5 value for case-insensitive comparison
            // Handle both "P01" and "p01" formats
            String mg5Upper = mg5Value.toUpperCase();

            // SOQL doesn't support UPPER() in WHERE clause, so we query all and filter in Apex
            // Alternatively, we can query with case-insensitive comparison using the normalized value
            // Since MG5__c might have mixed case, we'll fetch records and filter in Apex
            /*List<Consumable_Parts__c> allParts = [
                SELECT Id, Material__c, MG5__c, MG4__c
                FROM Consumable_Parts__c
                WHERE MG5__c = :mg5Value AND MG4__c = :mg4Value
                ORDER BY Material__c
            ]; */ 

            List<Product2> allParts = [select Id, Name from Product2 
                                                        where Material_Group_5__c = : mg5Value
                                                         and Material_Group_4__c = :mg4Value
                                                         ORDER BY Name];
            

            List<Map<String, String>> options = new List<Map<String, String>>();
            Set<String> uniqueMaterials = new Set<String>(); // Prevent duplicates
            
            // Filter by case-insensitive MG5 match
            for (Product2 part : allParts) {
                if (!uniqueMaterials.contains(part.Name)) {
                    options.add(new Map<String, String>{
                        'label' => part.Name,
                        'value' => part.Name
                    });
                    uniqueMaterials.add(part.Name);
                }
            }

            return options;
        } catch (Exception e) {
            System.debug('Error fetching consumable parts: ' + e.getMessage());
            throw new AuraHandledException('Error fetching consumable parts: ' + e.getMessage());
        }
    }

    /**
     * @description Wrapper class for printer parameter data structure
     *              Used to represent parameter information with parameterName, selectedOption, selectedType, and selectedValue
     */
    public class PrinterParameterWrapper {
        @AuraEnabled public String parameterName { get; set; }
        @AuraEnabled public String selectedOption { get; set; }
        @AuraEnabled public String selectedType { get; set; }
        @AuraEnabled public String selectedValue { get; set; }
        
        /**
         * @description Default constructor
         */
        public PrinterParameterWrapper() {}
        
        /**
         * @description Constructor with all parameters
         * @param parameterName The name of the parameter
         * @param selectedOption The selected option value
         * @param selectedType The selected type value
         * @param selectedValue The selected value
         */
        public PrinterParameterWrapper(String parameterName, String selectedOption, String selectedType, String selectedValue) {
            this.parameterName = parameterName;
            this.selectedOption = selectedOption;
            this.selectedType = selectedType;
            this.selectedValue = selectedValue;
        }
        
        /**
         * @description Convert from Service_Report_Printer_Parameter__c to wrapper
         * @param param The Service_Report_Printer_Parameter__c record
         * @return PrinterParameterWrapper instance
         */
        public  PrinterParameterWrapper fromServiceReportParameter(Service_Report_Printer_Parameter__c param) {
            PrinterParameterWrapper wrapper = new PrinterParameterWrapper();
            wrapper.parameterName = param.Name;
            wrapper.selectedOption = param.Selected_Type__c; // Assuming selectedOption maps to Selected_Type__c
            wrapper.selectedType = param.Selected_Type__c;
            wrapper.selectedValue = param.Selection_Value__c;
            return wrapper;
        }
        
        /**
         * @description Convert from Installation_Report_Printer_Parameter__c to wrapper
         * @param param The Installation_Report_Printer_Parameter__c record
         * @return PrinterParameterWrapper instance
         */
        public  PrinterParameterWrapper fromInstallationReportParameter(Installation_Report_Printer_Parameter__c param) {
            PrinterParameterWrapper wrapper = new PrinterParameterWrapper();
            wrapper.parameterName = param.Name;
            wrapper.selectedOption = param.Selected_Type__c; // Assuming selectedOption maps to Selected_Type__c
            wrapper.selectedType = param.Selected_Type__c;
            wrapper.selectedValue = param.Selection_Value__c;
            return wrapper;
        }
        
        /**
         * @description Convert wrapper to Service_Report_Printer_Parameter__c
         * @param serviceReportId The Service Report Id to link the parameter
         * @return Service_Report_Printer_Parameter__c instance
         */
        public Service_Report_Printer_Parameter__c toServiceReportParameter(String serviceReportId) {
            Service_Report_Printer_Parameter__c param = new Service_Report_Printer_Parameter__c();
            param.Name = this.parameterName;
            param.Selected_Type__c = this.selectedType;
            param.Selection_Value__c = this.selectedValue;
            param.Service_Report__c = serviceReportId;
            return param;
        }
        
        /**
         * @description Convert wrapper to Installation_Report_Printer_Parameter__c
         * @param installationReportId The Installation Report Id to link the parameter
         * @return Installation_Report_Printer_Parameter__c instance
         */
        public Installation_Report_Printer_Parameter__c toInstallationReportParameter(String installationReportId) {
            Installation_Report_Printer_Parameter__c param = new Installation_Report_Printer_Parameter__c();
            param.Name = this.parameterName;
            param.Selected_Type__c = this.selectedType;
            param.Selection_Value__c = this.selectedValue;
            param.Installation_Report__c = installationReportId;
            return param;
        }
    }

    @AuraEnabled(cacheable=true)
    public static Boolean hasSpareRequestRecords(String workOrderId) {
        try {
            List<Work_Order__c> workOrderList = [SELECT Id, Case__c FROM Work_Order__c WHERE Id = :workOrderId];

            if(workOrderList.size() > 0 && workOrderList[0].Case__c != null) {
                List<Spare_Request__c> spareRequests = [SELECT Id FROM Spare_Request__c WHERE Case__c = :workOrderList[0].Case__c];
                return !spareRequests.isEmpty();
            }
            return false;
        } catch (Exception e) {
            System.debug('Error checking spare requests: ' + e.getMessage());
            return false;
        }
    }

    public class CustomException extends Exception {}
}