import { LightningElement, track,wire, api } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import stopRecInAmazonConnect from '@salesforce/apex/MEDSS_EventController.stopRecInAmazonConnect';
import USER_ID from '@salesforce/user/Id';

// get property from class - token and ctr

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Import custom labels
import successMessageForStopRecording from '@salesforce/label/c.Stop_Recording_Amazon_Connect';
import successTitleForStopRecording from '@salesforce/label/c.Medss_Success_title_Stop_Recording';
import errorMessageForStopRecording from '@salesforce/label/c.Medss_Error_Message_Stop_Recording';
 
export default class Medss_Highlight_panel extends LightningElement {
    @api recordId;
    @track userId = USER_ID;

    @wire(getRecord, { recordId: '$recordId'})
    case;
    

    // Success message on Stop Recording
    showSuccessToast() {
        const evt = new ShowToastEvent({
            title: successTitleForStopRecording,
            message: successMessageForStopRecording,
            variant: 'Success',
            mode: 'sticky'
        });
        this.dispatchEvent(evt);
    }

    // Error message on Stop Recording
    showErrorToast() {
        const evt = new ShowToastEvent({
            title: 'Error',
            message: errorMessageForStopRecording,
            variant: 'Error',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
        setTimeout(() => {
            this.ready = true;
        }, 3000);
    }

  
    stopRecording() {
        console.log('---inside stop rec---');
        //console.log('user id '+this.userId);
        stopRecInAmazonConnect({
            userInfoId : this.userId
        })
            .then((result) => {
                console.log(' result is '+result);
                this.stopRecResults = result;
                if (result === false) {
                    this.showErrorToast();
                } else {
                    this.showSuccessToast();
                }
            })
            .catch((error) => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error updating record',
                        message:
                            error.body.message +
                            error.statusText, 
                        variant: 'error'
                    })
                );
            });
    }
}