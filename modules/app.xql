xquery version "3.1";

module namespace app="http://dennisried.de/templates";

import module namespace i18n = "http://exist-db.org/xquery/i18n" at "/db/apps/homepageDR/modules/i18n.xql";
import module namespace templates="http://exist-db.org/xquery/templates";
import module namespace config="http://exist-db.org/xquery/config" at "/db/apps/homepageDR/modules/config.xqm";
import module namespace shared="http://dennisried.de/shared" at "/db/apps/homepageDR/modules/shared.xql";
import module namespace functx="http://www.functx.com" at "/db/apps/homepageDR/modules/functx.xqm";

declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace mei = "http://www.music-encoding.org/ns/mei";

declare variable $app:contentBasePath := '/db/apps/homepageDRContent/data/';
declare variable $app:formatText := doc('/db/apps/homepageDR/resources/xslt/formattingText.xsl');


declare function app:about($node as node(), $model as map(*)) {
    let $lang := request:get-parameter("lang", 'de')
    let $doc := doc($app:contentBasePath || 'about.xml')/tei:TEI
    let $person := $doc//tei:person
    
    let $forename := $person/tei:persName/tei:forename/text()
    let $surname := $person/tei:persName/tei:surname/text()
    let $email := $person//tei:email
    let $settlement := $person//tei:settlement/text()
    let $country := $person//tei:country/@key/string()
    let $orchid := $person//tei:idno[@type='ORCID']/text()
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

let $lang := request:get-parameter ('lang', 'de')
let $doc := doc($app:contentBasePath || 'about.xml')

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

let $lang := request:get-parameter ('lang', 'de')
let $doc := doc($app:contentBasePath || 'about.xml')

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
    let $biblItems := collection($app:contentBasePath)//tei:biblStruct
    let $biblTypes := distinct-values($biblItems/@type/string())
    
    for $biblType at $i in $biblTypes
        let $biblTypeSort := switch ($biblType)
                                case 'qualification' return '01'
                                case 'article' return '02'
                                case 'edition' return '03'
                                case 'software' return '04'
                                case 'poster' return '05'
                                case 'review' return '06'
                                case 'termPaper' return '07'
                                default return $biblType
        let $biblItems := $biblItems[@type=$biblType]
        let $biblItems := for $biblItem at $n in $biblItems
                              let $biblType := $biblItem/@type/string()
                              let $date := $biblItem//tei:imprint/tei:date/@when-custom/string()
                              let $titleAna := $biblItem//tei:analytic//tei:title[1]/text()
                              let $titleMono := $biblItem//tei:monogr//tei:title[1]/text()
                              order by $date descending, $titleAna ascending
                              return
                                <li style="padding: 3px;" id="{$biblItem/root()/node()/@xml:id}">{app:styleBibl($biblItem, $biblType)}</li>
        order by $biblTypeSort
        return
           (<h3>{shared:translate($biblType)} ({count($biblItems)})</h3>,
            <ul style="list-style: square;">
                {for $biblItem at $n in $biblItems
                    where $n lt 6
                    return
                        $biblItem
                }
            </ul>,
            if(count($biblItems) gt 5)
            then(
                <ul style="list-style: none">
                    <li class="btn btn-primary" type="button" data-toggle="collapse" data-target="#biblReadMore-{$i}" aria-expanded="false" aria-controls="collapseExample">{shared:translate('moreItems')}</li>
                </ul>,
                <ul class="collapse" id="biblReadMore-{$i}" style="list-style: square;">
                    {for $biblItem at $n in $biblItems
                    where $n gt 5
                    return
                        $biblItem
                }
                </ul>
                )
            else()
           )
};

declare function app:joinNames($names as node()*) as xs:string? {
    if(count($names)=1)
    then($names)
    else if (count($names) <= 3)
    then(string-join($names, ' / '))
    else if (count($names) > 3)
    then(concat(string-join(subsequence($names,1,2), ' / '), ' et.al.'))
    else('[N.N.]')

};



