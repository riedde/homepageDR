xquery version "3.1";

module namespace shared="http://dennisried.de/shared";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";

import module namespace i18n = "http://exist-db.org/xquery/i18n" at "/db/apps/homepageDR/modules/i18n.xql";
import module namespace app="http://dennisried.de/templates" at "/db/apps/homepageDR/modules/app.xql";

import module namespace templates="http://exist-db.org/xquery/templates";

import module namespace config="http://exist-db.org/xquery/config" at "/db/apps/homepageDR/modules/config.xqm";
(:import module namespace request="http://exist-db.org/xquery/request";:)
(:import module namespace range="http://exist-db.org/xquery/range";:)
(:import module namespace transform="http://exist-db.org/xquery/transform";:)

import module namespace functx="http://www.functx.com" at "/db/apps/homepageDR/modules/functx.xqm";
import module namespace json="http://www.json.org";
import module namespace jsonp="http://www.jsonp.org";


declare function shared:get-lang() as xs:string? {
  let $lang := if(string-length(request:get-parameter("lang", "")) gt 0) then
      (: use http parameter lang as selected language :)
      request:get-parameter("lang", "")
  else
     if(string-length(request:get-cookie-value("forceLang")) gt 0) then
       request:get-cookie-value("forceLang")
     else
       shared:get-browser-lang()
  (: limit to de and en; en default :)
  return if($lang != "en" and $lang != "de") then "en" else $lang
};


declare function shared:translate($content) {
    let $content := element i18n:text {
                        attribute key {$content}
                    }
    return
        i18n:process($content, '', '/db/apps/homepageDR/resources/lang', 'en')
};

(: Patrick integrates https://jaketrent.com/post/xquery-browser-language-detection/ :)

declare function shared:get-browser-lang() as xs:string? {
  let $header := request:get-header("Accept-Language")
  return if (fn:exists($header)) then
    shared:get-top-supported-lang(shared:get-browser-langs($header), ("de", "en"))
  else
    ()
};


declare function shared:get-top-supported-lang($ordered-langs as xs:string*, $translations as xs:string*) as xs:string? {
  if (fn:empty($ordered-langs)) then
    ()
  else
    let $lang := $ordered-langs[1]
    return if ($lang = $translations) then
      $lang
    else
      shared:get-top-supported-lang(fn:subsequence($ordered-langs, 2), $translations)
};

declare function shared:get-browser-langs($header as xs:string) as xs:string* {
  let $langs :=
    for $entry in fn:tokenize(shared:parse-header($header), ",")
    let $data := fn:tokenize($entry, "q=")
    let $quality := $data[2]
    order by
      if (fn:exists($quality) and fn:string-length($quality) gt 0) then
  xs:float($quality)
      else
  xs:float(1.0)
      descending
    return $data[1]
  return $langs
};

declare function shared:parse-header($header as xs:string) as xs:string {
  let $regex := "(([a-z]{1,8})(-[a-z]{1,8})?)\s*(;\s*q\s*=\s*(1|0\.[0-9]+))?"
  let $flags := "i"
  let $format := "$2q=$5"
  return fn:replace(fn:lower-case($header), $regex, $format)
};


declare function shared:getSelectedLanguage($node as node()*,$selectedLang as xs:string) {
    shared:get-lang()
};

