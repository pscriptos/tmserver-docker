<?php
/**
 * Php8Compat.php - PHP-8-Kompatibilitaet fuer AdminServ, RemoteCP und XAseco
 *
 * Aufruf: php Php8Compat.php <verzeichnis> [<verzeichnis> ...]
 *
 * PHP 8 behandelt Methoden mit dem Namen der Klasse (PHP-4-Konstruktoren)
 * nicht mehr als Konstruktor. Die alten Tools nutzen das an vielen Stellen,
 * Objekte blieben dadurch uninitialisiert.
 *
 * Fuer jede Klasse mit PHP-4-Konstruktor und ohne __construct() wird direkt
 * nach der oeffnenden Klammer ein __construct() eingefuegt, der die alte
 * Methode aufruft. Die alte Methode bleibt erhalten, damit Aufrufe wie
 * parent::IXR_Client(...) weiter funktionieren.
 *
 * Ausserdem werden String-Offsets mit geschweiften Klammern ($str{0}) auf
 * eckige Klammern umgestellt (unter PHP 8 ein Parse-Error).
 *
 * Nicht-statische Methoden, die statisch aufgerufen werden (Core::getObject()),
 * sind unter PHP 8 ein Fatal Error. Solche Methoden werden als static markiert,
 * sofern sie $this nicht verwenden und keine Unterklasse sie nicht-statisch
 * ueberschreibt.
 *
 * Idempotent: Klassen mit vorhandenem __construct() werden uebersprungen.
 * Dateien werden in-place geschrieben (Besitzer und Rechte bleiben erhalten).
 */

if ($argc < 2) {
    fwrite(STDERR, "Aufruf: php {$argv[0]} <verzeichnis> [...]\n");
    exit(1);
}

$files = array();
for ($i = 1; $i < $argc; $i++) {
    if (!is_dir($argv[$i])) continue;
    $it = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($argv[$i], FilesystemIterator::SKIP_DOTS));
    foreach ($it as $file) {
        if (strtolower($file->getExtension()) === 'php') $files[] = $file->getPathname();
    }
}

$changed = array();
$totalClasses = 0;
$totalCurly = 0;
$totalStatic = 0;

// Durchlauf 1: Konstruktoren und String-Offsets (pro Datei)
foreach ($files as $path) {
    $src = file_get_contents($path);
    if ($src === false) continue;
    list($new, $count) = patchConstructors($src);
    list($new, $curly) = patchCurlyOffsets($new);
    if ($new !== $src) {
        file_put_contents($path, $new);
        $changed[$path] = true;
        $totalClasses += $count;
        $totalCurly += $curly;
    }
}

// Durchlauf 2: statisch aufgerufene Methoden (dateiuebergreifend)
foreach (patchStaticCalls($files) as $path => $count) {
    $changed[$path] = true;
    $totalStatic += $count;
}

echo "    PHP-8-Kompatibilitaet: $totalClasses Konstruktor(en), $totalCurly Offset(s), $totalStatic static-Methode(n) in " . count($changed) . " Datei(en) angepasst.\n";

/**
 * Markiert nicht-statische Methoden als static, wenn sie irgendwo als
 * Klasse::methode() aufgerufen werden, $this nicht verwenden und von keiner
 * Unterklasse nicht-statisch ueberschrieben werden.
 *
 * Liefert [Pfad => Anzahl geaenderter Methoden].
 */
