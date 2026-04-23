// Lightning Web Components: UI events, navigation, actions, and message service
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import { publish } from 'lightning/messageService';
import RefreshEventMessageChannel from '@salesforce/messageChannel/RefreshEvent__c';

// Resource Loader: Load external styles and scripts
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';

// Static Resources: External styles and chart libraries
import quickActionPopupStyle from '@salesforce/resourceUrl/Quick_Action_Popup_Style';
import ChartLibraries from '@salesforce/resourceUrl/ChartLibraries';

// Additional Components: Alerts and form factor constants
import LightningAlert from 'lightning/alert';
import FORM_FACTOR from '@salesforce/client/formFactor';

// Browser Information: Get the user agent from the navigator
const { userAgent } = navigator;

import { getLocationService } from 'lightning/mobileCapabilities';



/**
 * Dispatch a toast event on the component or handle nested error details recursively.
 *
 * @param {Object} cmp - The component used to dispatch events.
 * @param {string} title - The toast title.
 * @param {string} message - The toast message.
 * @param {string} variant - The toast variant (e.g., 'success', 'error').
 * @param {Object} error - An optional error object containing nested error details.
 */
const toastHistory = {};
export function showToast(cmp, title, message, variant, error) {
    console.log('toast', 'title', title, 'message', message, 'variant', variant, 'error', error, typeof error, JSON.stringify(error));

    if (error instanceof TypeError) {
        console.log('TypeError detected:', error);
        if (cmp) {
            showToast(cmp, 'TypeError', error.message || 'An unexpected TypeError occurred.', 'error');
        }
        else {
            alert(msg);
        }
        return;
    }

    if (error instanceof Object && JSON.stringify(error).includes('LOCATION_SERVICE_DISABLED')) {
        showToast(cmp, 'Error', 'Kindly put ON your Mobile GPS location from mobile settings', 'error');
        return;
    }

    const isGeoError = error?.code !== undefined && error?.message && typeof error.code === 'number';
    if (isGeoError) {
        const geoErrorMessages = {
            1: 'User denied Geolocation permission.',
            2: 'Location information is unavailable.',
            3: 'The request to get user location timed out.'
        };
        const geoMessage = geoErrorMessages[error.code] || error.message;
        showToast(cmp, 'Geolocation Error', geoMessage, 'error');
        return;
    }


    const output = error?.body?.output;
    const body = error?.body;

    if (output?.errors) {
        output.errors.forEach(err => {
            showToast(cmp, err.errorCode, err.message, 'error');
        });
        return;
    }

    if (output?.fieldErrors) {
        for (let i = 0; i < Object.keys(output.fieldErrors).length; i++) {
            const fieldName = Object.keys(output.fieldErrors)[i];
            const fieldErrors = output.fieldErrors[fieldName];
            fieldErrors.forEach(err => {
                showToast(cmp, fieldName, err.message, 'error');
            });
        }
        return;
    }

    if (body?.pageErrors && Array.isArray(body.pageErrors) && body.pageErrors.length > 0) {
        body.pageErrors.forEach(err => {
            showToast(cmp, err.errorCode, err.message, 'error');
        });
        return;
    }

    if (body?.fieldErrors && Object.keys(body.fieldErrors).length > 0) {
        for (let i = 0; i < Object.keys(body.fieldErrors).length; i++) {
            const fieldName = Object.keys(body.fieldErrors)[i];
            const fieldErrors = body.fieldErrors[fieldName];
            fieldErrors.forEach(err => {
                showToast(cmp, fieldName, err.message, 'error');
            });
        }
        return;
    }

    const msg = error
        ? error.body?.message ?? error.body ?? error.message ?? error
        : message;
    console.log('msg', JSON.stringify(msg));

    if (msg && (msg.toString().toLowerCase().includes('invalidsession') || msg.toString().toLowerCase().includes('invalid session') || msg.toString().toLowerCase().includes('invalid_session'))) {
        return;
    }

    if (msg && msg.toString().toLowerCase().includes('aura:systemerror')) {
        return;
    }

    if (msg && msg.toString().toLowerCase().includes('disconnected or canceled')) {
        title = '';
        variant = 'info';
    }

    const normalizedMsg = msg.toString().trim();
    const now = Date.now();
    const coolDown = 5 * 1000;
    if (toastHistory[normalizedMsg] && now - toastHistory[normalizedMsg] < coolDown) {
        console.log(`Skipping duplicate toast for: "${normalizedMsg}" within 5s`);
        return;
    }
    toastHistory[normalizedMsg] = now;

    if (cmp) {
        const toastEvent = new ShowToastEvent({ title, message: msg.toString(), variant });
        try {
            cmp.dispatchEvent(toastEvent);
        } catch (error) {
            alert(msg);
        }
    }
    else {
        alert(msg);
    }
}

/**
 * Generate an array of toast events based on the error details or default parameters.
 *
 * @param {Object} cmp - The component (unused in this function but kept for consistency).
 * @param {string} title - The default toast title.
 * @param {string} message - The default toast message.
 * @param {string} variant - The default toast variant.
 * @param {Object} error - An optional error object with nested error details.
 * @returns {Array} An array of ShowToastEvent objects.
 */
