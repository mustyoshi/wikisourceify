<?xml version="1.0" encoding="UTF-8" ?>
<!--
    xml2infobox.xsl
    Transform xml from deepbills into wikipedia header
    based on work created by Francis Avila on 2013-04-04.
    Don Whiteside 27 June 2013
-->
<stylesheet version="1.0"
    xmlns="http://www.w3.org/1999/XSL/Transform"
    xmlns:cato="http://namespaces.cato.org/catoxml"
    xmlns:str="http://exslt.org/strings"
    extension-element-prefixes="str">

<strip-space elements="*"/>
<!-- <preserve-space elements="text continuation-text quoted-block-continuation-text quote"/> -->
<output encoding="UTF-8" method="text" omit-xml-declaration="yes" indent="no"/>

<variable name="people" select="document('../lookups/person.xml')"/>
<variable name="committees" select="document('../lookups/committee.xml')"/>
<variable name="federal-bodies" select="document('../lookups/federal-body.xml')"/>

<key name="wikipedia-id" match="/items/item/@wikipedia" use="../@id"/>
<key name="wikipedia-lis" match="/items/item/@wikipedia" use="../@lis_id"/>
<key name="nicename-id" match="/items/item/@name" use="../@id"/>
<key name="nicename-lis" match="/items/item/@name" use="../@lis_id"/>
<key name="committees" match="/doc/bill/form/action/committee-name" use="committee-id" />
<key name="federal-bodies" match="cato:entity-ref[@entity-type='federal-body']" use="@entity-id"/>
<key name="act-names" match="cato:entity-ref[@entity-type='act']" use="str:tokenize(@value, '/')[1]"/>

<template name="search-and-replace">
    <param name="input"/>
    <param name="search-string"/>
    <param name="replace-string"/>
    <choose>
    <when test="$search-string and contains($input,$search-string)">
       <value-of
           select="substring-before($input,$search-string)"/>
       <value-of select="$replace-string"/>
       <call-template name="search-and-replace">
         <with-param name="input" select="substring-after($input,$search-string)"/>
         <with-param name="search-string" select="$search-string"/>
         <with-param name="replace-string" select="$replace-string"/>
       </call-template>
    </when>
    <otherwise>
      <value-of select="$input"/>
    </otherwise>
    </choose>
</template>

<template match="text()">
    <!-- the normalization presentes an issue we'll need to address when it's getting down to certain levels -->
    <variable name="normalized" select="normalize-space()"/>
    <variable name="wikiescape" select="contains(., '[') or contains(., '{{') or contains('.', &quot;&apos;&apos;&quot;)"/>
    <if test="$wikiescape">&lt;nowiki></if>
<!-- We're going to de-tab the text when we get down to the nitty-gritty, else it goofs up the wikiheaders etc -->
   <call-template name="search-and-replace">
     <with-param name="input" select="$normalized" />
     <with-param name="search-string" select="'&#x9;'" />
     <with-param name="replace-string" select="''" />
   </call-template>
<!--     <copy select="$normalized"/> -->
    <if test="$wikiescape">&lt;/nowiki></if>
    <if test="string-length($normalized)=0 and string-length(.)>0">
        <text> </text>
    </if>
</template>

<!-- <template match="*[@display-inline='no-display-inline'] | text[not(@display-inline)]">
    <text>&#xA;</text>
    <apply-templates/>
    <text>&#xA;</text>
</template>
 -->

<template match="quote">
    <text>“</text>
    <apply-templates/>
    <text>”</text>
</template>

<template name="wikipedia-id">
    <param name="id"/>
    <param name="lookupdoc"/>
    <for-each select="$lookupdoc">
        <value-of select="key('wikipedia-id', $id)"/>
    </for-each>
</template>

<template name="wikipedia-lis">
    <param name="id"/>
    <param name="lookupdoc"/>
    <for-each select="$lookupdoc">
        <value-of select="key('wikipedia-lis', $id)"/>
    </for-each>
</template>

<template name="wikipedia-name-lis">
    <param name="id"/>
    <param name="lookupdoc"/>
    <for-each select="$lookupdoc">
        <value-of select="key('nicename-lis', $id)"/>
    </for-each>
