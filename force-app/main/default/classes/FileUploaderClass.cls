public with sharing class FileUploaderClass {
    
    @AuraEnabled
    public static String uploadFile(String base64, String filename, String recordId) {
        ContentVersion cv = createContentVersion(base64, filename);
        if(cv == null) {
            return null;
        }
        ContentDocumentLink cdl = createContentLink(cv.Id, recordId);
        if (cv == null || cdl == null) {
            return null;
        }
        return cdl.Id;
    }
    
    private static ContentVersion createContentVersion(String base64, String filename) {
        try {
            ContentVersion cv = new ContentVersion();
            cv.VersionData = EncodingUtil.base64Decode(base64);
            cv.Title = filename;
            cv.PathOnClient = filename;
            insert cv;
            return cv;
        }
        catch(DMLException e) {
            System.debug(e);
            return null;
        }
        catch(Exception e) {
            System.debug(e);
            return null;
        }
        
    }
    
    private static ContentDocumentLink createContentLink(String contentVersionId, String recordId) {
        try {
            if (contentVersionId == null || recordId == null) { return null; }
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = [SELECT ContentDocumentId  FROM ContentVersion  WHERE Id =: contentVersionId].ContentDocumentId;
            cdl.LinkedEntityId = recordId;
            cdl.ShareType = 'V';
            insert cdl;
            return cdl;
        }
        catch(DMLException e) {
            System.debug(e);
            return null;
        }
        catch(Exception e) {
            System.debug(e);
            return null;
        }
    }
}