declare function app:styleBibl($biblItem as node(), $biblType as xs:string) {
let $pubStatus := if($biblItem[@status="inThePipe"]) then(shared:translate('inThePipe'))
                  else if($biblItem[@status="unpublished"]) then(shared:translate('unpublished'))
                  else()

let $analytic := $biblItem/tei:analytic
let $monogr := $biblItem/tei:monogr
let $series := $biblItem/tei:series

let $monoTitle := $monogr/tei:title/string()
let $monoEditor := app:joinNames($monogr/tei:editor[not(@role)])
let $monoEditorColl := app:joinNames($monogr/tei:editor[@role="collaboration"])
let $monoEditorLabel := app:joinNames($monogr/tei:editor[@role="label"])
let $monoAuthor := app:joinNames($monogr/tei:author)

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
let $monoRef := if($biblItem//tei:ref[@type="doi"])
                then($biblItem//tei:ref[@type="doi"]/text())
                else($biblItem//tei:ref/@target)

let $seriesTitle := $series/tei:title[not(@type)]
let $seriesEditor := app:joinNames($series/tei:editor)
let $seriesSection := $series/tei:biblScope[@unit="section"]
let $seriesTitleSec := $series/tei:title[@type="section"]/text()

let $anaTitle := $analytic/tei:title/text()
let $anaAuthor := app:joinNames($analytic/tei:author)

(: Bibls :)
let $monogrBibl := concat(
                       if($monoAuthor)then(concat($monoAuthor, ': '))else(),
                       $monoTitle, ', ',
                       if($monoEditor)then(concat(shared:translate('editedBy'), ' ', $monoEditor, ', '))else(),
                       if($monoEditorLabel)then(concat(shared:translate('label'), ': ', $monoEditorLabel, ', '))else(),
                       if($monoEditorColl)then(concat(' ', shared:translate('collaborator'), ' ', $monoEditorColl, ', '))else(),
                       if($monoScopeIssue)then(concat(shared:translate('issue'), ' ', $monoScopeIssue, ', '))else(),
                       if($monoScopeVolume)then(concat(shared:translate('volume'), ' ', $monoScopeVolume, ', '))else(),
                       if($monoPubPlace and not($biblItem[@status="unpublished"])) then(concat($monoPubPlace, ' ')) else(shared:translate('noPlace')),' ',
                       if($monoPubDate) then($monoPubDate) else(shared:translate('noDate')),
                       if($monoRef) then('DOI: ' || $monoRef) else(),
                       if($pubStatus) then(concat(', ',$pubStatus))else()
                   )
let $analyticBibl := concat($anaAuthor, ': ',
                            $anaTitle, ', in: ',
                            $monogrBibl,
                            if($monoScopePages)then(concat(', ', shared:translate('page'), ' ', $monoScopePages))else()
                           )
let $seriesBibl := concat($seriesTitle, ', ', shared:translate('editedBy'),' ',$seriesEditor, ', ', shared:translate('section'),' ', $seriesSection, ' ', $seriesTitleSec, ', ')

let $posterBibl := concat($anaTitle, ', ', $monoPublisher, if($monoPubPlace) then(concat(', ', $monoPubPlace, ' ')) else if($biblItem[@status="unpublished"]) then() else(shared:translate('noPlace')),' ', if($monoPubDate) then($monoPubDate) else(shared:translate('noDate')))
let $termPaperBibl := concat($monoTitle, ', ',
                   if($monoPubPlace) then(concat($monoPubPlace, ' '))
                   else if($biblItem[@status="unpublished"])
                   then()
                   else(shared:translate('noPlace')),' ',
                   if($monoPubDate) then($monoPubDate) else(shared:translate('noDate')))
let $editionBibl := concat(
                           if($monoAuthor)then(concat($monoAuthor, ': '))else(),
                           $monoTitle, ', ',
                           if($monoEditor)then(concat(shared:translate('editedBy'), ' ', $monoEditor, ', '))else(),
                           if($monoEditorColl)then(concat(' ', shared:translate('collaboration'), ' ', $monoEditorColl, ', '))else(),
                           if($monoScopeIssue)then(concat(shared:translate('issue'), ' ', $monoScopeIssue, ', '))else(),
                           if($monoScopeVolume)then(concat(shared:translate('volume'), ' ', $monoScopeVolume, ', '))else(),
                           if($seriesTitle) then(concat($seriesBibl, ' ')) else(),
                           if($monoPubPlace) then(concat($monoPubPlace, ' '))
                           else if($biblItem[@status="unpublished"])
                           then()
                           else(shared:translate('noPlace')),' ',
                           if($monoPubDate) then($monoPubDate) else(shared:translate('noDate')),
                           if($monoRef) then(', DOI: ' || $monoRef) else(),
                           if($pubStatus) then(concat(', ',$pubStatus))else()
                          )

return
    if($biblType = 'article' or $biblType = 'review')
    then(concat($analyticBibl, '.'))
    else if($biblType = 'book' or $biblType = 'qualification' or $biblType = 'software')
    then(concat($monogrBibl, '.'))
    else if($biblType = 'poster')
    then(concat($posterBibl, '.'))
    else if($biblType = 'termPaper')
    then(concat($termPaperBibl, '.'))
    else if($biblType = 'edition')
    then(concat($editionBibl, '.'))
    else()
};

declare function app:getEvents($events as node()*, $param1 as xs:string?, $param2 as xs:string, $lang as xs:string, $from as xs:integer?, $to as xs:integer?) {
    for $event at $n in $events
        let $eventType := $event/@type
        let $label := $event//tei:label//text() => string-join(' ')
        let $orgName := $event//tei:orgName/text()
        let $settlement := $event//tei:settlement/text()
        let $date := shared:getDate($event//tei:date, 'full', $lang)
        let $dateFuture := shared:isFutureDate($event//tei:date)
        let $dateSort := shared:getDateSort($event//tei:date)
        let $contr := $event//tei:desc[@type="contribution"][if(@xml:lang)then(@xml:lang=$lang)else(true())]/text()
        let $contrType := $event//tei:desc[@type="contribution"][if(@xml:lang)then(@xml:lang=$lang)else(true())]/@subtype/string()
        let $from := if($from)then($from)else(1)
        let $to := if($to)then($to)else(count($events))
        
        let $conferenceName := string-join(($label, $orgName, $settlement, $date), ', ') || '.'
        
        where if ($param1 = 'future')
              then( shared:isFutureDate($event//tei:date))
              else(not(shared:isFutureDate($event//tei:date)))
        where $n >= $from
        where $n <= $to
        order by $dateSort descending
    
        return
            if($param2 = 'contribution')
            then(<li style="padding: 3px;" type="{$eventType}">
                    {$contr || ', ' || shared:translate($contrType) || ': ' || $conferenceName}
                 </li>)
            else(<li style="padding: 3px;" type="{$eventType}">
                    {$conferenceName}
                 </li>)
};

declare function app:conferences($node as node(), $model as map(*)) {
    let $lang := request:get-parameter('lang', 'de')
    let $events := collection($app:contentBasePath)//tei:event
    
    return
        (<h3 class="mb-4">{shared:translate('future')}</h3>,
         <h5 class="mb-2">{shared:translate('conference')}</h5>,
         <ul  style="list-style: square;">
            {if(app:getEvents($events[@type='conference'], 'future', '', $lang, (), ()))
             then(functx:distinct-deep(app:getEvents($events[@type='conference'], 'future', '', $lang, (), ())))
             else(<i>{shared:translate('currentNo')}</i>)}
         </ul>,
         <h5 class="mb-2">{shared:translate('contributions')}</h5>,
         <ul  style="list-style: square;">
            {if(app:getEvents($events[@type='conference'][.//tei:desc[@type='contribution']], 'future', 'contribution', $lang, 1, 100))
             then(app:getEvents($events[@type='conference'][.//tei:desc[@type='contribution']], 'future', 'contribution', $lang, 1, 100))
             else(<i>{shared:translate('currentNo')}</i>)}
         </ul>,
         <h3 class="mb-4">{shared:translate('past')}</h3>,
         <h5 class="mb-2">{shared:translate('conference')}</h5>,
         <ul  style="list-style: square;">
           {functx:distinct-deep(for $each at $n in app:getEvents($events[@type='conference'], 'past', '', $lang, 1, ())
               where $n lt 6
               return $each)
           }
         </ul>,
         <ul style="list-style: none">
            <li class="btn btn-primary" type="button" data-toggle="collapse" data-target="#biblReadMore-conference" aria-expanded="false" aria-controls="collapseExample">{shared:translate('moreItems')}</li>
         </ul>,
         <ul class="collapse" id="biblReadMore-conference" style="list-style: square;">
            {functx:distinct-deep(for $each at $n in app:getEvents($events[@type='conference'], 'past', '', $lang, 1, ())
               where $n gt 5
               return $each)}
         </ul>,
         <h5 class="mb-2">{shared:translate('contributions')}</h5>,
         <ul  style="list-style: square;">
              {for $each at $n in app:getEvents($events[@type='conference'][.//tei:desc[@type='contribution']], 'past', 'contribution', $lang, 1, ())
                  where $n lt 6
               return $each
              }
         </ul>,
         <ul style="list-style: none">
            <li class="btn btn-primary" type="button" data-toggle="collapse" data-target="#biblReadMore-talks" aria-expanded="false" aria-controls="collapseExample">{shared:translate('moreItems')}</li>
         </ul>,
         <ul class="collapse" id="biblReadMore-talks" style="list-style: square;">
            {for $each at $n in app:getEvents($events[@type='conference'][.//tei:desc[@type='contribution']], 'past', 'contribution', $lang, 1, ())
                where $n gt 5
               return $each
            }
         </ul>
        )
};

declare function app:skills($node as node(), $model as map(*)) {
    let $lang := request:get-parameter('lang', 'de')
    let $skillsDoc := doc($app:contentBasePath || 'skills.xml')/tei:TEI
    let $skills := $skillsDoc//tei:body/tei:div[@xml:lang=$lang]
    
    return
        transform:transform($skills, $app:formatText, ())
};

declare function app:commitment($node as node(), $model as map(*)) {
    let $lang := request:get-parameter('lang', 'de')
    let $commitments := collection($app:contentBasePath)//tei:event[@type='commitment']
    let $orgs := collection($app:contentBasePath)//tei:org
    
    return
        (<h3>{shared:translate('projects')}</h3>,
         <ul style="list-style: square;">{for $project in $commitments
                let $label := $project//tei:label[@xml:lang = $lang]
                let $date := if($project//tei:date) then(shared:getDate($project//tei:date, 'full', $lang)) else()
                return
                   <li style="padding: 3px;">{$date} | {transform:transform($label, $app:formatText, ())}</li>}
        </ul>,
        <h3>{shared:translate('organisations')}</h3>,
         <ul style="list-style: square;">{for $org in $orgs
                let $label := $org//tei:label[@xml:lang = $lang]
                let $date := if($org//tei:date) then(shared:getDate($org//tei:date, 'full', $lang)) else()
                return
                   <li style="padding: 3px;">{transform:transform($label, $app:formatText, ())}</li>}
        </ul>)
};

declare function app:langSwitch($node as node(), $model as map(*)) {
    <li class="nav-item">{
        let $supportedLangVals := ('de', 'en')
        for $lang in $supportedLangVals
            return
                <a id="{concat('lang-switch-', $lang)}"
                   class="nav-link {if(shared:get-lang() = $lang) then('active')else('')}"
                   style="display:inline-block; padding-right: 20px; {if (shared:get-lang() = $lang) then ('color: white!important; font-weight: bold;') else ()}"
                   href="?lang={$lang}"
                   onclick="{response:set-cookie('forceLang', $lang, 'P1D', true())}">{upper-case($lang)}</a>
    }</li>
};
