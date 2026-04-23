public class IntegrationRequestBuilder {

    public class ProductMasterJson {
        public String ITEM_NUMBER;	//000000000400009166
        public String ITEM_DESCRIPTION;	//KYROS STNSL 80DA-210LT HD BL
        public String ITEM_GROUP;	//FG3000
        public String ITEM_TYPE;	//FERT
        public String BASE_UOM;	//L
        public String OLD_MATERIAL_CODE;	//KSL40401PM551
        public String SALES_ORGANISATION;	//
        public String DISTRIBUTION_CHANNEL;	//10
        public String DIVISION;	//28
        public String SALES_UOM;	//NOS
        public String PLANT_CODE;	//1000
        public String GENITEMCATGROUP;	//NORM
        public String SIZE_DIMENSIONS;	//210 LT
        public String ITEM_TYPE_C;	//Fertigerzeugnis
        public String MATERIAL_GROUP_1;	//AD
        public String MATERIAL_GROUP_1_C;	//SBU-4
        public String MATERIAL_GROUP_2;	//AO
        public String MATERIAL_GROUP_2_C;	//Kyros
        public String MATERIAL_GROUP_3;	//AS
        public String MATERIAL_GROUP_3_C;	//Solvent
        public String MATERIAL_GROUP_4;	//CL
        public String MATERIAL_GROUP_4_C;	//Solvents
        public String MATERIAL_GROUP_5;	//CM
        public String MATERIAL_GROUP_5_C;	//Commodity
        public String MATERIAL_GROUP_6;	//CM
        public String MATERIAL_GROUP_6_C;	//CM
        public String LIST_PRICE_MRP_PRICE;	//
        public String HSN_CODE;	//27101990
        public String MPN;	//0
        public String PRODUCT_STATUS;	//KCVEDALQBGZX
        public String PRODUCT_IMAGE_BASE64;	//KCVEDALQBGZX
        public String PRODUCT_IMAGE_NAME;	//KCVEDALQBGZX
        public String Warranty;	//KCVEDALQBGZX
        public String LeadTime;	//KCVEDALQBGZX
    }


    public static List<ProductMasterJson> itemMasterParse(String json){
        return (List<ProductMasterJson>) System.JSON.deserialize(json, List<ProductMasterJson>.class);
    }


    public class CustomerWrapper {
        public String PARENT_ACCOUNT;
        public String CUSTOMER_NO;
        public String CUST_NAME;
        public String COMPANY_CODE;
        public String ACCOUNT_GROUP;
        public String MOBILE_NUMBER;
        public String EMAIL_ID;
        public String PHONE1;
        public String PHONE2;
        public String STREET;
        public String STREET1;
        public String STREET2;
        public String CITY;
        public String POST_CODE;
        public String COUNTRY;
        public String CURRENCY_SF;
        public String GST_NUMBER;
        public String PAN_NUMBER;
        public String INCOTERMS1;
        public String INCOTERMS2;
        public String TCS_APPLICABLE;
        public String TERMS_OF_PAYMENT;
        public String CLASSIFICATION;
        public String SUB_INDUSTRY;
        public String SUB_INDUSTRY2;
        public String INDUSTRY;
        public String SALES_DISTRICT;
		public String DISTRIBUTION_CHANNEL;
        public String DIVISION;
        public String SALES_OFF;
        public String SALES_GRP;
        public String SALES_ORG;
        public String VIRTUAL_ACCOUNT_NUMBER;
        public List<PartnerFunction> PARTNERFUNCTION_LIST;
        public List<BankDetail> BANK_DETAILS;

    }

    public class PartnerFunction {
        public String CUSTOMER_NO;
        public String ADDRESS_TYPE;
        public String ADDRESS_LINE1;
        public String ADDRESS_LINE2;
        public String ADDRESS_LINE3;
        public String CITY;
        public String POSTL_CODE;
        public String DISTRICT;
        public String STATE;
        public String REGION;
        public String GST_IN;
        public String COUNTRY;
        public String PAN_NUMBER;
    }

    public class BankDetail {
        public String CUSTOMER_NO;
        public String BANKNAME;
        public String IFSC_CODE;
        public String ADDRESS;
        public String CUST_BLOCK_STATUS;
    }

    public static List<CustomerWrapper> customerMasterParse(String json){
        return (List<CustomerWrapper>) System.JSON.deserialize(json, List<CustomerWrapper>.class);
    }

    // Wrapper class to handle input data
    public class InvoiceWrapper {
        public String NilkamalSrno { get; set; }
        public String VendorSrno { get; set; }
        public String WarrantyPeriods { get; set; }
        public String SAPInvoiceNo { get; set; }
        public String SAPOrderNo { get; set; }
        public String X2nd_LR_number { get; set; }
        public String X2nd_Transporter_name { get; set; }
        public String Billing_Date { get; set; }
        public String Billing_Document { get; set; }
        public Decimal Billing_Qty { get; set; }
        public String Billing_Type { get; set; }
        public String Customer_Mobile { get; set; }
        public String Sales_org { get; set; }
        public String Distribution_Channel { get; set; }
        public String Division { get; set; }
        public String Item_Text { get; set; }
        public String LR_number { get; set; }
        public String LR_Date { get; set; }
        public String Line_Item { get; set; }
        public String Material { get; set; }
        public String Material_Description { get; set; }
        public Decimal Net_Invoice_Amount { get; set; }
        public String PO_Date { get; set; }
        public String PO_Number { get; set; }
        public String Plant_Name { get; set; }
        public String Sales_Employee_code { get; set; }
        public String Serial_No { get; set; }
        public String Ship_to_Address { get; set; }
        public String Ship_to_City { get; set; }
        public String Ship_to_Country { get; set; }
        public String Ship_to_Email { get; set; }
        public String Ship_to_GST_No { get; set; }
        public String Ship_to_Mob { get; set; }
        public String Ship_to_Name { get; set; }
        public String Ship_to_Pin { get; set; }
        public String Ship_to_Region { get; set; }
        public String Ship_to_Tele { get; set; }
        public String Sold_to_Address { get; set; }
        public String Sold_to_City { get; set; }
        public String Sold_to_Country { get; set; }
        public String Sold_to_GST_No { get; set; }
        public String Sold_to_Party_Name { get; set; }
        public String Sold_to_Party_No { get; set; }
        public String Sold_to_Pin { get; set; }
        public String Sold_to_Email { get; set; }
        public String Sold_to_Telephone { get; set; }
        public String Sold_to_Region { get; set; }
        public String Valuation_Class { get; set; }
        public String Ship_to_Party { get; set; }
        public String MFG_part_no { get; set; }
        public Decimal Total_document_amount { get; set; }
        public Decimal Total_tax_amount { get; set; }
        public String Transporter_name { get; set; }
        public String Customer_Contact_Name {get; set;}
        public String Customer_Contact_Email {get; set;}
        public String Sales_Group_Code {get; set;}
        public String Sales_Group_Description {get; set;}
        public String Sales_Office_Code {get; set;}
        public String Sales_Office_Description {get; set;}
        public String Material_Group_6 {get; set;}
        public Decimal Line_Item_Net_Value {get; set;}
        public Decimal Net_Value_Per_PC {get; set;}
        public String Item_Category {get; set;}
    }

    public static List<InvoiceWrapper> InvoiceParse(String json){
        return (List<InvoiceWrapper>) System.JSON.deserialize(json, List<InvoiceWrapper>.class);
    }

    public class StockWrapper {
        public String Material{ get; set; }
        public String Material_Description{ get; set; }
        public String Plant_Name{ get; set; }
        public String Plant_Code{ get; set; }
        public String Quantity{ get; set;}
        public String Manufacturing_Part_No{ get; set;}
        public String Material_Group6{ get; set;}
        public String MG6_Description{ get; set;}
    }

    public static List<StockWrapper> StockParse(String json){
        return (List<StockWrapper>) System.JSON.deserialize(json, List<StockWrapper>.class);
    }



    // Wrapper class to handle input data
    public class SparesEquipmentWrapper {
        public String SAPMaterialNumber{ get; set; }
        public String VendorMatCode { get; set; }
        public String SAPEquipmentCode { get; set; }
        public String OEMModel { get; set; }

    }

    public static List<SparesEquipmentWrapper> SparesEquipmentParse(String json){
        return (List<SparesEquipmentWrapper>) System.JSON.deserialize(json, List<SparesEquipmentWrapper>.class);
    }

     // Wrapper class to handle input data
    public class HSNWrapper {
        public String HSNCode{ get; set; }
        public String Description { get; set; }
        public Integer GST { get; set; }
        public String Active { get; set; }

    }

    public static List<HSNWrapper> HSNParse(String json){
        return (List<HSNWrapper>) System.JSON.deserialize(json, List<HSNWrapper>.class);
    }
}