export function getShowToastEvents(cmp, title, message, variant, error) {
    console.log('toast', 'title', title, 'message', message, 'variant', variant, 'error', error, JSON.stringify(error));

    const toasts = [];

    if (error instanceof TypeError) {
        console.log('TypeError detected:', error);
        toasts.push(new ShowToastEvent({ title: 'TypeError', message: error.message || 'An unexpected TypeError occurred.', variant: 'error' }));
    }

    if (error instanceof Object && JSON.stringify(error).includes('LOCATION_SERVICE_DISABLED')) {
        toasts.push(new ShowToastEvent({ title: 'Error', message: 'Kindly put ON your Mobile GPS location from mobile settings', variant: 'error' }));
        return;
    }

    const isGeoError = error?.code !== undefined && error?.message && typeof error.code === 'number';
    if (isGeoError) {
        const geoErrorMessages = {
            1: 'User denied Geolocation permission.',
            2: 'Location information is unavailable.',
            3: 'The request to get user location timed out.'
        };
        const geoMessage = geoErrorMessages[error.code] || error?.message;
        toasts.push(new ShowToastEvent({ title: 'Geolocation Error', message: geoMessage, variant: 'error' }));
        return;
    }

    const output = error?.body?.output;
    const body = error?.body;

    if (output?.errors) {
        output.errors.forEach(err => {
            toasts.push(new ShowToastEvent({ title: err.errorCode, message: err.message, variant: 'error' }));
        });
    }

    else if (body?.pageErrors && Array.isArray(body.pageErrors) && body.pageErrors.length > 0) {
        body.pageErrors.forEach(err => {
            toasts.push(new ShowToastEvent({ title: err.statusCode, message: err.message, variant: 'error' }));
        });
    }

    else if (body?.fieldErrors) {
        for (let i = 0; i < Object.keys(body.fieldErrors).length; i++) {
            const fieldName = Object.keys(body.fieldErrors)[i];
            const fieldErrors = body.fieldErrors[fieldName];
            fieldErrors.forEach(err => {
                toasts.push(new ShowToastEvent({ title: fieldName, message: err.message, variant: 'error' }));
            });
        }
    }

    else {
        const msg = error
            ? error.body?.message ?? error.body ?? error.message ?? error
            : message;

        if (msg && (msg.toString().toLowerCase().includes('invalidsession') || msg.toString().toLowerCase().includes('invalid session') || msg.toString().toLowerCase().includes('invalid_session'))) {
            return;
        }

        if (msg && msg.toString().toLowerCase().includes('disconnected or canceled')) {
            title = '';
            variant = 'info';
        }

        const normalizedMsg = msg.toString().trim();
        const now = Date.now();
        const coolDown = 5 * 1000;
        if (toastHistory[normalizedMsg] && now - toastHistory[normalizedMsg] < coolDown) {
            console.log(`Skipping duplicate toast for: "${normalizedMsg}" within 5s`);
            return;
        }
        toastHistory[normalizedMsg] = now;

        toasts.push(new ShowToastEvent({ title, message: msg.toString(), variant }));
    }

    return toasts;
}

/**
 * Recursively removes all occurrences of a given keyword from an object or array.
 *
 * @param {Object} cmp - The component (unused in this function but kept for consistency).
 * @param {Object|Array} obj - The object or array to process.
 * @param {string} keyword - The property key to remove.
 */
export function removeAllOccurrencesOfKeywordFromObject(cmp, obj, keyword) {
    if (Array.isArray(obj)) {
        obj.forEach(item => removeAllOccurrencesOfKeywordFromObject(cmp, item, keyword));
    } else if (obj && typeof obj === 'object') {
        Object.keys(obj).forEach(key => {
            if (key === keyword) {
                delete obj[key];
            } else {
                removeAllOccurrencesOfKeywordFromObject(cmp, obj[key], keyword);
            }
        });
    }
}

/**
 * Returns a comparator function to sort an array of objects based on provided properties.
 * A property prefixed with '-' indicates descending order.
 *
 * @param {Array<string>} props - List of properties for sorting.
 * @returns {Function} Comparator function.
 */
export function arraySorterByProps(props) {
    return function (a, b) {
        return props
            .map(function (prop) {
                let dir = 1;
                if (prop[0] === '-') {
                    dir = -1;
                    prop = prop.substring(1);
                }
                if (a[prop] > b[prop]) {
                    return dir;
                }
                if (a[prop] < b[prop]) {
                    return -(dir);
                }
                return 0;
            })
            .reduce(function firstNonZeroValue(a, b) {
                return a ? a : b;
            }, 0);
    };
}

/**
 * Deep clones an object, handling cyclic references and special types.
 *
 * @param {*} obj - The object to clone.
 * @param {WeakMap} [hash=new WeakMap()] - WeakMap to handle cyclic references.
 * @returns {*} A deep cloned copy of the object.
 */
export function deepClone(obj, hash = new WeakMap()) {
    if (Object(obj) !== obj) return obj; // primitives
    if (hash.has(obj)) return hash.get(obj); // cyclic reference
    const result = obj instanceof Set ? new Set(obj) // See note about this!
        : obj instanceof Map ? new Map(Array.from(obj, ([key, val]) =>
            [key, deepClone(val, hash)]))
            : obj instanceof Date ? new Date(obj)
                : obj instanceof RegExp ? new RegExp(obj.source, obj.flags)
                    // ... add here any specific treatment for other classes ...
                    // and finally a catch-all:
                    : obj instanceof File ? new File([obj], obj.name, { type: obj.type })
                        : obj.constructor ? new obj.constructor()
                            : Object.create(null);
    hash.set(obj, result);
    return Object.assign(result, ...Object.keys(obj).map(
        key => ({ [key]: deepClone(obj[key], hash) })));
}





/**
 * Analyzes the form factor based on a global FORM_FACTOR variable and updates the component.
 * @param {Object} cmp - The component object.
 * @returns {Object} An object containing device properties.
 */
