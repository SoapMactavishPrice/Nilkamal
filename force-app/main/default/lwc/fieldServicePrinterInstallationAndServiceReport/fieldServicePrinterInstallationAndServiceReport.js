import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';

import getReportDetails from '@salesforce/apex/FieldServicePrinterInstallationService.getReportDetails';
import previewReport from '@salesforce/apex/FieldServicePrinterInstallationService.previewReport';
import saveReport from '@salesforce/apex/FieldServicePrinterInstallationService.saveReport';
import getDocumentId from '@salesforce/apex/FieldServicePrinterInstallationService.getDocumentId';
import uploadDiagnosticImage from '@salesforce/apex/FieldServicePrinterInstallationService.uploadDiagnosticImage';
import getDiagnosticImages from '@salesforce/apex/FieldServicePrinterInstallationService.getDiagnosticImages';
import deleteDiagnosticImage from '@salesforce/apex/FieldServicePrinterInstallationService.deleteDiagnosticImage';
import saveServiceReport from '@salesforce/apex/FieldServicePrinterInstallationService.saveServiceReport';
import saveServiceReportParameters from '@salesforce/apex/FieldServicePrinterInstallationService.saveServiceReportParameters';
import getServiceReportParameters from '@salesforce/apex/FieldServicePrinterInstallationService.getServiceReportParameters';
import getMaxPumpRunHoursForCase from '@salesforce/apex/FieldServicePrinterInstallationService.getMaxPumpRunHoursForCase';
import hasSpareRequestsForCase from '@salesforce/apex/FieldServicePrinterInstallationService.hasSpareRequestsForCase';
import saveInstallationReportParameters from '@salesforce/apex/FieldServicePrinterInstallationService.saveInstallationReportParameters';
import getInstallationReportParameters from '@salesforce/apex/FieldServicePrinterInstallationService.getInstallationReportParameters';
import getConsumableParts from '@salesforce/apex/FieldServicePrinterInstallationService.getConsumableParts';
import hasSpareRequestRecords from '@salesforce/apex/FieldServicePrinterInstallationService.hasSpareRequestRecords';

import { showToast, analyzeFormFactor, getNameAndValueOnChange, navigateToLWC, navigateToFilePreview } from 'c/utilJS';

export default class ExtendedInstallationReport extends NavigationMixin(LightningElement) {
    @track showSpinner = false;
    @api recordId;

    @api workOrderId;
    @api serviceAppointmentId;
    @api reportType;

    @track showInstallationReport = false;
    @track showServiceReport = false;

    // Installation Report properties
    @track installationReportRecord = {};
    @track isMobile = false;
    @track isSignatureModalOpen = false;
    @track isRemoteSupport = false;
    @track diagnosticScreenImages = [];
    @track modulationTestImages = [];
    @track ribbonImages = [];
    @track messageImages = [];
    @track earthingImages = [];
    @track printHeadStandImages = [];
    @track printerStandImages = [];
    @track toolBoxImages = [];
    @track printerManualImages = [];
    @track sensorImages = [];
    @track printHeadDirectionImages = []; // TIJ Photo 01
    @track printingMessageImages = []; // TIJ Photo 2
    @track packingChecklistImages = []; // TIJ Photo 03
    // TTO Physical Check Images
    @track printHeadPositionLiftedImages = []; // TTO - when "No"
    @track bomCheckListImages = []; // TTO - when "Items missing"
    @track sensorTTOImages = []; // TTO - when "NotOK"
    @track encoderTTOImages = []; // TTO - when "NOTok"
    @track gapBetweenPrintsImages = []; // TTO - MESSAGE Gap between prints (ribbon pic)
    @track industryTypeImages = []; // TTO - Industry Type
    // Installation Check Reference Images
    @track intermittentInstallationCheckImage = '/resource/IntermittentInstallationCheck'; // Can be updated to actual image URL
    @track continuousInstallationCheckImage = '/resource/ContinuousInstallationCheck'; // Can be updated to actual image URL
    @track showImageModal = false;
    @track selectedImageUrl = '';
    @track selectedImageName = '';
    @track selectedImageSection = '';
    @track currentReportParameters = [];

    // Service Report properties
    @track serviceReportRecord = {};
    @track serviceReportParameters = [];
    @track inkPartNoOptions = []; // Options for Ink Part No picklist
    @track usedInkCartridgeOptions = []; // Options for Used Ink Cartridge picklist
    @track isFirstServiceReport = true; // Track if this is the first Service Report for the Case
    @track fieldValidationErrors = {}; // Track validation errors for each field
    @track hasSpareRequestRecords;
    @track _recordVersion = 0; // Track version to force getter recalculation
    @track calculatedTotalRow1 = '0.00'; // Calculated total for row 1
    @track calculatedTotalRow2 = '0.00'; // Calculated total for row 2
    _hasCalculatedInitialTotals = false; // Flag to track if initial totals have been calculated
    
    // New table for TIJ - Based on CSV structure
    @track tijTableRows = [
        {
            key: 'print_head_firing_voltage',
            parameterName: 'Print head Firing Voltage',
            optionList: '',
            selectionType: '',
            selectionValue: ''
        },
        {
            key: 'pulse_value',
            parameterName: 'Pulse Value',
            optionList: 'N/A',
            selectionType: 'N/A',
            selectionValue: ''
        },
        {
            key: 'auto_jet_setting',
            parameterName: 'Auto jet setting',
            optionList: '',
            selectionType: '',
            selectionValue: ''
        },
        {
            key: 'nozzle_select',
            parameterName: 'Noizzle Select',
            optionList: '',
            selectionType: '',
            selectionValue: ''
        },
        {
            key: 'purging_auto_jet',
            parameterName: 'Purging auto jet',
            optionList: '',
            selectionType: '',
            selectionValue: '',
            intervalValue: '',
            quantityValue: ''
        },
        {
            key: 'dpi_x',
            parameterName: 'DPI X',
            optionList: 'N/A',
            selectionType: 'N/A',
            selectionValue: ''
        },
        {
            key: 'dpi_y',
            parameterName: 'DPI -Y',
            optionList: 'N/A',
            selectionType: 'N/A',
            selectionValue: ''
        },
        {
            key: 'printhead_delay',
            parameterName: 'Printhead Delay',
            optionList: 'N/A',
            selectionType: 'N/A',
            selectionValue: ''
        },
        {
            key: 'trigger_mode',
            parameterName: 'Trigger Mode',
            optionList: '',
            selectionType: '',
            selectionValue: ''
        },
        {
            key: 'continuous_print',
            parameterName: 'Continuous print',
            optionList: '',
            selectionType: '',
            selectionValue: ''
        },
        {
            key: 'photocell_setting',
            parameterName: 'Photocell setting',
            optionList: '',
            selectionType: '',
            selectionValue: ''
        },
        {
            key: 'encoder_setting',
            parameterName: 'Encoder setting',
            optionList: '',
            selectionType: '',
            selectionValue: '',
            pprValue: '',
            diameterValue: ''
        }
    ];
    
    // Separate date and time properties for Repair Start/End
    @track repairStartDate = '';
    @track repairStartTime = '';
    @track repairEndDate = '';
    @track repairEndTime = '';
    
    // Installation Report properties
    @track installationReportParameters = [];

    // Read‑only header fields for Installation (Customer / Contact / Phone)
    @track installationCustomerName;
    @track installationContactPerson;
    @track installationContactNumber;

    @wire(CurrentPageReference)
    getCurrentPageReference(currentPageReference) {
        if (currentPageReference && currentPageReference.state) {
            this.workOrderId = currentPageReference.state.c__workOrderId;
            this.serviceAppointmentId = currentPageReference.state.c__serviceAppointmentId;
            this.reportType = currentPageReference.state.c__reportType;

            this.showInstallationReport = this.reportType === 'InstallationReport';
            this.showServiceReport = this.reportType === 'ServiceReport';

            if (this.reportType === 'ServiceReport') {
                this.handleGetServiceReportDetails();
            } else if (this.reportType === 'InstallationReport') {
                this.handleGetInstallationReportDetails();
            }
        }
    }

    get currentReportRecord() {
        if (this.showInstallationReport) {
            return this.installationReportRecord || {};
        } else if (this.showServiceReport) {
            return this.serviceReportRecord || {};
        }
        return {};
    }

    // Helper flag to reuse Installation UI for both CIJ and TIJ printers
    get isCIJOrTIJ() {
        return !!this.isCIJ || !!this.isTIJ;
    }
    get currentObjectApiName() {
        return this.showInstallationReport ? 'Installation_Report__c' : 'Service_Report__c';
    }
    
    // CIJ Physical Check Image Upload Getters
    get isPrintHeadStandNotOK() {
        if (!this.installationReportRecord || !this.isCIJ) return false;
        const value = this.installationReportRecord.Print_Head_Stand__c;
        return value && (value.toLowerCase() === 'notok' || value.toLowerCase() === 'not ok' || value.toLowerCase() === 'nok');
    }

    get isPrinterStandNotOK() {
        if (!this.installationReportRecord || !this.isCIJ) return false;
        const value = this.installationReportRecord.Printer_Stand__c;
        return value && (value.toLowerCase() === 'notok' || value.toLowerCase() === 'not ok' || value.toLowerCase() === 'nok');
    }

    get isToolBoxNotOK() {
        if (!this.installationReportRecord || !this.isCIJ) return false;
        const value = this.installationReportRecord.Tool_Box__c;
        return value && (value.toLowerCase() === 'notok' || value.toLowerCase() === 'not ok' || value.toLowerCase() === 'nok');
    }

    get isPrinterManualNotOK() {
        if (!this.installationReportRecord || !this.isCIJ) return false;
        const value = this.installationReportRecord.Printer_Manual__c;
        return value && (value.toLowerCase() === 'notok' || value.toLowerCase() === 'not ok' || value.toLowerCase() === 'nok');
    }

    get isSensorNotOK() {
        if (!this.installationReportRecord || !this.isCIJ) return false;
        const value = this.installationReportRecord.Sensor__c;
        return value && (value.toLowerCase() === 'notok' || value.toLowerCase() === 'not ok' || value.toLowerCase() === 'nok');
    }

    // TTO Physical Check Image Upload Getters
    get isPrintHeadPositionLiftedNo() {
        if (!this.installationReportRecord || !this.isTTO) return false;
        const value = this.installationReportRecord.Print_head_position_lifted__c;
        return value && (value.toLowerCase() === 'no' || value.toLowerCase() === 'n');
    }
    
    get isBOMCheckListMissing() {
        if (!this.installationReportRecord || !this.isTTO) return false;
        const value = this.installationReportRecord.BOM_Check_list_verified__c;
        return value && (value.toLowerCase().includes('missing') || value.toLowerCase().includes('items missing'));
    }
    
    get isSensorTTONotOK() {
        if (!this.installationReportRecord || !this.isTTO) return false;
        const value = this.installationReportRecord.Sensor__c;
        return value && (value.toLowerCase() === 'notok' || value.toLowerCase() === 'not ok' || value.toLowerCase() === 'nok');
    }
    
    get isEncoderTTONotOK() {
        if (!this.installationReportRecord || !this.isTTO) return false;
        const value = this.installationReportRecord.Encoder__c;
        if (!value) return false;
        const valueLower = String(value).toLowerCase().trim();
        // Check for various "Not OK" variations
        return valueLower === 'notok' || 
               valueLower === 'not ok' || 
               valueLower === 'nok' ||
               (valueLower.includes('not') && valueLower.includes('ok'));
    }
    
    get isEarthingOK() {
        if (!this.installationReportRecord) return false;
        const value = this.installationReportRecord.Earthing__c;
        return value && (value.toLowerCase() !== 'ok' && value.toLowerCase() !== 'okay');
    }

    get showPasswordText() {
        if (!this.installationReportRecord) return false;
        const passwordValue = this.installationReportRecord.Password__c;
        if (!passwordValue) return false;
        const passwordLower = passwordValue.toLowerCase().trim();
        return passwordLower === 'level 01' || 
               passwordLower === 'level 02' ||
               passwordLower === 'level 1' ||
               passwordLower === 'level 2';
    }

    get showBracketText() {
        if (!this.installationReportRecord || !this.isTTO) return false;
        const value = this.installationReportRecord.Bracket_received_as_per_CRM_quopte__c;
        return value && (value.toLowerCase() === 'no' || value.toLowerCase() === 'n');
    }

    @track isAccordionOpen = {
        basicInfo: true,
        inkDetails: false,
        machineParams: false,
        deviceConfig: false,
        customerFeedback: false,
        ribbonPart: false,
        tijInstallationParams: false,
        travelExpense: false
    };

    // Computed properties for accordion icons
    get basicInfoIcon() {
        return this.isAccordionOpen.basicInfo ? 'utility:chevrondown' : 'utility:chevronright';
    }

    get inkDetailsIcon() {
        return this.isAccordionOpen.inkDetails ? 'utility:chevrondown' : 'utility:chevronright';
    }

    get machineParamsIcon() {
        return this.isAccordionOpen.machineParams ? 'utility:chevrondown' : 'utility:chevronright';
    }

    get deviceConfigIcon() {
        return this.isAccordionOpen.deviceConfig ? 'utility:chevrondown' : 'utility:chevronright';
    }

    get customerFeedbackIcon() {
        return this.isAccordionOpen.customerFeedback ? 'utility:chevrondown' : 'utility:chevronright';
    }

    get ribbonPartIcon() {
        return this.isAccordionOpen.ribbonPart ? 'utility:chevrondown' : 'utility:chevronright';
    }

    get tijInstallationParamsIcon() {
        return this.isAccordionOpen.tijInstallationParams ? 'utility:chevrondown' : 'utility:chevronright';
    }

    get travelExpenseIcon() {
        return this.isAccordionOpen.travelExpense ? 'utility:chevrondown' : 'utility:chevronright';
    }

    // Computed properties for accordion content classes
    get basicInfoContentClass() {
        return `accordion-content ${this.isAccordionOpen.basicInfo ? 'open' : ''}`;
    }

    get inkDetailsContentClass() {
        return `accordion-content ${this.isAccordionOpen.inkDetails ? 'open' : ''}`;
    }

    get machineParamsContentClass() {
        return `accordion-content ${this.isAccordionOpen.machineParams ? 'open' : ''}`;
    }

    get deviceConfigContentClass() {
        return `accordion-content ${this.isAccordionOpen.deviceConfig ? 'open' : ''}`;
    }

    get customerFeedbackContentClass() {
        return `accordion-content ${this.isAccordionOpen.customerFeedback ? 'open' : ''}`;
    }

    get ribbonPartContentClass() {
        return `accordion-content ${this.isAccordionOpen.ribbonPart ? 'open' : ''}`;
    }

    get tijInstallationParamsContentClass() {
        return `accordion-content ${this.isAccordionOpen.tijInstallationParams ? 'open' : ''}`;
    }

    get travelExpenseContentClass() {
        return `accordion-content ${this.isAccordionOpen.travelExpense ? 'open' : ''}`;
    }

