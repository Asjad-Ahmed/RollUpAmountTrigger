public class ContentVersionTriggerHandler{
	public static void handleAfterUpdate( List<ContentVersion> triggerNew)
    {
        List<ContentVersion> cvList = triggerNew;
        Set<ID> fileId=new Set<ID>();
        for(ContentVersion cv : cvList)
        {
            if(cv.FileType=='PNG' && cv.Title == 'Signature.png')
            {
                fileId.add(cv.ContentDocumentId);
            }
        }
        if(fileId.size()>0)
        {
            Set<Id> signatureIds=new Set<Id>();
            List<Opportunity> oppList=new List<Opportunity>();
            List<Lead> leadList=new List<Lead>();
            
            for(ContentDocumentLink cdl:[SELECT Id, LinkedEntityId,LinkedEntity.type FROM ContentDocumentLink WHERE ContentDocumentId in :fileId])
            {
                system.debug(cdl.LinkedEntity.Type);
                system.debug(cdl.LinkedEntityId);
                if(cdl.LinkedEntity.Type=='signature__Signature__c')
                {
                    signatureIds.add(cdl.LinkedEntityId);
                }
            }
            if(!signatureIds.isEmpty()){
                responseEmailAndAttachment(signatureIds);
            }
        }
    }

    @future(callout=true)
    public static void responseEmailAndAttachment(set<Id> signatureIds){  
        Set<ID> setSSIds=new Set<ID>();
        Set<String> setContactsEmail=new Set<String>();
        List<Attachment> lstAttachment = new List<Attachment>();
        list<ContentVersion> lstCV = new list<ContentVersion>();
        list<ContentDocumentLink> lstCDL = new list<ContentDocumentLink>();
        List<Messaging.SingleEmailMessage> lstEmails = new List<Messaging.SingleEmailMessage>();
        map<string,string> mapAttachmentNameRespectedParentId = new map<string,string>();

        EmailTemplate ET = [SELECT Id, HtmlValue, Subject, Body, DeveloperName FROM EmailTemplate where DeveloperName = 'SignedResponseTemplate' LIMIT 1];
        Map<Id, signature__Signature__c> mapSignature = new Map<Id, signature__Signature__c>([SELECT Id, signature__Name__c, signature__Full_Name__c, Quote__c, Quote__r.QuoteNumber, signature__Email__c FROM signature__Signature__c WHERE Id IN: signatureIds AND Quote__c != null]);
        for (signature__Signature__c objSS : mapSignature.values()) {
            setContactsEmail.add(objSS.signature__Email__c);
            Attachment attachment = new Attachment();
            PageReference pdf = new PageReference('/apex/ResponseQuotePDF');
            pdf.getParameters().put('id',objSS.Id);
            blob signedQuoteblob;
            if(Test.isRunningTest()){
                signedQuoteblob = blob.valueof('Test Data');
            }
            else{
                signedQuoteblob = pdf.getContentaspdf();
            }    
            attachment.body = signedQuoteblob;
            if(objSS.signature__Full_Name__c != null && objSS.signature__Full_Name__c != ''){
                attachment.Name = objSS.signature__Full_Name__c+'.pdf';
            }else{
                attachment.Name = objSS.Quote__r.QuoteNumber+' SignedQuote.pdf';
            }
            attachment.contenttype = 'application/pdf';
            attachment.IsPrivate = false;
            attachment.ParentId = objSS.Id;
            lstAttachment.add(attachment);

            ContentVersion objCV = new ContentVersion();
            objCV.Title = attachment.Name;
            objCV.PathOnClient = attachment.Name;
            objCV.VersionData = signedQuoteblob;
            lstCV.add(objCV);
            mapAttachmentNameRespectedParentId.put(objCV.PathOnClient, objSS.Id);

            Messaging.SingleEmailMessage objEmail = new Messaging.SingleEmailMessage();
            List<String> lstToAddresses = new List<String>();
            Messaging.EmailFileAttachment objEFA = new Messaging.EmailFileAttachment();
            objEmail.setToAddresses(new List<String>(setContactsEmail));
            objEFA.setFileName(attachment.Name);
            objEFA.setBody(signedQuoteblob);
            objEmail.setSubject(ET.Subject);
            String strBody = ET.HtmlValue;
            strBody = strBody.replace('{FName}', objSS.signature__Name__c);
            objEmail.setHtmlBody(strBody);
            objEmail.setFileAttachments(new Messaging.EmailFileAttachment[] {objEFA});
            lstEmails.add(objEmail);  
        }
        if(!lstEmails.isEmpty()){
            Messaging.sendEmail(lstEmails);
        }
        if(!lstCV.isEmpty())
        {
            insert lstCV;
            set<id> setOfCVID = new set<Id>();
            for(ContentVersion CV : lstCV)
            {
                setOfCVID.add(CV.Id);
            }
            for(ContentVersion CV : [SELECT Id, ContentDocumentId, PathOnClient FROM ContentVersion WHERE Id IN: setOfCVID])
            {
                if(!(mapAttachmentNameRespectedParentId.isEmpty()) && mapAttachmentNameRespectedParentId.containskey(CV.PathOnClient))
                {
                    ContentDocumentLink objCDL = new ContentDocumentLink();
                    objCDL.ContentDocumentId = CV.ContentDocumentId;
                    objCDL.LinkedEntityId = mapAttachmentNameRespectedParentId.get(CV.PathOnClient);
                    objCDL.ShareType = 'I';
                    lstCDL.add(objCDL);
                }
            }
        }
        if(!lstCDL.isEmpty()){
            insert lstCDL;
        }
    }
}