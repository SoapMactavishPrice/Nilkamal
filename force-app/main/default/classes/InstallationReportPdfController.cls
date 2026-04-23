public with sharing class InstallationReportPdfController {
    public Id recordId { get; set; }
    public Boolean isPreview  { get; set; }
    public Installation_Report__c record { get; set; }
    public Map<String, String> urlParams { get; set; }
    public Map<String, List<Work_Order_Checklist__c>> categorizedChecklists { get; set; }
    public Map<String, List<Object>> balancedChecklists { get; set; }
    public List<List<Work_Order_Checklist__c>> col1 { get; set; }
    public List<List<Work_Order_Checklist__c>> col2 { get; set; }
    public List<Work_Order_Checklist__c> mechanicalCheckpoints { get; set; }
    public List<Work_Order_Checklist__c> operationalCheckpoints { get; set; }
    public List<Work_Order_Checklist__c> batteryCheckpoints { get; set; }
    public List<Work_Order_Checklist__c> electricCheckpoints { get; set; }
    public List<Work_Order_Checklist__c> chargerCheckpoints { get; set; }
    public Service_Resource__c serviceResource { get; set; }
	public Date today { get; set; }
    public List<Installation_Report_Printer_Parameter__c> installationReportParameters {get; set;}
    public List<EarthingImageWrapper> earthingImages { get; set; }
    public List<MessageImageWrapper> messageImages { get; set; }
    public List<PhysicalCheckImageWrapper> diagnosticImages { get; set; }
    public List<PhysicalCheckImageWrapper> modulationImages { get; set; }
    public List<PhysicalCheckImageWrapper> printHeadStandImages { get; set; }
    public List<PhysicalCheckImageWrapper> printerStandImages { get; set; }
    public List<PhysicalCheckImageWrapper> toolBoxImages { get; set; }
    public List<PhysicalCheckImageWrapper> printerManualImages { get; set; }
    public List<PhysicalCheckImageWrapper> sensorImages { get; set; }
    public List<PhysicalCheckImageWrapper> printHeadDirectionImages { get; set; } // TIJ Photo 01
    public List<PhysicalCheckImageWrapper> printingMessageImages { get; set; } // TIJ Photo 2
    public List<PhysicalCheckImageWrapper> packingChecklistImages { get; set; } // TIJ Photo 03
    // TTO Physical Check Images
    public List<PhysicalCheckImageWrapper> printHeadPositionLiftedImages { get; set; } // TTO - when "No"
    public List<PhysicalCheckImageWrapper> bomCheckListImages { get; set; } // TTO - when "Items missing"
    public List<PhysicalCheckImageWrapper> sensorTTOImages { get; set; } // TTO - when "NotOK"
    public List<PhysicalCheckImageWrapper> encoderTTOImages { get; set; } // TTO - when "NOTok"
    public List<PhysicalCheckImageWrapper> gapBetweenPrintsImages { get; set; } // TTO - MESSAGE Gap between prints
    public List<PhysicalCheckImageWrapper> industryTypeImages { get; set; } // TTO - Industry Type
    public List<PhysicalCheckImageWrapper> ribbonImages { get; set; } // TTO - Ribbon Pic with Scale
    
    public class EarthingImageWrapper {
        public String title { get; set; }
        public String imageUrl { get; set; }
        
        public EarthingImageWrapper(String title, String contentVersionId) {
            this.title = title;
            // Use direct ContentVersion download URL
            this.imageUrl = '/sfc/servlet.shepherd/version/download/' + contentVersionId;
        }
    }
    
    public class MessageImageWrapper {
        public String title { get; set; }
        public String imageUrl { get; set; }
        
        public MessageImageWrapper(String title, String contentVersionId) {
            this.title = title;
            // Use direct ContentVersion download URL
            this.imageUrl = '/sfc/servlet.shepherd/version/download/' + contentVersionId;
        }
    }
    
    public class PhysicalCheckImageWrapper {
        public String title { get; set; }
        public String imageUrl { get; set; }
        
        public PhysicalCheckImageWrapper(String title, String contentVersionId) {
            this.title = title;
            // Use direct ContentVersion download URL
            this.imageUrl = '/sfc/servlet.shepherd/version/download/' + contentVersionId;
        }
    }




    public InstallationReportPdfController() {
        recordId = ApexPages.currentPage().getParameters().get('id');
        if(recordId == null) {
            recordId = 'a0HHE000001Jqoj';
        }
        System.debug('recordId'+ recordId);
        urlParams = ApexPages.currentPage().getParameters();
        System.debug('### URL Parameters: ' + urlParams);
        String isPreviewParam = ApexPages.currentPage().getParameters().get('isPreview');
        System.debug('isPreview'+ isPreview);

        today = System.today();

        if (isPreviewParam != null) {
            isPreview = Boolean.valueOf(isPreviewParam);
        } else {
            isPreview = false;
        }

        // Initialize all image arrays to prevent null reference errors
        earthingImages = new List<EarthingImageWrapper>();
        messageImages = new List<MessageImageWrapper>();
        diagnosticImages = new List<PhysicalCheckImageWrapper>();
        modulationImages = new List<PhysicalCheckImageWrapper>();
        printHeadStandImages = new List<PhysicalCheckImageWrapper>();
        printerStandImages = new List<PhysicalCheckImageWrapper>();
        toolBoxImages = new List<PhysicalCheckImageWrapper>();
        printerManualImages = new List<PhysicalCheckImageWrapper>();
        sensorImages = new List<PhysicalCheckImageWrapper>();
        printHeadDirectionImages = new List<PhysicalCheckImageWrapper>();
        printingMessageImages = new List<PhysicalCheckImageWrapper>();
        packingChecklistImages = new List<PhysicalCheckImageWrapper>();
        // TTO Physical Check Images
        printHeadPositionLiftedImages = new List<PhysicalCheckImageWrapper>();
        bomCheckListImages = new List<PhysicalCheckImageWrapper>();
        sensorTTOImages = new List<PhysicalCheckImageWrapper>();
        encoderTTOImages = new List<PhysicalCheckImageWrapper>();
        gapBetweenPrintsImages = new List<PhysicalCheckImageWrapper>();
        industryTypeImages = new List<PhysicalCheckImageWrapper>();
        ribbonImages = new List<PhysicalCheckImageWrapper>();

        if (recordId != null) {
            try {
                System.debug('recordId2'+ recordId);
                // Extended field set to support printer (CIJ) installation PDF layout.
                // Existing generic InstallationReportPDF page will continue to work,
                // it simply ignores the extra fields.
                record = [
                    SELECT
                        Id,
                        Name,
                        // Customer / header + signature
                        Customer_Email__c,
                        Signature_by__c,
                        Customer_Contact_Number__c,
                        Customer_Designation__c,
                        Signature__c,
                        // Case / account header
                        Case__c,
                        Case__r.Account.Name,
                        Case__r.Account.SAP_Customer_code__c,
                        Case__r.Asset.Invoice_Number__c,
                        Case__r.Asset.SerialNumber,
                        Case__r.Contact.Name,
                        Case__r.ContactMobile,
                        Case__r.Division__c,
                        Case__r.CreatedBy.Name,
                        Case__r.CreatedBy.mobilePhone,
                        Case__r.OwnerId,
                        Case__r.Owner.Name,
                        Case__r.Owner.Email,
                        Case__r.Owner.Phone,
                        // Invoice / product master
                        Item_Master__r.Name,
                        Item_Master__r.ProductCode,
                        Case__r.Asset.Invoice__r.Billing_Date__c,
                        Case__r.Asset.Product2.OEM_Material_Code__c,
                        Case__r.Asset.OEM_Serial_Number__c,
                        Case__r.Asset.Product2.Material_Group_5__c,
                        // Core installation
                        Installation_Start_Date__c,
                        Installation_End_Date__c,
                        Work_Order__c,
                        Installation_Asset_Serial_Number__c,
                        // Printer installation specific fields (must match LWC)
                        Party_Code__c,
                        Customer_Name__c,
                        Location__c,
                        Printer_Model__c,
                        Printer_Serial_Number__c,
                        Ink_Part_No__c,
                        Ink_Exp_Date__c,
                        Make_Up_Part_No__c,
                        Make_Up_Exp_Date__c,
                        Software_No__c,
                        Nozzle_Serial_No__c,
                        TIJ_Model_No__c,
                        Number_of_head__c,
                        Used_ink_cartridge__c,
                        Customer_Application__c,
                        // Firmware_Number__c,
                        Cartridge_Exp_Date__c,
                        // Physical check
                        Print_Head_Stand__c,
                        Printer_Stand__c,
                        Tool_Box__c,
                        Printer_Manual__c,
                        Sensor__c,
                        Encoder__c,
                        Sensor_Encoder__c,
                        // TTO Physical Check fields
                        Packing_foam_intact__c,
                        Print_head_position_lifted__c,
                        BOM_Check_list_verified__c,
                        Sensor_Encoder_end_connectors__c,
                        FRL__c,
                        Bracket_received_as_per_CRM_quopte__c,
                        Bracket_received_as_per_CRM_quopte_Text__c,
                        // Input AC / UPS / earthing / equipment status
                        L_N_volt__c,
                        N_G_volt__c,
                        G_L_volt__c,
                        UPS__c,
                        Earthing__c,
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
                        // Customer & production details
                        Industry_Type__c,
                        Substrate_Type__c,
                        Line_Speed_meter_per_Min__c,
                        Line_Speed_mm_per_Sec__c,
                        Customer_Product_Name__c,
                        Shift__c,
                        Work_Load_Hrs_Day__c,
                        Work_Load_Days_Wk__c,
                        // Installation Check fields
                        Intermittent_installation_check__c,
                        Continuous_installation_check__c,
                        // Footer fields
                        Complaint_Status__c,
                        Next_Visit_Proposed_Date__c,
                        Installation_Status__c,
                        M_C_Breakdown__c,
                        M_C_Temporary_Down__c,
                        M_C_Running__c,
                        Service_Rating__c,
                        Repair_Start_Time__c,
                        Repair_End_Time__c,
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
                        Product_Counter__c,
                        Head_In_Time__c,
                        Start_Border_Trim__c,
                        End_Border_Trim__c,
                        Darkness__c,
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
                        // Photocell / technical
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
                        // Machine Set
                        Modulation__c,
                        Charge_Value__c,
                        Running_Pressure__c,
                        Heater_Point__c,
                        Gutter_Mode__c,
                        EHT_Grade__c,
                        EHT_Range_Min__c,
                        EHT_Range_Max__c,
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
                        // Remarks
                        Engineer_Remarks__c,
                        Customer_Remark__c
                    FROM Installation_Report__c
                    WHERE Id = :recordId
                    LIMIT 1
                ];
                System.debug('record.Signature__c ' + record.Signature__c);

                if (record.Signature__c != null) {
                    record.Signature__c = record.Signature__c.replace('<img ', '<img style="width:150px; height:50px;" ');
                }

                // if (record.Case__r != null && record.Case__r.OwnerId != null) {
                    //     List<Service_Resource__c> serviceResources = [SELECT Id, User__c, Signature__c
            //                                                 FROM Service_Resource__c
            //                                                 WHERE User__c = :record.Case__r.OwnerId
            //                                                 LIMIT 1];

                    //     if (!serviceResources.isEmpty()) {
                        //         Service_Resource__c serviceResource = serviceResources[0];
                        //         // You can now use the serviceResource record in your Visualforce page
                        //         System.debug('Service Resource Signature: ' + serviceResource.Signature__c);
                    //     }
                // }

                if (record.Case__r != null && record.Case__r.OwnerId != null) {
                    List<Service_Resource__c> serviceResources = [SELECT Id, User__c, Signature__c, RSM__r.Name, RSM__r.Email, RSM__r.MobilePhone, Coordinator__r.Name, Coordinator__r.Email, Coordinator__r.MobilePhone
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

                // Fetch Installation Report Parameters for TIJ (P03)
                installationReportParameters = [
                    SELECT Id, Name, Selection_Options_List__c, Selected_Type__c, 
                           Selection_Value__c, Display_Order__c
                    FROM Installation_Report_Printer_Parameter__c 
                    WHERE Installation_Report__c = :record.Id
                    ORDER BY Display_Order__c NULLS LAST, CreatedDate
                ];

                // Fetch Earthing Images if Earthing is not OK
                if (record.Earthing__c != null && record.Earthing__c != 'OK') {
                    List<ContentDocumentLink> earthingLinks = [
                        SELECT ContentDocumentId, ContentDocument.LatestPublishedVersionId
                        FROM ContentDocumentLink
                        WHERE LinkedEntityId = :record.Id
                        AND ContentDocument.Title LIKE 'earthing_%'
                        ORDER BY ContentDocument.CreatedDate DESC
                    ];
                    
                    if (!earthingLinks.isEmpty()) {
                        Set<Id> contentVersionIds = new Set<Id>();
                        for (ContentDocumentLink link : earthingLinks) {
                            contentVersionIds.add(link.ContentDocument.LatestPublishedVersionId);
                        }
                        
                        List<ContentVersion> versions = [
                            SELECT Id, Title, VersionData, FileExtension, ContentDocumentId
                            FROM ContentVersion
                            WHERE Id IN :contentVersionIds
                            ORDER BY CreatedDate DESC
                        ];
                        
                        // Store image URLs for PDF display (using servlet to avoid memory issues)
                        earthingImages = new List<EarthingImageWrapper>();
                        for (ContentVersion cv : versions) {
                            if (cv.Id != null) {
                                try {
                                    earthingImages.add(new EarthingImageWrapper(cv.Title, cv.Id));
                                } catch (Exception e) {
                                    System.debug('Error processing earthing image: ' + e.getMessage());
                                }
                            }
                        }
                    } else {
                        earthingImages = new List<EarthingImageWrapper>();
                    }
                } else {
                    earthingImages = new List<EarthingImageWrapper>();
                }

                // Fetch Message Images for CIJ
                if (record.Case__r != null && record.Case__r.Asset != null && 
                    record.Case__r.Asset.Product2 != null && 
                    record.Case__r.Asset.Product2.Material_Group_5__c == 'P01') {
                    List<ContentDocumentLink> messageLinks = [
                        SELECT ContentDocumentId, ContentDocument.LatestPublishedVersionId
                        FROM ContentDocumentLink
                        WHERE LinkedEntityId = :record.Id
                        AND ContentDocument.Title LIKE 'message_%'
                        ORDER BY ContentDocument.CreatedDate DESC
                    ];
                    
                    if (!messageLinks.isEmpty()) {
                        Set<Id> contentVersionIds = new Set<Id>();
                        for (ContentDocumentLink link : messageLinks) {
                            contentVersionIds.add(link.ContentDocument.LatestPublishedVersionId);
                        }
                        
                        List<ContentVersion> versions = [
                            SELECT Id, Title, VersionData, FileExtension, ContentDocumentId
                            FROM ContentVersion
                            WHERE Id IN :contentVersionIds
                            ORDER BY CreatedDate DESC
                        ];
                        
                        // Store image URLs for PDF display (using servlet to avoid memory issues)
                        messageImages = new List<MessageImageWrapper>();
                        for (ContentVersion cv : versions) {
                            if (cv.Id != null) {
                                try {
                                    messageImages.add(new MessageImageWrapper(cv.Title, cv.Id));
                                } catch (Exception e) {
                                    System.debug('Error processing message image: ' + e.getMessage());
                                }
                            }
                        }
                    } else {
                        messageImages = new List<MessageImageWrapper>();
                    }
                } else {
                    messageImages = new List<MessageImageWrapper>();
                }

                // Fetch Diagnostic and Modulation images (always fetch if they exist)
                diagnosticImages = fetchImagesByType(record.Id, 'diagnostic');
                modulationImages = fetchImagesByType(record.Id, 'modulation');

                // Fetch Physical Check Images if values are Not OK
                printHeadStandImages = fetchPhysicalCheckImages(record.Id, 'printheadstand', record.Print_Head_Stand__c);
                printerStandImages = fetchPhysicalCheckImages(record.Id, 'printerstand', record.Printer_Stand__c);
                toolBoxImages = fetchPhysicalCheckImages(record.Id, 'toolbox', record.Tool_Box__c);
                printerManualImages = fetchPhysicalCheckImages(record.Id, 'printermanual', record.Printer_Manual__c);
                sensorImages = fetchPhysicalCheckImages(record.Id, 'sensor', record.Sensor__c);

                // Fetch TIJ Photo Images
                printHeadDirectionImages = fetchImagesByType(record.Id, 'printheaddirection');
                printingMessageImages = fetchImagesByType(record.Id, 'printingmessage');
                packingChecklistImages = fetchImagesByType(record.Id, 'packingchecklist');
                
                // Fetch TTO Physical Check Images
                printHeadPositionLiftedImages = fetchImagesByType(record.Id, 'printheadposition');
                bomCheckListImages = fetchImagesByType(record.Id, 'bomchecklist');
                sensorTTOImages = fetchImagesByType(record.Id, 'sensortto');
                encoderTTOImages = fetchImagesByType(record.Id, 'encodertto');
                gapBetweenPrintsImages = fetchImagesByType(record.Id, 'gapbetweenprints');
                industryTypeImages = fetchImagesByType(record.Id, 'industrytype');
                ribbonImages = fetchImagesByType(record.Id, 'ribbon');

                List<Work_Order_Checklist__c> workOrderChecklists = FieldServiceCaptureInteraction.getChecklistData(record.Work_Order__c);



                system.debug('workOrderChecklists'+workOrderChecklists);


                // mechanicalCheckpoints = new List<Work_Order_Checklist__c>();
                // operationalCheckpoints = new List<Work_Order_Checklist__c>();
                // batteryCheckpoints = new List<Work_Order_Checklist__c>();
                // electricCheckpoints = new List<Work_Order_Checklist__c>();
                // chargerCheckpoints = new List<Work_Order_Checklist__c>();

                // categorizedChecklists = new Map<String, List<Work_Order_Checklist__c>>();

                // for (Work_Order_Checklist__c checklist : workOrderChecklists) {
                    //     String category = checklist.Checklist_Category__c;
                    //     System.debug('Processing Checklist - Name: ' + checklist.Name + ', Category: ' + category);

                    //     if (!categorizedChecklists.containsKey(category)) {
                        //         categorizedChecklists.put(category, new List<Work_Order_Checklist__c>());
                    //     }

                    //     categorizedChecklists.get(category).add(checklist);
                // }

                // System.debug('Final Categorized Checklists: ' + categorizedChecklists);

                //     for (Work_Order_Checklist__c checklist : workOrderChecklists) {
                    //         if (checklist.Checklist_Category__c == 'Mechanical and Hydraulic Check Points') {
                        //             mechanicalCheckpoints.add(checklist);
                    //         } else if (checklist.Checklist_Category__c == 'Operational Check Points') {
                        //             operationalCheckpoints.add(checklist);
                    //         } else if (checklist.Checklist_Category__c == 'Battery Check Points') {
                        //             batteryCheckpoints.add(checklist);
                    //         } else if (checklist.Checklist_Category__c == 'Electric Check Points') {
                        //             electricCheckpoints.add(checklist);
                    //         } else if (checklist.Checklist_Category__c == 'Charger Check Points') {
                        //             chargecategoryListrCheckpoints.add(checklist);
                    //         }
                //     }

                categorizedChecklists = new Map<String, List<Work_Order_Checklist__c>>();
                for (Work_Order_Checklist__c checklist : workOrderChecklists) {
                    String category = checklist.Checklist_Category__c;
                    if (!categorizedChecklists.containsKey(category)) {
                        categorizedChecklists.put(category, new List<Work_Order_Checklist__c>());
                    }
                    categorizedChecklists.get(category).add(checklist);
                }

                balancedChecklists = balanceColumns(categorizedChecklists);

                Map<String, List<List<Work_Order_Checklist__c>>> balancedData = balanceColumns(categorizedChecklists);

                col1 = balancedData.get('col1');
                col2 = balancedData.get('col2');
                // Map<String, List<Object>> balancedData = balanceColumns(categorizedChecklists);
                // col1 = balancedData.get('col1');
                // col2 = balancedData.get('col2');

                System.debug('Column 1: ' + col1);
                System.debug('Column 2: ' + col2);
                System.debug('Balanced Checklists: ' + balancedChecklists);
                System.debug('Balanced Checklists: ' + JSON.serialize(balancedChecklists));

            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Record not found.'));
            }
        }
    }

    public String getSignatureImage() {
        if (record != null && record.Signature__c != null) {
            return 'data:image/png;base64,' + record.Signature__c;
        }
        return '';
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

    // Helper method to fetch Physical Check images
    public List<PhysicalCheckImageWrapper> fetchPhysicalCheckImages(Id recordId, String imageTypePrefix, String fieldValue) {
        List<PhysicalCheckImageWrapper> images = new List<PhysicalCheckImageWrapper>();
        
        // Only fetch if field value is "Not OK" or "NOK"
        if (fieldValue != null && (fieldValue == 'Not OK' || fieldValue == 'NOK')) {
            try {
                String likePattern = imageTypePrefix + '_%';
                List<ContentDocumentLink> links = [
                    SELECT ContentDocumentId, ContentDocument.LatestPublishedVersionId
                    FROM ContentDocumentLink
                    WHERE LinkedEntityId = :recordId
                    AND ContentDocument.Title LIKE :likePattern
                    ORDER BY ContentDocument.CreatedDate DESC
                ];
                
                if (!links.isEmpty()) {
                    Set<Id> contentVersionIds = new Set<Id>();
                    for (ContentDocumentLink link : links) {
                        contentVersionIds.add(link.ContentDocument.LatestPublishedVersionId);
                    }
                    
                    List<ContentVersion> versions = [
                        SELECT Id, Title
                        FROM ContentVersion
                        WHERE Id IN :contentVersionIds
                        ORDER BY CreatedDate DESC
                    ];
                    
                    for (ContentVersion cv : versions) {
                        if (cv.Id != null) {
                            try {
                                images.add(new PhysicalCheckImageWrapper(cv.Title, cv.Id));
                            } catch (Exception e) {
                                System.debug('Error processing ' + imageTypePrefix + ' image: ' + e.getMessage());
                            }
                        }
                    }
                }
            } catch (Exception e) {
                System.debug('Error fetching ' + imageTypePrefix + ' images: ' + e.getMessage());
            }
        }
        
        return images;
    }

    // Helper method to fetch images by type (for diagnostic and modulation - always fetch if they exist)
    public List<PhysicalCheckImageWrapper> fetchImagesByType(Id recordId, String imageTypePrefix) {
        List<PhysicalCheckImageWrapper> images = new List<PhysicalCheckImageWrapper>();
        
        try {
            String likePattern = imageTypePrefix + '_%';
            List<ContentDocumentLink> links = [
                SELECT ContentDocumentId, ContentDocument.LatestPublishedVersionId
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :recordId
                AND ContentDocument.Title LIKE :likePattern
                ORDER BY ContentDocument.CreatedDate DESC
            ];
            
            if (!links.isEmpty()) {
                Set<Id> contentVersionIds = new Set<Id>();
                for (ContentDocumentLink link : links) {
                    contentVersionIds.add(link.ContentDocument.LatestPublishedVersionId);
                }
                
                List<ContentVersion> versions = [
                    SELECT Id, Title
                    FROM ContentVersion
                    WHERE Id IN :contentVersionIds
                    ORDER BY CreatedDate DESC
                ];
                
                for (ContentVersion cv : versions) {
                    if (cv.Id != null) {
                        try {
                            images.add(new PhysicalCheckImageWrapper(cv.Title, cv.Id));
                        } catch (Exception e) {
                            System.debug('Error processing ' + imageTypePrefix + ' image: ' + e.getMessage());
                        }
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error fetching ' + imageTypePrefix + ' images: ' + e.getMessage());
        }
        
        return images;
    }
    }