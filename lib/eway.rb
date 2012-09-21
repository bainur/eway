class Eway
  attr_accessor :result, :method_type, :access_code, :access_code_response,
    :first_name, :last_name, :form_action_url
  
  
  def initialize
    if Rails.env == "development"
      settings = YAML.load_file('config/eway.yml')
    elsif Rails.env == "production"
      settings = YAML.load_file('config/eway.yml')
    end
    @xml_url = settings["eway"]["xml_url"]
    @json_url = settings["eway"]["json_url"]
    @soap_url = settings["eway"]["soap_url"]      
    @username = settings["eway"]["username"]      
    @password = settings["eway"]["password"]   
    @active_merchant_login = settings["eway"]["active_merchant_login"]   
    @active_merchant_password = settings["eway"]["active_merchant_password"]   
  end
  
  #### example params xml, json , and soap, and it will converted based on method type
  ##{"request_method_options"=>"xml", 
  #"txtTokenCustomerID"=>"NULL", "RedirectUrl"=>"http://localhost:3000/results", 
  #"IPAdress"=>"127.0.0.1", 
  #"Payment"=>{"TotalAmount"=>"", "CurrencyCode"=>"AUD", 
  #"InvoiceNumber"=>"Inv 21540", "InvoiceReference"=>"513456", 
  #"InvoiceDescription"=>"Individual Invoice Description"}, 
  #"request_options"=>"", "option1"=>"", "option2"=>"", "option3"=>"", 
  #"Customer"=>{"Title"=>"Mr.", "CustomerReference"=>"A12345", 
  #"FirstName"=>"John", "LastName"=>"Doe", "CompanyName"=>"WEB ACTIVE", 
  #"JobDescription"=>"Developer", "Street1"=>"15 Smith St", "City"=>"Phillip", 
  #"State"=>"ACT", "PostalCode"=>"2602", "Country"=>"au", "Email"=>"", 
  #"Phone"=>"1800 10 10 65", "Mobile"=>"1800 10 10 65"}, 
  #"Method"=>"CreateTokenCustomer", "commit"=>"submit"}
 
  def create_customer_token(method_type, params = {})
    self.method_type = method_type
    
    self.result = case method_type
    when "xml"
      customer_token_xml(params)
    when "soap"
      customer_token_soap(params)
    when "json"
      customer_token_json(params)
    end
  end
  
  def customer_token_xml(params)    
    tmp = params.except("utf8", "authenticity_token", "action", "controller", "commit","request_method_options")
    xml_hash = {"CreateAccessCode" => tmp} if self.method_type == "xml"
    
    xml = params
    xml = xml_hash.to_xml.gsub("<hash>","").gsub("</hash>","") if params.class == Hash
    
    c = Curl::Easy.http_post("https://api.sandbox.ewaypayments.com/AccessCodes") do |curl|
      curl.headers["Content-Type"] = "text/xml"
      curl.http_auth_types = :basic
      curl.username = @username
      curl.password = @password
      curl.verbose = true
    end

    c.post(xml)
    self.result = c.body_str
  end
  
  def customer_token_json(params)    
    tmp = params.except("utf8", "authenticity_token", "action", "controller", "commit","request_method_options")    
    json_call = params
    json_call = tmp.to_json if params.class == Hash
    
    c = Curl::Easy.http_post(@json_url,json_call) do |curl|
      curl.headers["Accept"] = "application/json"
      curl.headers["Content-Type"] = "application/json"
      curl.http_auth_types = :basic
      curl.username = @username
      curl.password = @password
      curl.verbose = true
      curl.on_complete {|response, err|
        code = response.body_str
      }
    end      
          
    self.result = code
  end
  
  def customer_token_soap(params)        
    xm = <<-EOF
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
<soap:Body>
        <CustomerIP>10.10.10.1</CustomerIP>
        <Method>CreateTokenCustomer</Method>
    <CreateAccessCode xmlns="https://api.ewaypayments.com/">
      <request>
        <RedirectUrl>#{params['RedirectUrl']}</RedirectUrl>
        <Customer>          
          <Reference>#{params["Customer"]["Reference"]}</Reference>
          <Title>#{params["Customer"]["Title"]}</Title>
          <FirstName>#{params["Customer"]["FirstName"]}</FirstName>
          <LastName>#{params["Customer"]["LastName"]}</LastName>
          <CompanyName>#{params["Customer"]["CompanyName"]}</CompanyName>
          <JobDescription>#{params["Customer"]["JobDescription"]}</JobDescription>
          <Street1>#{params["Customer"]["JobDescription"]}</Street1>
          <City>#{params["Customer"]["Citys"]}</City>
          <State>#{params["Customer"]["State"]}</State>
          <PostalCode>#{params["Customer"]["PostalCode"]}</PostalCode>
          <Country>#{params["Customer"]["Country"]}</Country>
          <Phone>#{params["Customer"]["Phone"]}</Phone>
          <Mobile>#{params["Customer"]["Mobile"]}</Mobile>
        </Customer>         
        <Payment>
          <TotalAmount>#{params["Payment"]["TotalAmount"].nil?? '100' : "100"}</TotalAmount>
          <InvoiceNumber>#{params["Payment"]["InvoiceNumber"]}</InvoiceNumber>
          <InvoiceDescription>#{params["Payment"]["InvoiceDescription"]}</InvoiceDescription>
          <InvoiceReference>#{params["Payment"]["InvoiceReference"]}</InvoiceReference>
          <CurrencyCode>#{params["Payment"]["CurrencyCode"]}</CurrencyCode>
        </Payment>        
      </request>
    </CreateAccessCode>
  </soap:Body>