    /**
     * Calculate totals for both rows and store in tracked properties
     * This method is called when the record is loaded and when relevant fields change
     */
    calculateTotals() {
        if (!this.serviceReportRecord) {
            this.calculatedTotalRow1 = '0.00';
            this.calculatedTotalRow2 = '0.00';
            return;
        }
        
        // Calculate Row 1 Total
        const lodging1 = parseFloat(this.serviceReportRecord.Lodging_Per_Day_1__c) || 0;
        const boarding1 = parseFloat(this.serviceReportRecord.Boarding_Per_Day_1__c) || 0;
        const conveyance1 = parseFloat(this.serviceReportRecord.Conven__c) || 0;
        const dailyTotal1 = lodging1 + boarding1 + conveyance1;
        
        let numberOfDays1 = 0;
        if (this.serviceReportRecord.TravelDate__c && this.serviceReportRecord.Date_To__c) {
            try {
                let dateFromStr = this.serviceReportRecord.TravelDate__c;
                let dateToStr = this.serviceReportRecord.Date_To__c;
                
                // Handle Date objects
                if (dateFromStr instanceof Date) {
                    dateFromStr = dateFromStr.toISOString().split('T')[0];
                } else if (typeof dateFromStr === 'string') {
                    // If it's an ISO string with time, extract just the date part
                    if (dateFromStr.includes('T')) {
                        dateFromStr = dateFromStr.split('T')[0];
                    }
                    // If it's already in YYYY-MM-DD format, use it as is
                }
                
                if (dateToStr instanceof Date) {
                    dateToStr = dateToStr.toISOString().split('T')[0];
                } else if (typeof dateToStr === 'string') {
                    // If it's an ISO string with time, extract just the date part
                    if (dateToStr.includes('T')) {
                        dateToStr = dateToStr.split('T')[0];
                    }
                    // If it's already in YYYY-MM-DD format, use it as is
                }
                
                // Parse dates at midnight to avoid timezone issues
                const dateFrom = new Date(dateFromStr + 'T00:00:00');
                const dateTo = new Date(dateToStr + 'T00:00:00');
                
                if (!isNaN(dateFrom.getTime()) && !isNaN(dateTo.getTime())) {
                    const diffTime = dateTo.getTime() - dateFrom.getTime();
                    const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));
                    numberOfDays1 = diffDays + 1;
                } else {
                    console.warn('Invalid dates for row 1 - TravelDate__c:', dateFromStr, 'Date_To__c:', dateToStr);
                }
            } catch (error) {
                console.error('Error calculating date difference for row 1:', error, 'TravelDate__c:', this.serviceReportRecord.TravelDate__c, 'Date_To__c:', this.serviceReportRecord.Date_To__c);
                numberOfDays1 = 0;
            }
        }
        
        const total1 = (dailyTotal1 * numberOfDays1).toFixed(2);
        this.calculatedTotalRow1 = total1;
        console.log('Row 1 Total calculated:', total1, 'Daily Total:', dailyTotal1, 'Days:', numberOfDays1);
        
        // Calculate Row 2 Total
        const lodging2 = parseFloat(this.serviceReportRecord.Lodging_Per_Day_2__c) || 0;
        const boarding2 = parseFloat(this.serviceReportRecord.Boarding_Per_Day_2__c) || 0;
        const conveyance2 = parseFloat(this.serviceReportRecord.Conveyance_2__c) || 0;
        const dailyTotal2 = lodging2 + boarding2 + conveyance2;
        
        let numberOfDays2 = 0;
        if (this.serviceReportRecord.Travel_Date_2__c && this.serviceReportRecord.Date_To_2__c) {
            try {
                let dateFromStr = this.serviceReportRecord.Travel_Date_2__c;
                let dateToStr = this.serviceReportRecord.Date_To_2__c;
                
                // Handle Date objects
                if (dateFromStr instanceof Date) {
                    dateFromStr = dateFromStr.toISOString().split('T')[0];
                } else if (typeof dateFromStr === 'string') {
                    // If it's an ISO string with time, extract just the date part
                    if (dateFromStr.includes('T')) {
                        dateFromStr = dateFromStr.split('T')[0];
                    }
                    // If it's already in YYYY-MM-DD format, use it as is
                }
                
                if (dateToStr instanceof Date) {
                    dateToStr = dateToStr.toISOString().split('T')[0];
                } else if (typeof dateToStr === 'string') {
                    // If it's an ISO string with time, extract just the date part
                    if (dateToStr.includes('T')) {
                        dateToStr = dateToStr.split('T')[0];
                    }
                    // If it's already in YYYY-MM-DD format, use it as is
                }
                
                // Parse dates at midnight to avoid timezone issues
                const dateFrom = new Date(dateFromStr + 'T00:00:00');
                const dateTo = new Date(dateToStr + 'T00:00:00');
                
                if (!isNaN(dateFrom.getTime()) && !isNaN(dateTo.getTime())) {
                    const diffTime = dateTo.getTime() - dateFrom.getTime();
                    const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));
                    numberOfDays2 = Math.abs(diffDays) + 1;
                } else {
                    console.warn('Invalid dates for row 2 - Travel_Date_2__c:', dateFromStr, 'Date_To_2__c:', dateToStr);
                }
            } catch (error) {
                console.error('Error calculating date difference for row 2:', error, 'Travel_Date_2__c:', this.serviceReportRecord.Travel_Date_2__c, 'Date_To_2__c:', this.serviceReportRecord.Date_To_2__c);
                numberOfDays2 = 0;
            }
        }
        
        const total2 = (dailyTotal2 * numberOfDays2).toFixed(2);
        this.calculatedTotalRow2 = total2;
        console.log('Row 2 Total calculated:', total2, 'Daily Total:', dailyTotal2, 'Days:', numberOfDays2);
    }

    // Computed property for Total calculation (Row 1)
    // Formula: (Lodging Per Day + Boarding Per Day + Conveyance Per Day) * (Integer(Date To - Date From))
    get totalPerDay() {
        // Return the calculated total from tracked property
        return this.calculatedTotalRow1 || '0.00';
    }

    // Computed property for Total calculation (Row 2)
    // Formula: (Lodging Per Day + Boarding Per Day + Conveyance Per Day) * (Integer(Date To - Date From))
    get totalPerDay2() {
        // Return the calculated total from tracked property
        return this.calculatedTotalRow2 || '0.00';
    }

    // Visual scale for Service Rating shown as smileys inside the signature modal
    get serviceRatingScale() {
        // Only relevant for Service Report
        const currentRating = this.showServiceReport && this.serviceReportRecord
            ? this.serviceReportRecord.Service_Rating__c
            : null;

        const baseScale = [
            { storedValue: 'Very Poor', icon: '😡', label: 'Very Poor' },
            { storedValue: 'Poor', icon: '☹️', label: 'Poor' },
            { storedValue: 'Average', icon: '😐', label: 'Average' },
            { storedValue: 'Good', icon: '🙂', label: 'Good' },
            { storedValue: 'Excellent', icon: '😃', label: 'Excellent' }
        ];

        return baseScale.map(item => {
            const isSelected = item.storedValue === currentRating;
            return {
                ...item,
                cssClass: `rating-icon${isSelected ? ' rating-icon_selected' : ''}`
            };
        });
    }


	    // ACCORDION TOGGLE METHOD
	    toggleAccordion(event) {
	        // Keep this handler simple and robust (works even when the click target is an
	        // SVG/text node or inside a shadow root).
	        const section = event?.currentTarget?.dataset?.section;
	        if (!section) {
	            return;
	        }
	        this.isAccordionOpen = {
	            ...this.isAccordionOpen,
	            [section]: !this.isAccordionOpen[section]
	        };
	    }


    connectedCallback() {
        analyzeFormFactor(this);
        // Don't calculate totals here - record hasn't been loaded yet
        // Totals will be calculated after record is loaded in mapReportDetails
    }

    renderedCallback() {
        // Calculate totals after component is rendered to ensure all data is available
        // Only do this once on initial load if we haven't calculated yet
        if (!this._hasCalculatedInitialTotals && this.serviceReportRecord && Object.keys(this.serviceReportRecord).length > 0) {
            // Only calculate if we have a record and it's a service report
            if (this.showServiceReport && this.serviceReportRecord.Id) {
                // Check if we have date fields populated
                if (this.serviceReportRecord.TravelDate__c || this.serviceReportRecord.Date_To__c || 
                    this.serviceReportRecord.Travel_Date_2__c || this.serviceReportRecord.Date_To_2__c) {
                    this.calculateTotals();
                    this._hasCalculatedInitialTotals = true;
                }
            }
        }
    }

    handleParameterMappingChange(event){
        this.currentReportParameters = event.detail.configuration;
    }



    // INSTALLATION REPORT METHODS
    handleGetInstallationReportDetails() {
        this.showSpinner = true;
        getReportDetails({
            workOrderId: this.workOrderId,
            serviceAppointmentId: this.serviceAppointmentId,
            reportType: this.reportType
        })
            .then(result => {
                if (!result) return;
                this.mapReportDetails(result);
                this.loadAllImages();
                // Load parameters if TIJ
                if (this.isTIJ) {
                    this.loadInstallationReportParameters();
                }
            })
            .catch(error => {
                console.log('error', error);
                showToast(this, 'Error', 'Something went wrong', 'error', error);
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }

    async loadInstallationReportParameters() {
        if (!this.installationReportRecord || !this.installationReportRecord.Id) {
            console.log('Installation Report ID not available, skipping parameter load');
            return;
        }

        try {
            const params = await getInstallationReportParameters({ installationReportId: this.installationReportRecord.Id });
            console.log('Loaded installation parameters:', params);
            this.installationReportParameters = params || [];
        } catch (error) {
            console.error('Error loading installation parameters:', error);
            showToast(this, 'Error', 'Failed to load parameters', 'error');
        }
    }

    async saveInstallationReportParameters() {
        if (!this.installationReportRecord || !this.installationReportRecord.Id) {
            console.error('Installation Report ID is required to save parameters');
            return;
        }

        try {
            // Use currentReportParameters if available (contains user edits from parameterMappingForm)
            // Otherwise fall back to installationReportParameters (original database values)
            const parametersToSave = (this.currentReportParameters && this.currentReportParameters.length > 0) 
                ? this.currentReportParameters 
                : this.installationReportParameters;

            console.log('Current Report Parameters before save:', JSON.stringify(this.currentReportParameters, null, 2));
            console.log('Parameters being saved:', JSON.stringify(parametersToSave, null, 2));

            const paramsToSave = parametersToSave.map((param, index) => ({
                Name: param.parameterName,
                Installation_Report__c: this.installationReportRecord.Id,
                Selected_Type__c: param.selectedType || '',
                Selection_Value__c: param.selectedValue || '',
                Display_Order__c: index + 1,
                Selection_Options_List__c: param.selectedOption || (param.dynamicOptions ? this.getOptionsString(param.dynamicOptions) : '')
            }));

            console.log('Saving installation parameters:', JSON.stringify(paramsToSave, null, 2));

            await saveInstallationReportParameters({ parameters: paramsToSave });
            console.log('Installation parameters saved successfully');
        } catch (error) {
            console.error('Error saving installation parameters:', error);
            showToast(this, 'Error', 'Failed to save installation parameters', 'error');
        }
    }

    // SERVICE REPORT METHODS
    handleGetServiceReportDetails() {
        this.showSpinner = true;
        console.log('Fetching service report details for Work Order ID:', this.workOrderId, 'and Service Appointment ID:', this.serviceAppointmentId);

        getReportDetails({
            workOrderId: this.workOrderId,
            serviceAppointmentId: this.serviceAppointmentId,
            reportType: this.reportType
        })
            .then(result => {
                console.log('Service Report Details:', result);
                if (!result) return;
                this.mapReportDetails(result);
                // Load parameters after mapping report details
                this.loadServiceReportParameters();
            })
            .catch(error => {
                console.error('error', error);
                showToast(this, 'Error', 'Something went wrong', 'error', error);
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }

    // FIXED: Unified mapping function
    mapReportDetails(result) {
        const { workOrder, serviceAppointment, installationReport, serviceReport, causeSubCauseList, sroList, hourMeterRequired } = result;

        // Remote_Support__c = true  → this.isRemoteSupport = true
        // (only in that case we enforce mandatory signature)
        this.isRemoteSupport = !!serviceAppointment?.Remote_Support__c;

        if (workOrder && workOrder.Case__r && workOrder.Case__r.Asset && workOrder.Case__r.Asset.Product2) {
            this.materialGroup5 = workOrder.Case__r.Asset.Product2.Material_Group_5__c || '';

            this.determineProductType(this.materialGroup5);

            console.log('Material Group 5 extracted:', this.materialGroup5);
            console.log('isCIJ:', this.isCIJ, 'isTIJ:', this.isTIJ, 'isTTO:', this.isTTO);

            // Load consumable parts for Ink Part No picklist (CIJ/P01, TTO/P02, TIJ/P03) and Ribbon Part picklist (TTO/P02)
            if (this.materialGroup5 && (this.reportType === 'ServiceReport' || (this.reportType === 'InstallationReport' && (this.isCIJ || this.isTTO || this.isTIJ)))) {
                this.loadConsumableParts();
            }
        }

        if (this.reportType === 'InstallationReport') {
            this.installationReportRecord = installationReport || {};

            // Pre‑populate read‑only customer header fields for Installation,
            // similar to how Service Report shows them.
            if (workOrder && workOrder.Case__r) {
                const account = workOrder.Case__r.Account;
                const contact = workOrder.Case__r.Contact;

                this.installationCustomerName = account ? account.Name : '';
                this.installationContactPerson = contact ? contact.Name : '';
                this.installationContactNumber = workOrder.Case__r.ContactMobile || '';
                
                // Pre-populate Complaint Status from the related Case Status when not already set.
                // This keeps the Installation Report complaint status aligned with the Case and
                // supports backfilling older Installation Reports that may not have this field populated.
                if (
                    workOrder.Case__r.Status &&
                    !this.installationReportRecord.Complaint_Status__c
                ) {
                    this.installationReportRecord = {
                        ...this.installationReportRecord,
                        Complaint_Status__c: workOrder.Case__r.Status
                    };
                }
                
                // Pre-populate Party Code and Customer Name for all printer types (CIJ, TIJ, TTO) - same as Service Report
                // This supports backfilling older Installation Reports that may not have these fields populated.
                if ((this.isCIJ || this.isTIJ || this.isTTO) && account) {
                    if (account.SAP_Customer_code__c && !this.installationReportRecord.Party_Code__c) {
                        this.installationReportRecord = {
                            ...this.installationReportRecord,
                            Party_Code__c: account.SAP_Customer_code__c
                        };
                    }
                    if (account.Name && !this.installationReportRecord.Customer_Name__c) {
                        this.installationReportRecord = {
                            ...this.installationReportRecord,
                            Customer_Name__c: account.Name
                        };
                    }
                }
                
                // Pre-populate Industry Type from Asset when not already set.
                // This supports backfilling older Installation Reports that may not have this field populated.
                if (
                    workOrder.Case__r.Asset &&
                    workOrder.Case__r.Asset.Industry__c &&
                    !this.installationReportRecord.Industry_Type__c
                ) {
                    this.installationReportRecord = {
                        ...this.installationReportRecord,
                        Industry_Type__c: workOrder.Case__r.Asset.Industry__c
                    };
                }
                
                // Pre-populate Location from Case Region when not already set.
                // This supports backfilling older Installation Reports that may not have this field populated.
                if (
                    workOrder.Case__r.Region__c &&
                    !this.installationReportRecord.Location__c
                ) {
                    this.installationReportRecord = {
                        ...this.installationReportRecord,
                        Location__c: workOrder.Case__r.Region__c
                    };
                }
            }
        } else if (this.reportType === 'ServiceReport') {
            this.serviceReportRecord = serviceReport || {};
            
            // Split Repair Start Time into date and time
            if (this.serviceReportRecord.Repair_Start_Time__c) {
                const startDateTime = new Date(this.serviceReportRecord.Repair_Start_Time__c);
                this.repairStartDate = this.formatDateForInput(startDateTime);
                this.repairStartTime = this.formatTimeForInput(startDateTime);
            }
            
            // Split Repair End Time into date and time
            if (this.serviceReportRecord.Repair_End_Time__c) {
                const endDateTime = new Date(this.serviceReportRecord.Repair_End_Time__c);
                this.repairEndDate = this.formatDateForInput(endDateTime);
                this.repairEndTime = this.formatTimeForInput(endDateTime);
            }
            
            console.log('Service Report loaded - Ink_Part_No__c:', this.serviceReportRecord.Ink_Part_No__c, 'MakeUp_Part_No__c:', this.serviceReportRecord.MakeUp_Part_No__c);

            // Determine if Ink Part No and Make Up Part No should be editable
            // If Ink_Part_No__c or MakeUp_Part_No__c are pre-populated, it means there was a first Service Report
            // Unlike Software No, these fields will be read-only (disabled) when pre-populated
            if (this.serviceReportRecord.Ink_Part_No__c || this.serviceReportRecord.MakeUp_Part_No__c) {
                this.isFirstServiceReport = false;
                console.log('Not first Service Report - Ink Part No:', this.serviceReportRecord.Ink_Part_No__c, 'Make Up Part No:', this.serviceReportRecord.MakeUp_Part_No__c);
            } else {
                this.isFirstServiceReport = true;
                console.log('First Service Report - fields will be editable');
            }

            // Pre-populate Complaint Status from the related Case Status when not already set.
            // This keeps the Service Report complaint status aligned with the Case and
            // supports backfilling older Service Reports that may not have this field populated.
            if (
                workOrder &&
                workOrder.Case__r &&
                workOrder.Case__r.Status &&
                !this.serviceReportRecord.Complaint_Status__c
            ) {
                this.serviceReportRecord = {
                    ...this.serviceReportRecord,
                    Complaint_Status__c: workOrder.Case__r.Status
                };
            }

            // Force reactivity and calculate totals after record is fully loaded
            // Use setTimeout to ensure this happens after all synchronous updates
            // Also log the record to see what fields are available
            console.log('Service Report Record after mapping:', JSON.stringify(this.serviceReportRecord, null, 2));
            console.log('TravelDate__c:', this.serviceReportRecord.TravelDate__c);
            console.log('Date_To__c:', this.serviceReportRecord.Date_To__c);
            
            setTimeout(() => {
                this.serviceReportRecord = { ...this.serviceReportRecord };
                console.log('Service Report Record after spread (300ms):', JSON.stringify(this.serviceReportRecord, null, 2));
                // Calculate totals after record is fully loaded and spread
                // Check if record has the necessary fields before calculating
                if (this.serviceReportRecord && (this.serviceReportRecord.TravelDate__c || this.serviceReportRecord.Date_To__c || 
                    this.serviceReportRecord.Travel_Date_2__c || this.serviceReportRecord.Date_To_2__c ||
                    this.serviceReportRecord.Lodging_Per_Day_1__c || this.serviceReportRecord.Boarding_Per_Day_1__c || 
                    this.serviceReportRecord.Conven__c || this.serviceReportRecord.Lodging_Per_Day_2__c || 
                    this.serviceReportRecord.Boarding_Per_Day_2__c || this.serviceReportRecord.Conveyance_2__c)) {
                    this.calculateTotals();
                    this._hasCalculatedInitialTotals = true;
                } else {
                    console.warn('calculateTotals not called - required fields are missing');
                }
                // Increment version counter to force getter recalculation
                this._recordVersion++;
            }, 500);

        }
    }

    // Helper methods for date/time formatting
    formatDateForInput(dateTime) {
        if (!dateTime) return '';
        const date = new Date(dateTime);
        const year = date.getFullYear();
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const day = String(date.getDate()).padStart(2, '0');
        return `${year}-${month}-${day}`;
    }

    formatTimeForInput(dateTime) {
        if (!dateTime) return '';
        const date = new Date(dateTime);
        const hours = String(date.getHours()).padStart(2, '0');
        const minutes = String(date.getMinutes()).padStart(2, '0');
        return `${hours}:${minutes}`;
    }

    combineDateAndTime(dateStr, timeStr) {
        if (!dateStr || !timeStr) return null;
        // Combine date and time into ISO string format
        const combined = `${dateStr}T${timeStr}:00`;
        return combined;
    }

    determineProductType(materialGroup5) {
        // Reset flags
        this.isCIJ = false;
        this.isTIJ = false;
        this.isTTO = false;
        this.productType = '';

        if (!materialGroup5) {
            return;
        }

        const mg5Upper = materialGroup5.toUpperCase();

        // Check for CIJ (Continuous Inkjet)
        if (mg5Upper.includes('P01')) {
            this.isCIJ = true;
            this.productType = 'CIJ';
        }
        // Check for TIJ (Thermal Inkjet)
        else if (mg5Upper.includes('P03')) {
            this.isTIJ = true;
            this.productType = 'TIJ';
        }
        // Check for TTO (Thermal Transfer Overprinter)
        else if (mg5Upper.includes('P02')) {
            this.isTTO = true;
            this.productType = 'TTO';
        }

        console.log(`Product Type Analysis - Material Group 5: ${materialGroup5}, Type: ${this.productType}`);
    }

    /**
     * Load consumable parts for Ink Part No picklist based on Material Group 5
     */
    loadConsumableParts() {
        if (!this.materialGroup5) {
            this.inkPartNoOptions = [];
            return;
        }
        let mg5Value = '';
        let mg4Value = '';
        if (this.isTIJ) {  
            mg5Value = 'P03';
            mg4Value = 'P03';
        }else if (this.isCIJ) {
            mg5Value = 'P01';
            mg4Value = 'P03';
        }else if (this.isTTO) {
            mg5Value = 'P02';
            mg4Value = 'P03';
        }
        getConsumableParts({ mg5Value: mg5Value, mg4Value: mg4Value })
            .then(result => {
                if (result && Array.isArray(result)) {
                    this.inkPartNoOptions = result;
                    console.log('Loaded consumable parts for MG5:', this.materialGroup5, 'Options:', this.inkPartNoOptions.length);
                } else {
                    this.inkPartNoOptions = [];
                }
            })
            .catch(error => {
                console.error('Error loading consumable parts:', error);
                this.inkPartNoOptions = [];
                showToast(this, 'Warning', 'Could not load consumable parts. You can still enter manually.', 'warning');
            });
    }

    /**
     * Handle click on a visual Service Rating (smiley).
     * Stores a friendly text value (e.g. "Excellent") into Service_Rating__c
     * so it matches typical picklist/text configurations and prints nicely on the PDF.
     * 
     * Allows selecting, changing, or deselecting the service rating.
     * Clicking the same rating that's already selected will deselect it.
     */
    handleServiceRatingClick(event) {
        const value = event.currentTarget?.dataset?.value;
        if (!value || !this.showServiceReport || !this.serviceReportRecord) {
            return;
        }

        const currentRating = this.serviceReportRecord.Service_Rating__c;
        
        // If clicking the same rating that's already selected, deselect it
        if (currentRating && currentRating === value) {
            this.serviceReportRecord = {
                ...this.serviceReportRecord,
                Service_Rating__c: null
            };
            return;
        }

        // Allow selecting a rating if none is selected, or changing to a different rating
        this.serviceReportRecord = {
            ...this.serviceReportRecord,
            Service_Rating__c: value
        };
    }

    get installationServiceRatingScale() {
        // For Installation Report (TIJ)
        const currentRating = this.showInstallationReport && this.installationReportRecord
            ? this.installationReportRecord.Service_Rating__c
            : null;

        // Rating scale based on image: AVG, Good, Very Good, Excellent
        const baseScale = [
            { storedValue: 'AVG', icon: '😐', label: 'AVG' },
            { storedValue: 'Good', icon: '🙂', label: 'Good' },
            { storedValue: 'Very Good', icon: '😊', label: 'Very Good' },
            { storedValue: 'Excellent', icon: '😃', label: 'Excellent' }
        ];

        return baseScale.map(item => {
            const isSelected = item.storedValue === currentRating;
            return {
                ...item,
                cssClass: `rating-icon${isSelected ? ' rating-icon_selected' : ''}`
            };
        });
    }

    handleInstallationServiceRatingClick(event) {
        const value = event.currentTarget?.dataset?.value;
        if (!value || !this.showInstallationReport || !this.installationReportRecord) {
            return;
        }

        const currentRating = this.installationReportRecord.Service_Rating__c;
        
        // If clicking the same rating that's already selected, deselect it
        if (currentRating && currentRating === value) {
            this.installationReportRecord = {
                ...this.installationReportRecord,
                Service_Rating__c: null
            };
            return;
        }

        // Allow selecting a rating if none is selected, or changing to a different rating
        this.installationReportRecord = {
            ...this.installationReportRecord,
            Service_Rating__c: value
        };
    }

    // SERVICE REPORT PARAMETER METHODS
    // Helper method to process service report parameters and add computed properties
    processServiceReportParameters() {
        if (this.serviceReportParameters && Array.isArray(this.serviceReportParameters)) {
            // Filter out expanded rows and get original parameters
            const originalParams = this.serviceReportParameters.filter(p => !p.isPurgingInterval && !p.isPurgingQuantity);
            
            // Also include expanded rows that need to be preserved (they'll be recreated if needed)
            let expandedParams = [];
            
            originalParams.forEach(param => {
                const processedParam = { ...param };
                
                // Initialize Option List Options based on Parameter Name
                processedParam.optionListOptions = this.getOptionListOptions(param.parameterName);
                
                // If selectionOptionList is not set, set it to the first option
                if (!processedParam.selectionOptionList && processedParam.optionListOptions.length > 0) {
                    processedParam.selectionOptionList = processedParam.optionListOptions[0].value;
                }
                
                // Special handling for "Purging auto jet" with Manual: Expand into two rows
                if (processedParam.parameterName === 'Purging auto jet' && processedParam.selectionOptionList === 'Manual') {
                    // Store original key for tracking
                    const originalKey = processedParam.key;
                    
                    // Find existing Interval and Quantity rows to preserve their values
                    const existingInterval = this.serviceReportParameters.find(p => p.key === originalKey + '_Interval');
                    const existingQuantity = this.serviceReportParameters.find(p => p.key === originalKey + '_Quantity');
                    
                    // Create Interval row
                    const intervalParam = {
                        ...processedParam,
                        key: originalKey + '_Interval',
                        originalKey: originalKey,
                        selectedType: 'Interval',
                        selectionValue: existingInterval ? existingInterval.selectionValue : (processedParam.intervalValue || processedParam.selectionValue || ''),
                        isPurgingInterval: true,
                        isPurgingQuantity: false,
                        dynamicOptions: [{ label: 'Interval', value: 'Interval' }],
                        isSelectionTypeDisabled: true,
                        isSelectionValueDisabled: false
                    };
                    this.applyParameterSpecificLogic(intervalParam);
                    expandedParams.push(intervalParam);
                    
                    // Create Quantity row
                    const quantityParam = {
                        ...processedParam,
                        key: originalKey + '_Quantity',
                        originalKey: originalKey,
                        selectedType: 'Quantity',
                        selectionValue: existingQuantity ? existingQuantity.selectionValue : (processedParam.quantityValue || ''),
                        isPurgingInterval: false,
                        isPurgingQuantity: true,
                        dynamicOptions: [{ label: 'Quantity', value: 'Quantity' }],
                        isSelectionTypeDisabled: true,
                        isSelectionValueDisabled: false
                    };
                    this.applyParameterSpecificLogic(quantityParam);
                    expandedParams.push(quantityParam);
                } else {
                    // Update dynamicOptions (Selection Type options) based on Option List selection
                    processedParam.dynamicOptions = this.getSelectionTypeOptions(param.parameterName, processedParam.selectionOptionList);
                    
                    // Handle parameter-specific logic
                    this.applyParameterSpecificLogic(processedParam);
                    
                    expandedParams.push(processedParam);
                }
            });
            
            // Force reactivity by creating new array reference
            this.serviceReportParameters = [...expandedParams];
        }
    }

    getOptionListOptions(parameterName) {
        const optionListMap = {
            'Print head Firing Voltage': [
                { label: 'Auto', value: 'Auto' },
                { label: 'Manual', value: 'Manual' }
            ],
            'Pulse Value': [
                { label: 'N/A', value: 'N/A' }
            ],
            'Auto jet setting': [
                { label: 'Auto', value: 'Auto' },
                { label: 'Manual', value: 'Manual' }
            ],
            'Nozzle Select': [
                { label: 'Splice', value: 'Splice' },
                { label: 'Head', value: 'Head' }
            ],
            'Purging auto jet': [
                { label: 'Auto', value: 'Auto' },
                { label: 'Manual', value: 'Manual' }
            ],
            'DPI X': [
                { label: 'N/A', value: 'N/A' }
            ],
            'DPI Y': [
                { label: 'N/A', value: 'N/A' }
            ],
            'DPI -Y': [
                { label: 'N/A', value: 'N/A' }
            ],
            'Printhead Delay': [
                { label: 'N/A', value: 'N/A' }
            ],
            'Trigger Mode': [
                { label: 'External', value: 'External' },
                { label: 'Internal', value: 'Internal' }
            ],
            'Continuous print': [
                { label: 'Close', value: 'Close' },
                { label: 'Times', value: 'Times' }
            ],
            'Photocell setting': [
                { label: 'Beep', value: 'Beep' },
                { label: 'Signal shielding', value: 'Signal shielding' }
            ],
            'Encoder setting': [
                { label: 'Yes', value: 'Yes' },
                { label: 'No', value: 'No' }
            ]
        };
        return optionListMap[parameterName] || [];
    }

    getSelectionTypeOptions(parameterName, optionListValue) {
        // For most parameters, Selection Type matches Option List
        if (parameterName === 'Purging auto jet') {
            if (optionListValue === 'Auto') {
                return [{ label: 'Auto', value: 'Auto' }];
            } else if (optionListValue === 'Manual') {
                return [
                    { label: 'Interval', value: 'Interval' },
                    { label: 'Quantity', value: 'Quantity' }
                ];
            }
        } else if (parameterName === 'Nozzle Select') {
            // For Nozzle Select, Selection Type options are always 1-4 regardless of Option List
            // The Option List (Splice/Head) determines whether to show dropdown or input
            return [
                        { label: '1', value: '1' },
                        { label: '2', value: '2' },
                        { label: '3', value: '3' },
                        { label: '4', value: '4' }
                    ];
        } else if (parameterName === 'Encoder setting') {
            if (optionListValue === 'Yes') {
                return [
                    { label: 'Yes', value: 'Yes' },
                    { label: 'No', value: 'No' }
                ];
            } else if (optionListValue === 'No') {
                return [{ label: 'N/A', value: 'N/A' }];
            }
        } else if (parameterName === 'Photocell setting') {
            // Multiselect - return both options
            return [
                { label: 'Beep', value: 'Beep' },
                { label: 'Signal Shielding', value: 'Signal Shielding' }
                    ];
                } else {
            // For most parameters, Selection Type matches Option List
            return this.getOptionListOptions(parameterName);
        }
        return [];
    }

    applyParameterSpecificLogic(param) {
        const paramName = param.parameterName;
        
        // Reset all flags
        param.isNozzleSelectSplice = false;
        param.isNozzleSelectHead = false;
        param.isPhotocellSetting = false;
        param.isRegularParameter = true;
        param.isSelectionValueDisabled = false;
        param.isSelectionTypeDisabled = false;
        param.valueOptions = [];
        param.selectionValueArray = [];

        // 1. Print head Firing Voltage
        if (paramName === 'Print head Firing Voltage') {
            if (param.selectedType === 'Auto') {
                param.selectionValue = 'NA';
                param.isSelectionValueDisabled = true;
            } else if (param.selectedType === 'Manual') {
                param.isSelectionValueDisabled = false;
            }
        }
        // 2. Pulse Value
        else if (paramName === 'Pulse Value') {
            param.isSelectionValueDisabled = false;
        }
        // 3. Auto jet setting
        else if (paramName === 'Auto jet setting') {
            if (param.selectedType === 'Auto') {
                param.selectionValue = 'NA';
                param.isSelectionValueDisabled = true;
            } else if (param.selectedType === 'Manual') {
                param.isSelectionValueDisabled = false;
            }
        }
        // 4. Nozzle Select
        else if (paramName === 'Nozzle Select') {
            param.isRegularParameter = false;
            param.valueOptions = [
                { label: '1', value: '1' },
                { label: '2', value: '2' },
                { label: '3', value: '3' },
                { label: '4', value: '4' }
            ];
            // Selection Type options are always 1-4
            param.dynamicOptions = [
                { label: '1', value: '1' },
                { label: '2', value: '2' },
                { label: '3', value: '3' },
                { label: '4', value: '4' }
            ];
            if (param.selectionOptionList === 'Splice') {
                param.isNozzleSelectSplice = true;
            } else if (param.selectionOptionList === 'Head') {
                param.isNozzleSelectHead = true;
            }
        }
        // 5. Purging auto jet
        else if (paramName === 'Purging auto jet') {
            if (param.selectionOptionList === 'Auto') {
                param.selectedType = 'Auto';
                param.isSelectionTypeDisabled = true;
                param.selectionValue = 'NA';
                param.isSelectionValueDisabled = true;
            } else if (param.selectionOptionList === 'Manual') {
                param.isSelectionTypeDisabled = false;
                param.isSelectionValueDisabled = false;
            }
        }
        // 6-8. DPI X, DPI Y, DPI -Y, Printhead Delay
        else if (['DPI X', 'DPI Y', 'DPI -Y', 'Printhead Delay'].includes(paramName)) {
            param.isSelectionValueDisabled = false;
        }
        // 9. Trigger Mode
        else if (paramName === 'Trigger Mode') {
            // Selection Type should match Option List
            if (param.selectionOptionList && !param.selectedType) {
                param.selectedType = param.selectionOptionList;
            }
            param.isSelectionValueDisabled = false;
        }
        // 10. Continuous print
        else if (paramName === 'Continuous print') {
            // Selection Type should match Option List
            if (param.selectionOptionList && !param.selectedType) {
                param.selectedType = param.selectionOptionList;
            }
            if (param.selectedType === 'Close') {
                param.isSelectionValueDisabled = true;
            } else if (param.selectedType === 'Times') {
                param.isSelectionValueDisabled = false;
            }
        }
        // 11. Photocell setting
        else if (paramName === 'Photocell setting') {
            param.isRegularParameter = false;
            param.isPhotocellSetting = true;
            param.isSelectionValueDisabled = true;
            // Convert selectionValue string to array for dual-listbox
            if (param.selectionValue) {
                param.selectionValueArray = Array.isArray(param.selectionValue) 
                    ? param.selectionValue 
                    : param.selectionValue.split(';').filter(v => v);
            } else {
                param.selectionValueArray = [];
            }
            param.valueOptions = [
                { label: 'Beep', value: 'Beep' },
                { label: 'Signal Shielding', value: 'Signal Shielding' }
            ];
        }
        // 12. Encoder setting
        else if (paramName === 'Encoder setting') {
            if (param.selectionOptionList === 'Yes') {
                param.isSelectionValueDisabled = false;
            } else if (param.selectionOptionList === 'No') {
                param.selectedType = 'N/A';
                param.isSelectionTypeDisabled = true;
                param.isSelectionValueDisabled = true;
            }
        }
    }

    async loadServiceReportParameters() {
        if (!this.serviceReportRecord.Id) {
            console.log('No Service Report ID available yet, using default parameters');
            this.initializeDefaultParameters();
            return;
        }

        try {
            this.showSpinner = true;
            const existingParams = await getServiceReportParameters({
                serviceReportId: this.serviceReportRecord.Id
            });

            console.log('Loaded parameters from server:', JSON.stringify(existingParams, null, 2));

            if (existingParams && existingParams.length > 0) {
                // First, combine "Purging auto jet" records with Interval and Quantity
                const combinedParams = [];
                const purgingParams = existingParams.filter(p => p.parameterName === 'Purging auto jet');
                const otherParams = existingParams.filter(p => p.parameterName !== 'Purging auto jet');
                
                if (purgingParams.length > 0) {
                    // Find Interval and Quantity records
                    const intervalParam = purgingParams.find(p => p.selectedType === 'Interval');
                    const quantityParam = purgingParams.find(p => p.selectedType === 'Quantity');
                    const autoParam = purgingParams.find(p => p.selectedType === 'Auto');
                    
                    if (intervalParam && quantityParam) {
                        // Combine into one parameter with both values
                        const combinedParam = {
                            ...intervalParam,
                            intervalValue: intervalParam.selectionValue || '',
                            quantityValue: quantityParam.selectionValue || '',
                            selectionOptionList: intervalParam.selectionOptionList || 'Manual'
                        };
                        combinedParams.push(combinedParam);
                    } else if (autoParam) {
                        // Single Auto parameter
                        combinedParams.push(autoParam);
                    } else if (purgingParams.length > 0) {
                        // Fallback: use first one
                        combinedParams.push(purgingParams[0]);
                    }
                }
                
                // Combine with other parameters
                const allParams = [...combinedParams, ...otherParams];
                
                // Directly use the parameters from server - they already have the correct structure
                this.serviceReportParameters = allParams.map(param => {
                    const mappedParam = {
                    key: param.key || this.generateUniqueKey(),
                    parameterName: param.parameterName,
                        selectionOptionList: param.selectionOptionList || '',
                    selectedType: param.selectedType || '',
                    selectionValue: param.selectionValue || '',
                    dynamicOptions: param.dynamicOptions || []
                    };
                    
                    // Store intervalValue and quantityValue for Purging auto jet
                    if (param.parameterName === 'Purging auto jet' && param.intervalValue !== undefined) {
                        mappedParam.intervalValue = param.intervalValue;
                    }
                    if (param.parameterName === 'Purging auto jet' && param.quantityValue !== undefined) {
                        mappedParam.quantityValue = param.quantityValue;
                    }
                    
                    // Always set valueOptions for Nozzle Select parameter
                    if (param.parameterName === 'Nozzle Select') {
                        mappedParam.valueOptions = param.valueOptions || [
                            { label: '1', value: '1' },
                            { label: '2', value: '2' },
                            { label: '3', value: '3' },
                            { label: '4', value: '4' }
                        ];
                    }
                    // Handle Photocell setting multiselect
                    if (param.parameterName === 'Photocell setting' && param.selectionValue) {
                        mappedParam.selectionValueArray = Array.isArray(param.selectionValue) 
                            ? param.selectionValue 
                            : param.selectionValue.split(';').filter(v => v);
                    }
                    return mappedParam;
                });
                // Process parameters to add computed properties
                this.processServiceReportParameters();
                console.log('Mapped parameters after load:', JSON.stringify(this.serviceReportParameters, null, 2));
            } else {
                console.log('No existing parameters found, using defaults');
                this.initializeDefaultParameters();
            }
        } catch (error) {
            console.error('Error loading parameters:', error);
            showToast(this, 'Error', 'Failed to load parameters', 'error');
            // Fallback to default parameters
            this.initializeDefaultParameters();
        } finally {
            this.showSpinner = false;
        }
    }

    initializeDefaultParameters() {
        this.serviceReportParameters = [
            {
                key: '1',
                parameterName: 'Print head Firing Voltage',
                selectionOptionList: 'Auto',
                selectedType: 'Auto',
                selectionValue: 'NA',
                dynamicOptions: [
                    { label: 'Auto', value: 'Auto' },
                    { label: 'Manual', value: 'Manual' }
                ]
            },
            {
                key: '2',
                parameterName: 'Pulse Value',
                selectionOptionList: 'N/A',
                selectedType: 'N/A',
                selectionValue: '',
                dynamicOptions: [
                    { label: 'N/A', value: 'N/A' }
                ]
            },
            {
                key: '3',
                parameterName: 'Auto jet setting',
                selectionOptionList: 'Auto',
                selectedType: 'Auto',
                selectionValue: 'NA',
                dynamicOptions: [
                    { label: 'Auto', value: 'Auto' },
                    { label: 'Manual', value: 'Manual' }
                ]
            },
            {
                key: '4',
                parameterName: 'Nozzle Select',
                selectionOptionList: 'Splice',
                selectedType: '1',
                selectionValue: '1',
                dynamicOptions: [
                    { label: '1', value: '1' },
                    { label: '2', value: '2' },
                    { label: '3', value: '3' },
                    { label: '4', value: '4' }
                ],
                valueOptions: [
                    { label: '1', value: '1' },
                    { label: '2', value: '2' },
                    { label: '3', value: '3' },
                    { label: '4', value: '4' }
                ]
            },
            {
                key: '5',
                parameterName: 'Purging auto jet',
                selectionOptionList: 'Auto',
                selectedType: 'Auto',
                selectionValue: 'NA',
                dynamicOptions: [
                    { label: 'Auto', value: 'Auto' }
                ]
            },
            {
                key: '6',
                parameterName: 'DPI X',
                selectionOptionList: 'N/A',
                selectedType: 'N/A',
                selectionValue: '',
                dynamicOptions: [
                    { label: 'N/A', value: 'N/A' }
                ]
            },
            {
                key: '7',
                parameterName: 'DPI Y',
                selectionOptionList: 'N/A',
                selectedType: 'N/A',
                selectionValue: '',
                dynamicOptions: [
                    { label: 'N/A', value: 'N/A' }
                ]
            },
            {
                key: '8',
                parameterName: 'Printhead Delay',
                selectionOptionList: 'N/A',
                selectedType: 'N/A',
                selectionValue: '',
                dynamicOptions: [
                    { label: 'N/A', value: 'N/A' }
                ]
            },
            {
                key: '9',
                parameterName: 'Trigger Mode',
                selectionOptionList: 'External',
                selectedType: 'External',
                selectionValue: '',
                dynamicOptions: [
                    { label: 'External', value: 'External' },
                    { label: 'Internal', value: 'Internal' }
                ]
            },
            {
                key: '10',
                parameterName: 'Continuous print',
                selectionOptionList: 'Close',
                selectedType: 'Close',
                selectionValue: '',
                dynamicOptions: [
                    { label: 'Close', value: 'Close' },
                    { label: 'Times', value: 'Times' }
                ]
            },
            {
                key: '11',
                parameterName: 'Photocell setting',
                selectionOptionList: 'Beep',
                selectedType: 'Beep',
                selectionValue: 'Beep',
                selectionValueArray: ['Beep'],
                dynamicOptions: [
                    { label: 'Beep', value: 'Beep' },
                    { label: 'Signal Shielding', value: 'Signal Shielding' }
                ],
                valueOptions: [
                    { label: 'Beep', value: 'Beep' },
                    { label: 'Signal Shielding', value: 'Signal Shielding' }
                ]
            },
            {
                key: '12',
                parameterName: 'Encoder setting',
                selectionOptionList: 'Yes',
                selectedType: 'Yes',
                selectionValue: '',
                dynamicOptions: [
                    { label: 'Yes', value: 'Yes' },
                    { label: 'No', value: 'No' }
                ]
            }
        ];
        // Process parameters to add computed properties for conditional rendering
        this.processServiceReportParameters();
    }

    generateUniqueKey() {
        return 'param-' + Date.now() + '-' + Math.random().toString(36).substr(2, 9);
    }

    handleParameterChange(event) {
        const index = event.currentTarget.dataset.index;
        const field = event.currentTarget.dataset.field;
        const value = event.detail.value;

        console.log(`Parameter change - Index: ${index}, Field: ${field}, Value: ${value}`);

        if (this.serviceReportParameters[index]) {
            // Create a new object to maintain reactivity
            let updatedParam = { ...this.serviceReportParameters[index] };
            updatedParam[field] = value;

            // Handle Option List changes - cascade to Selection Type and Value
            if (field === 'selectionOptionList') {
                const paramName = updatedParam.parameterName;
                
                // Special handling for "Purging auto jet" - reconstruct original and update
                if (paramName === 'Purging auto jet' && (updatedParam.isPurgingInterval || updatedParam.isPurgingQuantity)) {
                    // Find the original key
                    const originalKey = updatedParam.originalKey || updatedParam.key.replace(/_Interval|_Quantity/, '');
                    
                    // Find both Interval and Quantity rows
                    const intervalRow = this.serviceReportParameters.find(p => p.key === originalKey + '_Interval');
                    const quantityRow = this.serviceReportParameters.find(p => p.key === originalKey + '_Quantity');
                    
                    // Reconstruct original parameter
                    const originalParam = {
                        ...updatedParam,
                        key: originalKey,
                        selectionOptionList: value,
                        intervalValue: intervalRow ? intervalRow.selectionValue : '',
                        quantityValue: quantityRow ? quantityRow.selectionValue : '',
                        isPurgingInterval: false,
                        isPurgingQuantity: false
                    };
                    
                    // Remove expanded rows and add original back
                    this.serviceReportParameters = this.serviceReportParameters.filter(p => 
                        p.key !== originalKey + '_Interval' && p.key !== originalKey + '_Quantity'
                    );
                    
                    // Find the index where this parameter should be (based on original key)
                    const paramIndex = this.serviceReportParameters.findIndex(p => p.key === originalKey);
                    if (paramIndex >= 0) {
                        this.serviceReportParameters[paramIndex] = originalParam;
                    } else {
                        // If not found, find a "Purging auto jet" parameter and replace it
                        const purgingIndex = this.serviceReportParameters.findIndex(p => p.parameterName === 'Purging auto jet' && !p.isPurgingInterval && !p.isPurgingQuantity);
                        if (purgingIndex >= 0) {
                            this.serviceReportParameters[purgingIndex] = originalParam;
                        } else {
                            // Add it if not found
                            this.serviceReportParameters.push(originalParam);
                        }
                    }
                    
                    // Force reactivity and re-process
                    this.serviceReportParameters = [...this.serviceReportParameters];
                    this.processServiceReportParameters();
                    return; // Exit early since we've handled everything
                }
                
                // Update Selection Type options based on new Option List
                updatedParam.dynamicOptions = this.getSelectionTypeOptions(paramName, value);
                
                // Handle parameter-specific Option List changes
                if (paramName === 'Purging auto jet') {
                    if (value === 'Auto') {
                        updatedParam.selectedType = 'Auto';
                        updatedParam.selectionValue = 'NA';
                    } else if (value === 'Manual') {
                        updatedParam.selectedType = 'Interval'; // Default to Interval
                        updatedParam.selectionValue = '';
                    }
                } else if (paramName === 'Trigger Mode' || paramName === 'Continuous print') {
                    // Selection Type should match Option List
                    updatedParam.selectedType = value;
                    if (paramName === 'Continuous print' && value === 'Close') {
                        updatedParam.selectionValue = '';
                    } else if (paramName === 'Continuous print' && value === 'Times') {
                        updatedParam.selectionValue = '';
                    }
                } else if (paramName === 'Encoder setting') {
                    if (value === 'No') {
                        updatedParam.selectedType = 'N/A';
                        updatedParam.selectionValue = '';
                    } else if (value === 'Yes') {
                        updatedParam.selectedType = 'Yes';
                        updatedParam.selectionValue = '';
                    }
                } else if (paramName === 'Print head Firing Voltage' || paramName === 'Auto jet setting') {
                    // Reset Selection Type to match Option List
                    updatedParam.selectedType = value;
                    if (value === 'Auto') {
                        updatedParam.selectionValue = 'NA';
                    } else {
                        updatedParam.selectionValue = '';
                    }
                }
            }
            
            // Handle Selection Type changes
                if (field === 'selectedType') {
                const paramName = updatedParam.parameterName;
                
                // Handle Auto/Manual logic
                if (value === 'Auto' && (paramName === 'Print head Firing Voltage' || paramName === 'Auto jet setting')) {
                    updatedParam.selectionValue = 'NA';
                } else if (value === 'Manual' && (paramName === 'Print head Firing Voltage' || paramName === 'Auto jet setting')) {
                    updatedParam.selectionValue = '';
                }
                
                // Handle Continuous print
                if (paramName === 'Continuous print') {
                    if (value === 'Close') {
                        updatedParam.selectionValue = '';
                    } else if (value === 'Times') {
                        updatedParam.selectionValue = '';
                    }
                }
                
                // Handle Nozzle Select - when Option List changes, update Selection Type options
                if (paramName === 'Nozzle Select') {
                    // Selection Type options are always 1-4
                    updatedParam.dynamicOptions = [
                        { label: '1', value: '1' },
                        { label: '2', value: '2' },
                        { label: '3', value: '3' },
                        { label: '4', value: '4' }
                    ];
                    // Ensure Selection Type and Value are valid
                    if (!updatedParam.selectedType || !['1', '2', '3', '4'].includes(updatedParam.selectedType)) {
                        updatedParam.selectedType = '1';
                    }
                    if (!updatedParam.selectionValue || !['1', '2', '3', '4'].includes(updatedParam.selectionValue)) {
                        updatedParam.selectionValue = '1';
                    }
                }
            }
            
            // Handle Selection Value changes for Photocell setting (multiselect)
            if (field === 'selectionValue' && updatedParam.parameterName === 'Photocell setting') {
                // Convert array to semicolon-separated string for storage
                if (Array.isArray(value)) {
                    updatedParam.selectionValue = value.join(';');
                    updatedParam.selectionValueArray = value;
                }
            }

            // Update the array
            this.serviceReportParameters[index] = updatedParam;

            // Force reactivity by creating new array
            this.serviceReportParameters = [...this.serviceReportParameters];
            
            // Process parameters to update computed properties
            this.processServiceReportParameters();

            console.log('Updated parameter:', updatedParam);
        }
    }

    handleInstallationParameterChange(event) {
        const index = event.currentTarget.dataset.index;
        const field = event.currentTarget.dataset.field;
        const value = event.detail.value;

        console.log(`Installation Parameter change - Index: ${index}, Field: ${field}, Value: ${value}`);

        if (this.installationReportParameters && this.installationReportParameters[index]) {
            // Create a new object to maintain reactivity
            let updatedParam = { ...this.installationReportParameters[index] };
            updatedParam[field] = value;

            // Update the array
            this.installationReportParameters[index] = updatedParam;

            // Force reactivity by creating new array
            this.installationReportParameters = [...this.installationReportParameters];

            console.log('Updated installation parameter:', updatedParam);
        }
    }

    async handleServiceReportSave(event) {
        //showToast(this, 'Error', '1-Service report data is not available', 'error');
        // Prevent default form submission
        if (event) {
            event.preventDefault();
        }
        //showToast(this, 'Error', '2-Service report data is not available', 'error');
        // Add null checks to prevent script errors
        if (!this.serviceReportRecord) {
            showToast(this, 'Error', 'Service report data is not available', 'error');
            this.showSpinner = false;
            return;
        }
        //showToast(this, 'Error', '3-Service report data is not available', 'error');
        let isValid = true;
        //showToast(this, 'Error', '4-Service report data is not available', 'error');
        // Validate required fields
        const requiredFields = ['SR_Start_Date__c', 'SR_End_Date__c', 'Customer_Problem_Statement__c'];
        //showToast(this, 'Error', '5-Service report data is not available', 'error');
        requiredFields.forEach(field => {
            if (!this.serviceReportRecord[field]) {
                //showToast(this, 'Error', '6-Service report data is not available', 'error');
                showToast(this, 'Error', `${field.replace('__c', '').replace(/_/g, ' ')} is required`, 'error');
                isValid = false;
            }
        });
        //showToast(this, 'Error', '7-Service report data is not available', 'error');
        // Validate Capture Signature fields for TTO Service Reports
        if (this.isTTO) {
            if (!this.serviceReportRecord.Signature__c || 
                !this.serviceReportRecord.Signature_by__c || 
                !this.serviceReportRecord.Customer_Contact_Number__c || 
                !this.serviceReportRecord.Customer_Email__c || 
                !this.serviceReportRecord.Customer_Designation__c) {
                showToast(this, 'Error', 'All signature fields are required. Please capture the signature with all details (Contact Number, Email, and Designation) before saving.', 'error');
                isValid = false;
            }
        }
        //showToast(this, 'Error', '8-Service report data is not available', 'error');
        if (!isValid) {
            this.showSpinner = false;
            return;
        }
        //showToast(this, 'Error', '9-Service report data is not available', 'error');
        // Validate Pump Run Hours: must be greater than previous Service Reports for the same Case
        if (this.serviceReportRecord.Pump_Run_Hours__c != null && this.serviceReportRecord.Case__c) {
            try {
                const maxPreviousValue = await getMaxPumpRunHoursForCase({
                    caseId: this.serviceReportRecord.Case__c,
                    currentServiceReportId: this.serviceReportRecord.Id || null
                });
                
                if (maxPreviousValue != null && this.serviceReportRecord.Pump_Run_Hours__c <= maxPreviousValue) {
                    showToast(this, 'Error', `Pump Run Hours (${this.serviceReportRecord.Pump_Run_Hours__c}) must be greater than the previous value (${maxPreviousValue}) from previous Service Reports for this Case.`, 'error');
                    this.showSpinner = false;
                    return;
                }
            } catch (error) {
                console.error('Error validating Pump Run Hours:', error);
                // Continue with save - server-side validation will catch it
            }
        }

        // Validate Spare Replaced: if YES, check if there are spare requests on the Case
        if (this.serviceReportRecord.Spare_Replaced__c === 'Yes' && this.serviceReportRecord.Case__c) {
            try {
                const hasSpareRequests = await hasSpareRequestsForCase({
                    caseId: this.serviceReportRecord.Case__c
                });
                
                if (!hasSpareRequests) {
                    showToast(this, 'Error', 'Spare Replaced is selected as YES, but there are no Spare Requests on the related Case. Please create Spare Requests before saving.', 'error');
                    this.showSpinner = false;
                    return;
                }
            } catch (error) {
                console.error('Error validating Spare Replaced:', error);
                showToast(this, 'Error', 'Error validating Spare Replaced field. Please try again.', 'error');
                this.showSpinner = false;
                return;
            }
        }
        //showToast(this, 'Error', '10-Service report data is not available', 'error');

        // Validate all numeric range fields
        const numericFieldValidations = [
            { name: 'Visc_Set_Point__c', min: 12, max: 60, label: 'Visc Set Point' },
            { name: 'Visc_Actual__c', min: 12, max: 60, label: 'Visc Actual' },
            { name: 'Ink_Temp__c', min: 3, max: 55, label: 'Ink Temp' },
            { name: 'Cabinet_Temp__c', min: 5, max: 60, label: 'Cabinet Temp' },
            { name: 'Head_Temp__c', min: 0, max: 45, label: 'Head Temp' },
            { name: 'Heater_Point__c', min: 0, max: 45, label: 'Heater Point' },
            { name: 'Modulation__c', min: 0, max: 100, label: 'Modulation' },
            { name: 'Charge_Value__c', min: 110, max: 220, label: 'Charge Value' },
            { name: 'EHT_Range_Min__c', min: 110, max: 150, label: 'EHT Range Min' },
            { name: 'EHT_Range_Max__c', min: 160, max: 250, label: 'EHT Range Max' },
            { name: 'Print_Head_Resistance__c', min: 0, max: 9999, label: 'Print Head Resistance' },
            { name: 'Ribbon_Dia_D1__c', min: 1, max: 200, label: 'Ribbon Dia D1' },
            { name: 'Ribbon_Dia_D2__c', min: 1, max: 200, label: 'Ribbon Dia D2' },
            { name: 'Print_Speed__c', min: 40, max: 800, label: 'Print Speed' },
            { name: 'Ribbon_Fail_Count__c', min: 0, max: 244, label: 'Ribbon Fail Count' },
            { name: 'Registration_Dot__c', min: 0, max: 384, label: 'Registration Dot' },
            { name: 'Debounce_Time__c', min: 0, max: 1000, label: 'Debounce Time' },
            { name: 'Print_Delay__c', min: 0, max: 5000, label: 'Print Delay' },
            { name: 'PR_GO_Ignore__c', min: 0, max: 5000, label: 'PR-GO Ignore' },
            { name: 'Ribbon_Gap__c', min: -80, max: 150, label: 'Ribbon Gap' },
            { name: 'Output_Air_Pressure__c', min: 1, max: 8, label: 'Output Air Pressure' },
            { name: 'Head_Out_Time__c', min: 0, max: 1000, label: 'Head Out Time' },
            { name: 'Head_In_Time__c', min: 0, max: 200, label: 'Head In Time' },
            { name: 'Start_Border_Trim__c', min: 0, max: 20, label: 'Start Border Trim' },
            { name: 'End_Border_Trim__c', min: 0, max: 20, label: 'End Border Trim' },
            { name: 'Darkness__c', min: 0, max: 120, label: 'Darkness' }
        ];

        // Collect all validation errors first, then show inline errors and single toast
        // Use setTimeout to ensure DOM is ready
        await new Promise(resolve => setTimeout(resolve, 0));
        
        // Clear previous validation errors
        this.fieldValidationErrors = {};
        
        // Get the form element to trigger validation
        const formElement = this.template.querySelector('lightning-record-edit-form');
        //showToast(this, 'Error', '11-Service report data is not available', 'error');
        numericFieldValidations.forEach(fieldConfig => {
            if (this.serviceReportRecord[fieldConfig.name] !== null && 
                this.serviceReportRecord[fieldConfig.name] !== undefined && 
                this.serviceReportRecord[fieldConfig.name] !== '') {
                const fieldValue = parseFloat(this.serviceReportRecord[fieldConfig.name]);
                if (!isNaN(fieldValue) && (fieldValue < fieldConfig.min || fieldValue > fieldConfig.max)) {
                    const errorMessage = `${fieldConfig.label} must be between ${fieldConfig.min} and ${fieldConfig.max}`;
                    
                    // Store error message in reactive property for display in HTML
                    this.fieldValidationErrors[fieldConfig.name] = errorMessage;
                    //showToast(this, 'Error', '12-Service report data is not available', 'error');
                    // Find the field element and try to set validation
                    const fieldElement = this.template.querySelector(`lightning-input-field[field-name="${fieldConfig.name}"]`);
                    const inputElement = this.template.querySelector(`lightning-input[name="${fieldConfig.name}"]`);
                    //showToast(this, 'Error', '13-Service report data is not available', 'error');
                    if (fieldElement) {
                        try {
                            // Try to set custom validity on the field
                            if (typeof fieldElement.setCustomValidity === 'function') {
                                fieldElement.setCustomValidity(errorMessage);
                                fieldElement.reportValidity();
                                //showToast(this, 'Error', '14-Service report data is not available', 'error');
                            } else {
                                // Try to access the underlying input element through shadow DOM
                                const input = fieldElement.shadowRoot?.querySelector('input');
                                if (input) {
                                    input.setCustomValidity(errorMessage);
                                    input.reportValidity();
                                    //showToast(this, 'Error', '15-Service report data is not available', 'error');
                                } else {
                                    // Fallback: at least report validity
                                    if (typeof fieldElement.reportValidity === 'function') {
                                        fieldElement.reportValidity();
                                        //showToast(this, 'Error', '16-Service report data is not available', 'error');
                                    }
                                }
                            }
                        } catch (err) {
                            console.error(`Error setting validation for ${fieldConfig.name}:`, err);
                            // Fallback: at least report validity
                            if (typeof fieldElement.reportValidity === 'function') {
                                fieldElement.reportValidity();
                            }
                        }
                    } else if (inputElement) {
                        // For lightning-input, setCustomValidity should work
                        try {
                            if (typeof inputElement.setCustomValidity === 'function') {
                                inputElement.setCustomValidity(errorMessage);
                                inputElement.reportValidity();
                            }
                        } catch (err) {
                            console.error(`Error setting validation for ${fieldConfig.name}:`, err);
                        }
                    }
            isValid = false;
                } else {
                    // Clear error if value is valid
                    if (this.fieldValidationErrors[fieldConfig.name]) {
                        delete this.fieldValidationErrors[fieldConfig.name];
                    }
                }
            } else {
                // Clear error if field is empty
                if (this.fieldValidationErrors[fieldConfig.name]) {
                    delete this.fieldValidationErrors[fieldConfig.name];
                }
            }
        });
        //showToast(this, 'Error', '17-Service report data is not available', 'error');
        // Also trigger validation on the form to ensure all fields show their errors
        if (formElement && typeof formElement.reportValidity === 'function') {
            formElement.reportValidity();
        }

        //showToast(this, 'Error', '17.1', 'error');
        // Show single toast message if there are any validation errors
        if (!isValid) {
            showToast(this, 'Error', 'Error occurred while saving records', 'error');
        }
        //showToast(this, 'Error', '17.2', 'error');

        if (!isValid) {
            this.showSpinner = false;
            if (event) {
                event.stopPropagation();
            }
            return;
        }
        //showToast(this, 'Error', '17.3', 'error');
        this.showSpinner = true;
        //showToast(this, 'Error', '17.4', 'error');

        try {
            // Combine date and time into DateTime before saving
            //if (this.repairStartDate && this.repairStartTime) {
            //    this.serviceReportRecord.Repair_Start_Time__c = this.combineDateAndTime(this.repairStartDate, this.repairStartTime);
            //}
            //if (this.repairEndDate && this.repairEndTime) {
            //    this.serviceReportRecord.Repair_End_Time__c = this.combineDateAndTime(this.repairEndDate, this.repairEndTime);
            //}
            //showToast(this, 'Error', '18-Service report data is not available', 'error');
            debugger;
            console.log('Current report parameters:', JSON.stringify(this.currentReportParameters));
            const result = await saveServiceReport({
                serviceReportRecord: this.serviceReportRecord,
                workOrderId: this.workOrderId,
                serviceAppointmentId: this.serviceAppointmentId,
                currentReportParameters: JSON.stringify(this.currentReportParameters)
            });
            //showToast(this, 'Error', '19-Service report data is not available', 'error');
            if (result) {
                this.serviceReportRecord = { ...this.serviceReportRecord, ...result };
                this.serviceReportRecord.IsSavedByUser__c = true;
                this.recordId = this.serviceReportRecord.Id;

                // Save parameters after service report is saved
               // await this.saveServiceReportParameters();

                showToast(this, 'Success', 'Service report saved successfully', 'success');

                // Reload parameters to refresh the UI with saved data
                await this.loadServiceReportParameters();
            }
        } catch (error) {
            // Extract detailed error message
            let errorMessage = 'Failed to save service report';
            
            if (error.body) {
                // AuraHandledException from Apex
                if (error.body.message) {
                    errorMessage = error.body.message;
                } 
                // DML Exception with field errors
                else if (error.body.fieldErrors) {
                    const fieldErrors = Object.keys(error.body.fieldErrors).map(field => {
                        const fieldLabel = field.replace('__c', '').replace(/_/g, ' ');
                        return fieldLabel + ': ' + error.body.fieldErrors[field][0].message;
                    });
                    errorMessage = fieldErrors.join('; ');
                }
                // Page errors
                else if (error.body.pageErrors && error.body.pageErrors.length > 0) {
                    errorMessage = error.body.pageErrors[0].message;
                }
                // Output errors
                else if (error.body.output && error.body.output.errors && error.body.output.errors.length > 0) {
                    errorMessage = error.body.output.errors[0].message;
                }
            } else if (error.message) {
                errorMessage = error.message;
            }
            
            showToast(this, 'Error', errorMessage, 'error');
        } finally {
            this.showSpinner = false;
        }
    }

    async saveServiceReportParameters() {
        if (!this.serviceReportRecord.Id) {
            console.error('Service Report ID is required to save parameters');
            return;
        }

        try {
            const paramsToSave = this.serviceReportParameters.map((param, index) => ({
                Name: param.parameterName,
                Service_Report__c: this.serviceReportRecord.Id,
                Selected_Type__c: param.selectedType || '',
                Selection_Value__c: param.selectionValue || '',
                Display_Order__c: index + 1,
                Selection_Options_List__c: param.selectionOptionList || ''
            }));

            console.log('Saving parameters:', JSON.stringify(paramsToSave, null, 2));

          //c/captureSignaturePad  await saveServiceReportParameters({ parameters: paramsToSave });
            console.log('Parameters saved successfully');
        } catch (error) {
            console.error('Error saving parameters:', error);
            showToast(this, 'Error', 'Failed to save parameters', 'error');
        }
    }

    getOptionsString(options) {
        if (!options || !Array.isArray(options)) return '';
        return options.map(opt => opt.value).join(';');
    }

    // Handlers for Repair Start/End date and time
    handleRepairStartDateChange(event) {
        this.repairStartDate = event.target.value;
    }

    handleRepairStartTimeChange(event) {
        this.repairStartTime = event.target.value;
    }

    handleRepairEndDateChange(event) {
        this.repairEndDate = event.target.value;
    }

    handleRepairEndTimeChange(event) {
        this.repairEndTime = event.target.value;
    }

    // COMMON METHODS
    handleChange(event) {
        debugger;
        const { name, value } = getNameAndValueOnChange(this, event);

        // Validate Next Visit Proposed Date - must be a future date (after today)
        if (name === 'Next_Visit_Proposed_Date__c' && value) {
            const selectedDate = new Date(value);
            const today = new Date();
            today.setHours(0, 0, 0, 0); // Reset time to start of day
            selectedDate.setHours(0, 0, 0, 0);
            
            try {
                if (event.target && typeof event.target.setCustomValidity === 'function') {
                    if (selectedDate <= today) {
                        event.target.setCustomValidity('Next Visit Proposed Date must be a future date (after today)');
                        event.target.reportValidity();
                        // Clear the invalid value
                        if (this.showInstallationReport && this.installationReportRecord) {
                            this.installationReportRecord = { ...this.installationReportRecord, [name]: null };
                        } else if (this.showServiceReport && this.serviceReportRecord) {
                            this.serviceReportRecord = { ...this.serviceReportRecord, [name]: null };
                        }
                        showToast(this, 'Error', 'Next Visit Proposed Date must be a future date (after today)', 'error');
                        return;
                    } else {
                        event.target.setCustomValidity('');
                    }
                    event.target.reportValidity();
                }
            } catch (error) {
                console.log('Validation error:', error);
            }
        }

        // Determine which record to update based on active form
        if (this.showInstallationReport && this.installationReportRecord) {
            this.installationReportRecord = { ...this.installationReportRecord, [name]: value };
            // Validate TTO Installation Report numeric fields in real-time
            if (this.isTTO) {
                this.validateTTOInstallationField(name, value, event);
            }
            // Validate CIJ Installation Report numeric fields in real-time
            if (this.isCIJ) {
                this.validateCIJInstallationField(name, value, event);
            }
            // Validate TIJ Installation Report numeric fields in real-time
            if (this.isTIJ) {
                this.validateTIJInstallationField(name, value, event);
            }
        } else if (this.showServiceReport && this.serviceReportRecord) {
            this.serviceReportRecord = { ...this.serviceReportRecord, [name]: value };
            // If this is a date field that affects total calculation, recalculate totals
            if (name === 'TravelDate__c' || name === 'Date_To__c' || name === 'Travel_Date_2__c' || name === 'Date_To_2__c') {
                this.calculateTotals();
                this._recordVersion++;
            }
        }

        // Validate Level_1_Password__c and Level_2_Password__c - must be numeric only, length 4 or 6
        if ((name === 'Level_1_Password__c' || name === 'Level_2_Password__c') && value !== null && value !== undefined) {
            const inputValue = String(value);
            const hasAlphabets = /[a-zA-Z]/.test(inputValue);
            const numericOnly = inputValue.replace(/[^0-9]/g, '');
            const passwordValue = numericOnly.trim();
            const validLengthRegex = /^[0-9]{4}$|^[0-9]{6}$/;
            
            try {
                // Show error if alphabets are detected
                if (hasAlphabets) {
                    const errorMessage = 'Password must contain only numbers (alphabets are not allowed)';
                    
                    // Set error on input field
                    if (event.target && typeof event.target.setCustomValidity === 'function') {
                        event.target.setCustomValidity(errorMessage);
                        event.target.reportValidity();
                    }
                    
                    // Set error in fieldValidationErrors for display below field
                    this.fieldValidationErrors = { ...this.fieldValidationErrors, [name]: errorMessage };
                    
                    // Remove alphabets and update record with numeric-only value
                    if (this.showInstallationReport && this.installationReportRecord) {
                        this.installationReportRecord = { ...this.installationReportRecord, [name]: numericOnly };
                    }
                    
                    // Update the input field value to remove alphabets
                    if (event.target && numericOnly !== inputValue) {
                        event.target.value = numericOnly;
                    }
                    
                    // Show toast notification
                    showToast(this, 'Error', errorMessage, 'error');
                } else if (passwordValue && !validLengthRegex.test(passwordValue)) {
                    // Check if length is 4 or 6
                    const errorMessage = 'Password must be exactly 4 or 6 digits';
                    
                    if (event.target && typeof event.target.setCustomValidity === 'function') {
                        event.target.setCustomValidity(errorMessage);
                        event.target.reportValidity();
                    }
                    
                    this.fieldValidationErrors = { ...this.fieldValidationErrors, [name]: errorMessage };
                } else {
                    // Value is valid - clear errors
                    if (event.target && typeof event.target.setCustomValidity === 'function') {
                        event.target.setCustomValidity('');
                        event.target.reportValidity();
                    }
                    
                    // Clear error from fieldValidationErrors
                    if (this.fieldValidationErrors[name]) {
                        const errors = { ...this.fieldValidationErrors };
                        delete errors[name];
                        this.fieldValidationErrors = errors;
                    }
                }
            } catch (error) {
                console.log('Password validation error:', error);
            }
        }
        
        // Validate Customer Contact Number - must be exactly 10 digits if provided
        if (name === 'Customer_Contact_Number__c' && value) {
            const phoneRegex = /^[0-9]{10}$/;
            const contactNumber = String(value).trim();
        try {
            if (event.target && typeof event.target.setCustomValidity === 'function') {
                    if (contactNumber && !phoneRegex.test(contactNumber)) {
                        event.target.setCustomValidity('Customer Contact Number must be exactly 10 digits');
                    } else {
                event.target.setCustomValidity('');
                    }
                event.target.reportValidity();
            }
        } catch (error) {
            console.log('Validation error:', error);
            }
        } else if (name !== 'Next_Visit_Proposed_Date__c' && name !== 'Level_1_Password__c' && name !== 'Level_2_Password__c') {
            // Clear validation for other fields - only attempt if target has setCustomValidity method
            try {
                if (event.target && typeof event.target.setCustomValidity === 'function') {
                    event.target.setCustomValidity('');
                    event.target.reportValidity();
                }
            } catch (error) {
                console.log('Validation error:', error);
            }
        }

        if (name === 'Spare_Replaced__c' && value === 'Yes') {
            hasSpareRequestRecords({ workOrderId : this.workOrderId }).then(result => {
                this.hasSpareRequestRecords = result;
            });
        }
    }

    /**
     * Handle Travel Expense fields change - updates record and triggers Total Per Day recalculation
     */
    handleTravelExpenseChange(event) {

        const { name, value } = getNameAndValueOnChange(this, event);
        
        // Update the service report record
        if (this.showServiceReport && this.serviceReportRecord) {
            this.serviceReportRecord = { ...this.serviceReportRecord, [name]: value };
            // Recalculate totals when travel expense fields change
            this.calculateTotals();
            // Increment version to force getter recalculation
            this._recordVersion++;
        }
        
        // The totalPerDay computed property will automatically recalculate
    }

    /**
     * Handle Ink Part No combobox change (Service Report) - Single select
     */
    handleInkPartNoChange(event) {
        const value = event.detail.value;
        if (this.serviceReportRecord) {
            this.serviceReportRecord = {
                ...this.serviceReportRecord,
                Ink_Part_No__c: value
            };
        }
        // Also update Installation Report for TTO
        if (this.installationReportRecord) {
            this.installationReportRecord = {
                ...this.installationReportRecord,
                Ink_Part_No__c: value
            };
        }
    }

    /**
     * Handle MakeUp Part No combobox change (Service Report and Installation Report - TTO) - Single select
     */
    handleMakeUpPartNoChange(event) {
        const value = event.detail.value;
        if (this.serviceReportRecord) {
            this.serviceReportRecord = {
                ...this.serviceReportRecord,
                MakeUp_Part_No__c: value
            };
        }
        // Also update Installation Report for TTO
        if (this.installationReportRecord) {
            this.installationReportRecord = {
                ...this.installationReportRecord,
                Make_Up_Part_No__c: value
            };
        }
    }

    /**
     * Handle Ribbon Part combobox change (Service Report - TTO and Installation Report - TTO) - Single select
     */
    handleRibbonPartChange(event) {
        const value = event.detail.value;
        if (this.serviceReportRecord) {
            this.serviceReportRecord = {
                ...this.serviceReportRecord,
                Ribbon_Part__c: value
            };
        }
        if (this.installationReportRecord) {
            this.installationReportRecord = {
                ...this.installationReportRecord,
                Ribbon_Part__c: value
            };
        }
    }

    handleRibbonPartNoChange(event) {
        const value = event.detail.value;
        if (this.installationReportRecord) {
            this.installationReportRecord = {
                ...this.installationReportRecord,
                Ribbon_Part_No__c: value
            };
        }
    }

    /**
     * Validate CIJ Installation Report numeric fields in real-time
     */
    validateCIJInstallationField(fieldName, fieldValue, event) {
        // CIJ Installation Report field validations (matching HTML field names)
        const cijFieldValidations = [
            { name: 'Blocking_Time__c', min: 0, max: 10000, label: 'Blocking Time' },
            { name: 'Signal_Time__c', min: 0, max: 1000, label: 'Signal Time' },
            { name: 'Visc_Set_Point__c', min: 12, max: 60, label: 'Visc Set Point' },
            { name: 'Visc_Actual__c', min: 12, max: 60, label: 'Visc Actual' },
            { name: 'Ink_Temp__c', min: 3, max: 55, label: 'Ink Temp' },
            { name: 'Cabinet_Temp__c', min: 5, max: 60, label: 'Cabinet Temp' },
            { name: 'Head_Temp__c', min: 0, max: 45, label: 'Head Temp' },
            { name: 'Heater_Point__c', min: 0, max: 45, label: 'Heater Point' },
            { name: 'Modulation__c', min: 0, max: 100, label: 'Modulation' },
            { name: 'Charge_Value__c', min: 110, max: 220, label: 'Charge Value' },
            { name: 'EHT_Range_Min__c', min: 110, max: 150, label: 'EHT Range Min' },
            { name: 'EHT_Range_Max__c', min: 160, max: 250, label: 'EHT Range Max' },
            { name: 'L_N_volt__c', min: 180, max: 270, label: 'L & N, volt.' },
            { name: 'N_G_volt__c', min: 0, max: 5, label: 'N & G, volt.' },
            { name: 'G_L_volt__c', min: 0, max: 5, label: 'G & L, volt.' },
            { name: 'Line_Speed_meter_per_Min__c', min: 0, max: 600, label: 'Line Speed meter per Min' },
            { name: 'Work_Load_Hrs_Day__c', min: 0, max: 24, label: 'Work Load Hrs Per Day' },
            { name: 'Work_Load_Days_Wk__c', min: 0, max: 7, label: 'Work Load Days Per Week' }
        ];

        // Find the field configuration
        const fieldConfig = cijFieldValidations.find(config => config.name === fieldName);
        
        if (!fieldConfig) {
            return; // Field not in validation list
        }

        // Clear previous error
        if (this.fieldValidationErrors[fieldName]) {
            delete this.fieldValidationErrors[fieldName];
        }

        // Validate if value is provided
        if (fieldValue !== null && fieldValue !== undefined && fieldValue !== '') {
            const numericValue = parseFloat(fieldValue);
            
            if (isNaN(numericValue)) {
                // Not a valid number
                const errorMessage = `${fieldConfig.label} must be a valid number`;
                this.fieldValidationErrors[fieldName] = errorMessage;
                
                if (event && event.target && typeof event.target.setCustomValidity === 'function') {
                    event.target.setCustomValidity(errorMessage);
                    event.target.reportValidity();
                }
            } else if (numericValue < fieldConfig.min || numericValue > fieldConfig.max) {
                // Value out of range
                const errorMessage = `${fieldConfig.label} must be between ${fieldConfig.min} and ${fieldConfig.max}`;
                this.fieldValidationErrors[fieldName] = errorMessage;
                
                if (event && event.target && typeof event.target.setCustomValidity === 'function') {
                    event.target.setCustomValidity(errorMessage);
                    event.target.reportValidity();
                }
            } else {
                // Value is valid, clear any errors
                if (event && event.target && typeof event.target.setCustomValidity === 'function') {
                    event.target.setCustomValidity('');
                    event.target.reportValidity();
                }
            }
        } else {
            // Field is empty, clear errors
            if (event && event.target && typeof event.target.setCustomValidity === 'function') {
                event.target.setCustomValidity('');
                event.target.reportValidity();
            }
        }
        
        // Validate G_L_volt__c when L_N_volt__c or G_L_volt__c changes
        if (fieldName === 'L_N_volt__c' || fieldName === 'G_L_volt__c') {
            this.validateGLVolt();
        }
    }

    /**
     * Validate G_L_volt__c must be within 2% of L_N_volt__c
     */
    validateGLVolt() {
        // Clear previous error
        if (this.fieldValidationErrors.G_L_volt__c) {
            delete this.fieldValidationErrors.G_L_volt__c;
        }

        const fieldA = this.installationReportRecord.L_N_volt__c;
        const fieldB = this.installationReportRecord.G_L_volt__c;

        if (fieldA === undefined || fieldA === null || fieldA === '' || 
            fieldB === undefined || fieldB === null || fieldB === '') {
            // Clear error if either field is empty
            const fieldElement = this.template.querySelector('lightning-input-field[field-name="G_L_volt__c"]');
            if (fieldElement) {
                const inputElement = fieldElement.inputElement || 
                                   fieldElement.querySelector('input') || 
                                   fieldElement.shadowRoot?.querySelector('input') ||
                                   fieldElement;
                if (inputElement && typeof inputElement.setCustomValidity === 'function') {
                    inputElement.setCustomValidity('');
                    inputElement.reportValidity();
                }
            }
            return;
        }

        const lNValue = parseFloat(fieldA);
        const gLValue = parseFloat(fieldB);

        if (isNaN(lNValue) || isNaN(gLValue)) {
            return;
        }

        const tolerance = lNValue * 0.02;
        const minValue = lNValue - tolerance;
        const maxValue = lNValue + tolerance;

        if (gLValue < minValue || gLValue > maxValue) {
            const errorMessage = `G & L, volt. must be within 2% deviation of L & N, volt. (${minValue.toFixed(2)} - ${maxValue.toFixed(2)})`;
            this.fieldValidationErrors = { ...this.fieldValidationErrors, G_L_volt__c: errorMessage };
            
            const fieldElement = this.template.querySelector('lightning-input-field[field-name="G_L_volt__c"]');
            if (fieldElement) {
                const inputElement = fieldElement.inputElement || 
                                   fieldElement.querySelector('input') || 
                                   fieldElement.shadowRoot?.querySelector('input') ||
                                   fieldElement;
                if (inputElement && typeof inputElement.setCustomValidity === 'function') {
                    inputElement.setCustomValidity(errorMessage);
                    inputElement.reportValidity();
                }
            }
        } else {
            debugger;
            // Value is valid, clear error from fieldValidationErrors
            const updatedErrors = {};
            Object.keys(this.fieldValidationErrors).forEach(key => {
                if (key !== 'G_L_volt__c') {
                    updatedErrors[key] = this.fieldValidationErrors[key];
                }
            });
            this.fieldValidationErrors = updatedErrors;
            
            // Clear error from input field
            const fieldElement = this.template.querySelector('lightning-input-field[field-name="G_L_volt__c"]');
            if (fieldElement) {
                const inputElement = fieldElement.inputElement || 
                                   fieldElement.querySelector('input') || 
                                   fieldElement.shadowRoot?.querySelector('input') ||
                                   fieldElement;
                if (inputElement && typeof inputElement.setCustomValidity === 'function') {
                    inputElement.setCustomValidity('');
                    inputElement.reportValidity();
                }
            }
        }
    }

    /**
     * Validate TIJ Installation Report numeric fields in real-time
     */
    validateTIJInstallationField(fieldName, fieldValue, event) {
        // Special validation for Number_of_head__c (must be a positive number)
        if (fieldName === 'Number_of_head__c') {
            if (fieldValue !== null && fieldValue !== undefined && fieldValue !== '') {
                const numericValue = parseFloat(fieldValue);
                
                if (isNaN(numericValue)) {
                    const errorMessage = 'Number of head must be a valid number';
                    this.fieldValidationErrors[fieldName] = errorMessage;
                    if (event && event.target && typeof event.target.setCustomValidity === 'function') {
                        event.target.setCustomValidity(errorMessage);
                        event.target.reportValidity();
                    }
                } else if (numericValue <= 0) {
                    const errorMessage = 'Number of head must be a positive number (greater than 0)';
                    this.fieldValidationErrors[fieldName] = errorMessage;
                    if (event && event.target && typeof event.target.setCustomValidity === 'function') {
                        event.target.setCustomValidity(errorMessage);
                        event.target.reportValidity();
                    }
                } else if (!Number.isInteger(numericValue)) {
                    const errorMessage = 'Number of head must be a whole number';
                    this.fieldValidationErrors[fieldName] = errorMessage;
                    if (event && event.target && typeof event.target.setCustomValidity === 'function') {
                        event.target.setCustomValidity(errorMessage);
                        event.target.reportValidity();
                    }
                } else {
                    // Value is valid, clear any errors
                    if (this.fieldValidationErrors[fieldName]) {
                        delete this.fieldValidationErrors[fieldName];
                    }
                    if (event && event.target && typeof event.target.setCustomValidity === 'function') {
                        event.target.setCustomValidity('');
                        event.target.reportValidity();
                    }
                }
            } else {
                // Field is empty, clear errors (required validation will be handled separately)
                if (this.fieldValidationErrors[fieldName]) {
                    delete this.fieldValidationErrors[fieldName];
                }
                if (event && event.target && typeof event.target.setCustomValidity === 'function') {
                    event.target.setCustomValidity('');
                    event.target.reportValidity();
                }
            }
            return; // Exit early for Number_of_head__c
        }
        
        // TIJ Installation Report field validations (matching HTML field names)
        const tijFieldValidations = [
            { name: 'L_N_volt__c', min: 180, max: 270, label: 'L & N, volt.' },
            { name: 'N_G_volt__c', min: 0, max: 5, label: 'N & G, volt.' },
            { name: 'G_L_volt__c', min: 0, max: 5, label: 'G & L, volt.' },
            { name: 'Line_Speed_meter_per_Min__c', min: 0, max: 600, label: 'Line Speed meter per Min' },
            { name: 'Work_Load_Hrs_Day__c', min: 0, max: 24, label: 'Work Load Hrs Per Day' },
            { name: 'Work_Load_Days_Wk__c', min: 0, max: 7, label: 'Work Load Days Per Week' }
        ];

        // Find the field configuration
        const fieldConfig = tijFieldValidations.find(config => config.name === fieldName);
        
        
        if (!fieldConfig) {
            return; // Field not in validation list
        }

        // Clear previous error
        if (this.fieldValidationErrors[fieldName]) {
            delete this.fieldValidationErrors[fieldName];
        }

        // Validate if value is provided
        if (fieldValue !== null && fieldValue !== undefined && fieldValue !== '') {
            const numericValue = parseFloat(fieldValue);
            
            if (isNaN(numericValue)) {
                // Not a valid number
                const errorMessage = `${fieldConfig.label} must be a valid number`;
                this.fieldValidationErrors[fieldName] = errorMessage;
                
                if (event && event.target && typeof event.target.setCustomValidity === 'function') {
                    event.target.setCustomValidity(errorMessage);
                    event.target.reportValidity();
                }
            } else if (numericValue < fieldConfig.min || numericValue > fieldConfig.max) {
                // Value out of range
                const errorMessage = `${fieldConfig.label} must be between ${fieldConfig.min} and ${fieldConfig.max}`;
                this.fieldValidationErrors[fieldName] = errorMessage;
                
                if (event && event.target && typeof event.target.setCustomValidity === 'function') {
                    event.target.setCustomValidity(errorMessage);
                    event.target.reportValidity();
                }
            } else {
                // Value is valid, clear any errors
                if (event && event.target && typeof event.target.setCustomValidity === 'function') {
                    event.target.setCustomValidity('');
                    event.target.reportValidity();
                }
            }
        } else {
            // Field is empty, clear errors
            if (event && event.target && typeof event.target.setCustomValidity === 'function') {
                event.target.setCustomValidity('');
                event.target.reportValidity();
            }
        }
        
        // Validate G_L_volt__c when L_N_volt__c or G_L_volt__c changes
        if (fieldName === 'L_N_volt__c' || fieldName === 'G_L_volt__c') {
            this.validateGLVolt();
        }
    }

    /**
     * Validate TTO Installation Report numeric fields in real-time
     */
    validateTTOInstallationField(fieldName, fieldValue, event) {
        // TTO Installation Report field validations (matching HTML field names)
        const ttoFieldValidations = [
            { name: 'Print_head_Resistance__c', min: 0, max: 9999, label: 'Print Head Resistance (Ohm)' },
            { name: 'Ribbon_Dia_D1__c', min: 1, max: 200, label: 'Ribbon Dia D1 (mm)' },
            { name: 'Ribbon_Dia_D2__c', min: 1, max: 200, label: 'Ribbon Dia D2 (mm)' },
            { name: 'Print_speed__c', min: 40, max: 800, label: 'Print Speed (mm/sec)' },
            { name: 'Ribbon_fail_count__c', min: 0, max: 244, label: 'Ribbon Fail Count (Nos)' },
            { name: 'Registration_Dot__c', min: 0, max: 384, label: 'Registration Dot' },
            { name: 'Debounce_time_ms__c', min: 0, max: 1000, label: 'Debounce Time (ms)' },
            { name: 'Print_Delay__c', min: 0, max: 5000, label: 'Print Delay' },
            { name: 'Pr_GO_Ignore__c', min: 0, max: 5000, label: 'PR-GO Ignore' },
            { name: 'Ribbon_Gap__c', min: -80, max: 150, label: 'Ribbon Gap (mm)' },
            { name: 'Output_Air_Pressure__c', min: 1, max: 8, label: 'Output Air Pressure (PSI)' },
            { name: 'Head_out_time_ms__c', min: 0, max: 1000, label: 'Head Out Time (ms)' },
            { name: 'Head_In_Time__c', min: 0, max: 200, label: 'Head In Time (ms)' },
            { name: 'Start_Border_Trim__c', min: 0, max: 20, label: 'Start Border Trim (mm)' },
            { name: 'End_Border_Trim__c', min: 0, max: 20, label: 'End Border Trim (mm)' },
            { name: 'Darkness__c', min: 0, max: 120, label: 'Darkness' },
            { name: 'Work_Load_Hrs_Day__c', min: 0, max: 24, label: 'Work Load Hrs Per Day' },
            { name: 'Work_Load_Days_Wk__c', min: 0, max: 7, label: 'Work Load Days Per Week' }
        ];

        // Find the field configuration
        const fieldConfig = ttoFieldValidations.find(config => config.name === fieldName);
        
        if (!fieldConfig) {
            return; // Field not in validation list
        }

        // Clear previous error
        if (this.fieldValidationErrors[fieldName]) {
            delete this.fieldValidationErrors[fieldName];
        }

        // Validate if value is provided
        if (fieldValue !== null && fieldValue !== undefined && fieldValue !== '') {
            const numericValue = parseFloat(fieldValue);
            
            if (isNaN(numericValue)) {
                // Not a valid number
                const errorMessage = `${fieldConfig.label} must be a valid number`;
                this.fieldValidationErrors[fieldName] = errorMessage;
                
                if (event && event.target && typeof event.target.setCustomValidity === 'function') {
                    event.target.setCustomValidity(errorMessage);
                    event.target.reportValidity();
                }
            } else if (numericValue < fieldConfig.min || numericValue > fieldConfig.max) {
                // Value out of range
                const errorMessage = `${fieldConfig.label} must be between ${fieldConfig.min} and ${fieldConfig.max}`;
                this.fieldValidationErrors[fieldName] = errorMessage;
                
                if (event && event.target && typeof event.target.setCustomValidity === 'function') {
                    event.target.setCustomValidity(errorMessage);
                    event.target.reportValidity();
                }
            } else {
                // Value is valid, clear any errors
                if (event && event.target && typeof event.target.setCustomValidity === 'function') {
                    event.target.setCustomValidity('');
                    event.target.reportValidity();
                }
            }
        } else {
            // Field is empty, clear errors
            if (event && event.target && typeof event.target.setCustomValidity === 'function') {
                event.target.setCustomValidity('');
                event.target.reportValidity();
            }
        }
        
        // Validate G_L_volt__c when L_N_volt__c or G_L_volt__c changes
        if (fieldName === 'L_N_volt__c' || fieldName === 'G_L_volt__c') {
            this.validateGLVolt();
        }
    }

    // INSTALLATION REPORT SPECIFIC METHODS
    loadAllImages() {
        if (!this.installationReportRecord.Id) return;

        getDiagnosticImages({
            recordId: this.installationReportRecord.Id,
            imageType: 'diagnostic'
        })
            .then(result => {
                if (result) {
                    this.diagnosticScreenImages = result.map(img => ({
                        id: img.contentDocumentId,
                        name: img.title,
                        previewUrl: `/sfc/servlet.shepherd/document/download/${img.contentDocumentId}`,
                        contentVersionId: img.contentVersionId,
                        section: 'diagnostic'
                    }));
                }
            })
            .catch(error => {
                console.error('Error loading diagnostic images:', error);
            });

        getDiagnosticImages({
            recordId: this.installationReportRecord.Id,
            imageType: 'modulation'
        })
            .then(result => {
                if (result) {
                    this.modulationTestImages = result.map(img => ({
                        id: img.contentDocumentId,
                        name: img.title,
                        previewUrl: `/sfc/servlet.shepherd/document/download/${img.contentDocumentId}`,
                        contentVersionId: img.contentVersionId,
                        section: 'modulation'
                    }));
                }
            })
            .catch(error => {
                console.error('Error loading modulation test images:', error);
            });

        // Load ribbon images for TTO
        if (this.isTTO) {
            getDiagnosticImages({
                recordId: this.installationReportRecord.Id,
                imageType: 'ribbon'
            })
                .then(result => {
                    if (result) {
                        this.ribbonImages = result.map(img => ({
                            id: img.contentDocumentId,
                            name: img.title,
                            previewUrl: `/sfc/servlet.shepherd/document/download/${img.contentDocumentId}`,
                            contentVersionId: img.contentVersionId,
                            section: 'ribbon'
                        }));
                    }
                })
                .catch(error => {
                    console.error('Error loading ribbon images:', error);
                });
        }

        // Load TIJ photo images
        if (this.isTIJ) {
            // Photo 01: Print Head Direction
        getDiagnosticImages({
            recordId: this.installationReportRecord.Id,
                imageType: 'printheaddirection'
        })
            .then(result => {
                if (result) {
                        this.printHeadDirectionImages = result.map(img => ({
                        id: img.contentDocumentId,
                        name: img.title,
                        previewUrl: `/sfc/servlet.shepherd/document/download/${img.contentDocumentId}`,
                        contentVersionId: img.contentVersionId,
                            section: 'printheaddirection'
                    }));
                }
            })
            .catch(error => {
                    console.error('Error loading print head direction images:', error);
                });

            // Photo 2: Printing Message
            getDiagnosticImages({
                recordId: this.installationReportRecord.Id,
                imageType: 'printingmessage'
            })
                .then(result => {
                    if (result) {
                        this.printingMessageImages = result.map(img => ({
                            id: img.contentDocumentId,
                            name: img.title,
                            previewUrl: `/sfc/servlet.shepherd/document/download/${img.contentDocumentId}`,
                            contentVersionId: img.contentVersionId,
                            section: 'printingmessage'
                        }));
                    }
                })
                .catch(error => {
                    console.error('Error loading printing message images:', error);
                });

            // Photo 03: Packing Checklist
            getDiagnosticImages({
                recordId: this.installationReportRecord.Id,
                imageType: 'packingchecklist'
            })
                .then(result => {
                    if (result) {
                        this.packingChecklistImages = result.map(img => ({
                            id: img.contentDocumentId,
                            name: img.title,
                            previewUrl: `/sfc/servlet.shepherd/document/download/${img.contentDocumentId}`,
                            contentVersionId: img.contentVersionId,
                            section: 'packingchecklist'
                        }));
                    }
                })
                .catch(error => {
                    console.error('Error loading packing checklist images:', error);
                });
        }

        // Load CIJ Physical Check images
        if (this.isCIJ) {
            // Print Head Stand (when "Not OK")
            getDiagnosticImages({
                recordId: this.installationReportRecord.Id,
                imageType: 'printheadstand'
            })
                .then(result => {
                    if (result) {
                        this.printHeadStandImages = result.map(img => ({
                            id: img.contentDocumentId,
                            name: img.title,
                            previewUrl: `/sfc/servlet.shepherd/document/download/${img.contentDocumentId}`,
                            contentVersionId: img.contentVersionId,
                            section: 'printheadstand'
                        }));
                    }
                })
                .catch(error => {
                    console.error('Error loading print head stand images:', error);
                });

            // Printer Stand (when "Not OK")
            getDiagnosticImages({
                recordId: this.installationReportRecord.Id,
                imageType: 'printerstand'
            })
                .then(result => {
                    if (result) {
                        this.printerStandImages = result.map(img => ({
                            id: img.contentDocumentId,
                            name: img.title,
                            previewUrl: `/sfc/servlet.shepherd/document/download/${img.contentDocumentId}`,
                            contentVersionId: img.contentVersionId,
                            section: 'printerstand'
                        }));
                    }
                })
                .catch(error => {
                    console.error('Error loading printer stand images:', error);
                });

            // Tool Box (when "Not OK")
            getDiagnosticImages({
                recordId: this.installationReportRecord.Id,
                imageType: 'toolbox'
            })
                .then(result => {
                    if (result) {
                        this.toolBoxImages = result.map(img => ({
                            id: img.contentDocumentId,
                            name: img.title,
                            previewUrl: `/sfc/servlet.shepherd/document/download/${img.contentDocumentId}`,
                            contentVersionId: img.contentVersionId,
                            section: 'toolbox'
                        }));
                    }
                })
                .catch(error => {
                    console.error('Error loading tool box images:', error);
                });

            // Printer Manual (when "Not OK")
            getDiagnosticImages({
                recordId: this.installationReportRecord.Id,
                imageType: 'printermanual'
            })
                .then(result => {
                    if (result) {
                        this.printerManualImages = result.map(img => ({
                            id: img.contentDocumentId,
                            name: img.title,
                            previewUrl: `/sfc/servlet.shepherd/document/download/${img.contentDocumentId}`,
                            contentVersionId: img.contentVersionId,
                            section: 'printermanual'
                        }));
                    }
                })
                .catch(error => {
                    console.error('Error loading printer manual images:', error);
                });

            // Sensor (when "Not OK")
            getDiagnosticImages({
                recordId: this.installationReportRecord.Id,
                imageType: 'sensor'
            })
                .then(result => {
                    if (result) {
                        this.sensorImages = result.map(img => ({
                            id: img.contentDocumentId,
                            name: img.title,
                            previewUrl: `/sfc/servlet.shepherd/document/download/${img.contentDocumentId}`,
                            contentVersionId: img.contentVersionId,
                            section: 'sensor'
                        }));
                    }
                })
                .catch(error => {
                    console.error('Error loading sensor images:', error);
                });
        }

        // Load TTO Physical Check images
        if (this.isTTO) {
            // Print head position lifted (when "No")
            getDiagnosticImages({
                recordId: this.installationReportRecord.Id,
                imageType: 'printheadposition'
            })
                .then(result => {
                    if (result) {
                        this.printHeadPositionLiftedImages = result.map(img => ({
                            id: img.contentDocumentId,
                            name: img.title,
                            previewUrl: `/sfc/servlet.shepherd/document/download/${img.contentDocumentId}`,
                            contentVersionId: img.contentVersionId,
                            section: 'printheadposition'
                        }));
                    }
                })
                .catch(error => {
                    console.error('Error loading print head position images:', error);
                });

            // BOM Check list verified (when "Items missing")
            getDiagnosticImages({
                recordId: this.installationReportRecord.Id,
                imageType: 'bomchecklist'
            })
                .then(result => {
                    if (result) {
                        this.bomCheckListImages = result.map(img => ({
                            id: img.contentDocumentId,
                            name: img.title,
                            previewUrl: `/sfc/servlet.shepherd/document/download/${img.contentDocumentId}`,
                            contentVersionId: img.contentVersionId,
                            section: 'bomchecklist'
                        }));
                    }
                })
                .catch(error => {
                    console.error('Error loading BOM check list images:', error);
                });

            // Sensor (when "NotOK")
            getDiagnosticImages({
                recordId: this.installationReportRecord.Id,
                imageType: 'sensortto'
            })
                .then(result => {
                    if (result) {
                        this.sensorTTOImages = result.map(img => ({
                            id: img.contentDocumentId,
                            name: img.title,
                            previewUrl: `/sfc/servlet.shepherd/document/download/${img.contentDocumentId}`,
                            contentVersionId: img.contentVersionId,
                            section: 'sensortto'
                        }));
                    }
                })
                .catch(error => {
                    console.error('Error loading sensor TTO images:', error);
                });

            // Encoder (when "NOTok")
            getDiagnosticImages({
                recordId: this.installationReportRecord.Id,
                imageType: 'encodertto'
            })
                .then(result => {
                    if (result) {
                        this.encoderTTOImages = result.map(img => ({
                            id: img.contentDocumentId,
                            name: img.title,
                            previewUrl: `/sfc/servlet.shepherd/document/download/${img.contentDocumentId}`,
                            contentVersionId: img.contentVersionId,
                            section: 'encodertto'
                        }));
                    }
                })
                .catch(error => {
                    console.error('Error loading encoder TTO images:', error);
                });

            // Industry Type (TTO)
            getDiagnosticImages({
                recordId: this.installationReportRecord.Id,
                imageType: 'industrytype'
            })
                .then(result => {
                    if (result) {
                        this.industryTypeImages = result.map(img => ({
                            id: img.contentDocumentId,
                            name: img.title,
                            previewUrl: `/sfc/servlet.shepherd/document/download/${img.contentDocumentId}`,
                            contentVersionId: img.contentVersionId,
                            section: 'industrytype'
                        }));
                    }
                })
                .catch(error => {
                    console.error('Error loading industry type images:', error);
                });

            // MESSAGE Gap between prints (ribbon pic with scale)
            getDiagnosticImages({
                recordId: this.installationReportRecord.Id,
                imageType: 'gapbetweenprints'
            })
                .then(result => {
                    if (result) {
                        this.gapBetweenPrintsImages = result.map(img => ({
                            id: img.contentDocumentId,
                            name: img.title,
                            previewUrl: `/sfc/servlet.shepherd/document/download/${img.contentDocumentId}`,
                            contentVersionId: img.contentVersionId,
                            section: 'gapbetweenprints'
                        }));
                    }
                })
                .catch(error => {
                    console.error('Error loading gap between prints images:', error);
                });
        }

        // Load Earthing images (for all printer types: CIJ, TIJ, TTO)
        getDiagnosticImages({
            recordId: this.installationReportRecord.Id,
            imageType: 'earthing'
        })
            .then(result => {
                if (result) {
                    this.earthingImages = result.map(img => ({
                        id: img.contentDocumentId,
                        name: img.title,
                        previewUrl: `/sfc/servlet.shepherd/document/download/${img.contentDocumentId}`,
                        contentVersionId: img.contentVersionId,
                        section: 'earthing'
                    }));
                }
            })
            .catch(error => {
                console.error('Error loading earthing images:', error);
            });

        // Load Message images for CIJ
        if (this.isCIJ) {
        getDiagnosticImages({
            recordId: this.installationReportRecord.Id,
            imageType: 'message'
        })
            .then(result => {
                if (result) {
                    this.messageImages = result.map(img => ({
                        id: img.contentDocumentId,
                        name: img.title,
                        previewUrl: `/sfc/servlet.shepherd/document/download/${img.contentDocumentId}`,
                        contentVersionId: img.contentVersionId,
                        section: 'message'
                    }));
                }
            })
            .catch(error => {
                console.error('Error loading message images:', error);
            });
        }
    }

    handleFileUpload(event) {
        const file = event.target.files[0];
        const section = event.target.dataset.section;

        if (!file) return;

        const validTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/bmp'];
        if (!validTypes.includes(file.type)) {
            showToast(this, 'Error', 'Please upload a valid image file (JPEG, PNG, GIF, BMP)', 'error');
            return;
        }

        const maxSize = 300 * 1024; // 300KB in bytes
        if (file.size > maxSize) {
            showToast(this, 'Error', 'Image size should be less than 300KB. Current size: ' + Math.round(file.size / 1024) + 'KB', 'error');
            return;
        }

        this.uploadImage(file, section);
    }

    uploadImage(file, section) {
        this.showSpinner = true;

        const reader = new FileReader();
        reader.onload = () => {
            const base64 = reader.result.split(',')[1];

            uploadDiagnosticImage({
                recordId: this.installationReportRecord.Id,
                fileName: file.name,
                base64Data: base64,
                contentType: file.type,
                imageType: section
            })
                .then(result => {
                    if (result) {
                        showToast(this, 'Success', `${this.getSectionDisplayName(section)} image uploaded successfully`, 'success');
                        this.loadAllImages();
                        const fileInput = this.template.querySelector(`lightning-input[data-section="${section}"]`);
                        if (fileInput) {
                            fileInput.value = '';
                        }
                    }
                })
                .catch(error => {
                    console.error('Error uploading image:', error);
                    showToast(this, 'Error', `Failed to upload ${this.getSectionDisplayName(section)} image`, 'error');
                })
                .finally(() => {
                    this.showSpinner = false;
                });
        };
        reader.readAsDataURL(file);
    }

    getSectionDisplayName(section) {
        const sectionNames = {
            'diagnostic': 'Diagnostic Screen',
            'modulation': 'Modulation Test',
            'ribbon': 'Ribbon Pic with Scale',
            'printheaddirection': 'Print Head Direction Photo',
            'printingmessage': 'Printing Message Photo / Quality',
            'packingchecklist': 'Packing / Check List Validation Photo',
            'printheadposition': 'Print Head Position Lifted',
            'bomchecklist': 'BOM Check List Verified',
            'sensortto': 'Sensor (TTO)',
            'encodertto': 'Encoder (TTO)',
            'gapbetweenprints': 'Gap Between Prints (Ribbon Pic with Scale)',
            'industrytype': 'Industry Type',
            'printheadstand': 'Print Head Stand',
            'printerstand': 'Printer Stand',
            'toolbox': 'Tool Box',
            'printermanual': 'Printer Manual',
            'sensor': 'Sensor',
            'message': 'Message',
            'earthing': 'Earthing'
        };
        return sectionNames[section] || section;
    }

    handleDeleteImage(event) {
        const imageId = event.currentTarget.dataset.id;
        const section = event.currentTarget.dataset.section;

        let images;
        if (section === 'diagnostic') {
            images = this.diagnosticScreenImages;
        } else if (section === 'modulation') {
            images = this.modulationTestImages;
        } else if (section === 'ribbon') {
            images = this.ribbonImages;
        } else if (section === 'printheaddirection') {
            images = this.printHeadDirectionImages;
        } else if (section === 'printingmessage') {
            images = this.printingMessageImages;
        } else if (section === 'packingchecklist') {
            images = this.packingChecklistImages;
        } else if (section === 'printheadposition') {
            images = this.printHeadPositionLiftedImages;
        } else if (section === 'bomchecklist') {
            images = this.bomCheckListImages;
        } else if (section === 'sensortto') {
            images = this.sensorTTOImages;
        } else if (section === 'encodertto') {
            images = this.encoderTTOImages;
        } else if (section === 'gapbetweenprints') {
            images = this.gapBetweenPrintsImages;
        } else if (section === 'industrytype') {
            images = this.industryTypeImages;
        } else if (section === 'earthing') {
            images = this.earthingImages;
        } else if (section === 'message') {
            images = this.messageImages;
        }

        const imageName = images ? images.find(img => img.id === imageId)?.name : 'image';

        if (confirm(`Are you sure you want to delete ${imageName}?`)) {
            this.showSpinner = true;

            deleteDiagnosticImage({ contentDocumentId: imageId })
                .then(() => {
                    showToast(this, 'Success', 'Image deleted successfully', 'success');
                    if (section === 'diagnostic') {
                        this.diagnosticScreenImages = this.diagnosticScreenImages.filter(img => img.id !== imageId);
                    } else if (section === 'modulation') {
                        this.modulationTestImages = this.modulationTestImages.filter(img => img.id !== imageId);
                    } else if (section === 'ribbon') {
                        this.ribbonImages = this.ribbonImages.filter(img => img.id !== imageId);
                    } else if (section === 'printheaddirection') {
                        this.printHeadDirectionImages = this.printHeadDirectionImages.filter(img => img.id !== imageId);
                    } else if (section === 'printingmessage') {
                        this.printingMessageImages = this.printingMessageImages.filter(img => img.id !== imageId);
                    } else if (section === 'packingchecklist') {
                        this.packingChecklistImages = this.packingChecklistImages.filter(img => img.id !== imageId);
                    } else if (section === 'printheadposition') {
                        this.printHeadPositionLiftedImages = this.printHeadPositionLiftedImages.filter(img => img.id !== imageId);
                    } else if (section === 'bomchecklist') {
                        this.bomCheckListImages = this.bomCheckListImages.filter(img => img.id !== imageId);
                    } else if (section === 'sensortto') {
                        this.sensorTTOImages = this.sensorTTOImages.filter(img => img.id !== imageId);
                    } else if (section === 'encodertto') {
                        this.encoderTTOImages = this.encoderTTOImages.filter(img => img.id !== imageId);
                    } else if (section === 'gapbetweenprints') {
                        this.gapBetweenPrintsImages = this.gapBetweenPrintsImages.filter(img => img.id !== imageId);
                    } else if (section === 'industrytype') {
                        this.industryTypeImages = this.industryTypeImages.filter(img => img.id !== imageId);
                    } else if (section === 'earthing') {
                        this.earthingImages = this.earthingImages.filter(img => img.id !== imageId);
                    } else if (section === 'message') {
                        this.messageImages = this.messageImages.filter(img => img.id !== imageId);
                    } else if (section === 'printheadstand') {
                        this.printHeadStandImages = this.printHeadStandImages.filter(img => img.id !== imageId);
                    } else if (section === 'printerstand') {
                        this.printerStandImages = this.printerStandImages.filter(img => img.id !== imageId);
                    } else if (section === 'toolbox') {
                        this.toolBoxImages = this.toolBoxImages.filter(img => img.id !== imageId);
                    } else if (section === 'printermanual') {
                        this.printerManualImages = this.printerManualImages.filter(img => img.id !== imageId);
                    } else if (section === 'sensor') {
                        this.sensorImages = this.sensorImages.filter(img => img.id !== imageId);
                    }
                })
                .catch(error => {
                    console.error('Error deleting image:', error);
                    showToast(this, 'Error', 'Failed to delete image', 'error');
                })
                .finally(() => {
                    this.showSpinner = false;
                });
        }
    }

    handleViewImage(event) {
        const imageId = event.currentTarget.dataset.id;
        const section = event.currentTarget.dataset.section;

        let images;
        if (section === 'diagnostic') {
            images = this.diagnosticScreenImages;
        } else if (section === 'modulation') {
            images = this.modulationTestImages;
        } else if (section === 'ribbon') {
            images = this.ribbonImages;
        } else if (section === 'printheaddirection') {
            images = this.printHeadDirectionImages;
        } else if (section === 'printingmessage') {
            images = this.printingMessageImages;
        } else if (section === 'packingchecklist') {
            images = this.packingChecklistImages;
        } else if (section === 'printheadposition') {
            images = this.printHeadPositionLiftedImages;
        } else if (section === 'bomchecklist') {
            images = this.bomCheckListImages;
        } else if (section === 'sensortto') {
            images = this.sensorTTOImages;
        } else if (section === 'encodertto') {
            images = this.encoderTTOImages;
        } else if (section === 'gapbetweenprints') {
            images = this.gapBetweenPrintsImages;
        } else if (section === 'industrytype') {
            images = this.industryTypeImages;
        } else if (section === 'earthing') {
            images = this.earthingImages;
        } else if (section === 'message') {
            images = this.messageImages;
        } else if (section === 'printheadstand') {
            images = this.printHeadStandImages;
        } else if (section === 'printerstand') {
            images = this.printerStandImages;
        } else if (section === 'toolbox') {
            images = this.toolBoxImages;
        } else if (section === 'printermanual') {
            images = this.printerManualImages;
        } else if (section === 'sensor') {
            images = this.sensorImages;
        }

        const image = images.find(img => img.id === imageId);

        if (image) {
            this.selectedImageUrl = image.previewUrl;
            this.selectedImageName = image.name;
            this.selectedImageSection = this.getSectionDisplayName(section);
            this.showImageModal = true;
        }
    }

    handleCloseImageModal() {
        this.showImageModal = false;
        this.selectedImageUrl = '';
        this.selectedImageName = '';
        this.selectedImageSection = '';
    }

    handleViewReferenceImage(event) {
        const imageType = event.currentTarget.dataset.imageType;
        let imageUrl = '';
        let imageName = '';
        
        if (imageType === 'intermittent') {
            imageUrl = this.intermittentInstallationCheckImage;
            imageName = 'Intermittent Installation Check Reference';
        } else if (imageType === 'continuous') {
            imageUrl = this.continuousInstallationCheckImage;
            imageName = 'Continuous Installation Check Reference';
        }
        
        if (imageUrl) {
            this.selectedImageUrl = imageUrl;
            this.selectedImageName = imageName;
            this.selectedImageSection = 'Installation Check Reference';
            this.showImageModal = true;
        }
    }

    handleDownloadImage() {
        if (this.selectedImageUrl) {
            const link = document.createElement('a');
            link.href = this.selectedImageUrl;
            link.download = this.selectedImageName;
            link.target = '_blank';
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
        }
    }

    get imageAltText() {
        return this.selectedImageSection ? `${this.selectedImageSection} Preview` : 'Image Preview';
    }

    drawText(event) {
        if (this.showInstallationReport) {
            this.installationReportRecord = {
                ...this.installationReportRecord,
                Signature_by__c: event.detail
            };
        } else if (this.showServiceReport) {
            this.serviceReportRecord = {
                ...this.serviceReportRecord,
                Signature_by__c: event.detail
            };
        }
    }

    handleSave() {
        // Basic trace so we can see clicks in browser console
        // eslint-disable-next-line no-console
        console.log('Installation/Service Report - Save clicked');

        let isValid = true;
        const missingRequired = [];

        // Add null check for records before validating
        if (!this.installationReportRecord && !this.serviceReportRecord) {
            showToast(this, 'Error', 'Report data is not available', 'error');
            return;
        }

        // For TIJ installation reports, set default values for checkbox fields if they're undefined/null
        if (this.showInstallationReport && this.isTIJ && this.installationReportRecord) {
            if (this.installationReportRecord.M_C_Breakdown__c === null || this.installationReportRecord.M_C_Breakdown__c === undefined) {
                this.installationReportRecord.M_C_Breakdown__c = false;
            }
            if (this.installationReportRecord.M_C_Temporary_Down__c === null || this.installationReportRecord.M_C_Temporary_Down__c === undefined) {
                this.installationReportRecord.M_C_Temporary_Down__c = false;
            }
            if (this.installationReportRecord.M_C_Running__c === null || this.installationReportRecord.M_C_Running__c === undefined) {
                this.installationReportRecord.M_C_Running__c = false;
            }
        }

        // Validate lightning-input-field elements
        this.template.querySelectorAll('lightning-input-field')?.forEach(field => {
            // Skip validation for TIJ checkbox fields that should not be required
            if (this.showInstallationReport && this.isTIJ) {
                const fieldName = field.fieldName;
                if (fieldName === 'M_C_Breakdown__c' || fieldName === 'M_C_Temporary_Down__c' || fieldName === 'M_C_Running__c') {
                    // Set custom validity to empty to clear any required errors for these checkbox fields
                    if (field.setCustomValidity) {
                        field.setCustomValidity('');
                    }
                    return; // Skip validation for these fields
                }
            }
            
            field.reportValidity();
            if (field.required && !field.value) {
                isValid = false;
                // Try to capture a readable label for the field
                const label = field.label || field.fieldName || field.dataset.name;
                if (label && !missingRequired.includes(label)) {
                    missingRequired.push(label);
                }
            }
        });

        // Validate lightning-input elements (for fields converted from lightning-input-field)
        this.template.querySelectorAll('lightning-input[required]')?.forEach(field => {
            field.reportValidity();
            if (field.required && !field.value) {
                isValid = false;
                // Try to capture a readable label for the field
                const label = field.label || field.name;
                if (label && !missingRequired.includes(label)) {
                    missingRequired.push(label);
                }
            }
        });

        // Validate Customer Contact Number - must be exactly 10 digits if provided
        const reportRecord = this.showInstallationReport ? this.installationReportRecord : this.serviceReportRecord;
        const contactNumberField = this.template.querySelector('lightning-input[name="Customer_Contact_Number__c"]');
        
        if (contactNumberField) {
            // Always check validity of the field (pattern validation)
            contactNumberField.reportValidity();
            
            // Check if the field has a value and if it's valid
            const contactNumber = contactNumberField.value ? String(contactNumberField.value).trim() : '';
            if (contactNumber) {
                const phoneRegex = /^[0-9]{10}$/;
                if (!phoneRegex.test(contactNumber)) {
                    contactNumberField.setCustomValidity('Customer Contact Number must be exactly 10 digits');
                    contactNumberField.reportValidity();
                    isValid = false;
                } else {
                    contactNumberField.setCustomValidity('');
                }
            }
            
            // Check if field is invalid (pattern mismatch or custom validity)
            if (!contactNumberField.validity.valid) {
                isValid = false;
                if (!contactNumber) {
                    // If empty and required, it will be caught by required validation above
                } else {
                    showToast(this, 'Error', 'Customer Contact Number must be exactly 10 digits', 'error');
                }
            }
        }

        if (!isValid && missingRequired.length) {
            showToast(
                this,
                'Error',
                'Please fill all mandatory fields: ' + missingRequired.join(', '),
                'error'
            );
        }

        if (this.isRemoteSupport) {
            // Add null checks for signature fields
            if (!this.installationReportRecord || !this.installationReportRecord.Signature__c || !this.installationReportRecord.Signature_by__c) {
                showToast(this, 'Error', 'Signature and signer details are required for remote support.', 'error');
                isValid = false;
            }
        }

        // Final validation check - ensure all fields with patterns are valid
        this.template.querySelectorAll('lightning-input[pattern]')?.forEach(field => {
            field.reportValidity();
            if (!field.validity.valid && field.value) {
                isValid = false;
            }
        });

        // Validate Work Load fields for Installation Reports on Save
        if (this.showInstallationReport && this.installationReportRecord) {
            // Validate Work Load Hrs Per Day
            if (this.isCIJ || this.isTIJ || this.isTTO) {
                const workLoadHrsDay = this.installationReportRecord.Work_Load_Hrs_Day__c;
                const workLoadHrsDayField = this.template.querySelector('lightning-input-field[field-name="Work_Load_Hrs_Day__c"]');
                
                if (workLoadHrsDayField) {
                    if (this.isCIJ) {
                        this.validateCIJInstallationField('Work_Load_Hrs_Day__c', workLoadHrsDay, { target: workLoadHrsDayField });
                    } else if (this.isTIJ) {
                        this.validateTIJInstallationField('Work_Load_Hrs_Day__c', workLoadHrsDay, { target: workLoadHrsDayField });
                    } else if (this.isTTO) {
                        this.validateTTOInstallationField('Work_Load_Hrs_Day__c', workLoadHrsDay, { target: workLoadHrsDayField });
                    }
                    
                    if (this.fieldValidationErrors.Work_Load_Hrs_Day__c) {
                        isValid = false;
                        workLoadHrsDayField.reportValidity();
                    }
                }
            }
            
            // Validate Work Load Days Per Week
            if (this.isCIJ || this.isTIJ || this.isTTO) {
                const workLoadDaysWk = this.installationReportRecord.Work_Load_Days_Wk__c;
                const workLoadDaysWkField = this.template.querySelector('lightning-input-field[field-name="Work_Load_Days_Wk__c"]');
                
                if (workLoadDaysWkField) {
                    if (this.isCIJ) {
                        this.validateCIJInstallationField('Work_Load_Days_Wk__c', workLoadDaysWk, { target: workLoadDaysWkField });
                    } else if (this.isTIJ) {
                        this.validateTIJInstallationField('Work_Load_Days_Wk__c', workLoadDaysWk, { target: workLoadDaysWkField });
                    } else if (this.isTTO) {
                        this.validateTTOInstallationField('Work_Load_Days_Wk__c', workLoadDaysWk, { target: workLoadDaysWkField });
                    }
                    
                    if (this.fieldValidationErrors.Work_Load_Days_Wk__c) {
                        isValid = false;
                        workLoadDaysWkField.reportValidity();
                    }
                }
            }
        }

        if (this.serviceReportRecord && this.serviceReportRecord.Spare_Replaced__c === 'Yes' && !this.hasSpareRequestRecords) {
            showToast(this, 'Error', 'Spare Replaced is selected as YES, but there are no Spare Requests on the related Case. Please create Spare Requests before saving.', 'error');
            isValid = false;
        }

        // Check if there are any validation errors in fieldValidationErrors
        if (Object.keys(this.fieldValidationErrors).length > 0) {
            isValid = false;
            // Show toast with validation errors
            const errorMessages = Object.values(this.fieldValidationErrors);
            if (errorMessages.length > 0) {
                showToast(this, 'Error', errorMessages.join('; '), 'error');
            }
        }

        // Only proceed with save if all validations pass
        if (!isValid) {
            // Don't show duplicate error messages - only show if we haven't shown one yet
            if (missingRequired.length === 0 && Object.keys(this.fieldValidationErrors).length === 0) {
                // Error messages should have already been shown by individual field validations
            }
            return; // Prevent save
        }

        if (isValid) {
            this.handleSaveAfterConfirmation();
        }
    }

    async handleSaveAfterConfirmation() {
        // Add null checks to prevent script errors
        if (!this.installationReportRecord) {
            showToast(this, 'Error', 'Installation report data is not available', 'error');
            this.showSpinner = false;
            return;
        }

        // Additional safety check for required fields
        if (!this.installationReportRecord.Id) {
            showToast(this, 'Error', 'Installation report ID is not available', 'error');
            this.showSpinner = false;
            return;
        }

        // Validate CIJ Installation Report numeric fields before saving
        if (this.isCIJ) {
            let isValid = true;
            const cijFieldValidations = [
                { name: 'Blocking_Time__c', min: 0, max: 10000, label: 'Blocking Time' },
                { name: 'Signal_Time__c', min: 0, max: 1000, label: 'Signal Time' },
                { name: 'Visc_Set_Point__c', min: 12, max: 60, label: 'Visc Set Point' },
                { name: 'Visc_Actual__c', min: 12, max: 60, label: 'Visc Actual' },
                { name: 'Ink_Temp__c', min: 3, max: 55, label: 'Ink Temp' },
                { name: 'Cabinet_Temp__c', min: 5, max: 60, label: 'Cabinet Temp' },
                { name: 'Head_Temp__c', min: 0, max: 45, label: 'Head Temp' },
                { name: 'Heater_Point__c', min: 0, max: 45, label: 'Heater Point' },
                { name: 'Modulation__c', min: 0, max: 100, label: 'Modulation' },
                { name: 'Charge_Value__c', min: 110, max: 220, label: 'Charge Value' },
                { name: 'EHT_Range_Min__c', min: 110, max: 150, label: 'EHT Range Min' },
                { name: 'EHT_Range_Max__c', min: 160, max: 250, label: 'EHT Range Max' },
                { name: 'L_N_volt__c', min: 180, max: 270, label: 'L & N, volt.' },
                { name: 'N_G_volt__c', min: 0, max: 5, label: 'N & G, volt.' },
                { name: 'Line_Speed_meter_per_Min__c', min: 0, max: 600, label: 'Line Speed meter per Min' }
            ];

            // Clear previous validation errors
            this.fieldValidationErrors = {};

            // Use setTimeout to ensure DOM is ready
            await new Promise(resolve => setTimeout(resolve, 0));

            cijFieldValidations.forEach(fieldConfig => {
                if (this.installationReportRecord[fieldConfig.name] !== null && 
                    this.installationReportRecord[fieldConfig.name] !== undefined && 
                    this.installationReportRecord[fieldConfig.name] !== '') {
                    const fieldValue = parseFloat(this.installationReportRecord[fieldConfig.name]);
                    if (!isNaN(fieldValue) && (fieldValue < fieldConfig.min || fieldValue > fieldConfig.max)) {
                        const errorMessage = `${fieldConfig.label} must be between ${fieldConfig.min} and ${fieldConfig.max}`;
                        this.fieldValidationErrors[fieldConfig.name] = errorMessage;
                        
                        // Find the field element and try to set validation
                        const fieldElement = this.template.querySelector(`lightning-input-field[field-name="${fieldConfig.name}"]`);
                    if (fieldElement) {
                        try {
                            if (typeof fieldElement.setCustomValidity === 'function') {
                                fieldElement.setCustomValidity(errorMessage);
                                    fieldElement.reportValidity();
                            }
                        } catch (err) {
                                console.error(`Error setting validation for ${fieldConfig.name}:`, err);
                        }
                    }
                isValid = false;
                } else {
                        // Clear error if value is valid
                        if (this.fieldValidationErrors[fieldConfig.name]) {
                            delete this.fieldValidationErrors[fieldConfig.name];
                        }
                    }
                } else {
                    // Clear error if field is empty
                    if (this.fieldValidationErrors[fieldConfig.name]) {
                        delete this.fieldValidationErrors[fieldConfig.name];
                    }
                }
            });


            // Show single toast message if there are any validation errors
            if (!isValid) {
                showToast(this, 'Error', 'Please correct the validation errors before saving', 'error');
                this.showSpinner = false;
                return;
            }
        }

        // Validate TTO Installation Report numeric fields before saving
        if (this.isTTO) {
            let isValid = true;
            const ttoFieldValidations = [
                { name: 'Print_head_Resistance__c', min: 0, max: 9999, label: 'Print Head Resistance (Ohm)' },
                { name: 'Ribbon_Dia_D1__c', min: 1, max: 200, label: 'Ribbon Dia D1 (mm)' },
                { name: 'Ribbon_Dia_D2__c', min: 1, max: 200, label: 'Ribbon Dia D2 (mm)' },
                { name: 'Print_speed__c', min: 40, max: 800, label: 'Print Speed (mm/sec)' },
                { name: 'Ribbon_fail_count__c', min: 0, max: 244, label: 'Ribbon Fail Count (Nos)' },
                { name: 'Registration_Dot__c', min: 0, max: 384, label: 'Registration Dot' },
                { name: 'Debounce_time_ms__c', min: 0, max: 1000, label: 'Debounce Time (ms)' },
                { name: 'Print_Delay__c', min: 0, max: 5000, label: 'Print Delay' },
                { name: 'Pr_GO_Ignore__c', min: 0, max: 5000, label: 'PR-GO Ignore' },
                { name: 'Ribbon_Gap__c', min: -80, max: 150, label: 'Ribbon Gap (mm)' },
                { name: 'Output_Air_Pressure__c', min: 1, max: 8, label: 'Output Air Pressure (PSI)' },
                { name: 'Head_out_time_ms__c', min: 0, max: 1000, label: 'Head Out Time (ms)' },
                { name: 'Head_In_Time__c', min: 0, max: 200, label: 'Head In Time (ms)' },
                { name: 'Start_Border_Trim__c', min: 0, max: 20, label: 'Start Border Trim (mm)' },
                { name: 'End_Border_Trim__c', min: 0, max: 20, label: 'End Border Trim (mm)' },
                { name: 'Darkness__c', min: 0, max: 120, label: 'Darkness' }
            ];

            // Clear previous validation errors
            this.fieldValidationErrors = {};

            // Use setTimeout to ensure DOM is ready
            await new Promise(resolve => setTimeout(resolve, 0));

            ttoFieldValidations.forEach(fieldConfig => {
                if (this.installationReportRecord[fieldConfig.name] !== null && 
                    this.installationReportRecord[fieldConfig.name] !== undefined && 
                    this.installationReportRecord[fieldConfig.name] !== '') {
                    const fieldValue = parseFloat(this.installationReportRecord[fieldConfig.name]);
                    if (!isNaN(fieldValue) && (fieldValue < fieldConfig.min || fieldValue > fieldConfig.max)) {
                        const errorMessage = `${fieldConfig.label} must be between ${fieldConfig.min} and ${fieldConfig.max}`;
                        this.fieldValidationErrors[fieldConfig.name] = errorMessage;
                            
                            // Find the field element and try to set validation
                        const inputElement = this.template.querySelector(`lightning-input[name="${fieldConfig.name}"]`);
                        if (inputElement) {
                            try {
                                if (typeof inputElement.setCustomValidity === 'function') {
                                    inputElement.setCustomValidity(errorMessage);
                                    inputElement.reportValidity();
                                }
                            } catch (err) {
                                console.error(`Error setting validation for ${fieldConfig.name}:`, err);
                            }
                        }
                        isValid = false;
                    } else {
                        // Clear error if value is valid
                        if (this.fieldValidationErrors[fieldConfig.name]) {
                            delete this.fieldValidationErrors[fieldConfig.name];
                        }
                    }
                } else {
                    // Clear error if field is empty
                    if (this.fieldValidationErrors[fieldConfig.name]) {
                        delete this.fieldValidationErrors[fieldConfig.name];
                    }
                }
            });

            // Validate G_L_volt__c must be within 2% of L_N_volt__c
            const fieldA = this.installationReportRecord.L_N_volt__c;
            const fieldB = this.installationReportRecord.G_L_volt__c;

            if (fieldA !== undefined && fieldA !== null && fieldA !== '' && 
                fieldB !== undefined && fieldB !== null && fieldB !== '') {
                const lNValue = parseFloat(fieldA);
                const gLValue = parseFloat(fieldB);

                if (!isNaN(lNValue) && !isNaN(gLValue)) {
                    const tolerance = lNValue * 0.02;
                    const minValue = lNValue - tolerance;
                    const maxValue = lNValue + tolerance;

                    if (gLValue < minValue || gLValue > maxValue) {
                        const errorMessage = `G & L, volt. must be within 2% deviation of L & N, volt. (${minValue.toFixed(2)} - ${maxValue.toFixed(2)})`;
                        this.fieldValidationErrors = { ...this.fieldValidationErrors, G_L_volt__c: errorMessage };
                        
                        const fieldElement = this.template.querySelector(`lightning-input-field[field-name="G_L_volt__c"]`);
                        if (fieldElement) {
                            try {
                                const inputElement = fieldElement.inputElement || 
                                                   fieldElement.querySelector('input') || 
                                                   fieldElement.shadowRoot?.querySelector('input') ||
                                                   fieldElement;
                                if (inputElement && typeof inputElement.setCustomValidity === 'function') {
                                    inputElement.setCustomValidity(errorMessage);
                                    inputElement.reportValidity();
                                }
                            } catch (err) {
                                console.error('Error setting validation for G_L_volt__c:', err);
                            }
                        }
                        isValid = false;
                    } else {
                        // Value is valid, clear error from fieldValidationErrors
                        const updatedErrors = {};
                        Object.keys(this.fieldValidationErrors).forEach(key => {
                            if (key !== 'G_L_volt__c') {
                                updatedErrors[key] = this.fieldValidationErrors[key];
                            }
                        });
                        this.fieldValidationErrors = updatedErrors;
                        
                        // Clear error from input field
                        const fieldElement = this.template.querySelector(`lightning-input-field[field-name="G_L_volt__c"]`);
                        if (fieldElement) {
                            try {
                                const inputElement = fieldElement.inputElement || 
                                                   fieldElement.querySelector('input') || 
                                                   fieldElement.shadowRoot?.querySelector('input') ||
                                                   fieldElement;
                                if (inputElement && typeof inputElement.setCustomValidity === 'function') {
                                    inputElement.setCustomValidity('');
                                    inputElement.reportValidity();
                                }
                            } catch (err) {
                                console.error('Error clearing validation for G_L_volt__c:', err);
                            }
                        }
                    }
                }
            }

            // Show single toast message if there are any validation errors
            if (!isValid) {
                showToast(this, 'Error', 'Please correct the validation errors before saving', 'error');
                this.showSpinner = false;
                return;
            }
        }

        // Validate TIJ Installation Report numeric fields before saving
        if (this.isTIJ) {
            let isValid = true;
            const tijFieldValidations = [
                { name: 'L_N_volt__c', min: 180, max: 270, label: 'L & N, volt.' },
                { name: 'N_G_volt__c', min: 0, max: 5, label: 'N & G, volt.' },
                { name: 'Line_Speed_meter_per_Min__c', min: 0, max: 600, label: 'Line Speed meter per Min' }
            ];

            // Clear previous validation errors
            this.fieldValidationErrors = {};

            // Use setTimeout to ensure DOM is ready
            await new Promise(resolve => setTimeout(resolve, 0));

            // Special validation for Number_of_head__c (must be a positive integer)
            if (this.installationReportRecord.Number_of_head__c !== null && 
                this.installationReportRecord.Number_of_head__c !== undefined && 
                this.installationReportRecord.Number_of_head__c !== '') {
                const numericValue = parseFloat(this.installationReportRecord.Number_of_head__c);
                
                if (isNaN(numericValue)) {
                    const errorMessage = 'Number of head must be a valid number';
                    this.fieldValidationErrors.Number_of_head__c = errorMessage;
                    isValid = false;
                    
                    const fieldElement = this.template.querySelector(`lightning-input-field[field-name="Number_of_head__c"]`);
                            if (fieldElement) {
                                try {
                                    if (typeof fieldElement.setCustomValidity === 'function') {
                                        fieldElement.setCustomValidity(errorMessage);
                                                fieldElement.reportValidity();
                                            }
                        } catch (err) {
                            console.error('Error setting validation for Number_of_head__c:', err);
                        }
                    }
                } else if (numericValue <= 0) {
                    const errorMessage = 'Number of head must be a positive number (greater than 0)';
                    this.fieldValidationErrors.Number_of_head__c = errorMessage;
                    isValid = false;
                    
                    const fieldElement = this.template.querySelector(`lightning-input-field[field-name="Number_of_head__c"]`);
                    if (fieldElement) {
                        try {
                            if (typeof fieldElement.setCustomValidity === 'function') {
                                fieldElement.setCustomValidity(errorMessage);
                                        fieldElement.reportValidity();
                                    }
                        } catch (err) {
                            console.error('Error setting validation for Number_of_head__c:', err);
                                }
                            }
                } else if (!Number.isInteger(numericValue)) {
                    const errorMessage = 'Number of head must be a whole number';
                    this.fieldValidationErrors.Number_of_head__c = errorMessage;
                            isValid = false;
                    
                    const fieldElement = this.template.querySelector(`lightning-input-field[field-name="Number_of_head__c"]`);
                    if (fieldElement) {
                        try {
                            if (typeof fieldElement.setCustomValidity === 'function') {
                                fieldElement.setCustomValidity(errorMessage);
                                fieldElement.reportValidity();
                            }
                        } catch (err) {
                            console.error('Error setting validation for Number_of_head__c:', err);
                        }
                    }
                        } else {
                            // Clear error if value is valid
                    if (this.fieldValidationErrors.Number_of_head__c) {
                        delete this.fieldValidationErrors.Number_of_head__c;
                    }
                }
            }

            tijFieldValidations.forEach(fieldConfig => {
                if (this.installationReportRecord[fieldConfig.name] !== null && 
                    this.installationReportRecord[fieldConfig.name] !== undefined && 
                    this.installationReportRecord[fieldConfig.name] !== '') {
                    const fieldValue = parseFloat(this.installationReportRecord[fieldConfig.name]);
                    if (!isNaN(fieldValue) && (fieldValue < fieldConfig.min || fieldValue > fieldConfig.max)) {
                        const errorMessage = `${fieldConfig.label} must be between ${fieldConfig.min} and ${fieldConfig.max}`;
                        this.fieldValidationErrors[fieldConfig.name] = errorMessage;
                        
                        // Find the field element and try to set validation
                        const fieldElement = this.template.querySelector(`lightning-input-field[field-name="${fieldConfig.name}"]`);
                        const inputElement = this.template.querySelector(`lightning-input[name="${fieldConfig.name}"]`);
                            if (fieldElement) {
                                try {
                                    if (typeof fieldElement.setCustomValidity === 'function') {
                                        fieldElement.setCustomValidity(errorMessage);
                                                fieldElement.reportValidity();
                                            }
                            } catch (err) {
                                console.error(`Error setting validation for ${fieldConfig.name}:`, err);
                                        }
                        } else if (inputElement) {
                            try {
                                if (typeof inputElement.setCustomValidity === 'function') {
                                    inputElement.setCustomValidity(errorMessage);
                                    inputElement.reportValidity();
                                    }
                                } catch (err) {
                                console.error(`Error setting validation for ${fieldConfig.name}:`, err);
                                }
                            }
                isValid = false;
                        } else {
                            // Clear error if value is valid
                        if (this.fieldValidationErrors[fieldConfig.name]) {
                            delete this.fieldValidationErrors[fieldConfig.name];
                    }
                }
            } else {
                // Clear error if field is empty
                    if (this.fieldValidationErrors[fieldConfig.name]) {
                        delete this.fieldValidationErrors[fieldConfig.name];
                    }
                }
            });

            // Validate G_L_volt__c must be within 2% of L_N_volt__c
            const fieldA = this.installationReportRecord.L_N_volt__c;
            const fieldB = this.installationReportRecord.G_L_volt__c;

            if (fieldA !== undefined && fieldA !== null && fieldA !== '' && 
                fieldB !== undefined && fieldB !== null && fieldB !== '') {
                const lNValue = parseFloat(fieldA);
                const gLValue = parseFloat(fieldB);

                if (!isNaN(lNValue) && !isNaN(gLValue)) {
                    const tolerance = lNValue * 0.02;
                    const minValue = lNValue - tolerance;
                    const maxValue = lNValue + tolerance;

                    if (gLValue < minValue || gLValue > maxValue) {
                        const errorMessage = `G & L, volt. must be within 2% deviation of L & N, volt. (${minValue.toFixed(2)} - ${maxValue.toFixed(2)})`;
                        this.fieldValidationErrors = { ...this.fieldValidationErrors, G_L_volt__c: errorMessage };
                        
                        const fieldElement = this.template.querySelector(`lightning-input-field[field-name="G_L_volt__c"]`);
                        if (fieldElement) {
                            try {
                                const inputElement = fieldElement.inputElement || 
                                                   fieldElement.querySelector('input') || 
                                                   fieldElement.shadowRoot?.querySelector('input') ||
                                                   fieldElement;
                                if (inputElement && typeof inputElement.setCustomValidity === 'function') {
                                    inputElement.setCustomValidity(errorMessage);
                                    inputElement.reportValidity();
                                }
                            } catch (err) {
                                console.error('Error setting validation for G_L_volt__c:', err);
                            }
                        }
                        isValid = false;
                    } else {
                        // Value is valid, clear error from fieldValidationErrors
                        const updatedErrors = {};
                        Object.keys(this.fieldValidationErrors).forEach(key => {
                            if (key !== 'G_L_volt__c') {
                                updatedErrors[key] = this.fieldValidationErrors[key];
                            }
                        });
                        this.fieldValidationErrors = updatedErrors;
                        
                        // Clear error from input field
                        const fieldElement = this.template.querySelector(`lightning-input-field[field-name="G_L_volt__c"]`);
                        if (fieldElement) {
                            try {
                                const inputElement = fieldElement.inputElement || 
                                                   fieldElement.querySelector('input') || 
                                                   fieldElement.shadowRoot?.querySelector('input') ||
                                                   fieldElement;
                                if (inputElement && typeof inputElement.setCustomValidity === 'function') {
                                    inputElement.setCustomValidity('');
                                    inputElement.reportValidity();
                                }
                            } catch (err) {
                                console.error('Error clearing validation for G_L_volt__c:', err);
                            }
                        }
                    }
                }
            }

            // Show single toast message if there are any validation errors
            if (!isValid) {
                showToast(this, 'Error', 'Please correct the validation errors before saving', 'error');
            this.showSpinner = false;
            return;
        }
        }

        // Always send the explicit report type to Apex so it follows the correct branch
        const reportType = this.showInstallationReport ? 'InstallationReport' : 'ServiceReport';
        // eslint-disable-next-line no-console
        console.log('Calling saveReport with type:', reportType, 'record:', this.installationReportRecord?.Id);

        this.showSpinner = true;
        saveReport({
            installationReportRecord: this.installationReportRecord,
            serviceReportRecord: null,
            reportType: reportType,
            serviceReportObservations: [],
            workOrderChecklist: [],
            serviceAppointmentId: this.serviceAppointmentId,
            currentReportParameters: JSON.stringify(this.currentReportParameters)
        })
            .then(result => {
                // eslint-disable-next-line no-console
                console.log('saveReport success result:', result);
                if (result) {
                    this.installationReportRecord.IsSavedByUser__c = true;
                    if (this.installationReportRecord.Id) {
                        notifyRecordUpdateAvailable([{ recordId: this.installationReportRecord.Id }]);
                    }
                    // Parameters are now saved as part of the saveReport Apex call via currentReportParameters
                    showToast(this, 'Success', 'Installation report saved successfully', 'success');
                    this.handleGetInstallationReportDetails();
                } else {
                    // If Apex returned no payload, surface a friendly message so it doesn't
                    // look like the button did nothing.
                    showToast(this, 'Error', 'Failed to save Installation report. Please try again or contact admin.', 'error');
                }
            })
            .catch(error => {
                // eslint-disable-next-line no-console
                console.error('Error in saveReport:', error);
                showToast(this, 'Error', 'Something went wrong', 'error', error);
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }
    handlePreviewPDF() {
        // Use the component's active report type flags as the source of truth
        const isInstallation = this.showInstallationReport && !!this.installationReportRecord.Id;
        const isService = this.showServiceReport && !!this.serviceReportRecord.Id;
        const reportType = this.showInstallationReport ? 'InstallationReport' : 'ServiceReport';

        if (!isInstallation && !isService) {
            showToast(this, 'Error', 'Please save the report before previewing PDF', 'error');
            return;
        }

        // Validate that signature exists before allowing preview
        const reportRecord = isInstallation ? this.installationReportRecord : this.serviceReportRecord;
        if (!reportRecord || !reportRecord.Signature__c) {
            showToast(this, 'Error', 'Customer signature is required before previewing PDF. Please capture the signature first.', 'error');
            return;
        }

        this.showSpinner = true;

        // Call previewReport with the active record; other must be null
        previewReport({
            installationReportRecord: isInstallation ? this.installationReportRecord : null,
            serviceReportRecord: isService ? this.serviceReportRecord : null,
            reportType: reportType
        })
            .then(contentDocumentId => {
                if (contentDocumentId) {
                    // Open the generated preview document
                    navigateToFilePreview(this, contentDocumentId);
                } else {
                    showToast(this, 'Error', 'Failed to generate PDF preview', 'error');
                }
            })
            .catch(error => {
                console.error('Error previewing PDF:', error);
                showToast(this, 'Error', 'Failed to generate PDF preview: ' + (error.body?.message || error.message), 'error');
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }
    /*

    handlePreviewPDF() {
        console.log('=== LWC: handlePreviewPDF START ===');
        alert('DEBUG: handlePreviewPDF called');
        
        // For showServiceReport, use Preview flow (creates a preview ContentDocument each time)
        const isInstallation = !!this.installationReportRecord.Id;
        const isService = !!this.serviceReportRecord.Id;
        const reportType = isInstallation ? 'InstallationReport' : 'ServiceReport';
        
        console.log('DEBUG: isInstallation = ' + isInstallation);
        console.log('DEBUG: isService = ' + isService);
        console.log('DEBUG: reportType = ' + reportType);
        alert('DEBUG: isInstallation=' + isInstallation + ', isService=' + isService + ', reportType=' + reportType);

        if (!isInstallation && !isService) {
            console.error('ERROR: No record ID available');
            alert('ERROR: No record ID available');
            showToast(this, 'Error', 'Please save the report before previewing PDF', 'error');
            return;
        }

        // Validate that signature exists before allowing preview
        const reportRecord = isInstallation ? this.installationReportRecord : this.serviceReportRecord;
        console.log('DEBUG: reportRecord = ' + JSON.stringify(reportRecord, null, 2));
        console.log('DEBUG: reportRecord.Id = ' + (reportRecord ? reportRecord.Id : 'NULL'));
        console.log('DEBUG: reportRecord.Signature__c = ' + (reportRecord ? (reportRecord.Signature__c ? 'EXISTS' : 'NULL') : 'NULL'));
        
        if (!reportRecord || !reportRecord.Signature__c) {
            console.error('ERROR: Signature is missing');
            alert('ERROR: Signature is missing');
            showToast(this, 'Error', 'Customer signature is required before previewing PDF. Please capture the signature first.', 'error');
            return;
        }

        console.log('DEBUG: About to call previewReport Apex method');
        alert('DEBUG: About to call previewReport');
        this.showSpinner = true;

        // Call previewReport with the active record; other must be null
        const params = {
            installationReportRecord: isInstallation ? this.installationReportRecord : null,
            serviceReportRecord: isService ? this.serviceReportRecord : null,
            reportType: reportType
        };
        console.log('DEBUG: previewReport params = ' + JSON.stringify(params, null, 2));
        
        previewReport(params)
            .then(contentDocumentId => {
                console.log('=== LWC: previewReport SUCCESS ===');
                console.log('DEBUG: contentDocumentId = ' + contentDocumentId);
                alert('SUCCESS: contentDocumentId = ' + contentDocumentId);
                
                if (contentDocumentId) {
                    console.log('DEBUG: About to navigate to file preview');
                    // Open the generated preview document
                    navigateToFilePreview(this, contentDocumentId);
                } else {
                    console.error('ERROR: contentDocumentId is null');
                    alert('ERROR: contentDocumentId is null');
                    showToast(this, 'Error', 'Failed to generate PDF preview', 'error');
                }
            })
            .catch(error => {
                console.error('=== LWC: previewReport ERROR ===');
                console.error('ERROR: Error object:', error);
                console.error('ERROR: Error message:', error.body?.message || error.message);
                console.error('ERROR: Error body:', error.body);
                console.error('ERROR: Error stack:', error.stack);
                alert('ERROR: ' + (error.body?.message || error.message));
                showToast(this, 'Error', 'Failed to generate PDF preview: ' + (error.body?.message || error.message), 'error');
            })
            .finally(() => {
                console.log('=== LWC: handlePreviewPDF FINALLY ===');
                this.showSpinner = false;
            });
    }
            */

    handleSendEmail() {
        const recordId = this.installationReportRecord.Id || this.serviceReportRecord.Id;
        const email = this.installationReportRecord.Customer_Email__c || this.serviceReportRecord.Customer_Email__c;

        if (!recordId) return;

        navigateToLWC(this, 'fieldServiceSendDocument', {
            c__id: recordId,
            c__attachmentIds: recordId,
            c__toEmailAddresses: email
        });
    }

    handleOpenCaptureSignatureClick() {
        this.isSignatureModalOpen = true;
    }

    handleSignatureModalCaptureClick() {
        const pad = this.template.querySelector('c-signature-pad');
        if (pad) {
            const dataURL = pad.getSignature();
            const text = pad.getInputText();

            // Read the current values directly from the input fields in the modal
            const contactNumberField = this.template.querySelector('lightning-input[name="Customer_Contact_Number__c"]');
            const emailField = this.template.querySelector('lightning-input[name="Customer_Email__c"]');
            const designationField = this.template.querySelector('lightning-input[name="Customer_Designation__c"]');
            
            const contactNumber = contactNumberField ? contactNumberField.value : null;
            const email = emailField ? emailField.value : null;
            const designation = designationField ? designationField.value : null;

            if (this.showInstallationReport) {
                this.installationReportRecord = {
                    ...this.installationReportRecord,
                    Signature__c: dataURL ? `<img src="data:image/png;base64,${dataURL.split(',')[1]}" />` : null,
                    Signature_by__c: text || this.installationReportRecord.Signature_by__c,
                    Customer_Contact_Number__c: contactNumber !== null ? contactNumber : this.installationReportRecord.Customer_Contact_Number__c,
                    Customer_Email__c: email !== null ? email : this.installationReportRecord.Customer_Email__c,
                    Customer_Designation__c: designation !== null ? designation : this.installationReportRecord.Customer_Designation__c
                };
            } else if (this.showServiceReport) {
                this.serviceReportRecord = {
                    ...this.serviceReportRecord,
                    Signature__c: dataURL ? `<img src="data:image/png;base64,${dataURL.split(',')[1]}" />` : null,
                    Signature_by__c: text || this.serviceReportRecord.Signature_by__c,
                    Customer_Contact_Number__c: contactNumber !== null ? contactNumber : this.serviceReportRecord.Customer_Contact_Number__c,
                    Customer_Email__c: email !== null ? email : this.serviceReportRecord.Customer_Email__c,
                    Customer_Designation__c: designation !== null ? designation : this.serviceReportRecord.Customer_Designation__c
                };
            }
        }

        const reportRecord = this.showInstallationReport ? this.installationReportRecord : this.serviceReportRecord;

        // Validate Customer Contact Number - must be exactly 10 digits if provided
        if (reportRecord && reportRecord.Customer_Contact_Number__c) {
            const phoneRegex = /^[0-9]{10}$/;
            const contactNumber = String(reportRecord.Customer_Contact_Number__c).trim();
            if (contactNumber && !phoneRegex.test(contactNumber)) {
                showToast(this, 'Error', 'Customer Contact Number must be exactly 10 digits', 'error');
                // Also trigger validation on the input field
                const contactNumberField = this.template.querySelector('lightning-input[name="Customer_Contact_Number__c"]');
                if (contactNumberField) {
                    contactNumberField.setCustomValidity('Customer Contact Number must be exactly 10 digits');
                    contactNumberField.reportValidity();
                }
                return;
            }
        }
        if (this.isRemoteSupport && reportRecord) {
            if (
                !reportRecord.Signature__c ||
                !reportRecord.Signature_by__c ||
                !reportRecord.Customer_Email__c ||
                !reportRecord.Customer_Contact_Number__c ||
                !reportRecord.Customer_Designation__c
            ) {
                showToast(this, 'Error', 'Signature and signer details are required for remote support.', 'error');
                return;
            }
        }

        this.isSignatureModalOpen = false;
    }

    handleSignatureModalCancelClick() {
        this.isSignatureModalOpen = false;
    }

    handleSignatureModalClearClick() {
        const pad = this.template.querySelector('c-signature-pad');
        if (pad) {
            pad.clearSignature();
        }
        // this.installationReportRecord.Signature__c = undefined;
        // this.installationReportRecord.Signature_by__c = undefined;
        // this.installationReportRecord.Customer_Email__c = undefined;
        // this.installationReportRecord.Customer_Contact_Number__c = undefined;
        // this.installationReportRecord.Customer_Designation__c = undefined;
        if (this.showInstallationReport && this.installationReportRecord) {
            this.installationReportRecord.Signature__c = undefined;
            this.installationReportRecord.Signature_by__c = undefined;
            this.installationReportRecord.Customer_Email__c = undefined;
            this.installationReportRecord.Customer_Contact_Number__c = undefined;
            this.installationReportRecord.Customer_Designation__c = undefined;
        } else if (this.showServiceReport && this.serviceReportRecord) {
            this.serviceReportRecord.Signature__c = undefined;
            this.serviceReportRecord.Signature_by__c = undefined;
            this.serviceReportRecord.Customer_Email__c = undefined;
            this.serviceReportRecord.Customer_Contact_Number__c = undefined;
            this.serviceReportRecord.Customer_Designation__c = undefined;
        }
    }

    handleOnLoad(event) {
        if (event.target.objectApiName === 'Installation_Report__c') {
            this.installationReportRecord.isRecordEditFormLoaded = true;
        } else if (event.target.objectApiName === 'Service_Report__c') {
            this.serviceReportRecord.isRecordEditFormLoaded = true;
            if (!this.recordId && event.detail.recordId) {
                this.recordId = event.detail.recordId;
            }
        }
    }

    get isPreviewAndSendDisabled() {
        return !this.installationReportRecord.IsSavedByUser__c && !this.serviceReportRecord.IsSavedByUser__c;
    }

    // Get minimum date for Next Visit Proposed Date (tomorrow)
    get minNextVisitDate() {
        const tomorrow = new Date();
        tomorrow.setDate(tomorrow.getDate() + 1);
        // Format as YYYY-MM-DD for date input
        return tomorrow.toISOString().split('T')[0];
    }

    // Getter to check if Ink Part No and Make Up Part No should be disabled
    get isInkPartNoDisabled() {
        return !this.isFirstServiceReport;
    }

    // Getters for new TIJ table
    get autoManualOptions() {
        return [
            { label: 'Auto', value: 'Auto' },
            { label: 'Manual', value: 'Manual' }
        ];
    }

    get externalInternalOptions() {
        return [
            { label: 'External', value: 'External' },
            { label: 'Internal', value: 'Internal' }
        ];
    }

    get closeTimesOptions() {
        return [
            { label: 'Close', value: 'Close' },
            { label: 'Times', value: 'Times' }
        ];
    }

    get beepSignalShieldingOptions() {
        return [
            { label: 'Beep', value: 'Beep' },
            { label: 'Signal shielding', value: 'Signal shielding' }
        ];
    }

    get yesNoOptions() {
        return [
            { label: 'Yes', value: 'Yes' },
            { label: 'NO', value: 'NO' }
        ];
    }

    get nozzleSelectValueOptions() {
        return [
            { label: '1', value: '1' },
            { label: '2', value: '2' },
            { label: '3', value: '3' },
            { label: '4', value: '4' }
        ];
    }

    // Get processed rows (expand rows with checkboxes) - Based on CSV structure
    get processedTijTableRows() {
        const rows = [];
        this.tijTableRows.forEach((row, index) => {
            // 1. Print head Firing Voltage: Auto/Manual
            if (row.key === 'print_head_firing_voltage') {
                rows.push({
                    ...row,
                    key: row.key + '_auto',
                    optionListValue: 'Auto',
                    optionListChecked: row.optionList === 'Auto',
                    selectionType: row.optionList === 'Auto' ? 'Auto' : '',
                    selectionValue: row.optionList === 'Auto' ? 'N/A' : '',
                    isPulseValue: false,
                    isNozzleSelect: false,
                    isPurgingAutoJet2Auto: false,
                    isIntervalRow: false,
                    isQuantityRow: false,
                    isSelectionTypeDisabled: true,
                    isSelectionValueDisabled: true,
                    showParameterName: true,
                    parameterRowspan: 2
                });
                rows.push({
                    ...row,
                    key: row.key + '_manual',
                    optionListValue: 'Manual',
                    optionListChecked: row.optionList === 'Manual',
                    selectionType: row.optionList === 'Manual' ? 'Manual' : '',
                    selectionValue: row.optionList === 'Manual' ? (row.selectionValue || '') : '',
                    isPulseValue: false,
                    isNozzleSelect: false,
                    isPurgingAutoJet2Auto: false,
                    isIntervalRow: false,
                    isQuantityRow: false,
                    isSelectionTypeDisabled: true,
                    isSelectionValueDisabled: false,
                    showParameterName: false,
                    parameterRowspan: 0
                });
            } 
            // 2. Pulse Value: N/A
            else if (row.key === 'pulse_value') {
                // Pulse Value: Single row with N/A
                rows.push({
                    ...row,
                    isPulseValue: true,
                    isNozzleSelect: false,
                    isPurgingAutoJet2Auto: false,
                    isIntervalRow: false,
                    isQuantityRow: false,
                    isSelectionTypeDisabled: true,
                    isSelectionValueDisabled: false,
                    optionListValue: 'N/A',
                    optionListChecked: false,
                    showParameterName: true,
                    parameterRowspan: 1
                });
            } 
            // 3. Auto jet setting: Auto/Manual
            else if (row.key === 'auto_jet_setting') {
                rows.push({
                    ...row,
                    key: row.key + '_auto',
                    optionListValue: 'Auto',
                    optionListChecked: row.optionList === 'Auto',
                    selectionType: row.optionList === 'Auto' ? 'Auto' : '',
                    selectionValue: row.optionList === 'Auto' ? 'N/A' : '',
                    isPulseValue: false,
                    isNozzleSelect: false,
                    isPurgingAutoJet2Auto: false,
                    isIntervalRow: false,
                    isQuantityRow: false,
                    isSelectionTypeDisabled: true,
                    isSelectionValueDisabled: true,
                    showParameterName: true,
                    parameterRowspan: 2
                });
                rows.push({
                    ...row,
                    key: row.key + '_manual',
                    optionListValue: 'Manual',
                    optionListChecked: row.optionList === 'Manual',
                    selectionType: row.optionList === 'Manual' ? 'Manual' : '',
                    selectionValue: row.optionList === 'Manual' ? (row.selectionValue || '') : '',
                    isPulseValue: false,
                    isNozzleSelect: false,
                    isPurgingAutoJet2Auto: false,
                    isIntervalRow: false,
                    isQuantityRow: false,
                    isSelectionTypeDisabled: true,
                    isSelectionValueDisabled: false,
                    showParameterName: false,
                    parameterRowspan: 0
                });
            } 
            // 4. Noizzle Select: Splice with values 1,2,3,4
            else if (row.key === 'nozzle_select') {
                if (row.optionList === 'Splice') {
                    // First row: Splice checkbox
                    rows.push({
                        ...row,
                        key: row.key + '_splice',
                        optionListValue: 'Splice',
                        optionListChecked: true,
                        selectionType: 'Splice',
                        selectionValue: 'N/A',
                        isPulseValue: false,
                        isNozzleSelect: false,
                        isPurgingAutoJet2Auto: false,
                        isIntervalRow: false,
                        isQuantityRow: false,
                        isSelectionTypeDisabled: true,
                        isSelectionValueDisabled: true,
                        showParameterName: true,
                        parameterRowspan: 5  // Splice + 4 value rows
                    });
                    // Then rows for 1, 2, 3, 4
                    ['1', '2', '3', '4'].forEach((val, idx) => {
                        rows.push({
                            ...row,
                            key: row.key + '_value_' + val,
                            optionListValue: '',
                            optionListChecked: false,
                            selectionType: val,
                            selectionValue: row.selectionValue === val ? row.selectionValue : '',
                            isPulseValue: false,
                            isNozzleSelect: true,
                            isPurgingAutoJet2Auto: false,
                            isIntervalRow: false,
                            isQuantityRow: false,
                            isNozzleValueRow: true,
                            isSelectionTypeDisabled: true,
                            isSelectionValueDisabled: false,
                            showParameterName: false,
                            parameterRowspan: 0
                        });
                    });
                } else {
                    // No selection - show Splice checkbox only
                    rows.push({
                        ...row,
                        key: row.key + '_splice',
                        optionListValue: 'Splice',
                        optionListChecked: false,
                        selectionType: '',
                        selectionValue: '',
                        isPulseValue: false,
                        isNozzleSelect: false,
                        isPurgingAutoJet2Auto: false,
                        isIntervalRow: false,
                        isQuantityRow: false,
                        isSelectionTypeDisabled: true,
                        isSelectionValueDisabled: false,
                        showParameterName: true,
                        parameterRowspan: 1
                    });
                }
            } 
            // 5. Purging auto jet: Auto/Manual with Interval/Quantity
            else if (row.key === 'purging_auto_jet') {
                if (row.optionList === 'Auto') {
                    rows.push({
                        ...row,
                        key: row.key + '_auto',
                        optionListValue: 'Auto',
                        optionListChecked: true,
                        selectionType: 'Auto',
                        selectionValue: 'N/A',
                        isPulseValue: false,
                        isNozzleSelect: false,
                        isPurgingAutoJet2Auto: false,
                        isIntervalRow: false,
                        isQuantityRow: false,
                        isSelectionTypeDisabled: true,
                        isSelectionValueDisabled: true,
                        showParameterName: true,
                        parameterRowspan: 2
                    });
                    rows.push({
                        ...row,
                        key: row.key + '_manual',
                        optionListValue: 'Manual',
                        optionListChecked: false,
                        isPulseValue: false,
                        isNozzleSelect: false,
                        isPurgingAutoJet2Auto: false,
                        isIntervalRow: false,
                        isQuantityRow: false,
                        isSelectionTypeDisabled: true,
                        isSelectionValueDisabled: false,
                        showParameterName: false,
                        parameterRowspan: 0
                    });
                } else if (row.optionList === 'Manual') {
                    rows.push({
                        ...row,
                        key: row.key + '_auto',
                        optionListValue: 'Auto',
                        optionListChecked: false,
                        isPulseValue: false,
                        isNozzleSelect: false,
                        isPurgingAutoJet2Auto: false,
                        isIntervalRow: false,
                        isQuantityRow: false,
                        isSelectionTypeDisabled: true,
                        isSelectionValueDisabled: false,
                        showParameterName: true,
                        parameterRowspan: 4  // Auto, Manual, Interval, Quantity
                    });
                    rows.push({
                        ...row,
                        key: row.key + '_manual',
                        optionListValue: 'Manual',
                        optionListChecked: true,
                        isPulseValue: false,
                        isNozzleSelect: false,
                        isPurgingAutoJet2Auto: false,
                        isIntervalRow: false,
                        isQuantityRow: false,
                        isSelectionTypeDisabled: true,
                        isSelectionValueDisabled: false,
                        showParameterName: false,
                        parameterRowspan: 0
                    });
                    // Interval row
                    rows.push({
                        ...row,
                        key: row.key + '_interval',
                        optionListValue: '',
                        optionListChecked: false,
                        selectionType: 'Interval',
                        selectionValue: row.intervalValue || '',
                        isIntervalRow: true,
                        isQuantityRow: false,
                        isPulseValue: false,
                        isNozzleSelect: false,
                        isPurgingAutoJet2Auto: false,
                        isSelectionTypeDisabled: true,
                        isSelectionValueDisabled: false,
                        showParameterName: false,
                        parameterRowspan: 0
                    });
                    // Quantity row
                    rows.push({
                        ...row,
                        key: row.key + '_quantity',
                        optionListValue: '',
                        optionListChecked: false,
                        selectionType: 'Quantity',
                        selectionValue: row.quantityValue || '',
                        isIntervalRow: false,
                        isQuantityRow: true,
                        isPulseValue: false,
                        isNozzleSelect: false,
                        isPurgingAutoJet2Auto: false,
                        isSelectionTypeDisabled: true,
                        isSelectionValueDisabled: false,
                        showParameterName: false,
                        parameterRowspan: 0
                    });
                } else {
                    rows.push({
                        ...row,
                        key: row.key + '_auto',
                        optionListValue: 'Auto',
                        optionListChecked: false,
                        isPulseValue: false,
                        isNozzleSelect: false,
                        isPurgingAutoJet2Auto: false,
                        isIntervalRow: false,
                        isQuantityRow: false,
                        isSelectionTypeDisabled: true,
                        isSelectionValueDisabled: false,
                        showParameterName: true,
                        parameterRowspan: 2
                    });
                    rows.push({
                        ...row,
                        key: row.key + '_manual',
                        optionListValue: 'Manual',
                        optionListChecked: false,
                        isPulseValue: false,
                        isNozzleSelect: false,
                        isPurgingAutoJet2Auto: false,
                        isIntervalRow: false,
                        isQuantityRow: false,
                        isSelectionTypeDisabled: true,
                        isSelectionValueDisabled: false,
                        showParameterName: false,
                        parameterRowspan: 0
                    });
                }
            }
            // 6-8. DPI X, DPI -Y, Printhead Delay: All N/A
            else if (row.key === 'dpi_x' || row.key === 'dpi_y' || row.key === 'printhead_delay') {
                rows.push({
                    ...row,
                    isPulseValue: false,
                    isNozzleSelect: false,
                    isPurgingAutoJet2Auto: false,
                    isIntervalRow: false,
                    isQuantityRow: false,
                    isSelectionTypeDisabled: true,
                    isSelectionValueDisabled: false,
                    optionListValue: 'N/A',
                    optionListChecked: false,
                    selectionType: 'N/A',
                    showParameterName: true,
                    parameterRowspan: 1
                });
            }
            // 9. Trigger Mode: External/Internal
            else if (row.key === 'trigger_mode') {
                rows.push({
                    ...row,
                    key: row.key + '_external',
                    optionListValue: 'External',
                    optionListChecked: row.optionList === 'External',
                    selectionType: row.optionList === 'External' ? 'External' : '',
                    selectionValue: row.optionList === 'External' ? 'N/A' : '',
                    isPulseValue: false,
                    isNozzleSelect: false,
                    isPurgingAutoJet2Auto: false,
                    isIntervalRow: false,
                    isQuantityRow: false,
                    isSelectionTypeDisabled: true,
                    isSelectionValueDisabled: true,
                    showParameterName: true,
                    parameterRowspan: 2
                });
                rows.push({
                    ...row,
                    key: row.key + '_internal',
                    optionListValue: 'Internal',
                    optionListChecked: row.optionList === 'Internal',
                    selectionType: row.optionList === 'Internal' ? 'Internal' : '',
                    selectionValue: row.optionList === 'Internal' ? 'N/A' : '',
                    isPulseValue: false,
                    isNozzleSelect: false,
                    isPurgingAutoJet2Auto: false,
                    isIntervalRow: false,
                    isQuantityRow: false,
                    isSelectionTypeDisabled: true,
                    isSelectionValueDisabled: true,
                    showParameterName: false,
                    parameterRowspan: 0
                });
            }
            // 10. Continuous print: Close/Times
            else if (row.key === 'continuous_print') {
                rows.push({
                    ...row,
                    key: row.key + '_close',
                    optionListValue: 'Close',
                    optionListChecked: row.optionList === 'Close',
                    selectionType: row.optionList === 'Close' ? 'Close' : '',
                    selectionValue: row.optionList === 'Close' ? 'N/A' : '',
                    isPulseValue: false,
                    isNozzleSelect: false,
                    isPurgingAutoJet2Auto: false,
                    isIntervalRow: false,
                    isQuantityRow: false,
                    isSelectionTypeDisabled: true,
                    isSelectionValueDisabled: true,
                    showParameterName: true,
                    parameterRowspan: 2
                });
                rows.push({
                    ...row,
                    key: row.key + '_times',
                    optionListValue: 'Times',
                    optionListChecked: row.optionList === 'Times',
                    selectionType: row.optionList === 'Times' ? 'Times' : '',
                    selectionValue: row.optionList === 'Times' ? (row.selectionValue || '') : '',
                    isPulseValue: false,
                    isNozzleSelect: false,
                    isPurgingAutoJet2Auto: false,
                    isIntervalRow: false,
                    isQuantityRow: false,
                    isSelectionTypeDisabled: true,
                    isSelectionValueDisabled: false,
                    showParameterName: false,
                    parameterRowspan: 0
                });
            }
            // 11. Photocell setting: Beep/Signal shielding
            else if (row.key === 'photocell_setting') {
                rows.push({
                    ...row,
                    key: row.key + '_beep',
                    optionListValue: 'Beep',
                    optionListChecked: row.optionList === 'Beep',
                    selectionType: row.optionList === 'Beep' ? 'Beep' : '',
                    selectionValue: row.optionList === 'Beep' ? 'N/A' : '',
                    isPulseValue: false,
                    isNozzleSelect: false,
                    isPurgingAutoJet2Auto: false,
                    isIntervalRow: false,
                    isQuantityRow: false,
                    isSelectionTypeDisabled: true,
                    isSelectionValueDisabled: true,
                    showParameterName: true,
                    parameterRowspan: 2
                });
                rows.push({
                    ...row,
                    key: row.key + '_signal',
                    optionListValue: 'Signal shielding',
                    optionListChecked: row.optionList === 'Signal shielding',
                    selectionType: row.optionList === 'Signal shielding' ? 'Signal Shielding' : '',
                    selectionValue: row.optionList === 'Signal shielding' ? 'N/A' : '',
                    isPulseValue: false,
                    isNozzleSelect: false,
                    isPurgingAutoJet2Auto: false,
                    isIntervalRow: false,
                    isQuantityRow: false,
                    isSelectionTypeDisabled: true,
                    isSelectionValueDisabled: true,
                    showParameterName: false,
                    parameterRowspan: 0
                });
            }
            // 12. Encoder setting: Yes/NO with PPR/Diameter
            else if (row.key === 'encoder_setting') {
                if (row.optionList === 'Yes') {
                    rows.push({
                        ...row,
                        key: row.key + '_yes',
                        optionListValue: 'Yes',
                        optionListChecked: true,
                        isPulseValue: false,
                        isNozzleSelect: false,
                        isPurgingAutoJet2Auto: false,
                        isIntervalRow: false,
                        isQuantityRow: false,
                        isSelectionTypeDisabled: true,
                        isSelectionValueDisabled: false,
                        showParameterName: true,
                        parameterRowspan: 4  // Yes, NO, PPR, Diameter
                    });
                    rows.push({
                        ...row,
                        key: row.key + '_no',
                        optionListValue: 'NO',
                        optionListChecked: false,
                        selectionType: '',
                        selectionValue: '',
                        isPulseValue: false,
                        isNozzleSelect: false,
                        isPurgingAutoJet2Auto: false,
                        isIntervalRow: false,
                        isQuantityRow: false,
                        isSelectionTypeDisabled: true,
                        isSelectionValueDisabled: false,
                        showParameterName: false,
                        parameterRowspan: 0
                    });
                    // PPR row
                    rows.push({
                        ...row,
                        key: row.key + '_ppr',
                        optionListValue: '',
                        optionListChecked: false,
                        selectionType: 'PPR',
                        selectionValue: row.pprValue || '',
                        pprValue: row.pprValue || '',
                        isPulseValue: false,
                        isNozzleSelect: false,
                        isPurgingAutoJet2Auto: false,
                        isIntervalRow: false,
                        isQuantityRow: false,
                        isPprRow: true,
                        isDiameterRow: false,
                        isSelectionTypeDisabled: true,
                        isSelectionValueDisabled: false,
                        showParameterName: false,
                        parameterRowspan: 0
                    });
                    // Diameter row
                    rows.push({
                        ...row,
                        key: row.key + '_diameter',
                        optionListValue: '',
                        optionListChecked: false,
                        selectionType: 'Diameter',
                        selectionValue: row.diameterValue || '',
                        diameterValue: row.diameterValue || '',
                        isPulseValue: false,
                        isNozzleSelect: false,
                        isPurgingAutoJet2Auto: false,
                        isIntervalRow: false,
                        isQuantityRow: false,
                        isPprRow: false,
                        isDiameterRow: true,
                        isSelectionTypeDisabled: true,
                        isSelectionValueDisabled: false,
                        showParameterName: false,
                        parameterRowspan: 0
                    });
                } else if (row.optionList === 'NO') {
                    rows.push({
                        ...row,
                        key: row.key + '_yes',
                        optionListValue: 'Yes',
                        optionListChecked: false,
                        isPulseValue: false,
                        isNozzleSelect: false,
                        isPurgingAutoJet2Auto: false,
                        isIntervalRow: false,
                        isQuantityRow: false,
                        isSelectionTypeDisabled: true,
                        isSelectionValueDisabled: false,
                        showParameterName: true,
                        parameterRowspan: 2
                    });
                    rows.push({
                        ...row,
                        key: row.key + '_no',
                        optionListValue: 'NO',
                        optionListChecked: true,
                        selectionType: 'N/A',
                        selectionValue: 'N/A',
                        isPulseValue: false,
                        isNozzleSelect: false,
                        isPurgingAutoJet2Auto: false,
                        isIntervalRow: false,
                        isQuantityRow: false,
                        isSelectionTypeDisabled: true,
                        isSelectionValueDisabled: true,
                        showParameterName: false,
                        parameterRowspan: 0
                    });
                } else {
                    rows.push({
                        ...row,
                        key: row.key + '_yes',
                        optionListValue: 'Yes',
                        optionListChecked: false,
                        isPulseValue: false,
                        isNozzleSelect: false,
                        isPurgingAutoJet2Auto: false,
                        isIntervalRow: false,
                        isQuantityRow: false,
                        isSelectionTypeDisabled: true,
                        isSelectionValueDisabled: false,
                        showParameterName: true,
                        parameterRowspan: 2
                    });
                    rows.push({
                        ...row,
                        key: row.key + '_no',
                        optionListValue: 'NO',
                        optionListChecked: false,
                        isPulseValue: false,
                        isNozzleSelect: false,
                        isPurgingAutoJet2Auto: false,
                        isIntervalRow: false,
                        isQuantityRow: false,
                        isSelectionTypeDisabled: true,
                        isSelectionValueDisabled: false,
                        showParameterName: false,
                        parameterRowspan: 0
                    });
                }
            }
        });
        return rows;
    }

    // Helper to get row by key
    getRowByKey(key) {
        return this.tijTableRows.find(r => r.key === key);
    }

    // Helper to check if selection type is disabled
    isSelectionTypeDisabled(row) {
        if (row.key === 'pulse_value') {
            return true; // Always disabled for Pulse Value
        }
        if (row.key === 'purging_auto_jet_1' || row.key === 'auto_jet_setting') {
            return true; // Always disabled
        }
        if (row.key === 'nozzle_select') {
            return true; // Always disabled
        }
        if (row.key === 'purging_auto_jet_2') {
            if (row.optionList === 'Auto') {
                return false; // Editable when Auto
            }
            return true; // Disabled when Manual (shows as Interval/Quantity)
        }
        // For expanded rows (Interval/Quantity), show as read-only text
        if (row.isIntervalRow || row.isQuantityRow) {
            return true; // Show as read-only text, not dropdown
        }
        return false;
    }

    // Helper to check if selection value is disabled
    isSelectionValueDisabled(row) {
        if (row.key === 'pulse_value') {
            return false; // Editable
        }
        if (row.key === 'purging_auto_jet_1' || row.key === 'auto_jet_setting') {
            return row.optionList === 'Auto';
        }
        if (row.key === 'nozzle_select') {
            return false; // Always editable (dropdown)
        }
        if (row.key === 'purging_auto_jet_2') {
            if (row.optionList === 'Auto') {
                return false; // Editable when Auto
            }
            return false; // Editable for Interval/Quantity rows
        }
        // For expanded rows (Interval/Quantity), always editable
        if (row.isIntervalRow || row.isQuantityRow) {
            return false;
        }
        return false;
    }

    // Handler for new TIJ table changes
    handleTijTableChange(event) {
        const field = event.target.dataset.field;
        const value = event.detail.value;
        const checked = event.detail.checked;
        const rowKey = event.target.dataset.rowKey;
        
        // Handle checkbox changes for Option List
        if (field === 'optionListCheckbox') {
            // Get value from data attribute
            const optionValue = event.target.dataset.value;
            
            // Extract original key (remove all suffixes)
            let originalKey = rowKey;
            const suffixes = ['_auto', '_manual', '_splice', '_head', '_external', '_internal', '_close', '_times', '_beep', '_signal', '_yes', '_no', '_value_1', '_value_2', '_value_3', '_value_4', '_interval', '_quantity', '_ppr', '_diameter'];
            for (const suffix of suffixes) {
                if (rowKey.includes(suffix)) {
                    originalKey = rowKey.replace(suffix, '');
                    break;
                }
            }
            
            const originalRow = this.tijTableRows.find(r => r.key === originalKey);
            if (!originalRow) return;
            
            if (checked) {
                // Update the original row's optionList
                originalRow.optionList = optionValue;
                
                // Apply validation logic based on row type
                if (originalKey === 'print_head_firing_voltage' || originalKey === 'auto_jet_setting') {
                    if (optionValue === 'Auto') {
                        originalRow.selectionType = 'Auto';
                        originalRow.selectionValue = 'N/A';
                    } else if (optionValue === 'Manual') {
                        originalRow.selectionType = 'Manual';
                        if (!originalRow.selectionValue || originalRow.selectionValue === 'N/A') {
                            originalRow.selectionValue = '';
                        }
                    }
                } else if (originalKey === 'nozzle_select') {
                    if (optionValue === 'Splice') {
                        originalRow.selectionType = 'Splice';
                    }
                } else if (originalKey === 'purging_auto_jet') {
                    if (optionValue === 'Auto') {
                        originalRow.selectionType = 'Auto';
                        originalRow.selectionValue = 'N/A';
                    } else if (optionValue === 'Manual') {
                        originalRow.intervalValue = '';
                        originalRow.quantityValue = '';
                    }
                } else if (originalKey === 'trigger_mode') {
                    if (optionValue === 'External') {
                        originalRow.selectionType = 'External';
                        originalRow.selectionValue = 'N/A';
                    } else if (optionValue === 'Internal') {
                        originalRow.selectionType = 'Internal';
                        originalRow.selectionValue = 'N/A';
                    }
                } else if (originalKey === 'continuous_print') {
                    if (optionValue === 'Close') {
                        originalRow.selectionType = 'Close';
                        originalRow.selectionValue = 'N/A';
                    } else if (optionValue === 'Times') {
                        originalRow.selectionType = 'Times';
                        if (!originalRow.selectionValue || originalRow.selectionValue === 'N/A') {
                            originalRow.selectionValue = '';
                        }
                    }
                } else if (originalKey === 'photocell_setting') {
                    if (optionValue === 'Beep') {
                        originalRow.selectionType = 'Beep';
                        originalRow.selectionValue = 'N/A';
                    } else if (optionValue === 'Signal shielding') {
                        originalRow.selectionType = 'Signal Shielding';
                        originalRow.selectionValue = 'N/A';
                    }
                } else if (originalKey === 'encoder_setting') {
                    if (optionValue === 'Yes') {
                        originalRow.pprValue = '';
                        originalRow.diameterValue = '';
                    } else if (optionValue === 'NO') {
                        originalRow.selectionType = 'N/A';
                        originalRow.selectionValue = 'N/A';
                    }
                }
            } else {
                // Unchecking - only clear if this was the selected option
                if (originalRow.optionList === optionValue) {
                    originalRow.optionList = '';
                    // Clear related fields based on parameter type
                    if (originalKey === 'print_head_firing_voltage' || originalKey === 'auto_jet_setting') {
                        originalRow.selectionType = '';
                        originalRow.selectionValue = '';
                    } else if (originalKey === 'nozzle_select') {
                        originalRow.selectionType = '';
                        originalRow.selectionValue = '';
                    } else if (originalKey === 'purging_auto_jet') {
                        originalRow.selectionType = '';
                        originalRow.selectionValue = '';
                        originalRow.intervalValue = '';
                        originalRow.quantityValue = '';
                    } else if (originalKey === 'trigger_mode') {
                        originalRow.selectionType = '';
                        originalRow.selectionValue = '';
                    } else if (originalKey === 'continuous_print') {
                        originalRow.selectionType = '';
                        originalRow.selectionValue = '';
                    } else if (originalKey === 'photocell_setting') {
                        originalRow.selectionType = '';
                        originalRow.selectionValue = '';
                    } else if (originalKey === 'encoder_setting') {
                        originalRow.selectionType = '';
                        originalRow.selectionValue = '';
                        originalRow.pprValue = '';
                        originalRow.diameterValue = '';
                    }
                }
            }
            
            // Force reactivity
            this.tijTableRows = [...this.tijTableRows];
            return;
        }
        
        // Handle expanded rows (Interval/Quantity for Purging auto jet)
        if (rowKey.includes('purging_auto_jet_interval')) {
            const mainRow = this.tijTableRows.find(r => r.key === 'purging_auto_jet');
            if (mainRow && field === 'selectionValue') {
                mainRow.intervalValue = value;
            }
            this.tijTableRows = [...this.tijTableRows];
            return;
        } else if (rowKey.includes('purging_auto_jet_quantity')) {
            const mainRow = this.tijTableRows.find(r => r.key === 'purging_auto_jet');
            if (mainRow && field === 'selectionValue') {
                mainRow.quantityValue = value;
            }
            this.tijTableRows = [...this.tijTableRows];
            return;
        }
        
        // Handle PPR and Diameter for Encoder setting
        if (rowKey.includes('encoder_setting_ppr')) {
            const mainRow = this.tijTableRows.find(r => r.key === 'encoder_setting');
            if (mainRow && field === 'selectionValue') {
                mainRow.pprValue = value;
            }
            this.tijTableRows = [...this.tijTableRows];
            return;
        } else if (rowKey.includes('encoder_setting_diameter')) {
            const mainRow = this.tijTableRows.find(r => r.key === 'encoder_setting');
            if (mainRow && field === 'selectionValue') {
                mainRow.diameterValue = value;
            }
            this.tijTableRows = [...this.tijTableRows];
            return;
        }
        
        // Handle nozzle select value rows (1, 2, 3, 4)
        if (rowKey.includes('nozzle_select_value_')) {
            const mainRow = this.tijTableRows.find(r => r.key === 'nozzle_select');
            if (mainRow && field === 'selectionValue') {
                // Update selectionValue with the selected value (1, 2, 3, or 4)
                mainRow.selectionValue = value;
            }
            this.tijTableRows = [...this.tijTableRows];
            return;
        }
        
        // Handle other fields (selectionType, selectionValue) for expanded rows
        const suffixes = ['_auto', '_manual', '_splice', '_head', '_external', '_internal', '_close', '_times', '_beep', '_signal', '_yes', '_no'];
        let hasSuffix = false;
        let originalKey = rowKey;
        for (const suffix of suffixes) {
            if (rowKey.includes(suffix)) {
                originalKey = rowKey.replace(suffix, '');
                hasSuffix = true;
                break;
            }
        }
        
        if (hasSuffix) {
            const originalRow = this.tijTableRows.find(r => r.key === originalKey);
            if (!originalRow) return;
            
            if (field === 'selectionValue') {
                // Only update if the checkbox for this row is checked
                let optionValue = '';
                if (rowKey.includes('_auto')) optionValue = 'Auto';
                else if (rowKey.includes('_manual')) optionValue = 'Manual';
                else if (rowKey.includes('_splice')) optionValue = 'Splice';
                else if (rowKey.includes('_external')) optionValue = 'External';
                else if (rowKey.includes('_internal')) optionValue = 'Internal';
                else if (rowKey.includes('_close')) optionValue = 'Close';
                else if (rowKey.includes('_times')) optionValue = 'Times';
                else if (rowKey.includes('_beep')) optionValue = 'Beep';
                else if (rowKey.includes('_signal')) optionValue = 'Signal shielding';
                else if (rowKey.includes('_yes')) optionValue = 'Yes';
                else if (rowKey.includes('_no')) optionValue = 'NO';
                
                if (originalRow.optionList === optionValue) {
                    originalRow.selectionValue = value;
                }
            } else if (field === 'selectionType') {
                originalRow.selectionType = value;
            }
            
            this.tijTableRows = [...this.tijTableRows];
            return;
        }
        
        // Handle regular rows (shouldn't happen with new structure, but keep for safety)
        const rowIndex = this.tijTableRows.findIndex(r => r.key === rowKey);
        if (rowIndex !== -1) {
            const row = this.tijTableRows[rowIndex];
            if (field === 'selectionType') {
                row.selectionType = value;
            } else if (field === 'selectionValue') {
                row.selectionValue = value;
            }
            this.tijTableRows = [...this.tijTableRows];
        }
    }

    // handlePreviewPDF() {
    //     const recordId = this.installationReportRecord.Id || this.serviceReportRecord.Id;
    //     const reportType = this.installationReportRecord.Id ? 'InstallationReport' : 'ServiceReport';

    //     if (!recordId) {
    //         showToast(this, 'Error', 'Please save the report before previewing PDF', 'error');
    //         return;
    //     }

    //     this.showSpinner = true;

    //     previewReport({
    //         installationReportRecord: this.installationReportRecord.Id ? this.installationReportRecord : null,
    //         serviceReportRecord: this.serviceReportRecord.Id ? this.serviceReportRecord : null,
    //         reportType: reportType
    //     })
    //         .then(result => {
    //             if (result) {
    //                 // Navigate to the preview document
    //                 navigateToFilePreview(this, result);
    //             } else {
    //                 showToast(this, 'Error', 'Failed to generate PDF preview', 'error');
    //             }
    //         })
    //         .catch(error => {
    //             console.error('Error previewing PDF:', error);
    //             showToast(this, 'Error', 'Failed to generate PDF preview: ' + error.body?.message || error.message, 'error');
    //         })
    //         .finally(() => {
    //             this.showSpinner = false;
    //         });
    // }
}