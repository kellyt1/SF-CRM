import { LightningElement, wire, api } from "lwc";
import { getRecord } from "lightning/uiRecordApi";
import { updateRecord } from "lightning/uiRecordApi";
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import complete_Interview_Help_Text from "@salesforce/label/c.Complete_Interview_Help_Text";
import call_attmpt_dt_Help_Text from "@salesforce/label/c.Call_Attempted_Date_Set";
import medss_RedirectURL from "@salesforce/label/c.Medss_RedirectURL"; // used in prod for url
import medss_UnloadCaseURL from "@salesforce/label/c.Medss_UnloadCaseURL"; // used in prod for url
import USER_ID from "@salesforce/user/Id";
import { publish, MessageContext } from "lightning/messageService";
import Medss from "@salesforce/messageChannel/Medss__c";

const FIELDS = [
  "Case.Status",
  "Case.MEDSS_Case_Key__c",
  "Case.MEDSS_Event_ID__c",
];

export default class medssMyWork extends NavigationMixin(LightningElement) {
  @api recordId;
  userId = USER_ID;
  disableCompleteInterview = true;
  disableOpen = false;
  windowObjectReference;
  windowFeatures =
    "menubar=yes,location=yes,resizable=yes,scrollbars=yes,status=yes";

  @wire(getRecord, { recordId: "$recordId", userId: USER_ID, fields: FIELDS })
  case;

  @wire(MessageContext)
  messageContext;

  // Call unload case and close tabs
  closeTab() {
    if (this.windowObjectReference != undefined) {
      let unloadCase = window.open(
        medss_UnloadCaseURL,
        "medss",
        this.windowFeatures
      );
      let msgContext = this.messageContext;
      let winObjRef = this.windowObjectReference;

      // Prevent closing tabs before code is complete
      setTimeout(function () {
        unloadCase.close();
      }, 100);

      // Prevent closing tabs before code is complete
      setTimeout(function () {
        publish(msgContext, Medss, {
          closeTabInSalesforce: true,
        });
        winObjRef.close();
      }, 200);
    }
  }

  // Navigation to web page on Start Interview
  startInterview() {
    this.disableCompleteInterview = false;
    this.disableOpen = true;
    this.closeTab();

    // prettier-ignore
    var url = medss_RedirectURL + this.case.data.fields.MEDSS_Case_Key__c.value;
    // var url = 'https://medssdemo.web.health.state.mn.us/medssdemo/main.do?CaseKey=' + this.case.data.fields.MEDSS_Case_Key__c.value;

    this.windowObjectReference = window.open(url, "medss", this.windowFeatures);
  }

  // Complete Interview - Close the case
  completeInterview() {
    updateRecord({ fields: { Id: this.recordId, Status: "Closed" } })
      .then(() => {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Success",
            message: complete_Interview_Help_Text,
            variant: "success",
            mode: "dismissable",
          })
        );
        this.disableCompleteInterview = true;
      })
      .catch((error) => {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Error",
            message: error.body.message,
            variant: "error",
            mode: "sticky",
          })
        );
      });
    this.closeTab();
  }

  // Call Attempted - Change status to Follow-up
  callAttempted() {
    updateRecord({
      fields: {
        Id: this.recordId,
        Status: "Follow-up",
        Requeue_Reason__c: "Call Attempted",
        Call_Attempt_Date__c: new Date().toISOString(),
      },
    })
      .then(() => {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Success",
            message: call_attmpt_dt_Help_Text,
            variant: "success",
            mode: "dismissable",
          })
        );
        this.disableCompleteInterview = true;
      })
      .catch((error) => {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Error",
            message: error.body.message,
            variant: "error",
            mode: "sticky",
          })
        );
      });
    this.closeTab();
  }
}
