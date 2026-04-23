import { LightningElement, api, track, wire } from 'lwc';
import getServiceAppointments from '@salesforce/apex/WorkOrderController.getServiceAppointments';
import getWorkOrderDetails from '@salesforce/apex/WorkOrderController.getWorkOrderDetails';
import getServiceAppointmentDetails from "@salesforce/apex/WorkOrderController.getServiceAppointmentDetails";
import saveServiceAppointment from '@salesforce/apex/WorkOrderController.saveServiceAppointment';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import getServiceResourceAvailability from '@salesforce/apex/WorkOrderController.getServiceResourceAvailability';
import saveAvailability from '@salesforce/apex/WorkOrderController.saveAvailability';
import { NavigationMixin } from 'lightning/navigation';
import getPicklistValues from '@salesforce/apex/WorkOrderController.getPicklistValues';






export default class ServiceAppointment extends NavigationMixin(LightningElement) {
    @api recordId; // Work Order record ID
    @track workOrderNumber = ''; // Work Order Number
    @track selectedServiceAppointment = ''; // Selected Service Appointment
    @track serviceAppointmentOptions = []; // Options for Service Appointment Combobox
    @track workType = ''; // Work Type field value
    @track address = ''; // Address field value
    @track territory = ''; // Territory field value
    @track selectedServiceAppointment = ''; // Selected Service Appointment (if needed)
    @track caseId;
    // @track territoryOptions = [
    //     { label: "Navi Mumbai", value: "Navi Mumbai" },
    //     { label: "Mumbai", value: "Mumbai" },
    //     { label: "Pune", value: "Pune" }
    // ];

    @track earliestStartPermitted;
    @track dueDate;
    isMoreFieldsVisible = false;

    @track availabilityData = [];
    @track dateKeys = [];
    @track filteredData = []; // Data to display
    @track tabOptions = []; // Tab options with active class
    @track activeTab = 'Show All'; // Default active tab
    @track isSaved = false; // Boolean to control the success screen

    @track addressFilter;



    @wire(getPicklistValues)
    wiredPicklistValues({ error, data }) {
        if (data) {
            console.log('data-->>', data);
            this.territoryOptions = data.territory;
        } else if (error) {
            this.showToast('Error', 'Failed to fetch picklist values', 'error');
            console.log(error);
        }
    }

    // Fetch Work Order details when the component is initialized
    connectedCallback() {
        console.log('recordId', this.recordId);
        setTimeout(() => {
            console.log('recordId2', this.recordId);
        }, 15000);
        this.fetchWorkOrderDetails();
        this.fetchServiceAppointments();
        // this.generateDummyData(); // Generate dummy data on component load
        // this.generateTabOptions();
        // this.filterData(); // Default to "Show All"
    }

    // @wire(getRecord, { recordId: '$recordId', fields: ['Work_Order__c.Work_Order_Type__c'] })
    // getCaseRecord({ data, error }) {
    //     if (data) {
    //         console.log('Work_Order__c-->', data);
    //     } else {
    //         console.log('error99', error);
    //     }
    // }


    // Fetch Work Order details
    fetchWorkOrderDetails() {
        getWorkOrderDetails({ workOrderId: this.recordId })
            .then((data) => {
                console.log('workorderdeails-->', data);
                if (data) {
                    this.workOrderNumber = data.Name;
                    this.caseId = data.Case__c;
                    this.workType = data.Work_Order_Type__c;
                    this.address = data.Partner_Function_Address_Information__c;
                    this.territory = data.Case__r?.Case_Territory__r?.Name;
                    this.pinCode = data.Case__r?.Case_Pincode__r?.Name;
                    this.addressFilter = {
                        criteria: [
                            {
                                fieldPath: 'Customer_Name__c',
                                operator: 'eq',
                                value: data.Case__r?.AccountId
                            }
                        ]
                    };
                }
            })
            .catch((error) => {
                console.log('Error fetching Work Order details:', error);
            });
    }

    // Fetch Service Appointment options
    fetchServiceAppointments() {
        getServiceAppointments({ workOrderId: this.recordId })
            // .then((data) => {
            //     this.serviceAppointmentOptions = data.map((appointment) => ({
            //         label: appointment.AppointmentNumber,
            //         value: appointment.Id,
            //     }));
            // })
            .then((data) => {
                console.log('data------->>>>', data);
                // Map service appointments and add "Create New" option
                this.serviceAppointmentOptions = [
                    { label: 'Create a new Service Appointment', value: 'new' },
                    ...data.map((appointment) => ({
                        label: appointment.Name, // Assuming 'Subject' is a field
                        value: appointment.Id
                    }))
                ];
                this.serviceAppointmentOptions.sort((a, b) => a.label.localeCompare(b.label));

            })

            .catch((error) => {
                console.log('Error fetching Service Appointments:', error);
            });
    }

