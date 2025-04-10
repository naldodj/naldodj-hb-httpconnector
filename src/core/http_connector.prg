/*

 _    _      _    _                                                  _
| |_ | |__  | |_ | |_  _ __    ___   ___   _ __   _ __    ___   ___ | |_   ___   _ __
| __|| '_ \ | __|| __|| '_ \  / __| / _ \ | '_ \ | '_ \  / _ \ / __|| __| / _ \ | '__|
| |_ | | | || |_ | |_ | |_) || (__ | (_) || | | || | | ||  __/| (__ | |_ | (_) || |
 \__||_| |_| \__| \__|| .__/  \___| \___/ |_| |_||_| |_| \___| \___| \__| \___/ |_|
                      |_|

Class THTTPConnector

Released to Public Domain.
--------------------------------------------------------------------------------------

*/

#include "hbcurl.ch"
#include "hbclass.ch"

#if defined(__PLATFORM__WINDOWS)
    #require "hbwin"
#endif

// Base class for HTTP connectors
class THttpConnector

    data cError as character          // Stores error messages
    data cProxy as character          // Proxy configuration

    data hHeaders init { => } as hash // HTTP headers

    data lHasSSL init tip_SSL()
    data lVerifySSL init .F. as logical // SSL verification flag

    data nError init 0 as numeric     // Error code
    data nTimeout init 180 as numeric // Timeout in seconds
    data nHttpCode init 0 as numeric  // HTTP status code

    data oUrl as object              // URL object

    method New(cUrl as character) constructor
    method Get(cQuery as character) as hash
    method Post(cData as character,cQuery as character) as hash
    method SetProxy(cProxy as character) as character
    method SetHeader(cKey as character,cValue as character) as hash
    method SetTimeout(nSeconds as numeric) as numeric
    method ClearHeaders() as hash
    method SetSSLVerify(lVerify as logical) as logical

    //Virtual Methods
    method SendRequest(cMethod as character,cData as character,cQuery as character) as hash virtual
    method Close() as numeric virtual
    method Reset() as numeric virtual
    method ResetAll() as numeric virtual

end class

method New(cUrl as character) class THttpConnector
    self:oUrl:=TUrl():new()
    if (!self:oUrl:SetAddress(cUrl))
        self:cError:="Invalid URL"
    endif
    return(self) as object

method Get(cQuery as character) class THttpConnector
    return(self:SendRequest("GET",cQuery)) as hash

method Post(cData as character,cQuery as character) class THttpConnector
    return(self:SendRequest("POST",cData,cQuery)) as hash

method SetProxy(cProxy as character) class THttpConnector
    self:cProxy:=cProxy
    return(self:cProxy) as character

method SetHeader(cKey as character,cValue as character) class THttpConnector
    self:hHeaders[Lower(cKey)]:=cValue
    return(self:hHeaders) as hash

method ClearHeaders() class THttpConnector
    if !Empty(self:hHeaders)
        hb_HClear(@self:hHeaders)
    endif
    return(self:hHeaders) as hash

method SetTimeout(nSeconds as numeric) class THttpConnector
    hb_default(@nSeconds,180)
    self:nTimeout:=nSeconds
    return(self:nTimeout) as numeric

method SetSSLVerify(lVerify as logical) class THttpConnector
    hb_default(@lVerify,.F.)
    self:lVerifySSL:=self:lHasSSL.and.lVerify
    return(self:lVerifySSL) as logical

************************************************************************************************************************
// Implementation for HBCURL
class TCURLHTTPConnector FROM THttpConnector

    data hCURLOptions init {=>} as hash
    data phCurl as pointer

    method New(cUrl as character) constructor
    method SetOption(nCURLOption as numeric,uValue as anytype) as hash
    method DelOption(nCURLOption as numeric) as hash
    method ClearOptions() as hash
    method SendRequest(cMethod as character,cData as character,cQuery as character) as hash
    method Close() as numeric
    method Reset() as numeric
    method ResetAll() as numeric

end class

method New(cUrl as character) class TCURLHTTPConnector
    self:SUPER:New(cUrl)
    curl_global_init()
    self:phCurl:=curl_easy_init()
    if Empty(self:phCurl)
        self:cError:="Failed to initialize cURL"
        self:Close()
    endif
    return(self) as object

