import { LightningElement, track, wire } from 'lwc';
import getServiceAppointments from '@salesforce/apex/FieldServiceCreateVisitController.getServiceAppointments';
import { showToast, showLightningAlert, analyzeFormFactor, analyzeUserAgent, getNameAndValueOnChange, initCalendar, navigateToRecord, navigateToLWC, navigateToTab, navigateToObjectPage, navigateToUrl, openLightningModal, scrollToTop, loadQuickActionPopupStyle, unloadQuickActionPopupStyle, disablePullToRefresh, enablePullToRefresh } from 'c/utilJS';

export default class CustomerList extends LightningElement {
    @track currentDate = new Date(); // Tracks the current displayed date
    @track items = []; // List of events for the current displayed date
    @track serviceAppointments = [];
    @track error;




    @wire(getServiceAppointments)
    wiredServiceAppointments({ error, data }) {
        if (data) {
            this.serviceAppointments = data.map(appointment => ({
                id: appointment.Id,
                subject: appointment.Subject,
                startDate: appointment.StartDate,
                endDate: appointment.EndDate,
                status: appointment.Status,
            }));
        } else if (error) {
            this.error = error;
            console.error('Error fetching service appointments:', error);
        }
    }

    connectedCallback() {
        this.serviceAppointments = [
            { id: 'a001', subject: 'Installation', startDate: '2024-12-23', endDate: '2024-12-23', status: 'Scheduled' },
            { id: 'a002', subject: 'Maintenance', startDate: '2024-12-24', endDate: '2024-12-24', status: 'Completed' },
        ];
        disablePullToRefresh(this);
    }



    // Sample data for demonstration
    eventsData = {
        '2024-12-23': [
            { id: 1, name: 'Cust Name', installation: 'Installation', time: '9:00 AM', icon: 'utility:preview' },
            { id: 2, name: 'Cust Name', installation: 'Installation', time: '10:00 AM', icon: 'utility:preview' },
            { id: 3, name: 'Cust Name', installation: 'Installation', time: '11:00 AM', icon: 'utility:preview' },
            { id: 4, name: 'Cust Name', installation: 'Installation', time: '12:00 PM', icon: 'utility:preview' },
            { id: 5, name: 'Cust Name', installation: 'Installation', time: '2:00 PM', icon: 'utility:preview' },
            { id: 6, name: 'Cust Name', installation: 'Installation', time: '3:00 PM', icon: 'utility:preview' },
        ],
        '2024-12-24': [
            { id: 1, name: 'Cust Name', installation: 'Installation', time: '9:00 AM', icon: 'utility:preview' },
            { id: 2, name: 'Cust Name', installation: 'Installation', time: '10:00 AM', icon: 'utility:preview' },
            { id: 3, name: 'Cust Name', installation: 'Installation', time: '11:00 AM', icon: 'utility:preview' },
            { id: 4, name: 'Cust Name', installation: 'Installation', time: '12:00 PM', icon: 'utility:preview' },
            { id: 5, name: 'Cust Name', installation: 'Installation', time: '2:00 PM', icon: 'utility:preview' },
            { id: 6, name: 'Cust Name', installation: 'Installation', time: '3:00 PM', icon: 'utility:preview' },
        ],
        '2024-12-25': [
            { id: 1, name: 'Cust Name', installation: 'Installation', time: '9:00 AM', icon: 'utility:preview' },
            { id: 2, name: 'Cust Name', installation: 'Installation', time: '10:00 AM', icon: 'utility:preview' },
            { id: 3, name: 'Cust Name', installation: 'Installation', time: '11:00 AM', icon: 'utility:preview' },
            { id: 4, name: 'Cust Name', installation: 'Installation', time: '12:00 PM', icon: 'utility:preview' },
            { id: 5, name: 'Cust Name', installation: 'Installation', time: '2:00 PM', icon: 'utility:preview' },
            { id: 6, name: 'Cust Name', installation: 'Installation', time: '3:00 PM', icon: 'utility:preview' },
        ],

        '2024-12-26': [
            { id: 1, name: 'Cust Name', installation: 'Installation', time: '9:00 AM', icon: 'utility:preview' },
            { id: 2, name: 'Cust Name', installation: 'Installation', time: '10:00 AM', icon: 'utility:preview' },
            { id: 3, name: 'Cust Name', installation: 'Installation', time: '11:00 AM', icon: 'utility:preview' },
            { id: 4, name: 'Cust Name', installation: 'Installation', time: '12:00 PM', icon: 'utility:preview' },
            { id: 5, name: 'Cust Name', installation: 'Installation', time: '2:00 PM', icon: 'utility:preview' },
            { id: 6, name: 'Cust Name', installation: 'Installation', time: '3:00 PM', icon: 'utility:preview' },
        ],

        '2024-12-27': [
            { id: 1, name: 'Cust Name', installation: 'Installation', time: '9:00 AM', icon: 'utility:preview' },
            { id: 2, name: 'Cust Name', installation: 'Installation', time: '10:00 AM', icon: 'utility:preview' },
            { id: 3, name: 'Cust Name', installation: 'Installation', time: '11:00 AM', icon: 'utility:preview' },
            { id: 4, name: 'Cust Name', installation: 'Installation', time: '12:00 PM', icon: 'utility:preview' },
            { id: 5, name: 'Cust Name', installation: 'Installation', time: '2:00 PM', icon: 'utility:preview' },
            { id: 6, name: 'Cust Name', installation: 'Installation', time: '3:00 PM', icon: 'utility:preview' },
        ],

        '2024-12-28': [
            { id: 1, name: 'Cust Name', installation: 'Installation', time: '9:00 AM', icon: 'utility:preview' },
            { id: 2, name: 'Cust Name', installation: 'Installation', time: '10:00 AM', icon: 'utility:preview' },
            { id: 3, name: 'Cust Name', installation: 'Installation', time: '11:00 AM', icon: 'utility:preview' },
            { id: 4, name: 'Cust Name', installation: 'Installation', time: '12:00 PM', icon: 'utility:preview' },
            { id: 5, name: 'Cust Name', installation: 'Installation', time: '2:00 PM', icon: 'utility:preview' },
            { id: 6, name: 'Cust Name', installation: 'Installation', time: '3:00 PM', icon: 'utility:preview' },
        ],

        '2024-12-29': [
            { id: 1, name: 'Cust Name', installation: 'Installation', time: '9:00 AM', icon: 'utility:preview' },
            { id: 2, name: 'Cust Name', installation: 'Installation', time: '10:00 AM', icon: 'utility:preview' },
            { id: 3, name: 'Cust Name', installation: 'Installation', time: '11:00 AM', icon: 'utility:preview' },
            { id: 4, name: 'Cust Name', installation: 'Installation', time: '12:00 PM', icon: 'utility:preview' },
            { id: 5, name: 'Cust Name', installation: 'Installation', time: '2:00 PM', icon: 'utility:preview' },
            { id: 6, name: 'Cust Name', installation: 'Installation', time: '3:00 PM', icon: 'utility:preview' },
        ],

        '2024-12-30': [
            { id: 1, name: 'Cust Name', installation: 'Installation', time: '9:00 AM', icon: 'utility:preview' },
            { id: 2, name: 'Cust Name', installation: 'Installation', time: '10:00 AM', icon: 'utility:preview' },
            { id: 3, name: 'Cust Name', installation: 'Installation', time: '11:00 AM', icon: 'utility:preview' },
            { id: 4, name: 'Cust Name', installation: 'Installation', time: '12:00 PM', icon: 'utility:preview' },
            { id: 5, name: 'Cust Name', installation: 'Installation', time: '2:00 PM', icon: 'utility:preview' },
            { id: 6, name: 'Cust Name', installation: 'Installation', time: '3:00 PM', icon: 'utility:preview' },
        ],

        '2024-12-31': [
            { id: 1, name: 'Cust Name', installation: 'Installation', time: '9:00 AM', icon: 'utility:preview' },
            { id: 2, name: 'Cust Name', installation: 'Installation', time: '10:00 AM', icon: 'utility:preview' },
            { id: 3, name: 'Cust Name', installation: 'Installation', time: '11:00 AM', icon: 'utility:preview' },
            { id: 4, name: 'Cust Name', installation: 'Installation', time: '12:00 PM', icon: 'utility:preview' },
            { id: 5, name: 'Cust Name', installation: 'Installation', time: '2:00 PM', icon: 'utility:preview' },
            { id: 6, name: 'Cust Name', installation: 'Installation', time: '3:00 PM', icon: 'utility:preview' },
        ],
    };

