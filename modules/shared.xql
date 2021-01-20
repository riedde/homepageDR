xquery version "3.1";

module namespace shared="http://dennisried.de/shared";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";

import module namespace app="http://dennisried.de/templates" at "/db/apps/homepageDR/modules/app.xql";

import module namespace templates="http://exist-db.org/xquery/templates";
import module namespace i18n = "http://exist-db.org/xquery/i18n" at "/db/apps/homepageDR/modules/i18n.xql";

import module namespace config="http://exist-db.org/xquery/config" at "/db/apps/homepageDR/modules/config.xqm";
import module namespace request="http://exist-db.org/xquery/request";
import module namespace range="http://exist-db.org/xquery/range";
import module namespace transform="http://exist-db.org/xquery/transform";

import module namespace functx="http://www.functx.com" at "/db/apps/homepageDR/modules/functx.xqm";
import module namespace json="http://www.json.org";
import module namespace jsonp="http://www.jsonp.org";


declare variable $shared:xsltTEI as document-node() := doc('xmldb:exist:///db/apps/baudiApp/resources/xslt/tei/html5/html5.xsl');


(:~ 
: MRP Main Nav lang switch
:
: @param $node the processed node
: @param $model the model
:
: @return html <li/>-Elements
:)

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


(:~ 
: i18n text from a TEI file
:
: @param $doc the docuemtent node to process
:
: @return html
:)

