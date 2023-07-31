/**
 * Date:        7 jan 2020
 * Created By : Girikon(Ashish)
 * Test Class : ValidateCustomerResponseTest
 * *************************************************************************
 * Description: This class is wraper for SAP intregration
 * *************************************************************************
 * History: 
 */
public with sharing class ValidateCustomerResponse {

    public Header header;
    public Content content;
    public List<Message> messages;
    public ValidateCustomerResponse()
    {
        messages = new List<Message>();
    }

    public class Header {
        public Systems systems;
        public List<DataPacket> dataPacket;
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
    }

    public class DataPacket {
        public String dataField;
        public String dataValue;
    }

    public class Message 
    {
        public String messageReference;
        public String messageSeverity;
        public String messageType;
        public String messageID;
        public String messageText;
    }

    public static ValidateCustomerResponse parse(String json) 
    {
        ValidateCustomerResponse obj = new ValidateCustomerResponse();
        if(String.isNotBlank(json))
        {
        	obj = (ValidateCustomerResponse) System.JSON.deserialize(json, ValidateCustomerResponse.class);    
        }
        return obj;
    }
}