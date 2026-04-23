import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createServiceRequest from '@salesforce/apex/fieldServiceRequest.createServiceRequest';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';
import { disablePullToRefresh, navigateToLWC, showToast } from 'c/utilJS';

import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import SERVICE_REQUEST_OBJECT from '@salesforce/schema/Service_Request__c';
import WARRANTY_FIELD from '@salesforce/schema/Service_Request__c.Warranty_Period__c';

import getPerviousAmCoRWarrrentyDetails from '@salesforce/apex/fieldServiceRequest.getAssetDetails';
import getWorkOrderData from '@salesforce/apex/fieldServiceRequest.getWorkOrderData';
import getProductsByPartNo from '@salesforce/apex/fieldServiceRequest.getProductsByPartNo';
import getWarrantyMapping from '@salesforce/apex/FieldServiceEditServiceRequestController.getWarrantyMapping';


export default class FieldServiceRequest extends NavigationMixin(LightningElement) {
    @track showSpinner = false;
    @track isMHE = false;
    @api recordId;
    @track itemMasterId;
    @track workOrderData = {};
    @track error;
    @track isCheckboxChecked = false;
    @track currentPage = 1;
    @track pageSize = 10;
    @track isFirstPage = true;
    @track isLastPage = false;
    @track isMobileView = false;    //for mobile view
    @track caseType = '';
    @track caseDivision = '';
    @track materialCommissionDate = '';
    @track invoiceNumber;
    @track assetStatus = '';
    @track spareParts = [];
    @track searchKey = '';
    @track error;
    @track allData = [];
    @track allFilteredData = [];
    @track tempSpareParts = [];
    clientFilterQuery;
    @track serviceAppointmentId;
    @track warrantyOptions = [];
    @track MG6Code = '';

    // Fetch object info to get the default record type ID
    @wire(getObjectInfo, { objectApiName: SERVICE_REQUEST_OBJECT })
    objectInfo;

