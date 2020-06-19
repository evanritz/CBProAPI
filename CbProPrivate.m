classdef CbProPrivate < CbProPublic
    properties
        apiKey
        secretKey
        passPhrase
    end
    methods
        function CbPro = CbProPrivate(apiType, apiKey, secretKey, passPhrase)
            % Init Public API 
            CbPro = CbPro@CbProPublic(apiType);
            % Set needed auth params
            CbPro.apiKey = apiKey; 
            CbPro.secretKey = secretKey;
            CbPro.passPhrase = passPhrase;
            % Add java classes to path for use
            % local dir that the program is located in 
            classPath = [pwd() '/bin']; 
            javaaddpath(classPath);
            javaclasspath('-dynamic');
        end
        function headers = auth(CbPro, method, path, body)
            % Generates the needed headers for auth
            % KEY - apikey
            % TIME - timestamp in epoch time
            % PASS - passphrase
            % SIGN - base64 encoded hmac sha256 hash of header message
            import matlab.net.http.HeaderField;
            method = char(method);
            [timeStamp, ~] = CbPro.getTime();
            if ~isempty(body)
                body = jsonencode(body);
            end
            
            prehashedMessage = [timeStamp method path body]
            HMAC = HMACGenerator;
            Sign_Sha256_B64 = char(HMAC.genSign(CbPro.secretKey, prehashedMessage));
            
            TIME = timeStamp
            SIGN = Sign_Sha256_B64
            KEY = CbPro.apiKey
            PASS = CbPro.passPhrase
            
            headers = HeaderField('Content-Type', 'application/json', 'Accept', 'application/json', 'User-Agent', CbPro.userAgent, 'CB-ACCESS-KEY', KEY, 'CB-ACCESS-SIGN', SIGN, 'CB-ACCESS-TIMESTAMP', TIME, 'CB-ACCESS-PASSPHRASE', PASS);
        end
        function [response, jsonStruct, statusCode] = get(CbPro, path)
            % Auth GET request for private endpoints
            method = matlab.net.http.RequestMethod.GET;
            body = '';
            url = [CbPro.url path];
            headers = CbPro.auth(method, path, body);
            [response, jsonStruct, statusCode] = CbPro.request(url, method, headers, body);
        end 
        function [response, jsonStruct, statusCode] = delete(CbPro, path)
            % Auth DELETE request for private endpoints
            method = matlab.net.http.RequestMethod.DELETE;
            body = '';
            url = [CbPro.url path];
            headers = CbPro.auth(method, path, body);
            [response, jsonStruct, statusCode] = CbPro.request(url, method, headers, body);
        end
        function [response, jsonStruct, statusCode] = post(CbPro, path, body)
            % Auth POST request for private endpoints
            method = matlab.net.http.RequestMethod.POST;
            url = [CbPro.url path];
            headers = CbPro.auth(method, path, body);
            [response, jsonStruct, statusCode] = CbPro.request(url, method, headers, body);            
        end
        % Account endpoints
        function accounts = getAccounts(CbPro)
            % Returns list of accounts
            path = '/accounts';
            [~, accounts, ~] = CbPro.get(path);
        end
        function account = getAccount(CbPro, accountId)
            % Returns account details for specified account ID
            path = ['/accounts/' accountId];
            [~, account, ~] = CbPro.get(path);
        end
        function accountHistory = getAccountHistory(CbPro, accountId)
            % Returns account history for specified account ID
            path = ['/accounts/' accountId '/ledger'];
            [~, accountHistory, ~] = CbPro.get(path);
        end
        function accountHolds = getAccountHolds(CbPro, accountId)
            % Returns account holds for specified account ID
            path = ['/accounts/' accountId, '/holds'];
            [~, accountHolds, ~] = CbPro.get(path);
        end
        % Order endpoints
        function [orderReceipt, orderUuid] = placeOrder(CbPro, productId, side, type, selfTradePrevention, stopType, stopPrice, varargin)
            % Place order for a specified product
            % varargin - If type == 'limit' - price, size, timeInForce, cancelAfter, postOnly
            % varargin - If type == 'market' - size, funds
            
            % Possible Options
            % selfTradePreventionOptions = {'dc', 'co', 'cn', 'cb'};
            % timeInForceOptions = {'GTC', 'GTT', 'IOC', 'FOK'};
            % stopTypeOptions = {'loss', 'entry'};
            % typeOptions = {'limit', 'market'};
            % sideOptions = {'buy', 'sell'};
            
            path = '/orders';
            UUID = UUIDGenerator;
            orderUuid = char(UUID.genUuid());
            % Build json struct order
            orderDetails.client_oid = orderUuid;
            orderDetails.product_id = productId;
            orderDetails.side = side;
            orderDetails.type = type;
            orderDetails.stp = selfTradePrevention;
            orderDetails.stop = stopType;
            orderDetails.stop_price = stopPrice;
            switch type
                case 'limit'
                    orderDetails.price = varargin{1}; % price
                    orderDetails.size = varargin{2}; % size
                    orderDetails.time_in_force = varargin{3}; % timeInForce
                    orderDetails.cancel_after = varargin{4}; % cancelAfter
                    %orderDetails.cancel_after = varargin{5}; % postOnly
                case 'market'
                    orderDetails.size = varargin{1}; % size
                    orderDetails.funds = varargin{2}; % funds
            end
            [~, orderReceipt, ~] = CbPro.post(path, orderDetails);
        end
        function orderUuid = cancelOrder(CbPro, uuidType, orderUuid)
            % Cancels order given either server or client UUID 
            path = '/orders/';
            switch uuidType
                case 'server'
                    path = [path orderUuid];
                case 'client'
                    path = [path 'client:' orderUuid];
                otherwise
                    error('Enter vaild UUID type');
            end
            [~, orderUuid, ~] = CbPro.delete(path);
        end
        function orderUuids = cancelOrders(CbPro)
            % Cancels all orders 
            path = '/orders';
            [~, orderUuids, ~] = CbPro.delete(path)
        end
        function orders = getOrders(CbPro, status, varargin)
            % Returns orders for specified status and product 
            path = '/orders';
            switch status
                case 'all'
                    path = [path '?status=done&status=pending&status=active&staus=open'];
                otherwise
                    path = [path '?status=' status];
            end
            if ~isempty(varargin)
                productId = varargin{1};
                path = [path '&product_id=' productId];
            end
            [~, orders, ~] = CbPro.get(path);
        end
        function order = getOrder(CbPro, uuidType, orderUuid)
            % Returns order for specified UUID
            path = '/orders/';
            switch uuidType
                case 'server'
                    path = [path orderUuid];
                case 'client'
                    path = [path 'client:' orderUuid];
                otherwise
                    error('Enter vaild UUID type');
            end
            [~, order, ~] = CbPro.get(path);
        end
        % Fee endpoint
        function fees = getFees(CbPro)
            % Returns marker and taker fees over the past 30 days
            path = '/fees';
            [~, fees, ~] = CbPro.get(path);
        end
    end
end