    handleServiceAppointmentChange(event) {
        this.selectedServiceAppointment = event.detail.value;

        if (this.selectedServiceAppointment === "new") {
            this.earliestStartPermitted = this.getTodayDate();
            this.dueDate = this.getTodayDatePlusDays(7);
            this.address = ""; // Reset address for new Service Appointment
            this.selectedTerritory = "";
        } else if (this.selectedServiceAppointment !== "new") {
            // Fetch details of the selected Service Appointment
            this.fetchSelectedServiceAppointmentDetails(this.selectedServiceAppointment);
        }
    }

    // Fetch details of a selected Service Appointment
    fetchSelectedServiceAppointmentDetails(serviceAppointmentId) {
        getServiceAppointmentDetails({ serviceAppointmentId })
            .then((data) => {
                console.log('data--kk>>', data);
                //this.address = data.Address || "";
                this.earliestStartPermitted = data.Assigned_Date__c;
                this.dueDate = data.Due_Date__c;
                this.selectedTerritory = data.Territory__c;
                this.address = data.Partner_Function_Address_Information__c;

            })
            .catch((error) => {
                console.log("Error fetching Service Appointment details:", error);
            });
    }

    // Fetch Service Appointment details
    // fetchServiceAppointmentDetails() {
    //     getServiceAppointmentDetails({ serviceAppointmentId: this.serviceAppointmentId })
    //         .then((result) => {
    //             if (result) {
    //                 this.serviceAppointment = {
    //                     ...result,
    //                     // Format EarliestStartTime and DueDate to only include the date
    //                     EarliestStartTime: result.EarliestStartTime
    //                         ? this.formatDate(result.EarliestStartTime)
    //                         : null,
    //                     DueDate: result.DueDate ? this.formatDate(result.DueDate) : null,
    //                 };
    //             }
    //         })
    //         .catch((error) => {
    //             console.log("Error fetching service appointment details:", error);
    //         });
    // }

    // Format ISO 8601 date to 'YYYY-MM-DD'
    formatDate(isoDate) {
        const date = new Date(isoDate);
        const year = date.getFullYear();
        const month = String(date.getMonth() + 1).padStart(2, "0"); // Months are zero-based
        const day = String(date.getDate()).padStart(2, "0");
        return `${year}-${month}-${day}`; // Format as YYYY-MM-DD
    }

    // Handle "Get Appointments" button click
    getAppointments() {
        console.log('Fetching appointments for:', this.selectedServiceAppointment);
    }

    // Handle Address field changes
    handleAddressChange(event) {
        this.address = event.detail.recordId; // Update the address as the user types
        console.log('address', this.address);
    }

    // Handle changes to the 'Earliest Start Permitted' date
    handleStartDateChange(event) {
        this.earliestStartPermitted = event.target.value; // Update earliestStartPermitted when the user selects a date
    }

    // Handle changes to the 'Due Date'
    handleDueDateChange(event) {
        this.dueDate = event.target.value;
    }

    handlePinCodeChange(event) {
        this.pinCode = event.target.value;
    }

    handleZoneChange(event) {
        this.territory = event.target.value;
    }


    getTodayDate() {
        const today = new Date();
        return today.toISOString().split("T")[0];
    }

    // Utility: Get today's date plus X days in YYYY-MM-DD format
    getTodayDatePlusDays(days) {
        const date = new Date();
        date.setDate(date.getDate() + days);
        return date.toISOString().split("T")[0];
    }

    // Handle Territory selection
    handleTerritoryChange(event) {
        this.selectedTerritory = event.detail.value;
        new Promise((resolve, reject) => {
            getServiceResourceAvailability({
                territory: this.selectedTerritory
            }).then((result) => {
                console.log(result);
            }).catch((error) => {

            })
        }).then(() => {

        })
    }

    // Save new Service Appointment
    // saveNewServiceAppointment() {
    //     // Pass necessary fields to Apex to create a new Service Appointment
    //     createServiceAppointment({
    //         workOrderId: this.recordId,
    //         workType: this.workType,
    //         address: this.address,
    //         territory: this.selectedTerritory
    //     })
    //         .then((result) => {
    //             // Success toast
    //             this.showToast('Success', 'New Service Appointment created successfully!', 'success');
    //             console.log('Created Service Appointment:', result);
    //         })
    //         .catch((error) => {
    //             console.log('Error creating Service Appointment:', error);
    //             this.showToast('Error', 'Failed to create Service Appointment. Please try again.', 'error');
    //         });
    // }

