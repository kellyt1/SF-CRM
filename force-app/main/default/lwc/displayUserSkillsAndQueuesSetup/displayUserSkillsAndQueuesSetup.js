import { LightningElement, wire, api, track } from 'lwc';
import {
    FlowAttributeChangeEvent,
    FlowNavigationNextEvent
} from 'lightning/flowSupport';

// Importing the Apex method which pulls in all users belonging to a spcific Queue
import getUserGroupAssignments from '@salesforce/apex/DisplayUserSkillsAndQueuesSetup.getUsersGroups';
// Importing the Apex method which pulls in all users belonging to a specific Skill
import getUserSkillAssignments from '@salesforce/apex/DisplayUserSkillsAndQueuesSetup.getUsersSkills';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const queueColumns = [
    { label: 'User', fieldName: 'userName', type: 'text', sortable: 'true' },
    { label: 'Email', fieldName: 'email', type: 'text', sortable: 'true' },
    {
        label: 'Active',
        fieldName: 'active',
        type: 'checkbox',
        sortable: 'true'
    },
    { label: 'Role', fieldName: 'role', type: 'text', sortable: 'true' },
    {
        label: 'Last Modified Date',
        fieldName: 'userLastModified',
        type: 'datetime',
        sortable: 'true'
    },
    {
        label: 'Last Login Date',
        fieldName: 'userLastLogin',
        type: 'datetime',
        sortable: 'true'
    }
];

export default class DisplayUserSkillsAndQueuesSetup extends LightningElement {
    queueColumns = queueColumns;
    currentRegions = [];
    currentSkills = [];
    assignment;
    userName;
    email;
    userLastLogin;
    selectedRows = [];
    showQueues = false;
    showSkills = false;

    @track sortBy;
    @track sortDirection;

    @api
    availableActions = [];

    @api
    queueId;

    @api
    skillId;

    connectedCallback() {
        this.getUsersGroups();
    }

    getUsersGroups() {
        console.log('*** Queue ID to pass into Apex: ' + this.queueId);
        console.log('*** Skill ID to pass into Apex: ' + this.skillId);
        if (this.queueId) {
            this.showQueues = true;
            getUserGroupAssignments({
                queueId: this.queueId
            })
                .then((result) => {
                    this.currentRegions = [];
                    result.forEach((record) => {
                        let assignment = {};
                        assignment.userName = record.Name;
                        assignment.email = record.Email;
                        assignment.active = record.isActive;
                        assignment.role = record.UserRole.Name;
                        assignment.userLastModified = record.LastModifiedDate;
                        assignment.userLastLogin = record.LastLoginDate;
                        this.currentRegions = [
                            ...this.currentRegions,
                            assignment
                        ];
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
        } else if (this.skillId) {
            this.showSkills = true;
            getUserSkillAssignments({
                skillId: this.skillId
            })
                .then((result) => {
                    this.currentSkills = [];
                    result.forEach((record) => {
                        let assignment = {};
                        assignment.userName = record.Name;
                        assignment.email = record.Email;
                        assignment.active = record.isActive;
                        assignment.role = record.UserRole.Name;
                        assignment.userLastModified = record.LastModifiedDate;
                        assignment.userLastLogin = record.LastLoginDate;
                        this.currentSkills = [
                            ...this.currentSkills,
                            assignment
                        ];
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
    }

    handleSortQueuedata(event) {
        // field name
        this.sortBy = event.detail.fieldName;

        // sort direction
        this.sortDirection = event.detail.sortDirection;

        // calling sortdata function to sort the data based on direction and selected field
        this.sortQueueData(event.detail.fieldName, event.detail.sortDirection);
    }

    sortQueueData(fieldname, direction) {
        // serialize the data before calling sort function
        let parseData = JSON.parse(JSON.stringify(this.currentRegions));

        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
        };

        // cheking reverse direction
        let isReverse = direction === 'asc' ? 1 : -1;

        // sorting data
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';

            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });

        // set the sorted data to data table data
        this.currentRegions = parseData;
    }

    handleSortSkilldata(event) {
        // field name
        this.sortBy = event.detail.fieldName;

        // sort direction
        this.sortDirection = event.detail.sortDirection;

        // calling sortdata function to sort the data based on direction and selected field
        this.sortSkillData(event.detail.fieldName, event.detail.sortDirection);
    }

    sortSkillData(fieldname, direction) {
        // serialize the data before calling sort function
        let parseData = JSON.parse(JSON.stringify(this.currentSkills));

        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
        };

        // cheking reverse direction
        let isReverse = direction === 'asc' ? 1 : -1;

        // sorting data
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';

            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });

        // set the sorted data to data table data
        this.currentSkills = parseData;
    }
}
