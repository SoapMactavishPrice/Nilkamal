import { LightningElement, track, api } from 'lwc';
import buildCompleteHierarchy from '@salesforce/apex/ParameterMappingWrapper.buildCompleteHierarchy';

export default class ParameterMappingForm extends LightningElement {
    @track mappingRows = [];
    @track isLoading = true;
    @track hasError = false;
    @track errorMessage = '';
    @track configurationData = []; // Real-time configuration JSON

    // Store the original data for reset functionality
    originalData = [];

    // Dropdown options for Column 4 when selectionValueType is "Dropdown"
    dropdownValueOptions = [
        { label: 'Head', value: 'Head' },
        { label: 'Splice', value: 'Splice' }
    ];

    // Public getter to access configuration data from parent components
    @api
    get configuration() {
        return this.configurationData;
    }

    connectedCallback() {
        this.loadData();
    }

    async loadData() {
        this.isLoading = true;
        this.hasError = false;

        try {
            const result = await buildCompleteHierarchy();
            this.originalData = JSON.parse(JSON.stringify(result));
            this.processData(result);
        } catch (error) {
            this.hasError = true;
            this.errorMessage = error.body?.message || 'An error occurred while loading data';
            console.error('Error loading data:', error);
        } finally {
            this.isLoading = false;
        }
    }

    processData(data) {
        this.mappingRows = data.map((mapping, index) => {
            return this.createMappingRow(mapping, index);
        });
        // Build initial configuration
        this.updateConfigurationData();
    }

    createMappingRow(mapping, index) {
        // Build options list for the dropdown (Column 2)
        const optionsList = mapping.selectedOptions?.map(option => ({
            label: option.label,
            value: option.id
        })) || [];

        // Check if only N/A option exists
        const isNAOnlyOption = optionsList.length === 1 && optionsList[0].label === 'N/A';
        const preSelectedOptionValue = isNAOnlyOption ? optionsList[0].value : '';

        const row = {
            id: mapping.id || `mapping-${index}`,
            developerName: mapping.developerName,
            label: mapping.label,
            isMultiple: mapping.isMultiple,
            isMappingMultiple: mapping.isMultiple === true, // Flag for ParameterMapping.isMultiple
            hasOptions: optionsList.length > 0,
            optionsList: optionsList,
            selectedOptionValue: preSelectedOptionValue,
            isOptionDisabled: isNAOnlyOption, // Flag to disable dropdown when only N/A
            selectedOptions: mapping.selectedOptions || [],
            
            // Column 3: Type related fields (single mode)
            typesList: [],
            selectedTypeValue: '',
            typeComboName: `type-${mapping.id || index}`,
            showTypeDropdown: false,
            showSingleType: false,
            showNoTypeMessage: true,
            singleTypeLabel: '',
            
            // Column 4: Value related fields (single mode)
            textInputValue: '',
            showNAReadonly: false,
            showTextInput: false,
            showValueDropdown: false,
            showNoValueMessage: true,
            valueComboName: `value-${mapping.id || index}`,
            selectedDropdownValue: '',
            dropdownValueOptions: this.dropdownValueOptions,

            // Multiple mode fields (for Option.isMultiple)
            isMultipleMode: false,
            hasMultipleTypes: false,
            multipleTypes: [],

            // All options data (for Mapping.isMultiple = true)
            allOptionsData: []
        };

        // If ParameterMapping.isMultiple is true, pre-populate all options data
        if (mapping.isMultiple === true) {
            row.allOptionsData = this.buildAllOptionsData(mapping, row.id);
        }

        // If only N/A option exists, pre-populate Type and Value columns
        if (isNAOnlyOption && preSelectedOptionValue) {
            const selectedOption = mapping.selectedOptions?.find(opt => opt.id === preSelectedOptionValue);
            if (selectedOption && selectedOption.selectedTypes) {
                if (selectedOption.isMultiple) {
                    this.updateRowMultipleMode(row, selectedOption);
                } else {
                    this.updateRowTypeDisplay(row, selectedOption);
                }
            }
        }

        return row;
    }