    // Show a toast notification
    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }

    // Handle the "Save" action (Create or Update)
    saveServiceAppointment() {
        // if (!this.selectedTerritory) {
        //     this.showToast('Error', 'Territory must be selected.', 'error');
        //     return;
        // }

        saveServiceAppointment({
            serviceAppointmentId: this.selectedServiceAppointment === 'new' ? null : this.selectedServiceAppointment,
            caseId: this.caseId,
            workOrderId: this.recordId,
            workType: this.workType,
            address: this.address,
            // territory: this.territory,
            earliestStartPermitted: this.earliestStartPermitted,
            dueDate: this.dueDate
        })
            .then((result) => {
                const successMessage = this.selectedServiceAppointment === 'new' ?
                    'New Service Appointment created successfully!' :
                    'Service Appointment updated successfully!';
                this.selectedServiceAppointment = result.Id;
                this.showToast('Success', successMessage, 'success');
                console.log('Service Appointment:', result);
                this.isMoreFieldsVisible = true;  // Make the additional fields visible
                return getServiceResourceAvailability({ woId: this.recordId });
            })
            .then((result) => {
                // this.availabilityData = availabilityResult;
                // console.log('Availability Data:', this.availabilityData);


                for (const date in result) {
                    console.log('date-->', date);
                    console.log('result-->', result);
                    if (result.hasOwnProperty(date)) {
                        if (result[date] && result[date][0] && result[date][0].availableSlot) {
                            const apDate = result[date][0].availableSlot.dt
                            const users = result[date].map(resource => ({
                                name: resource.userName,
                                availableSlots: resource.availableSlot.formattedStartHour + ' - ' + resource.availableSlot.formattedEndHour,
                            }));
                            console.log('resource-->', users);


                            this.availabilityData.push({
                                date: apDate,
                                users: users,
                            });
                        } else {
                            console.log('Error: availableSlot not found for date:', date);
                        }
                    }
                }

                // if (!Array.isArray(this.availabilityData)) {
                //     this.availabilityData = [];
                // }

                // for (const date in result) {
                //     if (result.hasOwnProperty(date)) {
                //         // For each date, map through the users and format the necessary details
                //         const users = result[date].map(resource => ({
                //             name: resource.userName,  // Assuming you want the userName
                //             availableSlots: resource.availableSlot ? `${resource.availableSlot.start} - ${resource.availableSlot.end}` : 'Not Available',  // Assuming the available slot has start and end properties
                //         }));

                //         // Push the structured data (date and users) into the availabilityData array
                //         this.availabilityData.push({
                //             date: date,  // Date (the key in your result)
                //             users: users,  // Array of users with their available slots
                //         });
                //     }
                // }

                console.log('availabilityData--->>', this.availabilityData);
                this.generateTabOptions();
                this.filterData(); // Default to "Show All


            })
            .catch((error) => {
                this.showToast('Error', 'An error occurred while saving the Service Appointment.', 'error');
                console.log('Error saving Service Appointment:', error);
            });
    }


    formatDateTimeToGMTString(date) {
        // Ensure the date is in UTC format
        const utcDate = new Date(date.toISOString());
        const formattedDate = utcDate.toUTCString(); // Fri, 29 Nov 2024 00:00:00 GMT
        const parts = formattedDate.split(' ');

        // Reformat to match 'Fri Nov 29 00:00:00 GMT 2024'
        return `${parts[0]} ${parts[2]} ${parts[1]} ${parts[4]} GMT ${parts[3]}`;
    }


    // Toggle visibility of additional fields
    toggleMoreFields() {
        this.isMoreFieldsVisible = !this.isMoreFieldsVisible;
    }

    // Handle change for additional fields
    handleAdditionalField1Change(event) {
        this.additionalField1 = event.target.value;
    }

    handleAdditionalField2Change(event) {
        this.additionalField2 = event.target.value;
    }


    generateDummyData() {
        const today = new Date();
        const data = [];

        // Generate data for today and the next 6 days
        for (let i = 0; i < 7; i++) {
            const date = new Date(today);
            date.setDate(today.getDate() + i);

            const formattedDate = date.toISOString().split('T')[0]; // Format as YYYY-MM-DD
            data.push({
                date: formattedDate,
                users: [
                    { name: 'User 1', availableSlots: '9:00 - 18:00' },
                    { name: 'User 2', availableSlots: '13:00 - 15:00' }
                ]
            });
        }

        this.availabilityData = data;
    }

    generateTabOptions() {
        const today = new Date();
        const tabs = [{ label: 'Show All', value: 'Show All', class: 'tab active' }];

        for (let i = 0; i < 7; i++) {
            const date = new Date(today);
            date.setDate(today.getDate() + i);

            const day = String(date.getDate()).padStart(2, '0');
            const month = date.toLocaleString('default', { month: 'short' }).toUpperCase();
            //const weekday = date.toLocaleString('default', { weekday: 'short' }).toUpperCase();

            //const label = `${day} ${month}, ${weekday}`;
            const label = `${day} ${month}`;

            tabs.push({ label, value: label, class: 'tab' });
        }

        this.tabOptions = tabs;
    }

    filterData(tab = 'Show All') {
        this.tabOptions.forEach((t) => {
            t.class = t.value === tab ? 'tab active' : 'tab';
        });

        if (tab === 'Show All') {
            this.filteredData = [...this.availabilityData];
        } else {
            const today = new Date();
            const dayIndex = this.tabOptions.findIndex((t) => t.value === tab) - 1; // Skip 'Show All'
            const targetDate = new Date(today.setDate(today.getDate() + dayIndex));
            const formattedDate = targetDate.toISOString().split('T')[0];
            console.log('formattedDate', formattedDate);

            // this.filteredData = this.availabilityData.filter((item) => item.date === formattedDate);
            this.filteredData = this.availabilityData.filter((item) => {
                // Convert availabilityData date to YYYY-MM-DD format
                const itemDate = new Date(item.date).toISOString().split('T')[0]; // Normalize item.date
                return itemDate === formattedDate;
            });

            console.log('filteredData', this.filteredData);
            this.filteredData.forEach(item => {
                console.log('filteredData', item);
            })
        }
    }

    handleTabClick(event) {
        const tabValue = event.target.dataset.value;
        console.log('tabValue', tabValue);
        this.activeTab = tabValue;
        this.filterData(tabValue);
    }

    handleSlotClick(event) {
        console.log('12346--->', event.currentTarget.dataset.user);

        const userName = event.currentTarget.dataset.user;
        const selectedDate = event.currentTarget.dataset.date;
        const selectedSlot = event.currentTarget.dataset.slot;
        console.log('--->', userName, selectedDate, selectedSlot);

        // Call a method to save this data to the backend
        this.saveAvailabilityData(userName, selectedDate, selectedSlot);
    }

    @track formattedStartDate;
    @track formattedEndDate;
    @track selectedServiceAppointmentId;
    // Method to call Apex and save data
    saveAvailabilityData(userName, selectedDate, selectedSlot) {
        saveAvailability({
            serviceAppointmentId: this.selectedServiceAppointment,
            userName: userName,
            selectedDate: selectedDate,
            selectedSlot: selectedSlot
        })
            .then(result => {
                console.log(result); // Success message
                console.log('result--->', result);
                this.isSaved = true; // Set success state to true
                let data = JSON.parse(result);
                console.log('data--->', data);
                this.selectedServiceAppointmentId = data.Id;
                this.formattedStartDate = this.formatSalesforceDateTime(data.Scheduled_Start__c);
                this.formattedEndDate = this.formatSalesforceDateTime(data.Scheduled_End__c);
                console.log('Formatted Start Date: ', this.formattedStartDate);
                console.log('Formatted End Date: ', this.formattedEndDate);

                // Optionally, show a success toast or notify the user
                this.dispatchEvent(
                    new CustomEvent('notify', {
                        detail: { message: 'Availability saved successfully!' }
                    })
                );
            })
            .catch(error => {
                console.log('Error saving availability:', error);
                // Optionally, show an error toast or notify the user
                this.dispatchEvent(
                    new CustomEvent('notify', {
                        detail: { message: 'Error saving availability.' }
                    })
                );
            });
    }


    // Function to format Salesforce DateTime into custom format 'DD-MM-YYYY HH:mm'
    formatSalesforceDateTime(para) {
        // Strip off the timezone part (everything after the last plus sign)
        const dateTimeWithoutTimezone = para.split('+')[0];  // "2024-11-30T02:30:00.000"

        // Replace the 'T' with a space to match the desired format
        const dateTimeFormatted = dateTimeWithoutTimezone.replace('T', ' ');

        // Create a Date object from the formatted string
        const date = new Date(dateTimeFormatted);

        // Extract the year, month, day, hours, and minutes
        const year = date.getFullYear();
        const month = ('0' + (date.getMonth() + 1)).slice(-2);  // Months are zero-indexed, so we add 1
        const day = ('0' + date.getDate()).slice(-2);   // Ensure two digits for day
        const hours = ('0' + date.getHours()).slice(-2);  // Ensure two digits for hours
        const minutes = ('0' + date.getMinutes()).slice(-2); // Ensure two digits for minutes

        // Format the date in "YYYY-MM-DD HH:mm" format
        return `${year}-${month}-${day} ${hours}:${minutes}`;
    }

    viewServiceAppointment() {
        console.log('selectedServiceAppointmentId', this.selectedServiceAppointmentId);
        console.log('click');
        if (this.selectedServiceAppointmentId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.selectedServiceAppointmentId,
                    objectApiName: 'Service_Appointment__c', // Customize with your object API name
                    actionName: 'view',
                },
            });
        }
    }





}