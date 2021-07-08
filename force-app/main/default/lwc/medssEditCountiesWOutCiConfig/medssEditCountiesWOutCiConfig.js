import { LightningElement } from 'lwc';
import GetCountiesWOutCI from '@salesforce/apex/MEDSS_EditConfigController.getCountiesWOutCI';
import AddCountiesWOutCI from '@salesforce/apex/MEDSS_EditConfigController.addCountiesWOutCI';
import DeleteCountiesWOutCI from '@salesforce/apex/MEDSS_EditConfigController.deleteCountiesWOutCI';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const columns = [
    {
        label: 'County',
        fieldName: 'County_Name__c',
        type: 'text',
        sortable: true
    }
];

export default class MedssEditCountiesWOutCiConfig extends LightningElement {
    columns = columns;
    countiesWOutCI = [];
    county;
    showModal = false;
    disableSave = true;
    sortedBy = 'county';
    sortedDirection = 'asc';

    connectedCallback() {
        this.getCountiesWOutCI();
    }

    // Get Counties with out CI
    getCountiesWOutCI() {
        GetCountiesWOutCI()
            .then((result) => {
                this.countiesWOutCI = [];

                result.forEach((record) => {
                    let county = {};
                    county.Id = record.Id;
                    county.Name = record.Name;
                    county.County_Name__c = record.County_Name__c;
                    this.countiesWOutCI = [...this.countiesWOutCI, county];
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
        this.deleteCountiesWOutCI();
    }

    handleCancel() {
        this.showModal = false;
    }

    handleSave() {
        this.addCountiesWOutCI();
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

    // Add County with out CI
    addCountiesWOutCI() {
        AddCountiesWOutCI({ county: this.county })
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
                this.getCountiesWOutCI();
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

    // Delete Counties with out CI
    deleteCountiesWOutCI() {
        let recIds = [];
        this.selectedRows.forEach((record) => {
            recIds.push(record.Id);
        });
        if (recIds.length === 0) return;

        DeleteCountiesWOutCI({ countyIds: recIds })
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
                this.getCountiesWOutCI();
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
        this.countiesWOutCI = this.sortData(fieldName, sortDirection);
    }

    sortData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.countiesWOutCI));
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
