<?xml version="1.0" encoding="UTF-8"?>
<!-- 
	Copyright © Nictiz
	see https://www.nictiz.nl/

    This file is part of Medicatieviewer
	
	This program is free software; you can redistribute it and/or modify it under the terms of the
	GNU Lesser General Public License as published by the Free Software Foundation; either version
	3.0 of the License, or (at your option) any later version.
	
	This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
	without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
	See the GNU Lesser General Public License for more details.
	
	The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:hl7="urn:hl7-org:v3"
    xmlns:fhir="http://hl7.org/fhir"
    xmlns:util="urn:hl7:utilities"
    exclude-result-prefixes="xs xd util hl7 fhir"
    version="1.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> May 11, 2017</xd:p>
            <xd:p><xd:b>Author:</xd:b> ahenket</xd:p>
            <xd:p></xd:p>
        </xd:desc>
    </xd:doc>
    
    <xd:doc>
        <xd:desc>
            <xd:p>Vocabulary file containing language dependant strings such as labels</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:param name="util:vocFile" select="'utilities-l10n.xml'"/>
    
    <xd:doc>
        <xd:desc>
            <xd:p>Cache language dependant strings</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:variable name="util:vocMessages" select="document($util:vocFile)"/>
    
    <xd:doc>
        <xd:desc>
            <xd:p>Retrieves a language dependant string from our <xd:ref name="vocFile" type="parameter">language file</xd:ref> such as a label based on a key. Returns string based on <xd:ref name="textLang" type="parameter">textLang</xd:ref>, <xd:ref name="textLangDefault" type="parameter">textLangDefault</xd:ref>, the first two characters of the textLangDefault, e.g. 'en' in 'en-US' and finally if all else fails just the key text.</xd:p>
        </xd:desc>
        <xd:param name="pre">Some text or space to prefix our string with</xd:param>
        <xd:param name="key">The key to find our text with</xd:param>
        <xd:param name="post">Some text like a colon or space to postfix our text with</xd:param>
        <xd:param name="textlangDefault"/>
        <xd:param name="textLang"/>
    </xd:doc>
    <xsl:template name="util:getLocalizedString">
        <xsl:param name="pre" select="''"/>
        <xsl:param name="key"/>
        <xsl:param name="post" select="''"/>
        <xsl:param name="textlangDefault" select="'en-US'"/>
        <xsl:param name="textLang">
            <xsl:choose>
                <xsl:when test="/hl7:ClinicalDocument/hl7:languageCode/@code">
                    <xsl:value-of select="/hl7:ClinicalDocument/hl7:languageCode/@code"/>
                </xsl:when>
                <xsl:when test="//fhir:*/fhir:language/@value">
                    <xsl:value-of select="(//fhir:*/fhir:language/@value)[1]"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$textlangDefault"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:param>
        
        <!-- Do lowercase compare of default language+region-->
        <xsl:variable name="textLangDefaultLowerCase">
            <xsl:call-template name="util:caseDown">
                <xsl:with-param name="data" select="$textlangDefault"/>
            </xsl:call-template>
        </xsl:variable>
        <!-- Do lowercase compare of default language (assume alpha2 not alpha3) -->
        <xsl:variable name="textLangDefaultPartLowerCase" select="substring($textLangDefaultLowerCase,1,2)"/>
        <!-- Do lowercase compare of language+region -->
        <xsl:variable name="textLangLowerCase">
            <xsl:call-template name="util:caseDown">
                <xsl:with-param name="data" select="$textLang"/>
            </xsl:call-template>
        </xsl:variable>
        <!-- Do lowercase compare of language (assume alpha2 not alpha3) -->
        <xsl:variable name="textLangPartLowerCase" select="substring($textLangLowerCase,1,2)"/>
        
        <xsl:choose>
            <!-- compare 'de-CH' -->
            <xsl:when test="$util:vocMessages/*/*/key[@value=$key]/value[@lang=$textLangLowerCase]">
                <xsl:value-of select="concat($pre,$util:vocMessages//key[@value=$key]/value[@lang=$textLangLowerCase]/text(),$post)"/>
            </xsl:when>
            <!-- compare 'de' in 'de-CH' -->
            <xsl:when test="$util:vocMessages/*/*/key[@value=$key]/value[substring(@lang, 1, 2)=$textLangPartLowerCase]">
                <xsl:value-of select="concat($pre,$util:vocMessages//key[@value=$key]/value[substring(@lang, 1, 2)=$textLangPartLowerCase]/text(),$post)"/>
            </xsl:when>
            <!-- compare 'en-US' -->
            <xsl:when test="$util:vocMessages/*/*/key[@value=$key]/value[@lang=$textLangDefaultLowerCase]">
                <xsl:value-of select="concat($pre,$util:vocMessages//key[@value=$key]/value[@lang=$textLangDefaultLowerCase]/text(),$post)"/>
            </xsl:when>
            <!-- compare 'en' in 'en-US' -->
            <xsl:when test="$util:vocMessages/*/*/key[@value=$key]/value[substring(@lang, 1, 2)=$textLangDefaultPartLowerCase]">
                <xsl:value-of select="concat($pre,$util:vocMessages//key[@value=$key]/value[substring(@lang, 1, 2)=$textLangDefaultPartLowerCase]/text(),$post)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="concat($pre,$key,$post)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            <xd:p>Converts Latin characters in input to lower case and returns the result</xd:p>
        </xd:desc>
        <xd:param name="data">Input string</xd:param>
    </xd:doc>
    <xsl:template name="util:caseDown">
        <xsl:param name="data"/>
        <xsl:if test="$data">
            <xsl:value-of select="translate($data, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz')"/>
        </xsl:if>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            <xd:p>Converts Latin characters in input to upper case and returns the result</xd:p>
        </xd:desc>
        <xd:param name="data">Input string</xd:param>
    </xd:doc>
    <xsl:template name="util:caseUp">
        <xsl:param name="data"/>
        <xsl:if test="$data">
            <xsl:value-of select="translate($data,'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')"/>
        </xsl:if>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            <xd:p>Converts first character in input to upper case if it is a Latin character and returns the result</xd:p>
        </xd:desc>
        <xd:param name="data">Input string</xd:param>
    </xd:doc>
    <xsl:template name="util:firstCharCaseUp">
        <xsl:param name="data"/>
        <xsl:if test="$data">
            <xsl:call-template name="util:caseUp">
                <xsl:with-param name="data" select="substring($data,1,1)"/>
            </xsl:call-template>
            <xsl:value-of select="substring($data,2)"/>
        </xsl:if>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            <xd:p>Tokenize based on delimiters, or if no delimiter do character tokenization</xd:p>
        </xd:desc>
        <xd:param name="string">String to tokenize</xd:param>
        <xd:param name="delimiters">Optional delimiter string</xd:param>
        <xd:param name="prefix">Optional prefix for every 'array' item</xd:param>
    </xd:doc>
    <xsl:template name="util:tokenize">
        <xsl:param name="string" select="''"/>
        <xsl:param name="delimiters" select="' '"/>
        <xsl:param name="prefix"/>
        <xsl:choose>
            <xsl:when test="not($string)"/>
            <xsl:when test="not($delimiters)">
                <xsl:call-template name="util:_tokenize-characters">
                    <xsl:with-param name="string" select="$string"/>
                    <xsl:with-param name="prefix" select="$prefix"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="util:_tokenize-delimiters">
                    <xsl:with-param name="string" select="$string"/>
                    <xsl:with-param name="delimiters" select="$delimiters"/>
                    <xsl:with-param name="prefix" select="$prefix"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            <xd:p>Tokenize every character</xd:p>
        </xd:desc>
        <xd:param name="string">String to tokenize</xd:param>
        <xd:param name="prefix">Optional prefix for every 'array' item</xd:param>
    </xd:doc>
    <xsl:template name="util:_tokenize-characters">
        <xsl:param name="string"/>
        <xsl:param name="prefix"/>
        <xsl:if test="$string">
            <xsl:call-template name="util:getLocalizedString">
                <xsl:with-param name="key" select="concat($prefix,substring($string, 1, 1))"/>
            </xsl:call-template>
            <xsl:call-template name="util:_tokenize-characters">
                <xsl:with-param name="string" select="substring($string, 2)"/>
                <xsl:with-param name="prefix" select="$prefix"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            <xd:p>Tokenize based on delimiters</xd:p>
        </xd:desc>
        <xd:param name="string">String to tokenize</xd:param>
        <xd:param name="delimiters">Required delimiter string</xd:param>
        <xd:param name="prefix">Optional prefix for every 'array' item</xd:param>
    </xd:doc>
    <xsl:template name="util:_tokenize-delimiters">
        <xsl:param name="string"/>
        <xsl:param name="delimiters"/>
        <xsl:param name="prefix"/>
        <xsl:variable name="delimiter" select="substring($delimiters, 1, 1)"/>
        <xsl:choose>
            <xsl:when test="not($delimiter)">
                <xsl:call-template name="util:getLocalizedString">
                    <xsl:with-param name="key" select="concat($prefix,$string)"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="contains($string, $delimiter)">
                <xsl:if test="not(starts-with($string, $delimiter))">
                    <xsl:call-template name="util:_tokenize-delimiters">
                        <xsl:with-param name="string" select="substring-before($string, $delimiter)"/>
                        <xsl:with-param name="delimiters" select="substring($delimiters, 2)"/>
                        <xsl:with-param name="prefix" select="$prefix"/>
                    </xsl:call-template>
                </xsl:if>
                <xsl:text> </xsl:text>
                <xsl:call-template name="util:_tokenize-delimiters">
                    <xsl:with-param name="string" select="substring-after($string, $delimiter)"/>
                    <xsl:with-param name="delimiters" select="$delimiters"/>
                    <xsl:with-param name="prefix" select="$prefix"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="util:_tokenize-delimiters">
                    <xsl:with-param name="string" select="$string"/>
                    <xsl:with-param name="delimiters" select="substring($delimiters, 2)"/>
                    <xsl:with-param name="prefix" select="$prefix"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            <xd:p>Show a nullFlavor as text</xd:p>
        </xd:desc>
        <xd:param name="in">The nullFlavor code, e.g. NI, OTH</xd:param>
    </xd:doc>
    <xsl:template name="util:show-nullFlavor">
        <xsl:param name="in"/>
        <xsl:if test="string-length($in) > 0">
            <xsl:value-of select="concat('nullFlavor_', $in)"/>
        </xsl:if>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            <xd:p>Show element with datatype EN, ON, PN, or TN</xd:p>
        </xd:desc>
        <xd:param name="in">One element, possibly out of a set</xd:param>
    </xd:doc>
    <xsl:template name="util:show-name">
        <xsl:param name="in"/>
        <xsl:if test="$in">
            <xsl:if test="$in/@use">
                <xsl:call-template name="util:tokenize">
                    <xsl:with-param name="prefix" select="'nameUse_'"/>
                    <xsl:with-param name="string" select="$in/@use"/>
                    <xsl:with-param name="delimiters" select="' '"/>
                </xsl:call-template>
                <xsl:text>: </xsl:text>
            </xsl:if>
            <xsl:if test="$in[@use][@nullFlavor]">
                <xsl:text> </xsl:text>
            </xsl:if>
            <xsl:call-template name="util:show-nullFlavor">
                <xsl:with-param name="in" select="$in/@nullFlavor"/>
            </xsl:call-template>
            <xsl:for-each select="$in/node()">
                <!-- 
                        Except for prefix, suffix and delimiter name parts, every name part is surrounded by implicit whitespace.
                        Leading and trailing explicit whitespace is insignificant in all those name parts. 
                    -->
                <xsl:if test="self::hl7:given[string-length(normalize-space(.)) > 0] | self::hl7:family[string-length(normalize-space(.)) > 0] | self::hl7:part[@type = 'GIV' or @type = 'FAM'][string-length(normalize-space(@value)) > 0]">
                    <xsl:text> </xsl:text>
                </xsl:if>
                <xsl:choose>
                    <xsl:when test="self::comment() | self::processing-instruction()"/>
                    <!-- DTr1 -->
                    <xsl:when test="self::hl7:family">
                        <xsl:call-template name="util:caseUp">
                            <xsl:with-param name="data" select="."/>
                        </xsl:call-template>
                    </xsl:when>
                    <!-- DTr2 -->
                    <xsl:when test="self::hl7:part[@type = 'FAM']">
                        <xsl:call-template name="util:caseUp">
                            <xsl:with-param name="data" select="@value"/>
                        </xsl:call-template>
                    </xsl:when>
                    <!-- DTr1 -->
                    <xsl:when test="self::hl7:prefix[contains(@qualifier, 'VV')]">
                        <xsl:call-template name="util:caseUp">
                            <xsl:with-param name="data" select="."/>
                        </xsl:call-template>
                        <xsl:text> </xsl:text>
                    </xsl:when>
                    <!-- DTr2 -->
                    <xsl:when test="self::hl7:part[@type = 'PFX' and contains(@qualifier, 'VV')]">
                        <xsl:call-template name="util:caseUp">
                            <xsl:with-param name="data" select="@value"/>
                        </xsl:call-template>
                        <xsl:text> </xsl:text>
                    </xsl:when>
                    <!-- DTr1 -->
                    <xsl:when test="self::hl7:prefix | self::hl7:given | self::delimiter">
                        <xsl:value-of select="."/>
                    </xsl:when>
                    <!-- DTr2 -->
                    <xsl:when test="self::hl7:part[@type = 'PFX' or @type = 'GIV' or @type = 'DEL']">
                        <xsl:value-of select="@value"/>
                    </xsl:when>
                    <xsl:when test="string-length(normalize-space(.)) > 0">
                        <xsl:value-of select="."/>
                    </xsl:when>
                    <!-- DTr2 -->
                    <xsl:when test="self::hl7:part[not(@type)][string-length(normalize-space(@value)) > 0]">
                        <xsl:value-of select="@value"/>
                    </xsl:when>
                </xsl:choose>
                <xsl:if test="self::hl7:given[string-length(normalize-space(.)) > 0] | self::hl7:family[string-length(normalize-space(.)) > 0] | self::hl7:part[@type = 'GIV' or @type = 'FAM'][string-length(normalize-space(@value)) > 0]">
                    <xsl:text> </xsl:text>
                </xsl:if>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            <xd:p>Show elements with datatype EN, ON, PN or TN separated with the value in 'sep'. Calls <xd:ref name="show-name" type="template">show-name</xd:ref></xd:p>
        </xd:desc>
        <xd:param name="in">Set of 0 to * elements</xd:param>
        <xd:param name="sep">Separator between output of different elements. Default ', ' and special is 'br' which generates an HTML br tag</xd:param>
    </xd:doc>
    <xsl:template name="util:show-name-set">
        <xsl:param name="in"/>
        <xsl:param name="sep" select="', '"/>
        <xsl:if test="$in">
            <xsl:choose>
                <!-- DTr1 -->
                <xsl:when test="count($in) > 1">
                    <xsl:for-each select="$in">
                        <xsl:call-template name="util:show-name">
                            <xsl:with-param name="in" select="."/>
                        </xsl:call-template>
                        <xsl:if test="position() != last()">
                            <xsl:choose>
                                <xsl:when test="$sep = 'br'">
                                    <br/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="$sep"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:when>
                <!-- DTr2 -->
                <xsl:when test="$in[hl7:item]">
                    <xsl:for-each select="$in/hl7:item">
                        <xsl:call-template name="util:show-name">
                            <xsl:with-param name="in" select="."/>
                        </xsl:call-template>
                        <xsl:if test="position() != last()">
                            <xsl:choose>
                                <xsl:when test="$sep = 'br'">
                                    <br/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="$sep"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:when>
                <!-- DTr1 or DTr2 -->
                <xsl:otherwise>
                    <xsl:call-template name="util:show-name">
                        <xsl:with-param name="in" select="$in"/>
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            <xd:p>Show element with datatype AD</xd:p>
        </xd:desc>
        <xd:param name="in">One element, possibly out of a set</xd:param>
        <xd:param name="withLineBreaks">Display the address on multiple lines (default), or on one line</xd:param>
    </xd:doc>
    <xsl:template name="util:show-address">
        <xsl:param name="in"/>
        <xsl:param name="withLineBreaks" select="true()"/>
        
        <xsl:if test="$in">
            <xsl:if test="$in/@use and $withLineBreaks">
                <xsl:call-template name="util:tokenize">
                    <xsl:with-param name="prefix" select="'addressUse_'"/>
                    <xsl:with-param name="string" select="$in/@use"/>
                    <xsl:with-param name="delimiters" select="' '"/>
                </xsl:call-template>
                <xsl:text>: </xsl:text>
            </xsl:if>
            <xsl:if test="$in[@use][@nullFlavor]">
                <xsl:text> </xsl:text>
            </xsl:if>
            <xsl:call-template name="util:show-nullFlavor">
                <xsl:with-param name="in" select="$in/@nullFlavor"/>
            </xsl:call-template>
            <xsl:for-each select="$in/node()">
                <xsl:choose>
                    <!-- DTr1 -->
                    <xsl:when test="self::hl7:streetName">
                        <!-- 
                            Look for
                            - streetName, houseNumber|houseNumberNumeric, additionalLocator, houseNumber|houseNumberNumeric or
                            - additionalLocator, houseNumber|houseNumberNumeric
                            in that order and nothing in between.
                        -->
                        <xsl:value-of select="."/>
                        <xsl:if test="following-sibling::hl7:*[1][local-name()='houseNumberNumeric']">
                            <xsl:text>&#160;</xsl:text>
                            <xsl:value-of select="following-sibling::hl7:*[1][local-name()='houseNumberNumeric']"/>
                        </xsl:if>
                        <xsl:if test="following-sibling::hl7:*[1][local-name()='houseNumber']">
                            <xsl:text>&#160;</xsl:text>
                            <xsl:value-of select="following-sibling::hl7:*[1][local-name()='houseNumber']"/>
                        </xsl:if>
                        <xsl:if test="not(preceding-sibling::hl7:*[1][local-name()='houseNumber' or local-name()='houseNumberNumeric'])">
                            <xsl:text>&#160;</xsl:text>
                            <xsl:value-of select="following-sibling::hl7:*[1][local-name()='houseNumber' or local-name()='houseNumberNumeric']/following-sibling::hl7:*[1][local-name()='additionalLocator']"/>
                            <xsl:if test="following-sibling::hl7:*[1][local-name()='houseNumber' or local-name()='houseNumberNumeric']/following-sibling::hl7:*[1][local-name()='additionalLocator']">
                                <xsl:if test="following-sibling::hl7:*[1][local-name()='houseNumber' or local-name()='houseNumberNumeric']/following-sibling::hl7:*[1][local-name()='additionalLocator']/following-sibling::hl7:*[1][local-name()='houseNumberNumeric']">
                                    <xsl:text>&#160;</xsl:text>
                                    <xsl:value-of select="following-sibling::hl7:*[1][local-name()='houseNumber' or local-name()='houseNumberNumeric']/following-sibling::hl7:*[1][local-name()='additionalLocator']/following-sibling::hl7:*[1][local-name()='houseNumberNumeric']"/>
                                </xsl:if>
                                <xsl:if test="following-sibling::hl7:*[1][local-name()='houseNumber' or local-name()='houseNumberNumeric']/following-sibling::hl7:*[1][local-name()='additionalLocator']/following-sibling::hl7:*[1][local-name()='houseNumber']">
                                    <xsl:text>&#160;</xsl:text>
                                    <xsl:value-of select="following-sibling::hl7:*[1][local-name()='houseNumber' or local-name()='houseNumberNumeric']/following-sibling::hl7:*[1][local-name()='additionalLocator']/following-sibling::hl7:*[1][local-name()='houseNumber']"/>
                                </xsl:if>
                            </xsl:if>
                        </xsl:if>
                        <xsl:if test="following-sibling::*[not(local-name()='houseNumber')][not(local-name()='houseNumberNumeric')][not(local-name()='additionalLocator')][string-length(.) > 0 or @code]">
                            <xsl:choose>
                                <xsl:when test="$withLineBreaks"><br/></xsl:when>
                                <xsl:otherwise></xsl:otherwise>  <!-- Space already present -->
                            </xsl:choose>
                        </xsl:if>
                    </xsl:when>
                    <!-- DTr2 -->
                    <xsl:when test="self::hl7:part[@type='STR']">
                        <!-- 
                            Look for
                            - streetName, houseNumber|houseNumberNumeric, additionalLocator, houseNumber|houseNumberNumeric or
                            - additionalLocator, houseNumber|houseNumberNumeric
                            in that order and nothing in between.
                        -->
                        <xsl:value-of select="@value"/>
                        <xsl:if test="following-sibling::hl7:part[1][@type='BNN']">
                            <xsl:text>&#160;</xsl:text>
                            <xsl:value-of select="following-sibling::hl7:part[1][@type='BNN']/@value"/>
                        </xsl:if>
                        <xsl:if test="following-sibling::hl7:part[1][@type='BNR']">
                            <xsl:text>&#160;</xsl:text>
                            <xsl:value-of select="following-sibling::hl7:part[1][@type='BNR']/@value"/>
                        </xsl:if>
                        <xsl:if test="not(preceding-sibling::hl7:part[1][@type='BNN' or @type='BNR'])">
                            <xsl:text>&#160;</xsl:text>
                            <xsl:value-of select="following-sibling::hl7:part[1][@type='BNN' or @type='BNR']/following-sibling::hl7:part[1][@type='ADL']"/>
                            <xsl:if test="following-sibling::hl7:part[1][@type='BNN' or @type='BNR']/following-sibling::hl7:part[1][@type='ADL']/@value">
                                <xsl:if test="following-sibling::hl7:part[1][@type='BNN' or @type='BNR']/following-sibling::hl7:part[1][@type='ADL']/following-sibling::part[1][@type='BNN']">
                                    <xsl:text>&#160;</xsl:text>
                                    <xsl:value-of select="following-sibling::hl7:part[1][@type='BNN' or @type='BNR']/following-sibling::hl7:part[1][@type='ADL']/following-sibling::part[1][@type='BNN']/@value"/>
                                </xsl:if>
                                <xsl:if test="following-sibling::hl7:part[1][@type='BNN' or @type='BNR']/following-sibling::hl7:part[1][@type='ADL']/following-sibling::part[1][@type='BNR']">
                                    <xsl:text>&#160;</xsl:text>
                                    <xsl:value-of select="following-sibling::hl7:part[1][@type='BNN' or @type='BNR']/following-sibling::hl7:part[1][@type='ADL']/following-sibling::hl7:part[1][@type='BNR']/@value"/>
                                </xsl:if>
                            </xsl:if>
                        </xsl:if>
                        <xsl:if test="following-sibling::hl7:part[1][@type='BNR'][@type='BNN'][@type='ADL'][string-length(@value) > 0 or @code]">
                            <xsl:choose>
                                <xsl:when test="$withLineBreaks"><br/></xsl:when>
                                <xsl:otherwise><xsl:text> </xsl:text></xsl:otherwise>
                            </xsl:choose>
                        </xsl:if>
                    </xsl:when>
                    <!-- DTr1 -->
                    <xsl:when test="self::hl7:houseNumber or self::hl7:houseNumberNumeric">
                        <xsl:if test="not(preceding-sibling::hl7:*[1][local-name()='streetName' or local-name()='additionalLocator'])">
                            <xsl:value-of select="."/>
                            <xsl:if test="following-sibling::hl7:*[1][string-length(.) > 0 or @code]">
                                <xsl:choose>
                                    <xsl:when test="$withLineBreaks"><br/></xsl:when>
                                    <xsl:otherwise><xsl:text> </xsl:text></xsl:otherwise>
                                </xsl:choose>
                            </xsl:if>
                        </xsl:if>
                    </xsl:when>
                    <!-- DTr2 -->
                    <xsl:when test="self::hl7:part[@type='BNN' or @type='BNR']">
                        <xsl:if test="not(preceding-sibling::hl7:*[1][hl7:part[@type='STR' or @type='ADL']])">
                            <xsl:value-of select="@value"/>
                            <xsl:if test="following-sibling::hl7:part[1][string-length(@value) > 0 or @code]">
                                <xsl:choose>
                                    <xsl:when test="$withLineBreaks"><br/></xsl:when>
                                    <xsl:otherwise><xsl:text> </xsl:text></xsl:otherwise>
                                </xsl:choose>
                            </xsl:if>
                        </xsl:if>
                    </xsl:when>
                    <!-- DTr1 -->
                    <xsl:when test="self::hl7:additionalLocator">
                        <xsl:if test="not(preceding-sibling::hl7:*[1][local-name()='houseNumber' or local-name()='houseNumberNumeric'])">
                            <xsl:value-of select="."/>
                            <xsl:if test="following-sibling::hl7:*[1][local-name()='houseNumberNumeric']">
                                <xsl:text>&#160;</xsl:text>
                                <xsl:value-of select="following-sibling::hl7:*[1][local-name()='houseNumberNumeric']"/>
                            </xsl:if>
                            <xsl:if test="following-sibling::hl7:*[1][local-name()='houseNumber']">
                                <xsl:text>&#160;</xsl:text>
                                <xsl:value-of select="following-sibling::hl7:*[1][local-name()='houseNumber']"/>
                            </xsl:if>
                            <xsl:if test="following-sibling::hl7:*[1][string-length(.) > 0 or @code]">
                                <xsl:choose>
                                    <xsl:when test="$withLineBreaks"><br/></xsl:when>
                                    <xsl:otherwise><xsl:text> </xsl:text></xsl:otherwise>
                                </xsl:choose>
                            </xsl:if>
                        </xsl:if>
                    </xsl:when>
                    <!-- DTr2 -->
                    <xsl:when test="self::hl7:part[@type='ADL']">
                        <xsl:if test="not(preceding-sibling::hl7:*[1][@type='BNN' or @type='BNR'])">
                            <xsl:value-of select="@value"/>
                            <xsl:if test="following-sibling::hl7:*[1][@type='BNN']">
                                <xsl:text>&#160;</xsl:text>
                                <xsl:value-of select="following-sibling::hl7:*[1][@type='BNN']/@value"/>
                            </xsl:if>
                            <xsl:if test="following-sibling::hl7:*[1][@type='BNR']">
                                <xsl:text>&#160;</xsl:text>
                                <xsl:value-of select="following-sibling::hl7:*[1][@type='BNR']/@value"/>
                            </xsl:if>
                            <xsl:if test="following-sibling::hl7:part[1][string-length(@value) > 0 or @code]">
                                <xsl:choose>
                                    <xsl:when test="$withLineBreaks"><br/></xsl:when>
                                    <xsl:otherwise><xsl:text> </xsl:text></xsl:otherwise>
                                </xsl:choose>
                            </xsl:if>
                        </xsl:if>
                    </xsl:when>
                    <!-- DTr1 -->
                    <xsl:when test="self::hl7:postBox">
                        <xsl:call-template name="util:getLocalizedString">
                            <xsl:with-param name="key" select="'Postbox'"/>
                            <xsl:with-param name="post" select="' '"/>
                        </xsl:call-template>
                        <xsl:value-of select="."/>
                        <xsl:if test="following-sibling::hl7:*[1][string-length(.) > 0 or @code]">
                            <xsl:choose>
                                <xsl:when test="$withLineBreaks"><br/></xsl:when>
                                <xsl:otherwise><xsl:text> </xsl:text></xsl:otherwise>
                            </xsl:choose>
                        </xsl:if>
                    </xsl:when>
                    <!-- DTr2 -->
                    <xsl:when test="self::hl7:part[@type='POB']">
                        <xsl:call-template name="util:getLocalizedString">
                            <xsl:with-param name="key" select="'Postbox'"/>
                            <xsl:with-param name="post" select="' '"/>
                        </xsl:call-template>
                        <xsl:value-of select="@value"/>
                        <xsl:if test="following-sibling::hl7:part[1][string-length(@value) > 0 or @code]">
                            <xsl:choose>
                                <xsl:when test="$withLineBreaks"><br/></xsl:when>
                                <xsl:otherwise><xsl:text> </xsl:text></xsl:otherwise>
                            </xsl:choose>
                        </xsl:if>
                    </xsl:when>
                    <!-- DTr1 -->
                    <xsl:when test="self::hl7:city">
                        <xsl:value-of select="."/>
                        <xsl:if test="../hl7:state[string-length(.)>0]">
                            <xsl:text>, </xsl:text>
                            <xsl:value-of select="../hl7:state"/>
                        </xsl:if>
                        <xsl:if test="following-sibling::hl7:*[1][string-length(.) > 0 or @code]">
                            <xsl:choose>
                                <xsl:when test="$withLineBreaks"><br/></xsl:when>
                                <xsl:otherwise><xsl:text> ; </xsl:text></xsl:otherwise>
                            </xsl:choose>
                        </xsl:if>
                    </xsl:when>
                    <!-- DTr2 -->
                    <xsl:when test="self::hl7:part[@type='CTY']">
                        <xsl:value-of select="@value"/>
                        <xsl:if test="../hl7:part[@type='STA'][string-length(@value)>0]">
                            <xsl:text>, </xsl:text>
                            <xsl:value-of select="../hl7:part[@type='STA']/@value"/>
                        </xsl:if>
                        <xsl:if test="following-sibling::hl7:part[1][string-length(@value) > 0 or @code]">
                            <xsl:choose>
                                <xsl:when test="$withLineBreaks"><br/></xsl:when>
                                <xsl:otherwise><xsl:text> </xsl:text></xsl:otherwise>
                            </xsl:choose>
                        </xsl:if>
                    </xsl:when>
                    <!-- DTr1 -->
                    <xsl:when test="self::hl7:state and not(../hl7:city)">
                        <xsl:if test="(string-length(preceding-sibling::hl7:*[1]) > 0 or preceding-sibling::*/@code)">
                            <br/>
                        </xsl:if>
                        <xsl:value-of select="."/>
                        <xsl:if test="(string-length(following-sibling::hl7:*[1]) > 0 or following-sibling::*/@code)">
                            <xsl:choose>
                                <xsl:when test="$withLineBreaks"><br/></xsl:when>
                                <xsl:otherwise><xsl:text>(11) </xsl:text></xsl:otherwise>
                            </xsl:choose>
                        </xsl:if>
                    </xsl:when>
                    <!-- DTr2 -->
                    <xsl:when test="self::hl7:part[@type='STA'] and not(../hl7:part[@type='CTY'])">
                        <xsl:if test="(string-length(preceding-sibling::hl7:*[1]/@value) > 0 or preceding-sibling::hl7:*/@code)">
                            <xsl:choose>
                                <xsl:when test="$withLineBreaks"><br/></xsl:when>
                                <xsl:otherwise><xsl:text> </xsl:text></xsl:otherwise>
                            </xsl:choose>
                        </xsl:if>
                        <xsl:value-of select="@value"/>
                        <xsl:if test="(string-length(following-sibling::hl7:*[1]/@value) > 0 or following-sibling::hl7:*/@code)">
                            <xsl:choose>
                                <xsl:when test="$withLineBreaks"><br/></xsl:when>
                                <xsl:otherwise><xsl:text> </xsl:text></xsl:otherwise>
                            </xsl:choose>
                        </xsl:if>
                    </xsl:when>
                    <!-- DTr1 -->
                    <xsl:when test="self::hl7:state"/>
                    <!-- DTr2 -->
                    <xsl:when test="self::hl7:part[@type='STA']"/>
                    <!-- DTr1 -->
                    <xsl:when test="string-length(text()) > 0">
                        <xsl:value-of select="."/>
                        <xsl:if test="(string-length(following-sibling::hl7:*[1]) > 0 or following-sibling::hl7:*/@code)">
                            <xsl:choose>
                                <xsl:when test="$withLineBreaks"><br/></xsl:when>
                                <xsl:otherwise><xsl:text> </xsl:text></xsl:otherwise>
                            </xsl:choose>
                        </xsl:if>
                    </xsl:when>
                    <!-- DTr2 -->
                    <xsl:when test="string-length(@value) > 0">
                        <xsl:value-of select="@value"/>
                        <xsl:if test="(string-length(following-sibling::hl7:*[1]/@value) > 0 or following-sibling::hl7:*/@code)">
                            <xsl:choose>
                                <xsl:when test="$withLineBreaks"><br/></xsl:when>
                                <xsl:otherwise><xsl:text> </xsl:text></xsl:otherwise>
                            </xsl:choose>
                        </xsl:if>
                    </xsl:when>
                    <xsl:otherwise> </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>
    
</xsl:stylesheet>