method SetOption(nCURLOption as numeric,uValue as anytype) class TCURLHTTPConnector
    self:hCURLOptions[nCURLOption]:=uValue
    return(self:hCURLOptions) as hash

method DelOption(nCURLOption as numeric) class TCURLHTTPConnector
    local nPos:=hb_HPos(self:hCURLOptions,nCURLOption)
    if (nPos>0)
        hb_HDelAt(self:hCURLOptions,nPos)
    endif
    return(self:hCURLOptions) as hash

method ClearOptions() class TCURLHTTPConnector
    if (!Empty(self:hCURLOptions))
        hb_HClear(@self:hCURLOptions)
    endif
    return(self:hCURLOptions) as hash

method SendRequest(cMethod as character,cData as character,cQuery as character) class TCURLHTTPConnector

    local aHeaders as array

    local cCR as character
    local cLF as character
    local cCRLF as character

    local cFullUrl as character
    local cResponse as character
    local cRespHeaders as character
    local cCURLOptions as character

    local hHeader as hash
    local hOption as hash
    local nCRLF as numeric
    local nSizeHeader as numeric
    local nATHeaderEnd as numeric

    HB_SYMBOL_UNUSED(cQuery)

    if (Empty(self:phCurl))
        return(ResponseAsHash(""/*cBody*/,""/*cHeaders*/,500/*http_status*/,self:cError/*cError*/,500/*nError*/))
    endif

    self:Reset()

    cCURLOptions:=ValType(self:hCURLOptions)

    if ((cCURLOptions=="H").and.!Empty(self:hCURLOptions))
        for each hOption in self:hCURLOptions
            if (HB_CURLOPT_DL_BUFF_SETUP==hOption:__enumKey())
                curl_easy_setopt(self:phCurl,HB_CURLOPT_DL_BUFF_SETUP)
            else
                curl_easy_setopt(self:phCurl,hOption:__enumKey(),hOption:__enumValue())
            endif
        next each
    endif

    // Configure cURL using TUrl components
    if ((cCURLOptions=="H").and.!hb_HHasKey(self:hCURLOptions,HB_CURLOPT_URL))
        cFullUrl:=self:oUrl:BuildAddress()
        curl_easy_setopt(self:phCurl,HB_CURLOPT_URL,cFullUrl)
    endif

    if ((cCURLOptions=="H").and.!hb_HHasKey(self:hCURLOptions,HB_CURLOPT_CUSTOMREQUEST))
        curl_easy_setopt(self:phCurl,HB_CURLOPT_CUSTOMREQUEST,cMethod)
    endif

    // Set headers
    if (!Empty(self:hHeaders))
        if ((cCURLOptions=="H").and.!hb_HHasKey(self:hCURLOptions,HB_CURLOPT_HTTPHEADER))
            aHeaders:=Array(0)
            for each hHeader in self:hHeaders
                aAdd(aHeaders,hHeader:__enumKey()+": "+hHeader:__enumValue())
            next each //hHeader
            curl_easy_setopt(self:phCurl,HB_CURLOPT_HTTPHEADER,aHeaders)
        endif
    endif

    // Set proxy
    if ((cCURLOptions=="H").and.!hb_HHasKey(self:hCURLOptions,HB_CURLOPT_PROXY))
        if (!Empty(self:cProxy))
            curl_easy_setopt(self:phCurl,HB_CURLOPT_PROXY,self:cProxy)
        endif
    endif

    // Set timeout
    if ((cCURLOptions=="H").and.!hb_HHasKey(self:hCURLOptions,HB_CURLOPT_TIMEOUT))
        if self:nTimeout != NIL
            curl_easy_setopt(self:phCurl,HB_CURLOPT_TIMEOUT,self:nTimeout)
        endif
    endif

    // Configure SSL based on scheme
    if self:oUrl:cProto == "https"
        if ((cCURLOptions=="H").and.!hb_HHasKey(self:hCURLOptions,HB_CURLOPT_SSL_VERIFYPEER))
            curl_easy_setopt(self:phCurl,HB_CURLOPT_SSL_VERIFYPEER,self:lVerifySSL)
        endif
        if ((cCURLOptions=="H").and.!hb_HHasKey(self:hCURLOptions,HB_CURLOPT_SSL_VERIFYHOST))
            curl_easy_setopt(self:phCurl,HB_CURLOPT_SSL_VERIFYHOST,.F.)
        endif
    endif

    // Set data for POST/PUT
    if ((cMethod$"POST|PUT").and.(!Empty(cData)))
        if ((cCURLOptions=="H").and.!hb_HHasKey(self:hCURLOptions,HB_CURLOPT_POSTFIELDS))
            curl_easy_setopt(self:phCurl,HB_CURLOPT_POSTFIELDS,cData)
        endif
    endif

    // Return header
    curl_easy_setopt(self:phCurl,HB_CURLOPT_NOBODY,.F.)

    // Return body
    curl_easy_setopt(self:phCurl,HB_CURLOPT_HEADER,.T.)

    // Execute request
    if ((self:nError:=curl_easy_perform(self:phCurl))!=HB_CURLE_OK)
        self:cError:=curl_easy_strerror(self:nError)
        // Get status code
        self:nHttpCode:=curl_easy_getinfo(self:phCurl,HB_CURLINFO_RESPONSE_CODE)
    else
        // Get status code
        self:nHttpCode:=curl_easy_getinfo(self:phCurl,HB_CURLINFO_RESPONSE_CODE)
        cResponse:=curl_easy_dl_buff_get(self:phCurl)
        nSizeHeader:=curl_easy_getinfo(self:phCurl,HB_CURLINFO_HEADER_SIZE)
        if (Empty(nSizeHeader))
            cCR:=CHR(13)
            cLF:=CHR(10)
            cCRLF:=cCR+cLF
            nCRLF:=Len(cCRLF)
            nATHeaderEnd:=AT(cCRLF+cCRLF,cResponse)  // First search for \r\r
            if (nATHeaderEnd==0)
                nCRLF:=Len(cLF)
                nATHeaderEnd:=AT(cLF+cLF,cResponse)  // If not found, try
            endif
            nATHeaderEnd+=nCRLF+1
        else
            nATHeaderEnd:=nSizeHeader
        endif
        if (nATHeaderEnd>0)
            // Get the Header
            cRespHeaders:=Left(cResponse,nATHeaderEnd)
            // Get the Body
            cResponse:=SubStr(cResponse,(nATHeaderEnd+1))
        else
            // If no break is found, assume there is no header
            cRespHeaders:=""
        endif
    endif
    return(ResponseAsHash(cResponse/*cBody*/,cRespHeaders/*cHeaders*/,self:nHttpCode/*http_status*/,self:cError/*cError*/,self:nError/*nError*/))

