import { LightningElement, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import {
    showToast,
    navigateBackInHistory,
    disablePullToRefresh,
    enablePullToRefresh
} from 'c/utilJS';
import {
    PM_CHECKLIST_STRUCTURE,
    buildPmChecklistModel,
    generateNRCRemark,
    generateElectricalRemark,
    vmsLookup
} from './pmChecklistSchema.js';

import getOrCreatePMChecklist from '@salesforce/apex/FieldServicePMChecklistController.getOrCreatePMChecklist';
import savePMChecklist from '@salesforce/apex/FieldServicePMChecklistController.savePMChecklist';
import uploadPMChecklistImage from '@salesforce/apex/FieldServicePMChecklistController.uploadPMChecklistImage';
import getPMChecklistImages from '@salesforce/apex/FieldServicePMChecklistController.getPMChecklistImages';
import deletePMChecklistImage from '@salesforce/apex/FieldServicePMChecklistController.deletePMChecklistImage';

const JSON_VERSION = 2;

function parseChecklistPayload(jsonStr) {
    if (!jsonStr || typeof jsonStr !== 'string') return {};
    try {
        const o = JSON.parse(jsonStr);
        const raw = o.values && typeof o.values === 'object' ? o.values : o;
        const out = {};
        Object.keys(raw).forEach((k) => {
            const cell = raw[k];
            if (cell && typeof cell === 'object') {
                out[k] = {
                    actualReading: cell.actualReading != null ? String(cell.actualReading) : '',
                    remark: cell.remark != null ? String(cell.remark) : ''
                };
            } else if (typeof cell === 'string') {
                out[k] = { actualReading: cell, remark: '' };
            }
        });
        return out;
    } catch (e) {
        return {};
    }
}

function validateRow(row, actualStr) {
    const trimmed = actualStr != null ? String(actualStr).trim() : '';

    // Required check
    if (row.required && !trimmed) {
        return { valid: false, message: 'Required' };
    }
    if (!trimmed) return { valid: true };

    // Picklist validation
    if (row.type === 'picklist') {
        const allowed = (row.picklistOptions || []).map((o) => o.value);
        if (allowed.length && !allowed.includes(trimmed)) {
            return { valid: false, message: 'Invalid selection' };
        }
        return { valid: true };
    }

    // Integer validation
    if (row.type === 'integer') {
        const num = parseInt(trimmed, 10);
        if (isNaN(num) || String(num) !== trimmed) {
            return { valid: false, message: 'Must be a whole number' };
        }
        // Max digits check
        if (row.maxDigits && trimmed.length > row.maxDigits) {
            return { valid: false, message: `Max ${row.maxDigits} digits allowed` };
        }
        if (row.maxValue && num > row.maxValue) {
            return { valid: false, message: `Must be less than ${row.maxValue + 1}` };
        }
        // Block-save validation for EHT fields
        if (row.blockSaveAbove != null && num > row.blockSaveAbove) {
            return { valid: false, message: row.blockSaveMessage || `Value exceeds ${row.blockSaveAbove}` };
        }
        // Valid range check (soft — allows entry but marks error)
        if (row.validRange) {
            const [lo, hi] = row.validRange;
            if (num < lo || num > hi) {
                return { valid: false, message: `Must be between ${lo} and ${hi}` };
            }
        }
        return { valid: true };
    }

    // Number validation
    if (row.type === 'number') {
        const num = parseFloat(trimmed.replace(/,/g, ''));
        if (isNaN(num)) {
            return { valid: false, message: 'Invalid number' };
        }
        if (!row.allowDecimal && trimmed.includes('.')) {
            return { valid: false, message: 'Decimal not allowed' };
        }
        // Block-save for EHT
        if (row.blockSaveAbove != null && num > row.blockSaveAbove) {
            return { valid: false, message: row.blockSaveMessage || `Value exceeds ${row.blockSaveAbove}` };
        }
        // Valid range for fluid addition etc.
        if (row.validRange) {
            const [lo, hi] = row.validRange;
            if (num < lo || num > hi) {
                return { valid: false, message: `Must be between ${lo} and ${hi}` };
            }
        }
        return { valid: true };
    }

    return { valid: true };
}


export default class FieldServicePMChecklist extends LightningElement {
    @track serviceAppointmentId;
    @track workOrderId;
    @track showSpinner = false;

    @track values = {};
    @track fieldErrors = {};
    @track lastPm = {};
    @track lastPmSource = 'none';
    @track inkType = null;  // Ink Type from Installation Report for VMS lookup
    @track vmsMatrix = {};  // VMS matrix from Custom Metadata

    // PM Checklist record from Salesforce
    @track pmChecklistRecord = {};

    // Image storage per slot key
    @track imagesBySlot = {};

    pmModel = buildPmChecklistModel(PM_CHECKLIST_STRUCTURE);

    @track activeGroupNames;
    @track innerOpenByGroup = {};

    // ─────── Lifecycle ───────

    @wire(CurrentPageReference)
    wiredPageRef(pageRef) {
        const state = pageRef?.state;
        if (!state) return;
        const wo = state.c__id;
        const sa = state.c__serviceAppointmentId;
        if (wo && sa && sa !== this.serviceAppointmentId) {
            this.workOrderId = wo;
            this.serviceAppointmentId = sa;
            this.loadData();
        }
    }

    connectedCallback() {
        disablePullToRefresh(this);
        this.activeGroupNames = this.pmModel.groups.map((g) => g.key);
        const inner = {};
        this.pmModel.groups.forEach((g) => {
            inner[g.key] = g.sections.map((s) => s.sectionId);
        });
        this.innerOpenByGroup = inner;
    }

    disconnectedCallback() {
        enablePullToRefresh(this);
    }

    // ─────── Data Loading ───────

    async loadData() {
        this.showSpinner = true;
        try {
            const result = await getOrCreatePMChecklist({
                serviceAppointmentId: this.serviceAppointmentId,
                workOrderId: this.workOrderId
            });

            this.pmChecklistRecord = result.pmChecklist;

            // Parse existing checklist data if any
            let currentData = {};
            if (this.pmChecklistRecord.Checklist_Data__c) {
                currentData = parseChecklistPayload(this.pmChecklistRecord.Checklist_Data__c);
            }

            // Parse last PM reading
            const lastPMData = result.lastPMData;
            this.lastPmSource = lastPMData?.source || 'none';
            this.lastPm = {};

            if (lastPMData?.source === 'pmChecklist' && lastPMData.data) {
                const parsed = parseChecklistPayload(lastPMData.data);
                Object.keys(parsed).forEach((k) => {
                    this.lastPm[k] = parsed[k].actualReading || '';
                });
            } else if (lastPMData?.source === 'installationReport' && lastPMData.data) {
                try {
                    const irMap = JSON.parse(lastPMData.data);
                    Object.keys(irMap).forEach((k) => {
                        this.lastPm[k] = irMap[k] || '';
                    });
                } catch (e) { /* ignore parse error */ }
            }

            this.values = this.mergeWithSchemaDefaults(currentData);
            this.fieldErrors = {};

            // Store Ink Type from Installation Report for VMS matrix
            this.inkType = result.inkType || null;

            // Store VMS matrix from Custom Metadata (comes as JSON string from Apex)
            console.log('[VMS Load] raw vmsMatrix type:', typeof result.vmsMatrix, '| value:', result.vmsMatrix ? String(result.vmsMatrix).substring(0, 200) : 'EMPTY/NULL');
            try {
                this.vmsMatrix = result.vmsMatrix ? JSON.parse(result.vmsMatrix) : {};
                console.log('[VMS Load] parsed keys:', Object.keys(this.vmsMatrix));
            } catch (e) {
                console.error('Failed to parse VMS matrix:', e);
                this.vmsMatrix = {};
            }

            // Load images for all image slots
            if (this.pmChecklistRecord.Id) {
                await this.loadAllImages();
            }
        } catch (error) {
            console.error('Error loading PM Checklist:', error);
            showToast(this, 'Error', 'Failed to load PM Checklist.', 'error', error);
        } finally {
            this.showSpinner = false;
        }
    }

    async loadAllImages() {
        const allSlotKeys = [];
        this.pmModel.flatSections.forEach((sec) => {
            (sec.imageRows || []).forEach((imgRow) => {
                (imgRow.imageSlots || []).forEach((slot) => {
                    allSlotKeys.push(slot.key);
                });
            });
        });

        const imagesBySlot = {};
        for (const slotKey of allSlotKeys) {
            try {
                const images = await getPMChecklistImages({
                    pmChecklistId: this.pmChecklistRecord.Id,
                    imageType: slotKey
                });
                imagesBySlot[slotKey] = images || [];
            } catch (e) {
                imagesBySlot[slotKey] = [];
            }
        }
        this.imagesBySlot = imagesBySlot;
    }

    mergeWithSchemaDefaults(stored) {
        const out = { ...stored };
        this.pmModel.flatSections.forEach((sec) => {
            sec.rows.forEach((row) => {
                if (!out[row.id]) {
                    out[row.id] = {
                        actualReading: '',
                        remark: row.defaultRemark != null ? String(row.defaultRemark) : ''
                    };
                }
            });
            // Batch rows
            (sec.batchRows || []).forEach((br) => {
                if (!out[br.batchFieldId]) {
                    out[br.batchFieldId] = { actualReading: '', remark: '' };
                }
                if (!out[br.expiryFieldId]) {
                    out[br.expiryFieldId] = { actualReading: '', remark: '' };
                }
                if (!out[br.id + '_remark']) {
                    out[br.id + '_remark'] = { actualReading: '', remark: '' };
                }
            });
        });
        return out;
    }

    // ─────── Accordion Handlers ───────

    handleGroupAccordionToggle(event) {
        this.activeGroupNames = event.detail.openSections;
    }

    handleInnerAccordionToggle(event) {
        const wrap = event.currentTarget.parentElement;
        const gk = wrap?.dataset?.groupKey;
        if (!gk) return;
        this.innerOpenByGroup = {
            ...this.innerOpenByGroup,
            [gk]: event.detail.openSections
        };
    }

    // ─────── Value Change Handlers ───────

    handleActualChange(event) {
        const fieldId = event.target.dataset.fieldId;
        if (!fieldId) return;
        const prev = this.values[fieldId] || { actualReading: '', remark: '' };
        let v = event.detail?.value ?? event.target?.value;
        if (v === undefined || v === null) v = '';
        this.values = {
            ...this.values,
            [fieldId]: { actualReading: String(v), remark: prev.remark }
        };
        const err = { ...this.fieldErrors };
        delete err[fieldId];
        this.fieldErrors = err;
    }

    handleRemarkChange(event) {
        const fieldId = event.target.dataset.fieldId;
        if (!fieldId) return;
        const prev = this.values[fieldId] || { actualReading: '', remark: '' };
        const v = event.detail?.value ?? event.target?.value ?? '';
        this.values = {
            ...this.values,
            [fieldId]: { actualReading: prev.actualReading, remark: String(v) }
        };
    }

    handleBatchChange(event) {
        const fieldId = event.target.dataset.fieldId;
        if (!fieldId) return;
        const v = event.detail?.value ?? event.target?.value ?? '';
        const prev = this.values[fieldId] || { actualReading: '', remark: '' };
        this.values = {
            ...this.values,
            [fieldId]: { actualReading: String(v), remark: prev.remark }
        };
    }

    handleExpiryChange(event) {
        const fieldId = event.target.dataset.fieldId;
        if (!fieldId) return;
        const v = event.detail?.value ?? event.target?.value ?? '';
        const prev = this.values[fieldId] || { actualReading: '', remark: '' };
        this.values = {
            ...this.values,
            [fieldId]: { actualReading: String(v), remark: prev.remark }
        };
    }

    // ─────── Image Handlers ───────

    handleImageUpload(event) {
        const slotKey = event.target.dataset.slotKey;
        if (!slotKey) return;

        const file = event.target.files[0];
        if (!file) return;

        // Validate size (300KB)
        if (file.size > 300 * 1024) {
            showToast(this, 'File too large', 'Image must be less than 300KB.', 'warning');
            event.target.value = '';
            return;
        }

        const reader = new FileReader();
        reader.onload = async () => {
            const base64 = reader.result.split(',')[1];
            this.showSpinner = true;
            try {
                const result = await uploadPMChecklistImage({
                    pmChecklistId: this.pmChecklistRecord.Id,
                    base64Data: base64,
                    fileName: file.name,
                    imageType: slotKey
                });
                // Refresh images for this slot
                const images = await getPMChecklistImages({
                    pmChecklistId: this.pmChecklistRecord.Id,
                    imageType: slotKey
                });
                this.imagesBySlot = {
                    ...this.imagesBySlot,
                    [slotKey]: images || []
                };
                showToast(this, 'Success', 'Image uploaded successfully.', 'success');
            } catch (error) {
                console.error('Image upload error:', error);
                showToast(this, 'Error', 'Failed to upload image.', 'error', error);
            } finally {
                this.showSpinner = false;
                event.target.value = '';
            }
        };
        reader.readAsDataURL(file);
    }

    async handleImageDelete(event) {
        const docId = event.target.dataset.documentId;
        const slotKey = event.target.dataset.slotKey;
        if (!docId || !slotKey) return;

        this.showSpinner = true;
        try {
            await deletePMChecklistImage({ contentDocumentId: docId });
            const images = await getPMChecklistImages({
                pmChecklistId: this.pmChecklistRecord.Id,
                imageType: slotKey
            });
            this.imagesBySlot = {
                ...this.imagesBySlot,
                [slotKey]: images || []
            };
            showToast(this, 'Deleted', 'Image removed.', 'success');
        } catch (error) {
            showToast(this, 'Error', 'Failed to delete image.', 'error', error);
        } finally {
            this.showSpinner = false;
        }
    }

    // ─────── Validation ───────

    validateAll() {
        const errors = {};
        this.pmModel.flatSections.forEach((sec) => {
            sec.rows.forEach((row) => {
                const cell = this.values[row.id] || { actualReading: '', remark: '' };
                const res = validateRow(row, cell.actualReading);
                if (!res.valid) {
                    errors[row.id] = res.message;
                }

                // ±5% deviation mandatory remark check for filter life rows
                if (row.remarkRequiredOnDeviation && row.filterLifeSpec != null && cell.actualReading) {
                    const numVal = parseInt(cell.actualReading, 10);
                    if (!isNaN(numVal)) {
                        const specVal = row.filterLifeSpec;
                        const deviation = Math.abs(numVal - specVal) / specVal * 100;
                        if (deviation >= row.deviationPercent && (!cell.remark || !cell.remark.trim())) {
                            errors[row.id] = 'Remark is mandatory when value deviates ±' + row.deviationPercent + '% from specified';
                        }
                    }
                }
            });
        });
        this.fieldErrors = errors;
        return Object.keys(errors).length === 0;
    }

    // ─────── Save ───────

    async handleSave() {
        if (!this.validateAll()) {
            showToast(this, 'Validation', 'Fix highlighted fields before saving.', 'warning');
            return;
        }

        this.showSpinner = true;
        try {
            const payload = this.buildPayloadString();
            const record = {
                Id: this.pmChecklistRecord.Id,
                Checklist_Data__c: payload
            };

            const saved = await savePMChecklist({ pmChecklistRecord: record });
            this.pmChecklistRecord = saved;
            showToast(this, 'Saved', 'PM Checklist saved to Salesforce successfully.', 'success');
            navigateBackInHistory(this);
        } catch (error) {
            console.error('Save error:', error);
            showToast(this, 'Error', 'Failed to save PM Checklist.', 'error', error);
        } finally {
            this.showSpinner = false;
        }
    }

    handleCancel() {
        navigateBackInHistory(this);
    }

    buildPayloadString() {
        const values = {};
        this.pmModel.flatSections.forEach((sec) => {
            sec.rows.forEach((row) => {
                const cell = this.values[row.id] || { actualReading: '', remark: '' };
                // For auto-remark rows, compute the remark
                let remark = cell.remark;
                if (row.remarkMode === 'auto') {
                    remark = generateElectricalRemark(row, cell.actualReading, this.values);
                } else if (row.remarkMode === 'autoNRC') {
                    remark = generateNRCRemark(row, cell.actualReading, this.values);
                } else if (row.remarkMode === 'autoSunlight') {
                    remark = cell.actualReading === 'Yes' ? (row.autoSunlightRemark || 'If ink storage in direct sunlight') : '';
                }
                values[row.id] = {
                    actualReading: cell.actualReading,
                    remark
                };
            });
            // Batch rows
            (sec.batchRows || []).forEach((br) => {
                const batchCell = this.values[br.batchFieldId] || { actualReading: '', remark: '' };
                const expiryCell = this.values[br.expiryFieldId] || { actualReading: '', remark: '' };
                const remarkCell = this.values[br.id + '_remark'] || { actualReading: '', remark: '' };
                values[br.batchFieldId] = { actualReading: batchCell.actualReading, remark: '' };
                values[br.expiryFieldId] = { actualReading: expiryCell.actualReading, remark: '' };
                values[br.id + '_remark'] = { actualReading: '', remark: remarkCell.remark };
            });
        });

        return JSON.stringify({
            version: JSON_VERSION,
            savedAt: new Date().toISOString(),
            values
        });
    }

    // ─────── Auto-Remark Computation ───────

    computeAutoRemark(row) {
        const cell = this.values[row.id] || { actualReading: '' };
        const av = cell.actualReading;
        if (row.remarkMode === 'auto') {
            return generateElectricalRemark(row, av, this.values);
        }
        if (row.remarkMode === 'autoNRC') {
            return generateNRCRemark(row, av, this.values);
        }
        if (row.remarkMode === 'autoSunlight') {
            return av === 'Yes' ? (row.autoSunlightRemark || 'If ink storage in direct sunlight') : '';
        }
        return '';
    }

    // ─────── Template Getters ───────

    mapRowForDisplay(row) {
        const cell = this.values[row.id] || { actualReading: '', remark: '' };
        const err = this.fieldErrors[row.id];
        const last = this.lastPm[row.id];

        const isPicklist = row.type === 'picklist';
        const isNumber = row.type === 'number' || row.type === 'integer';
        const isText = row.type === 'text' || row.type === 'manual';
        const showUnit = Boolean(row.unit && String(row.unit).trim());
        const displayTitle = `${row.rowOrdinal || ''} ${row.title}`.trim();

        // For VMS spec lookup rows, compute the dynamic specifiedRange showing the expected value
        let specifiedRange = row.specifiedRange || '';
        if (row.vmsSpecLookup) {
            const inkTempVal = (this.values['env_ink_temp'] || {}).actualReading;
            const vmsVal = vmsLookup(this.vmsMatrix, this.inkType, inkTempVal);
            console.log('[VMS Debug] inkType:', this.inkType, '| inkTemp:', inkTempVal, '| matrixKeys:', Object.keys(this.vmsMatrix || {}), '| result:', vmsVal);
            specifiedRange = vmsVal != null ? `${vmsVal} (${this.inkType || '?'})` : '(set Ink Temp)';
        }

        // Remark handling
        const isAutoRemark = ['auto', 'autoNRC', 'autoSunlight'].includes(row.remarkMode);
        let autoRemarkText = '';
        if (isAutoRemark) {
            autoRemarkText = this.computeAutoRemark(row);
        }
        const isRemarkEditable = row.remarkMode === 'open';
        const isRemarkHidden = row.remarkMode === 'hidden';

        return {
            ...row,
            key: row.id,
            displayTitle,
            isPicklistRow: isPicklist,
            isNumberRow: isNumber,
            isTextRow: isText,
            inputValue: cell.actualReading,
            remarksValue: isAutoRemark ? autoRemarkText : (cell.remark || ''),
            lastPmDisplay: (row.hasLastPM && last != null && String(last).trim() !== '') ? last : 'N/A',
            showLastPM: row.hasLastPM !== false,
            hasError: Boolean(err),
            errorMessage: err || '',
            actualInputClass: err ? 'pm-invalid' : '',
            showUnit,
            unitLabel: row.unit || '',
            isAutoRemark,
            autoRemarkText,
            isRemarkEditable,
            isRemarkHidden,
            hasReferenceLink: Boolean(row.referenceLink),
            referenceLinkUrl: row.referenceLink || '',
            showSpecifiedRange: Boolean(specifiedRange && String(specifiedRange).trim()),
            specifiedRange: specifiedRange,
            inputStep: row.allowDecimal ? '0.01' : '1'
        };
    }

    mapImageRowForDisplay(imgRow) {
        return {
            key: imgRow.id,
            title: imgRow.title ? `${imgRow.rowOrdinal || ''} ${imgRow.title}`.trim() : '',
            slots: (imgRow.imageSlots || []).map((slot) => ({
                key: slot.key,
                label: slot.label,
                maxSizeKB: slot.maxSizeKB,
                images: this.imagesBySlot[slot.key] || [],
                hasImages: (this.imagesBySlot[slot.key] || []).length > 0
            }))
        };
    }

    mapBatchRowForDisplay(br) {
        const batchCell = this.values[br.batchFieldId] || { actualReading: '' };
        const expiryCell = this.values[br.expiryFieldId] || { actualReading: '' };
        const remarkCell = this.values[br.id + '_remark'] || { remark: '' };

        return {
            key: br.id,
            title: `${br.rowOrdinal || ''} ${br.title}`.trim(),
            batchFieldId: br.batchFieldId,
            expiryFieldId: br.expiryFieldId,
            remarkFieldId: br.id + '_remark',
            batchValue: batchCell.actualReading || '',
            expiryValue: expiryCell.actualReading || '',
            remarkValue: remarkCell.remark || '',
            isRemarkEditable: br.remarkMode === 'open'
        };
    }

    get groupsForTemplate() {
        return this.pmModel.groups.map((g) => ({
            key: g.key,
            groupAccordionLabel: g.groupAccordionLabel,
            innerActive: this.innerOpenByGroup[g.key] || g.sections.map((s) => s.sectionId),
            sections: g.sections.map((sec) => {
                const hideRemarks = Boolean(sec.hideRemarks);
                const hideLastPM = Boolean(sec.hideLastPM);
                return {
                    key: sec.sectionId,
                    sectionId: sec.sectionId,
                    label: sec.sectionAccordionLabel,
                    optional: sec.optional,
                    hideRemarks,
                    showRemarks: !hideRemarks,
                    hideLastPM,
                    showLastPMColumn: !hideLastPM,
                    hasReferenceLink: Boolean(sec.referenceLink),
                    referenceLink: sec.referenceLink || '',
                    referenceLinkLabel: sec.referenceLinkLabel || 'Open reference',
                    displayRows: sec.rows.map((row) => this.mapRowForDisplay(row)),
                    hasImageRows: (sec.imageRows || []).length > 0,
                    displayImageRows: (sec.imageRows || []).map((ir) => this.mapImageRowForDisplay(ir)),
                    hasBatchRows: (sec.batchRows || []).length > 0,
                    displayBatchRows: (sec.batchRows || []).map((br) => this.mapBatchRowForDisplay(br))
                };
            })
        }));
    }

    get lastPmSourceLabel() {
        if (this.lastPmSource === 'pmChecklist') return 'Previous PM Checklist';
        if (this.lastPmSource === 'installationReport') return 'Installation Report';
        return 'N/A';
    }
}