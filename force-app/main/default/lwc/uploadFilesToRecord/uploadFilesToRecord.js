import { LightningElement, track, api, wire } from 'lwc';



export default class UploadFilesToRecord extends LightningElement {

    @api recordId;
    @api objectApiName;

}