    // @track eventsListByDay = [
    //     {
    //         label: '18 Dec 2024', dt: '2024-12-18',
    //         items: []
    //     },
    //     {
    //         label: 'Yesterday', dt: '2024-12-22',
    //         items: []
    //     },
    //     {
    //         label: 'Today', dt: '2024-12-23',
    //         items: [{ id: 1, name: 'Cust Name', installation: 'Installation', time: '10:00 AM', icon: 'utility:preview' }]
    //     },
    //     {
    //         label: 'Tomorrow', dt: '2024-12-24',
    //         items: []
    //     },
    //     {
    //         label: 'Day After Tomorrow', dt: '2024-12-25',
    //         items: []
    //     },
    // ];

    // Fetch events for the current date
    connectedCallback() {
        this.updateItems();
    }

    // Update items based on the current date
    updateItems() {
        const formattedDate = this.formatDate(this.currentDate); // Format the current date
        this.items = this.eventsData[formattedDate] || []; // Fetch events for the date or empty array
    }

    // Getter for formatted display date
    get formattedDate() {
        return this.currentDate.toLocaleDateString('en-US', {
            weekday: 'long', // e.g., "Monday"
            year: 'numeric', // e.g., "2024"
            month: 'long',  // e.g., "December"
            day: 'numeric'  // e.g., "23"
        });
    }




    // Format a date to 'YYYY-MM-DD'
    formatDate(date) {
        const year = date.getFullYear();
        const month = (date.getMonth() + 1).toString().padStart(2, '0');
        const day = date.getDate().toString().padStart(2, '0');
        return `${year}-${month}-${day}`;
    }

    // Handle "Previous" button click
    handlePrevious() {
        this.currentDate = new Date(this.currentDate.setDate(this.currentDate.getDate() - 1)); // Go to previous day
        this.updateItems(); // Update items for the new date
    }

    // Handle "Next" button click
    handleNext() {
        this.currentDate = new Date(this.currentDate.setDate(this.currentDate.getDate() + 1)); // Go to next day
        this.updateItems(); // Update items for the new date
    }
}