export function analyzeFormFactor(cmp) {
    const deviceTypeMap = { Small: "isMobile", Medium: "isTablet", Large: "isDesktop" };
    const deviceProperties = { isMobile: false, isTablet: false, isDesktop: false };
    const deviceType = deviceTypeMap[FORM_FACTOR];

    cmp.deviceType = FORM_FACTOR;

    if (deviceType) {
        deviceProperties[deviceType] = true;
        cmp[deviceType] = true;
    }

    return deviceProperties;
}

/**
 * Analyzes the user agent string using predefined OS patterns and updates the component.
 * @param {Object} cmp - The component object.
 * @returns {Object} An object containing boolean results for each OS pattern.
 */
export function analyzeUserAgent(cmp) {
    const osPatterns = {
        isIOS: /iPhone|iPad|iPod/,
        isAndroid: /Android/,
        isWindows: /Windows/,
        isUnix: /X11|Unix/,
        isMac: /Mac|macintosh/,
        isLinux: /Linux(?!.*Android)/,
        isBlackberry: /BlackBerry/
    };

    const result = {};

    for (const [key, pattern] of Object.entries(osPatterns)) {
        result[key] = pattern.test(userAgent);
        cmp[key] = result[key];
    }

    return result;
}




/**
 * Disables pull-to-refresh by dispatching a custom event if the device is mobile or tablet.
 * @param {Object} cmp - The component object.
 */
export function disablePullToRefresh(cmp) {
    if (!cmp.isMobile && !cmp.isTablet && !cmp.isDesktop) {
        analyzeFormFactor(cmp);
    }
    if (cmp.isMobile || cmp.isTablet) {
        cmp.dispatchEvent(
            new CustomEvent("updateScrollSettings", {
                detail: { isPullToRefreshEnabled: false },
                bubbles: true,
                composed: true
            })
        );
    }
}

/**
 * Enables pull-to-refresh by dispatching a custom event.
 * @param {Object} cmp - The component object.
 */
export function enablePullToRefresh(cmp) {
    cmp.dispatchEvent(
        new CustomEvent("updateScrollSettings", {
            detail: { isPullToRefreshEnabled: true },
            bubbles: true,
            composed: true
        })
    );
}




/**
 * Loads the quick action popup style by constructing a dimension string and dynamically loading the CSS.
 * @param {Object} cmp - The component object.
 * @param {number} width - The width of the popup.
 * @param {number} [height] - The height of the popup (optional).
 */
export function loadQuickActionPopupStyle(cmp, width, height) {
    const dimension = height ? `${width}x${height}` : `${width}`;
    unloadQuickActionPopupStyle(cmp);
    loadStyle(cmp, `${quickActionPopupStyle}/${dimension}.css`);
}

/**
 * Unloads any quick action popup styles by removing linked stylesheets that match the quick action popup style.
 * @param {Object} cmp - The component object.
 */
export function unloadQuickActionPopupStyle(cmp) {
    const links = document.querySelectorAll('link');
    console.log('links', links, 'length', links.length);
    if (links) {
        links.forEach((link) => {
            const { href } = link;
            if (href && href.toLowerCase().includes('quick_action_popup_style')) {
                console.log('removing stylesheet', href);
                link.remove();
            }
        });
    }
}

/**
 * Closes the quick action popup by dispatching the CloseActionScreenEvent.
 * @param {Object} cmp - The component object.
 */
export function closeQuickActionPopup(cmp) {
    cmp.dispatchEvent(new CloseActionScreenEvent());
}





/**
 * Shows a Lightning alert with the specified parameters.
 * @param {Object} cmp - The component object.
 * @param {string} label - The label for the alert.
 * @param {string} message - The message to display.
 * @param {string} variant - The variant style of the alert.
 * @param {string} theme - The theme for the alert.
 */
export function showLightningAlert(cmp, label, message, variant, theme) {
    LightningAlert.open({ message, variant, theme, label });
}

/**
 * Opens a Lightning modal and optionally executes a callback with the modal result.
 * @param {Object} cmp - The component object.
 * @param {Object} modalInstance - The modal instance.
 * @param {Function} [callback] - Optional callback function to execute with the result.
 * @returns {Promise<void>}
 */
export async function openLightningModal(cmp, modalInstance, options, callback) {
    const result = await modalInstance.open({ size: 'medium', ...options });
    if (callback) {
        callback(result);
    }
}





/**
 * Navigates to a record page using Salesforce's NavigationMixin.
 * @param {Object} cmp - The component object.
 * @param {string} recordId - The record ID to navigate to.
 * @param {string} objectApiName - The API name of the object.
 * @param {object} stateParams - State parameters
 */
export function navigateToRecord(cmp, recordId, objectApiName, stateParams) {
    console.log('recordId', recordId, 'objectApiName', objectApiName);
    try {
        cmp[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId,
                actionName: 'view',
                objectApiName
            },
            state: stateParams
        });
    }
    catch (error) {
        console.log('error', error);
        showToast(cmp, 'Error', error, 'error');
    }
}


/**
 * Navigates to a record page in new tab using Salesforce's NavigationMixin.
 * @param {Object} cmp - The component object.
 * @param {string} recordId - The record ID to navigate to.
 * @param {string} objectApiName - The API name of the object.
 * @param {object} stateParams - State parameters
 */
