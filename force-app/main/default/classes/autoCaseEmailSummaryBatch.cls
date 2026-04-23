public with sharing class autoCaseEmailSummaryBatch implements Database.Batchable<SObject>,Database.Stateful{

    public class RowData {
        public String astWrtyName;
        public String astName;
        public String caseName;
        public String quoteName;
    }

    public List<RowData> warrantyRows = new List<RowData>();
    public List<RowData> amcRows = new List<RowData>();

    public Database.QueryLocator start(Database.BatchableContext bc) {

        return Database.getQueryLocator([SELECT Id,CaseNumber FROM Case where CreatedDate =TODAY ]);
    }

    public void execute(Database.BatchableContext bc, List<Case> scope) {

        Set<Id> caseIds = new Set<Id>();
        Map<Id,String> caseIdToName =  new Map<Id,String>();
        Map<Id,Asset_Warranty__c> caseToAstWarranty =  new Map<Id,Asset_Warranty__c>();
        Map<Id,Asset_AMC__c> caseToAstAMC =  new Map<Id,Asset_AMC__c>();
        Map<Id,String> caseToQuote =  new Map<Id,String>();
        for(Case caserec:scope){
            caseIds.add(caserec.Id);
            caseIdToName.put(caserec.Id,caserec.CaseNumber);
        }

        for(Asset_Warranty__c assetW:[SELECT Id,Name,Renewal_Case__c,Asset__r.Name FROM Asset_Warranty__c where Renewal_Case__c IN:caseIds]){
            caseToAstWarranty.put(assetW.Renewal_Case__c,assetW);
        }

        for(Asset_AMC__c assetA:[SELECT Id,Name,Renewal_Case__c,Asset__r.Name FROM Asset_AMC__c where Renewal_Case__c IN:caseIds]){
            caseToAstAMC.put(assetA.Renewal_Case__c,assetA);
        }

        for(Quote quoterec:[SELECT Id,QuoteNumber,Case__c,Document_No_1__c FROM Quote where case__c IN: caseIds]){
            caseToQuote.put(quoterec.Case__c,quoterec.Document_No_1__c);
        }

        if(!caseToAstWarranty.isEmpty()){
            for(Id caseId:caseToAstWarranty.keySet()){
                RowData rd = new RowData();
                rd.astWrtyName=caseToAstWarranty.get(caseId).Name;
                rd.astName=caseToAstWarranty.get(caseId).Asset__r.Name;
                rd.caseName=caseIdToName.get(caseId);
                rd.quoteName=caseToQuote.containsKey(caseId)?caseToQuote.get(caseId):'';
                warrantyRows.add(rd);
            }
        }

        if(!caseToAstAMC.isEmpty()){
            for(Id caseId:caseToAstAMC.keySet()){
                RowData rd = new RowData();
                rd.astWrtyName=caseToAstAMC.get(caseId).Name;
                rd.astName=caseToAstAMC.get(caseId).Asset__r.Name;
                rd.caseName=caseIdToName.get(caseId);
                rd.quoteName=caseToQuote.containsKey(caseId)?caseToQuote.get(caseId):'';
                amcRows.add(rd);
            }
        }

    }

    public void finish(Database.BatchableContext bc) {

        system.debug('rows-->'+warrantyRows);

        if (warrantyRows.isEmpty() && amcRows.isEmpty())
        return;

        String htmlBody ='';
        String cellStyle = 'border: 1px solid black; padding: 6px; text-align: left;';
        if(!warrantyRows.isEmpty()){

             htmlBody = '<html><body>' +
                '<h3>Asset Warranty Expiry Summary</h3>' +
                '<table width="100%" border="1" cellpadding="6" cellspacing="0" ' +
                'style="border-collapse: collapse; border: 1px solid black; font-family: sans-serif;">' +
                '<thead>' +
                    '<tr style="background-color: #fffefeff;">' +
                        '<th style="' + cellStyle + '">Asset Warranty</th>' +
                        '<th style="' + cellStyle + '">Asset</th>' +
                        '<th style="' + cellStyle + '">Warranty Case</th>' +
                        '<th style="' + cellStyle + '">Quote</th>' +
                    '</tr>' +
                '</thead>' +
                '<tbody>';

            for (RowData r : warrantyRows) {
                htmlBody += '<tr>' +
                    '<td style="' + cellStyle + '">' + (r.astWrtyName != null ? r.astWrtyName : '') + '</td>' +
                    '<td style="' + cellStyle + '">' + (r.astName != null ? r.astName : '') + '</td>' +
                    '<td style="' + cellStyle + '">' + (r.caseName != null ? r.caseName : '') + '</td>' +
                    '<td style="' + cellStyle + '">' + (r.quoteName != null ? r.quoteName : '') + '</td>' +
                '</tr>';
            }

            htmlBody += '</tbody></table></body></html>';
        }

         if(!amcRows.isEmpty()){
            if(htmlBody!='')
            {
                htmlBody+='\n\n';
            }
             htmlBody +=
                '<html><body>' +
                '<h3>Asset AMC Expiry Summary</h3>' +
                '<table width="100%" border="1" cellpadding="6" cellspacing="0" ' +
                'style="border-collapse: collapse; border: 1px solid black; font-family: sans-serif;">' +
                '<thead>' +
                    '<tr style="background-color: #fffefeff;">' +
                        '<th style="' + cellStyle + '">Asset AMC</th>' +
                        '<th style="' + cellStyle + '">Asset</th>' +
                        '<th style="' + cellStyle + '">AMC Case</th>' +
                        '<th style="' + cellStyle + '">Quote</th>' +
                    '</tr>' +
                '</thead>' +
                '<tbody>';

            for (RowData r : amcRows) {
                htmlBody +=
                    '<tr>' +
                        '<td style="' + cellStyle + '">' + (r.astWrtyName != null ? r.astWrtyName : '') + '</td>' +
                        '<td style="' + cellStyle + '">' + (r.astName != null ? r.astName : '') + '</td>' +
                        '<td style="' + cellStyle + '">' + (r.caseName != null ? r.caseName : '') + '</td>' +
                        '<td style="' + cellStyle + '">' + (r.quoteName != null ? r.quoteName : '') + '</td>' +
                    '</tr>';
            }

            htmlBody += '</tbody></table></body></html>';
        }

        If(htmlBody!=''){
            OrgWideEmailAddress owea = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE Address='mhd.servicecrm@nilkamal.com' LIMIT 1]; 
            List<String> ccAddress=System.Label.AutoCasemail_cc.split(',');  
            List<String> toAddress=System.Label.AutoCasemail_to.split(',');  

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setOrgWideEmailAddressId(owea.Id);
            mail.setToAddresses(toAddress);
            mail.setCcAddresses(ccAddress);
            mail.setSubject('Quotes Created Today Report');
            mail.setHtmlBody(htmlBody);

            Messaging.sendEmail(
                new List<Messaging.SingleEmailMessage>{ mail }
            );
        }
    }

}