xquery version "3.1";

module namespace app="http://dennisried.de/templates";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://dennisried.de/config" at "config.xqm";
import module namespace i18n = "http://exist-db.org/xquery/i18n" at "i18n.xql";

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