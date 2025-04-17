/*
 _      _    _                                                     _                    _         _
| |__  | |_ | |_  _ __       ___   ___   _ __   _ __    ___   ___ | |_   ___   _ __    | |_  ___ | |_
| '_ \ | __|| __|| '_ \     / __| / _ \ | '_ \ | '_ \  / _ \ / __|| __| / _ \ | '__|   | __|/ __|| __|
| | | || |_ | |_ | |_) |   | (__ | (_) || | | || | | ||  __/| (__ | |_ | (_) || |      | |_ \__ \| |_
|_| |_| \__| \__|| .__/     \___| \___/ |_| |_||_| |_| \___| \___| \__| \___/ |_|       \__||___/ \__|
                 |_|

Released to Public Domain.
--------------------------------------------------------------------------------------

*/

#include "hbcurl.ch"

#require "hbct"

REQUEST HB_CODEPAGE_UTF8EX

FUNCTION Main()

    local cCDP as character
    local cData  as character
    local cQuery as character
    local cResponse as character

    local hResponse as hash

    local oHTTPConnector as object

    #ifdef __ALT_D__    // Compile with -b -D__ALT_D__
        AltD(1)         // Enables the debugger. Press F5 to continue.
        AltD()          // Invokes the debugger
    #endif

    cCDP:=hb_cdpSelect("UTF8EX")

    #pragma __cstream|cData:=%s
    {
    "model": "gemma-3-4b-it",
    "messages": [
      { "role": "system", "content": "Always answer in rhymes. Today is Thursday" },
      { "role": "user", "content": "What day is it today?" }
    ],
    "temperature": 0.7,
    "max_tokens": -1,
    "stream": false
}
    #pragma __endtext

    // POST Usando TIP
    ? "POST Usando TIP",hb_eol()
    oHTTPConnector:=TIPHTTPConnector():New("http://127.0.0.1:1234/v1/chat/completions")
    oHTTPConnector:SetHeader("Accept", "application/json")
    oHTTPConnector:SetHeader("Content-Type","application/json")
    hResponse:=oHTTPConnector:SendRequest("POST",cData)
    oHTTPConnector:Close()
    cResponse:=hb_JSONEncode(hResponse,.T.)
    ? cResponse,hb_eol()

    ? Replicate("=",MaxCol())

    // GET Usando TIP
    ? "GET Usando TIP",hb_eol()
    oHTTPConnector:=TIPHTTPConnector():New(iif(tip_SSL(),"https","http")+"://duckduckgo.com/html/")
    oHTTPConnector:SetHeader("Accept", "text/html; charset=UTF-8")
    oHTTPConnector:SetHeader("Content-Type","text/html; charset=UTF-8")
    oHTTPConnector:oURL:addGetForm( { ;
      "q"  => "Harbour+Project", ;
      "kl" => "us-en" } )
    hResponse:=oHTTPConnector:SendRequest("GET")
    oHTTPConnector:Close()
    ? "headers",hb_eol(),hResponse["headers"],hb_eol()
    ? "body",hb_eol(),hResponse["body"],hb_eol()
    ? "http_status",hb_eol(),hResponse["http_status"],hb_eol()
    ? "has_error",hb_eol(),hResponse["has_error"],hb_eol()
    ? "conn_error",hb_eol(),hResponse["conn_error"],hb_eol()
    ? "error_number",hb_eol(),hResponse["error_number"],hb_eol()
    ? "error_description",hb_eol(),hResponse["error_description"],hb_eol()

    ? Replicate("=",MaxCol())

    // GET Usando TIP
    ? "GET Usando TIP",hb_eol()
    oHTTPConnector:=TIPHTTPConnector():New("http://127.0.0.1:1234/v1/models")
    oHTTPConnector:SetHeader("Accept", "text/html; charset=UTF-8")
    oHTTPConnector:SetHeader("Content-Type","text/html; charset=UTF-8")
    hResponse:=oHTTPConnector:SendRequest("GET")
    oHTTPConnector:Close()
    ? "headers",hb_eol(),hResponse["headers"],hb_eol()
    ? "body",hb_eol(),hResponse["body"],hb_eol()
    ? "http_status",hb_eol(),hResponse["http_status"],hb_eol()
    ? "has_error",hb_eol(),hResponse["has_error"],hb_eol()
    ? "conn_error",hb_eol(),hResponse["conn_error"],hb_eol()
    ? "error_number",hb_eol(),hResponse["error_number"],hb_eol()
    ? "error_description",hb_eol(),hResponse["error_description"],hb_eol()

    ? Replicate("=",MaxCol())

    // POST Usando CURL
    ? "POST Usando CURL",hb_eol()
    oHTTPConnector:=TCURLHTTPConnector():New("http://127.0.0.1:1234/v1/chat/completions")
    oHTTPConnector:SetHeader("Accept", "application/json")
    oHTTPConnector:SetHeader("Content-Type","application/json")
    oHTTPConnector:SetOption(HB_CURLOPT_USERNAME,"")
    oHTTPConnector:SetOption(HB_CURLOPT_DL_BUFF_SETUP)
    oHTTPConnector:SetOption(HB_CURLOPT_SSL_VERIFYPEER,.F.)
    /* enable all supported built-in compressions */
    oHTTPConnector:SetOption(HB_CURLOPT_ACCEPT_ENCODING,"")
    hResponse:=oHTTPConnector:SendRequest("POST",cData)
    oHTTPConnector:Close()
    cResponse:=hb_JSONEncode(hResponse,.T.)
    ? cResponse,hb_eol()

    ? Replicate("=",MaxCol())

    // GET Usando CURL
    ? "GET Usando CURL",hb_eol()
    oHTTPConnector:=TCURLHTTPConnector():New(iif(tip_SSL(),"https","http")+"://duckduckgo.com/html/")
    oHTTPConnector:SetHeader("Accept", "text/html; charset=UTF-8")
    oHTTPConnector:SetHeader("Content-Type","text/html; charset=UTF-8")
    oHTTPConnector:SetOption(HB_CURLOPT_USERNAME,"")
    oHTTPConnector:SetOption(HB_CURLOPT_DL_BUFF_SETUP)
    oHTTPConnector:SetOption(HB_CURLOPT_SSL_VERIFYPEER,.F.)
    /* enable all supported built-in compressions */
    oHTTPConnector:SetOption(HB_CURLOPT_ACCEPT_ENCODING,"")
    cQuery:=oHTTPConnector:oURL:addGetForm( { ;
          "q"  => "Harbour+Project", ;
          "kl" => "us-en" } )
    oHTTPConnector:oURL:SetAddress(oHTTPConnector:oURL:cAddress+"?"+cQuery)
    hResponse:=oHTTPConnector:SendRequest("GET")
    oHTTPConnector:Close()
    ? "headers",hb_eol(),hResponse["headers"],hb_eol()
    ? "body",hb_eol(),hResponse["body"],hb_eol()
    ? "http_status",hb_eol(),hResponse["http_status"],hb_eol()
    ? "has_error",hb_eol(),hResponse["has_error"],hb_eol()
    ? "conn_error",hb_eol(),hResponse["conn_error"],hb_eol()
    ? "error_number",hb_eol(),hResponse["error_number"],hb_eol()
    ? "error_description",hb_eol(),hResponse["error_description"],hb_eol()

    // GET Usando CURL
    ? "GET Usando CURL",hb_eol()
    oHTTPConnector:=TCURLHTTPConnector():New("http://127.0.0.1:1234/v1/models")
    oHTTPConnector:SetHeader("Accept", "text/html; charset=UTF-8")
    oHTTPConnector:SetHeader("Content-Type","text/html; charset=UTF-8")
    oHTTPConnector:SetOption(HB_CURLOPT_USERNAME,"")
    oHTTPConnector:SetOption(HB_CURLOPT_DL_BUFF_SETUP)
    oHTTPConnector:SetOption(HB_CURLOPT_SSL_VERIFYPEER,.F.)
    /* enable all supported built-in compressions */
    oHTTPConnector:SetOption(HB_CURLOPT_ACCEPT_ENCODING,"")
    hResponse:=oHTTPConnector:SendRequest("GET")
    oHTTPConnector:Close()
    ? "headers",hb_eol(),hResponse["headers"],hb_eol()
    ? "body",hb_eol(),hResponse["body"],hb_eol()
    ? "http_status",hb_eol(),hResponse["http_status"],hb_eol()
    ? "has_error",hb_eol(),hResponse["has_error"],hb_eol()
    ? "conn_error",hb_eol(),hResponse["conn_error"],hb_eol()
    ? "error_number",hb_eol(),hResponse["error_number"],hb_eol()
    ? "error_description",hb_eol(),hResponse["error_description"],hb_eol()