declare function shared:getI18nText($doc) {
    let $lang := shared:get-lang()
    return
        if ($lang != 'de')
        then (
            
            (: Is there tei:div[@xml:lang] ?:)
            if (exists($doc//tei:body/tei:div[@xml:lang]))
            then (
            
                (: Is there a $lang summary? :)
                if ($doc//tei:body/tei:div[@xml:lang = $lang and exists(@type = 'summary')])
                then (
                    transform:transform($doc//tei:body/tei:div[@xml:lang = $lang and @type = 'summary'], $shared:xsltTEI, ()),
                    transform:transform($doc//tei:body/tei:div[@xml:lang = 'de'], $shared:xsltTEI, ())
                )
                
                (: No $lang or 'en' summary but $lang tei:div (text)? :)
                else if ($doc//tei:body/tei:div[@xml:lang = $lang])
                then (
                    transform:transform($doc//tei:body/tei:div[@xml:lang = $lang], $shared:xsltTEI, ())
                )
            
                (: Is there no $lang summary but an 'en' summary? :)
                else if ($doc//tei:body/tei:div[@xml:lang = 'en' and exists(@type = 'summary')])
                then (
                    transform:transform($doc//tei:body/tei:div[@xml:lang = 'en' and @type = 'summary'], $shared:xsltTEI, ()),
                    transform:transform($doc//tei:body/tei:div[@xml:lang = 'de'], $shared:xsltTEI, ())
                )
                
                (: No summary but 'en' tei:div (text)? :)
                else if ($doc//tei:body/tei:div[@xml:lang = 'en'])
                then (
                    transform:transform($doc//tei:body/tei:div[@xml:lang = 'en'], $shared:xsltTEI, ())
                )
            
                (: There is no other tei:div than 'de' :)
                else (
                    transform:transform($doc//tei:body/tei:div[@xml:lang = 'de'], $shared:xsltTEI, ())
                )
        
            )
            
            (: No tei:div[@xml:lang]:)
            else (transform:transform($doc//tei:body/tei:div, $shared:xsltTEI, ()))
        )
        
        (: $lang = 'de' :)
        else (
            if (exists($doc//tei:body/tei:div[@xml:lang]))
            then (transform:transform($doc//tei:body/tei:div[@xml:lang = $lang]/*, $shared:xsltTEI, ()))
            else (transform:transform($doc//tei:body/tei:div, $shared:xsltTEI, ()))
        )
};


declare function shared:translate($content) {
    let $content := element i18n:text {
                        attribute key {$content}
                    }
    return
        i18n:process($content, '', '/db/apps/homepageDR/resources/lang', 'en')
};


(: DATES:)


(:~
: Return month names from month numbers in dates
:
: @param $monthNo the number of month (1…12)
: @param $lang the requested language
:
: @return a month name.
:
:)

declare function shared:monthName($monthNo as xs:integer) as xs:string {
    let $lang := shared:get-lang()

    return
    if ($lang = 'de')
    then (
        ('Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember')[$monthNo]
    )
    else (
        ('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December')[$monthNo]
    )
};


(:~
: Format our custom dates
:
: @param $dateVal the string with custom date to be analyzed, picture 0000-00-00
:
: @return a date string.
:
:)

declare function shared:customDate($dateVal as xs:string) as xs:string {
    let $dateValT := tokenize($dateVal, '-')
    let $hasDay := if (number($dateValT[3]) > 0)
                    then (number($dateValT[3]))
                    else ()
    let $hasMonth := if (number($dateValT[2]) > 0)
                        then (number($dateValT[2]))
                        else ()
    let $hasYear := if (number($dateValT[1]) > 0)
                    then (number($dateValT[1]))
                    else ()
    return
        if ($hasDay and $hasMonth and $hasYear)
        then (xs:date($dateVal))
        else if ($hasMonth and $hasYear)
        then (
            concat(
                shared:monthName($dateValT[2]),
                ' ',
                $dateValT[1],
                ' [',
                shared:translate('mriCat.entry.postalObject.date.day'),
                ' ',
                shared:translate('unknown'),
                ']'
            )
        )
        else if ($hasDay and $hasMonth)
        then (
            concat(
                format-number($dateValT[3], '0'),
                '.&#160;',
                shared:monthName($dateValT[2]),
                ', [',
                shared:translate('mriCat.entry.postalObject.date.year'),
                ' ',
                shared:translate('unknown'),
                ']'
            )
        )
        else if ($hasMonth)
        then (
            concat(
                shared:monthName($dateValT[2]),
                ', [',
                shared:translate('mriCat.entry.postalObject.date.day'),
                '/',
                shared:translate('mriCat.entry.postalObject.date.year'),
                ' ',
                shared:translate('unknown'),
                ']'
            )
        )
        else if ($hasDay)
        then (
            concat(
                format-number($dateValT[3], '0'),
                '., [',
                shared:translate('mriCat.entry.postalObject.date.month'),
                '/',
                shared:translate('mriCat.entry.postalObject.date.year'),
                ' ',
                shared:translate('unknown'),
                ']'
            )
        )
        else if ($hasYear)
        then (
            concat(
                $dateValT[1],
                ', [',
                shared:translate('mriCat.entry.postalObject.date.day'),
                '/',
                shared:translate('mriCat.entry.postalObject.date.month'),
                ' ',
                shared:translate('unknown'),
                ']'
            )
        )
        else (shared:translate('mriCat.entry.postalObject.date.type.undated'))

};


(:~
: Format xs:date with respect to language and desired form
:
: @param $date the date
: @param $form the form (e.g. full, short, …)
: @param $lang the requested language
:
: @return a i18n date string.
:
: ToDo: find the right type of $date for shared:getBirthDeathDates
:
:)

declare function shared:formatDate($date, $form as xs:string, $lang as xs:string) as xs:string {
    let $date := if (functx:atomic-type($date) = 'xs:date')
                    then ($date)
                    else ($date/@when/string())
    return
        if ($form = 'full')
        then (format-date($date, "[D1o]&#160;[MNn]&#160;[Y]", $lang, (), ()))
        else (format-date($date, "[D].[M].[Y]", $lang, (), ()))
};


(:~
: Shorten (if possible) and format two xs:date with respect to language and desired form
:
: @param $dateFrom the start date
: @param $dateTo the end date
: @param $form the form (e.g. full, short, …)
: @param $lang the requested language
:
: @return a i18n date string.
:
: ToDo: find the right type of $date for shared:getBirthDeathDates
:
:)

declare function shared:shortenAndFormatDates($dateFrom, $dateTo, $form as xs:string, $lang as xs:string) as xs:string {
    if ($form = 'full' and (month-from-date($dateFrom) = month-from-date($dateTo)) and (year-from-date($dateFrom) = year-from-date($dateTo)))
    then (
        concat(
            day-from-date($dateFrom), '.–', day-from-date($dateTo), '. ',
            format-date($dateFrom, "[MNn] [Y]", $lang, (), ())
        )
    )
    else if ($form = 'full' and (year-from-date($dateFrom) = year-from-date($dateTo)))
    then (
        concat(
            day-from-date($dateFrom), '. ', format-date($dateFrom, "[MNn]", $lang, (), ()),
            '–',
            day-from-date($dateTo), '. ', format-date($dateTo, "[MNn] ", $lang, (), ()),
            year-from-date($dateFrom)
        )
    )
    else if ($form = 'full')
    then (
        concat(
            format-date($dateFrom, "[D]. [MNn] [Y]", $lang, (), ()),
            '–',
            format-date($dateTo, "[D]. [MNn] [Y]", $lang, (), ())
        )
    )
    else (
        concat(
            format-date($dateFrom, "[D].[M].[Y]", $lang, (), ()),
            '–',
            format-date($dateTo, "[D].[M].[Y]", $lang, (), ())
        )
    )
};


declare function shared:getBirthDeathDates($dates, $lang) {
    let $date := if ($dates/tei:date)
                        then (shared:formatDate($dates/tei:date, 'full', $lang))
                        else ()
    let $datePlace := if ($dates/tei:placeName/text())
                        then (normalize-space($dates/tei:placeName/text()))
                        else ()
    return
        if ($date and $datePlace)
        then (concat($date, ', ', $datePlace))
        else if ($date)
        then ($date)
        else if ($date = '' and $datePlace = '')
        then (shared:translate('unknown'))
        else if ($datePlace)
        then (concat($datePlace, ', ', shared:translate('dateUnknown')))
        else (shared:translate('unknown'))
};

declare function shared:any-equals-any($args as xs:string*, $searchStrings as xs:string*) as xs:boolean {
    some $arg in $args
    satisfies
        some $searchString in $searchStrings
        satisfies
            $arg = $searchString
};

declare function shared:queryKey() {
  functx:substring-before-if-contains(concat(request:get-uri(), request:get-query-string()), "firstRecord")
};


declare %templates:wrap function shared:readCache($node as node(), $model as map(*), $cacheName as xs:string) {
    doc(concat('xmldb:exist:///db/apps/mriCat/caches/', $cacheName, '.xml'))/*
};


(: Patrick integrates https://jaketrent.com/post/xquery-browser-language-detection/ :)

declare function shared:get-browser-lang() as xs:string? {
  let $header := request:get-header("Accept-Language")
  return if (fn:exists($header)) then
    shared:get-top-supported-lang(shared:get-browser-langs($header), ("de", "en"))
  else
    ()
};

(:declare function shared:get-lang() as xs:string? {
  let $lang := if(string-length(request:get-parameter("lang", "")) gt 0) then
      (\: use http parameter lang as selected language :\)
      request:get-parameter("lang", "")
  else
     if(string-length(request:get-cookie-value("forceLang")) gt 0) then
       request:get-cookie-value("forceLang")
     else
       shared:get-browser-lang()
  (\: limit to de and en; en default :\)
  return if($lang != "en" and $lang != "de") then "en" else $lang
};:)

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


declare function shared:stringJoinAll($node as node()) {
    string-join($node/string(),' | ')
};

declare function shared:getPersNameFull($person as node()) {

    let $forename := $person/tei:persName/tei:forename[@type='used'][1]
    let $surname :=  $person/tei:persName/tei:surname[@type='used'][1]
    let $name := if($surname and $forename)
                                 then(concat($surname,', ',$forename))
                                 else if($surname and not($forename))
                                 then($surname)
                                 else if (not($surname) and $forename)
                                 then($forename)
                                 else($person/tei:persName)
    
    return
        $name
};

declare function shared:getPersNameShort($person as node()) {

    let $forename := $person/tei:persName/tei:forename
    let $surname :=  $person/tei:persName/tei:surname
    let $name := if($surname and $forename)
                 then(concat(string-join($surname, ' '),', ',string-join($forename,' ')))
                 else if($surname and not($forename))
                 then(string-join($surname,' '))
                 else if (not($surname) and $forename)
                 then(string-join($forename, ' '))
                 else($person/tei:persName)
    
    return
        $name
};

declare function shared:getPersNameFullLinked($person as node()) {

    let $personID := $person/@xml:id
    let $personUri := concat($app:dbRoot, '/person/', $personID)
    let $name := shared:getPersNameFull($person)
    
    return
        <a href="{$personUri}">{$name}</a>
};

declare function shared:getPersNameShortLinked($person as node()) {
    
    let $personID := $person/@xml:id
    let $personUri := concat($app:dbRoot, '/person/', $personID)
    let $name := shared:getPersNameShort($person)
    
    return
        <a href="{$personUri}">{$name}</a>
};

declare function shared:getPersonaLinked($id as xs:string) {
    
    let $personRecord := $app:collectionPersons[@xml:id = $id]
    let $personLink := concat($app:dbRoot, '/person/', $id)
    let $forename := $personRecord/tei:persName/tei:forename
    let $surname :=  $personRecord/tei:persName/tei:surname
    let $name := if($surname and $forename)
                 then(string-join(($forename, $surname),' '))
                 else if($surname and not($forename))
                 then(string-join($surname,' '))
                 else if (not($surname) and $forename)
                 then(string-join($forename, ' '))
                 else()
    
    return
        if($name)
        then(<a href="{$personLink}">{$name}</a>)
        else (shared:translate('baudi.catalog.persons.unknown'))
};

declare function shared:getOrgNameFull($org as node()) {

    let $name := string-join($org/tei:orgName[1]/text(), ' ')
    
    return
        $name
};

declare function shared:getOrgNameFullLinked($org as node()) {

    let $orgID := $org/@xml:id
    let $orgUri := concat($app:dbRoot, '/institution/', $orgID)
    let $name := shared:getOrgNameFull($org)
    
    return
        <a href="{$orgUri}">{$name}</a>
};

declare function shared:getCorpNameFullLinked($corpName as node()) {

    let $corpID := $corpName/@auth/string()
    let $corpUri := concat($app:dbRoot, '/institution/', $corpID)
    let $nameFound := $app:collectionInstitutions[matches(@xml:id, $corpID)]//tei:orgName[1]/text()
    let $name := if($nameFound) then($nameFound) else($corpName)
    
    return
        <a href="{$corpUri}">{$name}</a>
};

declare function shared:getName($key as xs:string, $param as xs:string){

    let $person :=$app:collectionPersons[range:field-eq("person-id", $key)]
    let $institution := $app:collectionInstitutions[range:field-eq("institution-id", $key)]
    let $nameForename := $person//tei:forename[matches(@type,"^used")][1]/text()[1]
    let $nameNameLink := $person//tei:nameLink[1]/text()[1]
    let $nameSurname := $person//tei:surname[matches(@type,"^used")][1]/text()[1]
    let $nameGenName := $person//tei:genName/text()
    let $nameAddNameTitle := $person//tei:addName[matches(@type,"^title")][1]/text()[1]
    let $nameAddNameEpitet := $person//tei:addName[matches(@type,"^epithet")][1]/text()[1]
    let $pseudonym := if ($person//tei:forename[matches(@type,'^pseudonym')] or $person//tei:surname[matches(@type,'^pseudonym')])
                      then (concat($person//tei:forename[matches(@type,'^pseudonym')], ' ', $person//tei:surname[matches(@type,'^pseudonym')]))
                      else ()
    let $nameRoleName := $person//tei:roleName[1]/text()[1]
    let $nameAddNameNick := $person//tei:addName[matches(@type,"^nick")][1]/text()[1]
    let $affiliation := $person//tei:affiliation[1]/text()
    let $nameUnspecified := $person//tei:name[matches(@type,'^unspecified')][1]/text()[1]
    let $nameUnspec := if($affiliation and $nameUnspecified)
                       then(concat($nameUnspecified, ' (',$affiliation,')'))
                       else($nameUnspecified)
    let $institutionName := $institution//tei:org/tei:orgName/text()
    
    let $name := if ($person)
                 then(
                      if($person and $param = 'full')
                      then(
                            if(not($nameForename) and not($nameNameLink) and not($nameUnspec))
                            then($nameRoleName)
                            else(string-join(($nameAddNameTitle, $nameForename, $nameAddNameEpitet, $nameNameLink, $nameSurname, $nameUnspec, $nameGenName), ' '))
                          )
                          
                      else if($person and $param = 'short')
                      then(
                           string-join(($nameForename, $nameNameLink, $nameSurname, $nameUnspec, $nameGenName), ' ')
                          )
                          
                      else if($person and $param = 'reversed')
                      then(
                            if($nameSurname)
                            then(
                                concat($nameSurname, ', ',string-join(($nameForename, $nameNameLink), ' '),
                                if($nameGenName) then(concat(' (',$nameGenName,')')) else())
                                )
                            else (
                                    if(not($nameForename) and not($nameNameLink) and not($nameUnspec))
                                    then($nameRoleName)
                                    else(
                                           string-join(($nameForename, $nameNameLink, $nameUnspec), ' '),
                                           if($nameGenName) then(concat(' (',$nameGenName,')')) else()
                                        )
                            )
                           )
                           
                      else ('[NoPersonFound]')
                     )
                 else if($institution)
                 then($institutionName)
                 else('[NoInstitutionFound]')
    return
       $name
};

declare function shared:linkAll($node as node()){
    transform:transform($node,doc('/db/apps/baudiApp/resources/xslt/linking.xsl'),())
};