function patchStaticCalls($files)
{
    $methods = array(); // "klasse::methode" => [pfad, token-index, static, usesThis]
    $parents = array(); // "klasse" => "elternklasse"
    $calls = array();   // "klasse::methode" => true
    $tokensByFile = array();

    foreach ($files as $path) {
        $src = file_get_contents($path);
        if ($src === false || strpos($src, '::') === false && stripos($src, 'class') === false) continue;
        $t = @token_get_all($src);
        $tokensByFile[$path] = $t;
        $n = count($t);
        $depth = 0;
        $cls = null;
        $clsDepth = -1;
        for ($i = 0; $i < $n; $i++) {
            $x = $t[$i];
            if ($x === '{' || (is_array($x) && in_array($x[0], array(T_CURLY_OPEN, T_DOLLAR_OPEN_CURLY_BRACES), true))) {
                $depth++;
            } elseif ($x === '}') {
                $depth--;
                if ($depth === $clsDepth) { $cls = null; $clsDepth = -1; }
            } elseif (is_array($x) && $x[0] === T_CLASS) {
                $prev = prevSignificant($t, $i);
                if ($prev !== null && is_array($t[$prev]) && in_array($t[$prev][0], array(T_DOUBLE_COLON, T_NEW), true)) continue;
                $j = nextSignificant($t, $i);
                if ($j !== null && is_array($t[$j]) && $t[$j][0] === T_STRING) {
                    $cls = strtolower($t[$j][1]);
                    $clsDepth = $depth;
                    $e = nextSignificant($t, $j);
                    if ($e !== null && is_array($t[$e]) && $t[$e][0] === T_EXTENDS) {
                        $pc = nextSignificant($t, $e);
                        if ($pc !== null && is_array($t[$pc])) $parents[$cls] = strtolower(ltrim($t[$pc][1], '\\'));
                    }
                }
            } elseif ($cls !== null && is_array($x) && $x[0] === T_FUNCTION && $depth === $clsDepth + 1) {
                $static = false;
                for ($k = $i - 1; $k >= 0; $k--) {
                    if (is_array($t[$k]) && $t[$k][0] === T_STATIC) $static = true;
                    if ($t[$k] === ';' || $t[$k] === '{' || $t[$k] === '}') break;
                }
                $j = nextSignificant($t, $i);
                if ($j !== null && $t[$j] === '&') $j = nextSignificant($t, $j);
                if ($j === null || !is_array($t[$j])) continue;
                $m = strtolower($t[$j][1]);
                $usesThis = false;
                $k = $j;
                while ($k < $n && $t[$k] !== '{' && $t[$k] !== ';') $k++;
                if ($k < $n && $t[$k] === '{') {
                    $d = 0;
                    for ($q = $k; $q < $n; $q++) {
                        $y = $t[$q];
                        if ($y === '{' || (is_array($y) && in_array($y[0], array(T_CURLY_OPEN, T_DOLLAR_OPEN_CURLY_BRACES), true))) $d++;
                        elseif ($y === '}') { $d--; if ($d === 0) break; }
                        elseif (is_array($y) && $y[0] === T_VARIABLE && $y[1] === '$this') $usesThis = true;
                    }
                }
                $methods["$cls::$m"] = array($path, $i, $static, $usesThis);
            } elseif (is_array($x) && $x[0] === T_DOUBLE_COLON && $i > 0 && isset($t[$i + 1])) {
                $p = $t[$i - 1];
                $nx = $t[$i + 1];
                if (is_array($p) && $p[0] === T_STRING && is_array($nx) && $nx[0] === T_STRING) {
                    $j = nextSignificant($t, $i + 1);
                    $c = strtolower($p[1]);
                    if ($j !== null && $t[$j] === '(' && !in_array($c, array('parent', 'self', 'static'), true)) {
                        $calls[$c . '::' . strtolower($nx[1])] = true;
                    }
                }
            }
        }
    }

    // Kandidaten je Datei sammeln (Token-Index der function-Deklaration)
    $todo = array();
    foreach ($calls as $key => $_) {
        if (!isset($methods[$key])) continue;
        list($path, $idx, $static, $usesThis) = $methods[$key];
        if ($static || $usesThis) continue;
        // Nicht anfassen, wenn eine Unterklasse die Methode nicht-statisch ueberschreibt
        list($target, $m) = explode('::', $key);
        $overridden = false;
        foreach ($methods as $other => $info) {
            list($oc, $om) = explode('::', $other);
            if ($om !== $m || $oc === $target || $info[2]) continue;
            for ($a = $oc, $guard = 0; isset($parents[$a]) && $guard < 20; $a = $parents[$a], $guard++) {
                if ($parents[$a] === $target) { $overridden = true; break 2; }
            }
        }
        if ($overridden) continue;
        $todo[$path][] = $idx;
    }

    $result = array();
    foreach ($todo as $path => $indexes) {
        $t = $tokensByFile[$path];
        foreach ($indexes as $idx) {
            $t[$idx] = array(T_FUNCTION, 'static ' . $t[$idx][1], 0);
        }
        $out = '';
        foreach ($t as $tok) $out .= is_array($tok) ? $tok[1] : $tok;
        file_put_contents($path, $out);
        $result[$path] = count($indexes);
    }
    return $result;
}

/**
 * Ersetzt String-Offsets mit geschweiften Klammern ($str{0}) durch eckige
 * Klammern ($str[0]); unter PHP 8 ist die alte Syntax ein Parse-Error.
 * Erfasst wird nur "{" direkt nach einer Variablen oder "]" (ohne
 * Leerzeichen), dort hat "{" keine andere Bedeutung.
 *
 * Liefert [neuer Quelltext, Anzahl ersetzter Offsets].
 */
function patchCurlyOffsets($src)
{
    if (strpos($src, '{') === false) return array($src, 0);
    $tokens = @token_get_all($src);
    $n = count($tokens);
    $count = 0;
    for ($i = 1; $i < $n; $i++) {
        if ($tokens[$i] !== '{') continue;
        $prev = $tokens[$i - 1];
        if (!($prev === ']' || (is_array($prev) && $prev[0] === T_VARIABLE))) continue;
        // Passende schliessende Klammer suchen
        $depth = 0;
        for ($j = $i; $j < $n; $j++) {
            $t = $tokens[$j];
            if ($t === '{' || (is_array($t) && in_array($t[0], array(T_CURLY_OPEN, T_DOLLAR_OPEN_CURLY_BRACES), true))) $depth++;
            elseif ($t === '}') { $depth--; if ($depth === 0) break; }
        }
        if ($j >= $n) continue;
        $tokens[$i] = '[';
        $tokens[$j] = ']';
        $count++;
    }
    if ($count === 0) return array($src, 0);
    $out = '';
    foreach ($tokens as $t) $out .= is_array($t) ? $t[1] : $t;
    return array($out, $count);
}

