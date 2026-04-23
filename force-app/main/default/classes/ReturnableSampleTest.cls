@isTest
private class ReturnableSampleTest {
    
    Public class ReturnableSampleMock implements WebServiceMock {
        Public void doInvoke(
            Object stub,
            Object request,
            Map<String, Object> response,
            String endpoint,
            String soapAction,
            String requestName,
            String responseName,
            String responseNS,
            String requestNS) {
                
                ReturnableSample.ZcrmReturnableSamplesResponse_element fakeResponse = 
                    new ReturnableSample.ZcrmReturnableSamplesResponse_element();
                
                ReturnableSample.ZcrmRsamplesOutput output = new ReturnableSample.ZcrmRsamplesOutput();
                
                ReturnableSample.ZcrmCustomerSampleOutStr sampleItem = new ReturnableSample.ZcrmCustomerSampleOutStr();
                sampleItem.Auart = 'SampleType';
                sampleItem.Vbeln = '12345';
                sampleItem.Name1 = 'Test Customer';
                sampleItem.Zdays = 10;
                
                output.item = new List<ReturnableSample.ZcrmCustomerSampleOutStr>();
                output.item.add(sampleItem);
                
                fakeResponse.EmReturnableSamples = output;
                fakeResponse.EmAddnData = 'Additional data';
                
                response.put(responseName, fakeResponse);
            }
    }
    
    @isTest
    static void testZcrmReturnableSamples() {
        Test.setMock(WebServiceMock.class, new ReturnableSampleMock());
        
        ReturnableSample.ZCRM_RETURNABLE_SAMPLES_WS service = new ReturnableSample.ZCRM_RETURNABLE_SAMPLES_WS();
        
        ReturnableSample.ZcrmReturnableSamplesResponse_element response = service.ZcrmReturnableSamples('testFoc');
        
       
        
        //ReturnableSample.ZcrmCustomerSampleOutStr firstItem = response.EmReturnableSamples.item[0];
      
    }
    
}