</template>

<template name="wikipedia-name-id">
    <param name="id"/>
    <param name="lookupdoc"/>
    <for-each select="$lookupdoc">
        <value-of select="key('nicename-id', $id)"/>
    </for-each>
</template>

<template name="wikilinkperson">
    <!-- this now needs to cope with the fact that when the code starts with S we need to look for senate IDs not bioguides 
    WHICH IS SO ANNOYING.
    -->
    <param name="id"/>
    <!-- crop off the first letter, is it an S? Senate. Else bioguide. -->
    <variable name="wikipage">
        <if test="string-length($id) = 7">
            <call-template name="wikipedia-id">
                <with-param name="id" select="$id"/>
                <with-param name="lookupdoc" select="$people"/>
            </call-template>
        </if>
        <if test="string-length($id) = 4">
            <call-template name="wikipedia-lis">
                <with-param name="id" select="$id"/>
                <with-param name="lookupdoc" select="$people"/>
            </call-template>
        </if>
    </variable>
    <variable name="wikiname">
        <if test="string-length($id) = 7">
            <call-template name="wikipedia-name-id">
                <with-param name="id" select="$id"/>
                <with-param name="lookupdoc" select="$people"/>
            </call-template>
        </if>
        <if test="string-length($id) = 4">
            <call-template name="wikipedia-name-lis">
                <with-param name="id" select="$id"/>
                <with-param name="lookupdoc" select="$people"/>
            </call-template>
        </if>
    </variable>    
    <text>[[</text>
    <value-of select="$wikipage"/>
    <text>|</text>
    <value-of select="$wikiname"/>    
    <text>]] </text>
</template>

<template name="wikilinkcommittee">
    <param name="id"/>
    <variable name="wikipage">
        <call-template name="wikipedia-id">
            <with-param name="id" select="$id"/>
            <with-param name="lookupdoc" select="$committees"/>
        </call-template>
    </variable>
    <variable name="wikiname">
        <call-template name="wikipedia-name-id">
            <with-param name="id" select="$id"/>
            <with-param name="lookupdoc" select="$committees"/>
        </call-template>
    </variable>    
    <text>[[</text>
    <value-of select="$wikipage"/>
    <text>]], </text>
</template>

<template match="committee-name">
    <call-template name="wikilinkcommittee">
        <with-param name="id" select="(@committee-id | @committee)[1]"/>
    </call-template>
</template>

<variable name="author">
    <variable name="normalized" select="normalize-space()"/>
    <variable name="authorid" select="(//sponsor/@name-id)[1]"/>
    <variable name="wikiit">
        <call-template name="wikilinkperson">
            <with-param name="id" select="$authorid"/>
        </call-template>
    </variable> 
    <value-of select="$wikiit"/>
</variable>

<variable name="chamber">
    <variable name="chamber-code" select="//docmeta/bill/@type"/>
    <variable name="chamber-char" select="substring($chamber-code, 1, 1)"/>
    <if test="$chamber-char='h'"><text>House</text></if>
    <if test="$chamber-char='s'"><text>Senate</text></if>
</variable>

<variable name="shorttitle" select="//short-title[text()]"/>
<variable name="fulltitle" select="//official-title[text()]"/>
<variable name="besttitle" select="//short-title[text()] | //official-title[text() and not (//short-title[text()])]"/>
<variable name="billtype" select="/doc/docmeta/bill/@type"/>
<variable name="action-date" select="*[2]/form/action/action-date/@date"/>

<template name="wikilink">
    <param name="id"/>
    <param name="idx"/>
    <variable name="wikipage">
        <call-template name="wikipedia-id">
            <with-param name="id" select="$id"/>
            <with-param name="lookupdoc" select="$idx"/>
        </call-template>
    </variable>
    <choose>
        <when test="$wikipage">
            <text>[[</text>
            <value-of select="$wikipage"/>
            <text>|</text>
            <apply-templates/>
            <text>]], </text>
        </when>
        <otherwise>
            <apply-templates/>
        </otherwise>
    </choose>
</template>