export function navigateToRecordInNewTab(cmp, recordId, objectApiName, stateParams) {
    console.log('recordId', recordId, 'objectApiName', objectApiName);
    try {
        cmp[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId,
                actionName: 'view',
                objectApiName
            },
            state: stateParams
        })
            .then((url) => {
                window.open(url, '_blank');
            })
            .catch((error) => {
                console.log('error', error);
                showToast(cmp, 'Error', error, 'error');
                showLightningAlert(cmp, 'Stay tuned', "Stay tuned. We're working on it!", 'header', 'default');
            });
    }
    catch (error) {
        console.log('error', error);
        showToast(cmp, 'Error', error, 'error');
    }
}


/**
 * Navigate to LWC without making entry in history
 * @param {object} cmp - Component context.
 * @param {string} lwcName - LWC name
 * @param {object} stateParams - State parameters
 */
export function navigateToRecordWithoutHistory(cmp, recordId, objectApiName, stateParams) {
    cmp[NavigationMixin.GenerateUrl]({
        type: 'standard__recordPage',
        attributes: {
            recordId,
            objectApiName,
            actionName: 'view'
        },
        state: stateParams
    })
        .then((url) => {
            window.location.replace(url);
        })
        .catch((error) => {
            console.log('error', error);
            showToast(cmp, 'Error', error, 'error');
            showLightningAlert(cmp, 'Stay tuned', "Stay tuned. We're working on it!", 'header', 'default');
        });
}


/**
 * Navigates to a Lightning Web Component (LWC) using Salesforce's NavigationMixin.
 * @param {Object} cmp - The component object.
 * @param {string} lwcName - The name of the Lightning Web Component.
 * @param {Object} [stateParams={}] - Optional state parameters to pass.
 */
export function navigateToLWC(cmp, lwcName, stateParams = {}) {
    console.log('lwcName:', lwcName, 'stateParams:', stateParams);

    // const encodedDef = btoa(JSON.stringify({ componentDef: `c:${lwcName}`, state: stateParams }));
    // console.log('encodedDef->', encodedDef);
    try {
        cmp[NavigationMixin.Navigate]({
            type: 'standard__component',
            attributes: {
                componentName: `c__${lwcName}`
            },
            state: stateParams
        });
        /*
            .then((url) => {
                window.location.replace(url);
            })
            .catch((error) => {
                console.error('Navigation error:', error);
                showToast(cmp, 'Error', error || 'An error occurred', 'error');
                showLightningAlert(cmp, 'Stay tuned', 'Stay tuned. We\'re working on it!', 'header', 'default');
            });
        */
    }
    catch (error) {
        console.error('Navigation error:', error);
        showToast(cmp, 'Error', error || 'An error occurred', 'error');
        showLightningAlert(cmp, 'Stay tuned', 'Stay tuned. We\'re working on it!', 'header', 'default');
    }
}

/**
 * Navigates to Lightning Web Component (LWC) using Salesforce's NavigationMixin with reload
 * @param {Object} cmp - The component object.
 * @param {string} lwcName - The name of the Lightning Web Component.
 * @param {Object} [stateParams={}] - Optional state parameters to pass.
 */
export function navigateToLWCWithReload(cmp, lwcName, stateParams = {}) {
    try {
        cmp[NavigationMixin.GenerateUrl]({
            type: 'standard__component',
            attributes: {
                componentName: `c__${lwcName}`
            },
            state: stateParams
        })
            .then((url) => {
                window.history.pushState(null, '', url);
                window.location.replace(url);
            })
            .catch((error) => {
                console.error('Navigation error:', error);
                showToast(cmp, 'Error', error || 'An error occurred', 'error');
                showLightningAlert(cmp, 'Stay tuned', 'Stay tuned. We\'re working on it!', 'header', 'default');
            });
    }
    catch (error) {
        console.error('Navigation error:', error);
        showToast(cmp, 'Error', error || 'An error occurred', 'error');
        showLightningAlert(cmp, 'Stay tuned', 'Stay tuned. We\'re working on it!', 'header', 'default');
    }
}

/**
 * Navigates to a Lightning Web Component (LWC) using Salesforce's NavigationMixin (encoded)
 * @param {Object} cmp - The component object.
 * @param {string} lwcName - The name of the Lightning Web Component.
 * @param {Object} [stateParams={}] - Optional state parameters to pass.
 */
export function navigateToLWCEncoded(cmp, lwcName, stateParams = {}) {
    const encodedDef = btoa(JSON.stringify({ componentDef: `c:${lwcName}`, state: stateParams }));
    console.log('encodedDef->', encodedDef);
    try {
        cmp[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/one/one.app#' + encodedDef
            }
        });
    }
    catch (error) {
        console.error('Navigation error:', error);
        showToast(cmp, 'Error', error || 'An error occurred', 'error');
        showLightningAlert(cmp, 'Stay tuned', 'Stay tuned. We\'re working on it!', 'header', 'default');
    }
}

/**
 * Navigates to a Lightning Web Component (LWC) using Salesforce's NavigationMixin without making an entry in the history.
 * In case of an error, logs the error and displays both a toast and a lightning alert.
 *
 * @param {Object} cmp - The component object.
 * @param {string} lwcName - The name of the Lightning Web Component.
 * @param {Object} [stateParams={}] - Optional state parameters to pass.
 */
export function navigateToLWCWithoutHistory(cmp, lwcName, stateParams = {}) {
    cmp[NavigationMixin.GenerateUrl]({
        type: 'standard__component',
        attributes: {
            componentName: `c__${lwcName}`
        },
        state: stateParams
    })
        .then((url) => {
            window.location.replace(url);
        })
        .catch((error) => {
            console.log('error', error);
            showToast(cmp, 'Error', error, 'error');
            showLightningAlert(cmp, 'Stay tuned', "Stay tuned. We're working on it!", 'header', 'default');
        });
}

