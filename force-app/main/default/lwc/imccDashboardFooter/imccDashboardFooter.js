import { LightningElement, track, wire } from 'lwc';

import POLICY_TEXT from '@salesforce/label/c.Privacy_Policy_Text';
import POLICY_LINK from '@salesforce/label/c.Privacy_Policy_Link';

import IMCC_Facebook from '@salesforce/label/c.IMCC_Facebook';
import IMCC_Youtube from '@salesforce/label/c.IMCC_Youtube';
import IMCC_Linkin from '@salesforce/label/c.IMCC_Linkin';
import IMCC_Twitter from '@salesforce/label/c.IMCC_Twitter';
import IMCC_Instagram from '@salesforce/label/c.IMCC_Instagram';

export default class ImccDashboardFooter extends LightningElement {    
    Facebook = IMCC_Facebook;
    Youtube = IMCC_Youtube;
    Linkin = IMCC_Linkin;
    Twitter = IMCC_Twitter;
    Instagram = IMCC_Instagram;
    privacyPolicyText = POLICY_TEXT;
    privacyPolicyLink = POLICY_LINK;        
}