<!-- We've added this because we want the full wikipedia names for these wikilinks (as opposed to the people)
 -->
 <template name="wikilinkfederalbodies">
    <param name="id"/>
    <param name="idx"/>
    <variable name="wikipage">
        <call-template name="wikipedia-id">
            <with-param name="id" select="$id"/>
            <with-param name="lookupdoc" select="$idx"/>
        </call-template>
    </variable>
    <choose>
        <when test="$wikipage">
            <text>[[</text>
            <value-of select="$wikipage"/>
            <text>]], </text>
        </when>
        <otherwise>
            <apply-templates/>
        </otherwise>
    </choose>
</template>

<template match="cato:entity[@entity-type='auth-auth-approp']">
 <!-- within this we need the funds-and-year tag for elements @amount & @year -->
     <for-each select="cato:funds-and-year">
        <text>[AAA:(amount:</text>
        <value-of select="concat(@amount, '|year:', @year)"/>
        <text>)],</text>
    </for-each>
</template>

<template match="cato:entity[@entity-type='auth-approp']">
 <!-- within this we need the funds-and-year tag for elements @amount & @year -->
<!--     <text>[AA:</text>
    <value-of select="concat(@amount, '|', @year)"/>
    <text>].</text>    
 -->
     <for-each select="cato:funds-and-year">
        <text>[AA:(amount:</text>
        <value-of select="concat(@amount, '|year:', @year)"/>
        <text>)],</text>
    </for-each>
</template>

<template match="cato:entity-ref[@entity-type='federal-body']">
            <call-template name="wikilinkfederalbodies">
                <with-param name="id" select="(@entity-id | @entity-parent-id)[1]"/>
                <with-param name="idx" select="$federal-bodies"/>
            </call-template>
</template>    

<!-- This may actually not be necessary; do we not have anywhere in the info box for PL? -->
 <template match="cato:entity-ref[@entity-type='public-law']">
    <variable name="parts" select="str:tokenize(@value, '/')"/>
    <variable name="congress" select="$parts[2]"/>
    <variable name="pl-number" select="$parts[3]"/>
    <text>{{USPL|</text>
    <value-of select="concat($congress, '|', $pl-number)"/>
    <text>}},</text>
</template>

<template match="cato:entity-ref[@entity-type='statute-at-large']">
    <variable name="parts" select="str:tokenize(@value, '/')"/>
    <variable name="congress" select="$parts[2]"/>
    <variable name="sal-number" select="$parts[3]"/>
    <text>{{USStatute|</text>
    <value-of select="concat($congress, '|', $sal-number)"/>
    <text>}},</text>
</template>


<!-- 
AHA! we need a rule to detect the ones we DON'T want and return an empty value!!!

TODO

{{USCSub|42|1395x}}, {{USCSub|20|1061}}, {{USCSub|20|1033}}, subchapter 1 ofchapter 57of title 5, United States Code{{USCSub|31|1342}}

<cato:entity-ref xmlns:cato="http://namespaces.cato.org/catoxml" entity-type="uscode" value="usc-chapter/5/57/1">
    subchapter 1 of 
    <external-xref legal-doc="usc-chapter" parsable-cite="usc-chapter/5/57">chapter 57</external-xref> 
    of title 5, United States Code
</cato:entity-ref>


we're ending up with:

, subchapter 1 ofchapter 57of title 5, United States Code{{USCSub|31|1342}}
 -->
<template match="external-xref[@legal-doc='usc' and parent::cato:entity-ref[@entity-type='uscode']]">
    <text></text>
</template>

