/**
 * Author             : jon.ferneau@slalom.com
 * Last Modified By   : Jon Ferneau
 * Last Modified On   : 01/27/2021
 **/

import { LightningElement, wire, track } from 'lwc';

// Importing the Apex method which pulls in the Region Skill that the logged in User is assigned
//import getUserRegion from '@salesforce/apex/UserDetail.getUserRegion';

// Importing the Apex method which pulls in all Queues that the logged in User belongs to
import getUsersGroups from '@salesforce/apex/UserDetail.getUsersGroups';

// Importing the Apex method which pulls in all Skills or Jurisdicitions that the logged in User is assigned
import getUsersResourceSkills from '@salesforce/apex/UserDetail.getUsersResourceSkills';

// Importing the Apex method which pulls in Custom Metadata to link Queues with their County callback numbers
import getCallbackNumbers from '@salesforce/apex/UserDetail.getCallbackNumbers';

// Importing Custom Labels to replace hard coded text
import CurrentCallBackInformationLabel from '@salesforce/label/c.CurrentCallBackInformation';
import LoggedInAsLabel from '@salesforce/label/c.LoggedInAs';
import CurrentRegionLabel from '@salesforce/label/c.CurrentRegion';
import CurrentJurisdictionLabel from '@salesforce/label/c.CurrentJurisdiction';
import CallBackNumbersLabel from '@salesforce/label/c.CallBackNumbers';
import CaseInvestigatorCallbackNumberLabel from '@salesforce/label/c.Case_Investigation_Call_Back_Number_Label';
import PhoneNumberforCaseInvestigatorCallBackLabel from '@salesforce/label/c.Phone_Number_for_Case_Investigator_Call_Back_Label';

// This is how you will retreive the USER ID of current logged in user.
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import NAME_FIELD from '@salesforce/schema/User.Name';

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

    // Using wire service to get the Region Skill based on UserId from Apex method
    //@wire(getUserRegion)
    //currentRegions;

    // Using wire service to get the Queue based on UserId from Apex method
    @wire(getUsersGroups)
    currentRegions;

    // Using wire service to get the Skills or Jurisdictions based on UserId from Apex method
    @wire(getUsersResourceSkills)
    currentJurisdictions;

    // Using wire service to get the Callback Numbers based on assigned Region Skill of the logged in UserId
    @wire(getCallbackNumbers)
    callbackNumbers;

    // Using wire service getting current user data
    @wire(getRecord, {
        recordId: USER_ID,
        fields: [NAME_FIELD]
    })
    wireuser({ error, data }) {
        if (error) {
            this.error = error;
        } else if (data) {
            this.name = data.fields.Name.value;
        }
    }
}
