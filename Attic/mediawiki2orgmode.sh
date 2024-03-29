#!/bin/bash

##  mediawiki2orgmode: convert (an xml dump of) a Mediawiki page to Orgmode format.
##  2021-11-06, MvdS:  initial version.


# Check number of CLI arguments:
if [[ ${#} -lt 1 || ${#} -gt 2 ]]
then
    command=`echo ${0} |sed -e 's/^.*\///g'`  # Remove path (e.g. ./)
    echo "This program converts (an xml dump of) a Mediawiki page to Orgmode format."
    echo "Error: one or two arguments were expected"
    echo "Syntax:  ${command} <Mediawiki file> <Orgmode file>"
    exit 1
fi


# Get file names from CLI arguments:
INFILE=$1
if [ ${#} -eq 2 ]
then
    OUTFILE=$2
else
    # Add extension .org.  Replace extensions .xml, .mw, .mediawiki to .org.  Replace .org.org with .org:
    OUTFILE=`echo "$INFILE.org" | sed -e 's|\.xml|\.org|' -e 's|\.mw|\.org|' -e 's|\.mediawiki|\.org|' -e 's|\.org\.org|\.org|'`
fi


# Check whether the input file exists:
if [ ! -e $INFILE ]
then
    echo -e "\nERROR: $INFILE does not exist!"
    echo -e "Aborting...\n"
    exit
fi


# Check whether the output file already exists:
if [ -e $OUTFILE ]
then
    echo -e "\nWarning: $OUTFILE already exists and will be overwritten!"
    echo -en "\nDo you want to continue (y/N)?  "
    read -n1 ans  # Read 1 character max
    echo
    if [[ ${ans} != "y" && ${ans} != "Y" ]]
    then
	echo -e "Aborting...\n"
	exit
    fi
fi


# OK to continue:
echo "Converting $INFILE to $OUTFILE..."
cp $INFILE $OUTFILE  ||  exit 1


# Remove xml <tags> from Mediawiki export:
sed -i \
    -e '/^  <\/*page>$/d' \
    -e '/^    <ns>0<\/ns>$/d' \
    -e '/^ *<id>[0-9]*<\/id>$/d' \
    -e '/^    <\/*revision>$/d' \
    -e '/^      <parentid>[0-9]*<\/parentid>$/d' \
    -e '/^      <\/*contributor>$/d' \
    -e '/^      <model>wikitext<\/model>$/d' \
    -e '/^      <format>text\/x-wiki<\/format>$/d' \
    -e '/^      <comment>.*<\/comment>/d' \
    -e '/^ *<ip>[0-9\.:]*<\/ip>/d' \
    -e 's|^ *<text xml:space="preserve" bytes="0" \/>||g' \
    -e 's|^ *<text xml:space="preserve" bytes="[0-9]*">||g' \
    -e '/^ *<username>.*<\/username>$/d' \
    -e 's|</text>$||' \
    -e '/^ *<sha1>[a-z0-9]*<\/sha1>$/d' \
    -e '/^ *<sha1\/>$/d' \
    -e '/^ *<minor\/>$/d' \
    -e 's|^    <title>\(.*\)<\/title>$|#+title: \1|' \
    -e 's|^      <timestamp>\(.*\)T\(.*\)Z<\/timestamp>$|#+date: \[\1 \2\] UTC\n|' \
    $OUTFILE  ||  exit 1

# Convert space, dash:
sed -i \
    -e 's|&amp;nbsp;| |g' \
    -e 's| &amp;mdash; | - |g' \
    -e 's|&amp;mdash;| - |g' \
    -e 's|&amp;ndash;|-|g' \
    $OUTFILE

# Convert bullets, enumerates and section headings:
sed -i \
    -e 's|^\*\*\*\*\*\([^\*].*\)$|        - \1|' \
    -e 's|^\*\*\*\*\([^\*].*\)$|      * \1|' \
    -e 's|^\*\*\*\([^\*].*\)$|    - \1|' \
    -e 's|^\*\*\([^\*].*\)$|  - \1|' \
    -e 's|^\*\([^\*].*\)$|+ \1|' \
    -e 's|^##### |            1. |g' \
    -e 's|^#### |         1. |g' \
    -e 's|^### |      1. |g' \
    -e 's|^## |   1. |g' \
    -e 's|^# |1) |g' \
    -e 's|^=====\([^=].*[^=]\)=====$|***** \1|' \
    -e 's|^====\([^=].*[^=]\)====$|**** \1|' \
    -e 's|^===\([^=].*[^=]\)===$|*** \1|' \
    -e 's|^==\([^=].*[^=]\)==$|** \1|' \
    -e 's|^=\([^=].*[^=]\)=$|* \1|' \
    $OUTFILE

# Convert HTML tables:
sed -i \
    -e "s: *width=&quot;[0-9]*%&quot; *::g" \
    -e "s: *colspan=&quot;[0-9]*&quot; *::g" \
    -e "s: *align=&quot;center&quot; *::g" \
    -e "s: *align=&quot;left&quot; *::g" \
    -e "s: *align=&quot;right&quot; *::g" \
    -e 's:^ *&lt;\/*table&gt; *$:|------|:' \
    -e 's:^ *&lt;table .*&gt; *$:|------|:' \
    -e 's:&lt;table&gt;:|------|\n:g' \
    -e 's:&lt;\/table&gt;:\n|------|:g' \
    -e 's: *&lt;tr&gt; *&lt;td&gt; *:| :g' \
    -e 's: *&lt;td&gt; *&lt;/td&gt; *: | :g' \
    -e 's: *&lt;\/td&gt; *&lt;\/tr&gt; *: |:g' \
    -e 's: *&lt;\/td&gt; *&lt;td&gt; *: | :g' \
    -e 's: *&lt;\/*td&gt; *: | :g' \
    -e 's: *&lt;\/*tr&gt; *::g' \
    $OUTFILE
# Same with <...>:
sed -i \
    -e 's:^ *<\/*table> *$:|------|:' \
    -e 's:^ *<table .*> *$:|------|:' \
    -e 's:<table>:|------|\n:g' \
    -e 's:<\/table>:\n|------|:g' \
    -e 's: *<tr> *<td> *:| :g' \
    -e 's: *<td> *</td> *: | :g' \
    -e 's: *<\/td> *<\/tr> *: |:g' \
    -e 's: *<\/td> *<td> *: | :g' \
    -e 's: *<\/*td> *: | :g' \
    -e 's: *<\/*tr> *::g' \
    $OUTFILE
#     -e 's:::g' \
#     -e 's: *&lt;tr align=&quot;center&quot;&gt; *&lt;td&gt; *:| :g' \
#     -e 's: *&lt;tr align=&quot;center&quot;&gt; *&lt;td colspan=&quot;[0-9]*&quot;&gt; *:| :g' \

# Convert common sup/sub constructs:
sed -i \
    -e 's|CO&lt;sub&gt;2&lt;/sub&gt;|CO_2|g' \
    -e 's|&lt;sup&gt;2&lt;/sup&gt;|^2|g' \
    -e 's|&lt;sub&gt;|_|g' \
    -e 's|&lt;\/sub&gt;||g' \
    -e 's|&lt;sup&gt;|^|g' \
    -e 's|&lt;\/sup&gt;||g' \
    $OUTFILE
# Same with <...>:
sed -i \
    -e 's|CO<sub>2</sub>|CO_2|g' \
    -e 's|<sup>2</sup>|^2|g' \
    -e 's|<sub>|_|g' \
    -e 's|<\/sub>||g' \
    -e 's|<sup>|^|g' \
    -e 's|<\/sup>||g' \
    $OUTFILE
#     -e 's|||g' \

# Convert &lt;TAG&gt;...&lt;\/TAG&gt; HTML constructs:
sed -i \
    -e 's|&lt;PRE&gt;|#+begin_src f90|g' \
    -e 's|&lt;pre&gt;|#+begin_src f90|g' \
    -e 's|&lt;\/PRE&gt;|#+end_src|g' \
    -e 's|&lt;\/pre&gt;|#+end_src|g' \
    -e 's|&lt;\/*small&gt;||g' \
    -e 's|\&lt;math\&gt;|\\\[|g' \
    -e 's|\&lt;\/math\&gt;|\\\]|g' \
    -e 's|&lt;b&gt; *|\*|g' \
    -e 's| *&lt;\/b&gt;|\*|g' \
    -e 's|&lt;br&gt;||' \
    -e '/^&lt;div class=&quot;noautonum&quot;&gt;__TOC__&lt;\/div&gt;$/d' \
    $OUTFILE
# Same with <...>:
sed -i \
    -e 's|<PRE>|#+begin_src f90|g' \
    -e 's|<pre>|#+begin_src f90|g' \
    -e 's|<\/PRE>|#+end_src|g' \
    -e 's|<\/pre>|#+end_src|g' \
    -e 's|<\/*small>||g' \
    -e 's|<math>|\\\[|g' \
    -e 's|<\/math>|\\\]|g' \
    -e 's|<b> *|\*|g' \
    -e 's| *<\/b>|\*|g' \
    -e 's|<br>||' \
    -e '/^<div class=&quot;noautonum&quot;>__TOC__<\/div>$/d' \
    $OUTFILE
#     -e 's|<TAG>||g' \
#     -e 's|<\/TAG>||g' \
#     -e 's|<\/*TAG>||g' \

# Convert bold, italic:
sed -i \
    -e "s|'''''\([^']*\)'''''|\*\/\1\/\*|g" \
    -e "s|'''|\*|g" \
    -e "s|''|\/|g" \
    $OUTFILE

# Convert HTML &amp; lower-case accents:
sed -i \
    -e 's|&amp;auml;|ä|g' \
    -e 's|&amp;euml;|ë|g' \
    -e 's|&amp;iuml;|ï|g' \
    -e 's|&amp;ouml;|ö|g' \
    -e 's|&amp;uuml;|ü|g' \
    -e 's|&amp;aacute;|á|g' \
    -e 's|&amp;eacute;|é|g' \
    -e 's|&amp;iacute;|í|g' \
    -e 's|&amp;oacute;|ó|g' \
    -e 's|&amp;uacute;|ú|g' \
    -e 's|&amp;agrave;|à|g' \
    -e 's|&amp;egrave;|è|g' \
    -e 's|&amp;igrave;|ì|g' \
    -e 's|&amp;ograve;|ò|g' \
    -e 's|&amp;ugrave;|ù|g' \
    $OUTFILE
#     -e 's|&amp;CODE;||g' \
    
# HTML &amp; upper-case accents:
sed -i \
    -e 's|&amp;Auml;|Ä|g' \
    -e 's|&amp;Euml;|Ë|g' \
    -e 's|&amp;Iuml;|Ï|g' \
    -e 's|&amp;Ouml;|Ö|g' \
    -e 's|&amp;Uuml;|Ü|g' \
    -e 's|&amp;Aacute;|Á|g' \
    -e 's|&amp;Eacute;|É|g' \
    -e 's|&amp;Iacute;|Í|g' \
    -e 's|&amp;Oacute;|Ó|g' \
    -e 's|&amp;Uacute;|Ú|g' \
    -e 's|&amp;Agrave;|À|g' \
    -e 's|&amp;Egrave;|È|g' \
    -e 's|&amp;Igrave;|Ì|g' \
    -e 's|&amp;Ograve;|Ò|g' \
    -e 's|&amp;Ugrave;|Ù|g' \
    $OUTFILE
#     -e 's|&amp;CODE;||g' \
    
# HTML &amp; symbols:
sed -i \
    -e 's|&amp;deg;|°|g' \
    -e 's|&amp;euro;|€|g' \
    -e 's|&amp;amp;|\&|g' \
    -e 's|&amp;pm;|±|g' \
    -e 's|&amp;gt;|>|g' \
    -e 's|&amp;lt;|<|g' \
    -e 's|&amp;ge;|>=|g' \
    -e 's|&amp;le;|<=|g' \
    -e 's|&amp;[lr]dquo;|"|g' \
    -e 's|&amp;#8734;|$\\infty$|g' \
    $OUTFILE
#     -e 's|&amp;CODE;||g' \
    
# Convert HTML &symbols;:
sed -i \
    -e "s|&quot;|'|g" \
    $OUTFILE
#     -e "s|&SYM;||g" \

# Convert HTML &lt;/&gt; 'single arrows':
sed -i \
    -e "s| &lt;- | <- |g" \
    -e "s| &lt;\(--*\)| <\1|g" \
    -e "s|^&lt;- |<- |g" \
    -e "s|^&lt;\(--*\)|<\1|g" \
    -e "s| -&gt; | -> |g" \
    -e "s|\(--*\)&gt; |\1> |g" \
    -e "s| -&gt;$| ->|g" \
    -e "s|\(--*\)&gt;$|\1>|g" \
    -e "s|&lt;-&gt;|<->|g" \
    -e "s|&lt;\(--*\)&gt;|<\1>|g" \
    $OUTFILE
# Same with <...>:
sed -i \
    -e "s| <- | <- |g" \
    -e "s| <\(--*\)| <\1|g" \
    -e "s|^<- |<- |g" \
    -e "s|^<\(--*\)|<\1|g" \
    -e "s| -> | -> |g" \
    -e "s|\(--*\)> |\1> |g" \
    -e "s| ->$| ->|g" \
    -e "s|\(--*\)>$|\1>|g" \
    -e "s|<->|<->|g" \
    -e "s|<\(--*\)>|<\1>|g" \
    $OUTFILE

# Convert HTML &lt;/&gt; 'double arrows':
sed -i \
    -e "s| &lt;= | <= |g" \
    -e "s| &lt;==*| <==|g" \
    -e "s|^&lt;= |<= |g" \
    -e "s|^&lt;==*|<==|g" \
    -e "s| =&gt; | => |g" \
    -e "s|==*&gt; |==> |g" \
    -e "s| =&gt;$| =>|g" \
    -e "s|==*&gt;$|==>|g" \
    -e "s|&lt;=&gt;|<=>|g" \
    -e "s|&lt;==*&gt;|<===>|g" \
    $OUTFILE
# Same with <...>:
sed -i \
    -e "s| <= | <= |g" \
    -e "s| <==*| <==|g" \
    -e "s|^<= |<= |g" \
    -e "s|^<==*|<==|g" \
    -e "s| => | => |g" \
    -e "s|==*> |==> |g" \
    -e "s| =>$| =>|g" \
    -e "s|==*>$|==>|g" \
    -e "s|<=>|<=>|g" \
    -e "s|<==*>|<===>|g" \
    $OUTFILE


# Convert Greek &letters;:
sed -i \
    -e "s|&amp;alpha;|$\\\\alpha$|g" \
    -e "s|&amp;beta;|$\\\\beta$|g" \
    -e "s|&amp;gamma;|$\\\\gamma$|g" \
    -e "s|&amp;delta;|$\\\\delta$|g" \
    -e "s|&amp;epsilon;|$\\\\epsilon$|g" \
    -e "s|&amp;zeta;|$\\\\zeta$|g" \
    -e "s|&amp;eta;|$\\\\eta$|g" \
    -e "s|&amp;theta;|$\\\\theta$|g" \
    -e "s|&amp;iota;|$\\\\iota$|g" \
    -e "s|&amp;kappa;|$\\\\kappa$|g" \
    -e "s|&amp;lambda;|$\\\\lambda$|g" \
    -e "s|&amp;mu;|$\\\\mu$|g" \
    -e "s|&amp;nu;|$\\\\nu$|g" \
    -e "s|&amp;xi;|$\\\\xi$|g" \
    -e "s|&amp;omicron;|$\\\\omicron$|g" \
    -e "s|&amp;pi;|$\\\\pi$|g" \
    -e "s|&amp;rho;|$\\\\rho$|g" \
    -e "s|&amp;sigma;|$\\\\sigma$|g" \
    -e "s|&amp;tau;|$\\\\tau$|g" \
    -e "s|&amp;upsilon;|$\\\\upsilon$|g" \
    -e "s|&amp;phi;|$\\\\phi$|g" \
    -e "s|&amp;chi;|$\\\\chi$|g" \
    -e "s|&amp;psi;|$\\\\psi$|g" \
    -e "s|&amp;omega;|$\\\\omega$|g" \
    -e "s|&amp;Alpha;|$\\\\Alpha$|g" \
    -e "s|&amp;Beta;|$\\\\Beta$|g" \
    -e "s|&amp;Gamma;|$\\\\Gamma$|g" \
    -e "s|&amp;Delta;|$\\\\Delta$|g" \
    -e "s|&amp;Epsilon;|$\\\\Epsilon$|g" \
    -e "s|&amp;Zeta;|$\\\\Zeta$|g" \
    -e "s|&amp;Eta;|$\\\\Eta$|g" \
    -e "s|&amp;Theta;|$\\\\Theta$|g" \
    -e "s|&amp;Iota;|$\\\\Iota$|g" \
    -e "s|&amp;Kappa;|$\\\\Kappa$|g" \
    -e "s|&amp;Lambda;|$\\\\Lambda$|g" \
    -e "s|&amp;Mu;|$\\\\Mu$|g" \
    -e "s|&amp;Nu;|$\\\\Nu$|g" \
    -e "s|&amp;Xi;|$\\\\Xi$|g" \
    -e "s|&amp;Omicron;|$\\\\Omicron$|g" \
    -e "s|&amp;Pi;|$\\\\Pi$|g" \
    -e "s|&amp;Rho;|$\\\\Rho$|g" \
    -e "s|&amp;Sigma;|$\\\\Sigma$|g" \
    -e "s|&amp;Tau;|$\\\\Tau$|g" \
    -e "s|&amp;Upsilon;|$\\\\Upsilon$|g" \
    -e "s|&amp;Phi;|$\\\\Phi$|g" \
    -e "s|&amp;Chi;|$\\\\Chi$|g" \
    -e "s|&amp;Psi;|$\\\\Psi$|g" \
    -e "s|&amp;Omega;|$\\\\Omega$|g" \
    $OUTFILE

# Convert common &lt;/&gt; constructs:
sed -i \
    -e 's|Mo&lt;M|Mo<M|g' \
    -e 's|R&gt;R|R>R|g' \
    -e 's|d&lt;P|d<P|g' \
    -e 's|0&lt;\$\beta\$|0<$\beta$|g' \
    $OUTFILE
# Same with <...>:
sed -i \
    -e 's|Mo<M|Mo<M|g' \
    -e 's|R>R|R>R|g' \
    -e 's|d<P|d<P|g' \
    -e 's|0<\$\beta\$|0<$\beta$|g' \
    $OUTFILE
#     -e 's|||g' \
    
# Convert common &amp; constructs:
sed -i \
    -e 's|M&amp;M&amp;A|M\&M\&A|g' \
    -e 's|M&amp;M|M\&M|g' \
    -e 's|M&amp;R|M\&R|g' \
    -e 's|H&amp;M|H\&M|g' \
    -e 's|R&amp;O|R\&O|g' \
    -e 's|R&amp;D|R\&D|g' \
    -e 's|A&amp;A|A\&A|g' \
    $OUTFILE

# Convert HTML &lt;, &gt; with numbers, equal/approx signs:
sed -i \
    -e "s|&lt;\([0-9]\)|<\1|g" \
    -e "s|&gt;\([0-9]\)|>\1|g" \
    -e "s|&lt;=|<=|g" \
    -e "s|&gt;=|>=|g" \
    -e "s|&lt;~|<~|g" \
    -e "s|&gt;~|>~|g" \
    -e "s|~&lt;|<~|g" \
    -e "s|~&gt;|>~|g" \
    $OUTFILE
# Same with <...>:
sed -i \
    -e "s|<\([0-9]\)|<\1|g" \
    -e "s|>\([0-9]\)|>\1|g" \
    -e "s|<=|<=|g" \
    -e "s|>=|>=|g" \
    -e "s|<~|<~|g" \
    -e "s|>~|>~|g" \
    -e "s|~<|<~|g" \
    -e "s|~>|>~|g" \
    $OUTFILE


# Leftover &lt;/&gt;:
# Convert HTML &lt; &gt; brackets:
sed -i \
    -e "s:&lt;\([^&]*|[^&]*\)&gt;:<\1>:g" \
    $OUTFILE

# Convert HTML standalone &lt;, &gt;, &amp;:
sed -i \
    -e "s| &lt; | < |g" \
    -e "s| &lt;&lt; | << |g" \
    -e "s| &gt; | > |g" \
    -e "s| &gt;&gt; | >> |g" \
    -e "s| &amp; | \& |g" \
    -e 's| &amp;&amp; | \&\& |g' \
    -e 's| &gt;&amp; | >\& |g' \
    $OUTFILE

# Convert remaining &lt;, &gt;, &amp;:
sed -i \
    -e 's|\&lt;\(---*\)|<\1|g' \
    -e 's|\&lt;-|<-|g' \
    -e 's|\(---*\)\&gt;|\1>|g' \
    -e 's|-\&gt;|->|g' \
    -e 's|\&gt;|>|g' \
    -e 's|\&lt;|<|g' \
    -e 's|\&gt;|>|g' \
    -e "s|&amp;|\&|g" \
    $OUTFILE

# ":<math>" seems to occur on Wikipedia - remove colon:
sed -i \
    -e 's|:\\\[|\\\[|g' \
    $OUTFILE

# Remove internal links:
sed -i \
    -e 's:\[\[[^]^|]*|\([^]]*\)\]\]:\1:g' \
    -e 's:\[\[\([^]]*\)\]\]:\1:g' \
    $OUTFILE

# Turn references into footnotes:
sed -i \
    -e 's|<ref name=\([^>]*\)>|\[fn:\1: |g' \
    -e 's|<ref>|\[fn:: |g' \
    -e 's|<\/ref>|\]|g' \
    -e 's|{{||g' \
    -e 's|}}||g' \
    $OUTFILE

# Convert http(s) links:
sed -i \
    -e 's|\[\(https*:\/\/[^ ]*\) \([^]][^]]*\)\]|[[\1][\2]]|g' \
    $OUTFILE
#     -e 's|||g' \
#     -e 's|||g' \
#     -e 's|||g' \
        

echo



        
