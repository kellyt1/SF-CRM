import { LightningElement } from 'lwc';
import IntakeJobs from '@salesforce/apex/BatchJobStatusController.getIntakeJobs';
import OutboundJobs from '@salesforce/apex/BatchJobStatusController.getOutboundJobs';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class BatchJobStatus extends LightningElement {

    lastIntakeRunTime;
    nextIntakeRunTime;
    lastOutboundRunTime;
    nextOutboundRunTime;
    batchJobs = [];
    job;

    connectedCallback() {
        this.getBatchJobStatus();
        this.getOutboundJobs();
    }

    // Get Last and Next Intake Scheduled job run
    getBatchJobStatus() {
        IntakeJobs()
            .then((result) => {
                this.lastIntakeRunTime = result;
            })
            .catch((error) => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.body.message,
                        variant: 'error',
                        mode: 'sticky'
                    })
                );
            });
    }

    //Get Last and Next Outbound Scheduled job run
    getOutboundJobs(){
        OutboundJobs()
            .then((result) => {
                this.lastOutboundRunTime = result;
            })
            .catch((error) => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.body.message,
                        variant: 'error',
                        mode: 'sticky'
                    })
                );
            });
    }
}