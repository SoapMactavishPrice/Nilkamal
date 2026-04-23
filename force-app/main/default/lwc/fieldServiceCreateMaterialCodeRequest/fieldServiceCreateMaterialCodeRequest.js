import { track, api, LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import uploadFile from '@salesforce/apex/FileUploaderClass.uploadFile'
import OEM_MATERIAL_CODE_FIELD from '@salesforce/schema/Spare_Material_Request__c.OEM_Material_Code__c';


export default class FieldServiceCreateMaterialCodeRequest extends NavigationMixin(LightningElement) {
    @track caseId;
    @api CaseStatus = 'New';
    @api reqId;
    @api recordId;
    @track materialCode;
    @track serialNo;


    @wire(CurrentPageReference)
    getCurrentPageReference(currentPageReference) {
        this.currentPageReference = currentPageReference;
        console.log('OUTPUT : ', this.currentPageReference);
        if (this.currentPageReference) {
            this.caseId = this.currentPageReference.state.c__caseId;
            this.materialCode = this.currentPageReference.state.c__materialCode;
            this.serialNo = this.currentPageReference.state.c__serialNo;
        }
    }


    handleSuccess(event) {
        this.reqId = event.detail.id;
        this.recordId = event.detail.id;
        if (this.fileData) {
            this.fileData['recordId'] = this.reqId;
            const { base64, filename, recordId } = this.fileData
            uploadFile({ base64, filename, recordId }).then(result => {
                this.fileData = null
                console.log(result);
            });
        }

        const evt = new ShowToastEvent({
            title: 'Success',
            message: 'New Spare Material Request created Successfully',
            variant: 'success',
        });
        const inputFields = this.template.querySelectorAll('lightning-input-field');
        inputFields.forEach(field => {
            field.reset();
        });
        this.dispatchEvent(evt);
        this.navigateToRecord();
    }

    navigateToRecord() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.reqId,
                actionName: 'view'
            }
        });
    }
    fileData
    openfileUpload(event) {
        const file = event.target.files[0]
        var reader = new FileReader()
        console.log(file.size);
        if (file.size > 2048000) {
            const evt = new ShowToastEvent({
                title: 'Error',
                message: 'File size should be less than 2 MB',
                variant: 'error',
            });
            this.dispatchEvent(evt);
            return;
        }
        reader.onload = () => {
            var base64 = reader.result.split(',')[1]
            this.fileData = {
                'filename': file.name,
                'base64': base64,
                'recordId': this.recordId
            }
            console.log(this.fileData)
        }
        reader.readAsDataURL(file)
    }

    cancelAction(event) {
        window.history.back();
    }

    handleSubmit(event) {
        event.preventDefault();
        const fields = event.detail.fields;

        if (!fields.OEM_Material_Code__c || fields.OEM_Material_Code__c.trim() === '') {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'OEM Material Code is required',
                    variant: 'error'
                })
            );
            return;
        }

        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }

}