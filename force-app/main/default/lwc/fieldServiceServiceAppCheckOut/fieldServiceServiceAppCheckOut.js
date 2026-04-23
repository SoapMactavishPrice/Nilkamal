import { LightningElement, track, api, wire } from 'lwc';
import LightningModal from 'lightning/modal';
import Id from '@salesforce/user/Id';

import { showToast, getNameAndValueOnChange, closeQuickActionPopup, getShowToastEvents, handleGetGeoLocation, analyzeFormFactor, analyzeUserAgent } from 'c/utilJS';


import getServiceAppointmentDetails from '@salesforce/apex/FieldServiceWorkOrderServiceAppInfo.getServiceAppointmentDetails';

import updateCheckOutLocation from '@salesforce/apex/FieldServiceWorkOrderServiceAppInfo.updateCheckOutLocation';



export default class FieldServiceServiceAppCheckOut extends LightningModal {
    @track showSpinner = false;

    @track isMobile;
    @track isTablet;
    @track isDesktop;

    @api
    get serviceAppointmentId() {
        return this._serviceAppointmentId;
    }
    set serviceAppointmentId(value) {
        if (value === this._serviceAppointmentId) return;
        this._serviceAppointmentId = value;
        getServiceAppointmentDetails({ recordId: value })
            .then(result => {
                console.log('result', result);
                this.serviceAppointment = result;
                this.serviceAppointment = {
                    ...this.serviceAppointment,
                    get isCaseOwnerAndUserSame() {
                        return this.Case__r.OwnerId === Id;
                    },
                };

                const { Check_In_GeoLocation__Latitude__s: checkInLat, Check_In_GeoLocation__Longitude__s: checkInLong } = result.Service_Appointment_Check_Ins_and_Outs__r[0];
                const checkInMarker = {
                    location: {
                        Latitude: checkInLat,
                        Longitude: checkInLong
                    },
                    title: 'Check In Location',
                    value: 'CheckIn',
                    icon: 'utility:checkin'
                };
                if (!this.mapMarkers) {
                    this.mapMarkers = [];
                }
                // this.mapMarkers.push(checkInMarker);
                this.mapMarkers = [...this.mapMarkers, checkInMarker];

                if (Array.isArray(this.mapMarkers) && this.mapMarkers.length === 2) {
                    this.haversineDistanceBetweenPoints(this.mapMarkers[0].location.Latitude, this.mapMarkers[0].location.Longitude, this.mapMarkers[1].location.Latitude, this.mapMarkers[1].location.Longitude);
                }

                console.log('mapMarkers', this.mapMarkers);
            })
            .catch(error => {
                console.log('error', error);
                const toastElement = this.template.querySelector('c-toast-message');
                if (toastElement) {
                    const toasts = getShowToastEvents(this, 'Error', 'Something went wrong', 'error', error);
                    if (toasts) {
                        (Array.isArray(toasts) ? toasts : [toasts]).forEach(toast => toastElement.showToast(toast));
                    }
                }
                this.close('Ok');
            }).finally(() => {
                this.showSpinner = false;
                this.getCurrentLocation();
            });
    }

    @track mapMarkers;
    @track zoomLevel;

    @track serviceAppointment;




    @track getLocationInterval;
    @track isFirstTimeLocated = true;;

    connectedCallback() {
        analyzeFormFactor(this);
        analyzeUserAgent(this);
    }


    async getCurrentLocation() {
        try {
            const myLocation = await handleGetGeoLocation(this);

            const checkOutMarker = {
                location: {
                    Latitude: myLocation.latitude,
                    Longitude: myLocation.longitude
                },
                title: 'Current Location',
                value: 'CheckOut',
                icon: 'utility:choice'
            };
            if (!this.mapMarkers) {
                this.mapMarkers = [];
            }
            if (this.isFirstTimeLocated) {
                this.mapMarkers = [...this.mapMarkers, checkOutMarker];
                this.isFirstTimeLocated = false;
            } else {
                const markerIndex = this.mapMarkers.findIndex(marker => marker.value === 'CheckOut');
                if (markerIndex !== -1) {
                    this.mapMarkers[markerIndex] = checkOutMarker;
                }
            }

            if (Array.isArray(this.mapMarkers) && this.mapMarkers.length === 2) {
                this.haversineDistanceBetweenPoints(this.mapMarkers[0].location.Latitude, this.mapMarkers[0].location.Longitude, this.mapMarkers[1].location.Latitude, this.mapMarkers[1].location.Longitude);
            }
        }
        catch (error) {
            console.log('error', error);
            showToast(this, 'Error', 'Something went wrong', 'error', error);
            this.close('location-disabled');
        }
    }





