import { LightningElement, wire, track } from 'lwc';

// Importing the Apex method which queries for a given user
import findUsers from '@salesforce/apex/UserPasswordResetController.findUsers';

// Importing the Apex method which pulls in all Queues that the logged in User belongs to
import getUsersGroups from '@salesforce/apex/SelectedUserDetails.getUsersGroups';

// Importing the Apex method which pulls in all Skills or Jurisdicitions that the logged in User is assigned
import getUsersResourceSkills from '@salesforce/apex/SelectedUserDetails.getUsersResourceSkills';

// Importing Custom Labels to replace hard coded text
import CurrentCallBackInformationLabel from '@salesforce/label/c.CurrentCallBackInformation';
import LoggedInAsLabel from '@salesforce/label/c.LoggedInAs';
import CurrentRegionLabel from '@salesforce/label/c.CurrentRegion';
import CurrentJurisdictionLabel from '@salesforce/label/c.CurrentJurisdiction';
import CallBackNumbersLabel from '@salesforce/label/c.CallBackNumbers';
import CaseInvestigatorCallbackNumberLabel from '@salesforce/label/c.Case_Investigation_Call_Back_Number_Label';
import PhoneNumberforCaseInvestigatorCallBackLabel from '@salesforce/label/c.Phone_Number_for_Case_Investigator_Call_Back_Label';

const columns = [
    { label: 'Name', fieldName: 'Name', type: 'text' },
    { label: 'Email', fieldName: 'Email', type: 'text' },
    { label: 'User ID', fieldName: 'Id', type: 'text' },
];

export default class userDetails extends LightningElement {
    // Setting the label values for use in the HTML file of the LWC
    label = {
        CurrentCallBackInformationLabel,
        LoggedInAsLabel,
        CurrentRegionLabel,
        CurrentJurisdictionLabel,
        CallBackNumbersLabel,
        CaseInvestigatorCallbackNumberLabel,
        PhoneNumberforCaseInvestigatorCallBackLabel
    };
    @track error;
    @track name;
    @track userSearchString;
    objectName = 'User';
    users = [];
    columns = columns;
    selectedRows = [];
    currentRegions = [];
    disableUserSearch = true;
    queueName;
    assignment;
    currentSkills = [];
    skillName;
    skillAssignment;
    disableUserSearch = false;
    disableSkillSearch = false;
    userSearchResult = false;
    userSelected = false;
    selectedUser;
    userName;

    handleInput(event){
        if( event.target.name == 'userInput' ){
            this.userSearchString = event.target.value;
        }
    }

    searchUsers(event) {
        findUsers({
            searchKey: this.userSearchString,
            objectName: this.objectName
        })
            .then((result) => {
                this.users = result;
                this.userSearchResult = true;
                this.disableUserSearch = true;
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
        //this.selectedRows = event.detail.selectedRows;
        const selectedRows = event.detail.selectedRows;
        //toggle the user search button only when 1 user is selected
        if(selectedRows.length == 1){
            this.disableUserSearch = false;
        } else if(selectedRows.length != 1){
            this.disableUserSearch = true;
        }
        for (let i = 0; i < selectedRows.length; i++){
            this.selectedUser = selectedRows[i].Id;
            this.userName = selectedRows[i].Name;
        }
    }

    getSkillsAndGroups(event) {
        getUsersGroups({
            userId: this.selectedUser
        })
            .then((result) => {
                this.currentRegions = result;
                this.userSelected = true;
                result.forEach((record) => {
                    let assignment = {};
                    assignment.queueName = record.Group.Name;
                    this.currentRegions = [...this.currentRegions, assignment];
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
            this.getSkills();
    }

    getSkills(){
        getUsersResourceSkills({
            userId: this.selectedUser
        })
            .then((result) => {
                this.currentSkills = result;
                result.forEach((record) => {
                    let skillAssignment = {};
                    skillAssignment.skillName = record.Skill.MasterLabel;
                    this.currentSkills = [...this.currentSkills, skillAssignment];
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

    newSearch(event) {
        this.userSearchResult = false;
        this.userSelected = false;
    }

}