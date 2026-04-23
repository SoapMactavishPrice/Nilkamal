import { LightningElement, track, api } from 'lwc';
import saveSignatureData from '@salesforce/apex/ServiceResourcesSignatureController.saveSignatureData';
import { showToast } from 'c/utilJS';
import { NavigationMixin } from 'lightning/navigation';
export default class ServiceResourcesSignature extends NavigationMixin(LightningElement) {


    @track isModalOpen = open;
    @api recordId;
    @track signatureData = null;
    @track name = '';


    connectedCallback() {
        console.log('recordId', this.recordId);
    }



    closeModal() {
        this.isModalOpen = false;
        this.navigateToRecordPage();
    }

    drawText(event) {
        // You can handle signature input here if needed
    }

    // Clear the signature pad
    clearSignature() {
        const signaturePad = this.template.querySelector('c-signature-pad');
        if (signaturePad) {
            signaturePad.clear();
        }
    }

    // Save the signature
    saveSignature() {
        const signaturePad = this.template.querySelector('c-signature-pad');

        if (signaturePad) {
            const signatureData = signaturePad.getSignature();
            // const dataURL = signaturePad.getSignature();
            // const text = signaturePad.getInputText();

            // console.log('Input Text:', text);
            console.log('dataURL', signatureData);
            console.log('recordId', this.recordId);

            // this.saveSignatureToService(signatureData);
            saveSignatureData({ recordId: this.recordId, signatureData: signatureData })
                .then(() => {
                    console.log('Signature and Name updated successfully in Service Resources Object!');
                    showToast(this, 'Success', 'Signature Updated Successfully', 'success');

                    // this.showToast('Success', 'Signature Updated Successfully!', 'success');
                    this.closeModal();
                    this.navigateToRecordPage();
                })
                .catch((error) => {
                    console.error('Error updating signature:', error);
                    // this.showToast('Error', 'Failed to update Signature', 'error');
                    showToast(this, 'Error', 'Failed to update Signature', 'error', error);

                });
        }
    }

    navigateToRecordPage() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Service_Resource__c',
                actionName: 'view'
            }
        });
    }



    // saveSignature() {
    //     const signaturePad = this.template.querySelector('c-signature-pad');
    //     if (signaturePad) {
    //         const signatureData = signaturePad.getSignature();
    //         const name = signaturePad.getName();
    //         console.log('name Text:', name);
    //         console.log('signatureData', signatureData);
    //         saveSignatureData({ recordId: this.recordId, signatureData: signatureData, name: name })
    //             .then(() => {
    //                 console.log('Signature and Name updated successfully in Service Resources Object!');
    //                 this.showToast('Success', 'Signature Updated Successfully!', 'success');
    //                 this.closeModal();
    //             })
    //             .catch((error) => {
    //                 console.error('Error updating signature:', error);
    //                 this.showToast('Error', 'Failed to update Signature', 'error');
    //             });
    //     }
    // }
}