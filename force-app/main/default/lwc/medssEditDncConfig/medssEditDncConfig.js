import { LightningElement } from 'lwc';
import GetDncCounties from '@salesforce/apex/MEDSS_EditConfigController.getDoNotCallCounties';
import AddDncCounties from '@salesforce/apex/MEDSS_EditConfigController.addDoNotCallCounties';
import DelDncCounties from '@salesforce/apex/MEDSS_EditConfigController.deleteDoNotCallCounties';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const columns = [
    {
        label: 'County',
        fieldName: 'County_Name__c',
        type: 'text',
        sortable: true
    }
];

export default class MedssEditDncConfig extends LightningElement {
    columns = columns;
    dncCounties = [];
    county;
    showModal = false;
    disableSave = true;
    sortedBy = 'county';
    sortedDirection = 'asc';

    connectedCallback() {
        this.getDncCounties();
    }

    // Get Do Not Call Counties
    getDncCounties() {
        GetDncCounties()
            .then((result) => {
                this.dncCounties = [];

                result.forEach((record) => {
                    let county = {};
                    county.Id = record.Id;
                    county.Name = record.Name;
                    county.County_Name__c = record.County_Name__c;
                    this.dncCounties = [...this.dncCounties, county];
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
        this.delDncCounties();
    }

    handleCancel() {
        this.showModal = false;
    }

    handleSave() {
        this.addDncCounties();
        this.showModal = false;
    }

    onInputChange(event) {
        this[event.target.name] = event.target.value;
        this.allowSave();
    }

    allowSave() {
        if (this.county) {
            this.disableSave = false;
        }
    }

    getSelectedId(event) {
        this.selectedRows = event.detail.selectedRows;
    }

    // Add Do Not Call Records
    addDncCounties() {
        AddDncCounties({ county: this.county })
            .then((result) => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'County Added',
                        variant: 'success',
                        mode: 'dismissable'
                    })
                );
            })
            .then(() => {
                this.getDncCounties();
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

    // Delete Do Not Call Records by Id
    delDncCounties() {
        let recIds = [];
        this.selectedRows.forEach((record) => {
            recIds.push(record.Id);
        });
        if (recIds.length === 0) return;

        DelDncCounties({ countyIds: recIds })
            .then((result) => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Counties Deleted',
                        variant: 'success',
                        mode: 'dismissable'
                    })
                );
            })
            .then(() => {
                this.getDncCounties();
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
        console.log('handleColumnSorting');
        var fieldName = event.detail.fieldName;
        var sortDirection = event.detail.sortDirection;
        // Assign the latest attribute with the sorted column fieldName and sorted direction
        this.sortedBy = fieldName;
        this.sortedDirection = sortDirection;
        this.dncCounties = this.sortData(fieldName, sortDirection);
    }

    sortData(fieldname, direction) {
        console.log('sortData');
        let parseData = JSON.parse(JSON.stringify(this.dncCounties));
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