    buildAllOptionsData(mapping, rowId) {
        const options = mapping.selectedOptions || [];
        
        return options.map((option, optIndex) => {
            const types = option.selectedTypes || [];
            const isOptionMultiple = option.isMultiple === true;

            const optionData = {
                uniqueKey: `${rowId}-${option.id}`,
                optionId: option.id,
                optionLabel: option.label,
                isFirstOption: optIndex === 0,
                isOptionMultiple: isOptionMultiple,
                isSelected: false, // User can check/uncheck to include this option
                
                // Single type mode fields
                typesList: [],
                selectedTypeValue: '',
                showTypeDropdown: false,
                showSingleType: false,
                showNoTypes: false,
                singleTypeLabel: '',
                
                // Value fields
                textInputValue: '',
                showNAReadonly: false,
                showTextInput: false,
                showValueDropdown: false,
                showNoValueMessage: true,
                selectedDropdownValue: '',
                dropdownValueOptions: this.dropdownValueOptions,

                // Multiple types (for Option.isMultiple = true)
                multipleTypes: [],
                
                // Store types for later use when checkbox is checked
                _types: types
            };

            // Pre-build the type display data (will be shown when checkbox is checked)
            if (isOptionMultiple) {
                optionData.multipleTypes = types.map(type => this.createTypeItem(type));
            } else {
                if (types.length === 0) {
                    optionData.showNoTypes = true;
                    optionData.showNoValueMessage = true;
                } else if (types.length === 1) {
                    const singleType = types[0];
                    optionData.showSingleType = true;
                    optionData.singleTypeLabel = singleType.label;
                    optionData.selectedTypeValue = singleType.id;
                    this.setValueFieldsForType(optionData, singleType);
                } else {
                    optionData.typesList = types.map(type => ({
                        label: type.label,
                        value: type.id
                    }));
                    optionData.showTypeDropdown = true;
                    optionData.showNoValueMessage = true;
                }
            }

            return optionData;
        });
    }

    createTypeItem(type) {
        const typeItem = {
            id: type.id,
            label: type.label,
            selectionValueType: type.selectionValueType,
            showNAReadonly: false,
            showTextInput: false,
            showValueDropdown: false,
            textValue: '',
            dropdownValue: '',
            dropdownOptions: this.dropdownValueOptions,
            placeholder: `Enter ${type.label}`
        };

        // Determine value input type based on selectionValueType
        // Only check selectionValueType, not the label, as label "N/A" doesn't mean value should be "N/A"
        if (type.selectionValueType === 'N/A') {
            typeItem.showNAReadonly = true;
        } else if (type.selectionValueType === 'Text') {
            typeItem.showTextInput = true;
        } else if (type.selectionValueType === 'Dropdown') {
            typeItem.showValueDropdown = true;
        } else {
            typeItem.showTextInput = true;
        }

        return typeItem;
    }

    setValueFieldsForType(target, type) {
        target.showNAReadonly = false;
        target.showTextInput = false;
        target.showValueDropdown = false;
        target.showNoValueMessage = false;

        // Only check selectionValueType, not the label, as label "N/A" doesn't mean value should be "N/A"
        if (type.selectionValueType === 'N/A') {
            target.showNAReadonly = true;
        } else if (type.selectionValueType === 'Text') {
            target.showTextInput = true;
        } else if (type.selectionValueType === 'Dropdown') {
            target.showValueDropdown = true;
        } else {
            target.showNoValueMessage = true;
        }
    }