#if defined(__PLATFORM__WINDOWS)

    // POST Usando TXMLHTTPConnector
    ? "POST Usando TXMLHTTPConnector",hb_eol()
    oHTTPConnector:=TXMLHTTPConnector():New("http://127.0.0.1:1234/v1/chat/completions")
    oHTTPConnector:SetHeader("Accept", "application/json")
    oHTTPConnector:SetHeader("Content-Type","application/json")
    hResponse:=oHTTPConnector:SendRequest("POST",cData)
    oHTTPConnector:Close()
    cResponse:=hb_JSONEncode(hResponse,.T.)
    ? cResponse,hb_eol()

    ? Replicate("=",MaxCol())

    // GET Usando TXMLHTTPConnector
    ? "GET Usando TXMLHTTPConnector",hb_eol()
    oHTTPConnector:=TXMLHTTPConnector():New(iif(tip_SSL(),"https","http")+"://duckduckgo.com/html/")
    oHTTPConnector:SetHeader("Accept", "text/html; charset=UTF-8")
    oHTTPConnector:SetHeader("Content-Type","text/html; charset=UTF-8")
    oHTTPConnector:oURL:addGetForm( { ;
      "q"  => "Harbour+Project", ;
      "kl" => "us-en" } )
    hResponse:=oHTTPConnector:SendRequest("GET")
    oHTTPConnector:Close()
    ? "headers",hb_eol(),hResponse["headers"],hb_eol()
    ? "body",hb_eol(),hResponse["body"],hb_eol()
    ? "http_status",hb_eol(),hResponse["http_status"],hb_eol()
    ? "has_error",hb_eol(),hResponse["has_error"],hb_eol()
    ? "conn_error",hb_eol(),hResponse["conn_error"],hb_eol()
    ? "error_number",hb_eol(),hResponse["error_number"],hb_eol()
    ? "error_description",hb_eol(),hResponse["error_description"],hb_eol()

    // POST Usando TXMLHTTPConnector
    ? "POST Usando TXMLHTTPConnector",hb_eol()
    oHTTPConnector:=TXMLHTTPConnector():New("http://127.0.0.1:1234/v1/chat/completions")
    oHTTPConnector:SetHeader("Accept", "application/json")
    oHTTPConnector:SetHeader("Content-Type","application/json")
    hResponse:=oHTTPConnector:SendRequest("POST",cData)
    oHTTPConnector:Close()
    cResponse:=hb_JSONEncode(hResponse,.T.)
    ? cResponse,hb_eol()

    ? Replicate("=",MaxCol())

    // GET Usando TWinHTTPConnector
    ? "GET Usando TWinHTTPConnector",hb_eol()
    oHTTPConnector:=TWinHTTPConnector():New(iif(tip_SSL(),"https","http")+"://duckduckgo.com/html/")
    oHTTPConnector:SetHeader("Accept", "text/html; charset=UTF-8")
    oHTTPConnector:SetHeader("Content-Type","text/html; charset=UTF-8")
    oHTTPConnector:oURL:addGetForm( { ;
      "q"  => "Harbour+Project", ;
      "kl" => "us-en" } )
    hResponse:=oHTTPConnector:SendRequest("GET")
    oHTTPConnector:Close()
    ? "headers",hb_eol(),hResponse["headers"],hb_eol()
    ? "body",hb_eol(),hResponse["body"],hb_eol()
    ? "http_status",hb_eol(),hResponse["http_status"],hb_eol()
    ? "has_error",hb_eol(),hResponse["has_error"],hb_eol()
    ? "conn_error",hb_eol(),hResponse["conn_error"],hb_eol()
    ? "error_number",hb_eol(),hResponse["error_number"],hb_eol()
    ? "error_description",hb_eol(),hResponse["error_description"],hb_eol()

#endif

    hb_cdpSelect(cCDP)

    RETURN NIL