/**
 * Navigates to an object's page with the specified action and state parameters.
 * @param {Object} cmp - The component instance.
 * @param {string} objectApiName - The API name of the object.
 * @param {string} actionName - The action to perform (e.g., 'new', 'list', etc.).
 * @param {Object} [stateParams={}] - Additional state parameters.
 */
export function navigateToObjectPage(cmp, objectApiName, actionName, stateParams = {}) {
    console.log('objectApiName', objectApiName, 'actionName', actionName);
    try {
        cmp[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName,
                actionName
            },
            state: stateParams
        });
    } catch (error) {
        console.log('error', error);
        showToast(cmp, 'Error', error, 'error');
        showLightningAlert(cmp, 'Stay tuned', 'Stay tuned. We\'re working on it!', 'header', 'default');
    }
}

export function navigateToRelatedList(cmp, recordId, objectApiName, relationshipApiName) {
    console.log('objectApiName', objectApiName, 'relationshipApiName', relationshipApiName, 'recordId', recordId);
    try {
        cmp[NavigationMixin.Navigate]({
            type: 'standard__recordRelationshipPage',
            attributes: {
                recordId,
                objectApiName,
                relationshipApiName,
                actionName: 'view'
            }
        });
    } catch (error) {
        console.log('error', error);
        showToast(cmp, 'Error', error, 'error');
        showLightningAlert(cmp, 'Stay tuned', 'Stay tuned. We\'re working on it!', 'header', 'default');
    }
}

/**
 * Navigate to object's page with the specified action and state parameters without making an entry in the history.
 * @param {object} cmp - Component context.
 * @param {string} objectApiName - The API name of the object.
 * @param {string} actionName - The action to perform (e.g., 'new', 'list', etc.).
 * @param {object} [stateParams={}] - Additional state parameters.
 */
export function navigateToObjectPageWithoutHistory(cmp, objectApiName, actionName, stateParams = {}) {
    cmp[NavigationMixin.GenerateUrl]({
        type: 'standard__objectPage',
        attributes: {
            objectApiName,
            actionName
        },
        state: stateParams
    })
        .then((url) => {
            console.log('url', url);
            window.location.replace(url);
        })
        .catch((error) => {
            console.log('error', error);
            showToast(cmp, 'Error', error, 'error');
            showLightningAlert(cmp, 'Stay tuned', "Stay tuned. We're working on it!", 'header', 'default');
        });
}

/**
 * Navigates to a specific tab page.
 * @param {Object} cmp - The component instance.
 * @param {string} tabName - The API name of the tab.
 */
export function navigateToTab(cmp, tabName) {
    console.log('tabName', tabName);
    try {
        cmp[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: tabName
            }
        });
    } catch (error) {
        console.log('error', error);
        showToast(cmp, 'Error', error, 'error');
        showLightningAlert(cmp, 'Stay tuned', 'Stay tuned. We\'re working on it!', 'header', 'default');
    }
}

/**
 * Navigates to the file preview page for a given record.
 * @param {Object} cmp - The component instance.
 * @param {string} recordId - The record ID of the file to preview.
 */
export function navigateToFilePreview(cmp, recordId) {
    cmp[NavigationMixin.Navigate]({
        type: 'standard__namedPage',
        attributes: {
            pageName: 'filePreview'
        },
        state: {
            selectedRecordId: recordId
        }
    });
}

/**
 * Navigates to the file preview page for a given record without history.
 * In case of an error, logs the error and displays both a toast and a lightning alert.
 *
 * @param {Object} cmp - The component instance.
 * @param {string} recordId - The record ID of the file to preview.
 */
export function navigateToFilePreviewWithoutHistory(cmp, recordId) {
    cmp[NavigationMixin.GenerateUrl]({
        type: 'standard__namedPage',
        attributes: {
            pageName: 'filePreview'
        },
        state: {
            selectedRecordId: recordId
        }
    })
        .then((url) => {
            window.location.replace(url);
        })
        .catch((error) => {
            console.log('error', error);
            showToast(cmp, 'Error', error, 'error');
            showLightningAlert(cmp, 'Stay tuned', "Stay tuned. We're working on it!", 'header', 'default');
        });
}

/**
 * Navigates to a specified URL using the component's navigation mixin.
 * In case of an error, logs the error and displays both a toast and a lightning alert.
 *
 * @param {Object} cmp - The component instance with navigation methods.
 * @param {string} url - The URL to navigate to.
 */
export function navigateToUrl(cmp, url) {
    try {
        cmp[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: { url }
        });
    } catch (error) {
        console.log('error', error);
        showToast(cmp, 'Error', error, 'error');
        showLightningAlert(cmp, 'Stay tuned', "Stay tuned. We're working on it!", 'header', 'default');
    }
}

/**
 * Navigates back in the browser history.
 * @param {object} cmp - Component context.
 */
export function navigateBackInHistory(cmp) {
    window.history.back();
}





/**
 * Publishes a refresh event through the message channel if the message context exists.
 * Otherwise, logs an error and shows a toast notification.
 *
 * @param {Object} cmp - The component instance containing the message context.
 */
export function publishRefreshEvent(cmp) {
    if (cmp.messageContext) {
        publish(cmp.messageContext, RefreshEventMessageChannel, { refresh: true });
    } else {
        console.log('No message context found.');
        showToast(cmp, 'Error', 'No message context', 'error');
    }
}





