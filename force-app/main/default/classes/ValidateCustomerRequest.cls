/**
 * Date:        7 jan 2020
 * Created By : Girikon(Ashish)
 * Test Class : ValidateCustomerRequestTest
 * *************************************************************************
 * Description: This class is wraper for SAP intregration
 * *************************************************************************
 * History: 
 */
public with sharing class ValidateCustomerRequest {

    public ValidateCustomerRequest(Account account, Contact primaryContact) 
    {
        Systems aSystem = new Systems();
        aSystem.CallingApplication = 'SFDC-GE';
        DateTime today = DateTime.now();
        aSystem.MessageDate = today.format('yyyy-MM-dd');
        aSystem.MessageStatus = '';
        aSystem.MessageStatusText = '';
        aSystem.SystemReference = account.Id;

        this.Header = new Header();
        this.Header.systems = aSystem;

        AddressWrapper anAddressWrapper = new AddressWrapper();
        Customer aCustomer = new Customer();
        aCustomer.CustomerEmail = primaryContact.Email != null ? primaryContact.Email : '';
        aCustomer.CustomerGroup = '';
        aCustomer.CustomerNumber = '';
        aCustomer.CustomerNumberType = 'web';

        Person aPerson = new Person();
        aPerson.FirstNames = primaryContact.FirstName != null ? primaryContact.FirstName : ' UNK';
        aPerson.LastName = primaryContact.LastName != null ? primaryContact.LastName : 'UNK';

        Address anAddress = new Address();
        anAddress.Organisation = '';
        anAddress.Department = '';
        // Map<Integer, String> billMailingAddress ; //= InvoiceUtilities.splitAddress(account.BillingStreet);
        // anAddress.AddressLine1 = billMailingAddress.get(1);
        // anAddress.AddressLine2 = billMailingAddress.get(2);
        anAddress.AddressLine1 =account.BillingStreet !=null ? account.BillingStreet : ''; 
        anAddress.AddressLine2 =''; //account.Billing_Address_Line_2__c != null ? account.Billing_Address_Line_2__c: '';
        anAddress.City = account.BillingCity != null ? account.BillingCity : '';
        anAddress.State = account.BillingStateCode;
        anAddress.Country = account.BillingCountryCode;
        anAddress.PostalCode = account.BillingPostalCode != null ? account.BillingPostalCode : '';
        anAddress.PhoneNumber = primaryContact.Phone != null ? primaryContact.Phone : '';
        anAddress.PhoneExtension = '';
        anAddress.FaxNumber = primaryContact.Fax != null ? primaryContact.Fax : '';
        anAddressWrapper.Customer = aCustomer;
        anAddressWrapper.Person = aPerson;
        anAddressWrapper.Address = anAddress;

        this.Content = new Content();
        this.Content.AddressWrapper = anAddressWrapper;

    }
    
     public Header header;
    public Content content;

    public class Header {
        public Systems systems;
        public List<DataPacket> dataPacket = new List<DataPacket>();
    }

    public class Address {
        public String organisation;
        public String department;
        public String addressLine1;
        public String addressLine2;
        public String city;
        public String state;
        public String postalCode;
        public String country;
        public String phoneNumber;
        public String phoneExtension;
        public String faxNumber;
    }

    public class AddressWrapper {
        public Customer customer;
        public Person person;
        public Address address;
    }

    public class Customer {
        public String customerNumber;
        public String customerNumberType;
        public String customerGroup;
        public String customerEmail;
    }

    public class Content {
        public AddressWrapper addressWrapper;
    }

    public class Person {
        public String firstNames;
        public String lastName;
    }

    public class Systems {
        public String callingApplication;
        public String messageDate;
        public String messageStatus;
        public String messageStatusText;
        public String systemReference;
    }

    public class DataPacket {
        public String dataField;
        public String dataValue;
    }



    public static ValidateCustomerRequest parse(String json) {
        return (ValidateCustomerRequest) System.JSON.deserialize(json, ValidateCustomerRequest.class);
    }

    public static String serializeToString(ValidateCustomerRequest request) {
        return JSON.serialize(request);
    }
}