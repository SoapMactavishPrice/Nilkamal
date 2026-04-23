import { LightningElement, track, api, wire } from 'lwc';
import saveGeoLocation from '@salesforce/apex/GetGeoLocationController.saveGeoLocation';
import saveGeoLocationPermissionDenied from '@salesforce/apex/GetGeoLocationController.saveGeoLocationPermissionDenied';
import LightningModal from 'lightning/modal';
import { showToast, getShowToastEvents } from 'c/utilJS';


export default class GetGeoLocation extends LightningModal {
    @track showSpinner = true;

    @api
    get recordId() {
        return this._recordId;
    }
    set recordId(value) {
        this._recordId = value;
        this.handleGetGeoLocation();
    }

    @api
    get geoLocationFieldApiName() {
        return this._geoLocationFieldApiName;
    }
    set geoLocationFieldApiName(value) {
        this._geoLocationFieldApiName = value;
        this.handleGetGeoLocation();
    }

    @api
    get geoLocationErrorFieldApiName() {
        return this._geoLocationErrorFieldApiName;
    }
    set geoLocationErrorFieldApiName(value) {
        this._geoLocationErrorFieldApiName = value;
        this.handleGetGeoLocation();
    }

    @api
    get addressFieldApiName() {
        return this._addressFieldApiName;
    }
    set addressFieldApiName(value) {
        this._addressFieldApiName = value;
        this.handleGetGeoLocation();
    }

    @api
    get addressErrorFieldApiName() {
        return this._addressErrorFieldApiName;
    }
    set addressErrorFieldApiName(value) {
        this._addressErrorFieldApiName = value;
        this.handleGetGeoLocation();
    }

    @api
    get dateFieldApiName() {
        return this._dateFieldApiName;
    }
    set dateFieldApiName(value) {
        this._dateFieldApiName = value;
        this.handleGetGeoLocation();
    }

    @api
    get override() {
        return this._override;
    }
    set override(value) {
        this._override = value;
        this.handleGetGeoLocation();
    }


    handleGetGeoLocation() {
        if (this.recordId &&
            this.geoLocationFieldApiName && this.geoLocationErrorFieldApiName &&
            this.addressFieldApiName && this.addressErrorFieldApiName &&
            this.dateFieldApiName && (this.override != null || this.override != undefined)) {
            if (navigator.geolocation) {
                console.log('navigator.geolocation', navigator.geolocation);
                console.log('navigator.geolocation', navigator.geolocation.getCurrentPosition);
                console.log('navigator.geolocation', (typeof navigator.geolocation.getCurrentPosition === 'function'));
                console.log('navigator.geolocation', navigator.geolocation.getCurrentPosition.length);


                navigator.geolocation.getCurrentPosition(position => {
                    console.log('navigator.geolocation', position);
                    const latitude = position.coords.latitude;
                    const longitude = position.coords.longitude;

                    saveGeoLocation({
                        recordId: this.recordId,
                        geoLocationFieldApiName: this.geoLocationFieldApiName, geoLocationErrorFieldApiName: this.geoLocationErrorFieldApiName,
                        addressFieldApiName: this.addressFieldApiName, addressErrorFieldApiName: this.addressErrorFieldApiName,
                        dateFieldApiName: this.dateFieldApiName, latitude: latitude, longitude: longitude, isOverride: this.override
                    })
                        .then(result => {
                            console.log('result', result);
                            this.close('Ok');
                        })
                        .catch(error => {
                            console.log('error', error);
                            const toasts = getShowToastEvents(this, 'Error', 'Something went wrong', 'error', error);
                            this.close(toasts);
                        })
                        .finally(() => {
                            this.showSpinner = false;
                        });
                },
                    error => {
                        console.log('error', error, JSON.stringify(error));
                        this.showSpinner = false;
                        console.error('Error while retrieving geolocation:', error);
                        switch (error.code) {
                            case error.PERMISSION_DENIED:
                                console.log('error.PERMISSION_DENIED', error.PERMISSION_DENIED);
                                console.error('User denied the request for Geolocation.');
                                console.log('--->', error.code, error.message);
                                alert('Location access was denied. Please allow location access and try again.');
                                break;

                            case error.POSITION_UNAVAILABLE:
                                console.log('error.POSITION_UNAVAILABLE', error.POSITION_UNAVAILABLE);
                                console.error('Location information is unavailable.');
                                console.log('--->2', error.code, error.message);
                                alert('Unable to retrieve your location. Please check your device settings.');
                                break;

                            case error.TIMEOUT:
                                console.log('error.TIMEOUT', error.TIMEOUT);
                                console.error('The request to get user location timed out.');
                                console.log('--->3', error.code, error.message);
                                alert('Getting your location took too long. Please try again.');
                                break;

                            default:
                                console.error('An unknown error occurred.');
                                console.log('--->4', error.code, error.message);
                                alert('An unknown error occurred while retrieving your location. Please try again.');
                                break;

                        }




                        saveGeoLocationPermissionDenied({
                            recordId: this.recordId,
                            geoLocationFieldApiName: this.geoLocationFieldApiName,
                            geoLocationErrorFieldApiName: this.geoLocationErrorFieldApiName,
                            dateFieldApiName: this.dateFieldApiName
                        })
                            .then(result => {
                                console.log('result', result);
                                this.close();
                            })
                            .catch(error => {
                                console.log('error', error);
                                const toasts = getShowToastEvents(this, 'Error', 'Something went wrong', 'error', error);
                                this.close(toasts);
                            })
                            .finally(() => {
                                this.showSpinner = false;
                            });
                    },
                    {
                        enableHighAccuracy: true,
                        timeout: 5000,
                        maximumAge: 0
                    }
                );
            } else {
                console.log('Geolocation is not supported in this browser.');
            }
        }
    }