/**
 * Extracts the name and value from an event's target.
 * For a "RecordPicker" type, returns the recordId from event details as value.
 *
 * @param {Object} cmp - The component instance.
 * @param {Event} event - The event object from which to extract data.
 * @returns {Object} An object containing the name, value, and dataset.
 */
export function getNameAndValueOnChange(cmp, event) {
    const { name, fieldName, value, dataset: { type } = {} } = event.target;
    const { recordId } = event.detail || {};
    const resultName = name || fieldName;
    const resultValue = (type === 'RecordPicker') ? recordId : value;

    console.log('Field change detected:', { name: resultName, value: resultValue });
    return { name: resultName, value: resultValue, dataset: event.target.dataset };
}





/**
 * Smoothly scrolls the window to the top using the defined scroll options.
 *
 * @param {Object} cmp - The component instance (not used in this function).
 */
export function scrollToTop(cmp) {
    window.scrollTo({
        top: 0,
        left: 0,
        behavior: 'smooth'
    });
}


/**
 * Smoothly scrolls the window to the height using the defined scroll options.
 *
 * @param {Object} cmp - The component instance (not used in this function).
 * @param {number} height - The height to scroll to.
 */
export function scrollToHeight(cmp, height) {
    window.scrollTo({
        top: height,
        left: 0,
        behavior: 'smooth'
    });
}





/**
 * Initializes the calendar view for a given container.
 *
 * @param {Object} cmp - The component instance containing calendar view properties and template.
 */
export function initCalendar(cmp) {
    const parentContainer = cmp.template.querySelectorAll('.calendar-container');

    if (!parentContainer && !parentContainer.length) return;

    let lwcName;
    if (parentContainer.attributes) {
        for (let i = 0; i < parentContainer.attributes.length; i++) {
            if (parentContainer.attributes[i].name.toLowerCase().includes('lwc')) {
                lwcName = parentContainer.attributes[i].name;
                break;
            }
        }
    }

    if (!lwcName) {
        const block1 = cmp.template.querySelector('div');
        if (block1 && block1.attributes) {
            for (let i = 0; i < block1.attributes.length; i++) {
                if (block1.attributes[i].name.toLowerCase().includes('lwc')) {
                    lwcName = block1.attributes[i].name;
                    break;
                }
            }
        }
    }

    if (parentContainer && parentContainer.length) {
        parentContainer.forEach(container => {
            renderCalendarHeader(cmp, container, lwcName);
        });
    }
}


/**
 * Renders the calendar header for a given container.
 *
 * @param {Object} cmp - The component instance containing calendar view properties and template.
 * @param {HTMLElement} parentContainer - The container element to render the header in.
 */
export function renderCalendarHeader(cmp, parentContainer, lwcName) {
    const MONTHS = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];

    const createElementWithLwc = tagName => {
        const element = document.createElement(tagName);
        if (lwcName) {
            element.setAttribute(lwcName, "");
        }
        return element;
    };

    parentContainer.innerHTML = '';

    const calendarView = createElementWithLwc('div');
    calendarView.className = 'calendar-view';

    const headerContainer = createElementWithLwc('div');
    headerContainer.className = 'calendar-header-container';

    const createButton = (title, symbol, clickHandler) => {
        const button = createElementWithLwc('button');
        button.title = title;
        button.style.cssText = `
            border: none;
            border-radius: 50%;
            width: 1.5em;
            height: 1.5em;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            font-size: x-large;
            color: black;
        `;
        button.innerHTML = symbol;
        button.addEventListener('click', clickHandler);
        return button;
    };

    const prevButton = createButton('Previous Month', '&#9664;', cmp.handlePreviousMonthClick.bind(cmp));
    headerContainer.appendChild(prevButton);

    const monthLabel = createElementWithLwc('div');
    monthLabel.className = 'calendar-month-label';
    monthLabel.textContent = `${MONTHS[cmp.current_view_month].substring(0, 3)} ${cmp.current_view_year}`;
    headerContainer.appendChild(monthLabel);

    const nextButton = createButton('Next Month', '&#9654;', cmp.handleNextMonthClick.bind(cmp));
    headerContainer.appendChild(nextButton);

    calendarView.appendChild(headerContainer);

    // Weekdays header
    const weekHeader = createElementWithLwc('div');
    weekHeader.className = 'calendar-week-header';

    ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].forEach(day => {
        const dayElement = createElementWithLwc('div');
        dayElement.className = 'ellipsis';
        dayElement.innerHTML = `<span>${day}</span>`;
        weekHeader.appendChild(dayElement);
    });

    calendarView.appendChild(weekHeader);

    // Days container
    const daysView = createElementWithLwc('div');
    daysView.className = 'calendar-days-view';

    const daysContainer = createElementWithLwc('div');
    daysContainer.className = 'calendar-days-container drop-target-parent';
    daysView.appendChild(daysContainer);

    calendarView.appendChild(daysView);
    parentContainer.appendChild(calendarView);

    renderCalendarDays(cmp, lwcName);
}


/**
 * Renders the calendar days for the current month.
 *
 * @param {Object} cmp - The component instance containing calendar view properties and template.
 */
