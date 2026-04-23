public with sharing class GetGeoLocationController {

    @AuraEnabled
    public static void saveGeoLocation(String recordId,
                                        String geoLocationFieldApiName, String geoLocationErrorFieldApiName,
                                        String addressFieldApiName, String addressErrorFieldApiName,
                                        String dateFieldApiName, Double latitude, Double longitude, Boolean isOverride)
    {
        // try {
        //     String objectAPIName = ((Id) recordId).getSObjectType().getDescribe().getName();
        //     Integer errorFieldLength = Schema.getGlobalDescribe().get(objectAPIName).getDescribe().fields.getMap().get(geoLocationErrorFieldApiName).getDescribe().getLength();
        //     System.debug('objectAPIName: ' + objectAPIName + ', errorFieldLength: ' + errorFieldLength);

        //     SObject sObjectRecord = ((Id)recordId).getSObjectType().newSObject(recordId);

        //     Double checkinLatitude, checkinLongitude; //07-02

        //     if(isOverride == false) {
        //         String query = 'SELECT Id, ' + geoLocationFieldApiName + ', ' + geoLocationErrorFieldApiName + ', ' + addressFieldApiName + ', ' + addressErrorFieldApiName
        //                     + ' FROM ' + objectAPIName + ' WHERE Id = :recordId';
        //         System.debug('query: ' + query);
        //         sObjectRecord = Database.query(query);
        //         System.debug('Fetched Record: ' + JSON.serialize(sObjectRecord));

        //         if(sObjectRecord.get(geoLocationFieldApiName) == null) {
        //             sObjectRecord.put(geoLocationFieldApiName.replace('__c', '__latitude__s'), latitude);
        //             sObjectRecord.put(geoLocationFieldApiName.replace('__c', '__longitude__s'), longitude);
        //             sObjectRecord.put(dateFieldApiName, System.now());
        //         } else{
        //             checkinLatitude = (Double) sObjectRecord.get(geoLocationFieldApiName.replace('__c', '__latitude__s'));
        //             checkinLongitude = (Double) sObjectRecord.get(geoLocationFieldApiName.replace('__c', '__longitude__s'));
        //             if (checkinLatitude != null && checkinLongitude != null) {
        //                 System.debug('Calling calculateDistance function');
        //                 Double distance = calculateDistance(checkinLatitude, checkinLongitude, latitude, longitude);
        //                 System.debug('Distance from Check-in: ' + distance + ' km');

        //                 if (distance > 2) {
        //                     throw new AuraHandledException('Check-out location must be within 2 km of the check-in location.');
        //                 }
        //             }
        //         }             
        //     } else {
        //         // 
        //         if (checkinLatitude != null && checkinLongitude != null) {
        //                 Double distance = calculateDistance(checkinLatitude, checkinLongitude, latitude, longitude);
        //                 System.debug('Distance from Check-in: ' + distance + ' km');

        //                 if (distance > 2) {
        //                     throw new AuraHandledException('Override not allowed. New location must be within 2 km of the check-in location.');
        //                 }
        //             }

        //         // 
        //         sObjectRecord.put(geoLocationFieldApiName.replace('__c', '__latitude__s'), latitude);
        //         sObjectRecord.put(geoLocationFieldApiName.replace('__c', '__longitude__s'), longitude);
        //         sObjectRecord.put(dateFieldApiName, System.now());
        //         System.debug('Check-in Latitude or Longitude is null. Skipping distance calculation.');
        //         System.debug('isOverride: ' + isOverride);
        //     }

try {
            String objectAPIName = ((Id) recordId).getSObjectType().getDescribe().getName();
            Integer errorFieldLength = Schema.getGlobalDescribe().get(objectAPIName)
                                            .getDescribe().fields.getMap().get(geoLocationErrorFieldApiName)
                                            .getDescribe().getLength();
            System.debug('Object Name: ' + objectAPIName + ', Error Field Length: ' + errorFieldLength);

            SObject sObjectRecord = ((Id)recordId).getSObjectType().newSObject(recordId);

            Double checkinLatitude, checkinLongitude;

            // String query = 'SELECT Id, ' 
            //             + 'Check_IN_GeoLocation__Latitude__s, ' 
            //             + 'Check_IN_GeoLocation__Longitude__s, ' 
            //             + geoLocationFieldApiName + ', ' 
            //             + geoLocationFieldApiName.replace('__c', '__Latitude__s') + ', '
            //             + geoLocationFieldApiName.replace('__c', '__Longitude__s') + ', ' 
            //             + geoLocationErrorFieldApiName + ', ' + addressFieldApiName + ', ' 
            //             + addressErrorFieldApiName 
            //             + ' FROM ' + objectAPIName + ' WHERE Id = :recordId';

            String query = 'SELECT Id, ';
            if (isOverride) {  
                query += 'Check_IN_GeoLocation__Latitude__s, Check_IN_GeoLocation__Longitude__s, ';
            }
            query += geoLocationFieldApiName + ', ' 
                   + geoLocationFieldApiName.replace('__c', '__Latitude__s') + ', '
                   + geoLocationFieldApiName.replace('__c', '__Longitude__s') + ', '
                   + geoLocationErrorFieldApiName + ', '
                   + addressFieldApiName + ', '
                   + addressErrorFieldApiName 
                   + ' FROM ' + objectAPIName + ' WHERE Id = :recordId';



            System.debug('Query: ' + query);
            sObjectRecord = Database.query(query);
            System.debug('Fetched Record: ' + JSON.serialize(sObjectRecord));

            checkinLatitude = (Double) sObjectRecord.get('Check_IN_GeoLocation__Latitude__s');
            checkinLongitude = (Double) sObjectRecord.get('Check_IN_GeoLocation__Longitude__s');
            
            System.debug('Check-IN Latitude: ' + checkinLatitude);
            System.debug('Check-IN Longitude: ' + checkinLongitude);

            if (!isOverride) {
                if(sObjectRecord.get(geoLocationFieldApiName) == null) {
                    sObjectRecord.put(geoLocationFieldApiName.replace('__c', '__latitude__s'), latitude);
                    sObjectRecord.put(geoLocationFieldApiName.replace('__c', '__longitude__s'), longitude);
                    sObjectRecord.put(dateFieldApiName, System.now());
                } else {
                    Double checkoutLatitude = (Double) sObjectRecord.get(geoLocationFieldApiName.replace('__c', '__Latitude__s'));
                    Double checkoutLongitude = (Double) sObjectRecord.get(geoLocationFieldApiName.replace('__c', '__Longitude__s'));
                    
                    System.debug('Check-OUT Latitude: ' + checkoutLatitude);
                    System.debug('Check-OUT Longitude: ' + checkoutLongitude);

                    if (checkinLatitude != null && checkinLongitude != null) {
                        System.debug('Calling calculateDistance function...');
                        Double distance = calculateDistance(checkinLatitude, checkinLongitude, latitude, longitude);
                        System.debug('Distance from Check-in: ' + distance + ' km');

                        if (distance > 2) {
                            throw new CustomException('Check-out location must be within 2 km of the check-in location.');
                        }
                    }
                }
            } else {
                if (checkinLatitude != null && checkinLongitude != null) {
                    System.debug('Checking Override Distance...');
                    Decimal distance = calculateDistance(checkinLatitude, checkinLongitude, latitude, longitude);
                    System.debug('Override Distance from Check-in: ' + distance + ' km');

                    if (distance > 2) {
                        throw new CustomException('Check-Out Failed.check-out location must be within 2 km of the check-in location. ' + distance.setScale(2) + ' km');
                    }
                }
                sObjectRecord.put(geoLocationFieldApiName.replace('__c', '__latitude__s'), latitude);
                sObjectRecord.put(geoLocationFieldApiName.replace('__c', '__longitude__s'), longitude);
                sObjectRecord.put(dateFieldApiName, System.now());
                System.debug('Override Successful.');
            }


            try {
                String geoLocationUrl = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=' + latitude + ',' + longitude + '&key=YOUR_GOOGLE_API_KEY';

                HttpRequest req = new HttpRequest();
                req.setEndpoint(geoLocationUrl);
                req.setMethod('GET');

                Http http = new Http();
                HttpResponse res = http.send(req);
                System.debug('GeoLocation API Response: ' + res.getBody());

                if (res.getStatusCode() == 200) {
                    Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
                    List<Object> results = (List<Object>)responseMap.get('results');
                    if (results != null && results.size() > 0) {
                        Map<String, Object> addressComponent = (Map<String, Object>) results[0];
                        String streetAddress = (String) addressComponent.get('formatted_address');
                        sObjectRecord.put(addressFieldApiName, streetAddress);
                    }
                } else {
                    sObjectRecord.put(addressErrorFieldApiName, 'API failed: ' + res.getStatusCode() + ' ' + res.getBody());
                    if(String.valueOf(sObjectRecord.get(addressErrorFieldApiName)).length() > errorFieldLength) {
                        sObjectRecord.put(addressErrorFieldApiName, String.valueOf(sObjectRecord.get(addressErrorFieldApiName)).substring(0, errorFieldLength-1));
                    }
                }
            } catch (Exception e) {
                sObjectRecord.put(addressErrorFieldApiName, 'API call failed: ' + e.getLineNumber() + ' ' + e.getMessage());
                if(String.valueOf(sObjectRecord.get(addressErrorFieldApiName)).length() > errorFieldLength) {
                    // sObjectRecord.put(addressErrorFieldApiName, String.valueOf(sObjectRecord.get(addressErrorFieldApiName)).substring(0, errorFieldLength-1));
                }
            }
            update sObjectRecord;
        }
        catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage()+e.getLineNumber());
        }
    }


    @AuraEnabled
    public static void saveGeoLocationPermissionDenied(String recordId, String geoLocationFieldApiName, String geoLocationErrorFieldApiName, String dateFieldApiName) {
        try {
            String objectAPIName = ((Id) recordId).getSObjectType().getDescribe().getName();

            SObject sObjectRecord = ((Id)recordId).getSObjectType().newSObject(recordId);

            sObjectRecord.put(geoLocationFieldApiName.replace('__c', '__latitude__s'), null);
            sObjectRecord.put(geoLocationFieldApiName.replace('__c', '__longitude__s'), null);
            sObjectRecord.put(geoLocationErrorFieldApiName, 'Permission Denied');
            sObjectRecord.put(dateFieldApiName, System.now());
            update sObjectRecord;
        }
        catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    // Haversine formula to calculate distance between two latitude/longitude points
    // public static Double calculateDistance(Double lat1, Double lon1, Double lat2, Double lon2) {
    //     Double R = 6371.0; 
    //     Double dLat = Math.radians(lat2 - lat1);
    //     Double dLon = Math.radians(lon2 - lon1);

    //     Double a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    //             Math.cos(Math.radians(lat1)) * Math.cos(Math.radians(lat2)) *
    //             Math.sin(dLon / 2) * Math.sin(dLon / 2);
    //     Double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

    //     return R * c;
    // }
    public static Double calculateDistance(Double lat1, Double lon1, Double lat2, Double lon2) {
    Double R = 6371.0; // Radius of Earth in km
    Double dLat = (lat2 - lat1) * Math.PI / 180;
    Double dLon = (lon2 - lon1) * Math.PI / 180;

    Double a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
               Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
               Math.sin(dLon / 2) * Math.sin(dLon / 2);
    Double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

    return R * c;
}


}