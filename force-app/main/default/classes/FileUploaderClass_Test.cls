@isTest
public class FileUploaderClass_Test {

    @isTest
    static void testUploadFileSuccess() {
        Asset ast = new Asset(Name = 'Test Asset');
        insert ast;

        String sampleText = 'This is a test file';
        String base64String = EncodingUtil.base64Encode(Blob.valueOf(sampleText));
        String filename = 'TestFile.txt';

        Test.startTest();
        String result = FileUploaderClass.uploadFile(base64String, filename, ast.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'ContentDocumentLink Id should not be null');

        ContentDocumentLink link = [
            SELECT Id, LinkedEntityId, ShareType
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :ast.Id
            LIMIT 1
        ];

        System.assertEquals('V', link.ShareType);
        System.assertEquals(ast.Id, link.LinkedEntityId);
    }

    @isTest
    static void testUploadFileWithInvalidInput() {
        Test.startTest();
        String result = FileUploaderClass.uploadFile(null, null, null);
        Test.stopTest();

        System.assertEquals(null, result);
    }

    @isTest
    static void testCreateContentVersionWithInvalidBase64() {
        Test.startTest();
        String result = FileUploaderClass.uploadFile('!!!invalidbase64$$$', 'badfile.txt', '001000000000000');
        Test.stopTest();

        System.assertEquals(null, result, 'Should return null on invalid base64 decode');
    }

    @isTest
    static void testCreateContentLinkWithInvalidId() {
        String base64String = EncodingUtil.base64Encode(Blob.valueOf('Dummy Content'));
        String filename = 'TestInvalidLink.txt';

        ContentVersion cv = new ContentVersion(
            Title = filename,
            PathOnClient = filename,
            VersionData = Blob.valueOf('Dummy')
        );
        insert cv;

        Test.startTest();
        String result = FileUploaderClass.uploadFile(base64String, filename, null);
        Test.stopTest();

        System.assertEquals(null, result, 'Should return null when ContentDocumentLink creation fails');
    }
}