    // handleGetGeoLocation() {
    //     if (
    //         this.recordId &&
    //         this.geoLocationFieldApiName && this.geoLocationErrorFieldApiName &&
    //         this.addressFieldApiName && this.addressErrorFieldApiName &&
    //         this.dateFieldApiName && (this.override !== null || this.override !== undefined)
    //     ) {
    //         if (navigator.geolocation) {
    //             console.log('Geolocation is supported in this browser.');

    //             navigator.geolocation.getCurrentPosition(
    //                 position => {
    //                     // Success case
    //                     if (!position || !position.coords) {
    //                         console.error('Error: Position data is unavailable or incomplete.');
    //                         alert('Unable to retrieve your location. Please try again.');
    //                         return;
    //                     }

    //                     const latitude = position.coords.latitude;
    //                     const longitude = position.coords.longitude;
    //                     console.log('Latitude:', latitude, 'Longitude:', longitude);

    //                     // Save geolocation
    //                     saveGeoLocation({
    //                         recordId: this.recordId,
    //                         geoLocationFieldApiName: this.geoLocationFieldApiName,
    //                         geoLocationErrorFieldApiName: this.geoLocationErrorFieldApiName,
    //                         addressFieldApiName: this.addressFieldApiName,
    //                         addressErrorFieldApiName: this.addressErrorFieldApiName,
    //                         dateFieldApiName: this.dateFieldApiName,
    //                         latitude: latitude,
    //                         longitude: longitude,
    //                         isOverride: this.override
    //                     })
    //                         .then(result => {
    //                             console.log('Location saved successfully:', result);
    //                             this.close('Ok'); // Close modal or process
    //                         })
    //                         .catch(error => {
    //                             console.error('Error saving location:', error);
    //                             alert('Something went wrong while saving the location.');
    //                         });
    //                 },
    //                 error => {
    //                     console.error('Error occurred while fetching geolocation:', error);

    //                     saveGeoLocationPermissionDenied({
    //                         recordId: this.recordId,
    //                         geoLocationFieldApiName: this.geoLocationFieldApiName,
    //                         geoLocationErrorFieldApiName: this.geoLocationErrorFieldApiName,
    //                         dateFieldApiName: this.dateFieldApiName
    //                     })
    //                         .then(result => {
    //                             console.log('result', result);
    //                             this.close();
    //                         })
    //                         .catch(error => {
    //                             console.log('error', error);
    //                             const toasts = getShowToastEvents(this, 'Error', 'Something went wrong', 'error', error);
    //                             this.close(toasts);
    //                         })
    //                         .finally(() => {
    //                             this.showSpinner = false;
    //                         });
    //                 }
    //             );
    //         } else {
    //             console.error('Geolocation is not supported in this browser.');
    //             alert('Geolocation is not supported in this browser. Please use a supported browser.');
    //         }
    //     } else {
    //         this.showSpinner = false;
    //         console.error('Required parameters are missing.');
    //         alert('Missing required parameters. Please check your configuration.');
    //     }
    // }


}