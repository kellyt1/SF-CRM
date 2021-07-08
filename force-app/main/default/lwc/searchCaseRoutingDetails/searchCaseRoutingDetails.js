import { LightningElement, track } from 'lwc';

// importing apex class methods
import getCaseRoutingDetails from '@salesforce/apex/DetermineCaseRoutingDetailsAndPriority.getCaseDetails';

//import toast even
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class SearchCaseRoutingDetails extends LightningElement {
    @track error;
    caseSearchTerm;
    currentCases = [];
    assignment = [];
    medssId;
    mnId;
    sfCaseNumber;
    owner;
    county;
    interviewJurisdiction;
    subRegionCode;
    routingType;
    status;
    callAttempt;
    callAttemptDate;
    pushedToAgent;
    agedToRegionalQueue;
    skills;
    caseOnDoNotCallList = false;
    caseOnCountiesWithoutCI = false;
    caseSearchResult = false;
    skillBasedRouting = false;

    // Get input for case num, MN ID, or MEDSS Event ID that user is searching by
    handleInput(event) {
        if (event.target.name == 'caseInput') {
            this.caseSearchTerm = event.target.value;
        }
    }

    // Details of the Case Routing Priority & Configuration
    searchCases() {
        if (!this.caseSearchTerm) {
            return;
        }
        getCaseRoutingDetails({
            searchTerm: this.caseSearchTerm
        })
            .then((result) => {
                result = JSON.parse(result);
                console.log('***Result: ' + JSON.stringify(result));
                this.currentCases = result;
                this.caseSearchResult = true;
                this.assignment = [];
                //loop through each record returned and populate key attributes which are displayed to end user
                result.forEach((record) => {
                    console.log('***Record: ' + JSON.stringify(record));
                    let assign = {};
                    assign.medssId = record.MEDSSEventId;
                    assign.mnId = record.MNId;
                    assign.sfCaseNumber = record.salesforceCaseNumber;
                    assign.county = record.CountyName;
                    this.caseOnDoNotCallList = record.DoNotCallList;
                    this.caseOnCountiesWithoutCI = record.CountyWithoutCIList;
                    assign.interviewJurisdiction = record.InterviewJurisdictionCode;
                    assign.subRegionCode = record.SubRegionJurisdictionCode;
                    assign.owner = record.Owner;
                    assign.status = record.CaseStatus;
                    assign.callAttempt = record.CallAttempted;
                    assign.callAttemptDate = record.CallAttDate;
                    assign.pushedToAgent = record.RoutingStatus;
                    assign.agedToRegionalQueue = record.AgedToRegionalQueue;
                    assign.routingType = record.RoutingType;
                    if(assign.routingType == null){
                        assign.routingType = 'Not Applicable';
                    }
                    console.log('***Skill Details: ' + record.SkillNames);
                    assign.skills = record.SkillNames;
                    this.assignment = [...this.assignment, assign];
                });
            })
            // throw an error if Apex controller returns an error
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