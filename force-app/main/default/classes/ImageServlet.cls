public with sharing class ImageServlet {
    public Blob imageData { get; set; }
    public String contentType { get; set; }
    
    public ImageServlet() {
        String contentVersionId = ApexPages.currentPage().getParameters().get('id');
        
        if (String.isNotBlank(contentVersionId)) {
            try {
                List<ContentVersion> versions = [
                    SELECT Id, VersionData, FileExtension, Title
                    FROM ContentVersion
                    WHERE Id = :contentVersionId
                    LIMIT 1
                ];
                
                if (!versions.isEmpty() && versions[0].VersionData != null) {
                    imageData = versions[0].VersionData;
                    String ext = versions[0].FileExtension != null ? versions[0].FileExtension.toLowerCase() : 'jpeg';
                    
                    if (ext == 'png') {
                        contentType = 'image/png';
                    } else if (ext == 'jpg' || ext == 'jpeg') {
                        contentType = 'image/jpeg';
                    } else if (ext == 'gif') {
                        contentType = 'image/gif';
                    } else if (ext == 'bmp') {
                        contentType = 'image/bmp';
                    } else {
                        contentType = 'image/jpeg';
                    }
                }
            } catch (Exception e) {
                System.debug('Error loading image: ' + e.getMessage());
            }
        }
    }
}