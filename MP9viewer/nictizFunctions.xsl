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
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" 
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xmlns:nf="http://www.nictiz.nl/functions"
    xmlns:util="urn:hl7:utilities"
    version="2.0">
    
    <xd:doc scope="stylesheet">
        <xd:desc>This NICTIZ stylesheet is meant to be included, and contains a collection of generic variables and functions.
        <br />The including function should define the nf namespace as in the stylesheet definition above.
        </xd:desc>
    </xd:doc>
    
    <!-- debugMessages = true means debug information is shown/logged to the message window -->     
    <xsl:variable name="debugNfMessages" as="xs:boolean" select="false()" />      
    
    <!--
      ++  INTERNATIONALIZATION
      -->
    
    <!-- For localized strings the Nictiz generic functionality from utilities.xsl (by Alexander Henket) is used. -->
    <xsl:include href="utilities.xsl"/>
    
    <!-- For now force Dutch as the language -->
    <xsl:variable name="nfLanguage" as="xs:string" select="'nl-NL'"/>
    
    <!-- Define the Date/Time format -->
    <xsl:variable name="nfDateFormat" as="xs:string" select="'[D01] [Mn] [Y0001]'"/>
    <xsl:variable name="nfDateTimeFormat" as="xs:string" select="concat($nfDateFormat, ' [H]:[m]:[s]')"/>
    <xsl:variable name="nfDateTimeLanguage" as="xs:string" select="substring($nfLanguage, 1, 2)"/>
    
    <xd:doc>
        <xd:desc>
            Function to get a (UI) string in the correct language, wrapping getLocalizedString from util:.
            <xd:p>The wrapper is for 2 reasons: a function call is more compact than a template call, and we can overrule the default language.</xd:p>
        </xd:desc>
        <xd:param name="key"/>
    </xd:doc>
    <xsl:function name="nf:getLocalizedString" as="xs:string">
        <xsl:param name="key" as="xs:string"/>
        
        <xsl:call-template name="util:getLocalizedString">
            <xsl:with-param name="key" select="$key"/>
            <xsl:with-param name="textLang" select="$nfLanguage"/>
        </xsl:call-template>
        
    </xsl:function>


    <!--
      ++  DATE-TIME FUNCIONS
      -->
    
    <!-- 'Constants' that represent an invalid date or dateTime. Date 1-1-1800 is expected not to occur in MP9 documents. -->
    <xsl:variable name="nfInvalidDate" select="xs:date('1800-01-01')"/>
    <xsl:variable name="nfInvalidDateTime" select="xs:dateTime('1800-01-01T00:00:00')"/>
    <xsl:variable name="nfFutureDateTime" select="xs:dateTime('2800-01-01T00:00:00')"/>
    
    
    <xd:doc>
        <xd:desc>Simple function that converts a hl7 date string to a xs:date variable.
            <br />This function requires month and day (unlike hl7 specification).
            <br/>To initialize the xs:date separators need to be added to the hl7 string: 
            <br />[YYYY][MM][DD] to [YYYY]-[MM]-[DD].
            <br />Text beyond the day number is ignored. (so strings that also contain time or timezone are allowed input)
        </xd:desc>
        <xd:param name="hl7date">The string containing a date in the HL7 format.</xd:param>
    </xd:doc>
    <xsl:function name="nf:convertDate" as="xs:date">
        <xsl:param name="hl7date" as="xs:string?"/>

        <xsl:variable name="matchPattern">^(\d{4})(\d{2})(\d{2}).*</xsl:variable> 
        <xsl:variable name="convertedDate" as="xs:date">
            <xsl:choose>
                <xsl:when test="string-length($hl7date) ge 8 and 
                    matches ($hl7date, $matchPattern)">
                    <!-- Currently this function also converts hl7 strings with more than 8 characters, 
                        so that it can also be used to make an xs:date from a date time string. 
                        That can be disabled by changing the above 'ge' in 'eq' or '=' -->
                    <xsl:value-of select="xs:date(replace($hl7date, $matchPattern, '$1-$2-$3'))"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$nfInvalidDate"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="$convertedDate"/>
        <xsl:if test="$debugNfMessages"> 
            <xsl:message>resultaat = <xsl:value-of select="$convertedDate"/></xsl:message>
        </xsl:if>
    </xsl:function>
    
    <xd:doc>
        <xd:desc>Simple function to display a xs:date in a standardized way.</xd:desc>
        <xd:param name="date"/>
    </xd:doc>
    <xsl:function name="nf:printDate" as="xs:string">
        <xsl:param name="date" as="xs:date"/>
        <xsl:value-of select="if ($date ne $nfInvalidDate) then 
            format-date($date, $nfDateFormat, $nfDateTimeLanguage, (), ()) else 
            nf:getLocalizedString('errInvalidDate')" />
    </xsl:function>
    
    <xd:doc>
        <xd:desc>Convert a HL7 date string without separators to a string that xs:dateTime accepts as input:
            <br/>[YYYY][MM][DD][HH][mm][SS].[uuuu][-/+][ZZ][zz] (e.g. '20160623141518.836+0000') to
            <br/>[YYYY]-[MM]-[DD]T[HH]:[mm]:[SS].[uuuu][-/+][ZZ]:[zz].
            <br/>Several parts are optional in the hl7 string. 
            <br />If no month or day is present, 01 is substituted.
            <br />Time is optional, but if hours are present, minutes are expected too.
            <br/>If no valid date or datetime can be constructed from the hl7 string, the variable InvalidDateTime is returned. 
        </xd:desc>
        <xd:param name="hl7date">String from a HL7 message that shoudl contain a date, with or without time and timezone</xd:param>
    </xd:doc>
    <xsl:function name="nf:convertDateTime" as="xs:dateTime">
        <xsl:param name="hl7date" as="xs:string?"/>
        <xsl:variable name="datetimePart" select="replace($hl7date, '^(\d+).*','$1')"/>
        <!-- milliseconds are optional -->
        <xsl:variable name="subSecPart" select="if (matches($hl7date, '^.*(\.\d+).*')) then 
            replace($hl7date, '^.*(\.\d+).*','$1') else 
            ''"/>
        <!-- timezone is optional, and if present can contain 2 (only hours) or 4 (hours and minutes) digits .-->
        <xsl:variable name="timezonePart" select="if (matches($hl7date, '^.*([+-]\d{2,4})')) then 
            replace($hl7date, '^.*([+-]\d{2,4})','$1') else 
            ''"/>
        
        <xsl:if test="$debugNfMessages"> 
            <xsl:message>datePart = <xsl:value-of select="$datetimePart"/></xsl:message>
            <xsl:message>subsecPart = <xsl:value-of select="$subSecPart"/></xsl:message>
            <xsl:message>timezonePart = <xsl:value-of select="$timezonePart"/></xsl:message>
        </xsl:if>
        
        <xsl:variable name="xsDateTime" as="xs:dateTime">
            <xsl:variable name="yearNum" select="substring($datetimePart, 1, 4)"/>
            <!--<xsl:variable name="monthNum" select="substring($datetimePart, 5, 2)"/>
            <xsl:variable name="dayNum" select="substring($datetimePart, 7, 2)"/>-->
            <!-- If no month is present, use month = 1 (since we need something to make an xs:date) -->
            <xsl:variable name="monthNum">
                <xsl:choose>
                    <xsl:when test="substring($datetimePart, 5, 2) = ''">01</xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="substring($datetimePart, 5, 2)"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <!-- If no day is present, use day = 1 (since we need something to make an xs:date) -->
            <xsl:variable name="dayNum">
            <xsl:choose>
                <xsl:when test="substring($datetimePart, 7, 2) = ''">01</xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="substring($datetimePart, 7, 2)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="time" select="substring($datetimePart, 9, 6)"/>
            <xsl:variable name="hourNum" select="substring($time, 1, 2)"/>
            <xsl:variable name="minNum" select="substring($time, 3, 2)"/>
            <!-- No seconds in hl7 string is supported, and then 0 seconds is inserted if a time is present at all. -->
            <xsl:variable name="secNum" select="if (string-length($time) >= 5) then 
                substring($time, 5, 2) else if (string-length($time) gt 1) then '00' else 
                '' "/>
            
            <xsl:variable name="zonePlusMin" select="substring($timezonePart, 1, 1)"/>
            <xsl:variable name="zoneHourNum" select="substring($timezonePart, 2, 2)"/>
            <!-- No timezone minutes in hl7 string is supported, and then 0 minutes is inserted if a timezone is present at all. -->
            <xsl:variable name="zoneMinNum" select="if (string-length($timezonePart) ge 4) then 
                substring($timezonePart, 4, 2) else if (string-length($timezonePart) gt 1) then '00' else 
                '' "/>
            <!-- The [. != ''] in the next line only concatenates non-empty strings -->
            <xsl:variable name="timeZoneString" 
                select="concat($zonePlusMin,string-join(($zoneHourNum,$zoneMinNum)[. != ''],':'))"/>

            <xsl:variable name="dateString" 
                select="string-join(($yearNum,$monthNum,$dayNum),'-')"/>
            <!-- If present also add the milliseconds to the time string -->
            <xsl:variable name="timeString" 
                select="concat(string-join(($hourNum,$minNum,$secNum)[. != ''],':'),$subSecPart)"/>
            <xsl:variable name="dateTimeString" 
                select="string-join(($dateString,$timeString)[. != ''],'T')"/>
            <xsl:variable name="dateTimeZoneString" 
                select="concat($dateTimeString,$timeZoneString)"/>
            
            <xsl:if test="$debugNfMessages"> 
                <xsl:message>dateString = <xsl:value-of select="$dateString"/></xsl:message>
                <xsl:message>timeString = <xsl:value-of select="$timeString"/></xsl:message>
                <xsl:message>dateTimeZoneString = <xsl:value-of select="$dateTimeZoneString"/></xsl:message>
            </xsl:if>
            
            <!-- If only a date is specified in the hl7 string, it is converted to a datetime with time 00:00:00.
                If the hl7 string cannot be recognized as either DateTime or Time, the variable InvalidDateTime is returned. --> 
            <xsl:choose>
                <xsl:when test="$dateTimeString castable as xs:dateTime">
                    <xsl:value-of select="xs:dateTime($dateTimeZoneString)"/>
                    <xsl:if test="$debugNfMessages"> 
                        <xsl:message>nf:getDateTime recognized input as xs:dateTime</xsl:message>
                    </xsl:if>
                </xsl:when>
                <xsl:when test="$dateTimeString castable as xs:date">
                    <xsl:value-of select="xs:dateTime(concat($dateString,'T00:00:00'))"/>
                    <xsl:if test="$debugNfMessages"> 
                        <xsl:message>nf:getDateTime recognized input as xs:date and converted to dateTime</xsl:message>
                    </xsl:if>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$nfInvalidDateTime"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:value-of select="$xsDateTime"/>
        <xsl:if test="$debugNfMessages"> 
            <xsl:message>resultaat = <xsl:value-of select="$xsDateTime"/></xsl:message>
        </xsl:if>
        
    </xsl:function>
    
    <xd:doc>
        <xd:desc>
            Calculate the sum of a date with a duration (given as a value and a unit as specified by HL7).
        </xd:desc>
        <xd:param name="startDate"/>
        <xd:param name="durationValue"/>
        <xd:param name="durationUnit"/>
    </xd:doc>
    <xsl:function name="nf:calculateDateTimePlusDuration">
        <xsl:param name="startDate" as="xs:dateTime"/>
        <xsl:param name="durationValue" as="xs:double"/>
        <xsl:param name="durationUnit" as="xs:string"/>
        
        <!-- "de eenheden zijn ‘us’ (microseconde), ‘ms’ (miliseconde), ‘s’ (seconde), ‘min’ (minuut), ‘h’ (uur), 
             ‘d’ (dag), ‘wk’ (week), ‘mo’ (maand) en ‘a’ (jaar)."  -->
        <xsl:choose>
            <xsl:when test="lower-case($durationUnit) eq 'us'">
                <xsl:value-of select="$startDate + xs:dayTimeDuration(concat('P',$durationValue div 1000000,'S'))"/>
            </xsl:when>
            <xsl:when test="lower-case($durationUnit) eq 'ms'">
                <xsl:value-of select="$startDate + xs:dayTimeDuration(concat('P',$durationValue div 1000,'S'))"/>
            </xsl:when>
            <xsl:when test="lower-case($durationUnit) eq 's'">
                <xsl:value-of select="$startDate + xs:dayTimeDuration(concat('P',$durationValue,'S'))"/>
            </xsl:when>
            <xsl:when test="lower-case($durationUnit) eq 'min'">
                <xsl:value-of select="$startDate + xs:dayTimeDuration(concat('P',$durationValue,'M'))"/>
            </xsl:when>
            <xsl:when test="lower-case($durationUnit) eq 'h'">
                <xsl:value-of select="$startDate + xs:dayTimeDuration(concat('P',$durationValue,'H'))"/>
            </xsl:when>
            <xsl:when test="lower-case($durationUnit) eq 'd'">
                <xsl:value-of select="$startDate + xs:dayTimeDuration(concat('P',$durationValue,'D'))"/>
            </xsl:when>
            <xsl:when test="lower-case($durationUnit) eq 'wk'">
                <xsl:value-of select="$startDate + xs:dayTimeDuration(concat('P',$durationValue*7,'D'))"/>
            </xsl:when>
            <xsl:when test="lower-case($durationUnit) eq 'mo'">
                <xsl:value-of select="$startDate + xs:yearMonthDuration(concat('P',$durationValue,'M'))"/>
            </xsl:when>
            <xsl:when test="lower-case($durationUnit) eq 'a'">
                <xsl:value-of select="$startDate + xs:yearMonthDuration(concat('P',$durationValue,'Y'))"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$nfFutureDateTime"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xd:doc>
        <xd:desc>Simple function to display a xs:dateTime in a standardized way.</xd:desc>
        <xd:param name="dateTime"/>
    </xd:doc>
    <xsl:function name="nf:printDateTime" as="xs:string">
        <xsl:param name="dateTime" as="xs:dateTime"/>
        
        <xsl:value-of select="if ($dateTime ne $nfInvalidDateTime) then 
            format-dateTime($dateTime,  $nfDateTimeFormat, $nfDateTimeLanguage, (), ()) else 
            nf:getLocalizedString('errInvalidDateTime') "/>
    </xsl:function>


    <xd:doc>
        <xd:desc>Simple function to display a HL7 date(time) in a standardized way.</xd:desc>
        <xd:param name="hl7DateTime"/>
    </xd:doc>
    <xsl:function name="nf:printHl7DateTime" as="xs:string">
        <xsl:param name="hl7DateTime" as="xs:string?"/>
        <xsl:param name="showDateOnly" as="xs:boolean"/>
        
        <xsl:variable name="monthName" select="nf:formatMonth(substring($hl7DateTime, 5, 2))"/>
        <xsl:variable name="resultDate">
            <xsl:choose>
                <xsl:when test="not($hl7DateTime) or string-length($hl7DateTime) eq 0">
                    <xsl:value-of select="''"/>
                </xsl:when>
                <xsl:when test="not(matches($hl7DateTime, '^\d{4,8}.*'))">
                    <xsl:value-of select="concat('foute datum/tijd: ', $hl7DateTime)"/>
                </xsl:when>
                <xsl:when test="string-length($hl7DateTime) eq 4">
                    <xsl:value-of select="$hl7DateTime"/>
                 </xsl:when>
                <xsl:when test="string-length($hl7DateTime) eq 6">
                    <xsl:value-of select="$monthName"/> <xsl:text> </xsl:text>
                    <xsl:value-of select="substring($hl7DateTime, 1, 4)"/>
                 </xsl:when>
                <xsl:when test="string-length($hl7DateTime) ge 8">
                    <xsl:value-of select="substring($hl7DateTime, 7, 2)"/> <xsl:text> </xsl:text>
                    <xsl:value-of select="$monthName"/> <xsl:text> </xsl:text>
                    <xsl:value-of select="substring($hl7DateTime, 1, 4)"/>
                </xsl:when>
             </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="resultTime">
            <xsl:variable name="hl7Time" select="if ('string-length($hl7DateTime) gt 8') then 
                replace($hl7DateTime, '^\d{8}(\.*)', '$1') else ''"/>
            
            <xsl:choose>
                <xsl:when test="not(matches($hl7DateTime, '^\d{8}.*'))">
                    <xsl:value-of select="''"/>
                </xsl:when>
                <xsl:when test="string-length($hl7Time) eq 2">
                    <xsl:value-of select="$hl7Time"/>
                </xsl:when>
                <xsl:when test="string-length($hl7Time) eq 4">
                    <xsl:value-of select="replace($hl7Time, '^(\d{2})(\d{2})', '$1:$2')"/>
                </xsl:when>
                <xsl:when test="string-length($hl7Time) ge 6">
                    <xsl:value-of select="replace($hl7Time, '^(\d{2})(\d{2})(\d{2})(\.*)', '$1:$2:$3$4')"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:choose>
            <xsl:when test="$showDateOnly">
                <xsl:value-of select="$resultDate"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="concat($resultDate, ' ', $resultTime)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xd:doc>
        <xd:desc>
            <xd:p>Takes the 5th and 6th character from a timestamp, and returns the localized month name</xd:p>
        </xd:desc>
        <xd:param name="monthNr">Timestamp string</xd:param>
    </xd:doc>
    <xsl:function name="nf:formatMonth" as="xs:string">
        <xsl:param name="monthNr" as="xs:string"/>
        <!-- month -->
        <xsl:choose>
            <xsl:when test="$monthNr='01'">
                <xsl:value-of select="nf:getLocalizedString('January')"/>
            </xsl:when>
            <xsl:when test="$monthNr='02'">
                <xsl:value-of select="nf:getLocalizedString('February')"/>
            </xsl:when>
            <xsl:when test="$monthNr='03'">
                <xsl:value-of select="nf:getLocalizedString('March')"/>
            </xsl:when>
            <xsl:when test="$monthNr='04'">
                <xsl:value-of select="nf:getLocalizedString('April')"/>
            </xsl:when>
            <xsl:when test="$monthNr='05'">
                <xsl:value-of select="nf:getLocalizedString('May')"/>
            </xsl:when>
            <xsl:when test="$monthNr='06'">
                <xsl:value-of select="nf:getLocalizedString('June')"/>
            </xsl:when>
            <xsl:when test="$monthNr='07'">
                <xsl:value-of select="nf:getLocalizedString('July')"/>
            </xsl:when>
            <xsl:when test="$monthNr='08'">
                <xsl:value-of select="nf:getLocalizedString('August')"/>
            </xsl:when>
            <xsl:when test="$monthNr='09'">
                <xsl:value-of select="nf:getLocalizedString('September')"/>
            </xsl:when>
            <xsl:when test="$monthNr='10'">
                <xsl:value-of select="nf:getLocalizedString('October')"/>
            </xsl:when>
            <xsl:when test="$monthNr='11'">
                <xsl:value-of select="nf:getLocalizedString('November')"/>
            </xsl:when>
            <xsl:when test="$monthNr='12'">
                <xsl:value-of select="nf:getLocalizedString('December')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="nf:getLocalizedString('dateUnknown')"/>
                <xsl:if test="$debugNfMessages">
                    <xsl:text> (</xsl:text><xsl:value-of select="$monthNr"/><xsl:text>)</xsl:text>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>



    <xd:doc>
        <xd:desc>Unit test for the convertDate and convertDateTime functions</xd:desc>
    </xd:doc>
    <xsl:template name="testConvertDateTime">
        <h3>Unittest datum/tijd conversie</h3>

        <table cellpadding="3">
            <tr>
                <th>test id</th>
                <th>description</th>
                <th>input</th>
                <th>output</th>
                <th>direct string convert</th>
            </tr>
            <!-- Date tests -->
            <tr>
                <xsl:variable name="testDateStr" as="xs:string" select="string('20170102')" />
                <xsl:variable name="testDate" as="xs:date" select="nf:convertDate($testDateStr)"/>
                <xsl:message>Date test 1</xsl:message>
                <td>Date test 1</td>
                <td>regular date</td>           
                <td><xsl:value-of select="$testDateStr"/></td>
                <td><xsl:value-of select="nf:printDate($testDate)" /></td>
                <td><xsl:value-of select="nf:printHl7DateTime($testDateStr, false())" /></td>
            </tr>
            <tr>
                <xsl:variable name="testDateStr" as="xs:string" select="string('+20170102')" />
                <xsl:variable name="testDate" as="xs:date" select="nf:convertDate($testDateStr)"/>
                <xsl:message>Date test 2</xsl:message>
                <td>Date test 2</td>
                <td>date with '+'</td>           
                <td><xsl:value-of select="$testDateStr"/></td>
                <td><xsl:value-of select="nf:printDate($testDate)" /></td>
                <td><xsl:value-of select="nf:printHl7DateTime($testDateStr, false())" /></td>
            </tr>
            <tr>
                <xsl:variable name="testDateStr" as="xs:string" select="string('20170102010203.3+01')" />
                <xsl:variable name="testDate" as="xs:date" select="nf:convertDate($testDateStr)"/>
                <xsl:message>Date test 3</xsl:message>
                <td>Date test 3</td>
                <td>date with time and timezone</td>           
                <td><xsl:value-of select="$testDateStr"/></td>
                <td><xsl:value-of select="nf:printDate($testDate)" /></td>
                <td><xsl:value-of select="nf:printHl7DateTime($testDateStr, false())" /></td>
            </tr>
            <tr>
                <xsl:variable name="testDateStr" as="xs:string" select="string('2017jan02')" />
                <xsl:variable name="testDate" as="xs:date" select="nf:convertDate($testDateStr)"/>
                <xsl:message>Date test 4</xsl:message>
                <td>Date test 4</td>
                <td>invalid date with month in letters</td>           
                <td><xsl:value-of select="$testDateStr"/></td>
                <td><xsl:value-of select="nf:printDate($testDate)" /></td>
                <td><xsl:value-of select="nf:printHl7DateTime($testDateStr, false())" /></td>
            </tr>
            
            <!-- DateTime tests -->
            <tr>
                <xsl:variable name="testDateTimeStr" as="xs:string" select="string('20160623141518.836+0100')" />
                <xsl:variable name="testDateTime" as="xs:dateTime" select="nf:convertDateTime($testDateTimeStr)"/>
                <xsl:message>DateTime test 1</xsl:message>
                <td>DateTime test 1</td>
                <td>fully filled dateTime</td>           
                <td><xsl:value-of select="$testDateTimeStr"/></td>
                <td><xsl:value-of select="nf:printDateTime($testDateTime)" /></td>
                <td><xsl:value-of select="nf:printHl7DateTime($testDateTimeStr, false())" /></td>
            </tr>
            
            <!-- DateTime tests -->
            <tr>
                <xsl:variable name="testDateTimeStr" as="xs:string" select="string('201701021112')" />
                <xsl:variable name="testDateTime" as="xs:dateTime" select="nf:convertDateTime($testDateTimeStr)"/>
                <xsl:message>DateTime test 2</xsl:message>
                <td>DateTime test 2</td>
                <td>without seconds</td>           
                <td><xsl:value-of select="$testDateTimeStr"/></td>
                <td><xsl:value-of select="nf:printDateTime($testDateTime)" /></td>
                <td><xsl:value-of select="nf:printHl7DateTime($testDateTimeStr, false())" /></td>
            </tr>
            
            <tr>
                <xsl:variable name="testDateTimeStr" as="xs:string" select="string('20170102111213+01')" />
                <xsl:variable name="testDateTime" as="xs:dateTime" select="nf:convertDateTime($testDateTimeStr)"/>
                <xsl:message>DateTime test 3</xsl:message>
                <td>DateTime test 3</td>
                <td>timezone in hours only</td>           
                <td><xsl:value-of select="$testDateTimeStr"/></td>
                <td><xsl:value-of select="nf:printDateTime($testDateTime)" /></td>
                <td><xsl:value-of select="nf:printHl7DateTime($testDateTimeStr, false())" /></td>
            </tr>

            <tr>
                <xsl:variable name="testDateTimeStr" as="xs:string" select="string('20170100141516')" />
                <xsl:variable name="testDateTime" as="xs:dateTime" select="nf:convertDateTime($testDateTimeStr)"/>
                <xsl:message>DateTime test 4</xsl:message>
                <td>DateTime test 4</td>
                <td>unsupported day '0'</td>           
                <td><xsl:value-of select="$testDateTimeStr"/></td>
                <td><xsl:value-of select="nf:printDateTime($testDateTime)" /></td>
                <td><xsl:value-of select="nf:printHl7DateTime($testDateTimeStr, false())" /></td>
            </tr>
            
            <tr>
                <xsl:variable name="testDateTimeStr" as="xs:string" select="string('20160623141518.836+010000')" />
                <xsl:variable name="testDateTime" as="xs:dateTime" select="nf:convertDateTime($testDateTimeStr)"/>
                <xsl:message>DateTime test 5</xsl:message>
                <td>DateTime test 5</td>
                <td>timezone with seconds (ignored)</td>           
                <td><xsl:value-of select="$testDateTimeStr"/></td>
                <td><xsl:value-of select="nf:printDateTime($testDateTime)" /></td>
                <td><xsl:value-of select="nf:printHl7DateTime($testDateTimeStr, false())" /></td>
            </tr>
            
            <tr>
                <xsl:variable name="testDateTimeStr" as="xs:string" select="string('2016june23141518.836+0100')" />
                <xsl:variable name="testDateTime" as="xs:dateTime" select="nf:convertDateTime($testDateTimeStr)"/>
                <xsl:message>DateTime test 6</xsl:message>
                <td>DateTime test 6</td>
                <td>unsupported: month in letters</td>           
                <td><xsl:value-of select="$testDateTimeStr"/></td>
                <td><xsl:value-of select="nf:printDateTime($testDateTime)" /></td>
                <td><xsl:value-of select="nf:printHl7DateTime($testDateTimeStr, false())" /></td>
            </tr>
            
            <tr>
                <xsl:variable name="testDateTimeStr" as="xs:string" select="string('+20160623141518.836+0100')" />
                <xsl:variable name="testDateTime" as="xs:dateTime" select="nf:convertDateTime($testDateTimeStr)"/>
                <xsl:message>DateTime test 7</xsl:message>
                <td>DateTime test 7</td>
                <td>'+' before year</td>           
                <td><xsl:value-of select="$testDateTimeStr"/></td>
                <td><xsl:value-of select="nf:printDateTime($testDateTime)" /></td>
                <td><xsl:value-of select="nf:printHl7DateTime($testDateTimeStr, false())" /></td>
            </tr>

            <tr>
                <xsl:variable name="testDateTimeStr" as="xs:string" select="string('-20160623141518.836+0100')" />
                <xsl:variable name="testDateTime" as="xs:dateTime" select="nf:convertDateTime($testDateTimeStr)"/>
                <xsl:message>DateTime test 8</xsl:message>
                <td>DateTime test 8</td>
                <td>unsupported '-' before year</td>           
                <td><xsl:value-of select="$testDateTimeStr"/></td>
                <td><xsl:value-of select="nf:printDateTime($testDateTime)" /></td>
                <td><xsl:value-of select="nf:printHl7DateTime($testDateTimeStr, false())" /></td>
            </tr>
        </table>
        <br />
        <br />
       
    </xsl:template>
    
</xsl:stylesheet>