export function renderCalendarDays(cmp, lwcName) {
    const daysContainer = cmp.template.querySelector(".calendar-days-container");
    if (!daysContainer) return;

    const MONTHS = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];

    daysContainer.innerHTML = '';

    const calendarMonthLabelElement = cmp.template.querySelector(".calendar-month-label");
    if (calendarMonthLabelElement) {
        calendarMonthLabelElement.textContent = `${MONTHS[cmp.current_view_month].substring(0, 3)} ${cmp.current_view_year}`;
    }

    const firstDay = new Date(cmp.current_view_year, cmp.current_view_month, 1);
    const lastDay = new Date(cmp.current_view_year, cmp.current_view_month + 1, 0);
    const prevLastDay = new Date(cmp.current_view_year, cmp.current_view_month, 0);
    const prevDays = prevLastDay.getDate();
    const lastDate = lastDay.getDate();

    const adjustedDay = firstDay.getDay() || 7; // Correct Sunday to 7
    const prevDaysToAdd = adjustedDay - 1; // Number of days from previous month to add
    // When lastDay is Sunday, getDay() returns 0 so nextDays becomes 7
    const nextDays = 7 - lastDay.getDay();
    // Adjust firstWeekDay so that Monday is index 0
    const firstWeekDay = (firstDay.getDay() === 0 ? 7 : firstDay.getDay()) - 1;

    /**
     * Checks if the provided day is today.
     * @param {number} day - Day to check.
     * @returns {boolean} True if day is today.
     */
    const isToday = day => {
        const today = new Date();
        return (
            day === today.getDate() &&
            cmp.current_view_year === today.getFullYear() &&
            cmp.current_view_month === today.getMonth()
        );
    };

    /**
     * Attaches event listeners to a day element.
     * @param {HTMLElement} dayElement - The day element to attach events to.
     */
    const addEventListeners = dayElement => {
        dayElement.addEventListener("click", event => {
            console.log("handleCalendarDayClick", JSON.stringify(event.currentTarget.dataset));
            const calendarContainer = event.currentTarget.dataset.calendarContainer;
            cmp.current_view_day = parseInt(calendarContainer);

            cmp.template.querySelectorAll('.calendar-day-selected')
                .forEach(day => day.classList.remove('calendar-day-selected'));

            const newCalendarDayDateToBeSelected = cmp.template.querySelector(
                `[data-calendar-date="${calendarContainer}"]`
            );
            if (newCalendarDayDateToBeSelected) {
                newCalendarDayDateToBeSelected.classList.add('calendar-day-selected');
            }
        });
        dayElement.addEventListener("click", cmp.handleCalendarDayClick.bind(cmp));
    };

    /**
     * Creates an element with the lwc attribute if available.
     * @param {string} tagName - The tag name for the element.
     * @returns {HTMLElement} New element.
     */
    const createElementWithLwc = tagName => {
        const element = document.createElement(tagName);
        if (lwcName) {
            element.setAttribute(lwcName, "");
        }
        return element;
    };

    /**
     * Creates a day element for the calendar.
     * @param {number} day - The day number.
     * @param {string} additionalClass - Additional CSS classes.
     * @param {boolean} isCurrentMonth - Flag indicating if day belongs to current month.
     * @returns {HTMLElement} The day element.
     */
    const createDayElement = (day, additionalClass, isCurrentMonth = false) => {
        const dayElement = createElementWithLwc("div");
        dayElement.className = `calendar-day-container ${additionalClass}`;

        const spanElement = createElementWithLwc("span");
        spanElement.className = "calendar-day-date";
        if (isCurrentMonth) {
            spanElement.setAttribute("data-calendar-date", day);
        }
        spanElement.textContent = day;
        dayElement.appendChild(spanElement);

        if (isCurrentMonth) {
            dayElement.classList.add("calendar-active-date");
            dayElement.setAttribute("data-calendar-container", day);

            const eventCountElement = createElementWithLwc("span");
            eventCountElement.className = "calendar-day-event-count";
            eventCountElement.setAttribute("data-calendar-date", day);
            eventCountElement.textContent = '';
            dayElement.appendChild(eventCountElement);

            if (isToday(day)) {
                spanElement.classList.add("calendar-day-today");
            }
            addEventListeners(dayElement);
        }
        return dayElement;
    };

    /**
     * Renders day elements within a given range.
     * @param {number} start - Start day number.
     * @param {number} end - End day number.
     * @param {string} additionalClass - Additional CSS classes.
     * @param {boolean} [isCurrentMonth=false] - Flag indicating if days belong to current month.
     */
    const renderDays = (start, end, additionalClass, isCurrentMonth = false) => {
        for (let day = start; day <= end; day++) {
            daysContainer.appendChild(createDayElement(day, additionalClass, isCurrentMonth));
        }
    };

    // Render previous month dates, current month dates, and next month dates
    renderDays(prevDays - firstWeekDay + 1, prevDays, 'calendar-prev-month-date calendar-disabled-date');
    renderDays(1, lastDate, 'calendar-active-date', true);
    renderDays(1, nextDays, 'calendar-next-month-date calendar-disabled-date');

    const calendarDayEventCountElements = cmp.template.querySelectorAll('.calendar-day-event-count');
    if (calendarDayEventCountElements && calendarDayEventCountElements.length > 0) {
        calendarDayEventCountElements.forEach(element => {
            const day = element.dataset.calendarDate;
            if (cmp.serviceAppointmentsList) {
                if (cmp.serviceAppointmentsList[day]) {
                    element.textContent = cmp.serviceAppointmentsList[day].length;
                }
                else {
                    element.textContent = '';
                }
            }
            else {
                element.textContent = '';
            }
        });
    }
}














/**
 * Dynamically loads the provided script URLs using loadScript.
 * @param {object} cmp - Component context for loadScript.
 * @param {string[]} scripts - Array of script URLs to load.
 * @returns {Promise<void>}
 */
