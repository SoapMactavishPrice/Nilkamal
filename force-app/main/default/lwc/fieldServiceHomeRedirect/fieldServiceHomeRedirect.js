import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

import { navigateToLWC, navigateToTab } from 'c/utilJS';
import { analyzeFormFactor, analyzeUserAgent } from 'c/utilJS';
import { disablePullToRefresh } from 'c/utilJS';




export default class FieldServiceHomeRedirect extends NavigationMixin(LightningElement) {

    @track intervalInstance;


    connectedCallback() {
        analyzeUserAgent(this);

        navigateToLWC(this, 'fieldServiceHome');

        this.handleNavigation();

        document.addEventListener('visibilitychange', () => {
            if (document.visibilityState === 'visible') {
                this.handleNavigation();
            }
            else if (document.visibilityState !== 'visible') {
                clearInterval(this.intervalInstance);
            }
        });
        disablePullToRefresh(this);

    }

    renderedCallback() {
        analyzeFormFactor(this);
    }

    disconnectedCallback() {
        document.removeEventListener('visibilitychange', () => { });
    }


    handleNavigation() {
        if (this.intervalInstance) {
            clearInterval(this.intervalInstance);
            this.intervalInstance = null;
        }
        this.intervalInstance = setInterval(() => {
            const url = window.location.href;
            const containsFieldService = url.includes('Field_Service_Home_Mobile');
            // console.log('window.location.href', url, 'contains Field_Service_Home_Mobile:', containsFieldService);

            if (containsFieldService) {
                if (this.isMobile) {
                    navigateToLWC(this, 'fieldServiceHome');
                }
                else if (this.isTablet || this.isDesktop) {
                    navigateToTab(this, 'Field_Service_Home');
                }
            }
        }, 1000);
    }


}