public without sharing class FieldServicePMChecklistController {

    /**
     * Returns the existing PM Checklist record for the given Service Appointment,
     * or creates a new draft record. Also returns last PM reading data and asset info.
     */
    @AuraEnabled
    public static Map<String, Object> getOrCreatePMChecklist(String serviceAppointmentId, String workOrderId) {
        try {
            // Query Work Order to get Case, Asset, and Material Group info
            Work_Order__c workOrder = [
                SELECT Id, Case__c, Case__r.AssetId,
                       Case__r.Asset.Product2.Material_Group_5__c,
                       Case__r.Asset.Id
                FROM Work_Order__c
                WHERE Id = :workOrderId
                LIMIT 1
            ];

            Id caseId = workOrder.Case__c;
            Id assetId = workOrder.Case__r.AssetId;

            // Check for existing PM Checklist for this Service Appointment
            List<PM_Checklist__c> existing = [
                SELECT Id, Name, Checklist_Data__c, IsSavedByUser__c, Status__c,
                       Service_Appointment__c, Work_Order__c, Case__c, Asset__c
                FROM PM_Checklist__c
                WHERE Service_Appointment__c = :serviceAppointmentId
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];

            PM_Checklist__c pmChecklist;
            if (!existing.isEmpty()) {
                pmChecklist = existing[0];
            } else {
                // Create new draft record
                pmChecklist = new PM_Checklist__c();
                pmChecklist.Service_Appointment__c = serviceAppointmentId;
                pmChecklist.Work_Order__c = workOrderId;
                pmChecklist.Case__c = caseId;
                pmChecklist.Asset__c = assetId;
                pmChecklist.Status__c = 'Draft';
                pmChecklist.IsSavedByUser__c = false;
                insert pmChecklist;

                // Re-query to get the auto-number Name
                pmChecklist = [
                    SELECT Id, Name, Checklist_Data__c, IsSavedByUser__c, Status__c,
                           Service_Appointment__c, Work_Order__c, Case__c, Asset__c
                    FROM PM_Checklist__c
                    WHERE Id = :pmChecklist.Id
                ];
            }

            // Get last PM reading data
            Map<String, Object> lastPMData = getLastPMReadingInternal(assetId, pmChecklist.Id);

            // Get Ink Type from most recent saved Installation Report for VMS matrix lookup
            String inkType = null;
            if (assetId != null) {
                List<Installation_Report__c> irForInkType = [
                    SELECT Ink_Type__c
                    FROM Installation_Report__c
                    WHERE Case__r.AssetId = :assetId
                    AND IsSavedByUser__c = true
                    AND Ink_Type__c != null
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ];
                if (!irForInkType.isEmpty()) {
                    inkType = irForInkType[0].Ink_Type__c;
                }
            }

            // Load VMS matrix from Custom Metadata (no SOQL limit impact)
            Map<String, String> vmsMatrix = new Map<String, String>();
            for (VMS_Matrix__mdt vms : [
                SELECT Ink_Type__c, VMS_Values__c
                FROM VMS_Matrix__mdt
                WHERE Ink_Type__c != null
            ]) {
                if (String.isNotBlank(vms.VMS_Values__c)) {
                    vmsMatrix.put(vms.Ink_Type__c, vms.VMS_Values__c);
                }
            }

            return new Map<String, Object>{
                'pmChecklist' => pmChecklist,
                'lastPMData' => lastPMData,
                'assetId' => assetId,
                'caseId' => caseId,
                'inkType' => inkType,
                'vmsMatrix' => JSON.serialize(vmsMatrix)
            };
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Saves the PM Checklist record with updated JSON data.
     */
    @AuraEnabled
    public static PM_Checklist__c savePMChecklist(PM_Checklist__c pmChecklistRecord) {
        try {
            pmChecklistRecord.IsSavedByUser__c = true;
            pmChecklistRecord.Status__c = 'Saved';
            upsert pmChecklistRecord;
            return [
                SELECT Id, Name, Checklist_Data__c, IsSavedByUser__c, Status__c,
                       Service_Appointment__c, Work_Order__c, Case__c, Asset__c
                FROM PM_Checklist__c
                WHERE Id = :pmChecklistRecord.Id
            ];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Returns last PM reading data for the given asset.
     * Priority: 1) Previous PM_Checklist__c for same Asset
     *           2) Installation_Report__c for same Asset (via Work Order → Case → Asset)
     */
    @AuraEnabled
    public static Map<String, Object> getLastPMReading(Id assetId, Id currentPMChecklistId) {
        try {
            return getLastPMReadingInternal(assetId, currentPMChecklistId);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Internal method for last PM reading logic.
     */
    private static Map<String, Object> getLastPMReadingInternal(Id assetId, Id currentPMChecklistId) {
        Map<String, Object> result = new Map<String, Object>();

        if (assetId == null) {
            result.put('source', 'none');
            return result;
        }

        // 1. Try to find previous PM Checklist for same Asset (excluding current)
        String query = 'SELECT Id, Checklist_Data__c, CreatedDate FROM PM_Checklist__c ' +
                        'WHERE Asset__c = :assetId AND IsSavedByUser__c = true';
        if (currentPMChecklistId != null) {
            query += ' AND Id != :currentPMChecklistId';
        }
        query += ' ORDER BY CreatedDate DESC LIMIT 1';

        List<PM_Checklist__c> previousPMs = Database.query(query);

        if (!previousPMs.isEmpty() && String.isNotBlank(previousPMs[0].Checklist_Data__c)) {
            result.put('source', 'pmChecklist');
            result.put('data', previousPMs[0].Checklist_Data__c);
            return result;
        }

        // 2. Fall back to Installation Report for this Asset
        List<Installation_Report__c> irList = [
            SELECT Id,
                   L_N_volt__c,
                   N_G_volt__c,
                   G_L_volt__c,
                   Ink_Temp__c,
                   Cabinet_Temp__c,
                   Head_Temp__c,
                   Ink_Type__c,
                   Visc_Actual__c,
                   Running_Pressure__c,
                   EHT_Grade__c,
                   EHT_Range_Min__c,
                   EHT_Range_Max__c,
                   Modulation__c,
                   Charge_Value__c
            FROM Installation_Report__c
            WHERE Case__r.AssetId = :assetId
            AND IsSavedByUser__c = true
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        if (!irList.isEmpty()) {
            Installation_Report__c ir = irList[0];
            // Map Installation Report fields to PM Checklist parameter keys
            Map<String, String> irMapping = new Map<String, String>();

            if (ir.L_N_volt__c != null) irMapping.put('el_line_neutral', String.valueOf(ir.L_N_volt__c));
            if (ir.N_G_volt__c != null) irMapping.put('el_neutral_earth', String.valueOf(ir.N_G_volt__c));
            if (ir.G_L_volt__c != null) irMapping.put('el_line_earth', String.valueOf(ir.G_L_volt__c));
            if (ir.Ink_Temp__c != null) irMapping.put('env_ink_temp', String.valueOf(ir.Ink_Temp__c));
            if (ir.Cabinet_Temp__c != null) irMapping.put('env_cabinet_temp', String.valueOf(ir.Cabinet_Temp__c));
            if (ir.Head_Temp__c != null) irMapping.put('env_head_temp', String.valueOf(ir.Head_Temp__c));

            // Note: Diagnostics fields (V1-V12, pumps, etc.) are intentionally NOT mapped
            // from Installation Report. They only get Last PM from previous PM Checklists.

            result.put('source', 'installationReport');
            result.put('data', JSON.serialize(irMapping));
            return result;
        }

        result.put('source', 'none');
        return result;
    }

    /**
     * Uploads an image for the PM Checklist (Dust before/after, Jet alignment 80:20/50:50).
     * Image type prefix is used to identify the category.
     */
    @AuraEnabled
    public static Map<String, String> uploadPMChecklistImage(Id pmChecklistId, String base64Data, String fileName, String imageType) {
        try {
            if (pmChecklistId == null || String.isBlank(base64Data) || String.isBlank(fileName)) {
                throw new AuraHandledException('Missing required parameters for image upload.');
            }

            // Validate file size (300KB = 307200 bytes; base64 is ~33% larger than raw)
            Integer maxBase64Size = 409600; // ~300KB in base64
            if (base64Data.length() > maxBase64Size) {
                throw new AuraHandledException('Image size must be less than 300KB. Please choose a smaller image.');
            }

            // Build title with type prefix for identification
            String title = imageType + '_' + fileName;

            ContentVersion cv = new ContentVersion();
            cv.Title = title;
            cv.PathOnClient = fileName;
            cv.VersionData = EncodingUtil.base64Decode(base64Data);
            cv.ContentLocation = 'S';
            insert cv;

            // Re-query for ContentDocumentId
            cv = [SELECT Id, ContentDocumentId, Title FROM ContentVersion WHERE Id = :cv.Id];

            // Link to PM Checklist record
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = cv.ContentDocumentId;
            cdl.LinkedEntityId = pmChecklistId;
            cdl.ShareType = 'V';
            cdl.Visibility = 'AllUsers';
            insert cdl;

            return new Map<String, String>{
                'contentDocumentId' => cv.ContentDocumentId,
                'contentVersionId' => cv.Id,
                'title' => title
            };
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Returns images linked to a PM Checklist record filtered by image type prefix.
     */
    @AuraEnabled
    public static List<Map<String, String>> getPMChecklistImages(Id pmChecklistId, String imageType) {
        try {
            List<Map<String, String>> images = new List<Map<String, String>>();

            if (pmChecklistId == null || String.isBlank(imageType)) {
                return images;
            }

            String likePattern = imageType + '_%';
            List<ContentDocumentLink> links = [
                SELECT ContentDocumentId,
                       ContentDocument.LatestPublishedVersionId,
                       ContentDocument.LatestPublishedVersion.Title
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :pmChecklistId
                AND ContentDocument.Title LIKE :likePattern
                ORDER BY ContentDocument.CreatedDate DESC
            ];

            for (ContentDocumentLink link : links) {
                images.add(new Map<String, String>{
                    'contentDocumentId' => link.ContentDocumentId,
                    'contentVersionId' => link.ContentDocument.LatestPublishedVersionId,
                    'title' => link.ContentDocument.LatestPublishedVersion.Title,
                    'url' => '/sfc/servlet.shepherd/version/download/' + link.ContentDocument.LatestPublishedVersionId
                });
            }

            return images;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Deletes an image (ContentDocument) from the PM Checklist.
     */
    @AuraEnabled
    public static void deletePMChecklistImage(Id contentDocumentId) {
        try {
            if (contentDocumentId == null) {
                throw new AuraHandledException('ContentDocument Id is required.');
            }
            delete [SELECT Id FROM ContentDocument WHERE Id = :contentDocumentId LIMIT 1];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}