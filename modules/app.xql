xquery version "3.1";

module namespace app="http://dennisried.de/templates";

import module namespace templates="http://exist-db.org/xquery/templates";
import module namespace config="http://exist-db.org/xquery/config" at "/db/apps/homepageDR/modules/config.xqm";
import module namespace i18n = "http://exist-db.org/xquery/i18n" at "/db/apps/homepageDR/modules/i18n.xql";
import module namespace shared="http://dennisried.de/shared" at "/db/apps/homepageDR/modules/shared.xql";

declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace mei = "http://www.music-encoding.org/ns/mei";

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