</soap:Envelope>
    EOF
    client = Savon::Client.new(@soap_url) do
      http.auth.basic "44DD7C70Jre1dVgIsULcEyi+A+/cX9V5SAHkIiyVdWrHRG2tZm0rdintfZz85Pa/kGwq/1", "Abcd1234"
        
    end

    puts client.wsdl.soap_actions

    response = client.request(:create_access_code) do
      soap.xml = xm
    end

    @res = response.to_hash
    self.result = response.to_hash
  end
  
  def payment
    case self.method_type
    when "xml"
      @result = Nokogiri::XML.parse(self.result)

      @access_code = @result.xpath('//CreateAccessCodeResponse/AccessCode').text
      @customer_data = @result.xpath('//CreateAccessCodeResponse/Customer').children
      @customer_arr = @customer_data.map{|x| x.name + "," + x.text}
      @first_name = @customer_data.xpath('//FirstName').text
      @last_name = @customer_data.xpath('//LastName').text

      @form_action = @result.xpath('//CreateAccessCodeResponse/FormActionURL').text
      @payment_data  = @result.xpath('//CreateAccessCodeResponse/Payment').children
      @payment_arr = @payment_data.map{|x| x.name + "," + x.text}
      
    when "json"      
      @result = JSON.parse(self.result)

      @access_code = @result["AccessCode"]
      @customer_data = @result["Customer"]      
      @customer_arr = @customer_data
      @first_name = @customer_data["FirstName"]
      @last_name = @customer_data["LastName"]

      @form_action = @result["FormActionURL"]
      @payment_data  = @result["Payment"]
      @payment_arr = @payment_data
    when "soap"      
      @result = self.result[:create_access_code_response][:create_access_code_result]
      @access_code = @result["AccessCode".underscore.to_sym]
      @customer_data = @result["Customer".underscore.to_sym]
      @customer_arr = @customer_data
      @first_name = @customer_data["FirstName".underscore.to_sym]
      @last_name = @customer_data["LastName".underscore.to_sym]

      @form_action = @result["FormActionURL".underscore.to_sym]
      @payment_data  = @result["Payment".underscore.to_sym]
      @payment_arr = @payment_data
    end
    self.access_code = @access_code
    self.first_name = @first_name
    self.last_name = @last_name
    self.form_action_url = @form_action
  end
  
  
  def access_code_result    
    c = Curl::Easy.http_get("https://api.sandbox.ewaypayments.com/AccessCode/#{self.access_code}") do |curl|
      curl.http_auth_types = :basic
      curl.username = @username
      curl.password = @password
      curl.verbose = true
    end
    c.perform
    @res = c.body_str
    self.access_code_response = @res   
  end
  
  ##
  # Example params
  {"EWAY_CARDNAME" => 'TestUser',
    'EWAY_CARDNUMBER' => "4444333322221111", "EWAY_CARDEXPIRYMONTH" => '09',
    'EWAY_CARDEXPIRYYEAR' => '2012', "EWAY_CARDSTARTMONTH" => '01', 
    'EWAY_CARDSTARTYEAR'=> '12',
    'EWAY_CARDISSUENUMBER' => '22','EWAY_CARDCVN' => '123'}
  # }
  ##
  def post_cc(params)
    params.merge!(
      {"first_name" => self.first_name, "last_name" => self.last_name, 
        "EWAY_ACCESSCODE" => self.access_code}
    )
    ### post to Eway api
    c = Curl::Easy.http_post(self.form_action_url) do |curl|
      #curl.headers["Content-Type"] = "text/xml"
      curl.http_auth_types = :basic
      curl.username = @username
      curl.password = @password
      curl.verbose = true
    end
    c.post(params)
  end
  
  def post_shopify(params)
    ## post to shopify
    if post_cc(params) ## if success post to eway payment      
      ActiveMerchant::Billing::Base.mode = :test
      
      gateway = ActiveMerchant::Billing::TrustCommerceGateway.new(
        :login => @active_merchant_login,
        :password => @active_merchant_password)
      
      # ActiveMerchant accepts all amounts as Integer values in cents
      amount = JSON.parse(self.access_code_response)["TotalAmount"]# $10.00
      
      # The card verification value is also known as CVV2, CVC2, or CID
      credit_card = ActiveMerchant::Billing::CreditCard.new(
        :first_name         => params["first_name"],
        :last_name          => params["last_name"],
        :number             => params["EWAY_CARDNUMBER"],
        :month              => params["EWAY_CARDEXPIRYMONTH"],
        :year               => params["EWAY_CARDEXPIRYYEAR"],
        :verification_value => params["EWAY_CARDCVN"])
      
      # Validating the card automatically detects the card type
      if credit_card.valid?
        # Capture $10 from the credit card
        response = gateway.purchase(amount, credit_card)
        
        if response.success?          
          #"/succesfully_submitted"
          return :json => {:success => true, :text_message => "$#{sprintf("%.2f", amount)} to the credit card #{credit_card.display_number}"}
        else
          return :json => {:success => false, :text_message => "#{response}"}
        end
      else
        
      end
    end
  end
    
  
  def soap_format(params)
    xm = <<-EOF
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
<soap:Body>
        <CustomerIP>10.10.10.1</CustomerIP>
        <Method>CreateTokenCustomer</Method>
    <CreateAccessCode xmlns="https://api.ewaypayments.com/">
      <request>
        <RedirectUrl>#{params['RedirectUrl']}</RedirectUrl>
        <Customer>          
          <Reference>#{params["Customer"]["Reference"]}</Reference>
          <Title>#{params["Customer"]["Title"]}</Title>
          <FirstName>#{params["Customer"]["FirstName"]}</FirstName>
          <LastName>#{params["Customer"]["LastName"]}</LastName>
          <CompanyName>#{params["Customer"]["CompanyName"]}</CompanyName>
          <JobDescription>#{params["Customer"]["JobDescription"]}</JobDescription>
          <Street1>#{params["Customer"]["JobDescription"]}</Street1>
          <City>#{params["Customer"]["Citys"]}</City>
          <State>#{params["Customer"]["State"]}</State>
          <PostalCode>#{params["Customer"]["PostalCode"]}</PostalCode>
          <Country>#{params["Customer"]["Country"]}</Country>
          <Phone>#{params["Customer"]["Phone"]}</Phone>
          <Mobile>#{params["Customer"]["Mobile"]}</Mobile>
        </Customer>         
        <Payment>
          <TotalAmount>#{params["Payment"]["TotalAmount"].nil?? '100' : "100"}</TotalAmount>
          <InvoiceNumber>#{params["Payment"]["InvoiceNumber"]}</InvoiceNumber>
          <InvoiceDescription>#{params["Payment"]["InvoiceDescription"]}</InvoiceDescription>
          <InvoiceReference>#{params["Payment"]["InvoiceReference"]}</InvoiceReference>
          <CurrencyCode>#{params["Payment"]["CurrencyCode"]}</CurrencyCode>
        </Payment>        
      </request>
    </CreateAccessCode>
  </soap:Body>
</soap:Envelope>
    EOF
    
    return xm
  end
end