    // Fetch picklist values using defaultRecordTypeId
    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: WARRANTY_FIELD
    })
    wiredWarrantyOptions({ data, error }) {
        if (data) {
            this.warrantyOptions = data.values.map(opt => ({
                label: opt.label,
                value: opt.value
            }));

        } else if (error) {
            console.error('Error loading warranty picklist values:', error);
        }
    }


    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        this.currentPageReference = currentPageReference;
        // console.log('OUTPUT : ', this.currentPageReference);
        if (this.currentPageReference) {
            this.recordId = this.currentPageReference.state.c__id;
            this.serviceAppointmentId = this.currentPageReference.state.c__serviceAppointmentId;
            this.caseId = this.currentPageReference.state.c__caseId;
            this.isMHE = false;
            // console.log('this.recordId', this.recordId);
            // console.log('serviceAppointmentId', this.serviceAppointmentId);
            // console.log('caseId', this.caseId);
            this.fetchWarrantyMapping();
            this.fetchCaseAndAssetDetails();
        }
    }

    connectedCallback() {
        // this.fetchSpareParts();

        const mediaQuery = window.matchMedia('(max-width: 768px)');
        this.isMobileView = mediaQuery.matches;

        mediaQuery.addEventListener('change', (event) => {
            this.isMobileView = event.matches;
        });
        disablePullToRefresh(this);
    }

    @track warrantyMap = {};
    fetchWarrantyMapping() {
        getWarrantyMapping()
            .then(result => {
                // console.log('warrantyMap', result);
                this.warrantyMap = Object.fromEntries(
                    Object.entries(result).map(([key, value]) => [key.replace('.0', ''), value])
                );
            })
            .catch(error => {
                console.error('Error fetching warranty mapping:', error);
            });
    }

    // fetch work order data related to case and asset
    fetchCaseAndAssetDetails() {
        // console.log('fetchCaseAndAssetDetails');
        getWorkOrderData({ woid: this.recordId })
            .then((data) => {
                let newData = JSON.parse(JSON.stringify(data));
                // console.log('newData-->', newData);
                let FinalNewData = newData[0];
                this.caseType = FinalNewData?.Case__r?.Type;
                this.caseDivision = FinalNewData?.Case__r?.Division__c;
                this.materialCommissionDate = FinalNewData?.Case__r?.Asset?.InstallDate;
                this.assetStatus = FinalNewData?.Case__r?.Asset?.Type__c;
                this.caseNum = FinalNewData?.Case__r?.CaseNumber;
                this.AccountName = FinalNewData?.Case__r?.Account?.Name;
                this.invoiceNumber = FinalNewData?.Case__r?.Asset?.Invoice__r?.Name;
                this.date = this.getDate(FinalNewData?.Case__r?.CreatedDate);
                this.SerialNo = FinalNewData?.Case__r?.Asset?.SerialNumber;
                this.MaterialCode = FinalNewData?.Case__r?.Asset?.ProductCode;
                this.MG6Code = FinalNewData?.Case__r?.Asset?.Product2?.Material_Group_6__c;
                this.itemMasterId = FinalNewData?.Case__r?.Asset?.Product2Id;
                this.fetchSpareParts();
                this.getPerviousAmCoRWarrrentyDetailsJS();

                if (this.caseDivision == 'MHE') {
                    this.isMHE = true;
                }
            })
    }

    @track amcorwarrenty = null;
    @track startDate = null;
    @track endDate = null;
    @track amount = null;

    getPerviousAmCoRWarrrentyDetailsJS() {
        // console.log('Calling getPerviousAmCoRWarrrentyDetailsJS');

        getPerviousAmCoRWarrrentyDetails({ serialNo: this.SerialNo })
            .then((data) => {
                // console.log('Received Warranty Details -->', JSON.stringify(data));

                if (data) {
                    // const start = new Date(data.AMC_Start_Date__c || data.Warranty_Start_Date__c);
                    // const end = new Date(data.AMC_End_Date__c || data.Warranty_End_Date__c);

                    // const formattedStart = start.toLocaleDateString('en-IN', {
                    //     day: '2-digit',
                    //     month: 'long',
                    //     year: 'numeric'
                    // });

                    // const formattedEnd = end.toLocaleDateString('en-IN', {
                    //     day: '2-digit',
                    //     month: 'long',
                    //     year: 'numeric'
                    // });

                    // const formattedAmount = data.AMC_PO_Value__c
                    //     ? new Intl.NumberFormat('en-IN', {
                    //           style: 'currency',
                    //           currency: 'INR',
                    //           minimumFractionDigits: 2
                    //       }).format(data.AMC_PO_Value__c)
                    //     : null;

                    // this.amcorwarrenty = {
                    //     startDate: formattedStart,
                    //     endDate: formattedEnd,
                    //     amount: formattedAmount
                    // };


                    const startRaw = data.AMC_Start_Date__c || data.Warranty_Start_Date__c;
                    const endRaw = data.AMC_End_Date__c || data.Warranty_End_Date__c;


                    const start = startRaw ? new Date(Date.parse(startRaw)) : null;
                    const end = endRaw ? new Date(Date.parse(endRaw)) : null;

                    const formattedStart = start
                        ? start.toLocaleDateString('en-IN', {
                            day: '2-digit',
                            month: 'long',
                            year: 'numeric'
                        })
                        : null;

                    const formattedEnd = end
                        ? end.toLocaleDateString('en-IN', {
                            day: '2-digit',
                            month: 'long',
                            year: 'numeric'
                        })
                        : null;

                    const formattedAmount = data.AMC_PO_Value__c
                        ? new Intl.NumberFormat('en-IN', {
                            style: 'currency',
                            currency: 'INR',
                            minimumFractionDigits: 2
                        }).format(data.AMC_PO_Value__c)
                        : null;

                    this.amcorwarrenty = {
                        startDate: formattedStart,
                        endDate: formattedEnd,
                        amount: formattedAmount
                    };
                    this.startDate = startRaw;
                    this.endDate = endRaw;
                    this.amount = data.AMC_PO_Value__c;
                } else {
                    this.amcorwarrenty = null;
                }
            })
            .catch((error) => {
                console.error('Error fetching previous warranty details -->', error);
            });
    }



    getDate(date) {
        let dateTimeStr = date;
        let dateObj = new Date(dateTimeStr);

        let day = dateObj.getDate().toString().padStart(2, '0');
        let month = (dateObj.getMonth() + 1).toString().padStart(2, '0');
        let year = dateObj.getFullYear();

        return `${day}-${month}-${year}`;
    }


    handleSearchChange(event) {
        this.searchKey = event.target.value.trim(); // Trim spaces
        // console.log('Search Key:', this.searchKey);
        // console.log('tempSpareParts ->')
        // console.log(this.tempSpareParts);

        this.currentPage = 1;

        if (this.searchKey === '') {
            this.spareParts = [...this.allData]; // Restore original data when search is cleared
            this.updatePaginationStatus();
            return;
        }

        this.spareParts = this.allData.filter((cli) => {
            return (
                (cli.modelDesc && cli.modelDesc.toUpperCase().includes(this.searchKey.toUpperCase())) ||
                (cli.modelName && cli.modelName.toUpperCase().includes(this.searchKey.toUpperCase()))
            );

        });

        // console.log('Filtered Data:', this.spareParts);

        // If no matching results, show the original data
        if (this.spareParts.length === 0) {
            // console.log('No matching results found, resetting spareParts');
            this.spareParts = [...this.allData];
        }

        this.spareParts.forEach(each => {
            this.tempSpareParts.forEach(eachTemp => {
                // console.log('ID->' + each.id + ' Temp Id' + eachTemp.id);
                if (each.modelName === eachTemp.modelName) {
                    each.quantity = eachTemp.quantity;
                    each.checkbox = eachTemp.checkbox;
                    each.modelName = eachTemp.modelName;
                    each.modelDesc = eachTemp.modelDesc;
                    each.price = Number(eachTemp.price);
                    each.currency = String(eachTemp.currency);
                    each.pricebookEntryId = eachTemp.pricebookEntryId;
                }
            })
        })

        this.updatePaginationStatus();
    }


    fetchSpareParts() {
        getProductsByPartNo({ woid: this.recordId })
            .then((result) => {
                console.log('Result from Apex:', result);
                try {
                    let recs = [];
                    for (var i = 0; i < result.length; i++) {
                        let opp = Object.assign({}, result[i]);
                        // console.log('v opp ', opp);
                        opp.checked = opp.quantity == 0 ? false : true;
                        // opp.checkbox = opp.quantity == 0 ? false : true;
                        opp.showQuantity = false;
                        opp.quantity = opp.quantity;
                        opp.isWarranty = opp.quantity != 0 && opp.warranty == 'Y' ? true : false;
                        opp.pricebookEntryId = opp.pricebookEntryId ? opp.pricebookEntryId : null;
                        opp.price = opp.price; //changes 15-3-25
                        opp.newprice = opp.price; //changes 15-3-25
                        opp.isEditable = opp.modelName.includes('AMC') ? true : false;
                        opp.rowIndex = i;
                        opp.currency = opp.CurrencyIsoCode;
                        opp.warrantyperiod = opp.warrantyperiod ? opp.warrantyperiod : '12';
                        // console.log('v opp.materialGroup6 ', opp.materialGroup6);

                        //const warrantyKey = opp.materialGroup6 + '-' + opp.warrantyperiod;
                        const warrantyKey = this.MG6Code + '-' + opp.warrantyperiod;
                        // console.log('v warrantyKey ', warrantyKey);

                        const warrantyValue = this.warrantyMap[warrantyKey];
                        // console.log('v warrantyValue ', warrantyValue);


                        opp.noofpmvisit = opp.noofpmvisit ? opp.noofpmvisit : (warrantyValue ? warrantyValue.PM.toString() : '');
                        // console.log('v noofpmvisit ', opp.noofpmvisit);
                        opp.noofbreakdownvisit = opp.noofbreakdownvisit ? opp.noofbreakdownvisit : (warrantyValue ? warrantyValue.BD.toString() : '');
                        // console.log('v noofbreakdownvisit ', opp.noofbreakdownvisit);
                        recs.push(opp);
                    }

                    this.spareParts = recs;
                    // console.log('final result', this.spareParts);
                    // console.log('spareParts result after push');
                    this.allData = this.spareParts;
                    this.updatePaginationStatus();
                    this.allFilteredData = this.spareParts;
                    // console.log('spareParts result:', this.spareParts);
                } catch (parseError) {
                    console.error('Error processing spare parts data:', parseError);
                    this.error = parseError;
                }
            })
            .catch((error) => {
                this.error = error;
                console.error('Error fetching spare parts:', error);
            });
    }

    handleAddRow(event) {
        this.showSpinner = true;

        // Clone the spareParts array
        let rec = [...this.spareParts];

        // Get the index of the row to duplicate
        const indexToDuplicate = parseInt(event.target.dataset.index);

        // Deep clone the row and customize
        let rowToDuplicate = JSON.parse(JSON.stringify(rec[indexToDuplicate]));
        rowToDuplicate.Id = rowToDuplicate.Id + '-' + (indexToDuplicate + 1); // Make ID unique
        rowToDuplicate.isClone = true;
        rowToDuplicate.cloneId = rowToDuplicate.Id + '-' + (indexToDuplicate + 1);
        // We'll reassign rowIndex for all later

        // Insert the cloned row just after the original
        rec.splice(indexToDuplicate + 1, 0, rowToDuplicate);

        // Reassign rowIndex for all
        rec = rec.map((item, idx) => {
            return { ...item, rowIndex: idx };
        });

        // Update tracked properties
        this.spareParts = rec;
        this.allData = this.spareParts;
        this.allFilteredData = this.spareParts;
        this.updatePaginationStatus();

        // console.log('Updated spareParts:', JSON.stringify(this.spareParts));
        this.showSpinner = false;
    }

    handleCheckboxChange(event) {
        const partId = event.target.dataset.id;
        const isChecked = event.target.checked;
        const index = event.target.dataset.index;
        this.spareParts[index].checkbox = isChecked;

        // this.spareParts = this.spareParts.map((part) => {
        //     if (part.Id === partId) {
        //         // Reset quantity to default (1) when checkbox is unchecked
        //         return { ...part, checkbox: isChecked, quantity: isChecked ? part.quantity : 1 };
        //     }
        //     return part;
        // });

        this.tempSpareParts = JSON.parse(JSON.stringify(this.spareParts));
    }
    handleQuantityChange(event) {
        const partId = event.target.dataset.id;
        let newValue = event.target.value;
        const inputField = event.target; // Access the input field directly
        const index = this.spareParts.findIndex(part => part.Id === partId);

        // Allow only numeric values greater than or equal to 1
        if (newValue === "" || isNaN(newValue) || parseInt(newValue, 10) < 1) {
            // Set custom validity message
            // inputField.setCustomValidity('Please enter a quantity greater than or equal to 1');
        } else {
            // Clear error if valid
            // inputField.setCustomValidity('');
            // if (index !== -1) {
            //     this.spareParts[index].quantity = parseInt(newValue, 10);
            // }
        }

        // Prevent the user from entering negative or less than 1 values
        if (parseInt(newValue, 10) < 1) {
            event.preventDefault(); // Prevent the invalid value
            inputField.value = '';  // Optionally, clear the input
        }

        // Display validation message
        inputField.reportValidity();
        this.tempSpareParts = JSON.parse(JSON.stringify(this.spareParts));
    }

    //added 15-3-25
    handlePriceChange(event) {
        const partId = event.target.dataset.id;
        const newValue = event.target.value;
        const index = event.target.dataset.index;
        this.spareParts[index].price = newValue;


        // this.spareParts = this.spareParts.map((part) => {
        //     if (part.Id === partId) {
        //         return { ...part, price: newValue };  // Update the price in the list
        //     }
        //     return part;
        // });
        this.tempSpareParts = JSON.parse(JSON.stringify(this.spareParts));
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }

    get paginatedCases() {
        if (!this.spareParts) return [];
        console.log('this.spareParts', this.spareParts);


        const startIdx = (this.currentPage - 1) * this.pageSize;
        const endIdx = this.currentPage * this.pageSize;
        this.isFirstPage = this.currentPage === 1;
        this.isLastPage = this.currentPage === this.totalPages;

        return this.spareParts.slice(startIdx, endIdx);
    }

    handlePreviousPage() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.updatePaginationStatus();
        }
    }

    handleNextPage() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this.updatePaginationStatus();
        }
    }

    refreshCases() {
        this.fetchSpareParts();
        this.currentPage = 1;
    }

    updatePaginationStatus() {
        const totalCases = this.spareParts.length;
        this.totalPages = Math.ceil(totalCases / this.pageSize);
        this.isFirstPage = this.currentPage === 1;
        this.isLastPage = this.currentPage === this.totalPages;
    }


    handleSave() {
        this.showSpinner = true;
        // console.log('this.spareParts ->', this.spareParts);
        const selectedParts = this.spareParts
            .filter(part => part.checkbox)
            .map(part => ({
                Id: part.Id,
                quantity: part.quantity,
                checkbox: part.checkbox,
                modelName: part.modelName,
                modelDesc: part.modelDesc,
                price: Number(part.price),
                newprice: Number(part.newprice),
                amcprice: Number(part.AMCprice),
                isClone: part.isClone,
                cloneId: part.cloneId,
                currency: String(part.currency),
                warrantyperiod: part.warrantyperiod,
                noofpmvisit: part.noofpmvisit,
                noofbreakdownvisit: part.noofbreakdownvisit,
                pricebookEntryId: part.pricebookEntryId,
                Item_Master__c: part.Item_Master__c
            }));

        // Check for invalid inputs
        const invalidParts = selectedParts.filter(part => {
            // console.log('part.price ', part.price);

            return part.checkbox && (isNaN(part.price) || part.price <= 0 || isNaN(part.quantity) || part.quantity <= 0);
        });

        if (selectedParts.length === 0) {
            this.showToast('Error', 'Please select at least one spare part and enter a valid quantity.', 'error');
            this.showSpinner = false;
            return;
        }

        if (invalidParts.length > 0) {
            this.showToast('Error', 'Invalid input! Ensure Price and Quantity are positive numeric values.', 'error');
            this.showSpinner = false;
            return;
        }

        createServiceRequest({ spareParts: selectedParts, woid: this.recordId, serviceAppointmentId: this.serviceAppointmentId })
            .then(() => {
                this.showToast('Success', 'Added to cart!', 'success');
                // this.fetchSpareParts(); // Refresh the list if needed
                // this.navigateToLWC();
            })
            .catch(error => {
                console.error('Error creating spare requests:', error);
                // this.showToast('Error', 'An error occurred while creating spare requests.', 'error');
                showToast(this, 'Error', 'Failed to fetch spare parts:', 'error', error);
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }

    navigateToLWC() {
        this[NavigationMixin.Navigate]({
            type: 'standard__component',
            attributes: {
                componentName: 'c__fieldServiceHome'
            }
        });
    }





    handleCartClick(event) {
        navigateToLWC(this, 'fieldServiceEditServiceRequest', { c__workOrderId: this.recordId, c__caseId: this.caseId, c__serviceAppointmentId: this.serviceAppointmentId });
    }

    handleCreateQuoteClick(event) {
        navigateToLWC(this, 'raiseOppAndQuote', { c__recordId: this.recordId, c__type: 'service' });
    }

    increaseQuantity(event) {
        const index = event.target.dataset.index;
        // console.log(this.spareParts[index].quantity);
        // console.log('index ', index);
        this.spareParts[index].quantity = (this.spareParts[index].quantity || 0) + 1;
        // console.log(this.spareParts[index].quantity);
        this.spareParts[index].checkbox = true;
        // this.spareParts[index].billingType = 'Chargeable';
        if (this.spareParts[index].quantity == 0) {
            this.spareParts[index].warrantyperiod = '';
            this.spareParts[index].noofpmvisit = '';
            this.spareParts[index].noofbreakdownvisit = '';
            this.spareParts[event.target.dataset.index].isWarranty = false;
        } else {
            if (this.spareParts[index].warranty == 'Y') {
                this.spareParts[event.target.dataset.index].isWarranty = true;
            }
        }
    }

    decreaseQuantity(event) {
        const index = event.target.dataset.index;
        if (this.spareParts[index].quantity > 1) {
            this.spareParts[index].quantity -= 1;
            // this.spareParts[index].billingType = 'Chargeable';
        }
        if (this.spareParts[index].quantity == 0) {
            this.spareParts[index].checkbox = false;
            // this.spareParts[index].billingType = '';

        }
        if (this.spareParts[index].quantity == 0) {
            this.spareParts[index].warrantyperiod = '';
            this.spareParts[index].noofpmvisit = '';
            this.spareParts[index].noofbreakdownvisit = '';
            this.spareParts[event.target.dataset.index].isWarranty = false;
        } else {
            if (this.spareParts[index].warranty == 'Y') {
                this.spareParts[event.target.dataset.index].isWarranty = true;
            }
        }
    }

    // handleChange(event) {
    //     const index = event.target.dataset.index;
    //     this.spareParts[index].warrantyperiod = event.detail.value;
    //     var selectedWarranty = this.spareParts[index].materialGroup6 + '_' + this.spareParts[index].warrantyperiod;

    //     // const selectedWarranty = event.detail.value;
    //     console.log('this.warrantyMap', this.warrantyMap);

    //     console.log('this.warrantyMap[selectedWarranty] ', this.warrantyMap[selectedWarranty]);

    //     if (this.warrantyMap && this.warrantyMap[selectedWarranty]) {
    //         const mapping = this.warrantyMap[selectedWarranty];
    //         this.spareParts[index].noofpmvisit = (mapping.PM).toString();
    //         this.spareParts[index].noofbreakdownvisit = (mapping.BD).toString();
    //     } else {
    //         this.spareParts[index].noofpmvisit = '';
    //         this.spareParts[index].noofbreakdownvisit = '';
    //     }
    //     console.log(JSON.stringify(this.spareParts));
    // }

    handleChange(event) {
        const index = event.target.dataset.index;
        this.spareParts[index].warrantyperiod = event.detail.value;

        const warrantyPeriod = event.detail.value;
        //const materialGroup6 = this.spareParts[index].materialGroup6;

        const warrantyKey = `${this.MG6Code}-${warrantyPeriod}`;

        // console.log('this.warrantyMap:', this.warrantyMap);
        // console.log('warrantyKey:', warrantyKey);
        // console.log('Mapped Value:', this.warrantyMap[warrantyKey]);

        const mapping = this.warrantyMap[warrantyKey];

        if (mapping) {
            this.spareParts[index].noofpmvisit = mapping.PM.toString();
            this.spareParts[index].noofbreakdownvisit = mapping.BD.toString();
        } else {
            this.spareParts[index].noofpmvisit = '';
            this.spareParts[index].noofbreakdownvisit = '';
        }

        // console.log(JSON.stringify(this.spareParts));
    }

    handlePmChange(event) {
        const index = event.target.dataset.index;
        this.spareParts[index].noofpmvisit = event.target.value;
        // console.log(JSON.stringify(this.spareParts));

    }
    handlebreakChange(event) {
        const index = event.target.dataset.index;
        this.spareParts[index].noofbreakdownvisit = event.target.value;
        // console.log(JSON.stringify(this.spareParts));

    }

    handleKeyDown(event) {
        // Prevent negative numbers and non-numeric characters
        if (!/^\d$/.test(event.key) && !['Backspace', 'Tab', 'ArrowLeft', 'ArrowRight'].includes(event.key)) {
            event.preventDefault();
        }
    }


}