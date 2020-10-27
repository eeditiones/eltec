xquery version "3.1";

(: 
 : Module for app-specific template functions
 :
 : Add your own templating functions here, e.g. if you want to extend the template used for showing
 : the browsing view.
 :)
module namespace app="teipublisher.com/app";

import module namespace templates="http://exist-db.org/xquery/templates";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare function app:parse-params($node as node(), $model as map(*)) {
    if (not($model?root) or $model?root = "") then
        ()
    else 
        element { node-name($node) } {
            for $attr in $node/@* except ($node/@url, $node/@data-template)
            return
                if (matches($attr, "\$\{[^\}]+\}")) then
                    attribute { node-name($attr) } {
                        string-join(
                            let $parsed := analyze-string($attr, "\$\{([^\}]+?)(?::([^\}]+))?\}")
                            for $token in $parsed/node()
                            return
                                typeswitch($token)
                                    case element(fn:non-match) return $token/string()
                                    case element(fn:match) return
                                        let $paramName := $token/fn:group[1]/string()
                                        let $default := $token/fn:group[2]/string()
                                        let $found := [
                                            request:get-parameter($paramName, $default),
                                            $model($paramName),
                                            session:get-attribute($config:session-prefix || "." || $paramName)
                                        ]
                                        return
                                            array:fold-right($found, (), function($in, $value) {
                                                if (exists($in)) then $in else $value
                                            })
                                    default return $token
                        )
                    }
                else
                    $attr,
            attribute { 'url' } {
                    'api/collection' || $model?root || '/frequency'
                }
            ,
            templates:process($node/node(), $model)
        }
};