method Close() class TCURLHTTPConnector
    if (valType(self:phCurl)=="P")
        curl_easy_cleanup(self:phCurl)
    endif
    curl_global_cleanup()
    return(0) as numeric

method Reset() class TCURLHTTPConnector
    if (valType(self:phCurl)=="P")
        curl_easy_reset(self:phCurl)
    endif
    return(0) as numeric

method ResetAll() class TCURLHTTPConnector
    self:Reset()
    self:ClearHeaders()
    self:ClearOptions()
    return(0) as numeric

************************************************************************************************************************
// Implementation for HBTIP
class TIPHTTPConnector FROM THttpConnector

    data oClient as object

    method New(cUrl as character) constructor
    method SendRequest(cMethod as character,cData as character,cQuery as character) as hash
    method Close() as numeric
    method Reset() as numeric
    method ResetAll() as numeric

end class

method New(cUrl as character) class TIPHTTPConnector

    self:SUPER:New(cUrl)
    self:oClient:=TIpClientHttp():new(self:oUrl)
    self:oClient:nConnTimeout:=(self:nTimeout*1000)

    if (Empty(self:oClient))
        self:cError:="Failed to create HTTP client"
    endif

    return(self) as object

method SendRequest(cMethod as character,cData as character,cQuery as character) class TIPHTTPConnector

    local cBody as character
    local cHeaders as character

    local lOK as logical:=.T.

    local nStatus as numeric

    // Configure SSL
    if (self:oUrl:cProto=="https")
        self:oClient:setSSL(.T.)
        self:oClient:setSSLverify(self:lVerifySSL)
    endif

    self:oClient:hFields:=self:hHeaders

    // Send request
    if (self:oClient:Open(self:oClient:oUrl:BuildAddress()))
        switch cMethod
            case "GET"
                if (!Empty(self:oClient:oUrl:cQuery))
                    lOK:=self:oClient:Get(cQuery)
                endif
                exit
            case "POST"
                lOK:=self:oClient:Post(cData,cQuery)
                exit
        end switch
    else
        lOK:=.F.
    endif

    if (!lOK)
        self:cError:=self:oClient:LastErrorMessage()
        self:nError:=self:oClient:LastErrorCode()
        return(ResponseAsHash(/*cBody*/,/*cHeaders*/,500/*http_status*/,self:cError/*cError*/,self:nError/*nError*/))
    endif

    // Process response
    cBody:=self:oClient:readAll()
    nStatus:=self:oClient:nReplyCode
    cHeaders:=hb_JSONEncode(self:oClient:hHeaders)

    self:cError:=self:oClient:LastErrorMessage()
    self:nError:=self:oClient:LastErrorCode()

    return(ResponseAsHash(cBody/*cBody*/,cHeaders/*cHeaders*/,nStatus/*http_status*/,self:cError/*cError*/,self:nError/*nError*/))