    @track checkInOutDistance;
    @track distanceBetweenPoints = 0;
    haversineDistanceBetweenPoints(lat1, lon1, lat2, lon2) {
        const R = 6371e3;
        const p1 = lat1 * Math.PI / 180;
        const p2 = lat2 * Math.PI / 180;
        const deltaLon = lon2 - lon1;
        const deltaLambda = (deltaLon * Math.PI) / 180;
        const d = Math.acos(Math.sin(p1) * Math.sin(p2) + Math.cos(p1) * Math.cos(p2) * Math.cos(deltaLambda),) * R;
        console.log('d', d);
        this.distanceBetweenPoints = d;
        this.checkInOutDistance = d > 1000 ? `${(d / 1000).toFixed(2)} km` : `${d.toFixed(2)} m`;

        const distance = d / 1000;
        if (distance < 1) this.zoomLevel = 13;
        else if (distance < 2) this.zoomLevel = 13;
        else if (distance < 5) this.zoomLevel = 12;
        else if (distance < 10) this.zoomLevel = 11;
        else if (distance < 50) this.zoomLevel = 10;
        else if (distance < 100) this.zoomLevel = 8;
    }



    @track scheduleNewVisitRecord = {
        doYouWantToScheduleOneMoreVisit: 'No',
        get isDateDisabled() {
            return this.doYouWantToScheduleOneMoreVisit !== 'Yes';
        },
        get minDate() {
            const today = new Date();
            const year = today.getFullYear();
            const month = String(today.getMonth() + 1).padStart(2, '0');
            const day = String(today.getDate()).padStart(2, '0');
            return `${year}-${month}-${day}`;
        },
        get isCheckout() {
            return this.doYouWantToScheduleOneMoreVisit === 'No';
        },
        get isCheckoutAndSchedule() {
            return this.doYouWantToScheduleOneMoreVisit === 'Yes';
        }
    };



    handleChange(event) {
        const { name, value } = getNameAndValueOnChange(this, event);
        this.scheduleNewVisitRecord[name] = value;
        event.target.setCustomValidity('');
        event.target.reportValidity();
    }



    handleSave(event) {
        const { action } = event.currentTarget.dataset;

        const toastElement = this.template.querySelector('c-toast-message');
        const showToast = (type, message, variant, error) => {
            if (toastElement) {
                const toasts = getShowToastEvents(this, type, message, variant, error);
                if (toasts) {
                    (Array.isArray(toasts) ? toasts : [toasts]).forEach(toast => toastElement.showToast(toast));
                }
            }
        };

        if (this.scheduleNewVisitRecord.isCheckoutAndSchedule && !this.scheduleNewVisitRecord.Scheduled_Start__c) {
            const dateElement = this.template.querySelector('lightning-input[data-name="Scheduled_Start__c"]');
            if (dateElement) {
                dateElement.setCustomValidity('Please select a date.');
                dateElement.reportValidity();
            } else {
                showToast('Error', 'Please select a date and time.', 'error');
            }
            return;
        }

        if (this.distanceBetweenPoints > 2000 && !this.serviceAppointment.Remote_Support__c) {
            if (!this.isDesktop) {
                showToast('Error', 'Distance between Check In and Check Out should be less than 2 km.', 'error');
                return;
            }
        }

        const checkOutMarker = this.mapMarkers.find(marker => marker.value === 'CheckOut');
        if (!checkOutMarker) {
            if (!this.isDesktop) {
                showToast('Error', 'Check Out location not found.', 'error');
                return;
            }
        }
        const { location: { Latitude = '', Longitude = '' } = {} } = checkOutMarker || {};

        this.showSpinner = true;
        updateCheckOutLocation({
            recordId: this.serviceAppointmentId,
            latitude: Latitude,
            longitude: Longitude,
            deviceType: this.deviceType,
            nextVisitDate: this.scheduleNewVisitRecord.Scheduled_Start__c
        })
            .then(result => {
                let msg = 'Checked Out Successfully';
                if (action === 'checkout-and-close-case') {
                    msg = 'Checked out successfully. Redirecting you to the case closure page.';
                }
                const toastElement = this.template.querySelector('c-toast-message');
                const toasts = getShowToastEvents(this, 'Success', msg, 'success');
                if (toasts) {
                    (Array.isArray(toasts) ? toasts : [toasts]).forEach(toast => toastElement.showToast(toast));
                }

                this.close({ action: action });
            })
            .catch(error => {
                console.log('error', error);
                const toastElement = this.template.querySelector('c-toast-message');
                if (toastElement) {
                    const toasts = getShowToastEvents(this, 'Error', 'Something went wrong', 'error', error);
                    if (toasts) {
                        (Array.isArray(toasts) ? toasts : [toasts]).forEach(toast => toastElement.showToast(toast));
                    }
                }
            }).finally(() => {
                this.showSpinner = false;
            });
    }







    handleCancel(event) {
        this.close('Ok');
    }







    get doYouWantToScheduleOneMoreVisitOptions() {
        return [
            { label: 'Yes', value: 'Yes' },
            { label: 'No', value: 'No' }
        ];
    }

}