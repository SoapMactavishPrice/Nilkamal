import { LightningElement, wire, track, api } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import fetchDataBySerialNumber from '@salesforce/apex/CreateCaseController.fetchDataBySerialNumber';
import saveCaseData from '@salesforce/apex/CreateCaseController.saveCaseData';
import fetchDataByInvoiceAndSerialNumber from '@salesforce/apex/CreateCaseController.fetchDataByInvoiceAndSerialNumber';
import { showToast, disablePullToRefresh } from 'c/utilJS';
// import verifyCaptcha from '@salesforce/apex/CreateCaseController.verifyCaptcha';
// import RECAPTCHA_API from '@salesforce/resourceUrl/reCAPTCHA';
// import { loadScript } from 'lightning/platformResourceLoader';
// import RECAPTCHA_SITE_KEY from '@salesforce/label/c.RecaptchaSiteKey';
// import pageUrl from '@salesforce/resourceUrl/reCaptchav3';
// import isReCaptchaValid from '@salesforce/apex/CreateCaseController.isReCaptchaValid';






export default class CreateCase extends LightningElement {
    @track serialNumber = '';
    @track customerName = '';
    @track invoiceNumber = '';
    @track assetNumber = '';
    @track name = '';
    @track email = '';
    @track contactNo = '';
    @track issue = '';
    @track location = '';
    @track comment = '';
    @track businessVertical = '';
    @track warrantyStatus;
    @track amcStatus;
    @track isReadOnly = false;
    @track showSpinner = false;
    @track issueOptions = [
        { label: 'Preventive Maintenance', value: 'Preventive Maintenance' },
        { label: 'Breakdown', value: 'Breakdown' }
    ];
    // @track fetchAsset = true;
    @track errorMessage = '';
    @track isNoAssetFound = false;
    @track isFormVisible = true;
    @track isSuccessMessageVisible = false;

    // @track recaptchaSiteKey = '6LcN_dUqAAAAALSaov7E1APBIClfFrQ1MziFA_AT';
    // @track recaptchaResponse = null;
    // @track recaptchaAction = 'submit_form';
    // @track isRecaptchaLoaded = false;

    // @track captchaValidated = false;

    // renderedCallback() {
    //     let divElement = this.template.querySelector("#recaptchaDiv");
    //     document.dispatchEvent(new CustomEvent("grecaptchaRender", { "detail": { element: divElement } }));
    // }

    // renderedCallback() {
    //     if (!window.grecaptcha) {
    //         this.loadReCAPTCHA();
    //     }
    // }



    // renderedCallback() {
    //     if (this.isRecaptchaLoaded) {
    //         return;
    //     }

    //     this.isRecaptchaLoaded = true;

    //     loadScript(this, RECAPTCHA_API)
    //         .then(() => {
    //             window.grecaptcha.ready(() => {
    //                 this.executeRecaptcha();
    //             });
    //         })
    //         .catch(error => {
    //             console.error('Error loading reCAPTCHA script:', error);
    //         });
    // }

    // renderedCallback() {
    //     if (window.grecaptcha) {
    //         return;
    //     }

    //     loadScript(this, 'https://www.google.com/recaptcha/api.js?render=6LcN_dUqAAAAALSaov7E1APBIClfFrQ1MziFA_AT')
    //         .then(() => {
    //             window.grecaptcha.ready(() => {
    //                 window.grecaptcha.execute('6LcN_dUqAAAAALSaov7E1APBIClfFrQ1MziFA_AT', { action: 'submit' }).then((token) => {
    //                     this.recaptchaResponse = token;
    //                 });
    //             });
    //         })
    //         .catch(error => {
    //             console.error('Error loading reCAPTCHA script:', error);
    //         });
    // }

    // renderedCallback() {
    //     if (window.grecaptcha) {
    //         return;
    //     }

    //     loadScript(this, 'https://www.google.com/recaptcha/api.js?render=' + this.recaptchaSiteKey)
    //         .then(() => {
    //             window.grecaptcha.ready(() => {
    //                 window.grecaptcha.execute(this.recaptchaSiteKey, { action: 'submit' }).then((token) => {
    //                     this.recaptchaResponse = token;
    //                 });
    //             });
    //         })
    //         .catch(error => {
    //             console.error("Error loading reCAPTCHA script:", error);
    //         });
    // }


    // loadReCAPTCHA() {
    //     const script = document.createElement('script');
    //     script.src = `https://www.google.com/recaptcha/api.js?render=${this.recaptchaSiteKey}`;
    //     // script.src = RECAPTCHA_API;
    //     script.onload = () => {
    //         window.grecaptcha.ready(() => {
    //             this.executeRecaptcha();
    //         });
    //     };
    //     document.body.appendChild(script);
    // }

    // executeRecaptcha() {
    //     window.grecaptcha.execute(this.recaptchaSiteKey, { action: this.recaptchaAction }).then((token) => {
    //         this.recaptchaResponse = token;
    //     });
    // }



