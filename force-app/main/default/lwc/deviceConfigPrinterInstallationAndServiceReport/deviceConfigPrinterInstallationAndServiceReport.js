import { LightningElement, track, api } from 'lwc';

export default class DeviceConfigPrinterInstallationAndServiceReport extends LightningElement {
    @track serviceReportParameters = [];
    @track isAccordionOpen = {
        deviceConfig: true
    };

    // Computed properties for accordion icons
    get deviceConfigIcon() {
        return this.isAccordionOpen.deviceConfig ? 'utility:chevrondown' : 'utility:chevronright';
    }

    get deviceConfigContentClass() {
        return `accordion-content ${this.isAccordionOpen.deviceConfig ? 'open' : ''}`;
    }

    connectedCallback() {
        // Initialize with default parameters when component loads
        this.initializeDefaultParameters();
    }

    // ACCORDION TOGGLE METHOD
    toggleAccordion(event) {
        const clickedElement = event.target;

        // Check if click was on a form element or its container
        const isFormElement = clickedElement.matches('input, textarea, select, button') ||
            clickedElement.closest('input, textarea, select, button, lightning-input-field, lightning-input, lightning-combobox, lightning-button, lightning-textarea');

        // Don't toggle if click was on a form element
        if (isFormElement) {
            return;
        }

        const section = event.currentTarget.dataset.section;
        this.isAccordionOpen = {
            ...this.isAccordionOpen,
            [section]: !this.isAccordionOpen[section]
        };
    }

    // Initialize default parameters based on Excel structure
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
                ],
                intervalValue: '',
                quantityValue: ''
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
                        isSelectionTypeDisabled: false, // Make dropdown editable (single value but editable)
                        isSelectionValueDisabled: false // Each row has its own Selection Value input box
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
                        isSelectionTypeDisabled: false, // Make dropdown editable (single value but editable)
                        isSelectionValueDisabled: false // Each row has its own Selection Value input box
                    };
                    this.applyParameterSpecificLogic(quantityParam);
                    expandedParams.push(quantityParam);
                } else {
                    // Update dynamicOptions (Selection Type options) based on Option List selection
                    processedParam.dynamicOptions = this.getSelectionTypeOptions(param.parameterName, processedParam.selectionOptionList);
                    
                    // Auto-set the single Selection Type value if only one option exists
                    if (processedParam.dynamicOptions && processedParam.dynamicOptions.length === 1) {
                        if (!processedParam.selectedType) {
                            processedParam.selectedType = processedParam.dynamicOptions[0].value;
                        }
                        // Keep dropdown editable even for single values
                    }
                    
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
        param.isSelectionOptionListDisabled = false; // Flag for disabling Selection Option List dropdown
        param.valueOptions = [];
        param.selectionValueArray = [];
        
        // Auto-set the single option value if only one option exists
        if (param.optionListOptions && param.optionListOptions.length === 1) {
            if (!param.selectionOptionList) {
                param.selectionOptionList = param.optionListOptions[0].value;
            }
            // Keep dropdown editable even for single values
        }

        // 1. Print head Firing Voltage
        if (paramName === 'Print head Firing Voltage') {
            if (param.selectedType === 'Auto') {
                param.selectionValue = 'NA';
                param.isSelectionValueDisabled = true;
            } else if (param.selectedType === 'Manual') {
                param.isSelectionValueDisabled = false;
            }
        }
        // 2. Pulse Value - Only N/A option, but keep editable
        else if (paramName === 'Pulse Value') {
            param.selectedType = 'N/A'; // Set Selected Type to N/A
            param.isSelectionValueDisabled = false; // Value input is still editable
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
        // 4. Nozzle Select - Selection Value should be N/A and non-editable
        else if (paramName === 'Nozzle Select') {
            param.isRegularParameter = false; // Use special rendering for N/A
            param.selectionValue = 'N/A'; // Set to N/A
            param.isSelectionValueDisabled = true; // Make non-editable
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
            // Always show as N/A readonly text box regardless of Splice/Head selection
            param.isNozzleSelectSplice = true; // Use this flag to show readonly N/A text box (works for both Splice and Head)
            param.isNozzleSelectHead = false; // Keep false, but isNozzleSelectSplice will handle the display
        }
        // 5. Purging auto jet
        else if (paramName === 'Purging auto jet') {
            // Ensure dropdown remains editable (not disabled)
            param.isSelectionOptionListDisabled = false;
            if (param.selectionOptionList === 'Auto') {
                param.selectedType = 'Auto';
                param.isSelectionTypeDisabled = false; // Make dropdown editable (single value but editable)
                param.selectionValue = 'NA';
                param.isSelectionValueDisabled = true; // Selection Value is disabled for Auto
            } else if (param.selectionOptionList === 'Manual') {
                // For Manual, Selection Option List dropdown should be editable
                // Selected Type will be expanded into Interval and Quantity rows
                // Each row will have its own editable dropdown and Selection Value input box
                param.isSelectionTypeDisabled = false;
                param.isSelectionValueDisabled = false;
            }
        }
        // 6-8. DPI X, DPI Y, DPI -Y, Printhead Delay - Only N/A option, but keep editable
        else if (['DPI X', 'DPI Y', 'DPI -Y', 'Printhead Delay'].includes(paramName)) {
            param.selectedType = 'N/A'; // Set Selected Type to N/A
            param.isSelectionValueDisabled = false; // Value input is still editable
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

            // Handle Selection Value changes for Purging auto jet expanded rows
            if (field === 'selectionValue' && (updatedParam.isPurgingInterval || updatedParam.isPurgingQuantity)) {
                const originalKey = updatedParam.originalKey || updatedParam.key.replace(/_Interval|_Quantity/, '');
                const mainParam = this.serviceReportParameters.find(p => p.key === originalKey && !p.isPurgingInterval && !p.isPurgingQuantity);
                
                if (mainParam) {
                    if (updatedParam.isPurgingInterval) {
                        mainParam.intervalValue = value;
                    } else if (updatedParam.isPurgingQuantity) {
                        mainParam.quantityValue = value;
                    }
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

    generateUniqueKey() {
        return 'param-' + Date.now() + '-' + Math.random().toString(36).substr(2, 9);
    }
}