import { LightningElement } from 'lwc';
import GetSlackTags from '@salesforce/apex/MEDSS_EditConfigController.getSlackTags';
import AddSlackTag from '@salesforce/apex/MEDSS_EditConfigController.addSlackTag';
import DelSlackTags from '@salesforce/apex/MEDSS_EditConfigController.deleteSlackTags';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const columns = [
    { label: 'Tag Name', fieldName: 'tagName', type: 'text', sortable: true },
    { label: 'Tag Id', fieldName: 'tagId', type: 'text' }
];

export default class MedssEditSlackTagConfig extends LightningElement {
    columns = columns;
    slackTags = [];
    tagName;
    tagId;
    showModal = false;
    disableSave = true;
    sortedBy = 'tagName';
    sortedDirection = 'asc';

    connectedCallback() {
        this.getSlackTags();
    }

    // Get Slack Tags and Ids
    getSlackTags() {
        GetSlackTags()
            .then((result) => {
                this.slackTags = [];

                result.forEach((record) => {
                    let tag = {};
                    tag.Id = record.Id;
                    tag.tagName = record.Name;
                    tag.tagId = record.SlackId__c;
                    this.slackTags = [...this.slackTags, tag];
                });
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

    handleAdd() {
        this.showModal = true;
    }

    handleDelete() {
        this.delSlackTags();
    }

    handleCancel() {
        this.showModal = false;
    }

    handleSave() {
        this.addSlackTag();
        this.showModal = false;
    }

    onInputChange(event) {
        this[event.target.name] = event.target.value;
        this.allowSave();
    }

    allowSave() {
        if (this.tagName && this.tagId) {
            this.disableSave = false;
        }
    }

    getSelectedId(event) {
        this.selectedRows = event.detail.selectedRows;
    }

    // Add Tags
    addSlackTag() {
        AddSlackTag({ name: this.tagName, slackId: this.tagId })
            .then((result) => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Tag Added',
                        variant: 'success',
                        mode: 'dismissable'
                    })
                );
            })
            .then(() => {
                this.getSlackTags();
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

    // Delete Tags by Id
    delSlackTags() {
        let recIds = [];
        this.selectedRows.forEach((record) => {
            recIds.push(record.Id);
        });
        if (recIds.length === 0) return;

        DelSlackTags({ slackIds: recIds })
            .then((result) => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Tags Deleted',
                        variant: 'success',
                        mode: 'dismissable'
                    })
                );
            })
            .then(() => {
                this.getSlackTags();
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

    // The method onsort event handler
    handleColumnSorting(event) {
        var fieldName = event.detail.fieldName;
        var sortDirection = event.detail.sortDirection;
        // Assign the latest attribute with the sorted column fieldName and sorted direction
        this.sortedBy = fieldName;
        this.sortedDirection = sortDirection;
        this.slackTags = this.sortData(fieldName, sortDirection);
    }

    sortData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.slackTags));
        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
        };
        // Cheking reverse direction
        let isReverse = direction === 'asc' ? 1 : -1;
        // Sorting data
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // Handling null values
            y = keyValue(y) ? keyValue(y) : '';
            // Sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });
        return parseData;
    }
}