<!-- This is falsely matching on usc-chapter -->
<template match="cato:entity-ref[@entity-type='uscode']">
    <variable name="parts" select="str:tokenize(@value, '/')"/>
    <variable name="descr" select="$parts[1]"/>    
    <variable name="title" select="$parts[2]"/>
    <variable name="section" select="$parts[3]"/>
    <variable name="ss1" select="$parts[4]"/>
    <variable name="ss2" select="$parts[5]"/>
    <variable name="ss3" select="$parts[6]"/>
    <text></text>
    <if test="string-length($title) > 0">
        <choose>
        <when test="$descr = 'usc-chapter'">
            <text>{{Usc-title-chap|</text>
        </when>
        <when test="$descr = 'usc-appendix'">
            <text>{{USC|</text>
        </when>        
        <when test="$descr = 'usc'">
            <text>{{USC|</text>
        </when>
        <otherwise>
            <text>{{***UNHANDLED-ERROR|</text>            
        </otherwise>
        </choose>      
        <value-of select="$title"/>
        <if test="string-length($section) > 0">
            <text>|</text><value-of select="$section"/>
        </if>
        <text>}}</text>   
        <!-- the etseq could be anywhere. The test is redundant but readable & short-circuit not worth complexity -->     
        <if test="$ss1='etseq'"><text> et seq.</text></if>
        <if test="$ss2='etseq'"><text> et seq.</text></if>
        <if test="$ss2='etseq'"><text> et seq.</text></if>
    </if>    
    <text>, </text>     
</template>

<template match="cato:entity-ref[@entity-type='act']">
    <variable name="parts" select="str:tokenize(@value, '/')"/>
    <variable name="title" select="$parts[1]"/>
    <text>"</text>
    <value-of select="$title"/>
    <text> [</text>
    <value-of select="count(key('act-names', $title))"/>    
    <text>]</text>

    <text>", </text>
</template>

<!-- 
we need to cope with fact that amount might be indefinite
-->
<variable name="appropriated-amount" select="sum(//cato:funds-and-year/@amount)"/>
<!-- 
wuff what a hassle. this is option but may have values like:
2015
2015,2017,2019
2012..2020
2014,..
..,2016

<variable name="appropriated-start" select="min(//cato:funds-and-year/@year)"/>
<variable name="appropriated-end" select="max(//cato:funds-and-year/@year)"/>
-->
<!-- example: <cato:funds-and-year amount="2800000000" year="2014..2018">-->

<template name="appropriated-sum">
      <!-- Initialize nodes to empty node set -->
      <param name="nodes" select="/.."/>
      <param name="result" select="0"/>
      <choose>
        <when test="not($nodes)">
          <value-of select="$result"/>
        </when>
        <otherwise>
            <!-- call or apply template that will determine value of node
              unless the node is literally the value to be summed -->
          <variable name="value">
            <call-template name="some-function-of-a-node">
              <with-param name="node" select="$nodes[1]"/>
            </call-template>
          </variable>
            <!-- recurse to sum rest -->
<call-template name="appropriated-sum">
<with-param name="nodes" select="$nodes[position() != 1]"/> <with-param name="result" select="$result + $value"/>
          </call-template>
        </otherwise>
      </choose>
    </template>

<!-- Deduped! -->
<variable name="agencies-affected">
    <apply-templates select="//cato:entity-ref[@entity-type='federal-body' 
        and generate-id(.) = generate-id(key('federal-bodies', (@entity-id | @entity-parent-id)[1])[1])
        ]">
        <sort select="(@entity-id | @entity-parent-id)[1]"/>
    </apply-templates>
</variable>

<!-- DON TESTING -->
<template name="act-name-only">
    <value-of select="str:tokenize(element()/@value, '/')[1]"/>
</template>

<variable name="acts">
    <apply-templates select="//cato:entity-ref[@entity-type='act' 
        and generate-id(.) = generate-id(key('act-names', str:tokenize(@value, '/')[1])[1])
        ]">
        <sort select="@value" />
    </apply-templates>
</variable>


<key name="act-names" match="cato:entity-ref[@entity-type='act']" use="str:tokenize(@value, '/')[1]"/>

<variable name="public-law">
    <apply-templates select="//cato:entity-ref[@entity-type='public-law']"/>
</variable>

<variable name="uscode">
    <apply-templates select="//cato:entity-ref[@entity-type='uscode']"/>
</variable>

<variable name="statute-at-large">
    <apply-templates select="//cato:entity-ref[@entity-type='statute-at-large']"/>
</variable>

<variable name="auth-approp">
    <apply-templates select="//cato:entity[@entity-type='auth-auth-approp']"/>
</variable>

<variable name="approp">
    <apply-templates select="//cato:entity[@entity-type='auth-approp']"/>
</variable>

<template match="/doc">
<!--
<variable name="committee-referred">
    <call-template name="wikipedia-key">
        <with-param name="id" select="HGO00"/>
        <with-param name="idx" select="$committees"/>
    </call-template>
</variable>
-->
{{Infobox United States federal proposed legislation
| name            = <value-of select="normalize-space($shorttitle)"/>
| fullname        = <value-of select="normalize-space($fulltitle)"/>
| acronym         = 
| nickname        = <!--Unofficial name used by the press or general public-->
| introduced in the = <value-of select="docmeta/bill/@congress"/>th<!--Name of Congress. (e.g. 1st, 10th, 100th). Auto-links to corresponding page. Adding other characters breaks the link-->
| introduceddate   = <value-of select="$action-date"/><!--date of introduction-->
| sponsored by    = <value-of select="$author"/>
| number of co-sponsors = <value-of select="count(//cosponsor)"/>
| public law url  = 
| cite public law = <!-- <value-of select="$public-law"/> --><!--{{USPL|XXX|YY}} where X is the congress number and Y is the law number-->
| cite statutes at large = <!--<value-of select="$statute-at-large"/>--><!--{{usstat}} can be used-->
| acts affected    = <value-of select="$acts"/><!--list, if applicable; make wikilinks where possible-->
| acts repealed   = <!--list, if applicable; make wikilinks where possible-->
| title affected   = <!--US code titles changed-->
| sections created = <!--{{USC}} can be used-->
| sections affected = <value-of select="$uscode"/><!--list, if applicable; make wikilinks where possible-->
| agenciesaffected = <value-of select="$agencies-affected"/> <!--list of federal agencies that would be affected by the legislation, wikilinks where possible-->
| authorizationsofappropriations = <value-of select="$auth-approp"/> <!--a dollar amount, with dollar sign, possibly including a time period-->
| appropriations = <value-of select="$approp"/> <!--a dollar amount, with dollar sign, possibly including a time period-->
| leghisturl      = 
| introducedin    = <value-of select="$chamber"/>
| introducedbill  = {{USBill|<value-of select="docmeta/bill/@congress"/>|<value-of select="$billtype"/>|<value-of select="docmeta/bill/@number"/>}}
| introducedby    = <value-of select="$author"/>
| introduceddate  = <value-of select="normalize-space(*[2]/form/action/action-date[text()])"/>
| committees      = <apply-templates select="bill/form/action/action-desc/committee-name"/>
| passedbody1     = <!--House or Senate-->
| passeddate1     = <!--date of passage-->
| passedvote1     = <!--give vote numbers, external link to roll call list where possible-->
| passedbody2     = <!--House or Senate-->
| passedas2       = <!-- used if the second body changes the name of the legislation -->
| passeddate2     = <!--date of passage-->
| passedvote2     = <!--give vote numbers, external link to roll call list where possible-->
| conferencedate  = 
| passedbody3     = 
| passeddate3     = 
| passedvote3     = 
| agreedbody3     = <!-- used when the other body agrees without going into committee -->
| agreeddate3     = <!-- used when the other body agrees without going into committee -->
| agreedvote3     = <!-- used when the other body agrees without going into committee -->
| agreedbody4     = <!-- used if agreedbody3 further amends legislation -->
| agreeddate4     = <!-- used if agreedbody3 further amends legislation -->
| agreedvote4     = <!-- used if agreedbody3 further amends legislation -->
| passedbody4     = 
| passeddate4     = 
| passedvote4     = 
| signedpresident = <!--name of the president, as wikilink-->
| signeddate      = 
| unsignedpresident = <!-- used when passed without presidential signing -->
| unsigneddate    = <!-- used when passed without presidential signing -->
| vetoedpresident = <!-- used when passed by overriding presidential veto -->
| vetoeddate      = <!-- used when passed by overriding presidential veto -->
| overriddenbody1 = <!-- used when passed by overriding presidential veto -->
| overriddendate1 = <!-- used when passed by overriding presidential veto -->
| overriddenvote1 = <!-- used when passed by overriding presidential veto -->
| overriddenbody2 = <!-- used when passed by overriding presidential veto -->
| overriddendate2 = <!-- used when passed by overriding presidential veto -->
| overriddenvote2 = <!-- used when passed by overriding presidential veto -->
| amendments      = 
| SCOTUS cases    = 
}}
</template>
</stylesheet>