    // Build configuration data from current state - called on every action
    updateConfigurationData() {
        const configData = [];

        this.mappingRows.forEach(row => {
            const parameterName = row.label;

            // Check if Mapping.isMultiple is true
            if (row.isMappingMultiple) {
                // Process only selected options (checked checkboxes)
                row.allOptionsData
                    .filter(optData => optData.isSelected)
                    .forEach(optData => {
                        const selectedOption = optData.optionLabel;

                        if (optData.isOptionMultiple) {
                            // Multiple types per option - create a record for each type
                            optData.multipleTypes.forEach(typeItem => {
                                let selectedValue = '';
                                if (typeItem.showNAReadonly) {
                                    selectedValue = 'N/A';
                                } else if (typeItem.showTextInput) {
                                    selectedValue = typeItem.textValue;
                                } else if (typeItem.showValueDropdown) {
                                    selectedValue = typeItem.dropdownValue;
                                }

                                configData.push({
                                    parameterName: parameterName,
                                    selectedOption: selectedOption,
                                    selectedType: typeItem.label,
                                    selectedValue: selectedValue
                                });
                            });
                        } else {
                            // Single type per option
                            let selectedValue = '';
                            if (optData.showNAReadonly) {
                                selectedValue = 'N/A';
                            } else if (optData.showTextInput) {
                                selectedValue = optData.textInputValue;
                            } else if (optData.showValueDropdown) {
                                selectedValue = optData.selectedDropdownValue;
                            }

                            configData.push({
                                parameterName: parameterName,
                                selectedOption: selectedOption,
                                selectedType: optData.singleTypeLabel,
                                selectedValue: selectedValue
                            });
                        }
                    });
            } else {
                // Regular single option mode
                const selectedOption = row.selectedOptions.find(opt => opt.id === row.selectedOptionValue);
                const selectedOptionLabel = selectedOption?.label || '';

                if (row.isMultipleMode && row.multipleTypes.length > 0) {
                    // Multiple types - create a record for each type
                    row.multipleTypes.forEach(typeItem => {
                        let selectedValue = '';
                        if (typeItem.showNAReadonly) {
                            selectedValue = 'N/A';
                        } else if (typeItem.showTextInput) {
                            selectedValue = typeItem.textValue;
                        } else if (typeItem.showValueDropdown) {
                            selectedValue = typeItem.dropdownValue;
                        }

                        configData.push({
                            parameterName: parameterName,
                            selectedOption: selectedOptionLabel,
                            selectedType: typeItem.label,
                            selectedValue: selectedValue
                        });
                    });
                } else {
                    // Single type
                    let selectedTypeLabel = row.singleTypeLabel;
                    if (selectedOption && row.selectedTypeValue) {
                        const selectedType = selectedOption.selectedTypes?.find(t => t.id === row.selectedTypeValue);
                        selectedTypeLabel = selectedType?.label || '';
                    }

                    let selectedValue = '';
                    if (row.showNAReadonly) {
                        selectedValue = 'N/A';
                    } else if (row.showTextInput) {
                        selectedValue = row.textInputValue;
                    } else if (row.showValueDropdown) {
                        selectedValue = row.selectedDropdownValue;
                    }

                    configData.push({
                        parameterName: parameterName,
                        selectedOption: selectedOptionLabel,
                        selectedType: selectedTypeLabel,
                        selectedValue: selectedValue
                    });
                }
            }
        });

        this.configurationData = configData;
        
        // Log to console on every update
        console.log('Configuration Updated:', JSON.stringify(this.configurationData, null, 2));

        // Dispatch event so parent components can react to changes
        this.dispatchEvent(new CustomEvent('configchange', {
            detail: { configuration: this.configurationData }
        }));
    }

    // Handle checkbox change for option selection in Mapping.isMultiple mode
    handleOptionCheckboxChange(event) {
        const isChecked = event.target.checked;
        const rowId = event.target.dataset.id;
        const optionId = event.target.dataset.optionId;

        this.mappingRows = this.mappingRows.map(row => {
            if (row.id === rowId) {
                const updatedRow = { ...row };
                updatedRow.allOptionsData = row.allOptionsData.map(optData => {
                    if (optData.optionId === optionId) {
                        return { ...optData, isSelected: isChecked };
                    }
                    return optData;
                });
                return updatedRow;
            }
            return row;
        });

        // Update configuration on change
        this.updateConfigurationData();
    }

    handleOptionChange(event) {
        const selectedValue = event.detail.value;
        const rowId = event.target.dataset.id;

        this.mappingRows = this.mappingRows.map(row => {
            if (row.id === rowId) {
                const updatedRow = { ...row };
                updatedRow.selectedOptionValue = selectedValue;

                const selectedOption = row.selectedOptions.find(opt => opt.id === selectedValue);

                if (selectedOption && selectedOption.selectedTypes) {
                    if (selectedOption.isMultiple) {
                        this.updateRowMultipleMode(updatedRow, selectedOption);
                    } else {
                        this.updateRowTypeDisplay(updatedRow, selectedOption);
                    }
                } else {
                    this.resetRowTypeDisplay(updatedRow);
                }

                return updatedRow;
            }
            return row;
        });

        // Update configuration on change
        this.updateConfigurationData();
    }

    updateRowMultipleMode(row, selectedOption) {
        const types = selectedOption.selectedTypes || [];
        
        row.isMultipleMode = true;
        row.hasMultipleTypes = types.length > 0;
        
        row.showTypeDropdown = false;
        row.showSingleType = false;
        row.showNoTypeMessage = false;
        row.showNAReadonly = false;
        row.showTextInput = false;
        row.showValueDropdown = false;
        row.showNoValueMessage = false;

        row.multipleTypes = types.map(type => this.createTypeItem(type));
    }

