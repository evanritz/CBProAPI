classdef CbProPublic < handle
    properties
        userAgent = 'Matlab CBPro API Client';
        apiUrl = 'https://api.pro.coinbase.com';
        sandboxApiUrl= 'https://api-public.sandbox.pro.coinbase.com';
        url
    end
    methods
        function CbPro = CbProPublic(apiType)
            % apiType - char arr
            % 'api' - Real CB pro api 
            % 'sandbox' - Sandbox CB pro api
            switch apiType
                case 'api'
                    CbPro.url = CbPro.apiUrl;
                case 'sandbox'
                    CbPro.url = CbPro.sandboxApiUrl;
                otherwise
                    error('Enter a vaild API type');
            end
        end
        function [response, jsonStruct, statusCode] = pubGet(CbPro, path)
            % Nonauth GET request for public endpoints
            % path - char arr
            % e.g 'time'
            import matlab.net.http.HeaderField;

            method = matlab.net.http.RequestMethod.GET;
            body = '';

            url = [CbPro.url path]
            
            headers = HeaderField('Content-Type', 'application/json', 'Accept', 'application/json', 'User-Agent', CbPro.userAgent);
            
            [response, jsonStruct, statusCode] = CbPro.request(url, method, headers, body);
        end
        function [response, jsonStruct, statusCode] = request(CbPro, url, method, headers, body)
            % General http request
            import matlab.net.http.RequestMessage;
            request = RequestMessage(method, headers, body);
            response = send(request, url);
            jsonStruct = response.Body.Data;
            statusCode = response.StatusCode; 
        end
        % Public Endpoints 
        function [epoch, iso] = getTime(CbPro)
            % Returns epoch and iso time as char arr 
            path = '/time';
            [~, jsonStruct, ~] = CbPro.pubGet(path)
            epoch = num2str(jsonStruct.epoch);
            iso = jsonStruct.iso;
        end
        function currencies = getCurrencies(CbPro)
            % Returns known currencies 
            path = '/currencies';
            [~, currencies, ~] = CbPro.pubGet(path);
        end
        function products = getProducts(CbPro)
            % Returns tradable product pairs 
            path = '/products';
            [~, products, ~] = CbPro.pubGet(path);
        end
        function orderBook = getProductOrderBook(CbPro, productId, varargin)
            % Returns orderbook for product at specified depth
            % productId - char arr
            % e.g 'BTC-USD'
            % depth - int 
            % e.g 1 - best, 2 - top 50, 3 - full
            path = ['/products/' productId '/book'];
            if ~isempty(varargin)
                depth = num2str(varargin{1});
                path = [path '?level=', depth];
            end
            [~, orderBook, ~] = CbPro.pubGet(path);
        end
        function latestTradeInfo = getProductTicker(CbPro, productId)
            % Returns latest trade info for specified product
            path = ['/products/' productId '/ticker'];
            [~, latestTradeInfo, ~] = CbPro.pubGet(path);
        end
        function latestTrades = getProductTrades(CbPro, productId)
            % Returns latest trades for specified product
            path = ['/products/' productId '/trades'];
            [~, latestTrades, ~] = CbPro.pubGet(path);
        end
        function rates = getHistoricRates(CbPro, productId, startTime, endTime, granularity)
            % Returns historic rates between start and end at specified slices
            % startTime and endTime in iso 8601 format - char arr
            % granularity in mins (api wants it in secs)
            % 1, 5, 15, 60, 360, 1440
            timeSlice = num2str(granularity)*60;
            path = ['/products/' productId '/candles?start=' startTime '&end=' endTime '&granularity=' timeSlice];
            [~, rates, ~] = CbPro.pubGet(path);
        end
        function stats = get24HrStats(CbPro, productId)
            % Returns 24 hours stats of specified product
            path = ['/products/' productId '/stats'];
            [~, stats, ~] = CbPro.pubGet(path);
        end
    end
end