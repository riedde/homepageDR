xquery version "3.1";

module namespace app="http://dennisried.de/templates";

import module namespace i18n = "http://exist-db.org/xquery/i18n" at "/db/apps/homepageDR/modules/i18n.xql";
import module namespace templates="http://exist-db.org/xquery/templates";
import module namespace config="http://exist-db.org/xquery/config" at "/db/apps/homepageDR/modules/config.xqm";
import module namespace shared="http://dennisried.de/shared" at "/db/apps/homepageDR/modules/shared.xql";
import module namespace functx="http://www.functx.com" at "/db/apps/homepageDR/modules/functx.xqm";

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
        <!--<p class="lead mb-3">Orcid-ID: <a href="https://orcid.org/{$orchid}" target="_blank">{$orchid}</a></p>-->
        <div class="social-icons row" style="padding-left: 1em;">
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

declare function app:experience($node as node(), $model as map(*)) {

let $lang := request:get-parameter ('lang', ())
let $doc := doc('/db/apps/homepageDR/content/about.xml')

let $occList := $doc//tei:occupation

for $occ in $occList

let $label := $occ//tei:label[@xml:lang = $lang]
let $org := $occ//tei:orgName[@xml:lang = $lang]
let $desc := $occ//tei:desc[@xml:lang = $lang]
let $date := shared:getDate($occ/tei:date, 'full', $lang)
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

declare function app:education($node as node(), $model as map(*)) {

let $lang := request:get-parameter ('lang', ())
let $doc := doc('/db/apps/homepageDR/content/about.xml')

let $eduList := $doc//tei:education

for $edu in $eduList

let $inst := $edu//tei:orgName[@xml:lang = $lang]
let $instPlace := $edu//tei:settlement/text()
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
let $date := shared:getDate($edu/tei:date, 'full', $lang)

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

declare function app:bibliography($node as node(), $model as map(*)) {
    let $bibliography := doc('/db/apps/homepageDR/content/bibliography.xml')/tei:TEI
    
    let $biblItems := $bibliography//tei:listBibl/tei:biblStruct
    
    let $biblTypes := distinct-values($biblItems/@type/string())
    
    for $biblType in $biblTypes
        
        return
            (<h3>{shared:translate($biblType)}</h3>,
             <ul style="list-style: square;">{for $biblItem in $biblItems[@type=$biblType]
                  let $biblType := $biblItem/@type/string()
                  let $date := $biblItem//tei:imprint/tei:date/@when-custom/string()
                  let $titleAna := $biblItem//tei:analytic//tei:title[1]/text()
                  let $titleMono := $biblItem//tei:monogr//tei:title[1]/text()
                  order by $date descending, $titleAna ascending
                  return
                         <li style="padding: 3px;">{app:styleBibl($biblItem, $biblType)}</li>}
             </ul>)
};

declare function app:styleBibl($biblItem as node(), $biblType as xs:string) {
let $inThePipe := if($biblItem[@status="inThePipe"]) then(shared:translate('inThePipe')) else()

let $analytic := $biblItem/tei:analytic
let $monogr := $biblItem/tei:monogr
let $series := $biblItem/tei:series

let $monoTitle := $monogr/tei:title/string()
let $monoEditors := $monogr/tei:editor[not(@role)]
let $monoEditor := if(count($monoEditors)=1)
                   then($monoEditors)
                   else if (count($monoEditors) <= 3)
                   then(string-join($monoEditors, '/'))
                   else if (count($monoEditors) > 3)
                   then(concat(string-join(subsequence($monoEditors,1,2), '/'), ' et.al.'))
                   else('[N.N.]')
let $monoEditorsColl := $monogr/tei:editor[@role="collaboration"]
let $monoEditorColl := if(count($monoEditorsColl)=1)
                   then($monoEditorsColl)
                   else if (count($monoEditorsColl) <= 3)
                   then(string-join($monoEditorsColl, '/'))
                   else if (count($monoEditorsColl) > 3)
                   then(concat(string-join(subsequence($monoEditorsColl,1,2), '/'), ' et.al.'))
                   else('[N.N.]')
let $monoAuthors := $monogr/tei:author
let $monoAuthor := if(count($monoAuthors)=1)
                  then($monoAuthors)
                  else if (count($monoAuthors) <= 3)
                  then(string-join($monoAuthors, '/'))
                  else if (count($monoAuthors) > 3)
                  then(concat(string-join(subsequence($monoAuthors,1,2), '/'), ' et.al.'))
                  else('[N.N.]')

let $monoScopePages := if($monogr//tei:biblScope/@from = $monogr//tei:biblScope/@to)
                       then($monogr//tei:biblScope/@from/string())
                       else if($monogr//tei:biblScope/@from and $monogr//tei:biblScope/@to)
                       then(concat($monogr//tei:biblScope/@from, '–', $monogr//tei:biblScope/@to))
                       else()
let $monoScopeIssue := $monogr//tei:biblScope[@unit='issue']/text()
let $monoScopeVolume := $monogr//tei:biblScope[@unit='volume']/text()
let $monoPubPlace := $monogr//tei:pubPlace/text()
let $monoPubDate := $monogr//tei:date/text()
let $monoPublisher := $monogr//tei:publisher/text()

let $seriesTitle := $series/tei:title[not(@type)]
let $seriesEditors := $series/tei:editor
let $seriesEditor := if(count($seriesEditors)=1)
                  then($seriesEditors)
                  else if (count($seriesEditors) <= 3)
                  then(string-join($seriesEditors, '/'))
                  else if (count($seriesEditors) > 3)
                  then(concat(string-join(subsequence($seriesEditors,1,2), '/'), ' et.al.'))
                  else('[N.N.]')
let $seriesSection := $series/tei:biblScope[@unit="section"]
let $seriesTitleSec := $series/tei:title[@type="section"]/text()

let $anaTitle := $analytic/tei:title/text()
let $anaAuthors := $analytic/tei:author
let $anaAuthor := if(count($anaAuthors)=1)
                  then($anaAuthors)
                  else if (count($anaAuthors) <= 3)
                  then(string-join($anaAuthors, '/'))
                  else if (count($anaAuthors) > 3)
                  then(concat(string-join(subsequence($anaAuthors,1,2), '/'), ' et.al.'))
                  else('[N.N.]')
let $monogrBibl := concat(
                   if($monoAuthor)then(concat($monoAuthor, ': '))else(),
                   $monoTitle, ', ',
                   if($monoEditor)then(concat(shared:translate('editedBy'), ' ', $monoEditor, ', '))else(),
                   if($monoEditorColl)then(concat(' ', shared:translate('collaborator'), ' ', $monoEditorColl, ', '))else(),
                   if($monoScopeIssue)then(concat(shared:translate('issue'), ' ', $monoScopeIssue, ', '))else(),
                   if($monoScopeVolume)then(concat(shared:translate('volume'), ' ', $monoScopeVolume, ', '))else(),
                   if($monoPubPlace) then(concat($monoPubPlace, ' ')) else(),
                   if($monoPubDate) then($monoPubDate) else(shared:translate('noDate')),
                           if($inThePipe) then(concat(', ',$inThePipe))else())
let $analyticBibl := concat($anaAuthor, ': ', $anaTitle, ', in: ', $monogrBibl, if($monoScopePages)then(concat(', ', shared:translate('page'), ' ', $monoScopePages))else(),
                           if($inThePipe) then(concat(', ',$inThePipe))else())
let $seriesBibl := concat($seriesTitle, ', ', shared:translate('editedBy'),' ',$seriesEditor, ', ', shared:translate('section'),' ', $seriesSection, ' ', $seriesTitleSec, ', ')

let $posterBibl := concat($anaTitle, ', ', $monoPublisher, if($monoPubPlace) then(concat(', ', $monoPubPlace, ' ')) else(shared:translate('noPlace')), if($monoPubDate) then($monoPubDate) else(shared:translate('noDate')))
let $termPaperBibl := concat($monoTitle, ', ',
                   if($monoPubPlace) then(concat($monoPubPlace, ' ')) else(),
                   if($monoPubDate) then($monoPubDate) else(shared:translate('noDate')))
let $editionBibl := concat(
                           if($monoAuthor)then(concat($monoAuthor, ': '))else(),
                           $monoTitle, ', ',
                           if($monoEditor)then(concat(shared:translate('editedBy'), ' ', $monoEditor, ', '))else(),
                           if($monoScopeIssue)then(concat(shared:translate('issue'), ' ', $monoScopeIssue, ', '))else(),
                           if($monoScopeVolume)then(concat(shared:translate('volume'), ' ', $monoScopeVolume, ', '))else(),
                           if($seriesBibl) then(concat($seriesBibl, ' ')) else(),
                           if($monoPubPlace) then(concat($monoPubPlace, ' ')) else(),
                           if($monoPubDate) then($monoPubDate) else(shared:translate('noDate')),
                           if($inThePipe) then(concat(', ',$inThePipe))else())

let $monoRef := $monogr//tei:ref/@target
let $anaRef := $analytic//tei:ref/@target

return
    if($biblType = 'article' or $biblType = 'review')
    then(concat($analyticBibl, '.'))
    else if($biblType = 'book')
    then(concat($monogrBibl, '.'))
    else if($biblType = 'poster')
    then(concat($posterBibl, '.'))
    else if($biblType = 'termPaper')
    then(concat($termPaperBibl, '.'))
    else if($biblType = 'edition')
    then(concat($editionBibl, '.'))
    else()
};

declare function app:conferences($node as node(), $model as map(*)) {
    let $lang := request:get-parameter('lang', ())
    let $conferences := doc('/db/apps/homepageDR/content/conferences.xml')/tei:TEI
    
    let $confItems := $conferences//tei:listEvent/tei:event
    
    let $confTypes := distinct-values($confItems/@type/string())
    
    for $confType in $confTypes
        return
            (<h3>{$confType}</h3>,
             <ul  style="list-style: square;">{for $confItem in $confItems[@type=$confType]
                    let $confType := $confItem/@type/string()
                    let $label := $confItem//tei:label/text()
                    let $orgName := $confItem//tei:orgName/text()
                    let $settlement := $confItem//tei:settlement/text()
                    let $date := shared:getDate($confItem//tei:date, 'full', $lang)
                    let $contr := $confItem//tei:desc[@type="contribution"]/text()
                    let $contrType := $confItem//tei:desc[@type="contribution"]/@subtype/string()
                    return
                       <li style="padding: 3px;" type="{$confType}">
                            {concat(if($contr) then(concat($contr, ', ', shared:translate($contrType), ': ')) else(), $label, ', ', $orgName, ', ', $settlement, ' ', $date, '.')
                       }</li>
             }</ul>)
};

declare function app:skills($node as node(), $model as map(*)) {
    let $lang := request:get-parameter('lang', 'de')
    let $skillsDoc := doc('/db/apps/homepageDR/content/skills.xml')/tei:TEI
    let $formatText := doc('/db/apps/homepageDR/resources/xslt/formattingText.xsl')
    let $skills := $skillsDoc//tei:body/tei:div[@xml:lang=$lang]
    
    return
        transform:transform($skills, $formatText, ())
};

declare function app:commitment($node as node(), $model as map(*)) {
    let $lang := request:get-parameter('lang', 'de')
    let $commitmentDoc := doc('/db/apps/homepageDR/content/commitment.xml')/tei:TEI
    let $formatText := doc('/db/apps/homepageDR/resources/xslt/formattingText.xsl')
    let $commitment := $commitmentDoc//tei:listEvent/tei:event
    let $orgs := $commitmentDoc//tei:listOrg/tei:org
    
    return
        (<h3>{shared:translate('projects')}</h3>,
         <ul style="list-style: square;">{for $project in $commitment
                let $label := $project//tei:label[@xml:lang = $lang]
                let $date := if($project//tei:date) then(shared:getDate($project//tei:date, 'full', $lang)) else()
                return
                   <li style="padding: 3px;">{$date} | {transform:transform($label, $formatText, ())}</li>}
        </ul>,
        <h3>{shared:translate('organisations')}</h3>,
         <ul style="list-style: square;">{for $org in $orgs
                let $label := $org//tei:label[@xml:lang = $lang]
                let $date := if($org//tei:date) then(shared:getDate($org//tei:date, 'full', $lang)) else()
                return
                   <li style="padding: 3px;">{transform:transform($label, $formatText, ())}</li>}
        </ul>)
};

declare function app:langSwitch($node as node(), $model as map(*)) {
    let $supportedLangVals := ('de', 'en')
    for $lang in $supportedLangVals
        return
            <li class="nav-item">
                <a id="{concat('lang-switch-', $lang)}"
                   class="nav-link {if(shared:get-lang() = $lang) then('active')else('')}"
                   style="{if (shared:get-lang() = $lang) then ('color: white!important; font-weight: bold;') else ()}"
                   href="?lang={$lang}"
                   onclick="{response:set-cookie('forceLang', $lang, 'P1D', true())}">{upper-case($lang)}</a>
            </li>
};
