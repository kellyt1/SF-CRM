import { LightningElement, track } from 'lwc';
import findUsers from '@salesforce/apex/UserPasswordResetController.findUsers';
import resetPassword from '@salesforce/apex/UserPasswordResetController.resetPassword';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const columns = [
    { label: 'Name', fieldName: 'Name', type: 'text' },
    { label: 'Email', fieldName: 'Email', type: 'text' },
    {
        label: 'Last Login Date',
        fieldName: 'LastLoginDate',
        type: 'date',
        typeAttributes: {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit'
        }
    }
];

export default class UserPasswordReset extends LightningElement {
    @track error;
    @track searchKey;
    users = [];
    columns = columns;
    selectedRows = [];
    userSearchResult = false;
    disableReset = true;

    handleChange(event) {
        this.searchKey = event.detail.value;
    }

    searchUsers(event) {
        findUsers({
            searchKey: this.searchKey
        })
            .then((result) => {
                this.users = result;
                this.userSearchResult = true;
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

    getSelectedId(event) {
        this.disableReset = false;
        this.selectedRows = event.detail.selectedRows;
    }

    handleReset(event) {
        let userId = this.selectedRows[0].Id;
        resetPassword({
            selectedUser: userId
        })
            .then((result) => {
                this.userSearchResult = false;
                this.disableReset = true;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Password Reset',
                        message: 'Email Sent',
                        variant: 'success',
                        mode: 'dismissable'
                    })
                );
            })
            .catch((error) => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Unable to reset user password',
                        message: error.body.message,
                        variant: 'error',
                        mode: 'sticky'
                    })
                );
            });
    }
}