async function loadScripts(cmp, scripts) {
    await Promise.all(scripts.map(url => loadScript(cmp, url)));
}

/**
 * Loads a chart library if it isn't already available.
 * @param {object} cmp - Component context for loadScript.
 * @param {string} libraryName - The property name on window to check (e.g., 'Chart' or 'ApexCharts').
 * @param {string[]} scriptUrls - Array of script URLs required for the library.
 * @param {string} successMessage - Message to log on successful loading.
 * @param {string} errorPrefix - Message prefix for logging errors.
 * @returns {Promise<boolean>} Resolves to true if the library loads successfully, false otherwise.
 */
async function loadLibrary(cmp, libraryName, scriptUrls, successMessage, errorPrefix) {
    if (cmp[libraryName + '_loaded']) {
        return true;
    }
    try {
        await loadScripts(cmp, scriptUrls);
        cmp[libraryName + '_loaded'] = true;
        console.log(successMessage);
        return true;
    } catch (error) {
        console.error(errorPrefix, error);
        return false;
    }
}

/**
 * Loads Chart.js library if it isn't already loaded.
 * @param {object} cmp - Component context for loadScript.
 * @returns {Promise<boolean>} Resolves to true if Chart.js loads successfully, false otherwise.
 */
async function loadChartJs(cmp) {
    return loadLibrary(cmp, 'ChartJs', [`${ChartLibraries}/chartjs_v447.js`, `${ChartLibraries}/ResizeObserver.min.js`], 'Chart.js loaded successfully', 'Error loading Chart.js:');
}

/**
 * Loads ApexCharts library if it isn't already loaded.
 * @param {object} cmp - Component context for loadScript.
 * @returns {Promise<boolean>} Resolves to true if ApexCharts loads successfully, false otherwise.
 */
async function loadApexChart(cmp) {
    return loadLibrary(cmp, 'ApexCharts', [`${ChartLibraries}/apexcharts_v430.js`, `${ChartLibraries}/ResizeObserver.min.js`], 'ApexCharts loaded successfully', 'Error loading ApexCharts:');
}



/**
 * Renders a Chart.js chart on the provided canvas element.
 * @param {object} cmp - Component context for loadScript.
 * @param {object} chartInstance - The existing chart instance to be destroyed before re-rendering (if applicable).
 * @param {HTMLCanvasElement} canvasElement - The canvas element where the chart will be drawn.
 * @param {object} config - Chart configuration object.
 * @returns {Promise<Chart|ApexCharts|undefined>} Resolves to a chart instance if rendering is successful.
 */
export async function renderChartJs(cmp, chartInstance, canvasElement, config) {
    if (!await loadChartJs(cmp)) {
        return;
    }
    if (!canvasElement) {
        return;
    }
    const ctx = canvasElement.getContext('2d');
    if (chartInstance && chartInstance.destroy && typeof chartInstance.destroy === 'function') {
        chartInstance.destroy();
    }
    chartInstance = new window.Chart(ctx, config);
    return chartInstance;
}

/**
 * Renders an ApexCharts chart on the provided element.
 * @param {object} cmp - Component context for loadScript.
 * @param {object} chartInstance - The existing chart instance to be replaced (if applicable).
 * @param {HTMLElement} chartContainer - The chart element where the chart will be rendered.
 * @param {object} config - Chart configuration object.
 * @returns {Promise<ApexCharts|undefined>} Resolves to an ApexCharts instance if rendering is successful.
 */
export async function renderApexChart(cmp, chartInstance, chartContainer, config) {
    if (!await loadApexChart(cmp)) {
        return;
    }
    if (!chartContainer) {
        return;
    }
    if (chartInstance && chartInstance.destroy && typeof chartInstance.destroy === 'function') {
        chartInstance.destroy();
    }
    chartInstance = new window.ApexCharts(chartContainer, config);
    await chartInstance.render();
    return chartInstance;
}







/**
 * Retrieves the current location of the user. On success, returns an object containing the latitude and longitude of the user's location. If device type is desktop then location is not mandatory, returns null location
 * @param {object} cmp - Component context for loadScript.
 * @returns {Promise<{ latitude: number, longitude: number }>} Resolves to an object containing the latitude and longitude of the user's location.
 * @throws {Error} Throws an error if the user's location cannot be determined.
 */
export async function handleGetGeoLocation(cmp) {
    const isDesktop = cmp.isDesktop;

    const handleError = (error) => {
        if (!isDesktop) {
            showToast(cmp, 'Error', 'Something went wrong', 'error', error);
        }
    };

    const myLocationService = getLocationService();

    const getCoords = () => {
        return new Promise((resolve, reject) => {
            if (myLocationService.isAvailable()) {
                myLocationService.getCurrentPosition({ enableHighAccuracy: true })
                    .then(result => resolve(result.coords))
                    .catch(error => {
                        // handleError(error);
                        reject(error);
                    });
            }
            else if (navigator.geolocation) {
                navigator.geolocation.getCurrentPosition(
                    position => resolve(position.coords),
                    error => {
                        // handleError(error);
                        reject(error);
                    },
                    { enableHighAccuracy: true }
                );
            }
            else {
                reject(new Error('Geolocation is not supported by this browser/device.'));
            }
        });
    };

    try {
        return await getCoords();
    }
    catch (error) {
        if (isDesktop) {
            console.log('Location unavailable, returning blank location for desktop:', error);
            return { latitude: null, longitude: null };
        } else {
            // handleError(error);
            throw error;
        }
    }
}