/**
 * Liefert [neuer Quelltext, Anzahl eingefuegter Konstruktoren].
 */
function patchConstructors($src)
{
    if (stripos($src, 'class') === false) return array($src, 0);
    $eol = (strpos($src, "\r\n") !== false) ? "\r\n" : "\n";
    $tokens = @token_get_all($src);
    $n = count($tokens);
    $inserts = array(); // Byte-Offset => einzufuegender Text

    // Byte-Offsets aller Tokens berechnen
    $offsets = array();
    $pos = 0;
    for ($i = 0; $i < $n; $i++) {
        $offsets[$i] = $pos;
        $pos += strlen(is_array($tokens[$i]) ? $tokens[$i][1] : $tokens[$i]);
    }

    for ($i = 0; $i < $n; $i++) {
        if (!is_array($tokens[$i]) || $tokens[$i][0] !== T_CLASS) continue;

        // "Foo::class" und anonyme Klassen ("new class") ignorieren
        $prev = prevSignificant($tokens, $i);
        if ($prev !== null && is_array($tokens[$prev]) && in_array($tokens[$prev][0], array(T_DOUBLE_COLON, T_NEW), true)) continue;

        $nameIdx = nextSignificant($tokens, $i);
        if ($nameIdx === null || !is_array($tokens[$nameIdx]) || $tokens[$nameIdx][0] !== T_STRING) continue;
        $className = $tokens[$nameIdx][1];

        // Oeffnende Klammer des Klassenkoerpers suchen
        $open = $nameIdx;
        while ($open < $n && $tokens[$open] !== '{') $open++;
        if ($open >= $n) continue;

        // Methoden auf Klassenebene einsammeln
        $depth = 0;
        $hasConstruct = false;
        $oldCtor = null;
        for ($j = $open; $j < $n; $j++) {
            $t = $tokens[$j];
            if ($t === '{' || (is_array($t) && in_array($t[0], array(T_CURLY_OPEN, T_DOLLAR_OPEN_CURLY_BRACES), true))) {
                $depth++;
            } elseif ($t === '}') {
                $depth--;
                if ($depth === 0) break;
            } elseif ($depth === 1 && is_array($t) && $t[0] === T_FUNCTION) {
                $k = nextSignificant($tokens, $j);
                if ($k !== null && $tokens[$k] === '&') $k = nextSignificant($tokens, $k);
                if ($k === null || !is_array($tokens[$k])) continue;
                $method = $tokens[$k][1];
                if (strcasecmp($method, '__construct') === 0) $hasConstruct = true;
                if (strcasecmp($method, $className) === 0) $oldCtor = $k;
            }
        }
        if ($hasConstruct || $oldCtor === null) continue;

        // Parameterliste der alten Methode uebernehmen
        $p = $oldCtor;
        while ($p < $n && $tokens[$p] !== '(') $p++;
        $params = '';
        $vars = array();
        $byRef = false;
        $pd = 0;
        for ($q = $p; $q < $n; $q++) {
            $t = $tokens[$q];
            if ($t === '(') { $pd++; if ($pd === 1) continue; }
            if ($t === ')') { $pd--; if ($pd === 0) break; }
            $txt = is_array($t) ? $t[1] : $t;
            $params .= $txt;
            if ($pd === 1 && is_array($t) && $t[0] === T_VARIABLE) $vars[] = $t[1];
            if ($pd === 1 && $t === '&') $byRef = true;
        }

        // Ohne Referenzparameter func_get_args() nutzen (gleiche Semantik bei
        // optionalen Parametern), sonst die Variablen direkt durchreichen.
        $call = $byRef ? implode(', ', $vars) : '...func_get_args()';
        $shim = "{$eol}\t// tmserver-docker: Php8Compat{$eol}"
              . "\tfunction __construct(" . trim($params) . ") { \$this->{$tokens[$oldCtor][1]}($call); }";
        $inserts[$offsets[$open] + 1] = $shim;
    }

    if (empty($inserts)) return array($src, 0);
    krsort($inserts);
    foreach ($inserts as $off => $txt) {
        $src = substr($src, 0, $off) . $txt . substr($src, $off);
    }
    return array($src, count($inserts));
}

function nextSignificant($tokens, $i)
{
    for ($j = $i + 1, $n = count($tokens); $j < $n; $j++) {
        if (is_array($tokens[$j]) && in_array($tokens[$j][0], array(T_WHITESPACE, T_COMMENT, T_DOC_COMMENT), true)) continue;
        return $j;
    }
    return null;
}

function prevSignificant($tokens, $i)
{
    for ($j = $i - 1; $j >= 0; $j--) {
        if (is_array($tokens[$j]) && in_array($tokens[$j][0], array(T_WHITESPACE, T_COMMENT, T_DOC_COMMENT), true)) continue;
        return $j;
    }
    return null;
}
