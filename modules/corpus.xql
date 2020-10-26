xquery version "3.1";

(:~
 : Module for basic linguistic functions
 :
 : @author: Magdalena Turska
 : @date: 2020Q3
 
 ~:)
module namespace corpus="teipublisher.com/corpus";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare
function corpus:collection-frequency($request as map(*)) {
    let $path := xmldb:decode($request?parameters?path)
    let $max := xmldb:decode($request?parameters?max)

return
    corpus:indexTerms(
        collection($config:data-root || '/' || $path)/util:index-keys-by-qname(xs:QName("tei:text"), '',
        function($key, $count) {
            <term><name>{$key}</name><count>{$count[1]}</count><docs>{$count[2]}</docs></term>
        }, $max, "lucene-index"),
        'multi'
    )
};

declare
function corpus:document-frequency($request as map(*)) {
    let $path := xmldb:decode($request?parameters?id)
    let $max := xmldb:decode($request?parameters?max)

return
    corpus:indexTerms(
        doc($config:data-root || '/' || $path)/util:index-keys-by-qname(xs:QName("tei:text"), '',
        function($key, $count) {
            <term><name>{$key}</name><count>{$count[1]}</count><docs>{$count[2]}</docs></term>
        }, $max, "lucene-index"),
        'single'
    )
};

(: Return terms as a HTML table :)
declare function corpus:indexTerms($terms, $mode) {

let $ordered :=
    for $t in $terms
        let $count := xs:integer($t//*:count)
        order by $count descending
        return 
            <tr>
                <td>{$t//*:name/string()}</td>
                <td>{$t//*:count/string()}</td>
            
            { 
                if ($mode= "multi") then 
                    <td>{$t//*:docs/string()}</td>
                else
                    ()
            }
            </tr>

return 
    <table>
        <tr>
            <th><pb-i18n key="eltec.frequency.term">Term</pb-i18n></th>
            <th><pb-i18n key="eltec.frequency.occurrences">Occurrences</pb-i18n></th>
            { 
                if ($mode= "multi") then 
                    <th><pb-i18n key="eltec.frequency.documents">Documents</pb-i18n></th>
                else
                    ()
            }
            
        </tr>
    
        {$ordered}
    </table>
};