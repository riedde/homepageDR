xquery version "3.1";

module namespace app="http://dennisried.de/templates";

import module namespace i18n = "http://exist-db.org/xquery/i18n" at "/db/apps/homepageDR/modules/i18n.xql";
import module namespace templates="http://exist-db.org/xquery/templates";
import module namespace config="http://exist-db.org/xquery/config" at "/db/apps/homepageDR/modules/config.xqm";
import module namespace shared="http://dennisried.de/shared" at "/db/apps/homepageDR/modules/shared.xql";

declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace mei = "http://www.music-encoding.org/ns/mei";

declare function app:about($node as node(), $model as map(*)) {
    let $lang := request:get-parameter("lang", ())
    let $doc := doc('/db/apps/homepageDR/content/about.xml')/tei:TEI
    let $person := $doc//tei:person
    
    let $forename := $person/tei:persName/tei:forename/text()
    let $surname := $person/tei:persName/tei:surname/text()
    let $email := $person//tei:email
    let $settlement := $person//tei:settlement/text()
    let $country := $person//tei:country/@key/string()
    let $orchid := $person//tei:idno[@type='ORCHID']/text()
    let $text := $doc//tei:body/tei:div[@xml:lang = $lang]/tei:p/text()
    let $socialLinks := $doc//tei:person/tei:link
    return
        <div class="resume-section-content">
        <h1 class="mb-0">{$forename}&#160;<span class="text-primary">{$surname}</span>
        </h1>
        <div class="subheading mb-5">
            {$settlement} · {shared:translate(concat('country-',$country))} · <a href="mailto:{$email}">{$email}</a>
        </div>
        <p class="lead mb-4">{$text}</p>
        <p class="lead mb-3">Orcid-ID: <a href="https://orcid.org/{$orchid}" target="_blank">{$orchid}</a></p>
        <div class="social-icons row">
            {
                for $link in $socialLinks
                    let $tokens := tokenize($link/@target,' ')
                    let $label := switch ($tokens[1])
                                    case 'facebook' return 'facebook-f'
                                    case 'linkedin' return 'linkedin-in'
                                    default return $tokens[1]
                    let $url := $tokens[2]
                    return
                        <a class="social-icon" href="{$url}" target="_blank">
                            <i class="fab fa-{$label}"/>
                        </a>
            }
        </div>
    </div>
};

declare function app:education($node as node(), $model as map(*)) {

let $lang := request:get-parameter ('lang', ())
let $doc := doc('/db/apps/homepageDR/content/about.xml')

let $eduList := $doc//tei:education

for $edu in $eduList

let $inst := $edu//tei:orgName[@xml:lang = $lang]
let $instPlace := $edu//tei:settlement
let $subject := $edu//tei:note[@type = 'subject'][@xml:lang = $lang]
let $gradeNote := $edu//tei:note[@type = 'grade'][@subtype= 'german']/text()
let $gradeGPA := $edu//tei:note[@type = 'grade'][@subtype= 'GPA']/text()
let $grade := if($lang = 'en' and $gradeGPA)
              then(concat('GPA: ', $gradeGPA))
              else if($lang = 'de' and $gradeNote and $gradeGPA)
              then('Note: ', $gradeNote, ' (GPA: ', $gradeGPA, ')')
              else if($lang = 'de' and $gradeNote)
              then('Note: ', $gradeNote)
              else()
let $dateFrom := substring($edu//tei:date/@from-custom/string(),1,4)
let $dateTo := substring($edu//tei:date/@to-custom/string(),1,4)
let $date := if($dateTo)then(concat($dateFrom, '–', $dateTo))else(concat(shared:translate('since'), ' ', $dateFrom))
return
    <div class="d-flex flex-column flex-md-row justify-content-between mb-5">
            <div class="flex-grow-1">
                <h3 class="mb-0">{$inst}&#160;{$instPlace}</h3>
                <div class="subheading mb-3">{$subject}</div>
                <p>{$grade}</p>
            </div>
            <div class="flex-shrink-0">
                <span class="text-primary">{$date}</span>
            </div>
        </div>
};

declare function app:experience($node as node(), $model as map(*)) {

let $lang := request:get-parameter ('lang', ())
let $doc := doc('/db/apps/homepageDR/content/about.xml')

let $occList := $doc//tei:occupation

for $occ in $occList

let $label := $occ//tei:label[@xml:lang = $lang]
let $org := $occ//tei:orgName[@xml:lang = $lang]
let $desc := $occ//tei:desc[@xml:lang = $lang]
let $dateFrom := substring($occ//tei:date/@from-custom/string(),1,4)
let $dateTo := substring($occ//tei:date/@to-custom/string(),1,4)
let $date := if($dateTo)then(concat($dateFrom, '–', $dateTo))else(concat(shared:translate('since'), ' ', $dateFrom))
return
    <div class="d-flex flex-column flex-md-row justify-content-between mb-5">
        <div class="flex-grow-1">
            <h3 class="mb-0">{$label}</h3>
            <div class="subheading mb-3">{$org}</div>
            <p>{$desc}</p>
        </div>
        <div class="flex-shrink-0">
            <span class="text-primary">{$date}</span>
        </div>
    </div>
};

declare function app:bibliography($node as node(), $model as map(*)) {
    let $bibliography := doc('/db/apps/homepageDR/content/bibliography.xml')/tei:TEI
    
    let $biblItems := $bibliography//tei:listBibl/tei:biblStruct
    
    let $biblTypes := distinct-values($biblItems/@type/string())
    
    for $biblType in $biblTypes
        return
            (<h3>{$biblType}</h3>,
             <ul>{for $biblItem in $biblItems[@type=$biblType]
                                let $biblType := $biblItem/@type/string()
                                return
                                   <li type="{$biblType}">{$biblItem}</li>}</ul>)
};

declare function app:conferences($node as node(), $model as map(*)) {
    let $conferences := doc('/db/apps/homepageDR/content/conferences.xml')/tei:TEI
    
    let $confItems := $conferences//tei:listEvent/tei:event
    
    let $confTypes := distinct-values($confItems/@type/string())
    
    for $confType in $confTypes
        return
            (<h3>{$confType}</h3>,
             <ul>{for $confItem in $confItems[@type=$confType]
                                let $confType := $confItem/@type/string()
                                return
                                   <li type="{$confType}">{$confItem}</li>}</ul>)
};

declare function app:skills($node as node(), $model as map(*)) {
    let $skillsDoc := doc('/db/apps/homepageDR/content/skills.xml')/tei:TEI
    let $formatText := doc('/db/apps/homepageDR/resources/xslt/tei/html5/html5.xsl')
    let $skills := $skillsDoc//tei:body
    
    return
        transform:transform($skills, $formatText, ())
    };
    
declare function app:langSwitch($node as node(), $model as map(*)) {
    let $supportedLangVals := ('de', 'en')
    for $lang in $supportedLangVals
        return
            <li class="nav-item">
                <a id="{concat('lang-switch-', $lang)}" class="nav-link" style="{if (shared:get-lang() = $lang) then ('color: white!important;') else ()}" href="?lang={$lang}" onclick="{response:set-cookie('forceLang', $lang)}">{upper-case($lang)}</a>
            </li>
};