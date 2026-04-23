public with sharing class ContactTriggerHandler {

    public static void updateContactPhoneAndMobilePhone(List<Contact> contacts) {
        for (Contact contact : contacts) {
            if (contact.MobilePhone != contact.Phone) {
                contact.Phone = contact.MobilePhone;
            }
        }
    }

}