    updateRowTypeDisplay(row, selectedOption) {
        const types = selectedOption.selectedTypes || [];
        
        row.isMultipleMode = false;
        row.hasMultipleTypes = false;
        row.multipleTypes = [];

        row.showTypeDropdown = false;
        row.showSingleType = false;
        row.showNoTypeMessage = false;
        row.typesList = [];
        row.selectedTypeValue = '';
        row.singleTypeLabel = '';
        
        row.showNAReadonly = false;
        row.showTextInput = false;
        row.showValueDropdown = false;
        row.showNoValueMessage = true;
        row.textInputValue = '';
        row.selectedDropdownValue = '';

        if (types.length === 0) {
            row.showNoTypeMessage = true;
            row.showNoValueMessage = true;
            return;
        }

        if (types.length === 1) {
            const singleType = types[0];
            row.showSingleType = true;
            row.singleTypeLabel = singleType.label;
            row.selectedTypeValue = singleType.id;
            this.updateValueColumn(row, singleType);
        } else {
            row.typesList = types.map(type => ({
                label: type.label,
                value: type.id
            }));
            row.showTypeDropdown = true;
            row.showNoValueMessage = true;
        }
    }

    updateValueColumn(row, selectedType) {
        row.showNAReadonly = false;
        row.showTextInput = false;
        row.showValueDropdown = false;
        row.showNoValueMessage = false;

        if (!selectedType) {
            row.showNoValueMessage = true;
            return;
        }

        // Only check selectionValueType, not the label, as label "N/A" doesn't mean value should be "N/A"
        if (selectedType.selectionValueType === 'N/A') {
            row.showNAReadonly = true;
        } else if (selectedType.selectionValueType === 'Text') {
            row.showTextInput = true;
        } else if (selectedType.selectionValueType === 'Dropdown') {
            row.showValueDropdown = true;
        } else {
            row.showNoValueMessage = true;
        }
    }

    resetRowTypeDisplay(row) {
        row.isMultipleMode = false;
        row.hasMultipleTypes = false;
        row.multipleTypes = [];

        row.showTypeDropdown = false;
        row.showSingleType = false;
        row.showNoTypeMessage = true;
        row.typesList = [];
        row.selectedTypeValue = '';
        row.singleTypeLabel = '';
        
        row.showNAReadonly = false;
        row.showTextInput = false;
        row.showValueDropdown = false;
        row.showNoValueMessage = true;
        row.textInputValue = '';
        row.selectedDropdownValue = '';
    }

    handleTypeChange(event) {
        const selectedValue = event.detail.value;
        const rowId = event.target.dataset.id;

        this.mappingRows = this.mappingRows.map(row => {
            if (row.id === rowId) {
                const updatedRow = { ...row };
                updatedRow.selectedTypeValue = selectedValue;

                const selectedOption = row.selectedOptions.find(opt => opt.id === row.selectedOptionValue);
                if (selectedOption) {
                    const selectedType = selectedOption.selectedTypes?.find(t => t.id === selectedValue);
                    if (selectedType) {
                        this.updateValueColumn(updatedRow, selectedType);
                    }
                }

                return updatedRow;
            }
            return row;
        });

        // Update configuration on change
        this.updateConfigurationData();
    }

    handleTextInputChange(event) {
        const value = event.target.value;
        const rowId = event.target.dataset.id;

        this.mappingRows = this.mappingRows.map(row => {
            if (row.id === rowId) {
                return { ...row, textInputValue: value };
            }
            return row;
        });

        // Update configuration on change
        this.updateConfigurationData();
    }

    handleValueDropdownChange(event) {
        const value = event.detail.value;
        const rowId = event.target.dataset.id;

        this.mappingRows = this.mappingRows.map(row => {
            if (row.id === rowId) {
                return { ...row, selectedDropdownValue: value };
            }
            return row;
        });

        // Update configuration on change
        this.updateConfigurationData();
    }

    handleMultipleTextInputChange(event) {
        const value = event.target.value;
        const rowId = event.target.dataset.id;
        const typeId = event.target.dataset.typeId;

        this.mappingRows = this.mappingRows.map(row => {
            if (row.id === rowId) {
                const updatedRow = { ...row };
                updatedRow.multipleTypes = row.multipleTypes.map(typeItem => {
                    if (typeItem.id === typeId) {
                        return { ...typeItem, textValue: value };
                    }
                    return typeItem;
                });
                return updatedRow;
            }
            return row;
        });

        // Update configuration on change
        this.updateConfigurationData();
    }

    handleMultipleDropdownChange(event) {
        const value = event.detail.value;
        const rowId = event.target.dataset.id;
        const typeId = event.target.dataset.typeId;

        this.mappingRows = this.mappingRows.map(row => {
            if (row.id === rowId) {
                const updatedRow = { ...row };
                updatedRow.multipleTypes = row.multipleTypes.map(typeItem => {
                    if (typeItem.id === typeId) {
                        return { ...typeItem, dropdownValue: value };
                    }
                    return typeItem;
                });
                return updatedRow;
            }
            return row;
        });

        // Update configuration on change
        this.updateConfigurationData();
    }

