/**
 * Created by jay on 24/06/2024.
 */

public class JSONGenerator {
    public String merchant_id;
    public String account_name;
    public String account_id;
    public String type;
    public String usage_mode;
    public String usage_limit;
    public String reference;
    public String name;
    public String description;
    public String shippable;
    public String expiration_date;
    public Transactions transactions;
    public Notifications notifications;
    //public List<Image> images;


    public class Transactions {
        public String amount;
        public String channel;
        public String country;
        public String customerCurrency;
        public List<String> allowed_payment_methods;
    }

    public class Image {
    }

    public class Notifications {
        public String return_url;
        public String status_url;
        public String cancel_url;
    }

    public class JsonParser {
        public String secret { get; set; }
        public String nonce { get; set; }
        public String grant_type { get; set; }
        public String app_id { get; set; }
    }

    public class TransactionStatusParser{
        public notifications notifications{get;set;}
        public String shippable{get;set;}
        public String shipping_amount{get;set;}
        public String description{get;set;}
        public String usage_count{get;set;}
        public String name{get;set;}
        public String viewed_count{get;set;}
        public String reference{get;set;}
        public String expiration_date{get;set;}
        public String usage_limit{get;set;}
        public list<String> images{get;set;}
        public String usage_mode{get;set;}
        public transactionStatus transactions{get;set;}
        public transaction_list listOfTransactions{get;set;}
        public String type{get;set;}
        public String id{get;set;}
        public String account_name{get;set;}
        public String url{get;set;}
        public String account_id{get;set;}
        public String status{get;set;}
        public String merchant_name{get;set;}
        public String merchant_id{get;set;}
    }

    public class transactionStatus{
        public String country{get;set;}
        public list<String> allowed_payment_methods{get;set;}
        public String channel{get;set;}
        public list<transaction_list> transaction_list{get;set;}
        public String amount{get;set;}
    }
    public class transaction_list{
        public String id{get;set;}
        public String type{get;set;}
        public String status{get;set;}
        public String channel{get;set;}
        public String time_created{get;set;}
        public String amount{get;set;}
        public String reference{get;set;}
    }

}