    handleInputChange(event) {
        // const field = event.target.label.toLowerCase().replace(' ', '');
        const field = event.target.dataset.field;
        this[field] = event.target.value;
        console.log('field', field, this[field]);

    }
    @wire(CurrentPageReference)
    getStateFromPageReference(currentPageReference) {
        if (currentPageReference) {

            const serialNumberParam = currentPageReference.state.c__serialNumber;
            console.log('serialNumberParam', serialNumberParam);
            if (serialNumberParam) {
                this.serialNumber = serialNumberParam;
                // this.serialNumber = 'A-98989889';
                this.isReadOnly = true;
                this.fetchData();
            } else {
                this.isReadOnly = false;
                // this.fetchAsset = false;
            }
        }
    }
    connectedCallback() {
        console.log('connectedCallback from CreateCase');
        disablePullToRefresh(this);
        // this.loadRecaptcha();
        // 18-02
        // document.addEventListener("grecaptchaVerified", this.captchaListener.bind(this));
        // document.addEventListener("grecaptchaExpired", function () {
        //     this.captchaValidated = false;
        // });
        // 18-02
    }

    captchaListener(message) {
        this.captchaValidated = true;
    }

    fetchData() {
        this.showSpinner = true;
        fetchDataBySerialNumber({ serialNumber: this.serialNumber })
            .then(result => {
                this.showSpinner = false;
                console.log('result', result);
                console.log('result', result.asset.Account.Name);
                if (result) {
                    this.customerName = result.asset.Account.Name;
                    this.invoiceNumber = result.asset.Invoice_Number__c;
                    this.assetName = result.asset.Name;
                    this.serialNumber = result.asset.SerialNumber;
                    this.name = result.asset.Contact.Name;
                    this.contactId = result.asset.ContactId;
                    this.assetId = result.asset.Id;
                    this.businessVertical = result.asset.Business_Vertical__c;
                    this.warrantyStatus = result.warrantyStatus;
                    this.amcStatus = result.amcStatus;
                    // this.fetchAsset = true;
                    this.isNoAssetFound = false;
                } else {
                    // this.fetchAsset = false;
                    this.isNoAssetFound = true;
                    this.isReadOnly = false;

                }
            })
            .catch(error => {
                this.showSpinner = false;
                // this.fetchAsset = false;
                this.isReadOnly = false;
                this.isNoAssetFound = true;
                console.error('Error fetching data', error);
            });
    }

    handleSave() {
        // if (!this.recaptchaResponse) {
        //     this.errorMessage = 'Please complete the reCAPTCHA verification.';
        //     return;
        // }
        // this.errorMessage = '';

        // verifyCaptcha({ recaptchaResponse: this.recaptchaResponse })
        //     .then(isValid => {
        //         if (isValid) {
        //             // Proceed with saving case data if reCAPTCHA is valid
        //             this.saveCaseData();
        //         } else {
        //             alert('Invalid reCAPTCHA. Please try again.');
        //         }
        //     })
        //     .catch(error => {
        //         console.error('Error verifying reCAPTCHA:', error);
        //     });


        // if (!this.assetId) {
        //     this.handleFetchDataByInvoiceAndSerialNumber()
        //         .then(() => {
        //             this.saveCaseData();
        //         })
        //         .catch(error => {
        //             console.error('Error fetching asset:', error);
        //         });
        // } else {
        //     this.saveCaseData();
        // }

        // const caseData = {
        //     serialNumber: this.serialNumber,
        //     customerName: this.customerName,
        //     invoiceNumber: this.invoiceNumber,
        //     assetName: this.assetName,
        //     name: this.name,
        //     email: this.email,
        //     contactNo: this.contactno,
        //     issue: this.issue,
        //     location: this.location,
        //     comment: this.comment,
        //     assetId: this.assetId
        // };
        // console.log('caseData', caseData);
        // this.saveCaseData(caseData);

        this.saveCaseData();


        // try {
        //     const token = await this.executeRecaptcha('submit');
        //     this.verifyTokenWithApex(token);
        // } catch (error) {
        //     console.error('reCAPTCHA execution error', error);
        // }
    }


    handleFetchDataByInvoiceAndSerialNumber() {
        return new Promise((resolve, reject) => {
            console.log('invoiceNumber', this.invoiceNumber, 'serialNumber', this.serialNumber);
            fetchDataByInvoiceAndSerialNumber({ invoiceNumber: this.invoiceNumber, serialNumber: this.serialNumber })
                .then(result => {
                    if (result) {
                        this.assetId = result.Id;
                        console.log('Asset found:', result);
                        resolve();
                    } else {
                        reject('No asset found with the given invoice number and serial number');
                    }
                })
                .catch(error => {
                    reject(error);
                });
        });
    }