method Close() class TIPHTTPConnector
    local nRet as numeric:=0
    if (valType(self:oClient)=="O")
        nRet:=self:oClient:Close()
    endif
    return(nRet) as numeric

method Reset() class TIPHTTPConnector
    if (valType(self:oClient)=="O")
        self:oClient:Reset()
    endif
    return(0) as numeric

method ResetAll() class TIPHTTPConnector
    self:Reset()
    self:ClearHeaders()
    return(0) as numeric

#if defined(__PLATFORM__WINDOWS)
    ************************************************************************************************************************
    // Implementation for MSXML2.ServerXMLHTTP.6.0
    class TXMLHTTPConnector FROM THttpConnector

        data oHttp as object

        method New(cUrl as character) constructor
        method SendRequest(cMethod as character,cData as character,cQuery as character)
        method Close() INLINE 0
        method Reset() INLINE 0
        method ResetAll() INLINE 0

    end class

    method New(cUrl as character) class TXMLHTTPConnector
        self:SUPER:New(cUrl)
        self:oHttp:=win_oleCreateObject("MSXML2.ServerXMLHTTP.6.0")
        if (Empty(self:oHttp))
            self:cError:="Failed to create MSXML2.ServerXMLHTTP object"
        endif
    return(self) as object

    method SendRequest(cMethod as character,cData as character,cQuery as character) class TXMLHTTPConnector

        local cFullUrl as character:=self:oUrl:BuildAddress()
        local cResponse as character:=""
        local cRespHeaders as character:=""

        local hHeader as hash

        local nStatus as numeric

        local oError as object

        HB_SYMBOL_UNUSED(cQuery)

        cMethod:=Upper(AllTrim(cMethod))

        if (Empty(self:oHttp))
            return(ResponseAsHash(/*cBody*/,/*cHeaders*/,500/*http_status*/,self:cError/*cError*/,500/*nError*/))
        endif

        BEGIN SEQUENCE WITH __BreakBlock()

            self:oHttp:Open(cMethod,cFullUrl,.F.)

            // Set headers
            for each hHeader in self:hHeaders
                self:oHttp:setRequestHeader(hHeader)
            next each //hHeader

            if (self:nTimeout!=NIL)
                self:oHttp:setTimeouts((self:nTimeout*1000),(self:nTimeout*1000),(self:nTimeout*1000),(self:nTimeout*1000))
            endif

            if (!Empty(self:cProxy))
                self:oHttp:setProxy(2,self:cProxy)
            endif

            self:oHttp:Send(cData)
            self:oHttp:WaitForResponse()

            nStatus:=self:oHttp:status
            cResponse:=self:oHttp:responseText
            cRespHeaders:=self:oHttp:getAllResponseHeaders()

            self:nError:=hb_BitAnd(self:oHttp:number,0xFFFF)
            self:cError:=self:oHttp:description

        RECOVER USING oError

            self:cError:="MSXML Error: "+oError:description
            self:nError:=500

        END SEQUENCE

        return(ResponseAsHash(cResponse/*cBody*/,cRespHeaders/*cHeaders*/,nStatus/*http_status*/,self:cError/*cError*/,self:nError/*nError*/))

    ************************************************************************************************************************
    // Class for WinHttp.WinHttpRequest.5.1
    class TWinHTTPConnector FROM THttpConnector

        data oHttp as object

        method New(cUrl as character) constructor
        method SendRequest(cMethod as character,cData as character,cQuery as character)
        method Close() INLINE 0
        method Reset() INLINE 0
        method ResetAll() INLINE 0

    end class

    method New(cUrl as character) class TWinHTTPConnector
        self:SUPER:New(cUrl)
        self:oHttp:=win_oleCreateObject("WinHttp.WinHttpRequest.5.1")
        if (Empty(self:oHttp))
            self:cError:="Failed to create WinHttpRequest object"
        endif
    return(self) as object

    method SendRequest(cMethod as character,cData as character,cQuery as character) class TWinHTTPConnector

        local cFullUrl as character:=self:oUrl:BuildAddress()
        local cResponse as character
        local cRespHeaders as character

        local hHeader as hash

        local nStatus as numeric

        local oHeaders as object

        local oError as object

        HB_SYMBOL_UNUSED(cQuery)

        if (Empty(self:oHttp))
            return(ResponseAsHash(/*cBody*/,/*cHeaders*/,500/*http_status*/,self:cError/*cError*/,500/*nError*/))
        endif

        BEGIN SEQUENCE WITH __BreakBlock()

            // Set timeout
            if (self:nTimeout!=NIL)
                self:oHttp:SetTimeouts((self:nTimeout*1000),(self:nTimeout*1000),(self:nTimeout*1000),(self:nTimeout*1000))
            endif

            // Set proxy
            if (!Empty(self:cProxy))
                self:oHttp:SetProxy(2,self:cProxy)  // 2:=HTTP_PROXY_TYPE_PRECONFIG
            endif

            // Configure SSL
            if (!self:lVerifySSL)
                //self:oHttp:Option(4):=0x3300  // Ignore certificate errors (SslErrorIgnoreFlags)
            endif

            self:oHttp:Open(cMethod,cFullUrl,.F.)

            // Set headers
            for each hHeader in self:hHeaders
                self:oHttp:SetRequestHeader(hHeader)
            next each //hHeader

            self:oHttp:Send(cData)
            self:oHttp:WaitForResponse()

            nStatus:=self:oHttp:Status
            cResponse:=self:oHttp:ResponseText

            // Get response headers
            oHeaders:=self:oHttp:GetAllResponseHeaders()
            cRespHeaders:=oHeaders:Text

            self:nError:=hb_BitAnd(self:oHttp:number,0xFFFF)
            self:cError:=self:oHttp:description

        RECOVER USING oError

            self:cError:="WinHTTP Error: "+oError:Description
            self:nError:=500

            return(ResponseAsHash(/*cBody*/,/*cHeaders*/,500/*http_status*/,self:cError/*cError*/,self:nError/*nError*/))

        END SEQUENCE

        return(ResponseAsHash(cResponse/*cBody*/,cRespHeaders/*cHeaders*/,nStatus/*http_status*/,self:cError/*cError*/,self:nError/*nError*/))
#endif

************************************************************************************************************************
static function ResponseAsHash(cBody as character,cHeaders as character,nStatus as numeric,cError as character,nError as numeric)
    hb_default(@cBody,"")
    hb_default(@cHeaders,"")
    hb_default(@nStatus,0)
    hb_default(@cError,"")
    hb_default(@nError,0)
    return(;
        { ;
             "body" => cBody;
            ,"headers" => cHeaders;
            ,"http_status" => nStatus;
            ,"has_error" => ((nError!=0).and.(nStatus==0));
            ,"conn_error"=> (nError!=0);
            ,"error_number" => nError;
            ,"error_description" => cError;
        };
    )
