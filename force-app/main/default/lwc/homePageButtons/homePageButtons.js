import { LightningElement, api } from 'lwc';

// Importing the Navigation Mixin for Salesforce to better handle URL hard coding
import { NavigationMixin } from 'lightning/navigation';

// Importing Custom Labels to replace hard coded text
import TrainingResourcesLabel from '@salesforce/label/c.TrainingResources';
import SlackAnnouncementsLabel from '@salesforce/label/c.SlackAnnouncements';

export default class HomePageButtons extends NavigationMixin(LightningElement) {
    @api label;

    // Setting the label values for use in the HTML file of the LWC
    label = {
        TrainingResourcesLabel,
        SlackAnnouncementsLabel
    };

    navigateToTrainingResourcesHomePage() {
        // Navigate to the Training Resources Home Page URL
        this[NavigationMixin.Navigate](
            {
                type: 'standard__webPage',
                attributes: {
                    url:
                        'https://mn365.sharepoint.com/sites/MDH/response/coronaex/SitePages/caseinvestigation.aspx'
                }
            },
            false // Set to False so that the current page is not reset with the clicked URL on the button
        );
    }

    navigateToSlackAnnouncementsPage() {
        // Navigate to the Slack Announcements page URL
        this[NavigationMixin.Navigate](
            {
                type: 'standard__webPage',
                attributes: {
                    url: 'https://app.slack.com/client/T015RRC6B51/C01730F3R96'
                }
            },
            false
        );
    }
}