    // Handlers for Mapping.isMultiple = true mode
    handleMappingMultipleTypeChange(event) {
        const selectedValue = event.detail.value;
        const rowId = event.target.dataset.id;
        const optionId = event.target.dataset.optionId;

        this.mappingRows = this.mappingRows.map(row => {
            if (row.id === rowId) {
                const updatedRow = { ...row };
                updatedRow.allOptionsData = row.allOptionsData.map(optData => {
                    if (optData.optionId === optionId) {
                        const updatedOptData = { ...optData };
                        updatedOptData.selectedTypeValue = selectedValue;

                        // Find the option and type
                        const option = row.selectedOptions.find(o => o.id === optionId);
                        if (option) {
                            const selectedType = option.selectedTypes?.find(t => t.id === selectedValue);
                            if (selectedType) {
                                this.setValueFieldsForType(updatedOptData, selectedType);
                            }
                        }

                        return updatedOptData;
                    }
                    return optData;
                });
                return updatedRow;
            }
            return row;
        });

        // Update configuration on change
        this.updateConfigurationData();
    }

    handleMappingMultipleTextChange(event) {
        const value = event.target.value;
        const rowId = event.target.dataset.id;
        const optionId = event.target.dataset.optionId;

        this.mappingRows = this.mappingRows.map(row => {
            if (row.id === rowId) {
                const updatedRow = { ...row };
                updatedRow.allOptionsData = row.allOptionsData.map(optData => {
                    if (optData.optionId === optionId) {
                        return { ...optData, textInputValue: value };
                    }
                    return optData;
                });
                return updatedRow;
            }
            return row;
        });

        // Update configuration on change
        this.updateConfigurationData();
    }

    handleMappingMultipleDropdownChange(event) {
        const value = event.detail.value;
        const rowId = event.target.dataset.id;
        const optionId = event.target.dataset.optionId;

        this.mappingRows = this.mappingRows.map(row => {
            if (row.id === rowId) {
                const updatedRow = { ...row };
                updatedRow.allOptionsData = row.allOptionsData.map(optData => {
                    if (optData.optionId === optionId) {
                        return { ...optData, selectedDropdownValue: value };
                    }
                    return optData;
                });
                return updatedRow;
            }
            return row;
        });

        // Update configuration on change
        this.updateConfigurationData();
    }

    handleMappingMultipleTypeTextChange(event) {
        const value = event.target.value;
        const rowId = event.target.dataset.id;
        const optionId = event.target.dataset.optionId;
        const typeId = event.target.dataset.typeId;

        this.mappingRows = this.mappingRows.map(row => {
            if (row.id === rowId) {
                const updatedRow = { ...row };
                updatedRow.allOptionsData = row.allOptionsData.map(optData => {
                    if (optData.optionId === optionId) {
                        const updatedOptData = { ...optData };
                        updatedOptData.multipleTypes = optData.multipleTypes.map(typeItem => {
                            if (typeItem.id === typeId) {
                                return { ...typeItem, textValue: value };
                            }
                            return typeItem;
                        });
                        return updatedOptData;
                    }
                    return optData;
                });
                return updatedRow;
            }
            return row;
        });

        // Update configuration on change
        this.updateConfigurationData();
    }

    handleMappingMultipleTypeDropdownChange(event) {
        const value = event.detail.value;
        const rowId = event.target.dataset.id;
        const optionId = event.target.dataset.optionId;
        const typeId = event.target.dataset.typeId;

        this.mappingRows = this.mappingRows.map(row => {
            if (row.id === rowId) {
                const updatedRow = { ...row };
                updatedRow.allOptionsData = row.allOptionsData.map(optData => {
                    if (optData.optionId === optionId) {
                        const updatedOptData = { ...optData };
                        updatedOptData.multipleTypes = optData.multipleTypes.map(typeItem => {
                            if (typeItem.id === typeId) {
                                return { ...typeItem, dropdownValue: value };
                            }
                            return typeItem;
                        });
                        return updatedOptData;
                    }
                    return optData;
                });
                return updatedRow;
            }
            return row;
        });

        // Update configuration on change
        this.updateConfigurationData();
    }

    // Public method - can be called from parent component
    @api
    resetForm() {
        this.processData(JSON.parse(JSON.stringify(this.originalData)));
    }
}