    saveCaseData() {
        const caseData = {
            serialNumber: this.serialNumber,
            customerName: this.customerName,
            invoiceNumber: this.invoiceNumber,
            assetName: this.assetName,
            name: this.name,
            email: this.email,
            contactNo: this.contactNo,
            issue: this.issue,
            location: this.location,
            comment: this.comment,
            assetId: this.assetId,
            contactId: this.contactId,
            businessVertical: this.businessVertical
        };
        console.log('caseData', caseData);

        this.showSpinner = true;
        saveCaseData({ caseData })
            .then(() => {
                this.showSpinner = false;
                showToast(this, 'Success', 'Case saved successfully', 'success');
                console.log('Case saved successfully');
                this.clearFields();
                this.isFormVisible = false;
                this.isSuccessMessageVisible = true;
            })
            .catch(error => {
                this.showSpinner = false;
                showToast(this, 'Error', 'Error saving case', 'error', error);
                console.error('Error saving case', error);
                this.isFormVisible = true;
                this.isSuccessMessageVisible = false;
            });
    }

    clearFields() {
        // this.serialNumber = '';
        // this.customerName = '';
        // this.invoiceNumber = '';
        // this.assetName = '';
        this.name = '';
        this.email = '';
        this.contactNo = '';
        this.issue = '';
        this.location = '';
        this.comment = '';
        // this.assetId = '';
    }


    // 
    // @api formToken;
    // @api validReCAPTCHA = false;

    // @track navigateTo;
    // captchaWindow = null;

    // constructor() {
    //     super();
    //     this.navigateTo = pageUrl;
    //     window.addEventListener("message", this.listenForMessage);
    // }
    // listenForMessage(e) {
    //     console.log(e);
    //     console.log('e-' + JSON.stringify(e.data));
    //     if (e.data) {
    //         if (e.data.action == "getCAPCAH" && e.data.callCAPTCHAResponse == "") {
    //             console.log("Token not obtained!")
    //         } else if (e.data.action == "getCAPCAH") {
    //             this.formToken = e.data.callCAPTCHAResponse;
    //             isReCaptchaValid({ token: formToken }).then(data => {
    //                 this.validReCAPTCHA = data;
    //             });
    //         };
    //     }
    // }
    // onCaptchaLoaded(evt) {
    //     var e = evt;
    //     console.log(e.target.getAttribute('src') + ' loaded-' + pageUrl);
    //     if (e.target.getAttribute('src') == pageUrl) {
    //         this.listenForMessage(evt);
    //     }
    // }

    // 
    // widgetId = null;

    // renderedCallback() {
    //     console.log('LWC renderedCallback triggered');

    //     if (!window.grecaptcha) {
    //         console.log('reCAPTCHA script found in window.grecaptcha');
    //         this.renderRecaptcha();
    //     } else {
    //         console.error('reCAPTCHA script not found! Ensure it is added in Community Site <body>.');
    //     }
    // }

    // renderRecaptcha() {
    //     console.log('Dispatching event to trigger reCAPTCHA rendering');

    //     document.dispatchEvent(new CustomEvent('grecaptchaRender', {
    //         detail: { element: this.template.querySelector('#recaptchaCheckbox') }
    //     }));

    //     document.addEventListener('grecaptchaVerified', this.handleVerification.bind(this));

    //     document.addEventListener('grecaptchaExpired', () => {
    //         console.warn('reCAPTCHA expired, user needs to revalidate');
    //     });

    //     document.addEventListener('grecaptchaError', () => {
    //         console.error('reCAPTCHA encountered an error');
    //     });

    //     console.log('Event listeners for reCAPTCHA verification, expiration, and error added');
    // }

    // handleVerification(event) {
    //     console.log('reCAPTCHA verified successfully, token:', event.detail.response);

    //     this.dispatchEvent(new CustomEvent('recaptchaverified', {
    //         detail: { response: event.detail.response }
    //     }));
    // }


    // recaptchaLoaded = false;
    // token;

    // loadRecaptcha() {
    //     if (!this.recaptchaLoaded) {
    //         loadScript(this, 'https://www.google.com/recaptcha/api.js?render=' + RECAPTCHA_SITE_KEY)
    //             .then(() => {
    //                 this.recaptchaLoaded = true;
    //                 console.log('reCAPTCHA loaded successfully');
    //             })
    //             .catch(error => {
    //                 console.error('reCAPTCHA failed to load', error);
    //             });
    //     }
    // }

    // async executeRecaptcha(actionName) {
    //     if (this.recaptchaLoaded) {
    //         return new Promise((resolve, reject) => {
    //             grecaptcha.ready(() => {
    //                 grecaptcha.execute(RECAPTCHA_SITE_KEY, { action: actionName }).then(token => {
    //                     this.token = token;
    //                     resolve(token);
    //                 }).catch(error => {
    //                     reject(error);
    //                 });
    //             });
    //         });
    //     }
    // }

    // async handleSubmit() {
    //     try {
    //         const token = await this.executeRecaptcha('submit');
    //         this.verifyTokenWithApex(token);
    //     } catch (error) {
    //         console.error('reCAPTCHA execution error', error);
    //     }
    // }

    // verifyTokenWithApex(token) {
    //     verifyRecaptcha({ token: token })
    //         .then(response => {
    //             if (response.success) {
    //                 console.log('reCAPTCHA verified successfully!');
    //             } else {
    //                 console.error('reCAPTCHA verification failed', response.message);
    //             }
    //         })
    //         .catch(error => {
    //             console.error('Error verifying reCAPTCHA:', error);
    //         });
    // }





}